# Java ADBForward 命令注册、二进制布局与 mac 类名核对

本节只记录 APK `com.smartisanos.smartfolder` 的 Java 命令通道。引用中 `J/` 表示 `handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/`，`M/` 表示 `handshaker_analysis/jadx_out/sources/org/apache/mina/core/buffer/`，`D/` 表示 `handshaker_analysis/dumps/`。所有区间使用半开区间 `[start,end)`；表格的 `body+N` 从消息数据起点计算，**不包含头字节**。`F` 表示从4字节外层长度开始的整个帧，`packet`是去除长度后的包体，`body`是去除各模式内部头后的消息数据；三者起点不同。

## A. 必须区分两套证据

Java 解析器注册的是 `OLD_THUMBNAIL/FETCH/TERMINATE/GET/KEEP_ALIVE/HEARTBEAT/NEW_FETCH/THUMBNAIL/WATCH/DELETE/SCEN/EXIT`（`J/e/a/a/a.java:32-236`）。mac 转储包含 `SFADBForwardHandshakeOperation`、`SFADBForwardMediaThumbnailOperation` 以及 `cmd_keep_alive`/`cmd_push`（`D/SmartFinderCore.strings.txt:16796,16804-16807,16829`），同时包含 `SmartSyncProtocol.pbobjc.m` 和 Protobuf 生成属性（`D/SmartFinderCore.strings.txt:16507-16528`）。因此不能仅按相似功能将 mac `SSP*Request` 的枚举值套到 Java 注册表：现代mac枚举与schema已独立恢复；下文mac与Java仅作功能对照，不能把两套协议当作相同线格式。

## B. 请求和响应头的三个字节并非同顺序

定义 `C=command`、`S=subtype/媒体种类`、`H=version`。Java 仅保存并回写第三头字节；mac `_Version=0x01` 常量与 sendRequest 反汇编证明第三请求字节是 version（`D/adb_transport.constants.txt:16`，`D/adb_transport.disasm.txt:684-705`）。保留符号 H 便于下表表述。

| 字段 | 有签名请求整个输入帧偏移 | 标志为 0 的输入偏移 | 依据 |
|---|---:|---:|---|
| C | 133 | 5 | `J/e/a/c.java:65-67` |
| S | 134 | 6 | `J/e/a/c.java:70-72`；解析器第三参数保存在 `b/a.b`，业务代码用它 switch |
| H | 135 | 7 | `J/e/a/c.java:75-77` |
| 数据起点 | 136 | 28（切片方法） | `J/e/a/c.java:55-57` |

重要调用链：`J/e/a/a.java:31` 向 parser 传 `(C,H,S)`，`J/b/a.java:11-14` 保存 `a=C,c=H,b=S`；业务实例构造响应时传 `(a,c,b)`，响应基类 `J/f/a.java:9-16` 输出 `[a,c,b]`。所以**请求线上是 `[C,S,H]`，响应线上是 `[C,H,S]`**。响应没有请求中的标志与签名块：`J/d/b.java:34-38` 写 `BE32(result.length) || result`，`result` 从三字节响应头开始。

通用响应帧：`F[0..4)=BE32(3+bodyLength)`，`F[4]=C`、`F[5]=H`、`F[6]=S`、`F[7..)=body`；响应包体偏移（去除外层长度）是 `C=0,H=1,S=2,data=3`。`J/d/b.java:35-38`、`J/f/a.java:15-16`。

**标志 0 的输入不是一般旧版请求的有效执行路径。** `J/e/a/a.java:25-41` 对非零标志验签后才调用注册表；标志 0 无条件转入公钥握手 `a(b(bArr),bArr)`，`J/e/a/c.java:19-20,29-30` 把整个输入的 `[8,end)` 握手信封交给 utils/j 校验/解密公钥并构造 `b/f`，不会调用 `d()` 切出 28 起点的命令数据。因此 28 是代码存在的旧布局切片常量，不能声称旧格式普通命令目前可执行。

## C. 通用标量与字符串

请求解析器的 `getInt()` 为有符号 32 位大端，`getLong()` 为有符号 64 位大端。源码链：`J/e/a/a.java:31` 用 `IoBuffer.wrap(data)`；`M/IoBuffer.java:20,72-77` 默认 SimpleBufferAllocator；`M/SimpleBufferAllocator.java:12-15,82-84` 设大端；`M/AbstractIoBuffer.java:590-607` 委托 NIO `getInt/getLong`。

