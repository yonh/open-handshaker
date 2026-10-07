# Smartisan HandShaker 线协议逆向说明

本文用于开源重实现，目标读者是需要从零编写 Dart 客户端或手机守护程序的开发者。证据来自本地 APK 的 jadx Java 源码、APK native 库和随附 mac 应用的类名、字符串及反汇编；没有把未经抓包的假设写成协议保证。

## 1. 适用版本、证据等级与偏移约定

本地 APK manifest 标明 `versionCode=52`、`versionName=52.0`（[handshaker_analysis/jadx_out/resources/AndroidManifest.xml:3-4](../handshaker_analysis/jadx_out/resources/AndroidManifest.xml#L3)）。**这里实际存在两套协议：**

| 通道 | 手机证据 | mac 证据 | 数据编码 |
|---|---|---|---|
| 旧 ADBForward 命令通道 | 当前 APK 的 `e/a`、`b`、`f`、`c`、`d` | `SFADBForward*Operation` | 4 字节长度、RSA 签名、自定义大端字段、JSON/GZIP |
| 完整 SmartSyncProtocol SSP | 当前 APK Java 注册表没有其消息实现 | `SSP*Request/Response`、`SmartSyncProtocol.pbobjc.m`、GPB descriptors | protobuf 消息及独立的会话/传输封装；参见现代 SSP 部分 |
| HTTP 文件读取 | `d/d.java`、`d/g.java` | mac HTTP URL 字符串 | HTTP/1.1 原始文件流 |

mac 同时有两套类，不能给 `SSPUploadFileRequest` 等 protobuf 消息强行赋予旧 APK 的命令编号。以下先完整说明能从 Java 确认的旧通道，再记录从 mac 原始二进制恢复的现代 SSP。跨版本手机端是否实现全部 mac 字段、具体兼容版本及实机行为，均属于**待验证**。

证据标记：**已核实**表示直接由读取/写入代码、native 指令或字段描述符得到；**推断**表示有调用关系或客户端行为支持；**待验证**表示没有对应执行代码、版本差异或反编译存在矛盾。文中使用的符号名称是为说明而命名，不冒充未混淆的 Android 原名。

源码引用缩写：

- `J/` = `handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/`。
- `MINA/` = `handshaker_analysis/jadx_out/sources/org/apache/mina/`。
- `M/` = `handshaker_analysis/jadx_out/sources/org/apache/mina/core/buffer/`。
- `D/` = `handshaker_analysis/dumps/`。

所有字节区间均为 **0 起算、右端不包含** `[start,end)`。`F` 表示完整线上帧（包括长度），`P=F[4..]` 表示去掉长度后的包体，`B` 表示剥掉协议头后的消息数据。字段偏移写成 `B+n` 时从消息数据起算；不能把它直接当成整个 TCP 帧偏移。

## 2. 旧 ADBForward 帧：精确偏移图

### 2.1 外层长度与 TCP 收包

```text
完整帧 F
┌─────────────────┬────────────────────────────────────────────────┐
│ F[0,4) I32BE=L  │ F[4,4+L) 包体 P，恰好 L 字节                  │
└─────────────────┴────────────────────────────────────────────────┘
总帧长=4+L；L不包括自己；一条TCP read不等于一帧。
```

手机响应编码器明确 `BIG_ENDIAN; putInt(result.length); put(result)`（[J/d/b.java:34-40](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/b.java#L34)）。请求 decoder 在 `prefixedDataAvailable(4)` 成功后把 **包含长度前缀** 的数组交给 `e/a`（[J/d/a.java:11-18](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/a.java#L11)），所以用户初步观察中的 `[4]`、`[133]`、`[136]` 都是 **F 偏移**，不是 P 偏移。请求大端默认值由 [M/SimpleBufferAllocator.java:12-15,82-84](../handshaker_analysis/jadx_out/sources/org/apache/mina/core/buffer/SimpleBufferAllocator.java#L12) 与 [M/AbstractIoBuffer.java:1117-1156](../handshaker_analysis/jadx_out/sources/org/apache/mina/core/buffer/AbstractIoBuffer.java#L1117) 交叉支持。

原 decoder 的缺陷：它用 `new byte[ioBuffer.limit()]` 读取全部当前缓冲区，而不是按 `4+L` 切一帧（[J/d/a.java:15-17](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/a.java#L15)）。合并两帧时可能把后一帧当成前一帧的签名数据；已消费一段后也可能出现 limit/remaining 不一致。重实现应正确累计、按 L 切分并保留尾部；与原 APK 交互时普通请求尽量一连接一请求，持久连接按完成顺序发送，避免主动流水线。是否在实机上触发该问题**待验证**。

### 2.2 非零标志：有签名的普通请求

```text
F偏移       P偏移       长度     字段
[0,4)       —           4        L=132+len(B)，大端
[4,5)       [0,1)       1        signed_flag：手机仅检查 !=0；mac写1
[5,133)     [1,129)     128      RSA signature
[133,134)   [129,130)   1        C：command/type
[134,135)   [130,131)   1        S：subtype/requestType/业务分类
[135,136)   [131,132)   1        V：Version（此mac版本写1）
[136,4+L)   [132,L)     len(B)   B：请求数据

签名覆盖：F[133,4+L) = C || S || V || B
不覆盖：长度字段、signed_flag、signature本身
```

签名切片 `[5,133)` 与校验数据 `[133,end)` 直接来自 [J/e/a/c.java:34-41](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/c.java#L34)；算法 `SHA256withRSA`，即 SHA-256 摘要的 RSA PKCS#1 v1.5 签名，**不是 RSA-PSS**。头读取与数据起点来自 [J/e/a/c.java:55-77](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/c.java#L55)。mac `exifExposeFlag:` 同时核实 `flag=1`、SHA256、RSA_sign 并拼接原始请求数据（[D/adb_transport.disasm.txt:25-33,49-75,88-98](../handshaker_analysis/dumps/adb_transport.disasm.txt#L25)）。固定 128 字节签名意味着这一路实现期待 1024 bit RSA；选择其他位数不能保持这些偏移。

`V` 在 APK 内仅保存/回显；mac 构包代码明确 append `_Version`，常量值 1（[D/adb_transport.disasm.txt:684-713](../handshaker_analysis/dumps/adb_transport.disasm.txt#L684) 附近的 MediaFetch 构包；[D/adb_transport.constants.txt:11-14](../handshaker_analysis/dumps/adb_transport.constants.txt#L11)）。因此第三个字节不是请求 ID。注意下面普通响应会交换 S/V，而 PUSH 又使用单独的固定顺序。

### 2.3 零标志：实际是公钥握手

```text
F偏移       P偏移       长度      字段
[0,4)       —           4         L=24+N
[4,5)       [0,1)       1         flag=0
[5,6)       [1,2)       1         C：mac握手命令0x0e
[6,7)       [2,3)       1         S：mac写3
[7,8)       [3,4)       1         V：mac写1
[8,24)      [4,20)      16        MD5(PKCS#1 RSAPublicKey DER)，原始摘要
[24,28)     [20,24)     4         N：AES密文长度，I32BE；手机Java不读取此值
[28,28+N)   [24,24+N)   N         AES-256-CBC密文，解密后为Base64 DER+空格
```

这张图中的前 4 字节常被遗漏：所谓“28 字节旧头”包含外层长度，所以 **P 内数据起点是24**。`d()` 确实存在从 F28 切消息数据的旧格式常量，但 [J/e/a/a.java:25-41](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a.java#L25) 对 flag=0 不走任何普通命令 parser，而是无条件创建 `b/f` 握手。这并不能证明普通业务消息可使用零标志发送。

手机实际调用 `j.a(F[8..])`（[J/e/a/c.java:29-30](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/c.java#L29)）；`j` 比较输入前16字节的 MD5，跳过4字节，再交给 native 解密（[J/utils/j.java:29-35](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/j.java#L29)）。mac握手的命令值来自 [D/adb_transport.constants.txt:15-16](../handshaker_analysis/dumps/adb_transport.constants.txt#L15)，MD5与密文长度写入来自 `D/adb_transport.disasm.txt` 的握手 `sendRequest`。完整算法、native证据与公钥生命周期见握手部分。

### 2.4 手机普通响应、心跳、PUSH 与错误

```text
普通响应 F: [L:I32BE][C:U8][V:U8][S:U8][B:bytes]
F偏移:       [0,4)   [4]   [5]   [6]   [7,4+L)
P偏移:                 0     1     2     [3,L)
L=3+len(B)，没有signed_flag，没有RSA签名。

主动PUSH F: [L:I32BE][09][category][01][JSON UTF-8]
category=1设备、2文件事件、3媒体变更；不能套普通响应的S/V名称。
```

普通响应顺序由 [J/e/a/a.java:31](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a.java#L31) 的 `(C,V,S)` 参数传递、[J/b/a.java:11-14](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/a.java#L11) 的字段保存和 [J/f/a.java:9-16](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/a.java#L9) 的序列化共同核实。**请求头 `C,S,V` 与普通响应头 `C,V,S` 不同。** PUSH 分类来自 [J/utils/f.java:16](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/f.java#L16)、[J/c/g.java:75](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/g.java#L75)、[J/utils/m.java:186](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/m.java#L186) 的常量构造。心跳与错误的确切三字节值见后面的响应表。


## 3. 旧通道完整注册表、请求与响应二进制字段

### 3.1 通用标量与字符串

请求解析器的 `getInt()` 为有符号 32 位大端，`getLong()` 为有符号 64 位大端。源码链：[J/e/a/a.java:31](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a.java#L31) 用 `IoBuffer.wrap(data)`；[M/IoBuffer.java:20,72-77](../handshaker_analysis/jadx_out/sources/org/apache/mina/core/buffer/IoBuffer.java#L20) 默认 SimpleBufferAllocator；[M/SimpleBufferAllocator.java:12-15,82-84](../handshaker_analysis/jadx_out/sources/org/apache/mina/core/buffer/SimpleBufferAllocator.java#L12) 设大端；[M/AbstractIoBuffer.java:590-607](../handshaker_analysis/jadx_out/sources/org/apache/mina/core/buffer/AbstractIoBuffer.java#L590) 委托 NIO `getInt/getLong`。

请求字符串均为 `BE32(byteLength) || rawBytes`，代码用 `new String(bytes)`，没有显式字符集（[J/e/a/a/v.java:13-15](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/v.java#L13) 等）。Android 默认字符集通常为 UTF-8，跨端实现使用 UTF-8 是合理选择，但**协议显式规定 UTF-8 待验证**。响应 JSON 明确用 UTF-8：[J/c/b.java:8](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/b.java#L8) 和 [J/f/h.java:31](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/h.java#L31)。`f/f,k,n,j` 的 `getBytes()` 同样使用平台默认编码，没有 NUL 终止符，没有额外字符串长度（除 thumbnail 条目内部有长度）。

定义列表布局：

* `StringList`: `body+0: count:I32BE`；`p0=4`；每项 `body+p_i: length_i:I32BE`，`body+(p_i+4): text_i:bytes[length_i]`，`p_(i+1)=p_i+4+length_i`。
* `IdList`: `body+0: count:I32BE`；第 `i` 项（0 起）`body+(4+8*i): id_i:I64BE`；总长度 `4+8*count`。
* parser 不校验尾部剩余数据，也没有统一拒绝负长度/超大 count；Dart 应先做边界校验，不复刻越界行为（各 parser 代码见后表）。

### 3.2 完整 type → parser → 请求 → 响应注册表

[J/e/a/a/a/a.java:6-7](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/a/a.java#L6) 定义 factory；[J/e/a/a/a/b.java:13-26](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/a/b.java#L13) 遍历 enum 填表并对未知命令抛 `a/c`。实际 enum 在 `e/a/a/a.java`，不在更深的 `e/a/a/a/*.java` 中。

| C（十进制/hex） | enum 原名 | parser `e/a/a/` | request `b/` | response | 注册依据 |
|---|---|---|---|---|---|
| 1 / 01 | OLD_THUMBNAIL | v | j | f/j | [J/e/a/a/a.java:33-46](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/a.java#L33)；[J/b/j.java:229](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/j.java#L229) |
| 2 / 02 | FETCH | p | d | f/d | [J/e/a/a/a.java:49-63](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/a.java#L49)；[J/b/d.java:66](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/d.java#L66) |
| 3 / 03 | GET | q | e | f/e | [J/e/a/a/a.java:83-97](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/a.java#L83)；[J/b/e.java:14](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/e.java#L14) |
| 4 / 04 | TERMINATE | x | l | f/l | [J/e/a/a/a.java:66-80](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/a.java#L66)；[J/b/l.java:13](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/l.java#L13) |
| 5 / 05 | KEEP_ALIVE | t | h | f/e（经 b/e） | [J/e/a/a/a.java:100-114](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/a.java#L100)；[J/b/h.java:21](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/h.java#L21) |
| 6 / 06 | HEARTBEAT | r | g | d/a/b | [J/e/a/a/a.java:117-131](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/a.java#L117)；[J/b/g.java:13](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/g.java#L13) |
| 7 / 07 | NEW_FETCH | u | i | f/i | [J/e/a/a/a.java:134-148](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/a.java#L134)；[J/b/i.java:35](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/i.java#L35) |
| 8 / 08 | THUMBNAIL | y | m | f/m | [J/e/a/a/a.java:151-165](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/a.java#L151)；[J/b/m.java:134](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/m.java#L134) |
| 10 / 0A | WATCH | z | n | f/n | [J/e/a/a/a.java:168-182](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/a.java#L168)；[J/b/n.java:19,33](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/n.java#L19) |
| 11 / 0B | DELETE | n | b | f/b | [J/e/a/a/a.java:185-199](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/a.java#L185)；[J/b/b.java:23](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/b.java#L23) |
| 12 / 0C | SCEN（保留源码拼写） | w | k | f/k | [J/e/a/a/a.java:202-216](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/a.java#L202)；[J/b/k.java:22,29](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/k.java#L22) |
| 13 / 0D | EXIT（实际 EXIF） | o | c | f/c | [J/e/a/a/a.java:219-233](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/a.java#L219)；[J/b/c.java:21,25](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/c.java#L21) |

`C=9` **不注册请求**，是服务端主动 push；见本章PUSH消息表。`C=0` 未注册。mac公钥握手使用 **C=14/0x0E**（[D/adb_transport.constants.txt:15](../handshaker_analysis/dumps/adb_transport.constants.txt#L15)），不属于上面的注册表：signFlag=0时直接走 `e/a/c → b/f → f/f`，不查factory；其C/V/S从未签名输入取出（[J/e/a/c.java:19-20](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/c.java#L19)）。因此14不能标作普通“未知type”，而非零签名flag的14仍会触发unsupported command。

### 3.3 每个请求的数据布局及语义

正常有签名请求body从**整个帧偏移136**开始，等价于去除长度后的**packet偏移132**；表中`body+0`即该位置。普通响应body从整个帧偏移7 / packet偏移3开始；握手有专门信封，不混用此body定义。

| C | 数据布局 | 字段语义 / S | 精确读取依据 |
|---|---|---|---|
| 1 | StringList | 绝对文件路径列表；S=1 image，2 video，3 audio artwork | [J/e/a/a/v.java:10-17](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/v.java#L10)；[J/b/j.java:78-95,127-132,217](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/j.java#L78) |
| 2 | 空 或 `body+0 filterId:I32BE`（4 字节） | 无字节则 filterId=0；album_id 或 bucket_id 筛选；详见 subtype 表 | [J/e/a/a/p.java:8-9](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/p.java#L8)；[J/b/d.java:23-61](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/d.java#L23) |
| 3 | 空（不读 body） | 获取设备信息；S 未使用 | [J/e/a/a/q.java:8-9](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/q.java#L8)；[J/b/e.java:14](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/e.java#L14) |
| 4 | 空 | 返回终止 ACK；是否终止当前任务由 session wrapper 处理 | [J/e/a/a/x.java:8-9](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/x.java#L8)；[J/b/l.java:12-18](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/l.java#L12) |
| 5 | 空 | 设置持久会话并返回设备信息 | [J/e/a/a/t.java:8-9](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/t.java#L8)；[J/b/h.java:15-21](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/h.java#L15) |
| 6 | 空 | 忽略输入 C/S，取 V 构造 `g(V)`，强制输出 C=6,S=2,V=输入 V | [J/e/a/a/r.java:8-9](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/r.java#L8)；[J/b/g.java:7-13](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/g.java#L7)；[J/d/a/b.java:13-15](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/a/b.java#L13) |
| 7 | 空 | S=1 图片库，2 音频库，3 视频库；其他 S 无结果（空 body） | [J/e/a/a/u.java:8-9](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/u.java#L8)；[J/b/i.java:19-35](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/i.java#L19) |
| 8 | IdList | S=1 image media ID，2 video media ID，3 album art ID | [J/e/a/a/y.java:10-15](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/y.java#L10)；[J/b/m.java:62-72,122](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/m.java#L62) |
| 10 | StringList | S=1 注册；其他 S 撤销；路径映射到文件/Media/DeviceInfo observer | [J/e/a/a/z.java:12-22](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/z.java#L12)；[J/b/n.java:21-31](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/n.java#L21) |
| 11 | IdList | 删除 MediaStore.Files 的 `_id`；不是按路径 unlink | [J/e/a/a/n.java:10-15](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/n.java#L10)；[J/b/b.java:21-23](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/b.java#L21)；[J/utils/p.java:264-289](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L264) |
| 12 | StringList | 提交扫描路径到 SmartfolderMediaScannerService，不是上传文件内容 | [J/e/a/a/w.java:12-22](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/w.java#L12)；[J/b/k.java:24-29](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/k.java#L24) |
| 13 | `body+0 pathByteLength:I32BE`，`body+4 path:bytes[length]` | 读取路径的 EXIF 属性；enum EXIT 与行为不一致 | [J/e/a/a/o.java:9-11](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/o.java#L9)；[J/b/c.java:21-25](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/c.java#L21)；[J/utils/p.java:233-248](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L233) |
| 未签名握手 b/f | `F[8,24):MD5(DER)`；`F[24,28):I32BE(AES密文长)`；`F[28,end):AES-CBC密文` | 标志=0；Java把 F[8,end) 交 utils/j，JNI解密后 trim、Base64解码、MD5检查，再读PKCS#1 DER RSA | [J/e/a/c.java:29-30](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/c.java#L29)；[J/utils/j.java:29-34](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/j.java#L29)；密文长度与AES模式见 native/握手章节 |

WATCH/SCEN 的 count=0 会令 parser 返回 null，而不是产生 ACK（[J/e/a/a/z.java:19-20](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/z.java#L19)、[J/e/a/a/w.java:19-20](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/w.java#L19)）。FETCH 若 body 有 1～3 字节，`hasRemaining()` 为真随后 `getInt()` 越界；合法值只有 0 或至少 4 字节，剩余字段并未读取（[J/e/a/a/p.java:9](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/p.java#L9)）。

FETCH subtype：[J/b/d.java:25-61](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/d.java#L25) 为直接映射，utility 查询语义为下表。

| S | utility | 实际语义 | 依据 |
|---:|---|---|---|
| 1 | p.a(filterId) | 音频曲目，可按 album_id 筛选 | [J/utils/p.java:134-147](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L134) |
| 2 | p.a() | 音频专辑 | [J/utils/p.java:122-126](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L122)；audio albums URI [J/utils/p.java:37](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L37) |
| 3 | — | 不支持，抛 a/c | [J/b/d.java:32-34](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/d.java#L32) |
| 4 | p.b() | 音频所在 bucket 分组 | [J/utils/p.java:292-296](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L292) |
| 5 | p.c() | 图片 bucket 分组 | [J/utils/p.java:342-346](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L342) |
| 6 | p.d() | 视频 bucket 分组 | [J/utils/p.java:370-374](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L370) |
| 7 | p.b(filterId) | 文件库中 bucket_id=filterId 的条目 | [J/utils/p.java:304-308](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L304) |
| 8 | p.c(filterId) | 图片 bucket_id=filterId | [J/utils/p.java:354-358](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L354) |
| 9 | p.d(filterId) | 视频 bucket_id=filterId | [J/utils/p.java:382-386](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L382) |
| 10 | p.f() | 缓存图片项数组 | [J/utils/p.java:416-419](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L416) |
| 11 | p.i() | 缓存视频项数组 | [J/utils/p.java:436-439](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L436) |
| 12 | p.j() | DownloadManager 成功下载项数组 | [J/utils/p.java:447-451,621-622](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L447) |

### 3.4 所有响应布局

以下 body 起点均为整个响应帧 `F+7`，包体内 `+3`；`L` 是 body 字节数，外层长度值为 `3+L`。常规响应头 C/V/S 与对应请求的字段值一致，但位置为 `[C,V,S]`；心跳头有特例。

#### 单字节 ACK（f/b、f/l）

| 类 / 请求 | body 偏移 | 类型 | 意义与依据 |
|---|---:|---|---|
| f/b / DELETE | 0 | U8 | 1 表示 MediaStore delete 返回 >0；0 否；[J/b/b.java:21-23](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/b.java#L21)，序列化 [J/f/b.java:18-20](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/b.java#L18) |
| f/l / TERMINATE | 0 | U8 | 固定 1；[J/f/l.java:10-12,18-20](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/l.java#L10) |

#### 无长度字符串/JSON（f/h 及子类）

| 响应类 | data 布局 | 编码 / 说明 | 依据 |
|---|---|---|---|
| f/h（普通） | `body+0 bytes[L]` | 非空字符串的 UTF-8，空/null 无字节 | [J/f/h.java:27-36](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/h.java#L27)；[J/c/b.java:8](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/b.java#L8) |
| f/c / EXIT-EXIF | 同 f/h | UTF-8 JSON object，默认不压缩 | [J/f/c.java:5-6](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/c.java#L5)；[J/utils/p.java:239-248](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L239) |
| f/d / FETCH | 同 f/h | UTF-8 JSON array；查询无条目/null 返回空 body，不是 `[]` | [J/f/d.java:5-6](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/d.java#L5)；[J/utils/p.java:155-187](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L155) |
| f/e / GET、KEEP_ALIVE | 同 f/h | UTF-8 设备 JSON object | [J/f/e.java:5-6](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/e.java#L5)；[J/b/e.java:14](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/e.java#L14)；[J/utils/e.java:81-99](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/e.java#L81) |
| f/i / NEW_FETCH | `body+0 gzipBytes[L]` | 对 UTF-8 JSON 进行 GZIP，而非 zlib/裸 deflate；无单独原长字段 | [J/f/i.java:5-6](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/i.java#L5)；[J/f/h.java:31-35](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/h.java#L31)；[J/utils/i.java:87-99](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/i.java#L87) |

设备 JSON 键完整枚举：`version, device_name, device_owner, sdcard_root, file_num, picture_number, audio_number, video_number, download_number, screen_locked, disk_usage, battery_level`（[J/utils/e.java:84-95](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/e.java#L84)）。screen_locked 是整数 0/1；其他 numeric 字段最终来自 Java long/int。字段 nullable 与缺失应按 Android JSONObject 行为处理，勿设为固定二进制结构。

NEW_FETCH 解压后的对象：`all_item`（项目对象数组）、`all_group`（分组代表项数组）、`item_with_group`（数组，每项 `id` 与 `list`）；[J/utils/p.java:193-224,252-260](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L193)。S=1 按 bucket_id，2 按 album_id，3 按 bucket_id（[J/utils/p.java:459-468](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L459)）。JSON 对象列名来自 Cursor，没有固定字段表，audio projection 在 [J/utils/m.java:32](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/m.java#L32)。图片/视频请求查询 projection=null，JSON 列集合取决于系统 MediaStore schema，待目标手机验证（[J/utils/p.java:459,467,155-185](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L459)）。

#### 原样 ASCII/平台默认字符串（f/f、f/k、f/n）

| 类 / 请求 | body 布局 | 意义 | 依据 |
|---|---|---|---|
| f/f / 公钥握手 | `body+0 bytes[L]` | 失败字面值 `failed`；成功是 `Base64(RSA/ECB/PKCS1Padding(clientPublicKey, ASCII "ok"))`，Base64 flag=0，可能带换行，不要使用 trim 后长度来拆帧 | [J/f/f.java:18-20](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/f.java#L18)；[J/b/f.java:19-28](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/f.java#L19) |
| f/k / SCEN | `body+0 one ASCII char` | Y 已提交扫描；N 请求列表为 null | [J/f/k.java:18-20](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/k.java#L18)；[J/b/k.java:21-29](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/k.java#L21) |
| f/n / WATCH | `body+0 one ASCII char` | Y 完成注册/撤销；N 尚无 push session | [J/f/n.java:18-20](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/n.java#L18)；[J/b/n.java:18-33](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/n.java#L18) |

#### 路径缩略图 f/j（OLD_THUMBNAIL）

`body+0 count:I32BE`。令第 `i` 项起点 `p_i`，`p_0=4`：

| 条目偏移 | 字段 | 类型 / 大小 |
|---:|---|---|
| p_i | failure | U8；0 有图，1 缺失/空 |
| p_i+1 | pathByteLength | I32BE，4 |
| p_i+5 | path | 平台默认编码 bytes[N] |
| p_i+5+N | imageByteLength | I32BE，4 |
| p_i+9+N | image | bytes[K]，通常 JPEG |

`p_(i+1)=p_i+9+N+K`。序列化每个字段的代码 [J/f/j.java:21-40](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/j.java#L21)。条目顺序为 Map.keySet 迭代顺序，**不得假设等于请求顺序**（[J/f/j.java:24](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/j.java#L24)、[J/b/j.java:27,203](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/j.java#L27)）。缩略图生成倾向 200×200、JPEG quality=86（[J/b/j.java:52,72](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/j.java#L52)），格式从生成器证实，不另设 width/height/mime 字段。

#### ID 缩略图 f/m（THUMBNAIL）

`body+0 count:I32BE`，第 `i` 项起点 `p_i`，`p_0=4`：

| 条目偏移 | 字段 | 类型 / 大小 |
|---:|---|---|
| p_i | failure | U8；0 有图，1 空 |
| p_i+1 | mediaId/albumId | I64BE，8 |
| p_i+9 | imageByteLength | I32BE，4 |
| p_i+13 | image | bytes[K] |

`p_(i+1)=p_i+13+K`。[J/f/m.java:22-39](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/m.java#L22)；Map 迭代不保证顺序（[J/f/m.java:25](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/m.java#L25)）；JPEG quality=86（[J/b/m.java:80-82](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/m.java#L80)）。没有请求尺寸字段。

**反编译异常，待验证：** [J/b/j.java:187-192](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/j.java#L187) 与 [J/b/m.java:95-98](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/m.java#L95) 的反编译 finally 似乎会用空数组覆盖成功图片；不能由此断言实际 APK 永远无缩略图，需 smali/字节码或实机核对。`b/j.java:159-160` 对 embeddedPicture 非空却传 null 解码，也应核对字节码。线字段结构直接来自序列化器，不受这些疑点影响。

#### 心跳 d/a/a 与 d/a/b

整个响应格式仍是 `BE32(3)||threeBytes`，body 长度 0。

* 手机主动心跳：`[06,01,01]`，构造 `super(6,1,1)`，[J/d/a/a.java:8-16](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/a/a.java#L8)。
* 默认心跳响应：`[06,01,02]`，[J/d/a/b.java:9-10,21-22](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/a/b.java#L9)。
* 对已解析对端心跳：`[06,V,02]`，[J/e/a/a/r.java:9](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/r.java#L9)、[J/b/g.java:7-13](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/g.java#L7)、[J/d/a/b.java:13-15,21-22](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/a/b.java#L13)。
* KeepAliveMessageFactory 把 `d/a/b` 或 `b/g` 视为 response，不读取 S；`isRequest` 恒 false，`getResponse` 恒 null（[J/d/a/c.java:18-33](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/a/c.java#L18)）。勿根据第三字节单独推断 framework 会回应手机请求。

#### 错误 a/*

| 类 | 语义 | 可序列化形态 / 处理 |
|---|---|---|
| a/a | Internal logic error | RuntimeException；encoder 重新抛异常，不定义错误 body；[J/a/a.java:4-6](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/a/a.java#L4)，[J/d/b.java:19-26](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/b.java#L19) |
| a/b | RSA 错误基类 | 三个 byte 无初始化赋值，默认全 0，`a()` 返回 `[a,c,b]=[00,00,00]`；[J/a/b.java:5-14](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/a/b.java#L5) |
| a/c | Unsupported command/operation | factory 抛出后通常关闭连接；[J/a/c.java:4-10](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/a/c.java#L4)、[J/e/a/a/a/b.java:25-26](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/a/b.java#L25)、[J/d/c.java:32-34](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/c.java#L32) |
| a/d | 公钥不存在 | 若交给 encoder，返回 `BE32(3)\|\|00 00 00`；[J/a/d.java:4-6](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/a/d.java#L4)、[J/d/b.java:20-21,34-38](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/b.java#L20) |
| a/e | Command terminated | RuntimeException；[J/a/e.java:4-6](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/a/e.java#L4)；没有专用 wire enum |
| a/f | RSA signature verify failed | 若交给 encoder，与 a/d 同为 `BE32(3)\|\|00 00 00`，二者在线不可区分；[J/a/f.java:4-6](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/a/f.java#L4)、[J/d/b.java:23-26,34-38](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/b.java#L23) |

从现有 decoder [J/d/a.java:17](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/a.java#L17) 看，验签异常直接抛出，不包装为正常消息，handler [J/d/c.java:15-20](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/c.java#L15) 记录并关闭。故上述 a/d、a/f 的三零帧是 encoder **可处理的格式**，不应保证每次验签失败一定会收到该帧。

### 3.5 未注册请求 C=9 的 push 消息

都使用 `f/h` 未压缩 UTF-8 JSON，没有额外长度字段；外层长度遵守通用响应规则。

| 三字节响应头 | body | 依据 |
|---|---|---|
| 09 01 01 | 设备 JSON | [J/utils/f.java:16](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/f.java#L16)；[J/utils/e.java:84-95](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/e.java#L84) |
| 09 02 01 | 单个文件事件 JSON | [J/c/g.java:75](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/g.java#L75) |
| 09 03 01 | 媒体变更 JSON | [J/utils/m.java:186](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/m.java#L186) |

注意 push 构造参数的位置不同：设备/文件/媒体推送分别将第二响应字节设 1/2/3，第三响应字节固定 1。普通请求返回的第二响应字节是输入 version，而 push 第二字节是事件类别；需按 C=9 的专门头处理（[J/utils/f.java:16](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/f.java#L16)、[J/c/g.java:75](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/g.java#L75)、[J/utils/m.java:186](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/m.java#L186)）。
### 3.6 与mac类名的精确交叉对照

下表旧命令的mac常量值来自实际Mach-O读取，不是按SSP类名猜数字。现代protobuf type号独立于旧C值。

| 旧C | APK请求 | 对应mac ADB类/实现 | 现代SSP功能名称（独立消息，完整schema见第8章） |
|---:|---|---|---|
| 1 | b/j，路径缩略图 | SFADBForwardFileThumbnailOperation；CMD_File_Thumbnail=1（[D/adb_transport.constants.txt:13](../handshaker_analysis/dumps/adb_transport.constants.txt#L13)） | SSPGetThumbnailRequest/Response（type3，文件对象而非旧路径列表） |
| 2 | b/d，旧FETCH | 未在现有mac常量发现专用活动类，待验证 | 音频/图片/视频库仅作功能对照，不共享数字 |
| 3 | b/e，设备信息 | SFADBForwardDeviceInfoOperation（[D/adb_transport.constants.txt:9](../handshaker_analysis/dumps/adb_transport.constants.txt#L9)） | SSPGetDeviceInfoRequest/Response，type2 |
| 4 | b/l，终止 | SFADBForwardOperation的CMD_Close（[D/adb_transport.constants.txt:4](../handshaker_analysis/dumps/adb_transport.constants.txt#L4)） | SSPCancelRequest/type36；取消模型不同 |
| 5、6、10 | b/h、b/g、b/n | SFADBForwardKeepAliveOperation；Keep_Alive、Heart_Beat、File_Watch（[D/adb_transport.constants.txt:17-20](../handshaker_analysis/dumps/adb_transport.constants.txt#L17)） | SSPHeartBeatRequest/type1、SSPMonitorFolderRequest/type23 |
| 7 | b/i，NEW_FETCH | SFADBForwardMediaFetchOperation（[D/adb_transport.constants.txt:11](../handshaker_analysis/dumps/adb_transport.constants.txt#L11)；[D/adb_transport.disasm.txt:684-713](../handshaker_analysis/dumps/adb_transport.disasm.txt#L684)） | SSPGetPhoto/Audio/VideoLibrary，type4/6/5 |
| 8 | b/m，ID缩略图 | SFADBForwardMediaThumbnailOperation（[D/adb_transport.constants.txt:21](../handshaker_analysis/dumps/adb_transport.constants.txt#L21)） | SSPGetThumbnailRequest/type3 |
| 11、12 | b/b删除ID、b/k媒体扫描 | SFADBForwardUpdateMediaOperation；CMD_DeleteMedia=11、CMD_UpdateMedia=12（[D/adb_transport.constants.txt:6-8](../handshaker_analysis/dumps/adb_transport.constants.txt#L6)） | SSPDeleteFile/type19、SSPUpdateFile/type40，字段及效果不能等同 |
| 13 | b/c，读取EXIF | SFADBForwardExifFetchOperation；CMD_Exif_Fetch=13（[D/adb_transport.constants.txt:2](../handshaker_analysis/dumps/adb_transport.constants.txt#L2)） | 没有同名现代EXIF request；不能对应SSPQuitRequest/type35 |
| 14（仅flag0） | b/f，RSA公钥握手 | SFADBForwardHandshakeOperation（[D/adb_transport.constants.txt:15](../handshaker_analysis/dumps/adb_transport.constants.txt#L15)；[D/adb_transport.disasm.txt:151-172](../handshaker_analysis/dumps/adb_transport.disasm.txt#L151)） | SSPHandShakeRequest01/02，type31/33；两阶段信任不同 |

mac类名列表另见 [D/ssp_classes.txt:1-15](../handshaker_analysis/dumps/ssp_classes.txt#L1)。当前APK的 `b/*` 没有目录创建/重命名、SSP原生上传或剪贴板实现；这些功能的真实macprotobuf字段已恢复在第8章，实际macoperation行为见第9章。


## 4. 旧通道公钥交换与信任边界

### 4.1 本 APK 可实现的 RSA 公钥握手

#### 未签名格式并不意味着可执行任意旧命令

`F[4]==0` 时，解析流程 **不走命令注册表**，而是调用 `a(b(bArr),bArr)`，由 `e/a/c.a` 无条件创建 `b/f`；`b(bArr)` 从 `F[8,end)` 向 `utils/j` 尝试导入公钥（[J/e/a/a.java:25–41](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a.java#L25)；[J/e/a/c.java:19–20,29–31](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/c.java#L19)）。所以 `e/a/c.d` 存在 unsigned payload 起点 `28`，只能证明该辅助函数的布局分支，不能证明本 APK 允许 unsigned 普通请求（[J/e/a/c.java:55–57](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/c.java#L55)）。

mac `SFADBForwardHandshakeOperation` 对应这种旧 ADB RSA 公钥握手；它的 CMD 常量为 `0x0e`，Version 为 `1`（[D/adb_transport.constants.txt:15–16](../handshaker_analysis/dumps/adb_transport.constants.txt#L15)）。这是一个不在 signed 类型注册表中执行的特殊入口。

#### 精确公钥握手帧

| F 偏移 | B 偏移 | 长度 | 意义 | 证据 |
|---|---:|---:|---|---|
| 0–3 | 无 | 4 | `24+ciphertext.length` 的 BE 长度 | 同外层规则，body 从 4 开始 |
| 4 | 0 | 1 | `0` 未签名 | [J/e/a/c.java:14–16](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/c.java#L14) |
| 5 | 1 | 1 | CMD `0x0e` | [D/adb_transport.constants.txt:15](../handshaker_analysis/dumps/adb_transport.constants.txt#L15)；[D/adb_transport.disasm.txt:151](../handshaker_analysis/dumps/adb_transport.disasm.txt#L151) |
| 6 | 2 | 1 | 功能选择 `0x03` | mac handshake sendRequest；导入手机后用于 response 第三头字节 |
| 7 | 3 | 1 | Version `0x01` | [D/adb_transport.constants.txt:16](../handshaker_analysis/dumps/adb_transport.constants.txt#L16) |
| 8–23 | 4–19 | 16 | DER PKCS#1 公钥 bytes 的 MD5 原始摘要 | [J/e/a/c.java:30](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/c.java#L30)；[J/utils/j.java:29–34](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/j.java#L29)；[J/utils/l.java:8–12](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/l.java#L8) |
| 24–27 | 20–23 | 4 | AES 密文长度，u32be；手机 `utils/j` 实际跳过而未读取 | [J/utils/j.java:30](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/j.java#L30)；mac [D/adb_transport.disasm.txt:387–407](../handshaker_analysis/dumps/adb_transport.disasm.txt#L387) |
| 28… | 24… | 可变，16 整倍数 | AES-256-CBC 加密的 Base64 PKCS#1 RSA 公钥文本 | [J/utils/j.java:30](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/j.java#L30)；native 证据见下 |

```text
F   0        4   5    6   7   8                    24       28
    +--------+---+----+---+---+--------------------+--------+------------------
    | u32 BE |00 |0e  |03 |01 |MD5(DER public key) |u32 BE n|AES ciphertext…
    +--------+---+----+---+---+--------------------+--------+------------------
                              <-----16 bytes----->          <----n bytes---->
```

手机计算：`raw=F[8,end)`；摘要 `raw[0,16)` 等于 `F[8,24)`；`raw[20,end)` 等于 `F[28,end)` 进入 native 解密。所谓“8 后全部公钥”和“28 起 payload”不存在矛盾，`8` 是公钥封装结构起点，`28` 是封装里密文起点；中间依次是 16 字节 MD5 和 4 字节密文长度（[J/e/a/c.java:30](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/c.java#L30)；[J/utils/j.java:29–34](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/j.java#L29)，mac 上述长度写入代码）。

手机解密结果按 UTF-8 创建字符串后 `trim()`，再 Base64 解码，对 DER 做 MD5 检验。Base64 解码类可由标准 alphabet 和解码方法确认（[J/utils/j.java:30–32](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/j.java#L30)；源码 [handshaker_analysis/jadx_out/sources/org/a/b/a/a.java:10–17](../handshaker_analysis/jadx_out/sources/org/a/b/a/a.java#L10)、`org/a/b/a/b.java:9,68`）。DER 对象必须是两个 INTEGER 构成的 SEQUENCE；取第一个 INTEGER 为 modulus、第二个为 exponent，随后构造 `RSAPublicKeySpec`（[J/utils/j.java:33–35](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/j.java#L33)；[handshaker_analysis/jadx_out/sources/org/a/a/a/a.java:17–24,34–40](../handshaker_analysis/jadx_out/sources/org/a/a/a/a.java#L17)）。因此用 PKCS#1 `RSAPublicKey` DER；不要把 SubjectPublicKeyInfo `PUBLIC KEY` DER 直接 Base64 填入。

#### JNI `parseIoBuffer` 已核实的 AES 算法

Java 仅声明 native（[J/utils/C.java:5–9](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/C.java#L5)）；实际反汇编来自 `handshaker_analysis/jadx_out/resources/lib/x86_64/libsmartfolder.so`，导出 `Java_com_smartisanos_smartfolder_utils_C_parseIoBuffer` 地址 `0x2e10`。为稳定引用行号，完整 `objdump -d` 保存为 `D/libsmartfolder_x86_64.disasm.txt`。

```text
key = 28 e3 ee 32 b0 de 27 ef 6b c2 97 92 05 4e f9 73
      9c e8 e8 7b b4 95 f2 ea 0d 72 d4 f4 f4 0b 3b de
iv  = 2b 9e 34 d4 e1 d9 08 89 94 93 9e c4 e3 e9 60 c5
```

上述固定 key 在栈 `rbp-0x60…-0x41` 写入，IV 在 `rbp-0x70…-0x61` 写入（[D/libsmartfolder_x86_64.disasm.txt:2524–2573](../handshaker_analysis/dumps/libsmartfolder_x86_64.disasm.txt#L2524)）；key schedule `kysp_1` 入参 bits=`0x100=256`，随后调用 `dtcc_5` 解密（同文件 `2520–2521,2574–2581`）。mac 导出的常量字节完全一致（[D/adb_transport.constants.txt:23–24](../handshaker_analysis/dumps/adb_transport.constants.txt#L23)），mac 调用 `_etcc_4` 加密（[D/adb_transport.disasm.txt:340–372](../handshaker_analysis/dumps/adb_transport.disasm.txt#L340)）。

这不是仅按函数名猜 AES-CBC：`dtcc_5` 检查 `n & 15 == 0`；每 16 字节调用 `dt_3` 后 XOR 初始 IV/上一块密文，并将原输入密文作为下一轮 chaining 值（[D/libsmartfolder_x86_64.disasm.txt:2425–2433,2449–2472](../handshaker_analysis/dumps/libsmartfolder_x86_64.disasm.txt#L2425)）。`dt_3` 使用 `InvShiftRows/InvSubBytes/AddRoundKey/InvMixColumns` 完成 AES 逆轮（同文件 `2267–2285` 等）。native 原样返回输入长度的解密 bytes，不删 padding（同文件 `2582–2596`；Java后续 `trim` 见 [J/utils/j.java:30](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/j.java#L30)）。mac 从 PKCS#1 PEM 的 Base64 主体移除换行，添加 ASCII 空格 `0x20` 直到长度为32的整倍数；相关CFString常量直接读取为换行、空字符串、空格（[D/adb_transport.constants.txt:25–27](../handshaker_analysis/dumps/adb_transport.constants.txt#L25)；[D/adb_transport.disasm.txt:186,211,241–246](../handshaker_analysis/dumps/adb_transport.disasm.txt#L186)）。这不是 AES/PKCS7Padding。对于常见1024位RSA public key，Base64文本188字节、4个空格padding后192字节密文。

#### 公钥生命周期与成功证明

`utils/j` 公钥是单个 static `PublicKey a`，`a(byte[])` 为 synchronized，若已有公钥就直接返回它，不校验新请求 MD5/密文，也不替换（[J/utils/j.java:15–26,35](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/j.java#L15)）。手机端没有按设备、TCP session 或 host UUID 建多个公钥的逻辑；这些文件里也没有持久化、复位、私钥生成或手机公钥返送。成功握手只是主机向手机提供主机 RSA 公钥；主机私钥仍由主机持有。

握手成功响应：手机用此公钥、`RSA/ECB/PKCS1Padding` 加密 ASCII `ok`，再 `Base64.encodeToString(ciphertext,0)` 输出字符串；失败发送 `failed`（[J/b/f.java:18–28](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/f.java#L18)）。`Base64.DEFAULT` 可含换行，Dart 应允许 Base64 空白。主机 Base64 解码后以匹配私钥执行 RSA PKCS#1 v1.5 解密，确认明文是 `ok`。握手 request `b/f.b` 不把 session 标成 keep-alive（[J/b/f.java:32–35](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/f.java#L32)），响应发送完成后通常关闭该 TCP connection（[J/d/c.java:50–56](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/c.java#L50)）。

因公钥是进程级 single slot，一个不同密钥的第二主机即使收到握手响应，也只能拿到使用旧公钥加密的 `ok`，后续签名也会被旧公钥验证。不能将 `j.a(newKey)!=null` 当作“新 key 已被安装”。服务销毁时 `Process.killProcess`，所以服务结束后新进程会重置 static key（[J/AdbForwardService.java:89–96](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/AdbForwardService.java#L89)）。关闭单个连接不会删除公钥（[J/c/a.java:27–30](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/a.java#L27) 仅删session和取消任务）。

unsigned请求触发 Smartisan 系统更新提示有明确条件：brand=`smartisan` 且 release 与 `2.5.8` 作字符串比较小于零，随后仍执行公钥握手；这是系统安全提示，不是 TrustType 或用户授权消息（[J/e/a/a.java:35–41](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a.java#L35)；[J/AdbForwardService.java:100–107](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/AdbForwardService.java#L100)）。

#### 推荐文字消息序列

1. 主机保存/生成 RSA-1024 私钥；将 PKCS#1 公钥 DER 做 Base64、既定 padding 和 AES-256-CBC 封装。
2. 主机打开手机 `10086`（USB 情况通常经 ADB forward），发送 unsigned `[00,0e,03,01] + MD5 + u32be(ciphertext.length) + ciphertext`。
3. 手机首次导入成功，把公钥放入 static slot；手机返回 `u32be(3+ascii.length) + [0e,01,03] + Base64(RSA_public_encrypt("ok"))`，并结束此 socket。
4. 主机私钥解密并验证 `ok`。后续普通命令新建 socket，发送带 128 字节 RSA 签名的请求；所有 socket 使用同一 private key。
5. 主机另建 callback socket，第一条请求为 signed type `5`（KEEP_ALIVE）；手机回设备信息，并保留连接用于心跳和异步事件。

步骤 2/3 的具体头常量由 mac `SFADBForwardHandshakeOperation` 与 Android字段交叉确定；APK本身不会限制 unsigned CMD 必须是 `0x0e`。


## 5. 旧通道会话池、keep_alive_attr与心跳

### 5.1 会话池、短连接与回调连接

`c/e` singleton 使用 `ConcurrentHashMap<Long,c/a>`，key为 MINA `IoSession.getId()`（[J/c/e.java:8–13,25–45](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/e.java#L8)）。它另保存一个 `c/d` 长连接对象。第一次收到 `b/h`（keep-alive）时才以 boolean=true 创建该对象；其它 request 初次到来创建普通 `c/f`（[J/d/c.java:40–45](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/c.java#L40)；[J/c/e.java:33–44](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/e.java#L33)）。新长连接关闭旧长连接 `close(true)`，清空 EventManager，保存新session id并注册 DEVICE_INFO（[J/c/e.java:16–22,34–40](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/e.java#L16)）。所以手机同时只允许一个事件主连接，多个临时请求连接可分别进池。

普通请求 worker 为单线程 executor；如果旧任务未完成而新任务到来，取消旧 Future 并调用旧 request 的 `b(session)` 清理，然后提交新任务。closeFuture 同样删除池成员、设置closed flag并取消当前任务（[J/c/f.java:57–78](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/f.java#L57)；[J/c/a.java:14–16,27–30](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/a.java#L14)）。事件主 worker `c/d` 则每个request直接submit，不用普通worker的单个current Future覆盖机制（[J/c/d.java:11–14](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/d.java#L11)）。**注意**：这只是 single-thread executor 排队，不是后台并行执行。

每个worker执行 request.a(session) 并写回响应；遇到 `a/c` 关闭连接，遇到 `a/e` 终止当前处理（[J/c/f.java:40–53](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/f.java#L40)）。响应发送完成后，若 `keep_alive_attr` 默认为false并仍连接，则关闭socket（[J/d/c.java:50–56](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/c.java#L50)）。单次请求→响应→关闭是默认连接模型，不应默认请求多路复用。

`c/e.a(long)` JADX 末尾出现未定义 `throw th`（[J/c/e.java:51–62](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/e.java#L51)），这是反编译残损；前面的remove/reset操作明确，异常是否存在不能按源码文本当作可信运行语义。

#### type5 KEEP_ALIVE / callback socket

type5 由注册表映射 `t` parser，再创建 `b/h`（[J/e/a/a/a.java:100–115](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/a.java#L100)；[J/e/a/a/t.java:8–9](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/t.java#L8)）。`b/h.a` 设置 `keep_alive_attr=true`，暂设 BOTH_IDLE=20，添加 MINA KeepAliveFilter，requestInterval=10秒，forwardEvent=false，再调用普通 GET `b/e` 生成设备信息响应（[J/b/h.java:14–21](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/h.java#L14)；[J/b/e.java:13–14](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/e.java#L13)）。取消请求时只设 `keep_alive_attr=false`（[J/b/h.java:24–27](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/h.java#L24)）。

过滤器添加时 `onPostAdd -> resetStatus` 把 BOTH_IDLE改为requestInterval=10，并非持续20；默认requestTimeout=30秒、超时handler=CLOSE（[MINA/filter/keepalive/KeepAliveFilter.java:27–28,77–81,133–135](../handshaker_analysis/jadx_out/sources/org/apache/mina/filter/keepalive/KeepAliveFilter.java#L27)；[MINA/filter/keepalive/KeepAliveRequestTimeoutHandler.java:28–35](../handshaker_analysis/jadx_out/sources/org/apache/mina/filter/keepalive/KeepAliveRequestTimeoutHandler.java#L28)）。因此协议时序应表述为：10秒双向无业务流量发心跳、等待默认30秒，没有匹配心跳回应则close(true)，而不是固定每10秒不管流量发包（[MINA/filter/keepalive/KeepAliveFilter.java:151–170](../handshaker_analysis/jadx_out/sources/org/apache/mina/filter/keepalive/KeepAliveFilter.java#L151)）。

#### type6 HEARTBEAT

手机发 heartbeat 帧为 `00 00 00 03 06 01 01`，body仅 `[CMD6,Version1,1]`（[J/d/a/a.java:8–20](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/a/a.java#L8)；[J/f/a.java:15–16](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/a.java#L15)；[J/d/b.java:34–38](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/b.java#L34)）。对应 heartbeat parser `r` 创建 `b/g(b2)`，这里 b2是请求F[135] Version；`b/g`构造 `(6,Version,2)`（[J/e/a/a/a.java:117–131](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/a.java#L117)；[J/e/a/a/r.java:8–9](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/r.java#L8)；[J/b/g.java:7–13](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/g.java#L7)）。在keep-alive过滤器上，`b/g` 被视作response，过滤器重设超时，并消费掉此消息，不再传给普通 handler（[J/d/a/c.java:30–34](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/a/c.java#L30)；[MINA/filter/keepalive/KeepAliveFilter.java:109–121](../handshaker_analysis/jadx_out/sources/org/apache/mina/filter/keepalive/KeepAliveFilter.java#L109)）。

主机向手机的 heartbeat 回应仍需走主机→手机的 signed帧，CMD=6、Version=1。F[134]通常2（与heartbeat response命名对应），但该APK的heartbeat parser实际忽略F[134]，仅保留Version（[J/e/a/a/r.java:8–9](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/r.java#L8)）。若发送unsigned三字节response给手机，会被当成公钥导入并出错，不能因手机→主机heartbeat短头而误用对称编码。

若在普通短连接上发signed type6，它不会被KeepAliveFilter消费，而request.a返回手机heartbeatresponse `[06,Version,02]`（[J/b/g.java:11–13](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/g.java#L11)；[J/d/a/b.java:9–26](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/a/b.java#L9)）。这与主callback连接上作为pong的处理路径不同。

#### 事件推送与服务存活

EventManager `c/c` 保存一个 `long sessionId` 和类别列表（AUDIO/VIDEO/IMAGE/DEVICE_INFO/FILE/MEDIA）；事件发送获取 `c/e.b(sessionId)` 并直接 `session.write(response)`（[J/c/c.java:10–19,33–45,48–59](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/c.java#L10)）。注意该发送代码没有检查类别是否在列表里，所以不能从列表存在就推断其是严格订阅过滤器（同文件 `48–59`）。清除时设置sessionId=-1并清空列表（同文件 `62–65`）。

文字序列：主机建立signed type5长连接 → 手机关闭旧callback连接并指定新session → 手机回type5设备信息 → 手机在空闲时发type6 ping，主机回signed type6 pong → 文件/媒体/设备变更在此连接异步推送 → socket关闭后closeFuture清理池和EventManager。

`AdbForwardService` 每60秒检查是否仍存在长连接 `c/e.b()`；存在则重新安排检查，没有则stopSelf，onDestroy关闭服务、kill进程（[J/AdbForwardService.java:43–46,89–96](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/AdbForwardService.java#L43)；[J/a.java:14–19](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/a.java#L14)；[J/c/e.java:69–71](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/e.java#L69)）。所以只做短连接文件请求而没有callback连接，服务可能在60秒后终止；创建keep-alive连接不只是为了订阅事件，也保持守护服务存活。


## 6. 旧通道文件下载、媒体库、缩略图与变更监听

#### 当前APK实际提供的HTTP文件读取

已核实另走HTTP的服务：[J/d/d.java:15–23](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/d.java#L15)建立TCP 19999、安装 `HttpServerCodec`，handler=`J/d/g.java`。主守护端口10086同时启动这个服务（[J/d.java:14、20–28](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d.java#L14)）。

可用请求形式：

```http
GET /?file_path=%2Fstorage%2Femulated%2F0%2FMusic%2Fexample.mp3 HTTP/1.1
Host: PHONE:19999
Range: bytes=1048576-
```

路径与方法的精确行为：handler不检查method，不检查URL path，只检查query。`file_path`通过正则`file_path=([^*]*)`提取，再以UTF-8执行 `URLDecoder.decode`，作为`new File`的**绝对/原样文件路径**（[J/d/g.java:82–94](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/g.java#L82)）。正则会吞掉`&`之后内容，故Dart应只发送一个参数；使用标准application/x-www-form-urlencoded编码，字面`+`必须编码为`%2B`。path为空、文件不存在会返回404（[J/d/g.java:44–55、84–94](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/g.java#L44)）。

HTTP Range不是完备RFC实现。读取header名称`range`；正则接受`bytes=N-M`及逗号列表，但仅按`-`分割并取第一段作为起始偏移N，**忽略结束位置**。非匹配Range回退0；suffix range `bytes=-N`可能触发 `Long.parseLong("")` 异常，逗号多个range也不能可靠处理（[J/d/g.java:96–108](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/g.java#L96)）。应只用`bytes=N-`。N=0或无Range返回200，`content-length=file.length()`；N>0返回206，`content-length=file.length()-N`，源码生成非标准 `content-range: :bytes N-file.length()`，没有斜杠total，结束偏移也不是length-1（[J/d/g.java:111–127](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/g.java#L111)）。客户端不应依赖此header格式，应以已知文件长度和起始偏移校验。

数据由`FileInputStream.getChannel()`及`FilenameFileRegion(file, channel, N, channel.size())`直接发送，没有SSP分块帧，也没有在handler做gzip、MD5校验或签名验证（[J/d/g.java:129–133](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/g.java#L129)）。注意第四参数传入**整文件size**而非`size-N`，实际MINA EOF/region发送行为在断点下载时**待验证**。一次连接使用responseFlag只写一次header，虽然header声称keep-alive，后续不同请求不会重写header（[J/d/g.java:109–110、127](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/g.java#L109)），重实现每次读取宜建立新连接。

探活：query以`test`开头时，将query.substring(5)的UTF-8数据做MD5，返回200及16字节**原始摘要**后关闭连接（[J/d/g.java:67–80](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/d/g.java#L67)）。例如 `/?test=123`返回MD5("123")原始16字节。

Mac可直接交叉验证：[D/SmartFinderCore.strings.txt:15654–15661](../handshaker_analysis/dumps/SmartFinderCore.strings.txt#L15654)有ADB转发`tcp:19999`、`http://127.0.0.1:%lu/?test=123`和`http://127.0.0.1:%lu/?file_path=%@`；10086转发见[D/SmartFinderCore.strings.txt:15621–15625](../handshaker_analysis/dumps/SmartFinderCore.strings.txt#L15621)。它支持Mac通过ADB转发读取该HTTP服务的判断，但Wi-Fi是否采用同一个URL构造仍**待验证**。

已核实下载文字序列：

```text
电脑 -> 手机SSP: 获取媒体列表(type=2或7)，取得_data文件路径
电脑 -> ADB(USB时): 将本地端口转发到手机19999 [Mac字符串证据]
电脑 -> HTTP19999: GET /?test=123 [可选探活]
手机 -> 电脑: HTTP200 + raw MD5("123"), close
电脑 -> HTTP19999(新连接): GET /?file_path=<urlencoded absolute path>, 可带Range bytes=N-
手机 -> 电脑: HTTP200/206 header + 文件原始字节流
电脑: 写入本地文件；按content-length和源文件大小检查是否完整
```

### 6.1 媒体查询与JSON布局（当前APK已核实）

#### FETCH type=2

payload允许为空；有剩余数据则读取4字节大端signed int `groupId`，否则取0（[J/e/a/a/p.java:8–9](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/p.java#L8)）。K映射由[J/b/d.java:25–61](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/d.java#L25)确认：

| K | 语义 | p.java查询源/选择条件 |
|---:|---|---|
| 1 | 音轨列表；groupId>0按album_id过滤，否则全部 | [J/utils/p.java:134–147](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L134)，audio external；按title_key排序 |
| 2 | 音频专辑列表 | [J/utils/p.java:122–126](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L122)，audio albums external；按album_key排序 |
| 3 | 不支持 | [J/b/d.java:32–34](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/d.java#L32)，抛a/c异常 |
| 4 | 音频所在目录分组代表行 | [J/utils/p.java:292–296](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L292)，Files external，bucket_display_name非空/is_music=1/GROUP BY bucket_id |
| 5 | 图片相册分组代表行 | [J/utils/p.java:342–346](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L342)，Images external，GROUP BY bucket_id |
| 6 | 视频相册分组代表行 | [J/utils/p.java:370–374](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L370)，Video external，GROUP BY bucket_id |
| 7 | 某bucket下文件列表 | [J/utils/p.java:304–308](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L304)，Files external，bucket_id=groupId |
| 8 | 某bucket下图片 | [J/utils/p.java:354–358](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L354)，Images external，bucket_id=groupId |
| 9 | 某bucket下视频 | [J/utils/p.java:382–386](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L382)，Video external，bucket_id=groupId |
| 10 | 缓存全部图片 | [J/utils/p.java:416–419](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L416) |
| 11 | 缓存全部视频 | [J/utils/p.java:436–439](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L436) |
| 12 | Android DownloadManager完成下载列表 | [J/utils/p.java:447–451](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L447)、621–622，status=8 |

响应为UTF-8 JSON，根一般为记录数组，没有长度前缀（`J/f/d.java`/`J/f/h.java`）。没有记录时`p.a(Cursor)`返回null，结果只含3字节公共响应头，**不是固定空数组**（[J/utils/p.java:155–159](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L155)）。取消后抛a/e（[J/b/d.java:63–66](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/d.java#L63)）。

序列：电脑发送`type=2,V=version,K=5,payload=[groupId可省略]` -> 手机返回相册代表记录数组 -> 电脑读取每条bucket_id -> 对选中bucket发送`type=2,K=8,int32(bucket_id)` -> 手机返回图片记录数组 -> 电脑以 `_id`请求thumbnail(type8)，以`_data`从HTTP下载原图。

#### NEW_FETCH type=7

请求payload为空（[J/e/a/a/u.java:8–9](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/u.java#L8)）；K=1图片，2音频，3视频（[J/b/i.java:21–29](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/i.java#L21)）。对应`p.k/l/m()`，分别按bucket_id/album_id/bucket_id分组（[J/utils/p.java:459–468](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L459)）。响应gzip UTF-8 JSON，无gzip长度前缀；未知K返回空字符串结果（[J/b/i.java:19–35](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/i.java#L19)）。

根结构源码构造为：

```json
{
  "all_item": ["所有记录对象"],
  "all_group": ["每组第一条记录对象（不是单独album对象）"],
  "item_with_group": [{"id": "bucket_id或album_id的原类型", "list": "该组记录集合"}]
}
```

`all_item/all_group`明确定义为JSONArray（[J/utils/p.java:195–224](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L195)）。`item_with_group`外层是JSONArray，但`list`是直接`JSONObject.put("list", ArrayList<JSONObject>)`，未显式转换为JSONArray（[J/utils/p.java:252–260](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L252)），该设备Android `org.json`把它序列化成真正数组还是带JSON内容的字符串**待验证**。Dart解析器可先容忍List或JSON字符串两种形式，抓包后锁定。分组遍历HashMap无固定顺序，不能按响应次序假设album排序（[J/utils/p.java:254](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L254)）。

序列：电脑`type7,K1/2/3` -> 手机查询provider并group -> 手机响应3字节头+gzip数据 -> 电脑解gzip、UTF-8解码、JSON解析 -> 用all_item填充库、all_group生成相册列表、item_with_group建立关系。

#### 完整可证明的记录schema边界

JSON serializer输出cursor的**全部列名**，但忽略空列名及以`key`结尾的列（[J/utils/p.java:162–183、203–206](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L162)）。整数为Java long，浮点为float，文本为String，blob直接放byte[]；null使用put(key,null)，字段可能删除而不是显式JSON null（[J/utils/p.java:166–180](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L166)）。因此默认projection=null的图片/视频/下载查询**没有APK固定的完整字段schema**；必须以运行时provider返回列为准。不能把常见MediaStore列列表宣称为源码已确认的强制字段。常见`_id,_data,_display_name,_size,bucket_id,bucket_display_name,mime_type,date_added,date_modified,width,height,orientation,datetaken`是否存在、类型、扩展厂商字段都**待验证**；这些名称只应作为Dart宽松映射候选。

音频查询多数指定[J/utils/m.java:32](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/m.java#L32)projection，完整已核实输出列为：

```text
_id, title, album, _display_name, artist, _data, album_id, artist_id,
date_added, date_modified, mime_type, duration, year,
is_alarm, is_music, is_podcast, is_notification, is_ringtone,
_size, track, genre_id
```

其中track通过`CASE track WHEN 0 THEN 2147483647 ELSE track END AS track`替换0；genre_id通过audio_genres_map子查询。实际每列SQLite值类型仍由cursor决定；可为null而省略。分组音频(K=2, NEW_FETCH)及缓存音频使用隐藏目录过滤、音乐筛选（[J/utils/p.java:35、366–409、427–429、463–464](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L35)）。规则：Ringtones目录始终可见；其余要求is_music或is_podcast，并位于smartisan/music/cloud或Music或size>800000或mime_type=audio/x-smartisanos-cua，排除ogg/3gp/ac3；厂商hide_dir bucket_id排除。图片隐藏相册根据`content://smartisanos_gallery/bucket` status=2过滤（[J/utils/p.java:29、412–413、625–635](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L29)）。

注意K=2旧音频专辑查询使用`m.a`同一音轨projection去查询Albums（[J/utils/p.java:125](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L125)）；源码另外声明albums字段表`_id,album,album_art,artist,numsongs,minyear,album_key,maxyear`（[J/utils/p.java:38](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L38)），但该表未被该查询使用。这可能是反编译或原代码兼容缺陷，专辑实际返回列/是否抛异常**待验证**，不要按未使用数组规定线schema。

Dart应以`Map<String,dynamic>`保留未知provider字段，以int保存Java long（不要转double），字符串按UTF-8解码。源排序、隐藏策略属于手机语义，电脑不应自行“补齐”不可见数据。

### 6.2 缩略图

#### OLD_THUMBNAIL type=1，按路径

请求payload：relative 0 int32 count；随后每项int32 UTF-8字节长度+路径字节（[J/e/a/a/v.java:10–17](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/v.java#L10)实际使用默认Java charset，Android通常UTF-8，编码**待验证**）。K=1图片/2视频/3音频封面（[J/b/j.java:81–131](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/j.java#L81)）。图片缩放为200x200，EXIF方向3/6/8分别旋转180/90/270，JPEG质量86（[J/b/j.java:52–73](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/j.java#L52)）；视频读取frameAtTime(-1)，音频读取embeddedPicture。响应payload：

| 相对偏移 | 类型 | 含义 | 证据 |
|---|---|---|---|
| 0 | int32 BE | 结果count | [J/f/j.java:23](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/j.java#L23) |
| 游标q | u8 | status 0有图，1失败 | [J/f/j.java:27–35](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/j.java#L27) |
| q+1 | int32 BE | pathByteLength P | [J/f/j.java:36](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/j.java#L36) |
| q+5 | bytes[P] | path，默认charset | [J/f/j.java:25](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/j.java#L25)、37 |
| q+5+P | int32 BE | jpegByteLength J | [J/f/j.java:38](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/j.java#L38) |
| q+9+P | bytes[J] | JPEG（J=0时无） | [J/f/j.java:39–40](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/j.java#L39) |

下一项q+=9+P+J。输出迭代Map，顺序未保证（[J/f/j.java:24](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/j.java#L24)），必须按path匹配。

#### THUMBNAIL type=8，按media ID

请求payload：relative 0 int32 BE count；每项int64 BE mediaId（[J/e/a/a/y.java:10–15](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/y.java#L10)）。K=1图片 `_id`、2视频 `_id`、3音频**albumId**（[J/b/m.java:26、62–73](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/m.java#L26)），音频用`content://media/external/audio/albumart/<id>`；图片/视频MINI_KIND(1)。JPEG质量86（[J/b/m.java:79–82](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/m.java#L79)）。响应payload：

| 相对偏移 | 类型 | 含义 | 证据 |
|---|---|---|---|
| 0 | int32 BE | count | [J/f/m.java:24](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/m.java#L24) |
| 游标q | u8 | status 0成功、1失败 | [J/f/m.java:27–35](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/m.java#L27) |
| q+1 | int64 BE | mediaId / albumId | [J/f/m.java:36](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/m.java#L36) |
| q+9 | int32 BE | JPEG length J | [J/f/m.java:37](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/m.java#L37) |
| q+13 | bytes[J] | JPEG | [J/f/m.java:38–40](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/m.java#L38) |

下一项q+=13+J，结果顺序未保证（[J/f/m.java:25](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/m.java#L25)）。10线程处理，最多等待20秒（[J/b/m.java:27、122–126](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/m.java#L27)）；cancel将Future.cancel(true)（[J/b/m.java:138–143](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/m.java#L138)）。**待验证反编译异常**：[J/b/m.java:95–98](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/m.java#L95)finally无条件把结果覆盖为0字节，与前面成功分支[J/b/m.java:87–90](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/m.java#L87)冲突，应检查smali或抓包确认；线格式可以确定，但不能保证该APK缩略图必然成功。

序列：媒体列表 -> 电脑`type8,K1,count,ids` -> 手机查MediaStore并JPEG编码 -> 响应count与各id/status/JPEG -> 电脑以id关联缓存，失败status仅影响对应条目。

### 6.3 删除媒体记录与扫描新文件

`DELETE type11`请求payload=int32 BE count+count个int64 BE ID（[J/e/a/a/n.java:10–15](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/n.java#L10)），手机对`content://media/external/object`（失败则Files URI）执行 `_id IN (...)` delete；成功只意味着影响行数>0，**不逐项报告状态**（[J/utils/p.java:264–289](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/p.java#L264)，[J/b/b.java:19–23](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/b.java#L19)）。响应payload偏移0一个u8，1成功，0失败（[J/f/b.java:19–20](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/b.java#L19)）。空ID数组会selection=null，原代码可能删除全部provider记录（[J/f/b.java:273–274、289](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/b.java#L273)）；客户端禁止发空删除列表。它是基于MediaStore ID的删除，不等价于Mac SSPDeleteFile的路径/垃圾箱协议。

`SCEN type12`实际是媒体扫描路径（不是场景）：payload=int32 count+每项int32路径长度+路径字节（[J/e/a/a/w.java:12–22](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/w.java#L12)）。手机给每路径启动`SmartfolderMediaScannerService`，立即返回ASCII `Y`，只代表扫描任务已提交（[J/b/k.java:20–29](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/k.java#L20)），不能等同于完成入库。结果编码无长度前缀（[J/f/k.java:19–20](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/k.java#L19)）。

文字序列：电脑经ADB或尚未验证的SSP上传写文件 -> `type12,路径列表` -> 手机启动扫描服务 -> 响应Y -> MediaStore完成更新 -> 手机媒体增量通知 -> 电脑更新库。

### 6.4 MonitorFolder / WatchCallback 当前APK实现

`WATCH type10`payload=int32 count，循环int32字节长度+路径字符串；空列表解析返回null（[J/e/a/a/z.java:12–22](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/a/z.java#L12)）。K=1注册，其余K注销（[J/b/n.java:21–31](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/n.java#L21)）。EventManager尚未初始化时响应ASCII N；注册完成响应Y（[J/b/n.java:18–19、33](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/n.java#L18)；[J/f/n.java:19–20](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/f/n.java#L19)）。watch路径若是MediaStore三种external content URI，构造ContentObserver，其他构造FileObserver（[J/utils/r.java:18–28](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/r.java#L18)）。

文件路径观察实际上监控`externalStorageAbsolutePath + suppliedPath`（[J/utils/h.java:10、34–36](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/h.java#L10)），所以当前APK普通目录watch须发送相对存储根的`/DCIM`之类路径，而HTTP下载须绝对路径。不能混用。FileObserver mask=4040=0xFC8；event剥去高16位，回传path=suppliedPath+"/"+name（name为null时回传suppliedPath）（[J/utils/h.java:18、27–30](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/h.java#L18)）。它不是递归子树观察，源码只对给定目录创建一个FileObserver。

通知使用公共3字节`[9,2,1]`，内容UTF-8 JSON单键对象，value是观察路径/子路径（[J/c/g.java:26–33、75](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/g.java#L26)）：

| event数值 | JSON键 | 源码 |
|---:|---|---|
| 8 | CLOSE_WRITE | [J/c/g.java:51–52](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/g.java#L51) |
| 64 | MOVED_FROM | [J/c/g.java:53–54](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/g.java#L53) |
| 128 | MOVED_TO | [J/c/g.java:55–56](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/g.java#L55) |
| 256 | CREATE | [J/c/g.java:57–58](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/g.java#L57) |
| 512 | DELETE | [J/c/g.java:59–60](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/g.java#L59) |
| 1024 | DELETE_SELF | [J/c/g.java:61–62](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/g.java#L61) |
| 2048 | MOVE_SELF | [J/c/g.java:63–64](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/g.java#L63) |
| 其他(如0) | UPDATE | [J/c/g.java:65–66](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/g.java#L65) |

示例`{"CLOSE_WRITE":"/DCIM/new.jpg"}`。rename是两个独立MOVED_FROM/MOVED_TO事件，没有cookie/配对字段。注销停止FileObserver并删除watch map（[J/c/g.java:79–91](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/g.java#L79)）。Mac存在`SSPMonitorFolderRequest/ResponseHeader/Response`、`SSPWatchCallbackItem`（[D/ssp_classes.txt:132–135、166](../handshaker_analysis/dumps/ssp_classes.txt#L132)），与此功能相关；其真实protobuf字段见现代schema章节，不能等同当前JSON结构。

普通MediaStore `J/utils/d.java`的onChange会发UPDATE URI（[D/ssp_classes.txt:24–26](../handshaker_analysis/dumps/ssp_classes.txt#L24)），但`startWatching/stopWatching`实现为空（[D/ssp_classes.txt:39–45](../handshaker_analysis/dumps/ssp_classes.txt#L39)），没有注册ContentObserver代码，故通过type10对content URI观察是否会真的收到回调**待验证**。

另一路全局媒体增量通知更明确：[J/utils/m.java:48–61](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/m.java#L48)注册content://media/external、厂商隐藏目录/隐藏相册observer，合并200ms变化；比较新旧cursor，输出added/deleted，视频另可能updated（[J/utils/m.java:132–186](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/m.java#L132)）。公共通知头`[9,3,1]`，body未压缩UTF-8 JSON，schema：

```json
{
 "IMAGE":{"added":[],"deleted":[]},
 "VIDEO":{"added":[],"deleted":[],"updated":[]},
 "AUDIO":{"added":[],"deleted":[]}
}
```

VIDEO.updated键仅在相关变化时出现（[J/utils/m.java:147–149](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/m.java#L147)）；各数组记录是provider columns转换的同类对象（[J/utils/m.java:240–255](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/m.java#L240)）。added/deleted仅保留_size>0的记录（[J/utils/m.java:118–129](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/m.java#L118)）。字典键使用enum名字IMAGE/VIDEO/AUDIO（[J/utils/m.java:181–183](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/m.java#L181)）。

所有通知发送到EventManager记录的一个会话id，经session pool找到IoSession.write，**没有携带订阅request的标识，也没有广播全部session**（[J/c/c.java:33–35、48–58](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/c.java#L33)）。类别订阅列表虽被维护，但发送时不检查类别是否在列表中（[J/c/c.java:54–58](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/c/c.java#L54)），电脑必须对type9异步消息随时分发。

文字序列：

```text
电脑 -> 手机: 先建立并初始化事件接收会话 [具体握手/keep_alive见会话章节]
电脑 -> 手机: type10,K1,count=1,path="/DCIM"
手机: FileObserver(externalStorageRoot + "/DCIM").startWatching()
手机 -> 电脑: type10,V原样,K1 + ASCII Y
手机文件变化 -> FileObserver -> EventManager固定事件会话
手机 -> 电脑: [9,2,1] + {"CREATE":"/DCIM/a.jpg"}
电脑: 重新列举相应目录/更新本地视图 [当前APK需ADB目录路径]
电脑 -> 手机: type10,K!=1,同路径列表
手机: stopWatching(),移除类别与watch
手机 -> 电脑: ASCII Y
```


## 7. 现代SSP v2帧、两阶段握手与信任

这是从 macOS SmartFinderCore 方法反汇编、Proto descriptor 和常量读出的 **另一套** SSP 传输。`D/` 指 `handshaker_analysis/dumps/`。所有具体偏移从下列本地反汇编核实；未由本 APK 支持的现代帧不能直接发送给本 APK `10086` 旧协议入口。Modern hostSmartSyncProtocolVersion 字符串确认为 `"2"`（[D/modern_transport.constants.txt:2](../handshaker_analysis/dumps/modern_transport.constants.txt#L2)）。下面标为“推断”的手机侧行为，仅由 mac 接收逻辑推得，没有现代手机源码佐证。

### 7.1 现代主机→手机帧

Wi-Fi 的 `SFWifiDevice sendData:withSessionId:withFlag:` 和 USB 的同名方法都依次 append `u32be(sessionId)`、`u8(flag)`、`u32be(data.length)`、`data`（[D/modern_transport.disasm.txt:33–69,166–202](../handshaker_analysis/dumps/modern_transport.disasm.txt#L33)）。Wi-Fi 将完整缓冲交给 socket；USB写入libusb bulkOut（同文件 `78–84,223–241`）。没有旧协议的“先4字节总长度再flag”包装。

| wire 偏移 | 长度 | 类型 | 意义 | 证据 |
|---:|---:|---|---|---|
| 0 | 4 | u32be | sessionId；请求/响应关联标识 | [D/modern_transport.disasm.txt:33–40](../handshaker_analysis/dumps/modern_transport.disasm.txt#L33) |
| 4 | 1 | u8 | transport flag | 同文件 `41–47` |
| 5 | 4 | u32be | data长度，排除9字节transport头 | 同文件 `48–62` |
| 9 | L | bytes | 随flag解释的data | 同文件 `63–69` |

```text
0                4       5                9
+----------------+-------+----------------+-------------------+
| sessionId u32BE| flag  | dataLen u32BE  | data[dataLen]      |
+----------------+-------+----------------+-------------------+
```

flag已核实的发送路径：

- `0`：unsigned握手01/02，data是Protobuf，01使用sessionId=1，02先以1初始化再加1故sessionId=2（[D/modern_transport.disasm.txt:1226–1227,1284–1324,1732–1733,2038–2087](../handshaker_analysis/dumps/modern_transport.disasm.txt#L1226)）。
- `1`：普通命令。`SFGenericDevice sendRequestData:withSessionId:error:` 计算 `getSignatureForData(protobufBytes)`，先append签名再append原protobuf，并以flag1调用sendData（同文件 `5658–5694`）。因此wire `9…136` 是128字节签名，protobuf从`137`开始；签名覆盖 **protobuf原字节**，不覆盖外层sessionId、flag、length。
- `3`：裸文件bytes。`SFGenericDevice sendFileData:withSessionId:error:` 使用flag3，将原始data直接交给sendData；本方法不计算RSA签名（同文件 `5776–5791`）。手机对应实现、是否仅允许已有文件上传session使用、如何限定长度须进一步验证，不能把裸文件内容当Protobuf解析。

`getSignatureForData` 对输入bytes做SHA256，再`RSA_sign(NID_sha256=0x2a0,hash,32,...)`，RSA签名为PKCS#1 v1.5，与旧APK `SHA256withRSA` 算法相同（同文件 `1111–1144`）。mac `SFGenericDevice init` 为每device实例生成1024bit RSA、exponent=65537并保存为 `efxi`，使用signing_mutex串行签名（同文件 `7271–7308`）。不要把现代derivedKey理解为替代RSA签名的AES key；这些已核实路径仍使用 `efxi` RSA private key签名。

**实现建议**：显式区分旧ADB framed命令和现代v2 transport，不依靠“看到第4byte=0/1”自动识别，因为现代第0–3字节是sessionId而非长度。

### 7.2 现代手机→主机帧：物理chunk与逻辑消息

Wi-Fi后台 `messageReadingThreadMain` 从offset0取u32be sessionId、offset4取u16be chunkLen，从offset6取chunkData；对不完整的数据保留remainingData再累积（[D/modern_transport.disasm.txt:5888–5983](../handshaker_analysis/dumps/modern_transport.disasm.txt#L5888)，主要取字段 `5910–5922`）。USB后台具有相同代码结构；本文偏移的可引用证据以Wi-Fi为准。

```text
每个物理响应chunk:
0                4                6
+----------------+----------------+-------------------------+
| sessionId u32BE| chunkLen u16BE | chunkData[chunkLen]     |
+----------------+----------------+-------------------------+

同sessionId的chunkData按接收顺序拼接为逻辑消息:
0                          8
+--------------------------+-------------------------------+
| payloadLen u64BE         | payload[payloadLen]           |
+--------------------------+-------------------------------+
```

`sessionId & 0x80000000` 置位表示push，后台分流到 `device:withSessionId:withPushData:`；没有置位到withData（同文件 `5984–6040`）。普通callback通过SSPManager.sessionDict查找session并appendData（同文件 `7097–7175`）。`SSPRequestOperation appendData` 在不知道dataLength时累积lenData，至少8字节后取首8字节为u64be totalLen，剥掉这8字节才交给data积累逻辑（同文件 `6789–6974`，关键 `6820,6865–6869`）。因此u64逻辑长度可以跨物理chunk，不应硬编码在每个chunk重复。**totalLen不包含自身8字节**：完成判断比较已经剥头后的`data.length`与`dataLength`（同文件 `6972–6995`）；物理`chunkLen`则包含在此chunk承载的逻辑头字节。

同session可以按业务收到多个逻辑消息，例如Handshake02的Waiting响应后仍在session2继续读下一份完整Response02（同文件 `2953–2971,3450–3467`）。Dart收流器应按sessionId保留状态，完成一份`u64be length + payload`后，继续处理同session后续逻辑头。这里是支持业务多阶段流的实现设计；mac通用base `SSPRequestOperation.appendData`自身只完成一次，它甚至会截断超出声明长度的data而不保存剩余消息（同文件 `7017–7078`），不能把其缺陷原样实现为健壮Dart split逻辑。上传/下载的同session响应阶段需结合各专用operation核实。

同步握手读取路径 `SFWifiDevice syncReadResponseDataWithMSTimeout:error:` 则直接在首个receive里解析u32 sessionId、u16 chunkLen、u64 totalLen（同文件 `6561–6593`），收满totalLen返回不含8字节逻辑长度的data；该同步路径还把sessionId高位清除（同文件 `6564`），且u64 totalLen若超过0x6400000=100MiB有特殊分支（同文件 `6593–6597`）。它对首次read的头完整性处理不如后台parser严谨，Dart应采用完整增量状态机。

**待验证**：同步路径初次读入超长/粘连响应、多个chunk时对物理chunk头的处理；最大chunkLen实际值、USB最大bulk负载、0长度chunk用途、推送sessionId是否应在应用层移除高位。可以确认chunkLen类型是16位，而不是旧协议32位总长。

### 7.3 HandShakeRequest01/Response01

现代request01序列化的是Protobuf；字段tag与类型由真实descriptor读出（[D/ssp_descriptors.raw.txt:100–111](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L100)），不存在固定二进制offset，下面的tag不能误当wire byte偏移。

| tag | 字段 | Proto类型 | 本地mac赋值与意义 |
|---:|---|---|---|
| 1 | type | SSPRequestType enum | 31=HandshakeRequest01，mac读取默认type再setType以保证presence |
| 2 | hostUuid | string | `getMacUUID` |
| 3 | hostName | string | `getMacName` |
| 4 | hostTimestamp | uint64 | NSDate.timeIntervalSince1970转整数，即Unix秒 |
| 5 | hostSmartSyncProtocolVersion | string | `"2"` |
| 6 | hostAppVersion | string | mainBundle的CFBundleShortVersionString |
| 7 | hostMinClientVersion | string | `"1.0.197"` |
| 8 | md5 | bytes | RSA public key PKCS#1 DER的原始MD5摘要 |
| 9 | enckey | bytes | AES-256-CBC加密的Base64 PKCS#1公钥文本 |
| 10 | hostModel | string | `getMacModel` |
| 11 | heartbeatTimeoutSecond | uint64 | 来自device.heartbeatTimeoutSecond |

赋值代码证据：public key/MD5/AES [D/modern_transport.disasm.txt:371–574](../handshaker_analysis/dumps/modern_transport.disasm.txt#L371)；type、UUID、Name、Timestamp `620–704`；版本、md5、enckey、model `708–772`；heartbeat `775–783`。版本literal见 [D/modern_transport.constants.txt:2–3](../handshaker_analysis/dumps/modern_transport.constants.txt#L2)。heartbeatTimeoutSecond初始化读NSUserDefaults后限制到10…180秒（[D/modern_transport.disasm.txt:7239–7270](../handshaker_analysis/dumps/modern_transport.disasm.txt#L7239)）；本机实际值/偏好设置键待验证。

RSA public key封装同旧握手：`PEM_write_bio_RSAPublicKey`生成PKCS#1 public key文本，去换行，把Base64文本用空格补到32的倍数，AES-256-CBC（无PKCS7）使用固定key和IV；DER MD5和密文分别放入tag8/9，此处不再附旧握手的独立u32密文长度（同文件 `371–575,749–758`；常量 [D/adb_transport.constants.txt:28–29](../handshaker_analysis/dumps/adb_transport.constants.txt#L28)；空白常量 [D/modern_transport.cfstrings.txt:5–7](../handshaker_analysis/dumps/modern_transport.cfstrings.txt#L5)）。

```text
key = 28e3ee32b0de27ef6bc29792054ef9739ce8e87bb495f2ea0d72d4f4f40b3bde
iv  = 2b9e34d4e1d9088994939ec4e3e960c5
```

主机发session1、flag0 request01，等Response01，使用SSPHandShakeResponse01解析；成功缓存对象 `theResponse01`、标 `_aoaHandShaking01OK=true`，设置apkVersion/apkVersionName及usbSerial（[D/modern_transport.disasm.txt:1209–1324,1590–1645](../handshaker_analysis/dumps/modern_transport.disasm.txt#L1209)）。Response01字段由descriptor精确确认：type32、apkVersion(tag2 string)、apkVersionName(3 string)、clientTimestamp(4 uint64)、clientSmartSyncProtocolVersion(5 string)、clientMinHostVersion(6 string)、deviceUuid(7 string)、deviceName(8 string)、usbSerial(9 string)、isSmartisanDevice(10 bool)、clientMinHostVersionCode(11 uint64)（[D/ssp_descriptors.raw.txt:112–123](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L112)）。

这一步主要交换公钥和能力/身份；需要02阶段成功结果验证后才标整个连接可用，普通sendRequestData先检查aoaHandShakeOk（[D/modern_transport.disasm.txt:5635–5657](../handshaker_analysis/dumps/modern_transport.disasm.txt#L5635)）。

### 7.4 TrustType 与 HandShakeRequest02/Response02

TrustType enum已从descriptor原始数值表恢复，非字符串猜测（[D/ssp_descriptors.raw.txt:466–472](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L466)）：

| 值 | 原始名称 | 可由mac确认的行为 |
|---:|---|---|
| 1 | TrustWaiting | 继续等待手机后续02响应；mac可能通知阻塞状态 |
| 2 | TrustUnknow | 新信任record/default Request02使用这个值，原拼写就是Unknow |
| 3 | TrustNo | 被拒绝，结束02，返回失败 |
| 4 | TrustOnce | 保存response的derivedKey与trust_type=4，然后处理result |
| 5 | TrustAlways | 保存response的derivedKey与trust_type=5，然后处理result |
| 6 | TrustRemove | enum有该值；握手02这里不按成功处理，移除具体流程待验证 |

`getRequest02WithError` 设置type默认值33、hostUuid、trustType=2（[D/modern_transport.disasm.txt:828–870](../handshaker_analysis/dumps/modern_transport.disasm.txt#L828)）。最终发送前，`sendHandShakeRequest02` 以response01.deviceUuid查找SFDeviceTrustStore record；新record设TrustUnknow2，已有record将 `record.trust_type` 和 `record.derived_key` 填入request02（同文件 `1744–1784,1915–1997`）。类型31/32/33/34由enum表确认（[D/ssp_descriptors.raw.txt:430–433](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L430)）。

Request02 Proto布局（均optional，descriptor：[D/ssp_descriptors.raw.txt:124–128](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L124)）：tag1 type(enum默认33)、tag2 hostUuid(string)、tag3 derivedKey(bytes)、tag4 trustType(enum默认Waiting1，mac通常显式设置2或stored value)。区分“Proto默认1”与“业务构造函数设2”。

Response02 Proto布局（均optional，descriptor：同文件 `129–135`）：tag1 type(enum默认34)、tag2 trustType(enum默认1)、tag3 deviceUuid(string)、tag4 deviceName(string)、tag5 derivedKey(bytes)、tag6 result(string)。

mac发session2、flag0 request02，循环读response02。TrustWaiting1分支调用通知block，sleep1秒再读；TrustNo3结束失败；TrustOnce4和TrustAlways5保存record值及derivedKey，调用store.save，再检查result（[D/modern_transport.disasm.txt:2953–2980,3140–3291,3450–3467](../handshaker_analysis/dumps/modern_transport.disasm.txt#L2953)）。只有解析成功响应而且result证明通过才置aoaHandShakeOk=true。不能仅看到TrustAlways5就跳过RSA成功证明。

#### result证明与derivedKey的区别

result先检查非空、是否以ASCII `failed` 开头；否则Base64解码，交给 `checkResult`（同文件 `3647–3666,3818–3839,3992–4018`；literal [D/modern_transport.constants.txt:4–5](../handshaker_analysis/dumps/modern_transport.constants.txt#L4)）。`checkResult`：要求总密文长度能整除 `RSA_size(efxi)`，逐RSA块调用 `RSA_private_decrypt(...,RSA_PKCS1_PADDING=1)`，把正数长度的明文块拼接为UTF-8字符串（[D/modern_transport.disasm.txt:902–918,970–1015](../handshaker_analysis/dumps/modern_transport.disasm.txt#L902)）。只接受字符串 `"ok"` 后设置aoaHandShakeOk（同文件 `4055–4078`）。

result是手机用request01收到的host RSA public key加密后的证明，不是SHA256签名；这一判断由主机private decrypt路径确定。derivedKey是另外一个Proto bytes字段，由Response02返回并存盘，下一次Request02原样发回；mac上述路径没有对derivedKey计算hash、RSA解密或AES解密（同文件 `1984–1997,3156–3174,3232–3250`）。**待验证**：现代手机生成derivedKey的算法、它与hostUuid/public key的绑定、过期/撤销策略、TrustOnce是否应跨重启复用，以及一次授权的精确生命周期；这些不能从mac“保存bytes”代码推导。

### 7.5 SFDeviceTrustStore 与 mac 生命周期

这次已有真正方法证据，不再只靠类名字符串：defaultStore使用 `NSApplication.applicationSupportFolder` 加 `deviceStore.plist`，再 `storeWithPath`（[D/modern_transport.disasm.txt:4388–4411](../handshaker_analysis/dumps/modern_transport.disasm.txt#L4388)；filename literal [D/modern_transport.constants.txt:6](../handshaker_analysis/dumps/modern_transport.constants.txt#L6)）。initAllWithPath建立devices数组、visibleDevices数组和deviceUUIDs字典，从NSKeyedUnarchiver文件加载；save通过NSKeyedArchiver archiveRootObject:toFile保存devices，然后resetVisibleDevices（同文件 `4621–4677,5501–5519`）。文件虽然叫`.plist`，应视为NSKeyedArchive，不应未经检测就当简单dictionary plist。

02开始时record更新以下内容：deviceUuid/deviceName、apkVersion/apkVersionName、clientMinHostVersion/clientSmartSyncProtocolVersion、last_connection=NSDate.now、isSmartisanDevice、connection_count+1（同文件 `1785–1934`）。新record先addRecord后save（同文件 `1935–1945`），TrustOnce/Always后另保存trust_type和derived_key。对应字段是mac持久化模型，与旧APKutils/j的单个进程static key机制不同。

字典findRecordByDeviceUUID是现代重连信任的入口；SSP手机端信任store没有本地现代APK源码佐证。`TrustRemove`被addRecord检查到存在路径，但删除/可见过滤策略尚未完整分析，标 **待验证**（同文件 `5201` 等）。

### 7.6 Dart 可实现的现代握手文字序列

1. 新建device transport，生成RSA-1024/e=65537；保存此次device实例的private key。
2. 生成Request01 Proto(type31、身份/版本、MD5/密文公钥、heartbeat设置)；发 `[sid=1][flag=0][u32be protoLen][proto]`。
3. 根据响应chunk格式收集逻辑消息，读u64 totalLen后解析Response01(type32)，取得deviceUuid和能力版本信息。
4. 查本地主机TrustStore：无record则trustType2；有record则放入stored trustType、derivedKey。生成Request02(type33、hostUuid、这些字段)，发 `[sid=2][flag=0][u32be protoLen][proto]`。
5. 连续接收Response02(type34)：Waiting1继续等待；No3结束；Once4/Always5保存手机returned derivedKey并检查result；其它值按未知/失败处理并保留证据。
6. `result`为Base64(RSA public encrypt(UTF8("ok")))；匹配private key解密等于`ok`时才进入ready。
7. ready后普通protobuf request使用新的sessionId、flag1、`signature128 || protobuf`，按sessionId路由response和push。裸上传文件flag3的具体session状态及文件头请结合现代文件传输实现。

**待验证清单**：现代设备网络端口/发现与USB AOAccessory起始步骤；手机侧确认UI及TrustType最终赋值；derivedKey生成/撤销；现代response chunk最大值及各消息长度规则；raw file flag3认证状态；同device实例之外RSA private key寿命；错误/退出是否复位手机public key。上述任何内容都不应自动套用旧APK `10086/19999` 和keep_alive_attr逻辑。


## 8. 现代SSP完整protobuf注册表与字段schema

本节是在 Java ADBForward 旧命令通道之外，直接从所提供的 mac `SmartFinderCore` 未剥离 Mach-O 恢复的 **69 个消息、328 个字段、8 个枚举**。来源为 `handshaker_analysis/Contents/Frameworks/SmartFinderCore.framework/Versions/A/SmartFinderCore`，未使用网络与第三方推测。下文 `dumps/` 是 `handshaker_analysis/dumps/`。

### 8.1 恢复方法和证据边界

`+[SSP... descriptor]` 将静态 `_descriptor.fields.*`、fieldCount 与 descriptorFlags 传给 GPBDescriptor。`LC_SEGMENT_64` 建立 VM 地址→文件偏移；`nm -nm` 提供非外部静态符号的地址；读取原始 field records。复核用反汇编保存为 `D/ssp_descriptors.disasm.txt`，全部原始字段十六进制与解码保存在 `D/ssp_descriptors.raw.txt`，机器可读版本为 `D/ssp_descriptors.json`。

descriptorFlags 的 bit0 表示 records 含 8 字节 default union：有默认值结构的每 record 40 字节，否则 32 字节。GPB runtime `initWithFieldDescription:includesDefault:syntax:` 明确在 includesDefault 时先将指针 +8。除 union 外字段结构为：`namePtr@0:ptr64`、`typeSpecific@8:ptr64`、`number@16:u32`、`hasIndex@20:i32`、`storageOffset@24:u32`、`flags@28:u16`、`datatype@30:u8`、`padding@31:u8`。**这些是本机 descriptor 内存布局，不是线字段偏移。** number/name/type 从 GPBFieldDescriptor getter 的代码核实。

flags：required=0x01、repeated=0x02、optional=0x08、hasDefault=0x10；其他位原样留在 raw evidence，不凭位名推断其协议意义。所有 recovered repeated 字段都是 string/message，不涉及 packed scalar。本文表中的字段名是 Objective-C 属性名（如 `register_p`、`fileArray`），原始 .proto 的文本拼写可能不同，但数字 tag 与线类型不受名字影响。重建稿有意保留 repeated 字段的 ObjC `Array` 后缀：`filesArray`、`imageArray` 等是普通 repeated message 属性名，不代表额外数组封装/计数字段；线编码仍是该 tag 的多次 key+length+message。

**已恢复的是消息 schema；不能单凭 metadata 确认现代通道的帧头、会话标识、加密模式、消息 direction 和每个字段的业务单位。** 与 Java `[command,subtype,version]` 不能混用。时间戳的 `ms/seconds`、checksum 字符串是否 hex、gzip 数据包范围等须从 operation 实现进一步核实。

### 8.2 Dart 编解码规则和字段动态偏移

这些消息是 Protobuf，不存在每字段固定字节偏移，也不保证每次字段顺序相同。每项使用 `key=varint((tag<<3)|wireType)`；要能跳过未知 tag，并按 number 查 schema。

| protobuf 类型 | wireType | value编码 | 一个字段从当前 body+p 开始的范围 |
|---|---:|---|---|
| bool、enum、uint32、uint64、int32、int64 | 0 | 无符号base128 varint；int32/int64为two's-complement，负值通常10字节；bool 0/1 | `key[kl] \|\| value[vl]`；next=`p+kl+vl` |
| sint32/sint64 | 0 | ZigZag之后varint（本 SSP 字段没有此类型） | 同上 |
| string | 2 | UTF-8 bytes；先varint byteLength | `key[kl] \|\| n[varint nl] \|\| UTF8[n]`；next=`p+kl+nl+n` |
| bytes | 2 | 不解释内容；先varint byteLength | 同上 |
| 嵌套message/repeated message | 2 | 完整嵌套 protobuf 消息；每项独立 key+length+payload | 同上，重复字段多次出现，不加数组count |
| double | 1 | IEEE754 64bit **小端** | `key[kl] \|\| LE64[8]`；next=`p+kl+8` |

wireType table 来自二进制 `_GPBWireFormatForType.format`，含 `(0,5,5,5,1,1,1,0,0,0,0,0,0,2,2,2,3,0)`；datatype 0..17 通过 `_MergeSingleFieldFromCodedInputStream` 的 jump table 分支分别调用 ReadBool/ReadFixed32/ReadSFixed32/ReadFloat/ReadFixed64/ReadSFixed64/ReadDouble/ReadInt32/ReadInt64/ReadSInt32/ReadSInt64/ReadUInt32/ReadUInt64/ReadBytes/ReadString/ReadMessage/ReadGroup/ReadEnum 核对（[D/ssp_descriptors.raw.txt:486-505](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L486)；jump-table分支反汇编见[D/ssp_descriptors.disasm.txt:7100](../handshaker_analysis/dumps/ssp_descriptors.disasm.txt#L7100)）。

这是 proto2 presence：optional 未设置时 getter 返回默认值，但 hasX=false，序列化省略；显式设置为默认值时 hasX=true，序列化会发送该字段；clear 恢复缺失状态。保留 presence，不能仅凭值等于 default 删除字段。**尤其 tag=1 type 必须明确编码**，否则独立解析为 SSPRequest 时默认值为 HeartBeatRequest=1，不能可靠按具体 message 的默认 type 推断路由。required clipboard tag=2 必须存在。uint64 在 Dart 中用 protobuf生成器的`fixnum.Int64`位表示或BigInt，保留全部64位；Dart signed int不足以表示大于2^63-1的正uint64。数值不经JSON double，在JS编译目标尤其保留精度。

### 8.3 RequestType：完整现代注册编号

与旧 ADB 数字不同。所有现代 request/response 都在 protobuf **tag=1** 放 SSPRequestType enum，key=08（wire0），不是固定头第一个 byte。

字段结构复核：[D/ssp_descriptors.disasm.txt:6607](../handshaker_analysis/dumps/ssp_descriptors.disasm.txt#L6607)、[D/ssp_descriptors.disasm.txt:6892](../handshaker_analysis/dumps/ssp_descriptors.disasm.txt#L6892)、[D/ssp_descriptors.disasm.txt:6861](../handshaker_analysis/dumps/ssp_descriptors.disasm.txt#L6861)；flags见 [D/ssp_descriptors.disasm.txt:6922](../handshaker_analysis/dumps/ssp_descriptors.disasm.txt#L6922) 与 [D/ssp_descriptors.disasm.txt:6941](../handshaker_analysis/dumps/ssp_descriptors.disasm.txt#L6941)。


| 值 | 真实枚举名 | descriptor 默认使用该编号的类 |
|---:|---|---|
| 1 | HeartBeatRequest | SSPRequest, SSPHeartBeatRequest, SSPHeartBeatResponse；[D/ssp_descriptors.raw.txt:400](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L400) |
| 2 | GetDeviceInfoRequest | SSPGetDeviceInfoRequest, SSPGetDeviceInfoResponse；[D/ssp_descriptors.raw.txt:401](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L401) |
| 3 | GetThumbnailRequest | SSPGetThumbnailRequest, SSPGetThumbnailResponse；[D/ssp_descriptors.raw.txt:402](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L402) |
| 4 | GetPhotoLibRequest | SSPGetPhotoLibraryRequest, SSPGetPhotoLibraryResponse；[D/ssp_descriptors.raw.txt:403](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L403) |
| 5 | GetVideoLibRequest | SSPGetVideoLibraryRequest, SSPGetVideoLibraryResponse；[D/ssp_descriptors.raw.txt:404](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L404) |
| 6 | GetAudioLibRequest | SSPGetAudioLibraryRequest, SSPGetAudioLibraryResponse；[D/ssp_descriptors.raw.txt:405](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L405) |
| 7 | GetDirFilesRequest | SSPGetDirFilesRequest, SSPGetDirFilesResponse；[D/ssp_descriptors.raw.txt:406](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L406) |
| 8 | GetFileCountRequest | SSPGetFileCountRequest, SSPGetFileCountResponse；[D/ssp_descriptors.raw.txt:407](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L407) |
| 9 | GetFileExistRequest | SSPFileExistRequest, SSPFileExistResponse；[D/ssp_descriptors.raw.txt:408](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L408) |
| 10 | GetCreateFolderRequest | SSPCreateFolderRequest, SSPCreateFolderResponse；[D/ssp_descriptors.raw.txt:409](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L409) |
| 11 | GetRenameFileRequest | SSPRenameFileRequest, SSPRenameFileResponse；[D/ssp_descriptors.raw.txt:410](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L410) |
| 12 | GetDownloadFileRequest | SSPDownloadFileRequest；[D/ssp_descriptors.raw.txt:411](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L411) |
| 13 | GetDownloadFileResponseHeader | SSPDownloadFileResponseHeader；[D/ssp_descriptors.raw.txt:412](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L412) |
| 14 | GetDownloadFileResponseBody | 无独立 message descriptor；需查 operation 原始数据路径；[D/ssp_descriptors.raw.txt:413](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L413) |
| 15 | GetUploadFileRequestHeader | SSPUploadFileRequest；[D/ssp_descriptors.raw.txt:414](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L414) |
| 16 | GetUploadFileResponseHeader | 存在同名 SSPUploadFileResponseHeader 类，但默认编号18；16线上使用待验证；[D/ssp_descriptors.raw.txt:415](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L415) |
| 17 | GetUploadFileRequestBody | 无独立 message descriptor；需查 operation 原始数据路径；[D/ssp_descriptors.raw.txt:416](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L416) |
| 18 | GetUploadFileResponse | SSPUploadFileResponseHeader, SSPUploadFileResponse；[D/ssp_descriptors.raw.txt:417](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L417) |
| 19 | GetDeleteFileRequest | SSPDeleteFileRequest, SSPDeleteFileResponse；[D/ssp_descriptors.raw.txt:418](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L418) |
| 20 | PhotoLibChange | SSPPhotoLibraryChange；[D/ssp_descriptors.raw.txt:419](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L419) |
| 21 | AudioLibChange | SSPAudioLibraryChange；[D/ssp_descriptors.raw.txt:420](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L420) |
| 22 | VideoLibChange | SSPVideoLibraryChange；[D/ssp_descriptors.raw.txt:421](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L421) |
| 23 | MonitorFolderRequest | SSPMonitorFolderRequest；[D/ssp_descriptors.raw.txt:422](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L422) |
| 24 | MonitorFolderResponseHeader | SSPMonitorFolderResponseHeader；[D/ssp_descriptors.raw.txt:423](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L423) |
| 25 | MonitorFolderResponse | SSPMonitorFolderResponse；[D/ssp_descriptors.raw.txt:424](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L424) |
| 26 | GetClipboardRequest | SSPGetClipboardRequest, SSPGetClipboardResponse；[D/ssp_descriptors.raw.txt:425](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L425) |
| 27 | PostClipboardRequest | SSPPostClipboardRequest, SSPPostClipboardResponse；[D/ssp_descriptors.raw.txt:426](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L426) |
| 28 | ClearClipboardRequest | SSPClearClipboardRequest, SSPClearClipboardResponse；[D/ssp_descriptors.raw.txt:427](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L427) |
| 29 | DeleteClipboardRequest | SSPDeleteClipboardRequest, SSPDeleteClipboardResponse；[D/ssp_descriptors.raw.txt:428](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L428) |
| 30 | ClipboardChange | SSPClipboardChange；[D/ssp_descriptors.raw.txt:429](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L429) |
| 31 | HandshakeRequest01 | SSPHandShakeRequest01；[D/ssp_descriptors.raw.txt:430](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L430) |
| 32 | HandshakeResponse01 | SSPHandShakeResponse01；[D/ssp_descriptors.raw.txt:431](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L431) |
| 33 | HandshakeRequest02 | SSPHandShakeRequest02；[D/ssp_descriptors.raw.txt:432](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L432) |
| 34 | HandshakeResponse02 | SSPHandShakeResponse02；[D/ssp_descriptors.raw.txt:433](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L433) |
| 35 | QuitRequest | SSPQuitRequest；[D/ssp_descriptors.raw.txt:434](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L434) |
| 36 | CancelRequest | SSPCancelRequest；[D/ssp_descriptors.raw.txt:435](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L435) |
| 37 | PhotoSyncRequest | SSPPhotoSyncRequest, SSPPhotoSyncResponse；[D/ssp_descriptors.raw.txt:436](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L436) |
| 38 | FileChange | SSPFileChange；[D/ssp_descriptors.raw.txt:437](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L437) |
| 39 | SyncMonitorRequest | SSPSyncMonitorRequest, SSPSyncMonitorResponse；[D/ssp_descriptors.raw.txt:438](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L438) |
| 40 | UpdateFileInfo | SSPUpdateFileRequest；[D/ssp_descriptors.raw.txt:439](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L439) |
| 41 | UpdateFileInfoResponse | SSPUpdateFileResponse；[D/ssp_descriptors.raw.txt:440](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L440) |

**重要原始差异：** `SSPUploadFileResponseHeader` 的 tag=1 默认值确实为18（GetUploadFileResponse），但 RequestType enum 中 GetUploadFileResponseHeader=16。此处按原始 metadata 记录，实际 operation 是否覆盖为16待验证，不能自行“修正”。GetDownloadFileResponseBody=14、GetUploadFileRequestBody=17 没有独立 Protobuf message descriptor，可能是文件原始数据流的标识，它们在本客户端走原始文件数据路径，实际外层flag与分块规则见现代传输/文件章节；手机端是否使用这些枚举作为额外标记待验证。

### 8.4 其他全部枚举

#### SSPFileEventType

[D/ssp_descriptors.raw.txt:441](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L441)；原始名称保持 Unknow 等拼写。

| 值 | 名称 |
|---:|---|
| 1 | FileEventCreate |
| 2 | FileEventDelete |
| 3 | FileEventCloseWrite |
| 4 | FileEventMovedFrom |
| 5 | FileEventMovedTo |
| 6 | FileEventDeleteSelf |
| 7 | FileEventMoveSelf |
| 8 | FileEventDirChanged |

#### SSPFileIOError

[D/ssp_descriptors.raw.txt:450](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L450)；原始名称保持 Unknow 等拼写。

| 值 | 名称 |
|---:|---|
| 1 | FileIoUnknowError |
| 2 | FileIoInvalidName |
| 3 | FileIoInvalidSource |
| 4 | FileIoTargetAlreadyExist |
| 5 | FileIoPermissionError |
| 6 | FileIoInsufficientDiskSpaceError |
| 7 | FileIoMd5CheckError |
| 8 | FileIoSystemFile |
| 9 | FileIoSdcardRemoved |
| 10 | FileIoSdcardNoPermission |

#### SSPFileIOPermission

[D/ssp_descriptors.raw.txt:461](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L461)；原始名称保持 Unknow 等拼写。

| 值 | 名称 |
|---:|---|
| 0 | AllowNone |
| 1 | AllowRead |
| 2 | AllowWrite |
| 3 | AllowReadWrite |

#### SSPHandShakeTrustType

[D/ssp_descriptors.raw.txt:466](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L466)；原始名称保持 Unknow 等拼写。

| 值 | 名称 |
|---:|---|
| 1 | TrustWaiting |
| 2 | TrustUnknow |
| 3 | TrustNo |
| 4 | TrustOnce |
| 5 | TrustAlways |
| 6 | TrustRemove |

#### SSPCancelErrorCode

[D/ssp_descriptors.raw.txt:473](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L473)；原始名称保持 Unknow 等拼写。

| 值 | 名称 |
|---:|---|
| 1 | ErrorCodeUnknown |
| 2 | ErrorCodeSdcardRemoved |

#### SSPFileType

[D/ssp_descriptors.raw.txt:476](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L476)；原始名称保持 Unknow 等拼写。

| 值 | 名称 |
|---:|---|
| 0 | Normal |
| 1 | Data |

#### SSPFileChangeStatus

[D/ssp_descriptors.raw.txt:479](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L479)；原始名称保持 Unknow 等拼写。

| 值 | 名称 |
|---:|---|
| 0 | None |
| 1 | Added |
| 2 | Deleted |
| 3 | Modified |
| 4 | InfoModified |
| 5 | FileAndInfoModified |


TrustType 的状态序列应由握手 operation决定；enum只证明 waiting/unknown/no/once/always/remove 数值，不能保证 Java 单阶段RSA握手支持这些信任状态。

### 8.5 完整字段表（全部消息）

每张表按 tag 显示，但 decoder 不依赖此顺序。“key hex”是 field key 的varint，不包括 value。每个字段的来源行同时给出原始 record bytes、tag、datatype、flags和默认union，可逐字节复核。enum 字段的类型列用 enum 名称，message 用嵌套类名。无显式默认时 string/bytes为空，numeric/bool为0/false，message未设置，enum按该enum首项。

#### SSPFile

[D/ssp_descriptors.raw.txt:2](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L2)；fieldCount=9。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 0a | path | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:3](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L3) |
| 2 | 10 | fileSize | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:4](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L4) |
| 3 | 18 | createdTimestamp | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:5](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L5) |
| 4 | 20 | modifiedTimestamp | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:6](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L6) |
| 6 | 30 | isDirectory | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:7](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L7) |
| 7 | 3a | checksum | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:8](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L8) |
| 8 | 40 | fileType | SSPFileType | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:9](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L9) |
| 9 | 4a | prefixMd5 | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:10](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L10) |
| 10 | 52 | extData | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:11](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L11) |

#### SSPImageFile

[D/ssp_descriptors.raw.txt:12](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L12)；fieldCount=19。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 0a | path | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:13](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L13) |
| 2 | 10 | fileSize | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:14](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L14) |
| 3 | 18 | createdTimestamp | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:15](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L15) |
| 4 | 20 | modifiedTimestamp | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:16](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L16) |
| 5 | 28 | width | uint32 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:17](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L17) |
| 6 | 30 | height | uint32 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:18](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L18) |
| 7 | 38 | orientation | uint32 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:19](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L19) |
| 8 | 40 | mediaId | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:20](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L20) |
| 9 | 48 | albumId | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:21](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L21) |
| 10 | 52 | mimeType | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:22](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L22) |
| 11 | 5a | thumbnail | bytes | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:23](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L23) |
| 12 | 62 | albumName | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:24](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L24) |
| 13 | 68 | dateTaken | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:25](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L25) |
| 14 | 72 | latitude | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:26](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L26) |
| 15 | 7a | longitude | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:27](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L27) |
| 16 | 82 01 | miniThumbMagic | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:28](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L28) |
| 17 | 8a 01 | title | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:29](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L29) |
| 18 | 90 01 | getThumbnailError | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:30](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L30) |
| 19 | 98 01 | starred | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:31](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L31) |

#### SSPImageAlbum

[D/ssp_descriptors.raw.txt:32](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L32)；fieldCount=4。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 0a | albumPath | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:33](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L33) |
| 2 | 10 | albumId | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:34](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L34) |
| 3 | 1a | albumName | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:35](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L35) |
| 4 | 22 | coverImage | SSPImageFile | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:36](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L36) |

#### SSPAudioFile

[D/ssp_descriptors.raw.txt:37](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L37)；fieldCount=27。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 0a | path | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:38](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L38) |
| 2 | 10 | fileSize | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:39](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L39) |
| 3 | 18 | createdTimestamp | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:40](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L40) |
| 4 | 20 | modifiedTimestamp | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:41](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L41) |
| 5 | 28 | mediaId | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:42](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L42) |
| 6 | 30 | albumId | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:43](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L43) |
| 7 | 3a | title | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:44](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L44) |
| 8 | 42 | mimeType | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:45](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L45) |
| 9 | 48 | artistId | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:46](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L46) |
| 10 | 52 | artist | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:47](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L47) |
| 11 | 5a | composer | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:48](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L48) |
| 12 | 60 | genre | uint32 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:49](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L49) |
| 13 | 6a | comment | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:50](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L50) |
| 14 | 72 | copyright | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:51](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L51) |
| 15 | 7a | audioCodec | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:52](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L52) |
| 16 | 80 01 | track | uint32 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:53](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L53) |
| 17 | 89 01 | duration | double | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:54](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L54) |
| 18 | 91 01 | startOffset | double | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:55](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L55) |
| 19 | 98 01 | year | uint32 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:56](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L56) |
| 20 | a0 01 | bitrate | uint32 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:57](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L57) |
| 21 | a9 01 | sampleRate | double | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:58](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L58) |
| 22 | b0 01 | playCount | uint32 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:59](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L59) |
| 23 | b9 01 | rating | double | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:60](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L60) |
| 24 | c0 01 | totalFrames | uint32 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:61](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L61) |
| 25 | c8 01 | bitspersample | uint32 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:62](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L62) |
| 26 | d0 01 | channels | uint32 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:63](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L63) |
| 27 | da 01 | genreName | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:64](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L64) |

#### SSPAudioAlbum

[D/ssp_descriptors.raw.txt:65](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L65)；fieldCount=8。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 0a | albumPath | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:66](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L66) |
| 2 | 10 | albumId | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:67](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L67) |
| 3 | 1a | albumName | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:68](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L68) |
| 4 | 20 | artistId | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:69](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L69) |
| 5 | 2a | artist | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:70](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L70) |
| 6 | 30 | year | uint32 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:71](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L71) |
| 7 | 3a | thumbnail | bytes | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:72](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L72) |
| 8 | 40 | getThumbnailError | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:73](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L73) |

#### SSPVideoFile

[D/ssp_descriptors.raw.txt:74](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L74)；fieldCount=13。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 0a | path | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:75](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L75) |
| 2 | 10 | fileSize | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:76](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L76) |
| 3 | 18 | createdTimestamp | uint32 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:77](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L77) |
| 4 | 20 | modifiedTimestamp | uint32 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:78](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L78) |
| 5 | 28 | width | uint32 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:79](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L79) |
| 6 | 30 | height | uint32 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:80](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L80) |
| 7 | 38 | orientation | uint32 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:81](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L81) |
| 8 | 40 | mediaId | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:82](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L82) |
| 9 | 48 | albumId | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:83](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L83) |
| 10 | 52 | mimeType | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:84](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L84) |
| 11 | 5a | thumbnail | bytes | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:85](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L85) |
| 12 | 60 | getThumbnailError | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:86](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L86) |
| 13 | 69 | duration | double | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:87](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L87) |

#### SSPVideoAlbum

[D/ssp_descriptors.raw.txt:88](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L88)；fieldCount=3。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 0a | albumPath | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:89](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L89) |
| 2 | 10 | albumId | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:90](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L90) |
| 3 | 1a | albumName | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:91](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L91) |

#### SSPDataRange

[D/ssp_descriptors.raw.txt:92](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L92)；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | offset | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:93](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L93) |
| 2 | 10 | length | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:94](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L94) |

#### SSPFileEvent

[D/ssp_descriptors.raw.txt:95](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L95)；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 0a | file | SSPFile | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:96](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L96) |
| 2 | 10 | event | SSPFileEventType | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:97](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L97) |

#### SSPRequest

[D/ssp_descriptors.raw.txt:98](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L98)；fieldCount=1。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:99](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L99) |

#### SSPHandShakeRequest01

[D/ssp_descriptors.raw.txt:100](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L100)；fieldCount=11。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 31 (HandshakeRequest01) | [D/ssp_descriptors.raw.txt:101](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L101) |
| 2 | 12 | hostUuid | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:102](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L102) |
| 3 | 1a | hostName | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:103](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L103) |
| 4 | 20 | hostTimestamp | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:104](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L104) |
| 5 | 2a | hostSmartSyncProtocolVersion | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:105](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L105) |
| 6 | 32 | hostAppVersion | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:106](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L106) |
| 7 | 3a | hostMinClientVersion | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:107](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L107) |
| 8 | 42 | md5 | bytes | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:108](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L108) |
| 9 | 4a | enckey | bytes | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:109](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L109) |
| 10 | 52 | hostModel | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:110](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L110) |
| 11 | 58 | heartbeatTimeoutSecond | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:111](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L111) |

#### SSPHandShakeResponse01

[D/ssp_descriptors.raw.txt:112](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L112)；fieldCount=11。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 32 (HandshakeResponse01) | [D/ssp_descriptors.raw.txt:113](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L113) |
| 2 | 12 | apkVersion | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:114](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L114) |
| 3 | 1a | apkVersionName | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:115](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L115) |
| 4 | 20 | clientTimestamp | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:116](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L116) |
| 5 | 2a | clientSmartSyncProtocolVersion | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:117](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L117) |
| 6 | 32 | clientMinHostVersion | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:118](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L118) |
| 7 | 3a | deviceUuid | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:119](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L119) |
| 8 | 42 | deviceName | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:120](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L120) |
| 9 | 4a | usbSerial | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:121](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L121) |
| 10 | 50 | isSmartisanDevice | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:122](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L122) |
| 11 | 58 | clientMinHostVersionCode | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:123](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L123) |

#### SSPHandShakeRequest02

[D/ssp_descriptors.raw.txt:124](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L124)；fieldCount=4。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 33 (HandshakeRequest02) | [D/ssp_descriptors.raw.txt:125](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L125) |
| 2 | 12 | hostUuid | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:126](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L126) |
| 3 | 1a | derivedKey | bytes | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:127](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L127) |
| 4 | 20 | trustType | SSPHandShakeTrustType | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:128](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L128) |

#### SSPHandShakeResponse02

[D/ssp_descriptors.raw.txt:129](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L129)；fieldCount=6。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 34 (HandshakeResponse02) | [D/ssp_descriptors.raw.txt:130](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L130) |
| 2 | 10 | trustType | SSPHandShakeTrustType | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:131](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L131) |
| 3 | 1a | deviceUuid | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:132](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L132) |
| 4 | 22 | deviceName | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:133](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L133) |
| 5 | 2a | derivedKey | bytes | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:134](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L134) |
| 6 | 32 | result | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:135](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L135) |

#### SSPHeartBeatRequest

[D/ssp_descriptors.raw.txt:136](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L136)；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 1 (HeartBeatRequest) | [D/ssp_descriptors.raw.txt:137](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L137) |
| 2 | 10 | hostTimestamp | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:138](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L138) |

#### SSPHeartBeatResponse

[D/ssp_descriptors.raw.txt:139](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L139)；fieldCount=3。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 1 (HeartBeatRequest) | [D/ssp_descriptors.raw.txt:140](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L140) |
| 2 | 10 | hostTimestamp | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:141](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L141) |
| 3 | 18 | clientTimestamp | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:142](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L142) |

#### SSPQuitRequest

[D/ssp_descriptors.raw.txt:143](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L143)；fieldCount=1。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 35 (QuitRequest) | [D/ssp_descriptors.raw.txt:144](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L144) |

#### SSPGetDeviceInfoRequest

[D/ssp_descriptors.raw.txt:145](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L145)；fieldCount=11。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 2 (GetDeviceInfoRequest) | [D/ssp_descriptors.raw.txt:146](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L146) |
| 2 | 10 | hostTimestamp | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:147](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L147) |
| 3 | 1a | hostSmartSyncProtocolVersion | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:148](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L148) |
| 4 | 20 | needDeviceInfoCallback | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:149](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L149) |
| 5 | 28 | needPhotoLibraryCallback | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:150](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L150) |
| 6 | 30 | needAudioLibraryCallback | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:151](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L151) |
| 7 | 38 | needVideoLibraryCallback | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:152](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L152) |
| 8 | 42 | hostAppVersion | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:153](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L153) |
| 9 | 4a | hostMinClientVersion | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:154](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L154) |
| 10 | 50 | hostType | uint32 | optional | 1 | [D/ssp_descriptors.raw.txt:155](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L155) |
| 11 | 58 | hostAppVersionCode | uint32 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:156](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L156) |

#### SSPGetDeviceInfoResponse

[D/ssp_descriptors.raw.txt:157](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L157)；fieldCount=36。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 2 (GetDeviceInfoRequest) | [D/ssp_descriptors.raw.txt:158](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L158) |
| 2 | 10 | hostTimestamp | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:159](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L159) |
| 3 | 1a | hostSmartSyncProtocolVersion | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:160](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L160) |
| 4 | 22 | apkVersion | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:161](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L161) |
| 5 | 28 | clientTimestamp | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:162](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L162) |
| 6 | 32 | clientSmartSyncProtocolVersion | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:163](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L163) |
| 7 | 3a | hostAppVersion | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:164](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L164) |
| 8 | 42 | hostMinClientVersion | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:165](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L165) |
| 9 | 4a | phoneModel | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:166](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L166) |
| 10 | 52 | phoneColor | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:167](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L167) |
| 11 | 58 | diskSize | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:168](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L168) |
| 12 | 60 | ramSize | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:169](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L169) |
| 13 | 69 | batteryCapacity | double | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:170](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L170) |
| 14 | 70 | batteryPercentage | uint32 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:171](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L171) |
| 15 | 7a | phoneName | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:172](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L172) |
| 16 | 80 01 | usedDiskSize | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:173](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L173) |
| 17 | 8a 01 | rootPath | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:174](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L174) |
| 18 | 92 01 | productBrand | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:175](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L175) |
| 19 | 9a 01 | productManufacturer | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:176](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L176) |
| 20 | a2 01 | smartisanVersion | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:177](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L177) |
| 21 | a8 01 | phoneLocked | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:178](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L178) |
| 22 | b2 01 | clientMinHostVersion | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:179](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L179) |
| 23 | ba 01 | apkVersionName | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:180](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L180) |
| 24 | c2 01 | externalStoragePath | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:181](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L181) |
| 25 | c8 01 | externalStoragePermission | SSPFileIOPermission | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:182](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L182) |
| 26 | d0 01 | extDiskSize | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:183](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L183) |
| 27 | d8 01 | extUsedDiskSize | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:184](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L184) |
| 28 | e2 01 | phoneId | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:185](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L185) |
| 29 | e8 01 | audioSize | int64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:186](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L186) |
| 30 | f0 01 | picVideoSize | int64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:187](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L187) |
| 31 | f8 01 | downloadSize | int64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:188](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L188) |
| 32 | 80 02 | otherSize | int64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:189](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L189) |
| 33 | 88 02 | appSize | int64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:190](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L190) |
| 34 | 90 02 | cacheSize | int64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:191](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L191) |
| 35 | 9a 02 | debugBuildTime | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:192](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L192) |
| 36 | a0 02 | clientMinHostVersionCode | int64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:193](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L193) |

