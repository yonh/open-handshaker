# SmartFolder 手机守护端：HTTP API、adb 连接流程与 native 层

本文是对 `com.smartisanos.smartfolder`（APK `SmartFolder.apk`，versionCode 52 / versionName 52.0，AndroidManifest 声明版本）反编译产物的逆向分析笔记，重点覆盖 4 个主题：

1. 手机端 **19999 端口 HTTP 服务**的全部端点；
2. **adb 连接流程**（服务如何启动、`adb forward` 的语义、服务权限）；
3. **AndroidManifest** 的权限 / receiver / intent-filter 清单；
4. **`libsmartfolder.so` 的 native 方法**用途。

## 目录与引用约定

| 前缀 | 路径 |
|---|---|
| `J/` | `handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/` |
| `M/` | `handshaker_analysis/jadx_out/sources/org/apache/mina/` |
| `R/` | `handshaker_analysis/jadx_out/resources/` |
| `D/` | `handshaker_analysis/dumps/` |

所有 `文件:行号` 均指上述目录下的当前文件。类名已被 ProGuard 混淆成单字母（`a`~`f` 子包 + `utils` 子包），因此下文一律给出完整包名。标 **待验证** 的结论表示只有代码/字符串静态证据、缺少抓包或运行时确认。

---

## 0. 总体架构（先看这一节）

手机端由**一个**前台 Service 拉起**两个** Apache MINA TCP 监听器：

| 端口 | 协议 | acceptor 构造 | codec | handler | 用途 |
|---:|---|---|---|---|---|
| `10086` | 自定义二进制（4 字节 BE 长度前缀 + 签名/命令头） | `J/d.java:22–28` | `ProtocolCodecFilter(new f())`，见 `J/d.java:25`、`J/d/f.java:9–22`（decoder `J/d/a.java`、encoder `J/d/b.java`） | `J/d/c.java:26`（日志 tag `CommandHandler`） | 主命令通道：设备信息、媒体列表、缩略图、EXIF、文件增删、目录监听 |
| `19999` | 明文 HTTP/1.1 | `J/d/d.java:16–23` | `HttpServerCodec`，见 `J/d/d.java:20` | `J/d/g.java`（日志 tag `FileServer`） | 纯 HTTP 文件下载服务（+ 一个 MD5 探活端点） |

两个端口都在 `AdbForwardService.onCreate()` 里被启动：`this.a = new d(); this.a.a();`（`J/AdbForwardService.java:67–68`），根包 `d.a()` 内部先启 19999（`J/d.java:20–21`）再启 10086（`J/d.java:22–28`）。

> **重要结论**：手机端 **没有** HTTP 缩略图端点、也 **没有** HTTP EXIF 端点。缩略图与 EXIF 只存在于 10086 二进制协议里（`0x01`/`0x08`/`0x0D` 命令，见 §2.5）。19999 上只有"下载任意文件"和"MD5 探活"两件事。mac 端的 `SFADBForwardMediaThumbnailOperation` / `SFADBForwardExifFetchOperation` 走的是 10086，不是 HTTP（`D/SmartFinderCore.strings.txt:20055、20126、20128`）。

**绑定地址是通配地址**：`new InetSocketAddress(19999)`（`J/d/d.java:15`）等价于 `0.0.0.0:19999`，`J/d.java:28` 同理。因此两个端口在手机 Wi-Fi 局域网内也可直连，adb forward 只是 USB 场景下的便利通道。**待验证**：Smartisan ROM 是否有额外 SELinux/iptables 限制（非原生 Android 无法确认）。

---

## 1. 19999 端口 HTTP 服务

### 1.1 启动与绑定

```java
// J/d/d.java:14-24
public final void a() {
    InetSocketAddress inetSocketAddress = new InetSocketAddress(19999);   // :15
    this.b = new NioSocketAcceptor();
    this.b.setReuseAddress(true);                                          // :17
    this.b.getSessionConfig().setTcpNoDelay(true);                         // :18
    this.b.getFilterChain().addLast("threadPool",
        new ExecutorFilter(Executors.newCachedThreadPool()));               // :19
    this.b.getFilterChain().addLast("http", new HttpServerCodec());        // :20
    this.a = new g();                                                      // :21
    this.b.setHandler(this.a);                                             // :22
    this.b.bind(inetSocketAddress);                                        // :23
}
```

要点：

- `ExecutorFilter(cachedThreadPool)` → 每个连接一个线程，无并发上限（`J/d/d.java:19`）。19999 **没有** idle timeout 设置，也没有 `KeepAliveFilter`。
- 没有设置 `IdleStatus`，所以连接可无限期保持（除非客户端断开）。
- 关闭路径 `J/d/d.java:26–33` 启一个守护线程跑 `J/d/e.java:18–26`：遍历 `getManagedSessions()` 全部 `close(true)` → `getFilterChain().clear()` → `unbind()` → `dispose()`。

### 1.2 端点总表

handler 是 `J/d/g.java`，**只看 query string，不看 URL path，也不看 HTTP method**（全文件只有一处 `httpRequest.getQueryString()`，`J/d/g.java:67`；`getMethod()`/`getUri()` 在整个文件中零出现）。因此下面两个端点在 `POST`/`PUT`/`DELETE` 下行为完全相同（request body 被 `HttpServerCodec` 消费后丢弃）。

| # | 请求 | 参数 | 状态码 | 响应体 | 用途 | 证据 |
|---:|---|---|---|---|---|---|
| E1 | `GET /?test<DATA>` | `DATA` = `queryString.substring(5)`，任意字节 | `200 OK` | **16 字节原始 MD5**，随后**主动关闭连接** | 连通性/时延探活 + 数据校验 | `J/d/g.java:68–80` |
| E2 | `GET /?file_path=<URL-encoded 绝对路径>` | `file_path`，正则 `file_path=([^*]*)` | `200 OK` 或 `206 Partial Content` | 文件原始字节（`FilenameFileRegion` 流式发送） | **任意文件下载**（缩略图原图、媒体文件、文档全部走这里） | `J/d/g.java:82–133` |
| E3 | `GET /`（无 query，或 query 不匹配上述两种） | — | `404 Not Found` | 无（`throw new FileNotFoundException`） | 兜底 | `J/d/g.java:68、82–86` |

mac 端只有两个 URL 模板，与 E1/E2 一一对应：

```
http://127.0.0.1:%lu/?test=123              # D/SmartFinderCore.strings.txt:15659
http://127.0.0.1:%lu/?file_path=%@          # D/SmartFinderCore.strings.txt:15661
http://127.0.0.1:%d/                        # D/SmartFinderCore.strings.txt:15658
```

`D/SmartFinderCore.strings.txt:15658` 的 `http://127.0.0.1:%d/` 未在 strings 里找到配套的请求方法名，**待验证**它是否只是 base URL 常量（拼接前缀），还是一次不带 query 的探测（那样会命中 E3 返回 404）。

### 1.3 E1：MD5 探活端点详解

```java
// J/d/g.java:67-81
String queryString = httpRequest.getQueryString();
if (queryString != null && queryString.startsWith("test")) {                 // :68
    byte[] bArrDigest = MessageDigest.getInstance("MD5")
        .digest(queryString.substring(5).getBytes(StringEncodings.UTF8));   // :69
    if (ioSession.containsAttribute(b)) { return; }                          // :70-72
    ioSession.setAttribute(b);                                               // :73
    ioSession.write(new DefaultHttpResponse(
        httpRequest.getProtocolVersion(), HttpStatus.SUCCESS_OK, new HashMap())); // :74
    IoBuffer autoExpand = IoBuffer.allocate(bArrDigest.length).setAutoExpand(true);
    autoExpand.order(ByteOrder.BIG_ENDIAN);                                  // :76
    autoExpand.put(bArrDigest);                                              // :77
    autoExpand.flip();
    ioSession.write(autoExpand).addListener(IoFutureListener.CLOSE);         // :79
    return;                                                                   // :80
}
```

