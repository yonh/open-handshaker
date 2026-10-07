# SSP 握手、信任、外层帧和会话分析

本节基于本地 APK 的 JADX 源码，并以本地 macOS SmartFinderCore 二进制作为交叉证据。`J/` 表示 `handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/`，`M/` 表示 `handshaker_analysis/jadx_out/sources/org/apache/mina/`，`D/` 表示 `handshaker_analysis/dumps/`。下文的 `文件:行号` 均在这些目录下，行号针对当前工作区文件。帧偏移 `F` 从 TCP 帧长度字段首字节算起，包体偏移 `B=F-4` 从长度后算起；区间统一采用 `[起点,终点)`。

## 1. 外层 TCP 传输

手机 SSP TCP 监听端口为 `10086`；同一服务还启动独立的 `19999` HTTP 文件服务器。SSP acceptor 启用 TCP_NODELAY、codec 和 command handler，初始 BOTH_IDLE 为 10 秒（`J/d.java:14–28`；HTTP：`J/d/d.java:14–23`）。`AdbForwardService.onCreate` 启动这些服务器（`J/AdbForwardService.java:59–69`）。端口不是从 SSP 握手字段动态协商出来的。

手机响应编码器严格生成 `u32be(body.length) || body`，所以四字节长度 **不包括长度字段自身**（`J/d/b.java:34–40`）。收包检测使用 `prefixedDataAvailable(4)`，MINA 对 4 字节执行 `getInt(position)` 并判断 `remaining()-4 >= length`，同时拒绝负长度（`J/d/a.java:11–18`；`M/core/buffer/AbstractIoBuffer.java:1117–1139`）。

需要特别警惕原 APK decoder 的实现问题：检测完整帧后，它创建大小为 `ioBuffer.limit()` 的数组，`ioBuffer.get(bArr)` 取出整个 limit，没有按 `4+length` 限定，也没有剥离长度前缀（`J/d/a.java:12–17`）。因此 `e/a/c.java` 的 `4/5/133/136` 全都是 **F 偏移，包含外层四字节长度**。存在多个 TCP 帧粘连时原实现可能把它们误作一帧；Dart 应实现健壮的增量缓存，按 `4+length` 精确拆帧，不能照搬该缺陷。原 decoder 粘包兼容性尚无抓包验证，标记 **待验证**。

### 1.1 主机→手机：签名请求

| F 偏移 | B 偏移 | 长度 | 字段/手机端行为 | 证据 |
|---|---:|---:|---|---|
| 0–3 | 无 | 4 | 包体长度，big-endian | `J/d/b.java:34–38`；`M/core/buffer/AbstractIoBuffer.java:1132–1139` |
| 4 | 0 | 1 | 非零表示需要签名验证；手机只检查 `!=0`，不要求某个特定值 | `J/e/a/a.java:25–34`；`J/e/a/c.java:14–16,60–62` |
| 5–132 | 1–128 | 128 | RSA 签名 | `J/e/a/c.java:36–41` |
| 133 | 129 | 1 | type / CMD 命令号 | `J/e/a/c.java:65–67`；`J/e/a/a.java:31` |
| 134 | 130 | 1 | 功能选择字节：握手为 `3`；一般语义须结合各命令 | `J/e/a/c.java:70–72`；mac 见下一节 |
| 135 | 131 | 1 | Version，mac 常量为 `1` | `J/e/a/c.java:75–77`；`D/adb_transport.constants.txt:3–22` |
| 136… | 132… | 可变 | 命令 payload | `J/e/a/c.java:55–57` |

```text
F    0        4   5                                      133  134  135  136
     +--------+---+---------------------------------------+----+----+----+------
     | u32 BE |nz |             RSA signature            |CMD |arg |ver |data…
     +--------+---+---------------------------------------+----+----+----+------
                 <---------------128 bytes-------------->
                                                         <---签名覆盖直到帧尾-->
```

签名算法为 Java `SHA256withRSA`（PKCS#1 v1.5 + SHA-256），原样签名 `F[133,end)`，不覆盖四字节长度、标志和签名本身（`J/e/a/c.java:36–41`）。签名固定 128 字节与 RSA-1024 相吻合；mac 字符串明确出现 `keySize==128`（`D/SmartFinderCore.strings.txt:15523`）。Dart 互通实现应使用 1024 位 RSA 密钥，按 RSA 签名原始字节而非 hex/Base64 写入 128 字节字段。

