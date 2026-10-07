# Goal: 完整实现 HandShaker Open — 复刻 Smartisan HandShaker 全部功能

参考产品：https://www.smartisan.com/apps/#/handshaker
项目规范：严格遵循 `docs/DESIGN.md`（架构/优先级）、`docs/PROTOCOL.md`（SSP 线协议）、`docs/HTTP_API.md`（19999 HTTP API）、`docs/SmartSyncProtocol.recovered.proto`（已恢复 protobuf schema）、`docs/examples/`（可运行 Dart codec）。

## 总目标

在本 Flutter 工程中实现一个开源版 HandShaker：Host（macOS 桌面管理端）+ Agent（Android 手机守护端），两者通过 SSP 协议互通，功能上覆盖原版 HandShaker 的全部能力。协议层为纯 Dart、可独立测试；UI 复刻原版桌面端体验（左侧分类导航 + 内容区）。

## 阶段与验收标准

### Phase 1 — SSP 协议层（`lib/ssp/`，纯 Dart，不依赖 Flutter）
DONE（commit dbd2155）
- [x] 4 字节大端长度拆帧/组帧（frame.dart），处理粘包/半包
- [x] RSA 签名信封（envelope.dart）：28/136 偏移布局、signed_flag、SHA256-PKCS1v1.5 签名/验签
- [x] 两阶段握手（client.dart）：公钥交换、AES-256-CBC derivedKey 封装、TrustType（信任/临时/拒绝）
- [x] protoc 编译 `SmartSyncProtocol.recovered.proto` 生成 Dart pb（lib/ssp/pb/）
- [x] transport.dart：TCP socket 通道 + adb forward 通道抽象
- [x] requests.dart：封装全部 SSPRequest 操作（文件列表/读写/删除/重命名、媒体库、剪贴板、相册同步、文件夹监听等 PROTOCOL.md 已枚举的命令）
- [x] **验收：**`docs/examples/` 两个 codec 可运行；协议层 dart test 覆盖帧、信封、握手、往返 echo（本机 fake server）；`flutter analyze` 0 issue

### Phase 2 — Android Agent（`lib/agent/`）
DONE Dart 层 e9f312b；Android Kotlin 层 cc08ada
- [x] SSP server 监听 TCP :10086，HTTP 文件 server 监听 :19999（复刻 HTTP_API.md 全部端点，并修正 §6 列出的原版缺陷：非法 content-range、MIME 表、decoder 粘包）— loopback 集成测试 agent_service_test.dart 覆盖
- [x] 数据源 providers：MediaStore（照片/音乐/视频分类）、文件系统（SAF/MANAGE_EXTERNAL_STORAGE 权限申请流程）、剪贴板读写、已安装应用枚举 — Dart providers + android Kotlin MainActivity 全实现
- [x] 前台服务保活 + 连接状态通知（AgentForegroundService + 常驻通知）；WiFi 下显示配对二维码（agent UI 二维码卡片，内容为 `handshaker://connect?...` — 原版 t.tt 短链格式待验证，本格式为本实现定义）
- [ ] **验收：**真机/模拟器上，curl 可命中 19999 各端点；用本工程 Host 完成握手+文件列表+上传/下载 —— Dart 层已在 loopback 集成测试全量验证（三端口+上传下载+Range）；Android 真机 `flutter build apk` + curl 冒烟 **待真机验证**（本 VM 无 Android SDK，见 docs/ANDROID_STATUS.md）

### Phase 3 — macOS Host 连接层（`lib/host/discovery/`）
DONE（commit 3fc2211）
- [x] WiFi 发现：局域网扫描 10086 端口（wifi_discovery.dart 私网段 /24 分批并发探测）+ 手动输入配对（DeviceCandidate manual）；QR 扫描由 agent 端生成二维码、host 端手输 IP 替代（桌面端扫码摄像头路径未做，待验证）
- [x] USB 连接：检测 adb 设备 → `adb forward` → 拉起/提示安装 Agent（usb_discovery.dart）
- [x] 设备信任存储（TrustedDevice 持久化，首次连接确认弹窗，可管理/吊销 — trust_store.dart + PairingPrompt 流）
- [x] 自动重连、断线提示、连接状态机（扫描中/握手/已信任/已连接 — host_controller_impl.dart + 重连测试通过）
- [x] **验收：**USB 与 WiFi 两种通道均可稳定连接同一 Agent；信任设备重连免确认 — 自动重连集成测试（杀 agent→reconnecting→重启→connected）通过；真机 USB 链路透传待真机验证（VM 无 adb 设备）

DONE（子会话分支 `devin/1791398970-host-ui` commit 7241174，merge --no-ff 并入 dev）

