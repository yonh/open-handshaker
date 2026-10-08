# Android 平台层状态

实现：`android/app/src/main/kotlin/dev/openhandshaker/handshaker_open/`
（契约见 `lib/agent/platform_contract.dart`）。

## 已实现

- `MainActivity` 三通道：`open_handshaker/providers`（MethodChannel）、
  `open_handshaker/agent_service`、`open_handshaker/events`（EventChannel）。
- providers 方法：getDeviceInfo、getPhotoLibrary / getVideoLibrary /
  getAudioLibrary（MediaStore + BUCKET 分相册、start/count 分页）、
  getThumbnail（API29+ loadThumbnail / 旧版 Thumbnails + 音频封面，
  输出 PNG 到缓存目录同时带 bytes）、listDir / fileExists / fileCount /
  createFolder / rename / delete（java.io.File + MANAGE_EXTERNAL_STORAGE）、
  getInstalledApps（PackageManager + 图标 PNG 落缓存）、uninstallApp
  （ACTION_DELETE intent）、exportApk（sourceDir 拷贝）、
  getClipboard / setClipboard。
- service 方法：startService / stopService / isServiceRunning →
  `AgentForegroundService`（低重要度常驻通知 channel
  `open_handshaker_agent`、PARTIAL_WAKE_LOCK、START_STICKY）。
- events：MediaStore ContentObserver → `{event:'mediaChange'}`；
  ClipboardManager 主剪贴板监听 → `{event:'clipboard', content}`。
- `lib/agent_ui/agent_app.dart`：服务开关、配对审批弹窗
  （拒绝/允许一次/始终信任 → `resolvePairing`）、本机 IP 展示、
  连接指引文案。
- `lib/main.dart`：Android/iOS → AgentApp；桌面 → Host 入口。

## 待真机验证（无 Android SDK/真机，静态保证）

- `flutter build apk` 未在本机跑过：VM 无 Android SDK。
  Kotlin 代码只用 `android.*` + `androidx.core`（默认模板自带），无三方依赖。
- READ_MEDIA_* / MANAGE_EXTERNAL_STORAGE 运行时申请流程：manifest 已声明，
  Dart 侧权限引导页待补（设计见 platform_contract.dart 末段）。
- MediaStore DATA 列在 Android 10+ 分区存储下对「本应用不可见文件」可能
  为空；宿主 HTTP 下载走的是真实文件路径，需 MANAGE_EXTERNAL_STORAGE 生效。
- 通知渠道中文名、前台服务保活在各家 ROM（MIUI/EMUI 等）上的杀后台策略。
- EventChannel 的剪贴板变化在部分 ROM 只有应用在前台时回调（系统限制）。

## 未实现 / 边界

- 截屏回传（ScreenCapture）：待定义 wire 类型（goal.md 边界项）。
- 开机自启（BOOT_COMPLETED）：原版的自启行为「待验证」，当前未声明。

## iOS 端说明

iOS 上 `main.dart` 按平台分流到 AgentApp：daemon 三端口可正常监听，
文件 provider 走纯 Dart 实现（沙盒目录内文件可正常被 host 浏览/上传下载）。
相册 / 剪贴板 / 已安装应用需要 Swift 侧 providers（Photos.framework /
UIPasteboard）——**未实现，待后续补齐**；这些 channel 调用会拿到
MissingPluginException，Dart 侧已按契约静默降级为空数据。
iOS 作为 Host 角色（桌面管理 UI 纯 Dart）亦可运行。

**已验证（E2E，iOS Simulator 26.5 ↔ macOS Host，commit 51f779c 后）：**
配对握手全链路（拒绝/允许一次/始终信任）、暖信任自动重连（hosts.json
持久化生效）、三端口监听 + Wi-Fi 自动发现、真实文件浏览、上传落盘字节
一致、下载回环、目录监听在 iOS 优雅降级（FileSystemEntity.watch 不支持）。
注意：iOS 模拟器内绑定的端口实际落在宿主机网络上（lsof 可见），
会与宿主机上同端口进程冲突。