`b/a` 对构造参数保存为 `a=CMD,b=第三参数,c=第二参数`；parser 实际参数顺序是 `(CMD,F[135],F[134])`（`J/b/a.java:11–15`；`J/e/a/a.java:31`）。因此响应头内部字段顺序会翻转为 `CMD,Version,arg`，这是线格式真实的方向差异，不能因为 Java 变量名 `b/c` 而错误地把两者交换。

### 1.2 手机→主机：普通响应与错误

手机响应没有签名 flag，也没有 128 字节 RSA 签名：`f/a.b()` 仅返回三个字节 `{a,c,b}`；上层才添加 u32be 长度（`J/f/a.java:9–17`；`J/d/b.java:29–38`）。

```text
F    0        4     5        6      7
     +--------+-----+--------+------+------
     | u32 BE | CMD |Version | arg  |data…
     +--------+-----+--------+------+------
```

握手 `f/f` 响应为三个头字节 + 原样字符串 bytes，没有字符串长度和终止零（`J/f/f.java:16–24`）。大多数 JSON 响应使用 UTF-8；握手 response `getBytes()` 未指定字符集，但它只发送 ASCII `failed` 或 Base64，实际编码无歧义（`J/f/f.java:20`；`J/b/f.java:19–28`）。

签名请求若尚未获得公钥，抛 `a/d`（文本 `failed,the publickey is not exist`）；签名不通过则抛 `a/f`（文本 `rsa verify failed`），两者是 `a/b` 子类（`J/e/a/a.java:26–33`；`J/a/d.java:4–7`；`J/a/f.java:4–7`）。encoder 支持把这两个异常转为 `a/b.a()` 返回的三个字节。`a/b` 的三个 private byte 字段没有赋值，所以已知 wire 响应是 `00 00 00`，不是上述异常文本（`J/a/b.java:4–14`；`J/d/b.java:19–27`）。**待验证**：异常由 decoder 抛出时，是否实际进入 encoder；`CommandHandler.exceptionCaught` 会直接关闭连接（`J/d/c.java:15–20`），而 `messageReceived` 对非 request 对象才执行 `write(obj)`（`J/d/c.java:30–38`）。不要实现成“必然收到错误字符串”。

## 2. 本 APK 可实现的 RSA 公钥握手

### 2.1 未签名格式并不意味着可执行任意旧命令

`F[4]==0` 时，解析流程 **不走命令注册表**，而是调用 `a(b(bArr),bArr)`，由 `e/a/c.a` 无条件创建 `b/f`；`b(bArr)` 从 `F[8,end)` 向 `utils/j` 尝试导入公钥（`J/e/a/a.java:25–41`；`J/e/a/c.java:19–20,29–31`）。所以 `e/a/c.d` 存在 unsigned payload 起点 `28`，只能证明该辅助函数的布局分支，不能证明本 APK 允许 unsigned 普通请求（`J/e/a/c.java:55–57`）。

mac `SFADBForwardHandshakeOperation` 对应这种旧 ADB RSA 公钥握手；它的 CMD 常量为 `0x0e`，Version 为 `1`（`D/adb_transport.constants.txt:15–16`）。这是一个不在 signed 类型注册表中执行的特殊入口。

### 2.2 精确公钥握手帧

| F 偏移 | B 偏移 | 长度 | 意义 | 证据 |
|---|---:|---:|---|---|
| 0–3 | 无 | 4 | `24+ciphertext.length` 的 BE 长度 | 同外层规则，body 从 4 开始 |
| 4 | 0 | 1 | `0` 未签名 | `J/e/a/c.java:14–16` |
| 5 | 1 | 1 | CMD `0x0e` | `D/adb_transport.constants.txt:15`；`D/adb_transport.disasm.txt:151` |
| 6 | 2 | 1 | 功能选择 `0x03` | mac handshake sendRequest；导入手机后用于 response 第三头字节 |
| 7 | 3 | 1 | Version `0x01` | `D/adb_transport.constants.txt:16` |
| 8–23 | 4–19 | 16 | DER PKCS#1 公钥 bytes 的 MD5 原始摘要 | `J/e/a/c.java:30`；`J/utils/j.java:29–34`；`J/utils/l.java:8–12` |
| 24–27 | 20–23 | 4 | AES 密文长度，u32be；手机 `utils/j` 实际跳过而未读取 | `J/utils/j.java:30`；mac `D/adb_transport.disasm.txt:387–407` |
| 28… | 24… | 可变，16 整倍数 | AES-256-CBC 加密的 Base64 PKCS#1 RSA 公钥文本 | `J/utils/j.java:30`；native 证据见下 |

