import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../ssp/pb/SmartSyncProtocol.recovered.pb.dart' as pb;
import '../../ssp/requests.dart';
import '../host_controller.dart';
import 'format.dart';
import 'host_shell.dart';
import 'transfers_panel.dart';

/// How the file grid orders entries.
enum FileSort { name, size, mtime }

/// File manager page: breadcrumb navigation, multi-select grid,
/// upload (picker or drag-drop) / download to a Finder-chosen destination,
/// mkdir / rename / delete, sorting, name filtering and the live
/// [TransferTask] panel.
///
/// File pickers are injectable ([pickOpenFiles], [pickSaveDir],
/// [pickSaveLocation]) so widget tests can drive them without a platform.
class FilesPage extends StatefulWidget {
  const FilesPage({
    super.key,
    this.rootPath = '/sdcard',
    this.pickOpenFiles,
    this.pickSaveDir,
    this.pickSaveLocation,
  });

  final String rootPath;

  /// Returns local file paths to upload.
  final Future<List<String>> Function()? pickOpenFiles;

  /// Returns a destination directory for downloads.
  final Future<String?> Function()? pickSaveDir;

  /// Returns a destination file path for a single download.
  final Future<String?> Function(String suggestedName)? pickSaveLocation;

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  late String _path;
  List<pb.SSPFile> _entries = [];
  final Set<String> _selected = {};
  bool _loading = false;
  String? _error;
  FileSort _sort = FileSort.name;
  bool _ascending = true;
  String _query = '';
  bool _dragging = false;

  /// 当前已向 agent 注册的监控目录。
  String? _watching;

  StreamSubscription<dynamic>? _folderSub;
  StreamSubscription<dynamic>? _changeSub;
  Timer? _pushDebounce;
  bool _pushesHooked = false;

  SspApi? get _api => HostScope.of(context).controller.api;

  HostController get _controller => HostScope.of(context).controller;

  @override
  void initState() {
    super.initState();
    _path = widget.rootPath;
    unawaited(_reload());
    _hookPushes();
    _updateWatch();
  }

  /// 订阅 PushHub 的 MonitorFolder / FileChange 推送，防抖后刷新列表。
  /// mock / 未提供推送通道时静默降级为纯手动刷新。
  void _hookPushes() {
    if (_pushesHooked) return;
    _pushesHooked = true;
    final hub = HostScope.of(context).pushHub;
    void onEvent(dynamic _) {
      _pushDebounce?.cancel();
      _pushDebounce = Timer(const Duration(milliseconds: 400), () {
        if (mounted) unawaited(_reload());
      });
    }

    _folderSub = hub?.folderEvents.listen(onEvent);
    _changeSub = hub?.fileChanges.listen(onEvent);
  }

  /// 当前目录变化时向 agent 注册/注销 monitorFolder。
  void _updateWatch() {
    if (_watching == _path) return;
    final old = _watching;
    _watching = _path;
    unawaited(_watch(_path, true));
    if (old != null) unawaited(_watch(old, false));
  }

  Future<void> _watch(String? path, bool register) async {
    if (path == null) return;
    try {
      await _api?.monitorFolder(path, register: register);
    } catch (_) {}
  }

  @override
  void dispose() {
    _pushDebounce?.cancel();
    _folderSub?.cancel();
    _changeSub?.cancel();
    unawaited(_watch(_watching, false));
    super.dispose();
  }

