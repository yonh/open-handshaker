import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

import '../../ssp/pb/SmartSyncProtocol.recovered.pb.dart' as pb;
import '../../ssp/requests.dart';
import '../host_controller.dart';
import 'format.dart';
import 'host_shell.dart';
import 'media_common.dart';
import 'transfers_panel.dart';

/// Photos page: album sidebar, thumbnail grid, large preview dialog,
/// import-to-Mac (download) and delete.
class PhotosPage extends StatefulWidget {
  const PhotosPage({super.key, this.pickSaveDir});

  /// Injectable destination-directory picker (file_selector in the app).
  final Future<String?> Function()? pickSaveDir;

  @override
  State<PhotosPage> createState() => _PhotosPageState();
}

class _PhotosPageState extends State<PhotosPage> {
  List<pb.SSPImageFile> _photos = [];
  List<pb.SSPImageAlbum> _albums = [];
  Int64 _cameraAlbumId = Int64.ZERO;
  Int64? _albumFilter; // null = 全部
  final Set<int> _selected = {}; // mediaId
  bool _loading = false;
  String? _error;

  SspApi? get _api => HostScope.of(context).controller.api;
  HostController get _controller => HostScope.of(context).controller;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final api = _api;
    if (api == null) {
      setState(() {
        _photos = [];
        _albums = [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await api.photoLibrary();
      if (!mounted) return;
      setState(() {
        _photos = resp.imageArray.toList();
        _albums = resp.albumArray.toList();
        _cameraAlbumId = resp.cameraAlbumId;
        _loading = false;
      });
      unawaited(_fetchMissingThumbs());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  /// Batch-fetch thumbnails for images that did not carry inline bytes.
  Future<void> _fetchMissingThumbs() async {
    final api = _api;
    if (api == null) return;
    const batch = 60;
    var changed = false;
    final missing =
        _photos.where((f) => f.thumbnail.isEmpty).toList();
    for (var i = 0; i < missing.length; i += batch) {
      final slice = missing.sublist(
          i,
          i + batch > missing.length ? missing.length : i + batch);
      try {
        final resp = await api.thumbnails(images: slice);
        final byId = {
          for (final f in resp.imageArray) f.mediaId.toInt(): f
        };
        for (final f in slice) {
          final r = byId[f.mediaId.toInt()];
          if (r != null && r.thumbnail.isNotEmpty) {
            f.thumbnail = r.thumbnail;
            changed = true;
          }
        }
      } catch (_) {
        // keep placeholders for failed batches
      }
    }
    if (changed && mounted) setState(() {});
  }

  List<pb.SSPImageFile> get _visible => _albumFilter == null
      ? _photos
      : _photos.where((f) => f.albumId == _albumFilter).toList();

  List<pb.SSPImageFile> get _selectedItems => _photos
      .where((f) => _selected.contains(f.mediaId.toInt()))
      .toList();

  void _toggle(pb.SSPImageFile f) {
    final id = f.mediaId.toInt();
    setState(() => _selected.contains(id)
        ? _selected.remove(id)
        : _selected.add(id));
  }

  Future<String?> _pickDir() {
    final custom = widget.pickSaveDir;
    if (custom != null) return custom();
    return getDirectoryPath(confirmButtonText: '导入到这里');
  }

  Future<void> _importSelected() async {
    final items = _selectedItems;
    if (items.isEmpty) {
      _toast('请先选择照片');
      return;
    }
    final dir = await _pickDir();
    if (dir == null) return;
    for (final f in items) {
      unawaited(_controller.downloadFile(
          f.path, joinPath(dir, baseName(f.path)),
          taskName: baseName(f.path)));
    }
    _toast('已加入下载队列（${items.length} 项）');
  }

  Future<void> _deleteSelected() async {
    final api = _api;
    final items = _selectedItems;
    if (api == null || items.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除照片'),
        content: Text('确定从手机删除 ${items.length} 张照片？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('删除')),
        ],
      ),
    );
    if (ok != true) return;
    var failed = 0;
    for (final f in items) {
      try {
        final r = await api.delete(f.path);
        if (!r.succeed) failed++;
      } catch (_) {
        failed++;
      }
    }
    if (!mounted) return;
    if (failed > 0) _toast('$failed 项删除失败');
    unawaited(_load());
  }

  void _preview(pb.SSPImageFile f) {
    unawaited(showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: 560, maxHeight: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ColoredBox(
                  color: Colors.black,
                  child: ThumbImage(
                      bytes: f.thumbnail,
                      fit: BoxFit.contain,
                      icon: Icons.photo_outlined),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.title.isNotEmpty ? f.title : baseName(f.path),
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                        '${f.width}×${f.height} · '
                        '${fmtBytes(f.fileSize.toInt())} · '
                        '${fmtDate(f.dateTaken.toInt())}',
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        FilledButton.tonalIcon(
                          icon:
                              const Icon(Icons.download_outlined, size: 16),
                          label: const Text('导入到 Mac'),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            setState(() =>
                                _selected.add(f.mediaId.toInt()));
                            unawaited(_importSelected());
                          },
                        ),
                        const Spacer(),
                        TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('关闭')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _albumNav(),
        const VerticalDivider(width: 1),
        Expanded(
          child: Column(
            children: [
              _toolbar(),
              Expanded(child: _grid()),
              const TransfersPanel(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _albumNav() {
    return SizedBox(
      width: 140,
      child: ListView(
        children: [
          _albumTile(null, '全部照片', _photos.length),
          for (final a in _albums)
            _albumTile(
                a.albumId,
                a.albumName.isNotEmpty ? a.albumName : a.albumPath,
                _photos.where((f) => f.albumId == a.albumId).length),
        ],
      ),
    );
  }

  Widget _albumTile(Int64? id, String name, int count) {
    final selected = _albumFilter == id;
    final isCamera = id != null && id == _cameraAlbumId;
    return ListTile(
      dense: true,
      selected: selected,
      leading: Icon(
          isCamera ? Icons.photo_camera_outlined : Icons.photo_album_outlined,
          size: 18),
      title: Text(name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12)),
      subtitle: Text('$count', style: const TextStyle(fontSize: 10)),
      onTap: () => setState(() {
        _albumFilter = id;
        _selected.clear();
      }),
    );
  }

  Widget _toolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          TextButton.icon(
              onPressed:
                  _selected.isNotEmpty ? () => unawaited(_importSelected()) : null,
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('导入到 Mac')),
          TextButton.icon(
              onPressed: _selected.isNotEmpty
                  ? () => unawaited(_deleteSelected())
                  : null,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('删除')),
          const Spacer(),
          TextButton(
              onPressed: () => setState(() {
                    _selected
                        .addAll(_visible.map((f) => f.mediaId.toInt()));
                  }),
              child: const Text('全选')),
          TextButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () => setState(_selected.clear),
              child: const Text('取消选择')),
          IconButton(
              tooltip: '刷新',
              onPressed: () => unawaited(_load()),
              icon: const Icon(Icons.refresh, size: 20)),
        ],
      ),
    );
  }

  Widget _grid() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('加载失败：$_error'),
            const SizedBox(height: 8),
            FilledButton(
                onPressed: () => unawaited(_load()),
                child: const Text('重试')),
          ],
        ),
      );
    }
    final items = _visible;
    if (items.isEmpty) {
      return const Center(child: Text('没有照片'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 150,
          mainAxisExtent: 170,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final f = items[i];
        final id = f.mediaId.toInt();
        return MediaTile(
          label: f.title.isNotEmpty ? f.title : baseName(f.path),
          subtitle: fmtDate(f.dateTaken.toInt()),
          thumbnail: f.thumbnail,
          selected: _selected.contains(id),
          onTap: () => _toggle(f),
          onDoubleTap: () => _preview(f),
        );
      },
    );
  }
}
