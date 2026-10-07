import 'package:flutter/material.dart';

import '../host_controller.dart';
import 'host_shell.dart';
import 'transfers_panel.dart';

/// Transfer center page: 队列（waiting）+ 进行（进度）+ 历史
/// （completed/cancelled/paused/失败）三段，支持暂停/恢复/取消。
class TransfersPage extends StatelessWidget {
  const TransfersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = HostScope.of(context).controller;
    return Scaffold(
      appBar: AppBar(
          title: const Text('传输列表'), automaticallyImplyLeading: false),
      body: StreamBuilder<List<TransferTask>>(
        stream: controller.transfersStream,
        initialData: controller.transfers,
        builder: (ctx, snap) {
          final tasks = snap.data ?? const <TransferTask>[];
          final queued = tasks.where((t) => t.waiting).toList();
          final active = tasks.where(TransferRow.isActive).toList();
          final history =
              tasks.where(TransferRow.isHistory).toList().reversed.toList();
          if (tasks.isEmpty) {
            return const Center(child: Text('暂无传输任务'));
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _section(context, '等待中', queued),
              _section(context, '进行中', active),
              _section(context, '历史', history),
            ],
          );
        },
      ),
    );
  }

  Widget _section(
      BuildContext context, String title, List<TransferTask> tasks) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
            child: Text('$title（${tasks.length}）',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.outline)),
          ),
          for (final t in tasks)
            Card(
              elevation: 0,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: TransferRow(task: t, showActions: true),
              ),
            ),
        ],
      ),
    );
  }
}