#### SSPGetDirFilesRequest

[D/ssp_descriptors.raw.txt:194](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L194)；fieldCount=3。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 7 (GetDirFilesRequest) | [D/ssp_descriptors.raw.txt:195](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L195) |
| 2 | 12 | dir | SSPFile | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:196](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L196) |
| 3 | 18 | maxdepth | uint32 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:197](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L197) |

#### SSPGetDirFilesResponse

[D/ssp_descriptors.raw.txt:198](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L198)；fieldCount=5。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 7 (GetDirFilesRequest) | [D/ssp_descriptors.raw.txt:199](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L199) |
| 2 | 12 | dir | SSPFile | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:200](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L200) |
| 3 | 18 | maxdepth | uint32 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:201](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L201) |
| 4 | 20 | timecost | uint32 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:202](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L202) |
| 5 | 2a | fileArray | SSPFile | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:203](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L203) |

#### SSPGetFileCountRequest

[D/ssp_descriptors.raw.txt:204](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L204)；fieldCount=4。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 8 (GetFileCountRequest) | [D/ssp_descriptors.raw.txt:205](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L205) |
| 2 | 12 | dir | SSPFile | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:206](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L206) |
| 3 | 18 | maxdepth | uint32 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:207](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L207) |
| 4 | 22 | exclusionPatternArray | string | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:208](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L208) |