请求字符串均为 `BE32(byteLength) || rawBytes`，代码用 `new String(bytes)`，没有显式字符集（`J/e/a/a/v.java:13-15` 等）。Android 默认字符集通常为 UTF-8，跨端实现使用 UTF-8 是合理选择，但**协议显式规定 UTF-8 待验证**。响应 JSON 明确用 UTF-8：`J/c/b.java:8` 和 `J/f/h.java:31`。`f/f,k,n,j` 的 `getBytes()` 同样使用平台默认编码，没有 NUL 终止符，没有额外字符串长度（除 thumbnail 条目内部有长度）。

定义列表布局：

* `StringList`: `body+0: count:I32BE`；`p0=4`；每项 `body+p_i: length_i:I32BE`，`body+(p_i+4): text_i:bytes[length_i]`，`p_(i+1)=p_i+4+length_i`。
* `IdList`: `body+0: count:I32BE`；第 `i` 项（0 起）`body+(4+8*i): id_i:I64BE`；总长度 `4+8*count`。
* parser 不校验尾部剩余数据，也没有统一拒绝负长度/超大 count；Dart 应先做边界校验，不复刻越界行为（各 parser 代码见后表）。

## D. 完整 type → parser → 请求 → 响应注册表

`J/e/a/a/a/a.java:6-7` 定义 factory；`J/e/a/a/a/b.java:13-26` 遍历 enum 填表并对未知命令抛 `a/c`。实际 enum 在 `e/a/a/a.java`，不在更深的 `e/a/a/a/*.java` 中。

| C（十进制/hex） | enum 原名 | parser `e/a/a/` | request `b/` | response | 注册依据 |
|---|---|---|---|---|---|
| 1 / 01 | OLD_THUMBNAIL | v | j | f/j | `J/e/a/a/a.java:33-46`；`J/b/j.java:229` |
| 2 / 02 | FETCH | p | d | f/d | `J/e/a/a/a.java:49-63`；`J/b/d.java:66` |
| 3 / 03 | GET | q | e | f/e | `J/e/a/a/a.java:83-97`；`J/b/e.java:14` |
| 4 / 04 | TERMINATE | x | l | f/l | `J/e/a/a/a.java:66-80`；`J/b/l.java:13` |
| 5 / 05 | KEEP_ALIVE | t | h | f/e（经 b/e） | `J/e/a/a/a.java:100-114`；`J/b/h.java:21` |
| 6 / 06 | HEARTBEAT | r | g | d/a/b | `J/e/a/a/a.java:117-131`；`J/b/g.java:13` |
| 7 / 07 | NEW_FETCH | u | i | f/i | `J/e/a/a/a.java:134-148`；`J/b/i.java:35` |
| 8 / 08 | THUMBNAIL | y | m | f/m | `J/e/a/a/a.java:151-165`；`J/b/m.java:134` |
| 10 / 0A | WATCH | z | n | f/n | `J/e/a/a/a.java:168-182`；`J/b/n.java:19,33` |
| 11 / 0B | DELETE | n | b | f/b | `J/e/a/a/a.java:185-199`；`J/b/b.java:23` |
| 12 / 0C | SCEN（保留源码拼写） | w | k | f/k | `J/e/a/a/a.java:202-216`；`J/b/k.java:22,29` |
| 13 / 0D | EXIT（实际 EXIF） | o | c | f/c | `J/e/a/a/a.java:219-233`；`J/b/c.java:21,25` |

`C=9` **不注册请求**，是服务端主动 push；见 G。`C=0` 未注册。mac公钥握手使用 **C=14/0x0E**（`D/adb_transport.constants.txt:15`），不属于上面的注册表：signFlag=0时直接走 `e/a/c → b/f → f/f`，不查factory；其C/H/S从未签名输入取出（`J/e/a/c.java:19-20`）。因此14不能标作普通“未知type”，而非零签名flag的14仍会触发unsupported command。

## E. 每个请求的数据布局及语义

正常有签名请求body从**整个帧偏移136**开始，等价于去除长度后的**packet偏移132**；表中`body+0`即该位置。普通响应body从整个帧偏移7 / packet偏移3开始；握手有专门信封，不混用此body定义。

