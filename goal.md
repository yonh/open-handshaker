# Goal: 完整实现 HandShaker Open — 复刻 Smartisan HandShaker 全部功能

参考产品：https://www.smartisan.com/apps/#/handshaker
项目规范：严格遵循 `docs/DESIGN.md`（架构/优先级）、`docs/PROTOCOL.md`（SSP 线协议）、`docs/HTTP_API.md`（19999 HTTP API）、`docs/SmartSyncProtocol.recovered.proto`（已恢复 protobuf schema）、`docs/examples/`（可运行 Dart codec）。

## 总目标

在本 Flutter 工程中实现一个开源版 HandShaker：Host（macOS 桌面管理端）+ Agent（Android 手机守护端），两者通过 SSP 协议互通，功能上覆盖原版 HandShaker 的全部能力。协议层为纯 Dart、可独立测试；UI 复刻原版桌面端体验（左侧分类导航 + 内容区）。

## 阶段与验收标准

### Phase 1 — SSP 协议层（`lib/ssp/`，纯 Dart，不依赖 Flutter）
- [ ] 4 字节大端长度拆帧/组帧（frame.dart），处理粘包/半包
- [ ] RSA 签名信封（envelope.dart）：28/136 偏移布局、signed_flag、SHA256-PKCS1v1.5 签名/验签
- [ ] 两阶段握手（handshake.dart）：公钥交换、AES-256-CBC derivedKey 封装、TrustType（信任/临时/拒绝）
- [ ] protoc 编译 `SmartSyncProtocol.recovered.proto` 生成 Dart pb
- [ ] transport.dart：TCP socket 通道 + adb forward 通道抽象
- [ ] requests.dart：封装全部 SSPRequest 操作（文件列表/读写/删除/重命名、媒体库、剪贴板、相册同步、文件夹监听等 PROTOCOL.md 已枚举的命令）
- [ ] **验收：**`docs/examples/` 两个 codec 可运行；协议层 dart test 覆盖帧、信封、握手、往返 echo（本机 fake server）；`flutter analyze` 0 issue

### Phase 2 — Android Agent（`lib/agent/`）
- [ ] SSP server 监听 TCP :10086，HTTP 文件 server 监听 :19999（复刻 HTTP_API.md 全部端点，并修正 §6 列出的原版缺陷：非法 content-range、MIME 表、decoder 粘包）
- [ ] 数据源 providers：MediaStore（照片/音乐/视频分类）、文件系统（SAF/MANAGE_EXTERNAL_STORAGE 权限申请流程）、剪贴板读写、已安装应用枚举
- [ ] 前台服务保活 + 连接状态通知；WiFi 下显示配对二维码（`http://t.tt/apps/handshaker?qr=1` 同款格式 + 设备名/密钥）
- [ ] **验收：**真机/模拟器上，curl 可命中 19999 各端点；用本工程 Host 完成握手+文件列表+上传/下载

### Phase 3 — macOS Host 连接层（`lib/host/discovery/`）
- [ ] WiFi 发现：局域网扫描 10086 端口 + QR 码扫描/手动输入配对
- [ ] USB 连接：检测 adb 设备 → `adb forward` → 拉起/提示安装 Agent（复刻原版"插线即连"体验）
- [ ] 设备信任存储（TrustedDevice 持久化，首次连接确认弹窗，可管理/吊销）
- [ ] 自动重连、断线提示、连接状态机（扫描中/握手/已信任/已连接）
- [ ] **验收：**USB 与 WiFi 两种通道均可稳定连接同一 Agent；信任设备重连免确认

### Phase 4 — Host 管理 UI（`lib/host/pages/`，复刻原版交互）
- [ ] 欢迎页 + 设备连接引导（USB/WiFi 两入口）
- [ ] 文件管理器：目录树/列表双视图、面包屑导航、多选、拖拽上传/下载到 Finder、复制/粘贴/删除/重命名/新建文件夹、排序搜索、传输进度与队列（断点续传/Range）
- [ ] 照片页：按相册/时间分组、缩略图网格、大图预览、导入到 Mac/导出到手机、删除
- [ ] 音乐页：按歌曲/专辑/歌手分类、封面与元信息、导入导出、双击预览播放
- [ ] 视频页：缩略图 + 时长、导入导出、预览
- [ ] 应用管理：已安装应用列表（图标/版本/大小）、卸载、导出 APK
- [ ] 剪贴板页/全局剪贴板同步开关：双向文本剪贴板实时同步
- [ ] **验收：**每个页面有 widget test；macOS 实际跑通拖拽传文件、相册浏览、剪贴板同步

### Phase 5 — 进阶能力（P2）
- [ ] 相册同步（PhotoSync）：手机新照片自动/手动同步到 Mac 指定目录
- [ ] 文件变更监听（MonitorFolder/FileChange push）：手机侧目录变化实时推送刷新
- [ ] 传输任务中心：历史记录、并发队列、暂停/恢复/取消
- [ ] 闪念胶囊（Idea Pills）同步 — 数据可得的范围内尽量实现，不可得则在 docs 中记录边界

### Phase 6 — 工程质量
- [ ] `test/` 下协议单测 + provider 单测 + 页面 widget test + 关键路径集成测试（本机 loopback 起 agent+host）
- [ ] macOS entitlements（network.client/server、usb）、Android 权限清单完备且最小化
- [ ] README 更新使用说明；docs/ 中所有"待验证"项逐项标注已验证/不可验证及原因
- [ ] Windows/Linux Host 兼容性检查点（能跑通则跑通，不能则记录阻塞项）

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