```text
F   0        4   5    6   7   8                    24       28
    +--------+---+----+---+---+--------------------+--------+------------------
    | u32 BE |00 |0e  |03 |01 |MD5(DER public key) |u32 BE n|AES ciphertext…
    +--------+---+----+---+---+--------------------+--------+------------------
                              <-----16 bytes----->          <----n bytes---->
```

手机计算：`raw=F[8,end)`；摘要 `raw[0,16)` 等于 `F[8,24)`；`raw[20,end)` 等于 `F[28,end)` 进入 native 解密。所谓“8 后全部公钥”和“28 起 payload”不存在矛盾，`8` 是公钥封装结构起点，`28` 是封装里密文起点；中间依次是 16 字节 MD5 和 4 字节密文长度（`J/e/a/c.java:30`；`J/utils/j.java:29–34`，mac 上述长度写入代码）。

手机解密结果按 UTF-8 创建字符串后 `trim()`，再 Base64 解码，对 DER 做 MD5 检验。Base64 解码类可由标准 alphabet 和解码方法确认（`J/utils/j.java:30–32`；源码 `handshaker_analysis/jadx_out/sources/org/a/b/a/a.java:10–17`、`org/a/b/a/b.java:9,68`）。DER 对象必须是两个 INTEGER 构成的 SEQUENCE；取第一个 INTEGER 为 modulus、第二个为 exponent，随后构造 `RSAPublicKeySpec`（`J/utils/j.java:33–35`；`handshaker_analysis/jadx_out/sources/org/a/a/a/a.java:17–24,34–40`）。因此用 PKCS#1 `RSAPublicKey` DER；不要把 SubjectPublicKeyInfo `PUBLIC KEY` DER 直接 Base64 填入。

### 2.3 JNI `parseIoBuffer` 已核实的 AES 算法

Java 仅声明 native（`J/utils/C.java:5–9`）；实际反汇编来自 `handshaker_analysis/jadx_out/resources/lib/x86_64/libsmartfolder.so`，导出 `Java_com_smartisanos_smartfolder_utils_C_parseIoBuffer` 地址 `0x2e10`。为稳定引用行号，完整 `objdump -d` 保存为 `D/libsmartfolder_x86_64.disasm.txt`。

```text
key = 28 e3 ee 32 b0 de 27 ef 6b c2 97 92 05 4e f9 73
      9c e8 e8 7b b4 95 f2 ea 0d 72 d4 f4 f4 0b 3b de
iv  = 2b 9e 34 d4 e1 d9 08 89 94 93 9e c4 e3 e9 60 c5
```

上述固定 key 在栈 `rbp-0x60…-0x41` 写入，IV 在 `rbp-0x70…-0x61` 写入（`D/libsmartfolder_x86_64.disasm.txt:2524–2573`）；key schedule `kysp_1` 入参 bits=`0x100=256`，随后调用 `dtcc_5` 解密（同文件 `2520–2521,2574–2581`）。mac 导出的常量字节完全一致（`D/adb_transport.constants.txt:23–24`），mac 调用 `_etcc_4` 加密（`D/adb_transport.disasm.txt:340–372`）。

这不是仅按函数名猜 AES-CBC：`dtcc_5` 检查 `n & 15 == 0`；每 16 字节调用 `dt_3` 后 XOR 初始 IV/上一块密文，并将原输入密文作为下一轮 chaining 值（`D/libsmartfolder_x86_64.disasm.txt:2425–2433,2449–2472`）。`dt_3` 使用 `InvShiftRows/InvSubBytes/AddRoundKey/InvMixColumns` 完成 AES 逆轮（同文件 `2267–2285` 等）。native 原样返回输入长度的解密 bytes，不删 padding（同文件 `2582–2596`；Java后续 `trim` 见 `J/utils/j.java:30`）。mac 从 PKCS#1 PEM 的 Base64 主体移除换行，添加 ASCII 空格 `0x20` 直到长度为32的整倍数；相关CFString常量直接读取为换行、空字符串、空格（`D/adb_transport.constants.txt:25–27`；`D/adb_transport.disasm.txt:186,211,241–246`）。这不是 AES/PKCS7Padding。对于常见1024位RSA public key，Base64文本188字节、4个空格padding后192字节密文。