#### SSPGetFileCountResponse

[D/ssp_descriptors.raw.txt:209](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L209)；fieldCount=5。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 8 (GetFileCountRequest) | [D/ssp_descriptors.raw.txt:210](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L210) |
| 2 | 12 | dir | SSPFile | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:211](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L211) |
| 3 | 18 | maxdepth | uint32 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:212](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L212) |
| 4 | 22 | exclusionPatternArray | string | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:213](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L213) |
| 5 | 28 | count | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:214](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L214) |

#### SSPFileExistRequest

[D/ssp_descriptors.raw.txt:215](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L215)；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 9 (GetFileExistRequest) | [D/ssp_descriptors.raw.txt:216](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L216) |
| 2 | 12 | file | SSPFile | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:217](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L217) |

#### SSPFileExistResponse

[D/ssp_descriptors.raw.txt:218](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L218)；fieldCount=3。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 9 (GetFileExistRequest) | [D/ssp_descriptors.raw.txt:219](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L219) |
| 2 | 12 | file | SSPFile | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:220](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L220) |
| 3 | 18 | exist | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:221](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L221) |

#### SSPCreateFolderRequest

[D/ssp_descriptors.raw.txt:222](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L222)；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 10 (GetCreateFolderRequest) | [D/ssp_descriptors.raw.txt:223](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L223) |
| 2 | 12 | file | SSPFile | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:224](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L224) |

