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

## 代码审查修复记录（dev `57ffe78`）

独立全库审查（review.md，40 项）后已修复的高危项：

- **#2 信任绕过**：Trust 记录改为 proof 校验通过后才落盘——伪造 Response02 不再能换取永久免确认。
- **#3 HTTP :19999 鉴权**：`file_path` 端点现在要求 `&token=<base64url(derivedKey)>`，即必须先完成 SSP 配对；未授权请求返回 403。⚠️ 这意味着 goal.md Phase 2 的"裸 curl file_path"验收方式已不可行——需先配对取 token；`?test` 回显端点仍开放用于端口验收。
- **#4 下载 OOM**：agent 侧下载改流式分块（含流式 md5 预扫），大文件不再整文件驻留内存。
- **#6/#7 watcher 生命周期**：monitorFolder 按路径键控，注销真正生效；session 断开自动清理其 watcher，不再向死 socket 推送。
- **#11 运行时权限**：MainActivity 启动时申请 READ_MEDIA_IMAGES/VIDEO/AUDIO（API 33+）或 READ_EXTERNAL_STORAGE，API 30+ 引导授予 all-files 访问。
- 其余：下载截断检测、上传中途截短保护、SessionQueue 超时 waiter 清理、flag3 仅限已握手 session、信任库原子写盘、legacy 缩略图数组、相册 albumId 统一、AgentService 半启动回滚。

### 仍然存在的已知缺口（诚实记录）

- **应用管理 wire 未接通**：Kotlin `getInstalledApps/uninstallApp/exportApk` 已实现但恢复版 proto 没有对应 SSP op，应用页显示"暂不支持"占位。需要协议扩展（自定义 op 或复用 :19999）才能落地。
- **FileChange(38) 推送无发送点**：相册"自动同步"目前依赖 syncOnce/周期同步；Kotlin MediaStore observer → events 通道已在，缺 agent 侧 SSPFileChange 推送转发。
- **agent 文件操作无路径沙箱**：设计如此——agent 本来就是远程文件管理器，配对握手即信任边界；风险在 host 私钥泄露后的横向扩散（host_identity.json 明文存放，#30）。
- 取消下载仍会排干 wire 上已发出的字节后报 cancelled（协议无 download-cancel op，#19）。