### 2.4 公钥生命周期与成功证明

`utils/j` 公钥是单个 static `PublicKey a`，`a(byte[])` 为 synchronized，若已有公钥就直接返回它，不校验新请求 MD5/密文，也不替换（`J/utils/j.java:15–26,35`）。手机端没有按设备、TCP session 或 host UUID 建多个公钥的逻辑；这些文件里也没有持久化、复位、私钥生成或手机公钥返送。成功握手只是主机向手机提供主机 RSA 公钥；主机私钥仍由主机持有。

握手成功响应：手机用此公钥、`RSA/ECB/PKCS1Padding` 加密 ASCII `ok`，再 `Base64.encodeToString(ciphertext,0)` 输出字符串；失败发送 `failed`（`J/b/f.java:18–28`）。`Base64.DEFAULT` 可含换行，Dart 应允许 Base64 空白。主机 Base64 解码后以匹配私钥执行 RSA PKCS#1 v1.5 解密，确认明文是 `ok`。握手 request `b/f.b` 不把 session 标成 keep-alive（`J/b/f.java:32–35`），响应发送完成后通常关闭该 TCP connection（`J/d/c.java:50–56`）。

因公钥是进程级 single slot，一个不同密钥的第二主机即使收到握手响应，也只能拿到使用旧公钥加密的 `ok`，后续签名也会被旧公钥验证。不能将 `j.a(newKey)!=null` 当作“新 key 已被安装”。服务销毁时 `Process.killProcess`，所以服务结束后新进程会重置 static key（`J/AdbForwardService.java:89–96`）。关闭单个连接不会删除公钥（`J/c/a.java:27–30` 仅删session和取消任务）。

unsigned请求触发 Smartisan 系统更新提示有明确条件：brand=`smartisan` 且 release 与 `2.5.8` 作字符串比较小于零，随后仍执行公钥握手；这是系统安全提示，不是 TrustType 或用户授权消息（`J/e/a/a.java:35–41`；`J/AdbForwardService.java:100–107`）。

### 2.5 推荐文字消息序列

1. 主机保存/生成 RSA-1024 私钥；将 PKCS#1 公钥 DER 做 Base64、既定 padding 和 AES-256-CBC 封装。
2. 主机打开手机 `10086`（USB 情况通常经 ADB forward），发送 unsigned `[00,0e,03,01] + MD5 + u32be(ciphertext.length) + ciphertext`。
3. 手机首次导入成功，把公钥放入 static slot；手机返回 `u32be(3+ascii.length) + [0e,01,03] + Base64(RSA_public_encrypt("ok"))`，并结束此 socket。
4. 主机私钥解密并验证 `ok`。后续普通命令新建 socket，发送带 128 字节 RSA 签名的请求；所有 socket 使用同一 private key。
5. 主机另建 callback socket，第一条请求为 signed type `5`（KEEP_ALIVE）；手机回设备信息，并保留连接用于心跳和异步事件。

步骤 2/3 的具体头常量由 mac `SFADBForwardHandshakeOperation` 与 Android字段交叉确定；APK本身不会限制 unsigned CMD 必须是 `0x0e`。

## 3. mac `SSPHandShakeRequest01/02`、TrustType、TrustStore 的证据边界

mac 类名同时存在 `SFADBForwardHandshakeOperation`、`SFDeviceTrustStore` 和 `SSPHandShakeRequest01/02/Response01/02/TrustType`（`D/ssp_classes.txt:5,31,115–119`）；SmartFinderCore 有 `SmartSyncProtocol.pbobjc.m`、enum descriptor 等 Protobuf 生成代码线索（`D/SmartFinderCore.strings.txt:16499–16507`；`D/core_classes.txt:3381–3382`）。**不能将现代 01/02 对象直接对应到本 APK `b/f`、`b/h`**；`b/h` 明确是type5 keep-alive，`b/f` 是flag0特殊公钥握手，上面已给实际二进制代码。

仅通过 mac 字符串可确认：