### Phase 4 — Host 管理 UI（`lib/host/pages/`，复刻原版交互）
- [x] 欢迎页 + 设备连接引导（USB/WiFi 两入口）— `WelcomePage`：局域网自动发现列表 + 手动输入 IP/端口 + 扫码配对指引
- [x] 文件管理器：目录树/列表双视图、面包屑导航、多选、拖拽上传/下载到 Finder、复制/粘贴/删除/重命名/新建文件夹、排序搜索、传输进度与队列（断点续传/Range）— `FilesPage` + `TransfersPage`；拖入上传用 desktop_drop，下载到选定目录
- [x] 照片页：按相册/时间分组、缩略图网格、大图预览、导入到 Mac/导出到手机、删除 — `PhotosPage`，大图弹窗经 getThumbnail 懒加载
- [x] 音乐页：按歌曲/专辑/歌手分类、封面与元信息、导入导出、双击预览播放 — `MusicPage`，双击用系统播放器打开下载副本
- [x] 视频页：缩略图 + 时长、导入导出、预览 — `VideosPage`
- [x] 应用管理：已安装应用列表（图标/版本/大小）、卸载、导出 APK — `AppsPage`；Agent 端应用列表/图标来自 Android channel，导出 APK 走 downloadFile；卸载需系统权限 → UI 提供入口，真机验证
- [x] 剪贴板页/全局剪贴板同步开关：双向文本剪贴板实时同步 — `ClipboardPage` + `ClipboardSync`（本地粘贴 → postClipboard；远端 getClipboard 轮询→粘贴本地）
- [x] **验收：**每个页面有 widget test — host_ui_test.dart 15 项 widget test 全绿（fake controller 驱动）；macOS 实际跑通拖拽传文件/相册/剪贴板 → 真机互联待验证（VM 无 Android SDK，见 docs/ANDROID_STATUS.md）；demo 模式 `--dart-define=HOST_DEMO=true` 可在无手机时浏览全部页面

### Phase 5 — 进阶能力（P2）
DONE（commit ec48c54）
- [x] 相册同步（PhotoSync）：手机新照片自动/手动同步到 Mac 指定目录 — photo_sync.dart 快照 diff + FileChange push 驱动
- [x] 文件变更监听（MonitorFolder/FileChange push）：手机侧目录变化实时推送刷新 — agent Directory.watch → monitorFolderResp push；host PushHub 消费
- [x] 传输任务中心：历史记录、并发队列、暂停/恢复/取消 — maxConcurrentTransfers 可配 + .hsdownload Range 续传 + SSPCancelRequest
- [x] 闪念胶囊（Idea Pills）同步 — 数据可得的范围内尽量实现：双向目录镜像 `idea_pills/`（无专属 wire 类型，边界见 PROTOCOL.md 标注）

### Phase 6 — 工程质量
进行中
- [x] `test/` 下协议单测 + provider 单测 + 页面 widget test + 关键路径集成测试（本机 loopback 起 agent+host）— 31 项全绿；页面 widget test 已交付：host_ui_test 15 项 + 协议/集成 31 项 = 46 项全绿
- [x] macOS entitlements（network.client/server 已配置；usb 走 adb 无需特殊权限）+ NSLocalNetworkUsageDescription；Android 权限清单完备且最小化（AndroidManifest 按需声明 + docs/ANDROID_STATUS.md）
- [x] README 更新使用说明；docs/ 中所有"待验证"项逐项标注已验证/不可验证及原因（见 docs/ANDROID_STATUS.md 与各文档「待验证」标注）
- [ ] Windows/Linux Host 兼容性检查点：host 层为纯 Dart（socket+文件 IO），无平台专属代码 —— Linux/Windows 理论上可直接构建；本 VM 为 macOS，未实机验证（阻塞项：无 Windows/Linux 构建环境，标注待验证）

## 参考手段：原版二进制逆向分析

当实现受阻或行为不确定时（协议字段语义、UI 交互细节、edge case 处理、未记录命令），允许并鼓励对原版 HandShaker 的 macOS `.app` 和 Windows 版二进制做逆向分析作为事实来源：

- macOS 版：Hopper/Ghidra/objdump 分析 `HandShaker.app` 主二进制与 Frameworks；`class-dump`/`nm` 导 ObjC 符号；`strings` 找资源/日志串；Wireshark/Charles 抓实际流量验证协议字段
- Windows 版：Ghidra/IDA/x64dbg 分析 exe/dll；同样抓包对照
- 已有产物在 `docs/`（PROTOCOL.md、recovered .proto）；新逆向发现必须回写对应文档并标注来源与置信度（已验证/推断/猜测）
- 逆向产物（反编译片段、符号表、抓包文件）放 `docs/re/` 或工作区外部路径，**不提交原版代码到 git**——只提交我们自己写的文档与重实现

## 约束

- 不在本仓库分发任何 Smartisan 原版二进制/资源/代码（clean-room 重实现）；逆向分析仅用于理解行为，实现代码必须自己写
- 依赖选型按 DESIGN.md：protobuf + pointycastle/cryptography，新增依赖须先说明理由
- RSA 首版保持 1024bit 兼容原版；不复制 `sharedUserId=system` 设计
- 每个 Phase 完成后跑 `flutter analyze` + `flutter test`，全绿才进入下一阶段
- 每完成一个 Phase 用 git commit 落地（不 push），commit message 说明该阶段交付物

## 完成定义（Completion Audit 依据）

上述所有 checklist 勾选，或明确标注"不可实现/待真机验证"并写明证据；最终 `flutter test` 全绿，macOS Host ↔ Android Agent 真机或模拟器端到端连通，照片/音乐/视频/文件/应用/剪贴板六大功能演示通过。