行为精确描述：

1. 判据是 **query string 以字面 `test` 开头**，不是 `test=`。所以 `/?testabc` 也走这条分支，`DATA = "abc"`。
2. `DATA = queryString.substring(5)`，即**跳过 5 个字符**（`test` 或 `test=`）。`/?test=123` → `substring(5)` = `"123"` → `MD5("123")` 的 16 字节原始摘要。
3. 返回 200 **响应头没有 body 声明**（`new HashMap()` 空 header map，`J/d/g.java:74`），也没有 `Content-Length`。随后单独 `write` 一个 16 字节的 `IoBuffer`（`J/d/g.java:75–78`）。
4. `IoFutureListener.CLOSE` 在写完后**立即关闭会话**（`J/d/g.java:79`）。这是短连接探活，`connection: keep-alive` 对它无效。
5. `responseFlag`（字段 `b`，`J/d/g.java:34`）在同一会话第二次进入时直接 `return`（`J/d/g.java:70–72`），即**每连接最多响应一次探活**。因为后面就会关连接，实际不可达。**待验证**。
6. 日志会打印完整 query：`"ClientToProxyIoHandler ... messageReceived  >>  " + session + " \n :   " + obj`（`J/d/g.java:64`）。注意 `k.b()` 是 `Log.i`，但在非 debuggable 机型上被全局开关关掉（`J/utils/k.java:8` + `J/FolderApp.java:14–16、22–29`）。

最小验证命令：

```bash
curl -s "http://<phone>:19999/?test=123" | xxd        # 应输出 16 字节
printf '123' | md5                                    # 202cb962ac59075b964b07152d234b70
```

### 1.4 E2：文件下载端点详解

#### 1.4.1 路径提取

```java
// J/d/g.java:82-95
Matcher matcher = Pattern.compile("file_path=([^*]*)").matcher(queryString);   // :82
String strGroup = matcher.find() ? matcher.group(1) : null;                     // :83
if (TextUtils.isEmpty(strGroup)) { throw new FileNotFoundException(); }          // :84-86
String strDecode = URLDecoder.decode(strGroup, StringEncodings.UTF8);           // :87
k.b("FileServer", "file Path : " + strDecode);                                  // :88
if (TextUtils.isEmpty(strDecode)) { throw new FileNotFoundException(); }         // :89-91
File file = new File(strDecode);                                                 // :92
if (!file.exists()) { throw new FileNotFoundException(); }                       // :93-95
```

**没有任何路径白名单/沙箱检查**：`new File(strDecode)` 直接用客户端给的值，`file.exists()` 是唯一校验（`J/d/g.java:92–95`）。配合 `WRITE_EXTERNAL_STORAGE`（§3），配合 `adb forward` 后等同于"主机可读手机任意可访问路径"。这是本服务最大的攻击面。

正则语义的三个坑：

- `matcher.find()` 而非 `matches()` → `file_path=` 可以出现在 query 的任意位置，前面可以有别的参数。
- `([^*]*)` 排除字符是 `*`，**不是 `&`**。因此 `/?file_path=/a.jpg&x=1` 会把 `/a.jpg&x=1` 整段当成路径。
- `*` 在正则里同时是量词，但字符类 `[^*]` 内它是字面量。所以路径里含 `*` 会被截断。

结论：**复刻实现应只发送单个 `file_path` 参数、不要在后面追加任何 query**；并且用标准 `application/x-www-form-urlencoded` 编码，路径里的字面 `+` 必须编码为 `%2B`（`URLDecoder.decode` 会把 `+` 解成空格，`J/d/g.java:87`）。

#### 1.4.2 Range / 断点续传

```java
// J/d/g.java:96-108
String header = httpRequest.getHeader("range");                                  // :96
if (TextUtils.isEmpty(header)) {
    j = 0;                                                                       // :98
} else {
    String strTrim = header.trim();                                              // :100
    if (Pattern.compile("^bytes=\\d*-\\d*(,\\d*-\\d*)*$").matcher(strTrim).find()) { // :101
        String[] strArrSplit = strTrim.substring(6).split("-");                   // :102
        j2 = strArrSplit.length == 0 ? 0L : Long.parseLong(strArrSplit[0]);      // :103
    } else { j2 = 0; }                                                            // :105
    j = j2;                                                                      // :107
}
```

- 只取 `Range` 里的**起始偏移**（`bytes=N-` 或 `bytes=N-M` 都是取 `N`，`M` 被丢弃，`J/d/g.java:102–103`）。
- 正则允许多段（`,\d*-\d*)*`）但后续处理会把 `1-100,200-300` 用 `split("-")` 得到 `["1","100,200","300"]`，只取 `["1"]`。多段 Range 实际退化为单段，行为正确但非标准。**待验证**：客户端若依赖多段 Range 需抓包确认。
- `bytes=abc` 或 `bytes=-500`（suffix range）→ 正则不匹配或 `Long.parseLong` 抛异常 → 走 `exceptionCaught`，`NumberFormatException` 不是 `IOException` 子类，所以**没有**响应状态码，直接 `ioSession.close(false)`（`J/d/g.java:37–55`）。**待验证**：客户端对空响应的容错。
- `Range` 头是 `httpRequest.getHeader("range")`（小写），MINA 的 `HttpRequest` 头查找本身大小写不敏感，所以 `Range:` / `range:` 都能命中。

#### 1.4.3 响应头

```java
// J/d/g.java:109-127
if (!ioSession.containsAttribute(b)) {          // responseFlag，每连接只发一次头部  :109
    ioSession.setAttribute(b);
    HashMap map = new HashMap();
    map.put("connection", "keep-alive");                                       // :112
    int iLastIndexOf = file.getName().lastIndexOf(46);                        // :113 ('.')
    if (iLastIndexOf <= 0
        || (strA = utils.g.a(file.getName()
              .substring(iLastIndexOf + 1).toLowerCase())) == null
        || strA.isEmpty()) {
        map.put("content-type", "application/octet-stream");                  // :115
    } else {
        map.put("content-type", strA);                                        // :117
    }
    if (j > 0) {
        httpStatus = HttpStatus.SUCCESS_PARTIAL_CONTENT;                       // :120
        map.put("content-length", Long.toString(file.length() - j));          // :121
        map.put("content-range", ":bytes " + j + "-" + file.length());        // :122
    } else {
        httpStatus = HttpStatus.SUCCESS_OK;                                    // :124
        map.put("content-length", Long.toString(file.length()));              // :125
    }
    ioSession.write(new DefaultHttpResponse(
        httpRequest.getProtocolVersion(), httpStatus, map));                  // :127
}
```

**MIME 映射表**（`J/utils/g.java:13–22`，唯一入口 `J/utils/g.java:25–27`）只有 **10 条，全部是音频**：

| 扩展名 | MIME | 扩展名 | MIME |
|---|---|---|---|
| `3gp` | `audio/3gp` | `m4a` | `audio/x-m4a` |
| `aac` | `audio/aac` | `mp3` | `audio/mp3` |
| `aifc` | `audio/aifc` | `wav` | `audio/wav` |
| `aiff` | `audio/aiff` | `ape` | `audio/x-ape` |
| `caf` | `audio/x-caf` | `flac` | `audio/x-flac` |
| `aifc`/`aiff` 见上 | — | — | — |