- 两阶段握手调用分别名为 `sendHandShakeRequest01WithMSTimeout:error:` 和 `sendHandShakeRequest02WithMSTimeout:error:`（`D/SmartFinderCore.strings.txt:13382–13383`）。
- 01 响应具有 timeout/parsing error 分支；02 请求/响应有 `derivedKey`，响应判断 `SSPHandShakeTrustType_TrustNo`、`wired`、`result invalid`（同文件 `16268–16291`）。
- 可见的握手 Proto 属性有 hostUuid/hostName/hostTimestamp/hostSmartSyncProtocolVersion/hostAppVersion/hostMinClientVersion/md5/enckey/hostModel/heartbeatTimeoutSecond，client侧 deviceUuid/deviceName/usbSerial/clientMinHostVersionCode/derivedKey/trustType/result 等（同文件 `16588–16623`）。这证明字段名称存在，不证明各字段归属具体01/02消息，更不证明 field tag、wire type 或 enum numeric value。
- `SFDeviceTrustStore.m` 字符串和 `deviceStore.plist`，附近有 `device_uuid,device_name,derived_key,apk_version,apk_version_name,client_smart_sync_protocol_version,client_min_host_version,last_connection,connection_count,trust_type,is_smartisan_device` 的属性（同文件 `16393–16421`）。表明 mac 有设备信任记录，未证明手机 APK 在磁盘保存同样记录。

现代握手 01/02 的 request type、protobuf tag、TrustNo/wired 数值、派生 key 算法、确认/拒绝 UI、信任存储查找时机和 Wi-Fi 建连序列 **待验证**。没有本地明文源码/完整方法逆向或抓包证据时，不应为了“完整”而发明布局。重实现本 APK 互通可先实现上一节已证实的 ADB RSA 握手；现代手机端实现需要另取对应版本 APK。

## 4. 会话池、短连接与回调连接

`c/e` singleton 使用 `ConcurrentHashMap<Long,c/a>`，key为 MINA `IoSession.getId()`（`J/c/e.java:8–13,25–45`）。它另保存一个 `c/d` 长连接对象。第一次收到 `b/h`（keep-alive）时才以 boolean=true 创建该对象；其它 request 初次到来创建普通 `c/f`（`J/d/c.java:40–45`；`J/c/e.java:33–44`）。新长连接关闭旧长连接 `close(true)`，清空 EventManager，保存新session id并注册 DEVICE_INFO（`J/c/e.java:16–22,34–40`）。所以手机同时只允许一个事件主连接，多个临时请求连接可分别进池。

普通请求 worker 为单线程 executor；如果旧任务未完成而新任务到来，取消旧 Future 并调用旧 request 的 `b(session)` 清理，然后提交新任务。closeFuture 同样删除池成员、设置closed flag并取消当前任务（`J/c/f.java:57–78`；`J/c/a.java:14–16,27–30`）。事件主 worker `c/d` 则每个request直接submit，不用普通worker的单个current Future覆盖机制（`J/c/d.java:11–14`）。**注意**：这只是 single-thread executor 排队，不是后台并行执行。

每个worker执行 request.a(session) 并写回响应；遇到 `a/c` 关闭连接，遇到 `a/e` 终止当前处理（`J/c/f.java:40–53`）。响应发送完成后，若 `keep_alive_attr` 默认为false并仍连接，则关闭socket（`J/d/c.java:50–56`）。单次请求→响应→关闭是默认连接模型，不应默认请求多路复用。

`c/e.a(long)` JADX 末尾出现未定义 `throw th`（`J/c/e.java:51–62`），这是反编译残损；前面的remove/reset操作明确，异常是否存在不能按源码文本当作可信运行语义。

### 4.1 type5 KEEP_ALIVE / callback socket

type5 由注册表映射 `t` parser，再创建 `b/h`（`J/e/a/a/a.java:100–115`；`J/e/a/a/t.java:8–9`）。`b/h.a` 设置 `keep_alive_attr=true`，暂设 BOTH_IDLE=20，添加 MINA KeepAliveFilter，requestInterval=10秒，forwardEvent=false，再调用普通 GET `b/e` 生成设备信息响应（`J/b/h.java:14–21`；`J/b/e.java:13–14`）。取消请求时只设 `keep_alive_attr=false`（`J/b/h.java:24–27`）。

