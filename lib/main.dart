import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'agent_ui/agent_app.dart';

void main() {
  runApp(const HandShakerRoot());
}

/// 平台分流：Android/iOS → agent（被连接端）；macOS/Windows/Linux → host。
class HandShakerRoot extends StatelessWidget {
  const HandShakerRoot({super.key});

  bool get _isAgentPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  Widget build(BuildContext context) {
    if (_isAgentPlatform) return const AgentApp();
    return const _HostPlaceholder();
  }
}

/// Host 管理端入口占位 —— lib/host/pages/ 完整 UI 接入后替换。
class _HostPlaceholder extends StatelessWidget {
  const _HostPlaceholder();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HandShaker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B7EF7)),
      ),
      home: const Scaffold(
        body: Center(child: Text('HandShaker Host')),
      ),
    );
  }
}