完整列表按 `J/utils/g.java:13`–`:22` 逐行：`3gp→audio/3gp`、`aac→audio/aac`、`aifc→audio/aifc`、`aiff→audio/aiff`、`ape→audio/x-ape`、`caf→audio/x-caf`、`flac→audio/x-flac`、`m4a→audio/x-m4a`、`mp3→audio/mp3`、`wav→audio/wav`。

即：**jpg/png/mp4/pdf/zip 一律返回 `application/octet-stream`**（`J/d/g.java:115`）。扩展名先 `toLowerCase()`（`J/d/g.java:114`），`lastIndexOf('.') <= 0` 时（即无扩展名、或文件名以 `.` 开头）也走 `application/octet-stream`。

已知的两个实现缺陷，对复刻实现有直接影响：

1. **`Content-Range` 格式错误**：`":bytes " + j + "-" + file.length()`（`J/d/g.java:122`）。RFC 7233 要求 `bytes <start>-<end>/<total>`，这里既缺 `bytes` 前缀（写成 `:bytes`）、也缺 `/<total>`。严格解析 Content-Range 的客户端会失败。**待验证**：mac 端 HTTP 客户端（应该是 `NSURLSession` / `GCDAsyncSocket`）是否容错——从它只在 strings 里留了 `hasHeader`、`totalBodyLength`、`rawData`（`D/SmartFinderCore.strings.txt:15548–15554`）来看是手写解析器，很可能只读 `content-length` 而不读 `content-range`。
2. **`responseFlag` 导致 keep-alive 会话只发一次头部**：`J/d/g.java:109`。虽然第 `:112` 行写了 `connection: keep-alive`，但同一 TCP 连接上的**第二个请求不会写任何响应行/头部**，直接开始写文件体（`J/d/g.java:129–133`）。这在 HTTP/1.1 下是非法的。实际后果：客户端必须**每个文件下载都用新连接**，或接受第二个请求的畸形响应。**待验证**：抓包确认 mac 是否真的复用连接。

#### 1.4.4 文件体发送

```java
// J/d/g.java:129-133
FileChannel channel = new FileInputStream(file).getChannel();
FilenameFileRegion filenameFileRegion =
    new FilenameFileRegion(file, channel, j, channel.size());                // :130
DefaultWriteFuture defaultWriteFuture = new DefaultWriteFuture(ioSession);
ioSession.getFilterChain().fireFilterWrite(
    new DefaultWriteRequest(filenameFileRegion, defaultWriteFuture, null));   // :132
defaultWriteFuture.addListener((IoFutureListener<?>) new h(this, channel));   // :133
```

- 用 MINA `FilenameFileRegion`（零拷贝 sendfile 类路径），不是 `ByteBuffer` 循环。
- `FilenameFileRegion(file, channel, j, channel.size())` 第 4 参是 `length`，传的是 `channel.size()`（全文件长）而不是 `file.length() - j`。**待验证**：MINA 该构造器是否会自行用 `position+length` 与 `channel.size()` 取 min；若不取 min，`Range` 下载会多发 `j` 字节。需要查 `M/core/file/FileRegion.java` 与 `M/core/file/FilenameFileRegion.java` 确认。**建议复刻实现直接传 `file.length() - j`。**
- 写完成后 `IoFutureListener`（`J/d/h.java:20–25`）关闭 `FileChannel`；异常被静默吞掉（`J/d/h.java:22–24` 空 catch）。

### 1.5 错误码映射

```java
// J/d/g.java:37-56
if (th instanceof org.apache.a.a) {                 // :38 混淆的连接重置异常
    k.b("FileServer", "... ECONNRESET (Connection reset by peer) ");  // :39
} else {
    if (th instanceof FileNotFoundException) {
        → HttpStatus.CLIENT_ERROR_NOT_FOUND           // :44-45  (404)
    } else if (th instanceof ProtocolDecoderException) {
        → HttpStatus.CLIENT_ERROR_BAD_REQUEST         // :46-47  (400)
    } else if (th instanceof IOException) {
        → HttpStatus.SERVER_ERROR_INTERNAL_SERVER_ERROR // :48-49 (500)
    }
    if (defaultHttpResponse != null) ioSession.write(defaultHttpResponse); // :51-53
}
ioSession.close(false);                                                    // :55
```

| 情况 | 状态码 | 证据 |
|---|---|---|
| query 为 null、不以 `test` 开头、`file_path` 缺失/为空、路径解码后为空、文件不存在 | `404` | `J/d/g.java:44–45、68、84–95` |
| HTTP 报文本身解析失败 | `400` | `J/d/g.java:46–47` |
| 其他 `IOException`（如 `FileInputStream` 打开失败、无读权限） | `500` | `J/d/g.java:48–49` |
| 对端 RST（`org.apache.a.a`） | **不写任何响应**，直接关闭 | `J/d/g.java:38–39、55` |
| 其它异常类型（如 §1.4.2 的 `NumberFormatException`） | **不写任何响应**，直接关闭 | `J/d/g.java:51、55` |

`org.apache.a.a` 是被混淆掉的 `TransportException`（`org/apache/**` 整包都被重命名，见 `J/d/g.java:38`）。

### 1.6 日志

所有 19999 相关日志 tag 为 `"FileServer"`，共 6 处：`J/d/g.java:39、41、64、88、139、152、157`。注意 `messageReceived` 那条（`:64`）会把**整个 `HttpRequest` 对象 toString** 打进日志，包含完整路径与全部 query。

---

## 2. 10086 端口：为什么缩略图/EXIF 不在 HTTP 上

任务描述提到"缩略图/exif"端点。反编译结论是它们不在 19999，而在 10086 的二进制协议里。这里给出精简版，完整分析见 `_trust_session.md` 与 `_file_media.md`。

### 2.1 帧格式

```
F    0        4   5                                      133  134  135  136
     +--------+---+---------------------------------------+----+----+----+------
     | u32 BE |nz |             RSA signature            |CMD |arg |ver |data…
     +--------+---+---------------------------------------+----+----+----+------
```

- 外层 `u32 BE` 长度，**不含长度字段自身**（`J/d/b.java:34–40`）。
- `F[4]`：非零 = 该帧带签名（`J/e/a/c.java:14–16、60–62`）。
- 签名固定 128 字节 → RSA-1024，`SHA256withRSA`，覆盖 `F[133,end)`（`J/e/a/c.java:36–41`）。
- `F[133]`=CMD，`F[134]`=arg，`F[135]`=Version（mac 常量 `_Version = 1`，`D/adb_transport.constants.txt:3`）。
- 响应方向头部为 `[CMD][Version][arg]`（与请求方向第 2/3 字节互换，`J/f/a.java:5–17` 的 `b()` 返回 `{a,c,b}`）。

### 2.2 命令号表（mac 常量 ↔ Android 枚举 ↔ 用途）

命令号来源：`J/e/a/a/a.java`（枚举名字面量）+ `D/adb_transport.constants.txt`（mac 侧常量，二者完全吻合）。