#### SSPCreateFolderResponse

[D/ssp_descriptors.raw.txt:225](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L225)；fieldCount=5。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 10 (GetCreateFolderRequest) | [D/ssp_descriptors.raw.txt:226](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L226) |
| 2 | 12 | file | SSPFile | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:227](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L227) |
| 3 | 18 | succeed | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:228](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L228) |
| 4 | 20 | errorCode | SSPFileIOError | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:229](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L229) |
| 5 | 2a | errorMessage | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:230](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L230) |

#### SSPRenameFileRequest

[D/ssp_descriptors.raw.txt:231](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L231)；fieldCount=3。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 11 (GetRenameFileRequest) | [D/ssp_descriptors.raw.txt:232](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L232) |
| 2 | 12 | sourceFile | SSPFile | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:233](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L233) |
| 3 | 1a | targetFile | SSPFile | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:234](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L234) |

#### SSPRenameFileResponse

[D/ssp_descriptors.raw.txt:235](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L235)；fieldCount=6。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 11 (GetRenameFileRequest) | [D/ssp_descriptors.raw.txt:236](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L236) |
| 2 | 12 | sourceFile | SSPFile | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:237](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L237) |
| 3 | 1a | targetFile | SSPFile | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:238](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L238) |
| 4 | 20 | succeed | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:239](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L239) |
| 5 | 28 | errorCode | SSPFileIOError | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:240](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L240) |
| 6 | 32 | errorMessage | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:241](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L241) |

