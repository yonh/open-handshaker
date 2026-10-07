import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'agent_ui/agent_app.dart';
import 'host/host_bootstrap.dart';
import 'host/host_controller.dart';
import 'host/pages/apps_page.dart';
import 'host/pages/demo_support.dart';
import 'host/pages/host_shell.dart';

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
    return const HostEntrypoint();
  }
}

/// Host 管理端入口：装配真实连接层（或 --dart-define=HOST_DEMO=true 的
/// 演示数据）后进入 HostApp 主界面。
class HostEntrypoint extends StatefulWidget {
  const HostEntrypoint({super.key, this.demo = _demoFromEnv});

  /// `flutter run -d macos --dart-define=HOST_DEMO=true` → 假数据演示。
  static const _demoFromEnv = bool.fromEnvironment('HOST_DEMO');

  final bool demo;

  @override
  State<HostEntrypoint> createState() => _HostEntrypointState();
}

class _HostEntrypointState extends State<HostEntrypoint> {
  HostController? _controller;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_boot());
  }

  Future<void> _boot() async {
    if (widget.demo) {
      setState(
          () => _controller = DemoHostController(api: DemoSspApi()));
      return;
    }
    try {
      final c = await buildRealHostController();
      if (mounted) setState(() => _controller = c);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null) {
      return MaterialApp(
        title: 'HandShaker',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: _error == null
                ? const CircularProgressIndicator()
                : Text('Host 初始化失败：$_error'),
          ),
        ),
      );
    }
    return HostApp(
      controller: c,
      appsSource: widget.demo ? DemoAppsSource() : WireAppsSource(),
    );
  }
}