| CMD | Android 枚举名（`J/e/a/a/a.java`） | mac 常量（`D/adb_transport.constants.txt`） | 请求类 | 响应类 | 作用 |
|---:|---|---|---|---|---|
| `0x01` | `OLD_THUMBNAIL`（`:33`） | `CMD_File_Thumbnail = 0x01`（`:13`） | `J/b/j.java` | `J/f/j.java` | **按文件路径**取缩略图（图片/视频/音频） |
| `0x02` | `FETCH`（`:49`） | —（mac 无） | `J/b/d.java` | `J/f/d.java` | 旧版媒体列表，JSON |
| `0x03` | `GET`（`:83`） | `CMD_DeviceInfo = 0x03`（`:9`） | `J/b/e.java` | `J/f/e.java` | **设备信息** JSON |
| `0x04` | `TERMINATE`（`:66`） | `CMD_Close = 0x04`（`:4`） | `J/b/l.java` | `J/f/l.java` | 取消当前在途命令 |
| `0x05` | `KEEP_ALIVE`（`:100`） | `CMD_Keep_Alive = 0x05`（`:19`） | `J/b/h.java` | `J/f/e.java` | 保活；响应体是**设备信息 JSON**；并把该会话登记为推送目标 |
| `0x06` | `HEARTBEAT`（`:117`） | `CMD_Heart_Beat = 0x06`（`:20`） | `J/b/g.java` | `J/d/a/b.java` | ping/pong |
| `0x07` | `NEW_FETCH`（`:134`） | `CMD_Media_Fetch = 0x07`（`:11`） | `J/b/i.java` | `J/f/i.java` | 分组媒体列表，**GZIP** JSON |
| `0x08` | `THUMBNAIL`（`:151`） | `CMD_Media_Thumbnail = 0x08`（`:21`） | `J/b/m.java` | `J/f/m.java` | 按 **MediaStore row id** 取缩略图 |
| `0x09` | （不在枚举，仅推送） | — | — | `J/f/h.java` | 主动推送：sub1 设备信息 / sub2 文件变化 / sub3 媒体变化 |
| `0x0A` | `WATCH`（`:168`） | `CMD_File_Watch = 0x0a`（`:17`） | `J/b/n.java` | `J/f/n.java` | 目录监听注册/注销，返回 `"Y"`/`"N"` |
| `0x0B` | `DELETE`（`:185`） | `CMD_DeleteMedia = 0x0b`（`:6`） | `J/b/b.java` | `J/f/b.java` | 删除 MediaStore 行 |
| `0x0C` | `SCEN`（`:202`） | `CMD_UpdateMedia = 0x0c`（`:8`） | `J/b/k.java` | `J/f/k.java` | 触发 `MediaScanner.scanSingleFile` |
| `0x0D` | `EXIT`（`:219`，**EXIF 的拼写错误**） | `CMD_Exif_Fetch = 0x0d`（`:2`） | `J/b/c.java` | `J/f/c.java` | **EXIF** 读取 |
| `0x0E` | （不在枚举，走明文分支） | `CMD_Handshake = 0x0e`（`:15`） | `J/b/f.java` | `J/f/f.java` | **握手 / 客户端 RSA 公钥登记** |

### 2.3 缩略图实现细节（`0x01` / `0x08`）

`0x01`（`J/b/j.java`）按路径取图，子类型在 `J/b/j.java:81`：

- `type=1` 图片：`BitmapFactory` 两遍解码，`inSampleSize = min(w/200, h/200)`（`J/b/j.java:83–90`）。
- `type=2` 视频：`MediaMetadataRetriever.getFrameAtTime(-1)`（取首帧，`J/b/j.java:91–95`）。
- `type=3` 音频：`MediaMetadataRetriever.getEmbeddedPicture()`（内嵌封面）。

统一后处理：`ThumbnailUtils.extractThumbnail(bitmap, 200, 200)` → 按 `ExifInterface` 的 `Orientation`（3/6/8 → 旋转 180/90/270 度，`J/b/j.java:54–70`）→ `compress(JPEG, 86)`（`J/b/j.java:72`）。10 线程池 + `CountDownLatch`（`J/b/j.java:24`）。

`0x08`（`J/b/m.java`）按 MediaStore id 取图：sub1 `MediaStore.Images.Thumbnails`、sub2 `MediaStore.Video.Thumbnails`、sub3 `content://media/external/audio/albumart`（`J/b/m.java:26`）。

### 2.4 EXIF 实现（`0x0D`）

`J/b/c.java:21` 调 `utils/p.a(String)`，其实现（`J/utils/p.java:233–250`）反射读取 `ExifInterface.mAttributes` 私有字段，转成 `JSONObject`：

```java
// J/utils/p.java:233-240
public static String a(String str) {
    ExifInterface exifInterface = new ExifInterface(str);
    Field declaredField = ExifInterface.class.getDeclaredField("mAttributes"); // :236
    declaredField.setAccessible(true);
    HashMap map = (HashMap) declaredField.get(exifInterface);
    return map == null ? new JSONObject().toString() : new JSONObject(map).toString();
}
```

即：**手机端返回的是 `ExifInterface` 内部 map 的原始 key/value**（如 `Orientation`、`DateTimeOriginal`、`FNumber`、`ExposureTime`），不是标准 EXIF 二进制块。任何文件路径都可以（无白名单）。

### 2.5 会话/保活模型

- 服务端默认 `setIdleTime(IdleStatus.BOTH_IDLE, 10)`（10 秒，`J/d.java:27`）。
- `KEEP_ALIVE (0x05)` 把该会话 idle 提到 20 秒并装 `KeepAliveFilter`（10 秒间隔，`J/b/h.java:15–20`）。
- `messageSent` 里若 `keep_alive_attr` 不为 true 就**关闭会话**（`J/d/c.java:50–57`）。即：不发 `0x05` 的会话在第一次响应后就断开。
- 首次消息是 `0x05` 的会话被登记为"推送目标"（`J/d/c.java:43`），只有它会收到 `0x09` 推送（`J/d/c.java:41–45`、`J/c/c.java:48–60`）。
- `AdbForwardService` 另有 60 秒看门狗 Runnable（`J/a.java:14–20`），链路消失时 `stopSelf()`（`J/a.java:18`）；`onDestroy` 最后 `Process.killProcess(Process.myPid())`（`J/AdbForwardService.java:95`），即**服务停止即杀进程**。

---

## 3. adb 连接流程

### 3.1 手机端：服务如何被启动

一共只有 4 条触发路径，全部指向同一个 `AdbForwardService`：

| # | 触发者 | 证据 |
|---:|---|---|
| 1 | `UsbReceiver` 收到 `android.hardware.usb.action.USB_STATE`，extras 的 `connected == true` → `startService(AdbForwardService)`；`false` → `stopService` | `J/UsbReceiver.java:10–15` |
| 2 | mac 通过 adb `shell am startservice --user 0 com.smartisanos.smartfolder/.AdbForwardService` | `D/SmartFinderCore.strings.txt:15613–15616` |
| 3 | 10086 收到**明文帧**（`F[4]==0`）且 `ro.product.brand == "smartisan"` 且 ROM 版本 `< "2.5.8"` 时，app 自己 `startService` 带 action `ACTION_ALERT_SECURITY_SYSTEM_UPDATE`，弹出"请升级系统"对话框 | `J/e/a/a.java:35–40`；`J/AdbForwardService.java:101–107`；对话框 `J/AdbForwardService.java:35–37`，窗口类型 `2003 = TYPE_SYSTEM_ALERT`（`J/AdbForwardService.java:36`） |
| 4 | manifest 里 `AdbForwardService` 声明了 intent-filter action `com.smartisanos.smartfolder.AdbForwardService.FILTER` 且 `exported=true`，任何应用可显式启动 | `R/AndroidManifest.xml:26–32` |

`MainActivity` **不启动服务**。它只是 `onCreate` 里跑一个 AsyncTask，把本机 Wi-Fi IP 通过 TCP 写到硬编码的 `172.16.14.38:1987`：

```java
// J/MainActivity.java:37-39
public static String a() { return "172.16.14.38"; }
// J/MainActivity.java:21-24
k.a("HostAddress() : " + i.a(FolderApp.a()));        // 打印本机 Wi-Fi IP
return Boolean.valueOf(i.a(FolderApp.a(), MainActivity.a(), i.a(FolderApp.a())));
```

