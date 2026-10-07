# HandShaker Open — 开源重实现设计

> 逆向分析详见同目录 `PROTOCOL.md`(SSP 线协议,2233 行)、`HTTP_API.md`(19999 端口)、
> `SmartSyncProtocol.recovered.proto`(从 mac 二进制恢复的完整 protobuf schema,可用 protoc 编译)、
> `examples/`(可运行的 Dart 参考 codec)。

## 0. 原版架构结论

```
macOS HandShaker.app (ObjC)
  ├─ USB: 内嵌 adb → adb forward tcp:<local> → tcp:10086(命令) + tcp:19999(HTTP文件)
  │        连接时向手机安装/拉起 com.smartisanos.smartfolder(SmartFolder.apk)
  ├─ WiFi: TCP 直连手机 10086;二维码 http://t.tt/apps/handshaker?qr=1 配对
  └─ SSP: 4字节BE长度 + RSA签名信封 + protobuf消息体;握手两阶段+设备信任存储
```

关键限制:原 APK 声明 `sharedUserId="android.uid.system"`,依赖锤子系统签名获得全盘访问,
普通 Android 上不可复用 → 我们必须写自己的 Android 伴生应用。

## 1. 本项目形态

`handshaker_open/` 单 Flutter 工程,双角色:

| 角色 | 平台 | 职责 |
|---|---|---|
| Host(管理端) | macOS(先)/Windows/Linux(后)/iOS(远期) | 设备发现、配对信任、文件/相册/音乐/剪贴板管理 UI、发起 SSP 请求 |
| Agent(手机守护端) | Android | 起 SSP 服务(TCP 10086 命令 + HTTP 19999 文件流),提供文件/媒体/剪贴板数据 |

Wire 协议直接复刻原版 SSP(见 PROTOCOL.md),这样:
- 理论上可与真实锤子手机的内置服务互通(待真机验证,标注 待验证 项);
- 我们的 Agent 实现协议服务端,Host 实现客户端,两端都是开源可控的。

## 2. 代码结构(lib/)

```
lib/
  ssp/                 # 纯 Dart 协议层(不依赖 Flutter,可单独测试)
    frame.dart         # 4字节长度拆帧/组帧
    envelope.dart      # RSA签名信封(28/136偏移,signed_flag)
    handshake.dart     # 公钥握手、AES-256-CBC封装、TrustType、derivedKey
    proto/             # protoc 生成的 pb(pb_runtime via protobuf dart)
    transport.dart     # TCP socket + adb forward 通道抽象
    requests.dart      # 各 SSPRequest 操作封装
  host/                # 管理端(桌面)
    discovery/         # WiFi扫描、QR配对(t.tt URL格式)、USB adb检测
    pages/             # 欢迎/设备/照片/音乐/视频/文件/剪贴板
  agent/               # 手机守护端(Android)
    server.dart        # 10086 SSP server + 19999 HTTP server
    providers/         # MediaStore/文件系统/剪贴板数据源
```

依赖选型:`protobuf`(schema 直接编译 recovered .proto)、`pointycastle` 或 `cryptography`
(RSA SHA256/PKCS1v1.5 + AES-CBC,纯 Dart 可跨平台)、adb 通道初期直接调系统 `adb` 二进制。

## 3. 功能优先级

P0:WiFi 连接 + 握手信任 + 文件浏览/上传/下载/删除 + 剪贴板同步
P1:照片/音乐/视频库 + 缩略图 + USB(adb forward)
P2:相册同步(PhotoSync)、文件变更监听(MonitorFolder/FileChange push)、闪念胶囊
P3:iOS 端(仅网络通道,无法 adb)

## 4. 与原版的差异(有意为之)

- 不复制 `sharedUserId=system` 设计;Android Agent 用 SAF/MediaStore/`MANAGE_EXTERNAL_STORAGE`(可选)申请存储权限。
- 修正原版已发现的实现缺陷(见 HTTP_API.md §6:非法 content-range、MIME 表、decoder 粘包 bug)。
- 信任模型保留 RSA 公钥 pinning(TrustType),但密钥改 2048bit 时签名段偏移需同步调整——首版保持 1024bit 兼容。

## 5. 待验证清单(接手者必读)

见 PROTOCOL.md §11 表。最重要:现代 SSP v2 在真实新版手机系统服务上的实际表现
(此 APK v52 只含旧命令通道;现代 SSP 证据全部来自 mac 客户端二进制)。