  Future<void> _reload() async {
    final api = _api;
    if (api == null) {
      setState(() {
        _entries = [];
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await api.listDir(_path);
      if (!mounted) return;
      setState(() {
        _entries = resp.fileArray.toList();
        _selected.clear();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  void _enter(pb.SSPFile f) {
    if (!f.isDirectory) return;
    setState(() {
      _path = f.path;
      _query = '';
      _selected.clear();
    });
    _updateWatch();
    unawaited(_reload());
  }

  void _goUp() {
    if (_path == widget.rootPath || _path == '/') return;
    setState(() => _path = parentPath(_path));
    _updateWatch();
    unawaited(_reload());
  }

  void _goTo(String path) {
    if (path == _path) return;
    setState(() => _path = path);
    _updateWatch();
    unawaited(_reload());
  }

  // ---------- selection ----------

  void _toggle(pb.SSPFile f) {
    setState(() {
      _selected.contains(f.path)
          ? _selected.remove(f.path)
          : _selected.add(f.path);
    });
  }

  List<pb.SSPFile> get _visibleEntries {
    var list = _entries.where((f) {
      if (_query.isEmpty) return true;
      return baseName(f.path)
          .toLowerCase()
          .contains(_query.toLowerCase());
    }).toList();
    int cmp(pb.SSPFile a, pb.SSPFile b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      final r = switch (_sort) {
        FileSort.name =>
          baseName(a.path).toLowerCase().compareTo(baseName(b.path).toLowerCase()),
        FileSort.size => a.fileSize.compareTo(b.fileSize),
        FileSort.mtime => a.modifiedTimestamp.compareTo(b.modifiedTimestamp),
      };
      return _ascending ? r : -r;
    }

    list.sort(cmp);
    return list;
  }

  // ---------- file ops ----------

  Future<void> _mkdir() async {
    final api = _api;
    if (api == null) return;
    final name = await _promptText('新建文件夹', '文件夹名称', '未命名文件夹');
    if (name == null || name.isEmpty) return;
    final target = joinPath(_path, name);
    try {
      final resp = await api.createFolder(target);
      if (!mounted) return;
      if (!resp.succeed) {
        _toast('创建失败：${resp.errorMessage}');
        return;
      }
      unawaited(_reload());
    } catch (e) {
      _toast('创建失败：$e');
    }
  }

  Future<void> _rename(pb.SSPFile f) async {
    final api = _api;
    if (api == null) return;
    final name = await _promptText('重命名', '新名称', baseName(f.path));
    if (name == null || name.isEmpty || name == baseName(f.path)) return;
    try {
      final resp = await api.rename(f.path, joinPath(parentPath(f.path), name));
      if (!mounted) return;
      if (!resp.succeed) {
        _toast('重命名失败：${resp.errorMessage}');
        return;
      }
      unawaited(_reload());
    } catch (e) {
      _toast('重命名失败：$e');
    }
  }

  Future<void> _deleteSelected() async {
    final api = _api;
    if (api == null || _selected.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除所选'),
        content: Text('确定删除 ${_selected.length} 个项目？此操作不可撤销。'),
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
    for (final p in _selected.toList()) {
      try {
        final r = await api.delete(p);
        if (!r.succeed) failed++;
      } catch (_) {
        failed++;
      }
    }
    if (!mounted) return;
    if (failed > 0) _toast('$failed 项删除失败');
    unawaited(_reload());
  }

  // ---------- transfers ----------

  Future<String?> _pickSaveDir() {
    final custom = widget.pickSaveDir;
    if (custom != null) return custom();
    return getDirectoryPath(confirmButtonText: '保存到这里');
  }

  Future<String?> _pickSaveLocation(String name) {
    final custom = widget.pickSaveLocation;
    if (custom != null) return custom(name);
    return getSaveLocation(suggestedName: name)
        .then((l) => l?.path);
  }

  Future<List<String>> _pickOpenFiles() {
    final custom = widget.pickOpenFiles;
    if (custom != null) return custom();
    return openFiles().then((fs) => [for (final f in fs) f.path]);
  }

  Future<void> _downloadSelected() async {
    final paths = _selected
        .map((p) => _entries.firstWhere((f) => f.path == p))
        .where((f) => !f.isDirectory)
        .toList();
    if (paths.isEmpty) {
      _toast('请先选择要下载的文件');
      return;
    }
    if (paths.length == 1) {
      final dst = await _pickSaveLocation(baseName(paths.first.path));
      if (dst == null) return;
      await _controller.downloadFile(paths.first.path, dst,
          taskName: baseName(paths.first.path));
    } else {
      final dir = await _pickSaveDir();
      if (dir == null) return;
      for (final f in paths) {
        unawaited(_controller.downloadFile(
            f.path, joinPath(dir, baseName(f.path)),
            taskName: baseName(f.path)));
      }
    }
  }

  Future<void> _uploadPicked() async {
    final locals = await _pickOpenFiles();
    for (final local in locals) {
      final name = local.split('/').last;
      unawaited(_controller.uploadFile(
          local, joinPath(_path, name),
          taskName: name));
    }
  }

  void _uploadDropped(List<String> locals) {
    for (final local in locals) {
      final name = local.split('/').last;
      unawaited(_controller.uploadFile(
          local, joinPath(_path, name),
          taskName: name));
    }
  }

  Future<String?> _promptText(
      String title, String label, String initial) async {
    final ctl = TextEditingController(text: initial);
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctl,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(ctl.text),
              child: const Text('确定')),
        ],
      ),
    );
    return r?.trim();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (d) =>
          _uploadDropped([for (final f in d.files) f.path]),
      child: Column(
        children: [
          _toolbar(),
          _breadcrumbs(),
          Expanded(
            child: Stack(
              children: [
                _grid(),
                if (_dragging)
                  Positioned.fill(
                    child: Container(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.08),
                      child: const Center(
                        child: Text('松开以上传到当前目录',
                            style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const TransfersPanel(),
        ],
      ),
    );
  }

  Widget _toolbar() {
    final hasSel = _selected.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
              tooltip: '上级目录',
              onPressed:
                  _path == widget.rootPath || _path == '/' ? null : _goUp,
              icon: const Icon(Icons.arrow_upward, size: 20)),
          IconButton(
              tooltip: '刷新',
              onPressed: () => unawaited(_reload()),
              icon: const Icon(Icons.refresh, size: 20)),
          const VerticalDivider(),
          TextButton.icon(
              onPressed: _mkdir,
              icon: const Icon(Icons.create_new_folder_outlined, size: 18),
              label: const Text('新建文件夹')),
          TextButton.icon(
              onPressed: _uploadPicked,
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: const Text('上传')),
          TextButton.icon(
              onPressed: hasSel ? _downloadSelected : null,
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('下载')),
          TextButton.icon(
              onPressed: hasSel ? _deleteSelected : null,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('删除')),
          const Spacer(),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: TextField(
                decoration: const InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(Icons.search, size: 18),
                  hintText: '搜索当前目录',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<FileSort>(
            tooltip: '排序',
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => const [
              PopupMenuItem(value: FileSort.name, child: Text('按名称')),
              PopupMenuItem(value: FileSort.size, child: Text('按大小')),
              PopupMenuItem(value: FileSort.mtime, child: Text('按时间')),
            ],
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.sort, size: 20),
            ),
          ),
          IconButton(
            tooltip: _ascending ? '升序' : '降序',
            icon: Icon(
                _ascending ? Icons.arrow_downward : Icons.arrow_upward,
                size: 18),
            onPressed: () => setState(() => _ascending = !_ascending),
          ),
        ],
      ),
    );
  }

  Widget _breadcrumbs() {
    final parts = _path.split('/').where((e) => e.isNotEmpty).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          InkWell(
            onTap: () => _goTo('/'),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text('根目录',
                  style: TextStyle(fontWeight: FontWeight.w500)),
            ),
          ),
          for (var i = 0; i < parts.length; i++) ...[
            const Icon(Icons.chevron_right, size: 16),
            InkWell(
              onTap: () => _goTo('/${parts.take(i + 1).join('/')}'),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(parts[i],
                    style: TextStyle(
                        fontWeight: i == parts.length - 1
                            ? FontWeight.w600
                            : FontWeight.normal)),
              ),
            ),
          ],
          const Spacer(),
          if (_selected.isNotEmpty) Text('已选 ${_selected.length} 项'),
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
                onPressed: () => unawaited(_reload()),
                child: const Text('重试')),
          ],
        ),
      );
    }
    if (_api == null) {
      return const Center(child: Text('未连接'));
    }
    final items = _visibleEntries;
    if (items.isEmpty) {
      return const Center(child: Text('空目录'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 140,
          mainAxisExtent: 108,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4),
      itemCount: items.length,
      itemBuilder: (ctx, i) => _tile(items[i]),
    );
  }

  Widget _tile(pb.SSPFile f) {
    final selected = _selected.contains(f.path);
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _toggle(f),
      onDoubleTap: () => _enter(f),
      onLongPressStart: (d) => _showItemMenu(f, d.globalPosition),
      child: Card(
        elevation: 0,
        color: selected
            ? scheme.primaryContainer
            : scheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              Expanded(
                child: Icon(fileIcon(baseName(f.path), isDir: f.isDirectory),
                    size: 40,
                    color: f.isDirectory
                        ? scheme.primary
                        : scheme.onSurfaceVariant),
              ),
              Text(baseName(f.path),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12)),
              Text(
                  f.isDirectory
                      ? '文件夹'
                      : fmtBytes(f.fileSize.toInt()),
                  style: TextStyle(
                      fontSize: 10, color: scheme.outline)),
            ],
          ),
        ),
      ),
    );
  }

  void _showItemMenu(pb.SSPFile f, Offset globalPos) {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(globalPos.dx, globalPos.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem(value: 'rename', child: Text('重命名')),
        const PopupMenuItem(value: 'delete', child: Text('删除')),
        if (!f.isDirectory)
          const PopupMenuItem(value: 'download', child: Text('下载')),
      ],
    ).then((v) {
      switch (v) {
        case 'rename':
          unawaited(_rename(f));
        case 'delete':
          setState(() => _selected.add(f.path));
          unawaited(_deleteSelected());
        case 'download':
          unawaited(_downloadOne(f));
      }
    });
  }

  Future<void> _downloadOne(pb.SSPFile f) async {
    final dst = await _pickSaveLocation(baseName(f.path));
    if (dst == null) return;
    await _controller.downloadFile(f.path, dst,
        taskName: baseName(f.path));
  }

}