`utils/i.a(Context,String,String)` 的行为（`J/utils/i.java:53–85`）：先 `InetAddress.getByName(target).isReachable(1000)`（`J/utils/i.java:55–57`），**可达就抛异常**（防止重复连接同一台机器）；否则 `new Socket(target, 1987)` 并 `println(payload)` 后关闭（`J/utils/i.java:59–64`）。端口 1987 是硬编码的（`J/utils/i.java:59`）。

> `172.16.14.38:1987` 显然是 Smartisan 内网开发/调试地址。注意 **`MainActivity` 在 AndroidManifest 里没有 `<activity>` 声明**（见 `R/AndroidManifest.xml:18–47`），所以它在本 build 中根本不可启动，是死代码。

### 3.2 `adb forward tcp:10086 tcp:19999` 的含义

**先澄清一个容易混淆的点**：任务描述里写的 `adb forward tcp:10086 tcp:19999` 如果按字面执行，含义是"**主机** 10086 → **手机** 19999"（即只转发 HTTP 文件服务）。而 mac 客户端**实际**是分别建两条转发：

```
adb forward tcp:<本地端口A> tcp:10086     # 二进制协议
adb forward tcp:<本地端口B> tcp:19999     # HTTP 文件服务
```

`adb forward tcp:<local> tcp:<remote>` 的语义是：adb 在**主机**上监听 `<local>`，把该端口收到的字节流通过 adb 通道转发到**设备**上的 `<remote>`（由 adbd 发起连接）。所以只有一条 adb USB 链路，主机侧就等于有两个 localhost 端口分别映射到手机的两个服务，mac 侧再用 `127.0.0.1` 访问（`D/SmartFinderCore.strings.txt:15658–15661`）。

mac 侧的具体序列（全部字符串证据，`D/SmartFinderCore.strings.txt`）：

| 步骤 | 命令 / 字符串 | 行号 |
|---:|---|---|
| 1 | `start-server` | `:15594` |
| 2 | `devices`，用 `%@(.+)` 解析，状态取 `unauthorized` / `device` / `offline` | `:15595–15599` |
| 3 | `forward --list`，正则 `%@ tcp:(\d+) tcp:10086` 查是否已有本机 → 10086 的转发 | `:15619–15621` |
| 4 | 已有则复用其本地端口（`tcp:%lu`）；否则新建（`tcp:%@` / `tcp:10086`） | `:15622–15625` |
| 5 | 同上，对 19999：正则 `%@ tcp:(\d+) tcp:19999`，参数 `tcp:%u` / `tcp:19999` | `:15654–15656` |
| 6 | 清理：`forward --remove tcp:<port>` | `:15622–15623` |
| 7 | 请求 URL：`http://127.0.0.1:%lu/?test=123`（日志 `testdata=%@`）、`http://127.0.0.1:%lu/?file_path=%@`（日志 `response=%@`） | `:15657–15661` |

> 本地端口 `<local>` 由 mac 运行时选择（`socket local port=%d`，`:15591`；以及 `startADBForwardAtPort:`，`:13780`），**看起来是临时端口**，具体选择算法 **待验证**。因此不能假定主机侧一定是 10086。

mac 端建立连接前的其它 adb 交互（同样在 `D/SmartFinderCore.strings.txt`）：

| 用途 | 字符串 | 行号 |
|---|---|---|
| 查询已安装版本 | `dumpsys package com.smartisanos.smartfolder` + 正则 `(.*)versionCode=(\d+)` | `:15601–15603` |
| 推送/安装 APK | `SmartFolder.apk`、`install`、`[INSTALL_FAILED_UNKNOWN_SOURCES`、`[INSTALL_FAILED_VERSION_DOWNGRADE`、`[INSTALL_FAILED_PARSE_FAILED_INCONSISTENT_CERTIFICATES`、`[INSTALL_FAILED` | `:15604–15609` |
| 重启服务 | `am force-stop com.smartisanos.smartfolder` | `:15613` |
| 拉起服务 | `startservice --user 0` + `com.smartisanos.smartfolder/.AdbForwardService`，检查返回 `Starting service` | `:15614–15616` |
| 确认服务存活 | `dumpsys activity services com.smartisanos.smartfolder`，失败重试 `retry getServiceInfoForDevice` | `:15617–15618、15645` |
| 读电量 | `dumpsys battery` + 正则 `(.*): (\d*)` + `level` | `:15627–15629、15646` |
| 读设备名 | `getprop` + `ro.product.name`，取值集合 `yinger/msm8974sfo/msm8916_32/icesky_msm8992/surabaya/colombo/odin` | `:15610–15612、15637–15644、15647` |
| 读机身颜色 | `getprop` + `ro.housing.color`，取值 `black/white/beige/golden/wine-red/copper-red` | `:15630–15636` |
| 截图 | `screencap -p /sdcard/sfscreenshot.png` → `pull` → `rm` | `:15649–15653` |
| adb 路径 | `%@/Contents/Frameworks/%@.framework/Resources/adb`；`kill-server` | `:15717、15719` |
| SDK 版本 | `getprop ro.build.version.sdk` | `:15611` |

### 3.3 服务权限与身份

| 项 | 值 | 证据 |
|---|---|---|
| 包名 | `com.smartisanos.smartfolder` | `R/AndroidManifest.xml:5` |
| `sharedUserId` | **`android.uid.system`** | `R/AndroidManifest.xml:23` |
| `debuggable` | `false` | `R/AndroidManifest.xml:24` |
| `allowBackup` | `true` | `R/AndroidManifest.xml:25` |
| `AdbForwardService` | `exported=true`，intent-filter action `com.smartisanos.smartfolder.AdbForwardService.FILTER`，**无权限保护** | `R/AndroidManifest.xml:26–32` |
| `SmartfolderMediaScannerService` | `exported=true`，**无 intent-filter、无权限保护** | `R/AndroidManifest.xml:33–35` |
| `minSdkVersion` / `targetSdkVersion` | 16 / 19 | `R/AndroidManifest.xml:6–8` |

`android.uid.system` 共享 UID 是这套设计的基石：它让本应用能收到普通应用收不到的系统广播（`android.hardware.usb.action.USB_STATE` 是 protected broadcast），并能以前台 Service + `TYPE_SYSTEM_ALERT` 弹窗。因为 `targetSdkVersion=19`，`WRITE_EXTERNAL_STORAGE` 在安装时自动包含读权限（API 23 前 `READ_EXTERNAL_STORAGE` 不需要运行时授予），因此**读全盘外部存储**不需要额外声明。

版本不一致的证据：`assets/version.properties:3` 是 `VERSION_CODE=63`，而 manifest 是 `versionCode=52`；且该 properties 文件里残留了未清理的 git 冲突标记（`:2` `>>>>>>>=origin/master`、`:4` `=\=\=\=\=\=\=`、`:5` `<<<<<<<=HEAD`）。说明 manifest 落后于最后一次构建。**待验证**：实际安装的 APK 用的是 52 还是 63。

### 3.4 完整时序