| C | 数据布局 | 字段语义 / S | 精确读取依据 |
|---|---|---|---|
| 1 | StringList | 绝对文件路径列表；S=1 image，2 video，3 audio artwork | `J/e/a/a/v.java:10-17`；`J/b/j.java:78-95,127-132,217` |
| 2 | 空 或 `body+0 filterId:I32BE`（4 字节） | 无字节则 filterId=0；album_id 或 bucket_id 筛选；详见 subtype 表 | `J/e/a/a/p.java:8-9`；`J/b/d.java:23-61` |
| 3 | 空（不读 body） | 获取设备信息；S 未使用 | `J/e/a/a/q.java:8-9`；`J/b/e.java:14` |
| 4 | 空 | 返回终止 ACK；是否终止当前任务由 session wrapper 处理 | `J/e/a/a/x.java:8-9`；`J/b/l.java:12-18` |
| 5 | 空 | 设置持久会话并返回设备信息 | `J/e/a/a/t.java:8-9`；`J/b/h.java:15-21` |
| 6 | 空 | 忽略输入 C/S，取 H 构造 `g(H)`，强制输出 C=6,S=2,H=输入 H | `J/e/a/a/r.java:8-9`；`J/b/g.java:7-13`；`J/d/a/b.java:13-15` |
| 7 | 空 | S=1 图片库，2 音频库，3 视频库；其他 S 无结果（空 body） | `J/e/a/a/u.java:8-9`；`J/b/i.java:19-35` |
| 8 | IdList | S=1 image media ID，2 video media ID，3 album art ID | `J/e/a/a/y.java:10-15`；`J/b/m.java:62-72,122` |
| 10 | StringList | S=1 注册；其他 S 撤销；路径映射到文件/Media/DeviceInfo observer | `J/e/a/a/z.java:12-22`；`J/b/n.java:21-31` |
| 11 | IdList | 删除 MediaStore.Files 的 `_id`；不是按路径 unlink | `J/e/a/a/n.java:10-15`；`J/b/b.java:21-23`；`J/utils/p.java:264-289` |
| 12 | StringList | 提交扫描路径到 SmartfolderMediaScannerService，不是上传文件内容 | `J/e/a/a/w.java:12-22`；`J/b/k.java:24-29` |
| 13 | `body+0 pathByteLength:I32BE`，`body+4 path:bytes[length]` | 读取路径的 EXIF 属性；enum EXIT 与行为不一致 | `J/e/a/a/o.java:9-11`；`J/b/c.java:21-25`；`J/utils/p.java:233-248` |
| 未签名握手 b/f | `F[8,24):MD5(DER)`；`F[24,28):I32BE(AES密文长)`；`F[28,end):AES-CBC密文` | 标志=0；Java把 F[8,end) 交 utils/j，JNI解密后 trim、Base64解码、MD5检查，再读PKCS#1 DER RSA | `J/e/a/c.java:29-30`；`J/utils/j.java:29-34`；密文长度与AES模式见 native/握手章节 |

WATCH/SCEN 的 count=0 会令 parser 返回 null，而不是产生 ACK（`J/e/a/a/z.java:19-20`、`J/e/a/a/w.java:19-20`）。FETCH 若 body 有 1～3 字节，`hasRemaining()` 为真随后 `getInt()` 越界；合法值只有 0 或至少 4 字节，剩余字段并未读取（`J/e/a/a/p.java:9`）。

FETCH subtype：`J/b/d.java:25-61` 为直接映射，utility 查询语义为下表。

| S | utility | 实际语义 | 依据 |
|---:|---|---|---|
| 1 | p.a(filterId) | 音频曲目，可按 album_id 筛选 | `J/utils/p.java:134-147` |
| 2 | p.a() | 音频专辑 | `J/utils/p.java:122-126`；audio albums URI `J/utils/p.java:37` |
| 3 | — | 不支持，抛 a/c | `J/b/d.java:32-34` |
| 4 | p.b() | 音频所在 bucket 分组 | `J/utils/p.java:292-296` |
| 5 | p.c() | 图片 bucket 分组 | `J/utils/p.java:342-346` |
| 6 | p.d() | 视频 bucket 分组 | `J/utils/p.java:370-374` |
| 7 | p.b(filterId) | 文件库中 bucket_id=filterId 的条目 | `J/utils/p.java:304-308` |
| 8 | p.c(filterId) | 图片 bucket_id=filterId | `J/utils/p.java:354-358` |
| 9 | p.d(filterId) | 视频 bucket_id=filterId | `J/utils/p.java:382-386` |
| 10 | p.f() | 缓存图片项数组 | `J/utils/p.java:416-419` |
| 11 | p.i() | 缓存视频项数组 | `J/utils/p.java:436-439` |
| 12 | p.j() | DownloadManager 成功下载项数组 | `J/utils/p.java:447-451,621-622` |

