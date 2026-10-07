# HandShaker Open

HandShaker（锤子科技）的开源 clean-room 重实现：桌面 Host（macOS / Windows / Linux）↔ 手机 Agent（Android / iOS）互联，走 SSP（Smartisan Sync Protocol）私有协议。

## 功能

- 文件管理器：目录浏览、上传/下载（Range 断点续传、`.hsdownload` 续传标记）、删除/重命名/新建文件夹
- 照片 / 音乐 / 视频：按相册分组浏览、缩略图、导入导出、相册自动同步（PhotoSync）
- 应用管理：已安装应用列表、图标、卸载、导出 APK
- 剪贴板：双向文本剪贴板同步 + 变更 push
- 闪念胶囊：双向文件夹镜像同步（边界见 docs/PROTOCOL.md）
- 目录监听：手机侧文件变更实时推送（monitorFolder / FileChange push）
- 传输任务中心：并发队列、暂停/恢复/取消、历史记录
- 连接：Wi-Fi 局域网扫描 + 扫码/手动 IP + USB adb forward；信任设备免确认重连

## 架构

```
lib/
  ssp/         纯 Dart 协议层（拆帧/信封/握手/传输/请求封装/pb）
  agent/       手机端 daemon（现代 :10088 + legacy :10086 + HTTP :19999）
    providers/ MethodChannel 数据源（Android 实现见 android/ Kotlin）
  agent_ui/    手机端壳（服务开关、配对审批、配对二维码、连接指引）
  host/        桌面端连接层（发现/配对/信任/重连）+ 同步引擎 + 传输中心
    pages/     桌面管理 UI
test/          协议单测 + provider 单测 + loopback 集成测试
docs/          协议文档（PROTOCOL.md）、设计（DESIGN.md）、HTTP_API、各模块速查
```

两条 wire 协议：

| 端口 | 协议 | 说明 |
|------|------|------|
| :10086 | legacy ADBForward | 4B 大端长度 + 可选 RSA 签名请求（28/136 偏移）|
| :10088 | modern SSP v2 | host→agent 9B 头 `[sid][flag][len]`；agent→host 6B 块 `[rawSid][len]`，rawSid 高 bit = push |
| :19999 | HTTP | 文件下载（Range `bytes=N-` → 206）、`?test` 16B echo 探活 |

详见 `docs/PROTOCOL.md`（请求类型表、握手序列、push 模型、文件传输三段式）。

## 使用

环境：Flutter 3.47+ / Dart 3.13+。

```bash
flutter pub get

# 手机端（Android）
flutter run -d <android-device>      # 打开即显示 agent 壳：服务开关 + 配对二维码

# 桌面端（macOS）
flutter run -d macos                 # Host 管理界面

# 测试
flutter analyze && flutter test      # 协议 + provider + 集成测试，本机 loopback
dart run docs/examples/legacy_codec.dart   # 协议示例
dart run docs/examples/modern_codec.dart
```

连接流程（Wi-Fi）：两端同网 → 手机端开启「互联服务」→ 电脑端扫描/扫码/手输 IP → 手机端弹出配对请求选「始终信任」→ 之后免确认直连。USB：手机开 USB 调试插线，host 自动 `adb forward` 拉起。

## 验证状态

- `flutter analyze` 0 issue；`flutter test` 31 项全绿（协议、握手、信任、上下传、监听推送、相册同步、胶囊镜像、传输队列、自动重连——全部本机 loopback 真实 socket 集成测试）
- Android 真机 APK 构建与真机互联：**待真机验证**（见 `docs/ANDROID_STATUS.md`）
- Windows / Linux host 端：纯 Dart 实现无平台代码，未实机构建（待验证）

## 合规

clean-room 重实现：本仓库不包含任何 Smartisan 原版二进制、资源或代码；协议知识来自逆向分析记录（`docs/` 内文档，标注「已验证/推断/待验证」置信度）。RSA-1024 仅为与原版握手兼容。