```text
Mac                                    Phone (adbd)                    App
 │  adb start-server                       │                          │
 │  adb devices → <serial> device          │                          │
 ├──────────────────────────────────────────────────────────────────────►│
 │  adb shell am force-stop com.smartisanos.smartfolder                 │
 │  adb shell am startservice --user 0 com.smartisanos.smartfolder/.AdbForwardService
 │                                          │  startService ──────────►│
 │                                          │            UsbReceiver 或显式 intent
 │                                          │                          │ onCreate:
 │                                          │                          │  ├ new d().a() → bind 0.0.0.0:19999
 │                                          │                          │  ├ bind 0.0.0.0:10086, BOTH_IDLE 10s
 │                                          │                          │  ├ m.a().b() 注册 MediaStore ContentObserver
 │                                          │                          │  ├ e.a().a(ctx) 注册电量/屏幕/计数 ContentObserver
 │                                          │                          │  └ startForeground(1, notification)
 │  adb forward --list → 复用或新建 tcp:<A> tcp:10086                   │
 ├──────────────────────────────────────────────────────────────────────►│ adbd connect 127.0.0.1:10086
 │  adb forward tcp:<B> tcp:19999                                        │
 ├──────────────────────────────────────────────────────────────────────►│ adbd connect 127.0.0.1:19999
 │                                                                  ◄────┤
 │  TCP 127.0.0.1:<A>  ── 明文握手帧 ────────────────────────────────────►│  0x0E: RSA 公钥 + MD5 + AES-256-CTR 密文
 │  ◄── base64(RSA_enc("ok")) 或 "failed" ───────────────────────────────┤
 │  TCP 127.0.0.1:<B>  ── GET /?test=123 ───────────────────────────────►│
 │  ◄── 200 + MD5("123") 16 字节 ───────────────────────────────────────┤  (随后主动关闭)
 │  TCP 127.0.0.1:<B>  ── GET /?file_path=%2F…%2Fphoto.jpg ────────────►│
 │  ◄── 200 + image/jpeg… (octet-stream) + 文件体 ──────────────────────┤
```

`AdbForwardService.onCreate` 的完整顺序（`J/AdbForwardService.java:59–86`）：

```java
k.d("AdbForwardService", "onCreate()");        // :62
e.a().a(this);                                 // :63  注册设备状态 observer（电量/屏幕/计数）
this.d = m.a();                                // :64
this.d.b();                                    // :65  快照 MediaStore + 注册 ContentObserver
e = new a(Looper.getMainLooper());             // :66
this.a = new d();                              // :67  根包 d：启动 10086 + 19999
this.a.a();                                    // :68
a();                                           // :69  排入 60 秒看门狗
if (FolderApp.a().b) { /* ROM 版本以 "1.5" 开头 → 显示通知 */ }  // :70–84
startForeground(1, notification);              // :85
```

前台通知只在 ROM 版本以 `1.5` 开头时才构造（`J/FolderApp.java:47–51` → `J/AdbForwardService.java:70`），否则退化为空的 `new Notification()`（`J/AdbForwardService.java:83`）。通知文案 `Connected to HandShaker` / `已连接至 HandShaker`（`R/res/values/strings.xml:6`、`R/res/values-zh-rCN/strings.xml:6`）。

---

## 4. AndroidManifest 完整清单

来源：`R/AndroidManifest.xml`（全文 48 行）。

### 4.1 `uses-permission`（9 项）

| # | 权限 | 推断用途（需代码对应） | 证据 |
|---:|---|---|---|
| 1 | `android.permission.ACCESS_WIFI_STATE` | `utils/i.a(Context)` 用 `WifiManager.getConnectionInfo().getIpAddress()` 取本机 IP | `R/AndroidManifest.xml:9`；`J/utils/i.java:19–21` |
| 2 | `android.permission.INTERNET` | 10086/19999 两个 MINA acceptor 的 socket | `R/AndroidManifest.xml:10` |
| 3 | `android.permission.WRITE_EXTERNAL_STORAGE` | 文件下载写入 / MediaScanner；因 `targetSdkVersion=19`，隐含读权限 | `R/AndroidManifest.xml:11、7` |
| 4 | `android.permission.ACCESS_ALL_DOWNLOADS` | 设备信息 JSON 的 `download_number`（`content://downloads/all_downloads`） | `R/AndroidManifest.xml:12`；`J/utils/e.java:22、141` |
| 5 | `android.permission.READ_PHONE_STATE` | **代码中未见使用**，推断用于设备标识/序列号。**待验证** | `R/AndroidManifest.xml:13` |
| 6 | `android.permission.WAKE_LOCK` | `SmartfolderMediaScannerService` 持 `PARTIAL_WAKE_LOCK` | `R/AndroidManifest.xml:14`；`J/SmartfolderMediaScannerService.java:154` |
| 7 | `android.permission.WRITE_MEDIA_STORAGE` | Smartisan 厂商权限，MediaStore 写入/删除 | `R/AndroidManifest.xml:15` |
| 8 | `android.permission.SYSTEM_ALERT_WINDOW` | 升级提示框 `getWindow().setType(2003)` | `R/AndroidManifest.xml:16`；`J/AdbForwardService.java:36` |
| 9 | `android.permission.ACCESS_NETWORK_STATE` | `utils/i.a(Context,String)` 里 `getNetworkInfo(1)` 判断 Wi-Fi 已连接 | `R/AndroidManifest.xml:17`；`J/utils/i.java:41–51` |

第 4、7 项（`ACCESS_ALL_DOWNLOADS`、`WRITE_MEDIA_STORAGE`）不是标准 AOSP 权限，是 Smartisan ROM 私有权限 —— 这也说明该 APK **无法在非 Smartisan 设备上正常工作**。

### 4.2 `receiver`（1 项）

```xml
<!-- R/AndroidManifest.xml:36-40 -->
<receiver android:name="com.smartisanos.smartfolder.UsbReceiver">
    <intent-filter>
        <action android:name="android.hardware.usb.action.USB_STATE"/>
    </intent-filter>
</receiver>
```

- **没有** `android:permission`、`android:exported`、`android:enabled` 属性。
- `USB_STATE` 是 protected broadcast，只有系统能发；`sharedUserId="android.uid.system"`（`:23`）使本应用能收到。
- extras 读取 `intent.getExtras().getBoolean("connected")`（`J/UsbReceiver.java:11`）—— 标准 `USB_STATE` extras 的 `connected` 键。**未判空** `getExtras()`，若被无 extras 的广播触发会 NPE。**待验证**：是否可能有这样的发送方。

### 4.3 `service`（2 项）

| 名称 | exported | intent-filter | 证据 |
|---|---|---|---|
| `com.smartisanos.smartfolder.AdbForwardService` | `true` | action `com.smartisanos.smartfolder.AdbForwardService.FILTER` | `R/AndroidManifest.xml:26–32` |
| `com.smartisanos.smartfolder.SmartfolderMediaScannerService` | `true` | 无 | `R/AndroidManifest.xml:33–35` |

两者都 `exported=true` 且无权限保护 → **任意第三方应用可启动它们**。`SmartfolderMediaScannerService` 的 `onStartCommand` 接受 `"filepath"` extras 并拼到 SD 卡根目录后调 `MediaScanner.scanSingleFile`（`J/SmartfolderMediaScannerService.java:79–81、114`），是一个无鉴权的"任意路径触发 MediaStore 扫描"原语。

### 4.4 `application` 属性与 meta-data

| 项 | 值 | 行号 |
|---|---|---|
| `android:name` | `com.smartisanos.smartfolder.FolderApp` | `:22` |
| `android:theme` | `@style/AppTheme` | `:19` |
| `android:label` | `@string/app_name` = `HandShaker` | `:20`；`R/res/values/strings.xml:12` |
| `android:icon` | `@drawable/ic_launcher` | `:21` |
| `android:sharedUserId` | `android.uid.system` | `:23` |
| `android:debuggable` | `false` | `:24` |
| `android:allowBackup` | `true` | `:25` |
| `<meta-data android:name="AppChannel" android:value="0"/>` | 统计渠道 | `:41–43` |
| `<meta-data android:name="AppId" android:value="30"/>` | 统计 AppId（配 `com.smartisan.trackerlib.Agent`） | `:44–46`；`J/AdbForwardService.java:102–103` |