## F. 所有响应布局

以下 body 起点均为整个响应帧 `F+7`，包体内 `+3`；`L` 是 body 字节数，外层长度值为 `3+L`。常规响应头 C/H/S 与对应请求的字段值一致，但位置为 `[C,H,S]`；心跳头有特例。

### F1. 单字节 ACK（f/b、f/l）

| 类 / 请求 | body 偏移 | 类型 | 意义与依据 |
|---|---:|---|---|
| f/b / DELETE | 0 | U8 | 1 表示 MediaStore delete 返回 >0；0 否；`J/b/b.java:21-23`，序列化 `J/f/b.java:18-20` |
| f/l / TERMINATE | 0 | U8 | 固定 1；`J/f/l.java:10-12,18-20` |

### F2. 无长度字符串/JSON（f/h 及子类）

| 响应类 | data 布局 | 编码 / 说明 | 依据 |
|---|---|---|---|
| f/h（普通） | `body+0 bytes[L]` | 非空字符串的 UTF-8，空/null 无字节 | `J/f/h.java:27-36`；`J/c/b.java:8` |
| f/c / EXIT-EXIF | 同 f/h | UTF-8 JSON object，默认不压缩 | `J/f/c.java:5-6`；`J/utils/p.java:239-248` |
| f/d / FETCH | 同 f/h | UTF-8 JSON array；查询无条目/null 返回空 body，不是 `[]` | `J/f/d.java:5-6`；`J/utils/p.java:155-187` |
| f/e / GET、KEEP_ALIVE | 同 f/h | UTF-8 设备 JSON object | `J/f/e.java:5-6`；`J/b/e.java:14`；`J/utils/e.java:81-99` |
| f/i / NEW_FETCH | `body+0 gzipBytes[L]` | 对 UTF-8 JSON 进行 GZIP，而非 zlib/裸 deflate；无单独原长字段 | `J/f/i.java:5-6`；`J/f/h.java:31-35`；`J/utils/i.java:87-99` |

设备 JSON 键完整枚举：`version, device_name, device_owner, sdcard_root, file_num, picture_number, audio_number, video_number, download_number, screen_locked, disk_usage, battery_level`（`J/utils/e.java:84-95`）。screen_locked 是整数 0/1；其他 numeric 字段最终来自 Java long/int。字段 nullable 与缺失应按 Android JSONObject 行为处理，勿设为固定二进制结构。

NEW_FETCH 解压后的对象：`all_item`（项目对象数组）、`all_group`（分组代表项数组）、`item_with_group`（数组，每项 `id` 与 `list`）；`J/utils/p.java:193-224,252-260`。S=1 按 bucket_id，2 按 album_id，3 按 bucket_id（`J/utils/p.java:459-468`）。JSON 对象列名来自 Cursor，没有固定字段表，audio projection 在 `J/utils/m.java:32`。图片/视频请求查询 projection=null，JSON 列集合取决于系统 MediaStore schema，待目标手机验证（`J/utils/p.java:459,467,155-185`）。

### F3. 原样 ASCII/平台默认字符串（f/f、f/k、f/n）

| 类 / 请求 | body 布局 | 意义 | 依据 |
|---|---|---|---|
| f/f / 公钥握手 | `body+0 bytes[L]` | 失败字面值 `failed`；成功是 `Base64(RSA/ECB/PKCS1Padding(clientPublicKey, ASCII "ok"))`，Base64 flag=0，可能带换行，不要使用 trim 后长度来拆帧 | `J/f/f.java:18-20`；`J/b/f.java:19-28` |
| f/k / SCEN | `body+0 one ASCII char` | Y 已提交扫描；N 请求列表为 null | `J/f/k.java:18-20`；`J/b/k.java:21-29` |
| f/n / WATCH | `body+0 one ASCII char` | Y 完成注册/撤销；N 尚无 push session | `J/f/n.java:18-20`；`J/b/n.java:18-33` |

### F4. 路径缩略图 f/j（OLD_THUMBNAIL）

`body+0 count:I32BE`。令第 `i` 项起点 `p_i`，`p_0=4`：

| 条目偏移 | 字段 | 类型 / 大小 |
|---:|---|---|
| p_i | failure | U8；0 有图，1 缺失/空 |
| p_i+1 | pathByteLength | I32BE，4 |
| p_i+5 | path | 平台默认编码 bytes[N] |
| p_i+5+N | imageByteLength | I32BE，4 |
| p_i+9+N | image | bytes[K]，通常 JPEG |

