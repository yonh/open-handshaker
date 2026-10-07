import 'dart:async';

import 'package:flutter/material.dart';

import '../host_controller.dart';
import 'format.dart';
import 'host_shell.dart';

/// Compact live transfer strip pinned at the bottom of pages: shows active
/// and recent [TransferTask] progress from [HostController.transfersStream].
class TransfersPanel extends StatefulWidget {
  const TransfersPanel({super.key, this.maxItems = 4});

  final int maxItems;

  @override
  State<TransfersPanel> createState() => _TransfersPanelState();
}

class _TransfersPanelState extends State<TransfersPanel> {
  StreamSubscription<List<TransferTask>>? _sub;
  List<TransferTask> _tasks = [];
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _tasks = HostScope.of(context).controller.transfers;
    _sub = HostScope.of(context).controller.transfersStream.listen((l) {
      if (mounted) setState(() => _tasks = l);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tasks.isEmpty) return const SizedBox.shrink();
    final active =
        _tasks.where((t) => !t.completed && t.error == null).length;
    final shown =
        _expanded ? _tasks : _tasks.take(widget.maxItems).toList();
    return Material(
      elevation: 4,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(_expanded ? Icons.expand_more : Icons.expand_less,
                      size: 18),
                  const SizedBox(width: 6),
                  Text(active > 0 ? '传输中 $active 项' : '传输完成',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('共 ${_tasks.length} 项',
                      style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.outline)),
                ],
              ),
              for (final t in shown) TransferRow(task: t),
            ],
          ),
        ),
      ),
    );
  }
}

/// One transfer row: direction icon, name, progress bar, size / status
/// text, and optional pause / resume / cancel actions (transfer center).
class TransferRow extends StatelessWidget {
  const TransferRow({super.key, required this.task, this.showActions = false});

  final TransferTask task;

  /// 传输中心页传入 true 展示暂停/恢复/取消；底部紧凑条不展示。
  final bool showActions;

  static String statusText(TransferTask t) {
    if (t.error != null) return '失败';
    if (t.cancelled) return '已取消';
    if (t.paused) return '已暂停';
    if (t.completed) return '已完成';
    if (t.waiting) return '等待中';
    return '${fmtBytes(t.done)}/${fmtBytes(t.total)}';
  }

  static bool isActive(TransferTask t) =>
      !t.completed &&
      t.error == null &&
      !t.cancelled &&
      !t.paused &&
      !t.waiting;

  static bool isHistory(TransferTask t) =>
      t.completed || t.error != null || t.cancelled || t.paused;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final err = task.error;
    final pct = task.total == 0
        ? null
        : (task.done / task.total).clamp(0.0, 1.0);
    final finished = task.completed || task.cancelled || err != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
              task.isUpload
                  ? Icons.upload_outlined
                  : Icons.download_outlined,
              size: 16,
              color: err != null || task.cancelled
                  ? scheme.error
                  : task.completed
                      ? scheme.primary
                      : scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12)),
                if (task.remotePath.isNotEmpty)
                  Text(
                      task.isUpload
                          ? '${task.localPath} → ${task.remotePath}'
                          : '${task.remotePath} → ${task.localPath}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 10, color: scheme.outline)),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: finished || task.paused ? (err != null || task.completed ? 1 : pct) : pct,
              color: err != null || task.cancelled ? scheme.error : null,
              minHeight: 4,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 130,
            child: Text(statusText(task),
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 11, color: scheme.outline)),
          ),
          if (showActions) ..._actions(context),
        ],
      ),
    );
  }

  List<Widget> _actions(BuildContext context) {
    final c = HostScope.of(context).controller;
    Widget btn(IconData icon, String tip, VoidCallback onPressed) =>
        IconButton(
          icon: Icon(icon, size: 16),
          tooltip: tip,
          visualDensity: VisualDensity.compact,
          onPressed: onPressed,
        );
    if (task.paused) {
      return [
        btn(Icons.play_arrow, '恢复', () => c.resumeTransfer(task.id)),
        btn(Icons.close, '取消', () => c.cancelTransfer(task.id)),
      ];
    }
    if (task.waiting) {
      return [btn(Icons.close, '取消', () => c.cancelTransfer(task.id))];
    }
    if (isActive(task)) {
      return [
        btn(Icons.pause, '暂停', () => c.pauseTransfer(task.id)),
        btn(Icons.close, '取消', () => c.cancelTransfer(task.id)),
      ];
    }
    return const [SizedBox(width: 64)];
  }
}
