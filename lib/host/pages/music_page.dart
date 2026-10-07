import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

import '../../ssp/pb/SmartSyncProtocol.recovered.pb.dart' as pb;
import '../../ssp/requests.dart';
import '../host_controller.dart';
import 'format.dart';
import 'host_shell.dart';
import 'transfers_panel.dart';

/// Plays a local audio file preview. Injectable so tests don't touch the
/// platform audio stack.
abstract class AudioPreview {
  Future<void> play(String localPath);
  Future<void> stop();
  String? get nowPlaying;
}

/// Real preview player backed by audioplayers.
class AudioPlayersPreview extends AudioPreview {
  AudioPlayersPreview() : _player = AudioPlayer();

  final AudioPlayer _player;
  String? _now;

  @override
  String? get nowPlaying => _now;

  @override
  Future<void> play(String localPath) async {
    await _player.stop();
    await _player.play(DeviceFileSource(localPath));
    _now = localPath;
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _now = null;
  }
}

/// Music page: album filter rail, song table (title/album/artist/duration/
/// size), export to Mac, import to phone, double-click preview playback
/// (downloads to temp first).
class MusicPage extends StatefulWidget {
  const MusicPage({
    super.key,
    this.pickSaveDir,
    this.pickOpenFiles,
    this.preview,
  });

  final Future<String?> Function()? pickSaveDir;
  final Future<List<String>> Function()? pickOpenFiles;

  /// Injectable preview player; defaults to [AudioPlayersPreview].
  final AudioPreview? preview;

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  List<pb.SSPAudioFile> _songs = [];
  List<pb.SSPAudioAlbum> _albums = [];
  Int64? _albumFilter;
  final Set<int> _selected = {};
  bool _loading = false;
  String? _error;
  String _query = '';
  late final AudioPreview _preview =
      widget.preview ?? AudioPlayersPreview();

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
        _songs = [];
        _albums = [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await api.audioLibrary();
      if (!mounted) return;
      setState(() {
        _songs = resp.audioArray.toList();
        _albums = resp.albumArray.toList();
        _loading = false;
      });
      unawaited(_fetchAlbumCovers());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _fetchAlbumCovers() async {
    final api = _api;
    if (api == null) return;
    final missing =
        _albums.where((a) => a.thumbnail.isEmpty).toList();
    if (missing.isEmpty) return;
    try {
      final resp = await api.thumbnails(audioAlbums: missing);
      final byId = {
        for (final a in resp.audioAlbumArray) a.albumId.toInt(): a
      };
      var changed = false;
      for (final a in missing) {
        final r = byId[a.albumId.toInt()];
        if (r != null && r.thumbnail.isNotEmpty) {
          a.thumbnail = r.thumbnail;
          changed = true;
        }
      }
      if (changed && mounted) setState(() {});
    } catch (_) {
      // covers stay as placeholders
    }
  }

  List<pb.SSPAudioFile> get _visible {
    var list = _albumFilter == null
        ? _songs.toList()
        : _songs.where((f) => f.albumId == _albumFilter).toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((f) =>
              f.title.toLowerCase().contains(q) ||
              f.artist.toLowerCase().contains(q) ||
              baseName(f.path).toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  String _albumName(Int64 id) {
    for (final a in _albums) {
      if (a.albumId == id) return a.albumName;
    }
    return '-';
  }

  void _toggle(pb.SSPAudioFile f) {
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
    final items =
        _songs.where((f) => _selected.contains(f.mediaId.toInt())).toList();
    if (items.isEmpty) {
      _toast('请先选择歌曲');
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
            const XTypeGroup(label: '音频', extensions: [
              'mp3', 'aac', 'm4a', 'flac', 'ogg', 'wav'
            ])
          ]).then((fs) => [for (final f in fs) f.path]);
    if (paths.isEmpty) return;
    for (final f in paths) {
      final name = f.split('/').last;
      unawaited(_controller.uploadFile(
          f, joinPath('/sdcard/Music', name),
          taskName: name));
    }
    _toast('已加入上传队列（${paths.length} 项）');
  }

  Future<void> _playPreview(pb.SSPAudioFile f) async {
    _toast('正在下载试听…');
    try {
      final tmp = Directory.systemTemp
          .createTempSync('handshaker_audio')
          .path;
      final local = joinPath(tmp, baseName(f.path));
      await _controller.downloadFile(f.path, local,
          taskName: baseName(f.path));
      final file = File(local);
      if (!file.existsSync() || file.lengthSync() == 0) {
        _toast('下载未产生文件，无法试听');
        return;
      }
      await _preview.play(local);
      if (mounted) setState(() {});
    } catch (e) {
      _toast('试听失败：$e');
    }
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
              Expanded(child: _list()),
              if (_preview.nowPlaying != null) _nowPlayingBar(),
              const TransfersPanel(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _albumNav() {
    return SizedBox(
      width: 150,
      child: ListView(
        children: [
          _albumTile(null, '全部歌曲', _songs.length),
          for (final a in _albums)
            _albumTile(
                a.albumId,
                a.albumName.isNotEmpty ? a.albumName : '未知专辑',
                _songs.where((f) => f.albumId == a.albumId).length),
        ],
      ),
    );
  }

  Widget _albumTile(Int64? id, String name, int count) {
    final selected = _albumFilter == id;
    return ListTile(
      dense: true,
      selected: selected,
      leading: const Icon(Icons.album_outlined, size: 18),
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
          const Spacer(),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: TextField(
                decoration: const InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(Icons.search, size: 18),
                  hintText: '搜索歌曲',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          ),
          IconButton(
              tooltip: '刷新',
              onPressed: () => unawaited(_load()),
              icon: const Icon(Icons.refresh, size: 20)),
        ],
      ),
    );
  }

  Widget _nowPlayingBar() {
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.play_circle_outline),
        title: Text('正在试听 ${baseName(_preview.nowPlaying!)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.stop, size: 18),
          onPressed: () async {
            await _preview.stop();
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }

  Widget _list() {
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
      return const Center(child: Text('没有歌曲'));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const SizedBox(width: 24),
              _h('标题', flex: 4),
              _h('专辑', flex: 3),
              _h('歌手', flex: 2),
              _h('时长', flex: 1),
              _h('大小', flex: 1),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (ctx, i) => _row(items[i]),
          ),
        ),
      ],
    );
  }

  Widget _h(String t, {int flex = 1}) => Expanded(
      flex: flex,
      child: Text(t,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.outline)));

  Widget _row(pb.SSPAudioFile f) {
    final id = f.mediaId.toInt();
    final selected = _selected.contains(id);
    final playing =
        _preview.nowPlaying?.endsWith(baseName(f.path)) ?? false;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _toggle(f),
      onDoubleTap: () => unawaited(_playPreview(f)),
      child: Container(
        color: selected ? scheme.primaryContainer : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
                playing
                    ? Icons.graphic_eq
                    : Icons.music_note_outlined,
                size: 18,
                color: playing ? scheme.primary : scheme.outline),
            const SizedBox(width: 6),
            _cell(
                f.title.isNotEmpty ? f.title : baseName(f.path),
                flex: 4),
            _cell(_albumName(f.albumId), flex: 3),
            _cell(f.artist.isNotEmpty ? f.artist : '未知歌手', flex: 2),
            _cell(fmtDuration(f.duration), flex: 1),
            _cell(fmtBytes(f.fileSize.toInt()), flex: 1),
          ],
        ),
      ),
    );
  }

  Widget _cell(String t, {int flex = 1}) => Expanded(
      flex: flex,
      child: Text(t,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12)));
}