#### SSPDeleteFileRequest

[D/ssp_descriptors.raw.txt:242](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L242)；fieldCount=4。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 19 (GetDeleteFileRequest) | [D/ssp_descriptors.raw.txt:243](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L243) |
| 2 | 12 | file | SSPFile | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:244](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L244) |
| 3 | 18 | isSync | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:245](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L245) |
| 4 | 20 | isTrash | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:246](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L246) |

#### SSPDeleteFileResponse

[D/ssp_descriptors.raw.txt:247](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L247)；fieldCount=5。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 19 (GetDeleteFileRequest) | [D/ssp_descriptors.raw.txt:248](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L248) |
| 2 | 12 | file | SSPFile | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:249](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L249) |
| 4 | 20 | succeed | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:250](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L250) |
| 5 | 28 | errorCode | SSPFileIOError | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:251](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L251) |
| 6 | 32 | errorMessage | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:252](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L252) |

#### SSPMonitorFolderRequest

[D/ssp_descriptors.raw.txt:253](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L253)；fieldCount=3。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 23 (MonitorFolderRequest) | [D/ssp_descriptors.raw.txt:254](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L254) |
| 2 | 12 | file | SSPFile | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:255](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L255) |
| 3 | 18 | register_p | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:256](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L256) |

#### SSPMonitorFolderResponseHeader