### 4.5 缺失项（值得注意）

- **没有 `<activity>` 声明**。`MainActivity`（`J/MainActivity.java:12`）不在 manifest 中，因此不可启动、不可被 `am start` 拉起。它连同 `activity_main.xml`（`R/res/layout/activity_main.xml`）都是死代码。
- 没有 `MainActivity` → 也就没有 `LAUNCHER` intent-filter，**该 APK 没有任何用户可见入口**。
- 没有 `<uses-feature>`，没有 `android.hardware.usb` 特性声明。
- 没有 `BACKUP_AGENT` / `allowBackup` 相关配置（虽然 `allowBackup=true`，但无数据规则）。
- 没有 `android:usesCleartextTraffic`（`targetSdkVersion=19`，默认允许明文）。

---

## 5. `libsmartfolder.so` native 方法

### 5.1 只有一个 native 方法

全 APK 只有**一处** `loadLibrary` 和**一处** `native` 声明：

```java
// J/utils/C.java（全文 10 行）
package com.smartisanos.smartfolder.utils;                    // :1
public class C {                                              // :4
    static { System.loadLibrary("smartfolder"); }              // :5-7
    public static native byte[] parseIoBuffer(byte[] bArr);    // :9
}
```

APK 里每个 ABI 目录都恰好只有一个 `.so`，且都叫 `libsmartfolder.so`（`R/lib/{armeabi, armeabi-v7a, arm64-v8a, mips, mips64, x86, x86_64}/`）。

### 5.2 二进制导出符号

`nm -D` 出的 JNI 入口，每个 ABI 只有一个，地址各不相同：

| ABI | 地址 | 符号 |
|---|---|---|
| `arm64-v8a` | `0x2bf0` | `Java_com_smartisanos_smartfolder_utils_C_parseIoBuffer` |
| `x86_64` | `0x2e10` | `Java_com_smartisanos_smartfolder_utils_C_parseIoBuffer` |
| `x86` | `0x2cc0` | 同上 |
| `armeabi-v7a` | `0x25e4` | 同上 |
| `armeabi` | `0x24dc` | 同上 |
| `mips` | `0x32e0` | 同上 |
| `mips64` | `0x35c0` | 同上 |

其余 24 个导出符号全是 AES/CCM 实现（`arm64-v8a` 全量）：

```
xor_buf  itiv_7  ccm_prepare_first_ctr_blk  ccm_prepare_first_format_blk
SubBytes  SubWord  kysp_1  AddRoundKey  InvSubBytes  InvShiftRows
ShiftRows  MixColumns  InvMixColumns  et_2  etcc_4  etccmc_6
etcr_8  dtcr_9  dtcm_11  etcm_10  dt_3  dtcc_5
```

判定：**这是一个自包含的 AES + CCM（SP 800-38C）实现**（tiny-aes 风格参考实现）。证据链：标准 AES 原语名齐备；`kysp_1` 是 key expansion 入口；`ccm_*` 是 NIST CCM 的 MAC 格式化；`et_/dt_/etcc_/dtcc_/etcm_/dtcm_` 是分层变换；`.rodata` 含标准 AES 正向 S-box（`x86:0x2f24` / `arm64-v8a:0x30c8` 起为 `00 01 02 …`，arm64 另有 Te0 T-table 于 `0x2ec0` = `63 7c 77 7b f2 6b 6f c5`）。`dt_3` 完全展开且含 13 次 `InvMixColumns` → AES-256 解密轮数。

### 5.3 `parseIoBuffer` 的精确行为

调用链（`D/libsmartfolder_x86_64.disasm.txt:2490–2625` 即 `parseIoBuffer` 反汇编）：

```
GetArrayLength(env, in)                                     → len
GetByteArrayElements(env, in, NULL)                         → elems      (:2515 判空)
alloca((len + 0xf) & ~0xf)  16 字节对齐的栈缓冲              → out
materialize 32 字节硬编码 AES key 到栈
materialize 16 字节硬编码 nonce/IV 到栈
kysp_1(rk, key, 0x100)                                      :2574  → 轮密钥
dtcc_5(elems, len, out, rk, 0x100, nonce)                   :2581  → 解密
NewByteArray(env, len) + SetByteArrayRegion                 :2585–2593
ReleaseByteArrayElements(env, in, elems, JNI_ABORT)        :2599
__stack_chk_guard 校验后返回                                 :2600 之后
```

**硬编码密钥与 IV**（从栈上的逐字节 `movb` 立即数重建，`:2526–2573`）：

| 项 | 长度 | 值 |
|---|---:|---|
| AES key | 32 | `28e3ee32b0de27ef6bc29792054ef9739ce8e87bb495f2ea0d72d4f4f40b3bde` |
| nonce / IV | 16 | `2b9e34d4e1d9088994939ec4e3e960c5` |

这两个值与 mac 二进制里的常量**逐字节相同**：

```
handshake_key 28e3ee32b0de27ef6bc29792054ef9739ce8e87bb495f2ea0d72d4f4f40b3bde   D/adb_transport.constants.txt:24
handshake_IV  2b9e34d4e1d9088994939ec4e3e960c5                                     D/adb_transport.constants.txt:23
```

→ 结论：**握手密钥是对称共享密钥，硬编码在两端，可被任何拿到 APK 的人提取。**

**它只做 CTR 解密，不校验 CCM MAC**。调用图证明：`dtcc_5` 只调用 `dt_3` 和 `xor_buf`（`D/libsmartfolder_x86_64.disasm.txt` 中 `dtcc_5` 体内只有这两条 `callq`），而 `ccm_prepare_first_ctr_blk` / `ccm_prepare_first_format_blk` / `ccm_format_assoc_data` / `ccm_format_payload_data` / `itiv_7` 只被 `dtcm_11`/`etcm_10` 引用，`parseIoBuffer` 从不调它们。完整性校验完全在 Java 侧（MD5，见下）。

**长度必须是 16 的倍数**：`dtcc_5` 开头 `testb $0xf, %sil; jne`（长度非 16 倍数则直接跳过主循环），而 `parseIoBuffer` **不检查** `dtcc_5` 的返回值，仍按 `len` 分配并拷贝 → 返回未初始化的栈数据。

错误路径：只打一条日志 `__android_log_print(4 /*ANDROID_LOG_INFO*/, "SmartFolder", "GetByteArrayElements Failed!")`（`:2600` 之后），然后返回**长度 1 的数组**（不是 NULL）。这两条字符串是该 `.so` 里仅有的两段可读字符串（`arm64-v8a` 的 `0x36c0` / `0x36d0`）。

### 5.4 用途推断（从 Java native 声明与调用链反推）

`parseIoBuffer` 全 APK **只有一个调用点**：`J/utils/j.java:30`。它的输入布局与用途：

```java
// J/utils/j.java:21-38（握手公钥导入）
public static synchronized PublicKey a(byte[] bArr) {          // :21
    ...
    byte[] bArrCopyOfRange = Arrays.copyOfRange(bArr, 0, 16);  // :29  ← 期望的 MD5
    byte[] bArrA = org.a.b.a.a.a(                              // :30  ← Base64 解码
        new String(C.parseIoBuffer(                            // ← NATIVE 调用
                Arrays.copyOfRange(bArr, 20, bArr.length)),    // :30  ← [20..] 密文
                StringEncodings.UTF8).trim().getBytes());
    byte[] bArrA2 = l.a(bArrA);                                // :31  ← MD5(明文)
    if (bArrA2 != null && Arrays.equals(bArrA2, bArrCopyOfRange)) {   // :32  ← 校验
        org.a.a.a.a aVar = new org.a.a.a.a(                    // :33  ← ASN.1/DER 解析
            (org.a.a.j) new org.a.a.d(new ByteArrayInputStream(bArrA)).a());
        publicKeyGeneratePublic = KeyFactory.getInstance("RSA")
            .generatePublic(new RSAPublicKeySpec(aVar.c(), aVar.d()));  // :34
        a = publicKeyGeneratePublic;                            // :35  ← 缓存
    } else { publicKeyGeneratePublic = null; }                  // :36-38
    return publicKeyGeneratePublic;
}
```