`p_(i+1)=p_i+9+N+K`。序列化每个字段的代码 `J/f/j.java:21-40`。条目顺序为 Map.keySet 迭代顺序，**不得假设等于请求顺序**（`J/f/j.java:24`、`J/b/j.java:27,203`）。缩略图生成倾向 200×200、JPEG quality=86（`J/b/j.java:52,72`），格式从生成器证实，不另设 width/height/mime 字段。

### F5. ID 缩略图 f/m（THUMBNAIL）

`body+0 count:I32BE`，第 `i` 项起点 `p_i`，`p_0=4`：

| 条目偏移 | 字段 | 类型 / 大小 |
|---:|---|---|
| p_i | failure | U8；0 有图，1 空 |
| p_i+1 | mediaId/albumId | I64BE，8 |
| p_i+9 | imageByteLength | I32BE，4 |
| p_i+13 | image | bytes[K] |

`p_(i+1)=p_i+13+K`。`J/f/m.java:22-39`；Map 迭代不保证顺序（`:25`）；JPEG quality=86（`J/b/m.java:80-82`）。没有请求尺寸字段。

**反编译异常，待验证：** `J/b/j.java:187-192` 与 `J/b/m.java:95-98` 的反编译 finally 似乎会用空数组覆盖成功图片；不能由此断言实际 APK 永远无缩略图，需 smali/字节码或实机核对。`b/j.java:159-160` 对 embeddedPicture 非空却传 null 解码，也应核对字节码。线字段结构直接来自序列化器，不受这些疑点影响。

### F6. 心跳 d/a/a 与 d/a/b

整个响应格式仍是 `BE32(3)||threeBytes`，body 长度 0。

* 手机主动心跳：`[06,01,01]`，构造 `super(6,1,1)`，`J/d/a/a.java:8-16`。
* 默认心跳响应：`[06,01,02]`，`J/d/a/b.java:9-10,21-22`。
* 对已解析对端心跳：`[06,H,02]`，`J/e/a/a/r.java:9`、`J/b/g.java:7-13`、`J/d/a/b.java:13-15,21-22`。
* KeepAliveMessageFactory 把 `d/a/b` 或 `b/g` 视为 response，不读取 S；`isRequest` 恒 false，`getResponse` 恒 null（`J/d/a/c.java:18-33`）。勿根据第三字节单独推断 framework 会回应手机请求。

### F7. 错误 a/*

| 类 | 语义 | 可序列化形态 / 处理 |
|---|---|---|
| a/a | Internal logic error | RuntimeException；encoder 重新抛异常，不定义错误 body；`J/a/a.java:4-6`，`J/d/b.java:19-26` |
| a/b | RSA 错误基类 | 三个 byte 无初始化赋值，默认全 0，`a()` 返回 `[a,c,b]=[00,00,00]`；`J/a/b.java:5-14` |
| a/c | Unsupported command/operation | factory 抛出后通常关闭连接；`J/a/c.java:4-10`、`J/e/a/a/a/b.java:25-26`、`J/d/c.java:32-34` |
| a/d | 公钥不存在 | 若交给 encoder，返回 `BE32(3)||00 00 00`；`J/a/d.java:4-6`、`J/d/b.java:20-21,34-38` |
| a/e | Command terminated | RuntimeException；`J/a/e.java:4-6`；没有专用 wire enum |
| a/f | RSA signature verify failed | 若交给 encoder，与 a/d 同为 `BE32(3)||00 00 00`，二者在线不可区分；`J/a/f.java:4-6`、`J/d/b.java:23-26,34-38` |

从现有 decoder `J/d/a.java:17` 看，验签异常直接抛出，不包装为正常消息，handler `J/d/c.java:15-20` 记录并关闭。故上述 a/d、a/f 的三零帧是 encoder **可处理的格式**，不应保证每次验签失败一定会收到该帧。

## G. 未注册请求 C=9 的 push 消息

都使用 `f/h` 未压缩 UTF-8 JSON，没有额外长度字段；外层长度遵守通用响应规则。

| 三字节响应头 | body | 依据 |
|---|---|---|
| 09 01 01 | 设备 JSON | `J/utils/f.java:16`；`J/utils/e.java:84-95` |
| 09 02 01 | 单个文件事件 JSON | `J/c/g.java:75` |
| 09 03 01 | 媒体变更 JSON | `J/utils/m.java:186` |