[D/ssp_descriptors.raw.txt:257](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L257)；fieldCount=3。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 24 (MonitorFolderResponseHeader) | [D/ssp_descriptors.raw.txt:258](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L258) |
| 2 | 10 | succeed | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:259](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L259) |
| 3 | 1a | errorMessage | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:260](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L260) |

#### SSPMonitorFolderResponse

[D/ssp_descriptors.raw.txt:261](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L261)；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 25 (MonitorFolderResponse) | [D/ssp_descriptors.raw.txt:262](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L262) |
| 2 | 12 | eventArray | SSPFileEvent | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:263](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L263) |

#### SSPDownloadFileRequest

[D/ssp_descriptors.raw.txt:264](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L264)；fieldCount=6。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 12 (GetDownloadFileRequest) | [D/ssp_descriptors.raw.txt:265](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L265) |
| 2 | 12 | file | SSPFile | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:266](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L266) |
| 3 | 1a | range | SSPDataRange | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:267](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L267) |
| 4 | 20 | needMd5 | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:268](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L268) |
| 5 | 28 | gzip | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:269](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L269) |
| 6 | 30 | isSync | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:270](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L270) |

#### SSPDownloadFileResponseHeader

[D/ssp_descriptors.raw.txt:271](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L271)；fieldCount=7。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 13 (GetDownloadFileResponseHeader) | [D/ssp_descriptors.raw.txt:272](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L272) |
| 2 | 12 | file | SSPFile | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:273](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L273) |
| 3 | 1a | range | SSPDataRange | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:274](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L274) |
| 4 | 20 | needMd5 | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:275](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L275) |
| 5 | 2a | dataMd5 | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:276](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L276) |
| 6 | 30 | ready | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:277](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L277) |
| 7 | 38 | errorCode | SSPFileIOError | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:278](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L278) |

#### SSPUploadFileRequest

[D/ssp_descriptors.raw.txt:279](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L279)；fieldCount=5。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 15 (GetUploadFileRequestHeader) | [D/ssp_descriptors.raw.txt:280](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L280) |
| 2 | 12 | file | SSPFile | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:281](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L281) |
| 3 | 1a | dataMd5 | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:282](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L282) |
| 4 | 20 | gzip | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:283](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L283) |
| 5 | 28 | isSync | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:284](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L284) |

#### SSPUploadFileResponseHeader

[D/ssp_descriptors.raw.txt:285](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L285)；fieldCount=4。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 18 (GetUploadFileResponse) | [D/ssp_descriptors.raw.txt:286](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L286) |
| 2 | 12 | file | SSPFile | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:287](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L287) |
| 3 | 18 | ready | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:288](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L288) |
| 4 | 20 | errorCode | SSPFileIOError | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:289](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L289) |

#### SSPUploadFileResponse

[D/ssp_descriptors.raw.txt:290](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L290)；fieldCount=5。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 18 (GetUploadFileResponse) | [D/ssp_descriptors.raw.txt:291](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L291) |
| 2 | 12 | file | SSPFile | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:292](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L292) |
| 3 | 18 | canceled | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:293](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L293) |
| 4 | 20 | succeed | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:294](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L294) |
| 5 | 28 | errorCode | SSPFileIOError | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:295](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L295) |

#### SSPGetThumbnailRequest

[D/ssp_descriptors.raw.txt:296](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L296)；fieldCount=4。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 3 (GetThumbnailRequest) | [D/ssp_descriptors.raw.txt:297](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L297) |
| 2 | 12 | imageArray | SSPImageFile | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:298](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L298) |
| 3 | 1a | videoArray | SSPVideoFile | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:299](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L299) |
| 4 | 22 | audioAlbumArray | SSPAudioAlbum | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:300](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L300) |

#### SSPGetThumbnailResponse

[D/ssp_descriptors.raw.txt:301](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L301)；fieldCount=4。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 3 (GetThumbnailRequest) | [D/ssp_descriptors.raw.txt:302](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L302) |
| 2 | 12 | imageArray | SSPImageFile | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:303](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L303) |
| 3 | 1a | videoArray | SSPVideoFile | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:304](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L304) |
| 4 | 22 | audioAlbumArray | SSPAudioAlbum | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:305](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L305) |

#### SSPGetPhotoLibraryRequest

[D/ssp_descriptors.raw.txt:306](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L306)；fieldCount=1。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 4 (GetPhotoLibRequest) | [D/ssp_descriptors.raw.txt:307](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L307) |

#### SSPGetPhotoLibraryResponse

[D/ssp_descriptors.raw.txt:308](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L308)；fieldCount=4。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 4 (GetPhotoLibRequest) | [D/ssp_descriptors.raw.txt:309](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L309) |
| 2 | 12 | imageArray | SSPImageFile | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:310](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L310) |
| 3 | 1a | albumArray | SSPImageAlbum | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:311](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L311) |
| 4 | 20 | cameraAlbumId | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:312](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L312) |

#### SSPGetVideoLibraryRequest

[D/ssp_descriptors.raw.txt:313](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L313)；fieldCount=1。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 5 (GetVideoLibRequest) | [D/ssp_descriptors.raw.txt:314](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L314) |

#### SSPGetVideoLibraryResponse

[D/ssp_descriptors.raw.txt:315](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L315)；fieldCount=3。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 5 (GetVideoLibRequest) | [D/ssp_descriptors.raw.txt:316](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L316) |
| 2 | 12 | videoArray | SSPVideoFile | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:317](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L317) |
| 3 | 1a | albumArray | SSPVideoAlbum | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:318](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L318) |

#### SSPGetAudioLibraryRequest

[D/ssp_descriptors.raw.txt:319](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L319)；fieldCount=1。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 6 (GetAudioLibRequest) | [D/ssp_descriptors.raw.txt:320](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L320) |

#### SSPGetAudioLibraryResponse

[D/ssp_descriptors.raw.txt:321](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L321)；fieldCount=3。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 6 (GetAudioLibRequest) | [D/ssp_descriptors.raw.txt:322](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L322) |
| 2 | 12 | audioArray | SSPAudioFile | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:323](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L323) |
| 3 | 1a | albumArray | SSPAudioAlbum | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:324](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L324) |

#### SSPPhotoLibraryChange

[D/ssp_descriptors.raw.txt:325](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L325)；fieldCount=3。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 20 (PhotoLibChange) | [D/ssp_descriptors.raw.txt:326](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L326) |
| 2 | 12 | addedImageArray | SSPImageFile | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:327](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L327) |
| 3 | 1a | deletedImageArray | SSPImageFile | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:328](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L328) |

#### SSPVideoLibraryChange

[D/ssp_descriptors.raw.txt:329](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L329)；fieldCount=4。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 22 (VideoLibChange) | [D/ssp_descriptors.raw.txt:330](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L330) |
| 2 | 12 | addedVideoArray | SSPVideoFile | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:331](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L331) |
| 3 | 1a | deletedVideoArray | SSPVideoFile | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:332](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L332) |
| 4 | 22 | updatedVideoArray | SSPVideoFile | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:333](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L333) |

#### SSPAudioLibraryChange

[D/ssp_descriptors.raw.txt:334](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L334)；fieldCount=4。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 21 (AudioLibChange) | [D/ssp_descriptors.raw.txt:335](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L335) |
| 2 | 12 | addedAudioArray | SSPAudioFile | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:336](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L336) |
| 3 | 1a | deletedAudioArray | SSPAudioFile | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:337](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L337) |
| 4 | 22 | addedAlbumArray | SSPAudioAlbum | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:338](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L338) |

#### SSPClipboard

[D/ssp_descriptors.raw.txt:339](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L339)；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 0a | content | bytes | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:340](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L340) |
| 2 | 10 | mstimestamp | int64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:341](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L341) |

#### SSPGetClipboardRequest

[D/ssp_descriptors.raw.txt:342](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L342)；fieldCount=1。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 26 (GetClipboardRequest) | [D/ssp_descriptors.raw.txt:343](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L343) |

#### SSPGetClipboardResponse

[D/ssp_descriptors.raw.txt:344](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L344)；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 26 (GetClipboardRequest) | [D/ssp_descriptors.raw.txt:345](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L345) |
| 2 | 12 | clipboardArray | SSPClipboard | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:346](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L346) |

#### SSPPostClipboardRequest

[D/ssp_descriptors.raw.txt:347](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L347)；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 27 (PostClipboardRequest) | [D/ssp_descriptors.raw.txt:348](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L348) |
| 2 | 12 | clipboard | SSPClipboard | required | —（隐式默认） | [D/ssp_descriptors.raw.txt:349](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L349) |

#### SSPPostClipboardResponse

[D/ssp_descriptors.raw.txt:350](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L350)；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 27 (PostClipboardRequest) | [D/ssp_descriptors.raw.txt:351](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L351) |
| 2 | 10 | succeed | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:352](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L352) |

#### SSPClearClipboardRequest

[D/ssp_descriptors.raw.txt:353](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L353)；fieldCount=1。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 28 (ClearClipboardRequest) | [D/ssp_descriptors.raw.txt:354](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L354) |

#### SSPClearClipboardResponse

[D/ssp_descriptors.raw.txt:355](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L355)；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 28 (ClearClipboardRequest) | [D/ssp_descriptors.raw.txt:356](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L356) |
| 2 | 10 | succeed | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:357](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L357) |

#### SSPDeleteClipboardRequest

[D/ssp_descriptors.raw.txt:358](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L358)；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 29 (DeleteClipboardRequest) | [D/ssp_descriptors.raw.txt:359](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L359) |
| 2 | 12 | clipboard | SSPClipboard | required | —（隐式默认） | [D/ssp_descriptors.raw.txt:360](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L360) |

#### SSPDeleteClipboardResponse

[D/ssp_descriptors.raw.txt:361](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L361)；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 29 (DeleteClipboardRequest) | [D/ssp_descriptors.raw.txt:362](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L362) |
| 2 | 10 | succeed | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:363](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L363) |

#### SSPClipboardChange

[D/ssp_descriptors.raw.txt:364](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L364)；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 30 (ClipboardChange) | [D/ssp_descriptors.raw.txt:365](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L365) |
| 2 | 12 | clipboardArray | SSPClipboard | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:366](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L366) |

#### SSPCancelRequest

[D/ssp_descriptors.raw.txt:367](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L367)；fieldCount=3。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 36 (CancelRequest) | [D/ssp_descriptors.raw.txt:368](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L368) |
| 2 | 10 | sessionId | uint64 | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:369](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L369) |
| 3 | 18 | errorCode | SSPCancelErrorCode | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:370](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L370) |

#### SSPPhotoSyncRequest

[D/ssp_descriptors.raw.txt:371](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L371)；fieldCount=3。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 37 (PhotoSyncRequest) | [D/ssp_descriptors.raw.txt:372](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L372) |
| 2 | 12 | pcId | string | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:373](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L373) |
| 3 | 1a | filesArray | SSPFile | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:374](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L374) |

#### SSPPhotoSyncResponse

[D/ssp_descriptors.raw.txt:375](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L375)；fieldCount=4。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 37 (PhotoSyncRequest) | [D/ssp_descriptors.raw.txt:376](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L376) |
| 2 | 10 | isFirst | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:377](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L377) |
| 3 | 1a | filesArray | SSPFile | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:378](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L378) |
| 4 | 20 | isSuccess | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:379](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L379) |

#### SSPFileChange

[D/ssp_descriptors.raw.txt:380](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L380)；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 38 (FileChange) | [D/ssp_descriptors.raw.txt:381](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L381) |
| 2 | 12 | fileChangeItemsArray | SSPFileChangeItem | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:382](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L382) |

#### SSPFileChangeItem

[D/ssp_descriptors.raw.txt:383](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L383)；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 0a | file | SSPFile | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:384](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L384) |
| 2 | 10 | status | SSPFileChangeStatus | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:385](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L385) |

#### SSPSyncMonitorRequest

[D/ssp_descriptors.raw.txt:386](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L386)；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 39 (SyncMonitorRequest) | [D/ssp_descriptors.raw.txt:387](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L387) |
| 2 | 10 | isSyncMonitor | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:388](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L388) |

#### SSPSyncMonitorResponse

[D/ssp_descriptors.raw.txt:389](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L389)；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 39 (SyncMonitorRequest) | [D/ssp_descriptors.raw.txt:390](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L390) |
| 2 | 10 | isSuccess | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:391](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L391) |

#### SSPUpdateFileRequest

[D/ssp_descriptors.raw.txt:392](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L392)；fieldCount=3。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 40 (UpdateFileInfo) | [D/ssp_descriptors.raw.txt:393](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L393) |
| 2 | 12 | filesArray | SSPFile | repeated | —（隐式默认） | [D/ssp_descriptors.raw.txt:394](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L394) |
| 3 | 18 | isSync | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:395](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L395) |

#### SSPUpdateFileResponse

[D/ssp_descriptors.raw.txt:396](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L396)；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 41 (UpdateFileInfoResponse) | [D/ssp_descriptors.raw.txt:397](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L397) |
| 2 | 10 | isSuccess | bool | optional | —（隐式默认） | [D/ssp_descriptors.raw.txt:398](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L398) |


### 8.6 按功能的现代消息序列（方向与重试细节待 operation复核）

以下请求→响应关系来自字段结构与名称；业务语义推断明确标记，包体 schema 已证实。

* 握手：31 HandShakeRequest01（主机标识/版本、md5/enckey）→32 HandShakeResponse01（手机标识/版本）；33 HandShakeRequest02（hostUuid、derivedKey、trustType）→34 HandShakeResponse02（trustType、derivedKey、result）。具体 md5/enckey/derivedKey 推导算法待验证，不能沿用 Java utils/j AES/RSA 的单阶段格式。
* 心跳：1 HeartBeatRequest(hostTimestamp)→1 HeartBeatResponse(hostTimestamp,clientTimestamp)。header tag1都默认1，response多出tag3。
* 设备与订阅：2 GetDeviceInfoRequest，tag4..7需要device/photo/audio/video callback→2 GetDeviceInfoResponse。随后的通知 type=20/21/22 对应 photo/audio/video Change；是否同一socket及callback触发条件待验证。
* 目录：7 GetDirFilesRequest(dir,maxdepth)→7 Response(dir,maxdepth,timecost,repeated file)。8 GetFileCountRequest(dir,maxdepth,exclusionPattern[])→8 Response(count)。9 FileExistRequest(file)→9 Response(exist)。
* 目录修改：10 CreateFolderRequest(file)→10 Response(succeed,errorCode,errorMessage)；11 RenameFileRequest(source,target)→11 Response(...)；19 DeleteFileRequest(file,isSync,isTrash)→19 Response(succeed,errorCode,errorMessage)。isTrash语义是否移到回收站待验证。
* 下载：12 DownloadFileRequest(file,range,needMd5,gzip,isSync)→13 ResponseHeader(file,range,dataMd5,ready,errorCode)→14文件数据。原始字节流长度/分块来自 range与header及operation；schema没有“blockIndex”字段。
* 上传：15 UploadFileRequest(file,dataMd5,gzip,isSync)→16 Header（metadata默认type=18的差异见上）→17文件数据→18 UploadFileResponse(canceled,succeed,errorCode)。是否Header在数据前响应以及文件流帧格式须operation核实。
* 监视：23 MonitorFolderRequest(file,register_p)→24 Header(succeed,errorMessage)；25 MonitorFolderResponse(repeated events)。每个event有file与FileEventType，不使用Java WatchCallback JSON。
* 剪贴板：26 GetClipboardRequest→26 Response(clipboard[])；27 PostClipboardRequest(required clipboard)→27 Response(succeed)；28 ClearClipboardRequest→28 Response(succeed)；29 DeleteClipboardRequest(required clipboard)→29 Response(succeed)；30 ClipboardChange(clipboard[])为变更通知。Clipboard.content是bytes，不是直接UTF8 string；具体编码/富文本支持待验证。mstimestamp是int64，名称暗示毫秒时间戳，单位待operation核实。
* 媒体库：4 Photo、5 Video、6 Audio请求→对应response arrays；3 Thumbnail请求和响应共有 image/video/audioAlbum arrays，通过嵌套 thumbnail bytes与getThumbnailError字段传图。图片相册coverImage是嵌套SSPImageFile，视频/音频相册结构不同。
* 取消与退出：36 CancelRequest(sessionId,errorCode)，35 QuitRequest（仅type）。不能用Java TERMINATE无body直接替代现代cancel。
* 照片同步：37 PhotoSyncRequest(pcId,files[])→37 Response(isFirst,files[],isSuccess)。FileChange=38含FileChangeItem(file,status)。39 SyncMonitorRequest(isSyncMonitor)→39 Response(isSuccess)。40 UpdateFileRequest(files[],isSync)→41 Response(isSuccess)。完整增量同步算法/冲突策略待验证。

这些schemas已达到可生成Dart消息类的粒度；实际互通必须结合各模式的帧编解码、密钥和会话规则，不能只有Protobuf字段表。

### 8.7 已交付的可编译schema与复现

`handshaker_open_docs/SmartSyncProtocol.recovered.proto` 是 proto2 重建稿，完整包含69messages/328fields/8enums；保留tag、类型、required/repeated、明确默认值，每message/enum注释引原始证据行。`package recovered.ssp` 是重建稿人工命名；字段名使用ObjC property，字节互通不受名字变化影响。通过本机protoc语法/descriptor_set编译。

复现（从仓库根执行）：

```sh
python3 handshaker_analysis/tools/recover_ssp_descriptors.py
python3 handshaker_analysis/tools/render_ssp_schema_docs.py
protoc --proto_path=handshaker_open_docs --descriptor_set_out=/tmp/ssp.pb handshaker_open_docs/SmartSyncProtocol.recovered.proto
```

extractor要求macOS nm、otool和该版原始二进制；GPB runtime jump-table地址及过滤行范围针对此artifact，不宣称适用其他版本。换版应重新确定metadata结构、符号和runtime分支。


## 9. 现代SSP文件流及全部功能语义

本节用mac方法反汇编补充现代功能的实际构造与消费行为。第一手证据从SmartFinderCore x86_64 Mach-O的ObjC反汇编提取保存到 `handshaker_analysis/dumps/modern_file_media.disasm.txt`，每个方法前有original_disasm_lines，可回溯原 `/tmp/handshaker_core_disasm.txt`；地址原样保留。立即数/CFString另保存在 `modern_file_media.constants.txt`。现代SSP使用protobuf；准确tag/type交由descriptor还原章节，不把它和APK的 `[cmd,subtype,version]` 自定义JSON消息混为一种。

### 9.1 已核实的传输边界与分块

`SSPFileTransferObject`在Mac中是本地对象，只有`file`和`hostPath`属性及其getter/setter（[D/modern_file_media.disasm.txt:9460–9520](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L9460)，以`-[SSPFileTransferObject file]`标签定位；汇编地址0xb3460–0xb353c）。实际分块路径**不把SSPFileTransferObject序列化为protobuf块**：writeThreadMain直接调用上传操作`readFileDataWithSize:hasMoreData:`，该函数返回`NSFileHandle.readDataOfLength(size)`的NSData，随后发给`device.sendFileData(data,sessionId,error)`（[D/modern_file_media.disasm.txt:10860–10899](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L10860)；地址0x43a3a–0x43b1a）。

现代请求包 `sendRequestData`先计算签名并拼到protobuf前，送入`sendData`时flag=1；文件块 `sendFileData`直接送入相同函数、flag=3，无签名，没有块内offset/count/protobuf字段（[D/modern_file_media.disasm.txt:14147](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L14147)附近，地址0x92940–0x929ba；[D/modern_file_media.disasm.txt:5057–5070](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L5057)，地址0x927db–0x92802）。这里的flag=3是现代传输层标记，不是旧APK的type=3 GET。现代外层帧的sessionId/flag/长度布局见主文档帧章节。

USB与Wi-Fi `maxDataPackageSize()`均返回`0x3ff7=16375`（[D/modern_file_media.disasm.txt:823](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L823)、1557）。writeThreadMain按此大小读文件，尾块为剩余字节。因此这份Mac客户端的文件数据payload通常<=16375；没有证据表明手机必须强制同样大小，重实现可先遵循该数值。文件块使用**同一个请求sessionId**，顺序写入，文件游标只在发送侧的NSFileHandle中记录；断点续传由请求中的range表达，不是逐块offset。

普通现代响应/文件ResponseHeader还有内层8字节BE长度：`SSPRequestOperation.appendData`从lenData取[0,8)，`CFSwapInt64BigToHost`得到protobuf长度N，累积N字节后完成（[D/modern_file_media.disasm.txt:2003](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L2003)；地址0x7e7bb–0x7e8bd）。上传/下载特化header parser也先取8字节、BE转为dataLength，然后把剩余内容交给相应ResponseHeader protobuf（[D/modern_file_media.disasm.txt:4234](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L4234)、4334，地址0x904ae–0x907bb；[D/modern_file_media.disasm.txt:7140](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L7140)、7240附近，地址0xa81f6–0xa8554）。

```text
响应头的逻辑流：
 relative 0 .. 7     uint64 BE N（protobuf字节数）
 relative 8 .. 8+N-1 ResponseHeader protobuf
 后续传输payload    文件原始字节（按外层session路由的不同块）
```