过滤器添加时 `onPostAdd -> resetStatus` 把 BOTH_IDLE改为requestInterval=10，并非持续20；默认requestTimeout=30秒、超时handler=CLOSE（`M/filter/keepalive/KeepAliveFilter.java:27–28,77–81,133–135`；`M/filter/keepalive/KeepAliveRequestTimeoutHandler.java:28–35`）。因此协议时序应表述为：10秒双向无业务流量发心跳、等待默认30秒，没有匹配心跳回应则close(true)，而不是固定每10秒不管流量发包（`M/filter/keepalive/KeepAliveFilter.java:151–170`）。

### 4.2 type6 HEARTBEAT

手机发 heartbeat 帧为 `00 00 00 03 06 01 01`，body仅 `[CMD6,Version1,1]`（`J/d/a/a.java:8–20`；`J/f/a.java:15–16`；`J/d/b.java:34–38`）。对应 heartbeat parser `r` 创建 `b/g(b2)`，这里 b2是请求F[135] Version；`b/g`构造 `(6,Version,2)`（`J/e/a/a/a.java:117–131`；`J/e/a/a/r.java:8–9`；`J/b/g.java:7–13`）。在keep-alive过滤器上，`b/g` 被视作response，过滤器重设超时，并消费掉此消息，不再传给普通 handler（`J/d/a/c.java:30–34`；`M/filter/keepalive/KeepAliveFilter.java:109–121`）。

主机向手机的 heartbeat 回应仍需走主机→手机的 signed帧，CMD=6、Version=1。F[134]通常2（与heartbeat response命名对应），但该APK的heartbeat parser实际忽略F[134]，仅保留Version（`J/e/a/a/r.java:8–9`）。若发送unsigned三字节response给手机，会被当成公钥导入并出错，不能因手机→主机heartbeat短头而误用对称编码。

若在普通短连接上发signed type6，它不会被KeepAliveFilter消费，而request.a返回手机heartbeatresponse `[06,Version,02]`（`J/b/g.java:11–13`；`J/d/a/b.java:9–26`）。这与主callback连接上作为pong的处理路径不同。

### 4.3 事件推送与服务存活

EventManager `c/c` 保存一个 `long sessionId` 和类别列表（AUDIO/VIDEO/IMAGE/DEVICE_INFO/FILE/MEDIA）；事件发送获取 `c/e.b(sessionId)` 并直接 `session.write(response)`（`J/c/c.java:10–19,33–45,48–59`）。注意该发送代码没有检查类别是否在列表里，所以不能从列表存在就推断其是严格订阅过滤器（同文件 `48–59`）。清除时设置sessionId=-1并清空列表（同文件 `62–65`）。

文字序列：主机建立signed type5长连接 → 手机关闭旧callback连接并指定新session → 手机回type5设备信息 → 手机在空闲时发type6 ping，主机回signed type6 pong → 文件/媒体/设备变更在此连接异步推送 → socket关闭后closeFuture清理池和EventManager。

`AdbForwardService` 每60秒检查是否仍存在长连接 `c/e.b()`；存在则重新安排检查，没有则stopSelf，onDestroy关闭服务、kill进程（`J/AdbForwardService.java:43–46,89–96`；`J/a.java:14–19`；`J/c/e.java:69–71`）。所以只做短连接文件请求而没有callback连接，服务可能在60秒后终止；创建keep-alive连接不只是为了订阅事件，也保持守护服务存活。

## 5. Dart 实现要点与未验证清单

- codec按方向分开：host request具有 flag/signature，phone response仅3字节头；二者都是4字节BE长度，不要共用对称头模型。
- length 的数组验证必须在任何固定偏移访问前完成；host signed至少132字节body，unsigned公钥握手至少24字节body。对最大frame长度设置本地上限属于实现选择，原MINA只限制到signed int范围。
- 保留同一主机private key，握手与所有后续独立socket共享；公钥封装用PKCS#1 DER+MD5+AesCBC fixed key/IV，不要使用SPKI。
- 响应无request id或session id字段；每个临时连接绑定其请求，callback socket持续按type处理异步事件和ping。
- **待验证**：真实抓包上的签名flag具体值（手机只要求非0）；unsigned/response连接中EOF时机；原decoder粘包行为；现代01/02的完整Protobuf schema及TrustType取值；签名异常是否真正发送 `00 00 00`；跨进程、多主机、公钥替换时产品层应如何组织重连。