注意 push 构造参数的位置不同：设备/文件/媒体推送分别将第二响应字节设 1/2/3，第三响应字节固定 1。普通请求返回的第二响应字节是输入 version，而 push 第二字节是事件类别；需按 C=9 的专门头处理（`J/utils/f.java:16`、`J/c/g.java:75`、`J/utils/m.java:186`）。

## H. mac SSP 名称功能对照（已恢复现代编号，不可套到Java头）

现代 type 是 protobuf tag1 的enum，旧Java C是固定头字节；相同数字不意味着相同操作。完整现代字段布局见 `_modern_ssp.md`。下表将已恢复值与功能相近的Java项并列，二者不存在相同线编码映射。

| mac 类名 | 现代 SSPRequestType | Java 功能接近项 | 证据 |
|---|---:|---|---|
| SSPGetDeviceInfoRequest/Response | 2 | C=3、C=5 返回设备JSON | `D/ssp_descriptors.raw.txt:401` |
| SSPGetAudioLibraryRequest/Response | 6 | C=7,S=2；C=2音频查询 | `D/ssp_descriptors.raw.txt:405` |
| SSPGetPhotoLibraryRequest/Response | 4 | C=7,S=1 | `D/ssp_descriptors.raw.txt:403` |
| SSPGetVideoLibraryRequest/Response | 5 | C=7,S=3 | `D/ssp_descriptors.raw.txt:404` |
| SSPGetThumbnailRequest/Response | 3 | C=1/C=8 | `D/ssp_descriptors.raw.txt:402` |
| SSPHeartBeatRequest/Response | 1 | C=6 | `D/ssp_descriptors.raw.txt:400` |
| SSPMonitorFolderRequest/Header/Response | 23 / 24 / 25 | C=10 WATCH与C=9 push | `D/ssp_descriptors.raw.txt:422-424` |
| SSPCancelRequest | 36 | C=4 TERMINATE（现代有sessionId，旧版没有） | `D/ssp_descriptors.raw.txt:435` |
| SSPDeleteFileRequest/Response | 19 | C=11仅MediaStore id删除（现代嵌套SSPFile） | `D/ssp_descriptors.raw.txt:418` |
| SSPHandShakeRequest01/Response01/Request02/Response02 | 31 / 32 / 33 / 34 | C=14未签名单阶段公钥握手b/f；算法与字段不同 | `D/ssp_descriptors.raw.txt:430-433` |
| SSPQuitRequest | 35 | 无对应；Java C=13是EXIF | `D/ssp_descriptors.raw.txt:434`；`J/b/c.java:21-25` |

以下 mac 类在此 Java registry **没有对应的字段读取器**：`SSPClearClipboard*`（`D/ssp_classes.txt:61-63`）、`SSPDeleteClipboard*`（`:70-72`）、`SSPGetClipboard*`（`:95-97`）、`SSPPostClipboard*`（`:141-143`）、`SSPCreateFolder*`（`:66-68`）、`SSPGetDirFiles*`（`:101-103`）、`SSPGetFileCount*`（`:104-106`）、`SSPFileExist*`（`:85-87`）、`SSPRenameFile*`（`:145-147`）、`SSPUpdateFile*`（`:156-158`）、`SSPUploadFile*`（`:159-162`）、`SSPDownloadFile*`（`:76-78`）、`SSPPhotoSync*`（`:137-140`）、`SSPSyncMonitor*`（`:152-154`）。这些类属于现代Protobuf通道；完整tag/type/default布局已从mac metadata恢复，见 `_modern_ssp.md` 和 `SmartSyncProtocol.recovered.proto`，它们与Java注册命令之间没有一对一线编码映射。手机端具体业务行为仍须native/实机验证。

## I. mac ADB 常量直接核对

`D/adb_transport.constants.txt:2-22` 的 Mach-O 原始常量给出：CMD_Exif_Fetch=13、CMD_Close=4、CMD_DeleteMedia=11、CMD_UpdateMedia=12、CMD_DeviceInfo=3、CMD_Media_Fetch=7、CMD_File_Thumbnail=1、CMD_Handshake=14、CMD_File_Watch=10、CMD_Keep_Alive=5、CMD_Heart_Beat=6、CMD_Media_Thumbnail=8，Version 全为 1。这些已证实对应 Java 行为；CMD_Handshake=14 不需要注册，因为标志 0 路径不查 command registry。Java enum 中 EXIT 应按 mac 常量命名为 EXIF Fetch，SCEN 应按行为命名为 UpdateMedia/Scan。SSP protobuf 名称依然不能凭类名赋这些值。