它是**逻辑流**的结构，不能假设每个TCP read或USB bulk read等于一个header/块。普通operation lenData能积攒不足8字节，文件特化parser则源码未见不足8字节保护；Dart应正确缓冲拆包，不能复制该薄弱点。文件header与body被客户端不同阶段解释，服务端若将它们拼在同一次operation.appendData参数中，现有Mac parser是否正确分割**待验证**；兼容服务端宜确保header逻辑payload精确结束于8+N，再发body数据帧。

### 9.2 原生SSP上传流程（已核实Mac发送行为）

上传构造器先确认源文件存在且为普通文件，打开NSFileHandle（[D/modern_file_media.disasm.txt:3541](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L3541)开始，地址0x8fa3e–0x8fb8c）。它构造：

- `SSPUploadFileRequest.type = operation.type`。
- `file.path = 目标路径`，`file.fileSize = 本地文件size`，`file.modifiedTimestamp/createdTimestamp = Unix epoch秒整数`；这里timeIntervalSince1970转换为整数后设置，没有乘1000（[D/modern_file_media.disasm.txt:3711–3810](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L3711)；0x8fca0–0x8fe12）。
- `file.isDirectory = false`；`file.checksum = getMD5WithFilePath(本地源)`（[D/modern_file_media.disasm.txt:3832](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L3832)附近；0x8fe43–0x8febe）。
- `request.file = file`，`request.dataMd5 = ""`，`request.isSync = 入参`（[D/modern_file_media.disasm.txt:3840–3865](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L3840)；0x8feec–0x8ff31）。空字符串通过CFString对象地址0x2ae958直接解码确认（[D/modern_file_media.constants.txt:3](../handshaker_analysis/dumps/modern_file_media.constants.txt#L3)）。因此不要误把上传dataMd5宣称为当前Mac实际传完整文件MD5；它在file.checksum。
- `bodySize = file.fileSize`，进度回调保存于operation（0x8ff57–0x8ff97）。当前构造器未设置request.range或gzip；完整上传从NSFileHandle offset0开始。

writeThreadMain首先发送请求一次，将didSendRequestData置true（0x436d1–0x43923）。收到 `8-byte N + SSPUploadFileResponseHeader` 后读ready：ready=false先markCancel并转换errorCode后结束；ready=true设置isReadyToUploadFileData=true（[D/modern_file_media.disasm.txt:4401](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L4401)、4572；0x908a2–0x90bf4）。errorCode至少显式识别5、6、8、9、10；具体枚举由schema章节解释，不根据Mac NSError数字强行猜。

ready=true后，writeThreadMain持续读取<=16375原始字节，并调用sendFileData同sessionId、flag3（[D/modern_file_media.disasm.txt:10860–10899](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L10860)）。`readFileDataWithSize`以NSFileHandle offsetInFile与request.file.fileSize比较，设置hasMoreData=false/true；没有range-offset字段嵌在每块（[D/modern_file_media.disasm.txt:4707–4747](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L4707)；0x90e2b–0x90eee）。

**完成语义非常关键**：发送尾块后writeThreadMain调用markSent（[D/modern_file_media.disasm.txt:11048](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L11048)），上传operation覆写markSent后直接`callFinishBlockWithError:nil`（[D/modern_file_media.disasm.txt:4126–4134](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L4126)；0x90341–0x90358）。该Mac实现的成功回调代表“全部文件数据已送出”，没有等待 `SSPUploadFileResponse` 的明确最终确认；class存在不能证明该路径消费它。手机落盘/MD5成功的最终ack是否另有路径**待验证**。Dart重实现若目标是准确复刻Mac，应区分本地发送完成与服务器确认完成。

```text
电脑 -> 手机: flag1/session S，签名 + SSPUploadFileRequest protobuf
手机 -> 电脑: session S，8字节BE N + SSPUploadFileResponseHeader
电脑: 等ready；false则cancel/error；true才开始发送文件
电脑 -> 手机: flag3/session S，原始文件字节块0（<=16375）
电脑 -> 手机: flag3/session S，原始文件字节块1 ... 尾块
电脑: EOF -> markSent -> 本地成功callback、closeFile
[手机最终确认/落盘/校验通知：本路径未消费，待验证]
```

### 9.3 原生SSP下载流程（已核实Mac接收行为）

构造 `SSPDownloadFileRequest`：file.path=远端路径；建立SSPDataRange并设offset=0、length=0；needMd5初始false并写入请求；isSync来自入参（[D/modern_file_media.disasm.txt:5577](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L5577)、5648、5663；0xa641a–0xa663b）。length=0用于此客户端的完整文件下载请求，但服务端把0解释成“到EOF”的逻辑需另一端证据验证。

本地缓冲文件附加`.hsdownload`扩展（字符串`SmartFinderCore.strings.txt:16432`，调用0xa664b–0xa6677），创建父目录、删除既有buffer文件，再从头建立新文件供写入（[D/modern_file_media.disasm.txt:5730](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L5730)附近，0xa66b4–0xa689e）；此构造路径不是续传已有buffer。

收到header前，accumulate `8-byte BE N + SSPDownloadFileResponseHeader`；ready=false读errorCode，至少errorCode9特殊转换后cancel/finish；ready=true且header.file.fileSize=0则立即完成（[D/modern_file_media.disasm.txt:7140](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L7140)、7298–7360；0xa82a7–0xa875d）。其他情况进入data阶段。

header存在时每个后续appendData参数都直接 `fileHandle.writeData(data)`，transferedSize += data.length（[D/modern_file_media.disasm.txt:6674–6692](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L6674)；0xa78da–0xa7907）。bodySize取header.range.length，而不是请求原先的0；transferedSize达到header.range.length即完成（[D/modern_file_media.disasm.txt:6863](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L6863)；0xa7bff–0xa7ce4）。这说明**响应range.length必须是实际期望接收数据长度**，不能让Dart根据每块自行推断总长。range.offset未用于这个完整下载路径seek，本地是从0顺序写入。

若_needMd5=true：MD5_Init -> 每块MD5_Update -> 达到总长后MD5_Final，编码为32个hex字符，与header.dataMd5作case-insensitive比较（[D/modern_file_media.disasm.txt:6734](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L6734)、7004；0xa6d46–0xa6d6e、0xa79b5–0xa7a29、0xa7d13–0xa7fdc）。不匹配报NSError code0x26（0xa807e）。但默认needMd5=false，不能说此Mac客户端每次下载一定校验MD5。

成功结束时closeFile，恢复header.file.modifiedTimestamp/createdTimestamp为本地NSDate（秒），移除最终旧文件，将`.hsdownload`移动成目标文件；出错删除buffer（0xa6f9f–0xa75ba）。gzip属性虽在protobuf中存在，但此下载body路径没有inflate调用，客户端默认不启用文件gzip；启用时线行为**待验证**。

```text
电脑 -> 手机: flag1/session S，签名 + SSPDownloadFileRequest(file.path, range={0,0}, needMd5=false,...)
手机 -> 电脑: session S，8字节BE N + SSPDownloadFileResponseHeader(ready,file,range,dataMd5?)
电脑: 检查ready；创建/保持.hsdownload文件
手机 -> 电脑: session S，原始文件字节块序列（外层传输层flag见帧章节）
电脑: 顺序writeData；累计字节直到header.range.length
电脑: 如果needMd5开启则计算并核对header.dataMd5
电脑: 恢复mtime/ctime，buffer改名为目标，本地成功callback
```

### 9.4 现代目录与文件操作：调用链已核实

这些功能可用protobuf descriptor给出的消息编码实现，不需要套用旧APK JSON：

| 操作 | Mac实际构造语义 | 第一手证据 反汇编行号/地址 |
|---|---|---|
| 普通目录浏览 | SSPGetDirFilesRequest.dir=SSPFile(path,isDirectory=true)，maxdepth=1 | [D/modern_file_media.disasm.txt:7619](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L7619)附近，0xb136e–0xb13d5 |
| 下载目录递归列举 | 同上，maxdepth=4294967295=0xffffffff（uint32；wire varint为 ff ff ff ff 0f，共5字节） | [D/modern_file_media.disasm.txt:8602](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L8602)附近，0xb24ee–0xb2542 |
| 目录响应 | SSPGetDirFilesResponse.initWithData，遍历fileArray；isDirectory转SFDirectoryFile，否则按fileForSSPFile转换 | [D/modern_file_media.disasm.txt:7812–8150](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L7812)，0xb1735–0xb1de0；递归版0xb2809–0xb2be4 |
| 创建文件夹 | SSPCreateFolderRequest.file=SSPFile(path=入参目录对象.path)；解析SSPCreateFolderResponse | [D/modern_file_media.disasm.txt:927](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L927)附近，0x6a06b–0x6a0cb，response block随后 |
| 重命名 | sourceFile.path=旧路径；targetFile.path=删除旧末级路径后拼入新名字；解析SSPRenameFileResponse.succeed等 | [D/modern_file_media.disasm.txt:140](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L140)附近，0x7aa6–0x7c06 |
| 删除 | SSPDeleteFileRequest.file.path=入参路径，同时设isSync和isTrash；解析SSPDeleteFileResponse | [D/modern_file_media.disasm.txt:2352](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L2352)附近，0x8e50e–0x8e55b |

文字序列：普通浏览发dir/maxdepth1 -> 响应fileArray -> 按isDirectory展示；进入子目录再次发其路径。递归上传/下载前可发maxdepth=0xffffffff进行分析。创建/重命名/删除每次发对应protobuf并等待succeed/error。是否执行物理删除、垃圾箱目录、权限检查由手机现代实现决定；isTrash=false/true的服务端具体落盘行为**待验证**，不可用Mac调用参数推定目录。

### 9.5 现代剪贴板已经确认的编码与时间戳

`SFClipboard.setStringContent`按NSUTF8StringEncoding=4将文本转NSData，再`gzipDeflate`，存content；stringContent反向gzipInflate再UTF-8（[D/modern_file_media.disasm.txt:14546](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L14546)、14556、14601、14618；0xa1c17–0xa1c64、0xa1cc4–0xa1d2c）。所以SSPClipboard.content用于文本时是**gzip压缩的UTF-8字节**，不是直接UTF-8或base64字符串。

- 获取：SSPGetClipboardRequest仅设置type；收到SSPGetClipboardResponse后遍历clipboardArray，逐条构造SFClipboard（[D/modern_file_media.disasm.txt:3127–3170](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L3127)；0x8f29e–0x8f381）。
- 发布：SSPPostClipboardRequest.clipboard=新SSPClipboard；content直接复制传入SFClipboard.content（[D/modern_file_media.disasm.txt:5185](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L5185)；0xa360b–0xa3637）。mstimestamp由当前NSDate.timeIntervalSince1970先`NSNumber.longLongValue`取整秒，再乘double1000.0后设置（[D/modern_file_media.disasm.txt:5224](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L5224)附近；0xa36ec–0xa372c，[D/modern_file_media.constants.txt:2](../handshaker_analysis/dumps/modern_file_media.constants.txt#L2)）。因此该Mac发布消息实际为**epoch毫秒但精度1秒**，Dart可复刻 `secondsSinceEpoch.floor()*1000`；不要先乘1000再floor而声称逐字节一致。
- 单条删除：SSPDeleteClipboardRequest.clipboard.content与mstimestamp均从目标SFClipboard复制（[D/modern_file_media.disasm.txt:9664–9675](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L9664)；0xc5995–0xc5a2c）；没有看到另设ID，记录定位至少包含这两个字段。
- 清空：SSPClearClipboardRequest只设置type；回调解析SSPClearClipboardResponse.succeed（[D/modern_file_media.disasm.txt:1565–1780](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L1565)；0x7c4c0–0x7c7de）。Post/Delete响应也解析succeed；各准确tags见schema。

```text
电脑: string -> UTF-8 -> gzip -> SSPClipboard.content
电脑 -> 手机: SSPPostClipboardRequest(clipboard={content,mstimestamp},type)
手机 -> 电脑: SSPPostClipboardResponse(succeed)
电脑 -> 手机: SSPGetClipboardRequest(type)
手机 -> 电脑: SSPGetClipboardResponse(clipboardArray)
电脑: 每条content gunzip -> UTF-8，mstimestamp用于定位/展示
电脑 -> 手机: SSPDeleteClipboardRequest(目标content+mstimestamp) 或 ClearClipboardRequest
手机 -> 电脑: 对应Response(succeed)
```

`SSPManager.registerClipboardChange:withBlock:`只配置Mac本地callback（原反汇编0x665ab–0x66647），注册的手机握手needClipboardCallback字段是否存在/如何启用以descriptor与握手章节核实。不要把本地注册selector当成一条新的网络消息。

### 9.6 现代MonitorFolder

`SSPMonitorFolderRequestOperation`建立file.path，去掉末尾`/`，设置request.file，`register_p=true/false`由入参isRegister决定（[D/modern_file_media.disasm.txt:14738–14931](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L14738)；0x8009f–0x8028d）；响应回调将数据按SSPMonitorFolderResponseHeader解析，再返回本地SSPWatchCallbackItem(path)（[D/modern_file_media.disasm.txt:15045–15100](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L15045)；0x80477–0x8056e）。这个WatchCallbackItem是本地callback模型，不能凭名字宣称为线上protobuf或套用APK type9 JSON。

线上结构（[D/ssp_descriptors.raw.txt:253–263](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L253)）：Request `type#1=23,file#2:SSPFile,register_p#3:bool`；ResponseHeader `type#1=24,succeed#2:bool,errorMessage#3:string`；后续push Response `type#1=25,eventArray#2:SSPFileEvent[]`。每个event含`file#1:SSPFile,event#2:SSPFileEventType`（[D/ssp_descriptors.raw.txt:95–97](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L95)）；event值为1Create、2Delete、3CloseWrite、4MovedFrom、5MovedTo、6DeleteSelf、7MoveSelf、8DirChanged（[D/ssp_descriptors.raw.txt:441–449](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L441)），**不是旧APK FileObserver位掩码**。

文字序列：电脑 -> MonitorFolderRequest(file.path,register_p=true) -> 手机 -> MonitorFolderResponseHeader(succeed/errorMessage)；Mac将path与observerCallbacks建立关联；手机随后独立push MonitorFolderResponse(eventArray)；注销发送同path register_p=false并等待Header。Mac push路由确实解析type25，但只取`eventArray.firstObject`，再读event.file.path，按路径前缀和event值路由本地watchCallbackItems（[D/modern_file_media.disasm.txt:12345–12375](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L12345)、12400–12422、12694；0x634fd–0x635a3、0x6363a–0x636ae、0x63c88）。schema允许一帧多个event，Dart应遍历整个数组；Mac只取首项不能证明手机必发单事件。监听是否递归、路径前缀边界、目录变更合并策略均**现代手机效果待验证**。

### 9.7 实现边界

汇编确认的是**Mac客户端预期和发送行为**；当前APK不包含现代protobuf守护服务，不能验证现代手机端是否允许range>0、非默认gzip、最终上传ack、异常恢复等。文档应同时给出两套格式的已核实范围，不让“Dart从零实现”误以为当前APK支持现代SSP所有消息。实际互通还需：针对目标手机端版本抓包；验证ResponseHeader和body拆分；验证大文件>4GiB、空文件、失连取消；验证同session多块顺序及range续传。


### 9.8 现代媒体库、缩略图与变化通知

本节字段引用指向 `D/ssp_descriptors.raw.txt`。`#n`是protobuf字段号而不是固定字节偏移；所有列表是repeated message，字符串为UTF-8 length-delimited，bytes为原始length-delimited，ID为uint64 varint。现代媒体请求/响应是protobuf，没有旧APK的JSON/gzip布局。

#### 完整媒体库读取

| 功能/type | 线上请求 -> 响应字段 | Mac消费行为与第一手证据 |
|---|---|---|
| 照片库/4 | Request仅`type#1=4`；Response `type#1=4,imageArray#2:SSPImageFile[],albumArray#3:SSPImageAlbum[],cameraAlbumId#4:uint64` | 构造器只设type，cameraDir是Mac本地捕获值（[D/modern_file_media.disasm.txt:25036–25136](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L25036)，0xa3c02–0xa3cd0）；解析Response后检查hasCameraAlbumId，创建相册，再遍历imageArray，按albumId归组（[D/modern_file_media.disasm.txt:25281–25381](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L25281)、25477–25530、25730–25783、26205–26233；0xa3fe3–0xa4217、0xa441f–0xa4552、0xa4987–0xa4aba、0xa53c8–0xa5468）。字段证据D/ssp_descriptors.raw.txt:306–312。 |
| 视频库/5 | Request仅`type#1=5`；Response `type#1=5,videoArray#2:SSPVideoFile[],albumArray#3:SSPVideoAlbum[]` | 构造器只设type，cameraDir/sdcardCameraDir用于本地分类（[D/modern_file_media.disasm.txt:22177–22304](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L22177)，0x9a5fe–0x9a74b）；先albumArray建相册，再videoArray建SFVideoFile，按albumId归组（[D/modern_file_media.disasm.txt:22465–22473](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L22465)、22575–22589、22755–22784、22896–22949、23302–23330）。字段证据D/ssp_descriptors.raw.txt:313–318。 |
| 音频库/6 | Request仅`type#1=6`；Response `type#1=6,audioArray#2:SSPAudioFile[],albumArray#3:SSPAudioAlbum[]` | 构造器只设type（[D/modern_file_media.disasm.txt:23874–23947](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L23874)，0xa1f42–0xa1fa8）；先建立SFAudioAlbum，再建立SFAudioFile，以albumId关联children和album属性（[D/modern_file_media.disasm.txt:24074–24082](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L24074)、24168–24243、24370–24423、24492–24528；0xa2252–0xa2284、0xa2464–0xa261c、0xa28ba–0xa29ed、0xa2b75–0xa2c41）。字段证据D/ssp_descriptors.raw.txt:319–324。 |

最小请求protobuf分别是`08 04`、`08 05`、`08 06`，仍需按现代帧章节加签名和传输封装。没有在线的分页/albumId过滤字段；相册浏览可以在收到的完整列表上用albumId筛选。照片的cameraAlbumId是optional，Dart须保留`has`状态，不能把缺失直接当真实ID0。相册/媒体模型的所有可选属性和精确类型见完整schema；现代手机端对隐藏目录、音频is_music、排序及权限的具体筛选规则**待验证**，不能直接套用旧APK的MediaStore SQL。

```text
电脑 -> 手机: GetDeviceInfoRequest(type=2,needPhotoLibraryCallback=true,
               needAudioLibraryCallback=true,needVideoLibraryCallback=true,...)
手机 -> 电脑: GetDeviceInfoResponse(设备/存储信息)
电脑: 注册本地photo/audio/video回调
电脑 -> 手机: GetPhotoLibraryRequest(type=4) [独立session]
手机 -> 电脑: 内层BE64长度 + GetPhotoLibraryResponse(imageArray,albumArray,cameraAlbumId?)
电脑 -> 手机: GetVideoLibraryRequest(type=5) / GetAudioLibraryRequest(type=6)
手机 -> 电脑: 对应完整列表Response
电脑: 将每种文件的albumId与album.albumId关联，在本地显示相册/专辑
手机 -> 电脑: 后续独立push PhotoLibraryChange / AudioLibraryChange / VideoLibraryChange
电脑: 以mediaId更新缓存；需要图像的新增条目再发GetThumbnailRequest
```

三个need*Callback字段位于GetDeviceInfoRequest #5/#6/#7（[D/ssp_descriptors.raw.txt:145–156](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L145)），Mac确实都设置true：[D/modern_file_media.disasm.txt:31362–31376](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L31362)，0x8c822–0x8c865。`SSPManager.registerMediaLibraryChange:withBlock:`只设置本地photo/video/audioCallback，没有构造或enqueue新的网络消息（[D/modern_file_media.disasm.txt:27317–27448](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L27317)，0x4a710–0x4a9af）。因此注册本地观察者与向手机请求推送是两个动作；push何时开始、是否有首次快照竞态仍需手机互通验证。

#### 缩略图请求有ID与路径两种定位

GetThumbnailRequest/Response共用`type#1=3,imageArray#2:SSPImageFile[],videoArray#3:SSPVideoFile[],audioAlbumArray#4:SSPAudioAlbum[]`（[D/ssp_descriptors.raw.txt:296–305](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L296)），各记录也可含thumbnail/getThumbnailError字段。Mac构造行为：

- 照片模式：只创建SSPImageFile并设置mediaId，再append imageArray；本地字典按mediaId匹配响应（[D/modern_file_media.disasm.txt:15399–15430](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L15399)、15753–15768；0x2066–0x210b、0x27b8–0x2807）。
- 视频模式：只创建SSPVideoFile并设置mediaId，append videoArray；同样按mediaId匹配（[D/modern_file_media.disasm.txt:16165–16196](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L16165)；0x2fd6–0x307b）。
- 音频封面：创建SSPAudioAlbum只设置albumId，append audioAlbumArray；按albumId匹配（[D/modern_file_media.disasm.txt:16931–16962](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L16931)；0x3f46–0x3feb）。这不是发送音频文件mediaId。
- 普通目录的图片/视频：按SFImageFile/SFVideoFile的类型放入对应数组，设置path，**显式设置mediaId=0**，本地按path匹配响应（[D/modern_file_media.disasm.txt:17725–17741](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L17725)、17816–17829；0x4f54–0x4fa2、0x5137–0x5178）。音频路径模式未在withFiles构造器中出现；支持情况**待验证**。

收到Response后Mac先读getThumbnailError，再读thumbnail字节，用NSImage.initWithData解码并保留originalData（[D/modern_file_media.disasm.txt:15757–15850](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L15757)，0x27c6–0x29c5；路径模式D/modern_file_media.disasm.txt:18190–18285，0x58eb–0x5aee）。因此Dart应逐项报告失败，以ID/路径匹配而非请求数组位置；现代响应bytes的具体JPEG/PNG、尺寸、质量、EXIF处理**待验证**，当前Mac消费者不能证明一定为旧APK的JPEG86/200px。

```text
电脑 -> 手机: GetThumbnailRequest(type=3,imageArray=[{mediaId:42},{mediaId:43}])
手机 -> 电脑: GetThumbnailResponse(imageArray=[{mediaId:43,thumbnail:bytes,...},
               {mediaId:42,getThumbnailError:true,...}])
电脑: 按mediaId关联每项，失败项保留错误，成功项解码图像
或电脑 -> 手机: GetThumbnailRequest(imageArray=[{path:"/.../a.jpg",mediaId:0}],
               videoArray=[{path:"/.../b.mp4",mediaId:0}])
手机 -> 电脑: 对应path及thumbnail/getThumbnailError
或电脑 -> 手机: GetThumbnailRequest(audioAlbumArray=[{albumId:7}])
手机 -> 电脑: audioAlbumArray=[{albumId:7,thumbnail:bytes,getThumbnailError:false}]
```

#### 媒体push不是完整库替换

| type/消息 | protobuf增量字段（[D/ssp_descriptors.raw.txt:325–338](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L325)） | 路由确认 |
|---|---|---|
| 20 PhotoLibraryChange | `addedImageArray#2,deletedImageArray#3`，均SSPImageFile[] | [D/modern_file_media.disasm.txt:11764–11835](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L11764)；0x6294c–0x62ac5 |
| 21 AudioLibraryChange | `addedAudioArray#2,deletedAudioArray#3:SSPAudioFile[];addedAlbumArray#4:SSPAudioAlbum[]` | [D/modern_file_media.disasm.txt:11942–12013](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L11942)；0x62cdb–0x62e54 |
| 22 VideoLibraryChange | `addedVideoArray#2,deletedVideoArray#3,updatedVideoArray#4`，均SSPVideoFile[] | [D/modern_file_media.disasm.txt:12120–12191](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L12120)；0x6306a–0x631e3 |

SSPManager先用SSPRequest读取type，再解析上述具体protobuf并调用已注册的对应callback；每次push更新lastHeartBeat（[D/modern_file_media.disasm.txt:11547–11568](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L11547)、11926、12104、12282）。照片没有updatedImageArray、音频没有deletedAlbumArray或updatedAudioArray字段，这些变化如何由服务端表达**待验证**。实现者不得为了统一模型生成不存在的线上字段；可在收到已证明的增量后重新获取完整列表。

### 9.9 现代辅助文件/同步功能矩阵

以下消息都经现代通用请求session发送、普通响应采用BE64长度前缀+protobuf；字段布局由descriptor确认，实际构造与消费由Mac汇编进一步限定。`SSPFile`的path/fileSize/时间/isDirectory/checksum/fileType/prefixMd5/extData tags见完整schema。这里不能从一个response成功布尔值证明现代手机具体写入了什么。

| 功能/type | Request字段 -> Response字段（不重复type#1） | Mac实际值、消费与待验证边界 |
|---|---|---|
| GetFileCount /8 | `dir#2:SSPFile,maxdepth#3:uint32,exclusionPatternArray#4:string[]` -> 同名#2/#3/#4，`count#5:uint64`（[D/ssp_descriptors.raw.txt:204–214](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L204)） | dir仅设置path，排除模式数组直接append；**maxdepth=5**，不是目录浏览的1或递归0xffffffff（[D/modern_file_media.disasm.txt:21233–21280](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L21233)，0x8936c–0x89452）。回调读count并返回NSNumber（[D/modern_file_media.disasm.txt:21428–21503](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L21428)，0x896ee–0x8986f）。由字段/调用可推断“统计目录下文件数量”，pattern的glob/正则语法、是否含目录及深度定义**手机效果待验证**。 |
| FileExist /9 | `file#2:SSPFile` -> `file#2,exist#3:bool`（[D/ssp_descriptors.raw.txt:215–222](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L215)） | 请求file只设path（[D/modern_file_media.disasm.txt:21921–21943](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L21921)，0x8a0c6–0x8a133）；解析Response.exist回传bool（[D/modern_file_media.disasm.txt:22045–22084](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L22045)，0x8a2e7–0x8a392）。推断查询该路径存在性；目录、符号链接、无权限路径语义**手机效果待验证**。 |
| UpdateFile /40 ->41 | `filesArray#2:SSPFile[],isSync#3:bool` -> `isSuccess#2:bool`（[D/ssp_descriptors.raw.txt:392–398](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L392)） | 输入SFFile数组逐个`SFFile.transformSSPFileFromFile`，设filesArray与入参isSync，解析SSPUpdateFileResponse.isSuccess（[D/modern_file_media.disasm.txt:18765–18797](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L18765)、18896–18939、19175–19177；0x72281–0x7231a、0x724de–0x725a5、0x729eb–0x729f5）。没有上传raw data路径。推断更新记录/元信息；是否修改物理mtime、数据库extData/收藏/校验值**手机效果待验证**，不可把它代替UploadFile。 |
| PhotoSync /37 | `pcId#2:string,filesArray#3:SSPFile[]` -> `isFirst#2:bool,filesArray#3:SSPFile[],isSuccess#4:bool`（[D/ssp_descriptors.raw.txt:371–379](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L371)） | pcId取macUUID；lastFiles逐项transform为SSPFile（[D/modern_file_media.disasm.txt:20076–20131](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L20076)、20231–20244，0x8800c–0x8811e、0x882cb–0x88305）。响应先检查isSuccess，再检查hasIsFirst/isFirst并遍历filesArray构造本地文件（[D/modern_file_media.disasm.txt:20337–20434](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L20337)、20508–20585，0x884fe–0x8866c、0x887f6–0x8899a）。推断以电脑身份及上次快照进行相册同步协商；返回filesArray的新增/删除/冲突含义、首次同步标记具体服务端算法**手机效果待验证**。 |
| SyncMonitor /39 | `isSyncMonitor#2:bool` -> `isSuccess#2:bool`（[D/ssp_descriptors.raw.txt:386–391](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L386)） | `SSPSyncMonitorSettingRequestOperation`直接复制enabled（[D/modern_file_media.disasm.txt:19504–19534](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L19504)，0x7d5e0–0x7d679），回调检查isSuccess（[D/modern_file_media.disasm.txt:19741–19743](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L19741)）。**SSPPhotoSyncOverRequestOperation也构造同一SSPSyncMonitorRequest**，把syncMonitorEnabled设为isSyncMonitor，消费同一Response（[D/modern_file_media.disasm.txt:26826–26861](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L26826)、27063–27065；0xa8c80–0xa8d34、0xa9101–0xa910b）。没有独立“PhotoSyncOver”线上type，不能另造消息。推断切换同步监听开关；是否持久化、监听路径和生效时机**手机效果待验证**。 |
| FileChange push /38 | 无对应Request；`fileChangeItemsArray#2:SSPFileChangeItem[]`，item `file#1:SSPFile,status#2:enum`（[D/ssp_descriptors.raw.txt:380–385](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L380)） | SSPManager检查type=0x26、解析SSPFileChange并调fileChangeCallback（[D/modern_file_media.disasm.txt:13428–13561](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L13428)，0x64b84–0x64e34）；`registerFileChangedMonitorWithBlock`仅设置本地callback（[D/modern_file_media.disasm.txt:29514–29552](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L29514)，0x672b0–0x67359）。status为None0/Added1/Deleted2/Modified3/InfoModified4/FileAndInfoModified5（[D/ssp_descriptors.raw.txt:479–485](../handshaker_analysis/dumps/ssp_descriptors.raw.txt#L479)）。与MonitorFolder的SSPFileEvent不是同一结构；增量可能含文件内容和元信息变化区别，但服务端触发条件、与isSyncMonitor的因果关系**手机效果待验证**。 |

```text
电脑 -> 手机: GetFileCountRequest(dir.path,maxdepth=5,exclusionPatternArray)
手机 -> 电脑: GetFileCountResponse(count及回显字段)
电脑 -> 手机: FileExistRequest(file.path)
手机 -> 电脑: FileExistResponse(exist)

电脑 -> 手机: PhotoSyncRequest(pcId=持久电脑UUID,filesArray=上次本地记录)
手机 -> 电脑: PhotoSyncResponse(isSuccess,isFirst?,filesArray)
电脑: 根据返回记录执行必要的GetDirFiles/DownloadFile/UploadFile操作 [决策算法待验证]
电脑 -> 手机: UpdateFileRequest(filesArray=记录元信息,isSync=true)
手机 -> 电脑: UpdateFileResponse(isSuccess)
电脑 -> 手机: SSPSyncMonitorRequest(isSyncMonitor=期望监听开关) [同步结束/设置变更共用]
手机 -> 电脑: SSPSyncMonitorResponse(isSuccess)
手机 -> 电脑: 独立push SSPFileChange(fileChangeItemsArray)
电脑: 遍历每项status与file，更新本地缓存/安排传输 [服务端触发规则待验证]
```

## 10. Dart 实现分层、参考编码与核对向量

先选择对应的手机端版本/通道：当前 `52.0` APK 的 `10086` 入口只能使用旧 ADBForward；mac现代 SSP v2 的9字节请求头绝不能发给此入口。重实现应把 transport、签名/公钥封装、消息codec、业务operation分别实现。旧请求的业务字段是有序大端固定字段；现代消息按protobuf tag解析，不能共用一个“通用28/136字节头”。

建议实现顺序：

1. 旧通道：4字节长度累计拆帧 -> 公钥握手 -> GET(type3) -> KEEP_ALIVE(type5)与signed pong(type6) -> NEW_FETCH(type7) -> THUMBNAIL(type8) -> WATCH(type10) -> HTTP文件读取。
2. 现代通道：9字节request与6字节response chunk -> session路由/8字节逻辑header -> 两阶段握手 -> 显式type的protobuf请求 -> 文件operation分阶段解析 -> push callback。
3. 保留同版本未知protobuf tag、未知JSON列、未知enum值；业务层判断是否支持。不要把客户端默认值当成手机返回的保证。

### 10.1 密码学必须满足的接口

| 使用位置 | 需要实现的算法/输入 | 输出 |
|---|---|---|
| 公钥封装 | PKCS#1 RSAPublicKey DER(n,e)，e=65537；Base64 DER，ASCII空格补到32整倍数；固定key/IV的AES-256-CBC，无PKCS7 | MD5(DER)16bytes与AES密文 |
| 旧命令签名 | SHA256withRSA / PKCS#1 v1.5，输入原始 `C\|\|S\|\|V\|\|B` | 固定128bytes，不Base64 |
| 现代命令签名 | 同算法，输入序列化后的完整protobuf bytes | 固定128bytes；拼在protobuf前 |
| 握手成功证明 | Base64解码响应；RSA private decrypt/PKCS#1 v1.5 | UTF-8 `ok` |
| 现代剪贴板 | gzip(UTF-8 text)，反向gunzip+UTF-8 | protobuf bytes content |
| 旧type7 | gzip解压，再UTF-8和JSON解析 | 动态媒体记录对象 |

依据：旧 [J/e/a/c.java:34-41](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/e/a/c.java#L34)、[J/utils/j.java:29-35](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/utils/j.java#L29)、[J/b/f.java:23-25](../handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/b/f.java#L23)；现代 [D/modern_transport.disasm.txt:1111-1144](../handshaker_analysis/dumps/modern_transport.disasm.txt#L1111)、[D/modern_file_media.disasm.txt:14546-14618](../handshaker_analysis/dumps/modern_file_media.disasm.txt#L14546)。RSA签名callback的输入必须是raw bytes：如果选用的库提供“输入原文并内部hash”的接口，只hash一次；如果提供“输入已hash摘要”的接口，使用SHA256 DigestInfo的PKCS#1签名方式，避免双重hash。无需套用TLS、AES会话加密或derivedKey签名；这些均不是已核实的普通请求路径。

### 10.2 旧通道参考codec（仅Dart标准库）

下面代码直接体现前文核实的偏移。`signRaw`由实际RSA库实现；示例中的全零签名仅用于核对布局，不能通过手机验签。`FrameReader`修复原MINA decoder的粘包问题。64MiB上限是这个示例的本地策略，不是已发现的协议限制。

```dart
import 'dart:convert';
import 'dart:typed_data';

Uint8List be32(int n) {
  if (n < 0 || n > 0x7fffffff) throw RangeError.value(n);
  final b = ByteData(4)..setInt32(0, n, Endian.big);
  return b.buffer.asUint8List();
}

Uint8List concat(Iterable<List<int>> parts) {
  final b = BytesBuilder(copy: true);
  for (final part in parts) { b.add(part); }
  return b.takeBytes();
}

Uint8List frame(List<int> payload) => concat([be32(payload.length), payload]);

// signRaw must implement SHA256withRSA / PKCS#1 v1.5 over raw data.
Uint8List signedRequest(int command, int subtype, List<int> body,
    Uint8List Function(Uint8List raw) signRaw, {int version = 1}) {
  for (final v in [command, subtype, version]) {
    if (v < 0 || v > 255) throw RangeError.value(v);
  }
  final covered = concat([[command, subtype, version], body]);
  final signature = signRaw(covered);
  if (signature.length != 128) throw StateError('RSA signature must be 128 bytes');
  return frame(concat([[1], signature, covered]));
}

// encryptedBase64 is AES-CBC without PKCS#7; pad plaintext with spaces to 32.
Uint8List handshake(List<int> md5Der, List<int> encryptedBase64) {
  if (md5Der.length != 16 || encryptedBase64.isEmpty ||
      encryptedBase64.length % 32 != 0) {
    throw ArgumentError('Invalid handshake fields');
  }
  return frame(concat([[0, 14, 3, 1], md5Der,
                      be32(encryptedBase64.length), encryptedBase64]));
}

Uint8List lpString(String s) {
  final b = utf8.encode(s);
  return concat([be32(b.length), b]);
}

Uint8List stringList(List<String> paths) =>
    concat([be32(paths.length), ...paths.map(lpString)]);

// Signed 64-bit IDs are written as two's-complement. BigInt also works on web.
Uint8List i64be(BigInt n) {
  final min = -(BigInt.one << 63), max = (BigInt.one << 63) - BigInt.one;
  if (n < min || n > max) throw RangeError('I64 out of range');
  var v = n.toUnsigned(64);
  final b = Uint8List(8);
  for (var i = 7; i >= 0; i--) {
    b[i] = (v & BigInt.from(255)).toInt();
    v >>= 8;
  }
  return b;
}

Uint8List idList(List<BigInt> ids) =>
    concat([be32(ids.length), ...ids.map(i64be)]);

// Consume a TCP stream, yielding complete frames INCLUDING their length prefix.
// The cap is a client policy, not a discovered protocol maximum.
class FrameReader {
  FrameReader({this.maxPayload = 64 * 1024 * 1024});
  final int maxPayload;
  Uint8List pending = Uint8List(0);
  List<Uint8List> add(List<int> chunk) {
    pending = concat([pending, chunk]);
    final out = <Uint8List>[];
    var p = 0;
    while (pending.length - p >= 4) {
      final n = ByteData.sublistView(pending, p, p + 4).getInt32(0, Endian.big);
      if (n < 0 || n > maxPayload) throw FormatException('Invalid frame length');
      if (pending.length - p < 4 + n) break;
      out.add(Uint8List.fromList(pending.sublist(p, p + 4 + n)));
      p += 4 + n;
    }
    pending = Uint8List.fromList(pending.sublist(p));
    return out;
  }
}

String hex(List<int> b) => b.map((n) => n.toRadixString(16).padLeft(2, '0')).join();

void main() {
  // A structural fixture only: zero signature cannot pass phone verification.
  final get = signedRequest(3, 3, [], (_) => Uint8List(128));
  if (get.length != 136 || hex(get.sublist(0, 5)) != '0000008401' ||
      hex(get.sublist(133)) != '030301') throw StateError('GET layout');
  final h = handshake(List.filled(16, 0), List.filled(192, 0));
  if (h.length != 220 || hex(h.sublist(0, 8)) != '000000d8000e0301' ||
      hex(h.sublist(24, 28)) != '000000c0') throw StateError('Handshake layout');
  if (hex(idList([BigInt.from(42)])) != '00000001000000000000002a') {
    throw StateError('ID list');
  }
  if (hex(stringList(['/sdcard/a'])) != '00000001000000092f7364636172642f61') {
    throw StateError('String list');
  }
  final stream = FrameReader();
  final a = [0, 0, 0, 3, 6, 1, 1], b = [0, 0, 0, 3, 6, 1, 2];
  if (stream.add(a.sublist(0, 2)).isNotEmpty) throw StateError('Fragment');
  final frames = stream.add([...a.sublist(2), ...b]);
  if (frames.length != 2 || hex(frames[0]) != hex(a) || hex(frames[1]) != hex(b)) {
    throw StateError('Framing');
  }
  print('layout vectors: OK; split + coalesced frames: OK');
}
```

### 10.3 现代SSP transport参考codec

发送方向是9字节头，接收方向是6字节chunk头；不得把两方向写成对称帧。下面只拆物理chunk，保留rawSessionId并另给出低31位sessionId视图，将每个session的data交给其operation。普通operation再解析8字节逻辑长度；下载operation先解ResponseHeader，随后把data作为原始文件流，不再对每个文件chunk尝试读取protobuf。依据：[D/modern_transport.disasm.txt:33-69,5910-5922,6789-6995](../handshaker_analysis/dumps/modern_transport.disasm.txt#L33) 与现代文件章节。

```dart
import 'dart:typed_data';

Uint8List be32(int n) {
  if (n < 0 || n > 0x7fffffff) throw RangeError.value(n);
  return (ByteData(4)..setUint32(0, n, Endian.big)).buffer.asUint8List();
}
Uint8List concat(Iterable<List<int>> parts) {
  final b = BytesBuilder(copy: true);
  for (final part in parts) { b.add(part); }
  return b.takeBytes();
}
Uint8List modernPacket(int sid, int flag, List<int> data) {
  if (sid < 0 || sid > 0x7fffffff || flag < 0 || flag > 255) {
    throw RangeError('Invalid modern header');
  }
  return concat([be32(sid), [flag], be32(data.length), data]);
}
Uint8List modernSigned(int sid, Uint8List proto,
    Uint8List Function(Uint8List raw) signRaw) {
  final signature = signRaw(proto);
  if (signature.length != 128) throw StateError('RSA-1024 required');
  return modernPacket(sid, 1, concat([signature, proto]));
}
class ModernChunk {
  ModernChunk(this.rawSessionId, this.push, this.data);
  final int rawSessionId;
  int get sessionId => rawSessionId & 0x7fffffff;
  final bool push;
  final Uint8List data;
}
class ModernChunkReader {
  Uint8List pending = Uint8List(0);
  List<ModernChunk> add(List<int> bytes) {
    pending = concat([pending, bytes]);
    final out = <ModernChunk>[];
    var p = 0;
    while (pending.length - p >= 6) {
      final head = ByteData.sublistView(pending, p, p + 6);
      final rawSid = head.getUint32(0, Endian.big);
      final size = head.getUint16(4, Endian.big);
      if (pending.length - p < 6 + size) break;
      out.add(ModernChunk(rawSid,
          (rawSid & 0x80000000) != 0,
          Uint8List.fromList(pending.sublist(p + 6, p + 6 + size))));
      p += 6 + size;
    }
    pending = Uint8List.fromList(pending.sublist(p));
    return out;
  }
}
String hex(List<int> b) => b.map((n) => n.toRadixString(16).padLeft(2, '0')).join();
void main() {
  // A synthetic protobuf HeartBeat.type=1 fixture, no timestamp, invalid zerosig.
  final p = modernSigned(3, Uint8List.fromList([8, 1]), (_) => Uint8List(128));
  if (p.length != 139 || hex(p.sublist(0, 9)) != '000000030100000082') {
    throw StateError('Modern request');
  }
  final raw = [0x80,0,0,3,0,10, 0,0,0,0,0,0,0,2,8,1];
  final reader = ModernChunkReader();
  if (reader.add(raw.sublist(0, 5)).isNotEmpty) throw StateError('Split');
  final chunks = reader.add(raw.sublist(5));
  if (chunks.length != 1 || chunks[0].sessionId != 3 || !chunks[0].push ||
      hex(chunks[0].data) != '00000000000000020801') {
    throw StateError('Modern response');
  }
  print('modern request + split response chunk vectors: OK');
}
```

### 10.4 可复算的结构与protobuf向量

| 内容 | 十六进制/结构 | 应解释成 |
|---|---|---|
| 旧手机ping | `00 00 00 03 06 01 01` | L=3，CMD6、Version1、ping1 |
| 旧短连接pong response | `00 00 00 03 06 01 02` | L=3，CMD6、Version1、pong2；主机回复应重新签名而非原样写此帧 |
| 旧GET request | `00 00 00 84 01 \|\| S128 \|\| 03 03 01` | 整帧136字节，签名覆盖`03 03 01` |
| 旧握手（AES密文192） | `00 00 00 d8 00 0e 03 01 \|\| MD5_16 \|\| 00 00 00 c0 \|\| C192` | 整帧220字节，外层L216，内层N192 |
| 旧IdList，ID=42 | `00 00 00 01 00 00 00 00 00 00 00 2a` | count1+I64BE42 |
| 旧StringList `/sdcard/a` | `00 00 00 01 00 00 00 09 2f 73 64 63 61 72 64 2f 61` | count1+byteLength9+UTF-8路径 |
| 现代request（纯布局） | `00 00 00 03 01 00 00 00 82 \|\| S128 \|\| 08 01` | sid3，flag1，dataLen130，protobuf type1；未包含timestamp |
| 现代push物理chunk（纯布局） | `80 00 00 03 00 0a 00 00 00 00 00 00 00 02 08 01` | rawSid高位push，低31位sid3，chunkLen10，逻辑N2，proto2bytes |
| Request02：type33,hostUuid=`test`,trust5 | `08 21 12 04 74 65 73 74 20 05` | tag1 varint33，tag2 string，tag4 varint5 |
| SSPDataRange(offset300,length4096) | `08 ac 02 10 80 20` | tag1 varint300，tag2 varint4096 |
| maxdepth=0xffffffff | 字段tag3为 `18 ff ff ff ff 0f` | uint32最大值，5字节varint；不是int32的负一10字节编码 |

这些是根据代码和schema生成的核对向量，**不是实机抓包**。`S128`表示正确签名占位，`C192`表示密文占位，不应使用字符串本身或全零代替真实网络字段。应用语义须使用正确message type，不可仅为测试布局就发送push样例。

### 10.5 使用恢复的 `.proto`

[SmartSyncProtocol.recovered.proto](SmartSyncProtocol.recovered.proto) 保存全部69个message、328个field、8个enum，可交给Dart protobuf代码生成器；这份文本是按ObjC property名称重新表达的schema，Array后缀和命名空间可与原始schema不同，**tag、线类型、默认值才是互通依据**。

对协议parser应先以tag1/type判别消息，再按session所绑定的operation解释response；请求和响应经常共享同一type数值，单凭type不足以区分方向。对于upload header实际编号16/18差异，按已经确认的session状态和header schema处理，并保留抓包验证入口。不要为“看起来更合理”而修改恢复schema中的默认18。

本次验证：恢复proto通过`protoc --descriptor_set_out`编译；Request02与DataRange的编码向量通过protoc编码核对；以上两段Dart在本地Dart SDK中执行成功，覆盖旧帧长度/头、字符串与64位ID、握手结构、TCP分片/粘包以及现代9字节请求/6字节响应chunk。未进行真实手机互通、RSA端到端登录或大文件传输测试。

## 11. 可复现性、验证结果与待验证事项

本次核对以本地文件为准，证据没有来自运行中的手机。为避免后续换版本后误用偏移，原始输入SHA-256为：

```text
SmartFolder.apk
7b4099f4d4977ff353752642390e4cbc78c572bff7ef60cc97857be80e78efdc

Contents/Frameworks/SmartFinderCore.framework/Versions/A/SmartFinderCore
d257e38fb4c24f7b0682536e9e5f5ee0bfd21d3a2dc76a78f2b0c12b79438a0a

jadx_out/resources/lib/x86_64/libsmartfolder.so
99ba7ece52c9d0c72e1e1744af173a73db3e7743e85c9781a91b5b39b40a9aa1
```

恢复工具：[recover_ssp_descriptors.py](../handshaker_analysis/tools/recover_ssp_descriptors.py)、[render_ssp_schema_docs.py](../handshaker_analysis/tools/render_ssp_schema_docs.py)。原始字段记录：[ssp_descriptors.raw.txt](../handshaker_analysis/dumps/ssp_descriptors.raw.txt)；机器可读schema：[ssp_descriptors.json](../handshaker_analysis/dumps/ssp_descriptors.json)。字段描述符的本机storageOffset仅供逆向核对，不能拿它当作protobuf线上偏移。

已完成静态验证：全部328个字段逐项与Mach-O原始record核对；全部69个消息和8个enum与protoc输出descriptor核对；文内源文件链接与起始行号检查；两套Dart示例运行；恢复proto可编译。可运行的示例文件为 [legacy_codec.dart](examples/legacy_codec.dart) 和 [modern_codec.dart](examples/modern_codec.dart)。示例使用合成数据及无效签名占位，不代替真实握手或互通测试。

| 待验证项 | 已掌握的事实 | 下一步需要的证据 |
|---|---|---|
| 手机端版本与现代SSP入口 | 当前APK只有旧命令通道及HTTP；mac同时支持现代SSP v2 | 对应现代手机APK/系统服务，或同版本会话抓包；确认端口与发现/AOA建连 |
| 现代derivedKey生成与授权寿命 | mac保存Response02 bytes并下次发回；RSA仍用于普通请求签名 | 手机生成/验证代码；TrustOnce/Always/Remove完整行为 |
| upload header编号16/18 | enum定义header16；同名message descriptor默认18 | 真实ready响应proto或手机设置type的代码 |
| 上传成功与持久化确认 | mac发完最后一块即本地成功，无明确等待最终响应 | 手机落盘/MD5检查和最终ack时序，断连/失败处理 |
| 下载range/gzip与断点 | mac默认range={0,0}、needMd5=false；HTTP只取Range起点 | 非零range与gzip的双端行为，HTTP region EOF，空文件与大于4GiB测试 |
| response分片与多逻辑消息 | 6字节物理chunk、8字节逻辑长度已证实；握手Waiting可多响应 | 上传/下载header-body边界、0长度chunk、push完整sessionId处理 |
| 剪贴板变化通知启用 | schema定义ClipboardChange；mac有本地callback | 手机订阅触发条件与通知时序；不能凭本地callback当网络请求 |
| 旧JSON具体列与缩略图异常 | JSON列取决于provider；jadx finally似有空数组覆盖 | 目标设备provider输出、原dex/smali或真实缩略图响应 |
| 原MINA decoder与异常响应 | decoder取整个limit；异常encoder可产三零头但handler也可关闭 | 分片/粘包、验签失败实际网络行为 |

实现现代开源手机端时，可以按恢复schema和mac可核实的发送/接收行为建立兼容接口；手机内部信任、文件权限、持久化和通知机制需要自行设计，并用上面的待验证项目做双端兼容测试。实现电脑端与当前APK互通时，应先使用本文已核实的旧命令、同一主机密钥、callback会话和HTTP下载；其没有实现的现代消息无法靠改变旧type来启用。