输入 blob 布局（这是传给 `j.a` 的 `F[8..]` 切片，见 `J/e/a/c.java:30`）：

| 相对偏移 | 长度 | 内容 |
|---:|---:|---|
| `0`–`15` | 16 | `MD5(Base64 解码后的 RSA 公钥)`，用于完整性校验 |
| `16`–`19` | 4 | **未被读取**（`j.a` 直接跳到 20） |
| `20`–`end` | 变长 | AES-256-CTR 密文 → 解出 Base64 文本 → 解码 → DER 公钥 |

`MD5` 实现在 `J/utils/l.java:8–17`，Base64 解码器是重命名后的 `org.a.b.a.a.a(byte[])`（`J/../org/a/b/a/a.java`），DER 解析是重命名后的 `org.a.a.*`。

结果如何被消费（说明"用途"）：

| 消费点 | 用途 |
|---|---|
| `J/e/a/c.java:24–26` | `a()` → 返回缓存的 `PublicKey` |
| `J/e/a/c.java:29–31` | `b(byte[])` → `j.a(F[8..]) != null`，判断"明文握手帧里带的公钥是否可解密/有效" |
| `J/e/a/c.java:34–41` | `c(byte[])` → `Signature.getInstance("SHA256withRSA")`，用该公钥**验签** `F[5..133)` |
| `J/b/f.java:18–25` | 握手响应：用该公钥 `RSA/ECB/PKCS1Padding` **加密**字面量 `"ok"`，Base64 后回给客户端；失败则回 `"failed"` |
| `J/d/a.java:17` | `d/a.doDecode` → `e.a.b.a(bytes)` 链路的最上游入口 |

**结论：`libsmartfolder.so` 只有一个用途 —— 握手阶段解密客户端送来的 AES-256-CTR 密文，取出其中经 Base64 + ASN.1 包装的 RSA 公钥。** 它不参与 10086/19999 的任何数据传输、不做媒体处理、不做文件操作、不做加解密以外的事。之所以把这段逻辑放进 native，是因为它是唯一能让第三方伪装成 HandShaker 客户端的入口；把 key schedule 放进 `.so` 只是增加提取成本，而密钥同时硬编码在 mac 二进制里（`D/adb_transport.constants.txt:23–24`），所以实际防护强度很低。

安全影响：拿到该密钥后可以伪造一个合法客户端，走完握手，进而调用 10086 上的 `0x01`/`0x08`（任意路径缩略图）、`0x0D`（任意路径 EXIF）、`0x0A`（任意目录监听）、`0x0B`（删除媒体）等命令。**待验证**：这些能力是否有额外的"已信任设备"门槛 —— `_trust_session.md` 提到 mac 侧有 `deviceStore.plist` 信任存储（`D/modern_transport.constants.txt`），但那是**主机侧**的，Android 侧只有 `sharedUserId=system` + 上面这一层握手。

---

## 6. 待验证清单

| # | 事项 | 现有证据 | 需要什么 |
|---:|---|---|---|
| 1 | 10086 请求/响应头部第 2、3 字节是否真的互换（请求 `[CMD][arg][ver]`，响应 `[CMD][ver][arg]`） | `J/e/a/c.java:65–77`、`J/f/a.java:5–17`、`J/b/f.java:25` | 抓包 |
| 2 | `content-range` 畸形格式（`:bytes N-M`，缺 `/total`）客户端是否容错 | `J/d/g.java:122`；mac 疑似手写解析器 `D/SmartFinderCore.strings.txt:15548–15554` | 抓包 / 用真实 mac 客户端试 |
| 3 | `FilenameFileRegion(file, channel, j, channel.size())` 在 `Range` 时是否多发 `j` 字节 | `J/d/g.java:130`；需查 `M/core/file/FilenameFileRegion.java` 构造器语义 | 读 MINA 源码或抓包比对字节数 |
| 4 | 19999 keep-alive 会话第二个请求是否真的只发体不发头 | `J/d/g.java:109–127` | 抓包 |
| 5 | mac 是否复用 HTTP 连接；`http://127.0.0.1:%d/`（`:15658`）的具体用途 | `D/SmartFinderCore.strings.txt:15658` | 反汇编对应 ObjC 方法 |
| 6 | mac 选择的 adb 本地端口算法（是否总为临时端口） | `D/SmartFinderCore.strings.txt:15591、15624–15625、15655` | 反汇编 `SFADBManager` |
| 7 | `WRITE_EXTERNAL_STORAGE` 是否在安装时即隐含读权限（本分析依赖 `targetSdkVersion=19`） | `R/AndroidManifest.xml:7、11` | 在真机 `dumpsys package` 看 granted 列表 |
| 8 | `READ_PHONE_STATE` 的实际用途 | `R/AndroidManifest.xml:13`；代码中未见调用 | 装 Smartisan 真机后跑 `adb shell dumpsys package com.smartisanos.smartfolder` |
| 9 | 实际安装的 versionCode（52 vs 63） | `R/AndroidManifest.xml:3` vs `R/assets/version.properties:3` | 真机 `adb shell dumpsys package` |
| 10 | `UsbReceiver` 是否可能收到无 extras 的 `USB_STATE` | `J/UsbReceiver.java:11` 未判空 | 检查 Smartisan ROM 的 UsbDeviceManager 发送方 |
| 11 | Smartisan ROM 私有权限 `ACCESS_ALL_DOWNLOADS` / `WRITE_MEDIA_STORAGE` 的具体授予范围 | `R/AndroidManifest.xml:12、15` | 查 ROM 源码/权限定义 |
| 12 | `dtcc_5` 长度非 16 倍数时返回未初始化栈数据是否可被利用 | 静态推断（`D/libsmartfolder_x86_64.disasm.txt`） | 构造非 16 倍数长度的握手帧实测 |
| 13 | app 是否能装在非 Smartisan 设备上 | 依赖 `ACCESS_ALL_DOWNLOADS`/`WRITE_MEDIA_STORAGE`（厂商权限）、`ro.smartisan.version`、`Build.SMARTISAN_RELEASE`（`J/e/a/a.java:35`、`J/utils/p.java:608`） | 在 AOSP 设备上试装 |

---

## 7. 快速复刻清单（给实现者的最小可用集）

要在自己的客户端里完成"下载手机上的一个文件"，只需要：

1. `adb forward tcp:<本地端口> tcp:19999`；
2. `GET http://127.0.0.1:<本地端口>/?file_path=<percent-encoded-absolute-path> HTTP/1.1`；
3. **每次下载用新的 TCP 连接**（因为 `responseFlag` 让同会话第二次请求没有响应头）；
4. 忽略 `content-range`，只信 `content-length`；
5. 续传时加 `Range: bytes=<offset>-`，期望 `206` + `content-length = 文件长 - offset`。

要拿缩略图 / EXIF / 媒体列表，就必须实现 10086 的签名二进制协议（见 §2 与 `_trust_session.md`、`_file_media.md`），19999 帮不上忙。