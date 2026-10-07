import 'dart:async';
import 'dart:io';

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

/// Videos page: album grouping, thumbnail grid with duration badges,
/// preview dialog (info + export + open-on-Mac), import/export.
class VideosPage extends StatefulWidget {
  const VideosPage(
      {super.key, this.pickSaveDir, this.openLocal, this.pickOpenFiles});

  final Future<String?> Function()? pickSaveDir;

  /// Opens a downloaded local file (default: macOS `open`). Injectable so
  /// tests don't shell out.
  final Future<void> Function(String localPath)? openLocal;

  /// Injectable local-file picker for import.
  final Future<List<String>> Function()? pickOpenFiles;

  @override
  State<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> {
  List<pb.SSPVideoFile> _videos = [];
  List<pb.SSPVideoAlbum> _albums = [];
  Int64? _albumFilter;
  final Set<int> _selected = {};
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
        _videos = [];
        _albums = [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await api.videoLibrary();
      if (!mounted) return;
      setState(() {
        _videos = resp.videoArray.toList();
        _albums = resp.albumArray.toList();
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

  Future<void> _fetchMissingThumbs() async {
    final api = _api;
    if (api == null) return;
    const batch = 60;
    var changed = false;
    final missing =
        _videos.where((f) => f.thumbnail.isEmpty).toList();
    for (var i = 0; i < missing.length; i += batch) {
      final slice = missing.sublist(
          i,
          i + batch > missing.length ? missing.length : i + batch);
      try {
        final resp = await api.thumbnails(videos: slice);
        final byId = {
          for (final f in resp.videoArray) f.mediaId.toInt(): f
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

  List<pb.SSPVideoFile> get _visible => _albumFilter == null
      ? _videos
      : _videos.where((f) => f.albumId == _albumFilter).toList();

  List<pb.SSPVideoFile> get _selectedItems => _videos
      .where((f) => _selected.contains(f.mediaId.toInt()))
      .toList();

  void _toggle(pb.SSPVideoFile f) {
    final id = f.mediaId.toInt();
    setState(() => _selected.contains(id)
        ? _selected.remove(id)
        : _selected.add(id));
  }

  Future<String?> _pickDir() {
    final custom = widget.pickSaveDir;
    if (custom != null) return custom();
    return getDirectoryPath(confirmButtonText: '导出到这里');
  }

  Future<void> _exportSelected() async {
    final items = _selectedItems;
    if (items.isEmpty) {
      _toast('请先选择视频');
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

  Future<void> _importPicked() async {
    final custom = widget.pickOpenFiles;
    final paths = custom != null
        ? await custom()
        : await openFiles(acceptedTypeGroups: [
            const XTypeGroup(label: '视频', extensions: [
              'mp4', 'mov', 'mkv', 'avi', 'webm', '3gp'
            ])
          ]).then((fs) => [for (final f in fs) f.path]);
    if (paths.isEmpty) return;
    for (final f in paths) {
      final name = f.split('/').last;
      unawaited(_controller.uploadFile(
          f, joinPath('/sdcard/Movies', name),
          taskName: name));
    }
    _toast('已加入上传队列（${paths.length} 项）');
  }

  Future<void> _deleteSelected() async {
    final api = _api;
    final items = _selectedItems;
    if (api == null || items.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除视频'),
        content: Text('确定从手机删除 ${items.length} 个视频？'),
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
    for (final f in items) {
      try {
        await api.delete(f.path);
      } catch (_) {
        // counted via reload diff; keep going
      }
    }
    if (!mounted) return;
    unawaited(_load());
  }

  /// Downloads [f] to the temp dir then opens it with the system player.
  Future<void> _playOnMac(pb.SSPVideoFile f) async {
    _toast('正在下载到本机播放…');
    try {
      final tmp = Directory.systemTemp
          .createTempSync('handshaker_preview')
          .path;
      final local = joinPath(tmp, baseName(f.path));
      await _controller.downloadFile(f.path, local,
          taskName: baseName(f.path));
      final file = File(local);
      if (!file.existsSync() || file.lengthSync() == 0) {
        _toast('下载未产生文件，无法预览');
        return;
      }
      final opener = widget.openLocal ?? _defaultOpen;
      await opener(local);
    } catch (e) {
      _toast('预览失败：$e');
    }
  }

  static Future<void> _defaultOpen(String path) async {
    if (Platform.isMacOS) {
      await Process.run('open', [path]);
    } else if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', path]);
    } else {
      await Process.run('xdg-open', [path]);
    }
  }

  void _preview(pb.SSPVideoFile f) {
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
                      icon: Icons.movie_outlined),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(baseName(f.path),
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                        '${f.width}×${f.height} · '
                        '${fmtDuration(f.duration)} · '
                        '${fmtBytes(f.fileSize.toInt())}',
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: const Text('在 Mac 上播放'),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            unawaited(_playOnMac(f));
                          },
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonalIcon(
                          icon:
                              const Icon(Icons.download_outlined, size: 16),
                          label: const Text('导出'),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            setState(() =>
                                _selected.add(f.mediaId.toInt()));
                            unawaited(_exportSelected());
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
          _albumTile(null, '全部视频', _videos.length),
          for (final a in _albums)
            _albumTile(
                a.albumId,
                a.albumName.isNotEmpty ? a.albumName : a.albumPath,
                _videos.where((f) => f.albumId == a.albumId).length),
        ],
      ),
    );
  }

  Widget _albumTile(Int64? id, String name, int count) {
    final selected = _albumFilter == id;
    return ListTile(
      dense: true,
      selected: selected,
      leading: const Icon(Icons.video_library_outlined, size: 18),
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
              onPressed: _selected.isNotEmpty
                  ? () => unawaited(_exportSelected())
                  : null,
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('导出到 Mac')),
          TextButton.icon(
              onPressed: () => unawaited(_importPicked()),
              icon: const Icon(Icons.upload_outlined, size: 18),
              label: const Text('导入到手机')),
          TextButton.icon(
              onPressed: _selected.isNotEmpty
                  ? () => unawaited(_deleteSelected())
                  : null,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('删除')),
          const Spacer(),
          TextButton(
              onPressed: () => setState(() =>
                  _selected.addAll(
                      _visible.map((f) => f.mediaId.toInt()))),
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
      return const Center(child: Text('没有视频'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 170,
          mainAxisExtent: 180,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final f = items[i];
        final id = f.mediaId.toInt();
        return MediaTile(
          label: baseName(f.path),
          subtitle: fmtBytes(f.fileSize.toInt()),
          thumbnail: f.thumbnail,
          icon: Icons.movie_outlined,
          badge: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4)),
            child: Text(fmtDuration(f.duration),
                style: const TextStyle(
                    color: Colors.white, fontSize: 10)),
          ),
          selected: _selected.contains(id),
          onTap: () => _toggle(f),
          onDoubleTap: () => _preview(f),
        );
      },
    );
  }
}
