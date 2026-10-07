import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../ssp/client.dart';
import '../ssp/trust_store.dart';
import 'host_controller.dart';
import 'host_controller_impl.dart';

/// 桌面 Host 端启动装配：加载（或首次生成并持久化）本机 HostIdentity，
/// 初始化设备信任库，返回真实 [HostControllerImpl]。
///
/// [supportDir] 可注入（测试用临时目录）；缺省走系统应用支持目录。
Future<HostController> buildRealHostController(
    {Directory? supportDir, String? hostName}) async {
  final dir = supportDir ?? await getApplicationSupportDirectory();
  final idFile = File('${dir.path}/host_identity.json');
  HostIdentity identity;
  try {
    identity = HostIdentity.fromJson(
        jsonDecode(await idFile.readAsString()) as Map<String, dynamic>);
  } catch (_) {
    identity = HostIdentity.generate(
      hostUuid: const Uuid().v4(),
      hostName: hostName ?? Platform.localHostname,
    );
    await idFile.parent.create(recursive: true);
    await idFile.writeAsString(jsonEncode(identity.toJson()));
  }
  return HostControllerImpl(
    identity: identity,
    trustStore: TrustStore('${dir.path}/devices.json'),
  );
}
