# SSP 文件、媒体与监听研究片段

本文是供 `PROTOCOL.md` 整合的本地源码研究记录。Android 文件简称均相对于 `handshaker_analysis/jadx_out/sources/com/smartisanos/smartfolder/`；Mac 字符串与类名位于 `handshaker_analysis/dumps/`。只从源码确认的内容标为已核实；Mac 类名/属性名只能佐证功能存在，不能证明消息数字、protobuf tag、字段顺序或当前 APK 支持程度。

## 业务判别字节与响应内容

外层解析器先交换后两个参数：`e/a/a.java:31`将 `f=type,h=第三线字节,g=第二线字节`传给请求构造器，而`b/a.java:11–14`存为`a=b,b=b3,c=b2`。因此**请求线三字节是 `[cmd,subtype,version]`**，signed subtype偏移134 / legacy偏移6；version偏移135 / legacy偏移7（`e/a/c.java:65–76`）。下面K表示请求subtype，V表示version。响应构造通常 `new Response(this.a,this.c,this.b,...)`，再由 `f/a.java:9–16`输出 `[cmd,version,subtype]`；下面响应payload偏移均是公共三字节之后的相对偏移。

普通文本响应没有字符串长度前缀，直接使用UTF-8输出直至帧尾（`f/h.java:26–39`，charset=`c/b.java:8`）。`NEW_FETCH`响应先UTF-8编码再gzip压缩（`f/i.java:5–6`、`f/h.java:31–35`、`utils/i.java:87–99`）。`FETCH`文本不压缩（`f/d.java:5–6`）。通知也采用未压缩文本（构造调用 `c/g.java:75`、`utils/m.java:186` 没有启用gzip）。

## 1. 文件传输与目录操作：必须区分两代协议

### 1.1 当前APK实际提供的HTTP文件读取

已核实另走HTTP的服务：`d/d.java:15–23`建立TCP 19999、安装 `HttpServerCodec`，handler=`d/g.java`。主守护端口10086同时启动这个服务（`d.java:14、20–28`）。

可用请求形式：

```http
GET /?file_path=%2Fstorage%2Femulated%2F0%2FMusic%2Fexample.mp3 HTTP/1.1
Host: PHONE:19999
Range: bytes=1048576-
```

路径与方法的精确行为：handler不检查method，不检查URL path，只检查query。`file_path`通过正则`file_path=([^*]*)`提取，再以UTF-8执行 `URLDecoder.decode`，作为`new File`的**绝对/原样文件路径**（`d/g.java:82–94`）。正则会吞掉`&`之后内容，故Dart应只发送一个参数；使用标准application/x-www-form-urlencoded编码，字面`+`必须编码为`%2B`。path为空、文件不存在会返回404（`d/g.java:44–55、84–94`）。

HTTP Range不是完备RFC实现。读取header名称`range`；正则接受`bytes=N-M`及逗号列表，但仅按`-`分割并取第一段作为起始偏移N，**忽略结束位置**。非匹配Range回退0；suffix range `bytes=-N`可能触发 `Long.parseLong("")` 异常，逗号多个range也不能可靠处理（`d/g.java:96–108`）。应只用`bytes=N-`。N=0或无Range返回200，`content-length=file.length()`；N>0返回206，`content-length=file.length()-N`，源码生成非标准 `content-range: :bytes N-file.length()`，没有斜杠total，结束偏移也不是length-1（`d/g.java:111–127`）。客户端不应依赖此header格式，应以已知文件长度和起始偏移校验。

数据由`FileInputStream.getChannel()`及`FilenameFileRegion(file, channel, N, channel.size())`直接发送，没有SSP分块帧，也没有在handler做gzip、MD5校验或签名验证（`d/g.java:129–133`）。注意第四参数传入**整文件size**而非`size-N`，实际MINA EOF/region发送行为在断点下载时**待验证**。一次连接使用responseFlag只写一次header，虽然header声称keep-alive，后续不同请求不会重写header（`d/g.java:109–110、127`），重实现每次读取宜建立新连接。

探活：query以`test`开头时，将query.substring(5)的UTF-8数据做MD5，返回200及16字节**原始摘要**后关闭连接（`d/g.java:67–80`）。例如 `/?test=123`返回MD5("123")原始16字节。

Mac可直接交叉验证：`SmartFinderCore.strings.txt:15654–15661`有ADB转发`tcp:19999`、`http://127.0.0.1:%lu/?test=123`和`http://127.0.0.1:%lu/?file_path=%@`；10086转发见`:15621–15625`。它支持Mac通过ADB转发读取该HTTP服务的判断，但Wi-Fi是否采用同一个URL构造仍**待验证**。

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

### 1.2 上传、SSPFileTransferObject和大文件分块

当前APK的 `b/*.java`、`e/a/a/a.java`操作表中没有SSP上传/下载/文件存在/目录浏览/创建/重命名/剪贴板请求；源码中没有对应`FileOutputStream`、`RandomAccessFile`、`mkdir`、`renameTo`实现。不能给这些功能编造type或二进制布局。

Mac确实包含 `SSPUploadFileRequest`/`ResponseHeader`、`SSPDownloadFileRequest`/`ResponseHeader`、`SSPFileTransferObject`、`SSPDataRange`（`ssp_classes.txt:69、76–90、159–162`）。`SmartFinderCore.strings.txt:16507`显示`SmartSyncProtocol.pbobjc.m`，随后`:16578–16581`出现`offset/hasOffset/length/hasLength`，`:16701–16714`出现`SSPDataRange/range/hasRange/needMd5/gzip/dataMd5/ready/canceled`。这些是另一套protobuf生成类的明确证据。没有descriptor/实际序列化代码时，所有tag、wire type、取值枚举、字段归属和顺序均**待验证**。

Mac上传操作有`ready`、`offsetInFile`、`readDataOfLength:`、`transferedSize/header/bodySize`属性/selector（`SmartFinderCore.strings.txt:14514–14527`），日志有`UploadFileRequest_start,path=%@, fileSize=%ld`、`UploadFileRequest_end,path=%@, off=%ld`（`:16247–16258`）；下载操作有MD5完成核对日志（`:16432–16438`）。这支持“先请求并等ready，随后发送文件数据，记录已传偏移，下载完成检查MD5”的**推断**；不证明数据块包含offset字段，更不证明块size或最大frame。`offsetInFile`还可能只是本地NSFileHandle游标。Dart零起实现SSP原生上传/分块需要补充抓包或Mac ObjC反汇编/另一版本APK，不可用当前APK套出布局。

尚未验证的现代SSP文字序列（只能作为调查清单）：

```text
电脑 -> 手机: SSPUploadFileRequest(文件对象、range、MD5?, gzip?) [字段归属/数字待验证]
手机 -> 电脑: SSPUploadFileResponseHeader(ready?) [待验证]
电脑 -> 手机: SSPFileTransferObject/raw data块? [分块帧、offset、校验覆盖范围待验证]
手机 -> 电脑: SSPUploadFileResponse(succeed?) [待验证]

电脑 -> 手机: SSPDownloadFileRequest(file、range、needMd5?) [待验证]
手机 -> 电脑: SSPDownloadFileResponseHeader + 文件块? [待验证]
电脑: MD5核对 [Mac日志有证据，算法传输参数待验证]
```

### 1.3 ADB后备路径与目录功能

Mac字符串明确包含ADB `push`（`:15694`）、`ls -a "%@"`（`:15696`）、`ls -al "%@" %@`与结果正则（`:15708–15710`）、`echo $EXTERNAL_STORAGE`（`:15711`）、`mkdir`/`mkdir -p "%@"`及createFolder shell日志（`:15687–15691`）、renameFile shell日志（`:15685`）、rm -rf失败日志（`:15678`）。可以确认Mac有ADB文件管理路径；是否当前APK配套Mac默认选用该路径、何时fallback，**待验证**。

现代Mac相应类存在：目录浏览`SSPGetDirFilesRequest/Response`（`ssp_classes.txt:101–103`），创建`SSPCreateFolderRequest/Response`（`:66–68`），重命名`SSPRenameFileRequest/Response`（`:145–147`），删除`SSPDeleteFileRequest/Response`（`:73–75`），文件存在`:85–87`。这些类的请求type、protobuf tag、目录结果JSON schema **均待验证**。Mac selector与字符串`dir/maxdepth/exclusionPatternArray/filesArray/isFirst`（`SmartFinderCore.strings.txt:14455–14461、16667–16677、16759–16762`）不足以把它们绑定为固定二进制顺序。

文字序列：浏览`电脑 -> SSPGetDirFilesRequest(dir) -> 手机 -> response(files)`；创建`CreateFolder(path) -> succeed/error`；重命名`RenameFile(source,target) -> succeed/error`；删除`DeleteFile(file,isTrash?) -> succeed/error`，这些**现代SSP序列均待验证**。当前APK可用ADB shell/ADB sync实现对应功能；那是ADB协议而非当前已核实SSP线格式。

## 2. 媒体查询与JSON布局（当前APK已核实）

### 2.1 FETCH type=2

payload允许为空；有剩余数据则读取4字节大端signed int `groupId`，否则取0（`e/a/a/p.java:8–9`）。K映射由`b/d.java:25–61`确认：

| K | 语义 | p.java查询源/选择条件 |
|---:|---|---|
| 1 | 音轨列表；groupId>0按album_id过滤，否则全部 | :134–147，audio external；按title_key排序 |
| 2 | 音频专辑列表 | :122–126，audio albums external；按album_key排序 |
| 3 | 不支持 | b/d.java:32–34，抛a/c异常 |
| 4 | 音频所在目录分组代表行 | :292–296，Files external，bucket_display_name非空/is_music=1/GROUP BY bucket_id |
| 5 | 图片相册分组代表行 | :342–346，Images external，GROUP BY bucket_id |
| 6 | 视频相册分组代表行 | :370–374，Video external，GROUP BY bucket_id |
| 7 | 某bucket下文件列表 | :304–308，Files external，bucket_id=groupId |
| 8 | 某bucket下图片 | :354–358，Images external，bucket_id=groupId |
| 9 | 某bucket下视频 | :382–386，Video external，bucket_id=groupId |
| 10 | 缓存全部图片 | :416–419 |
| 11 | 缓存全部视频 | :436–439 |
| 12 | Android DownloadManager完成下载列表 | :447–451、621–622，status=8 |

响应为UTF-8 JSON，根一般为记录数组，没有长度前缀（`f/d.java`/`f/h.java`）。没有记录时`p.a(Cursor)`返回null，结果只含3字节公共响应头，**不是固定空数组**（`utils/p.java:155–159`）。取消后抛a/e（`b/d.java:63–66`）。

序列：电脑发送`type=2,V=version,K=5,payload=[groupId可省略]` -> 手机返回相册代表记录数组 -> 电脑读取每条bucket_id -> 对选中bucket发送`type=2,K=8,int32(bucket_id)` -> 手机返回图片记录数组 -> 电脑以 `_id`请求thumbnail(type8)，以`_data`从HTTP下载原图。

### 2.2 NEW_FETCH type=7

请求payload为空（`e/a/a/u.java:8–9`）；K=1图片，2音频，3视频（`b/i.java:21–29`）。对应`p.k/l/m()`，分别按bucket_id/album_id/bucket_id分组（`utils/p.java:459–468`）。响应gzip UTF-8 JSON，无gzip长度前缀；未知K返回空字符串结果（`b/i.java:19–35`）。

根结构源码构造为：

```json
{
  "all_item": ["所有记录对象"],
  "all_group": ["每组第一条记录对象（不是单独album对象）"],
  "item_with_group": [{"id": "bucket_id或album_id的原类型", "list": "该组记录集合"}]
}
```

`all_item/all_group`明确定义为JSONArray（`utils/p.java:195–224`）。`item_with_group`外层是JSONArray，但`list`是直接`JSONObject.put("list", ArrayList<JSONObject>)`，未显式转换为JSONArray（`:252–260`），该设备Android `org.json`把它序列化成真正数组还是带JSON内容的字符串**待验证**。Dart解析器可先容忍List或JSON字符串两种形式，抓包后锁定。分组遍历HashMap无固定顺序，不能按响应次序假设album排序（`:254`）。

序列：电脑`type7,K1/2/3` -> 手机查询provider并group -> 手机响应3字节头+gzip数据 -> 电脑解gzip、UTF-8解码、JSON解析 -> 用all_item填充库、all_group生成相册列表、item_with_group建立关系。

### 2.3 完整可证明的记录schema边界

JSON serializer输出cursor的**全部列名**，但忽略空列名及以`key`结尾的列（`utils/p.java:162–183、203–206`）。整数为Java long，浮点为float，文本为String，blob直接放byte[]；null使用put(key,null)，字段可能删除而不是显式JSON null（`:166–180`）。因此默认projection=null的图片/视频/下载查询**没有APK固定的完整字段schema**；必须以运行时provider返回列为准。不能把常见MediaStore列列表宣称为源码已确认的强制字段。常见`_id,_data,_display_name,_size,bucket_id,bucket_display_name,mime_type,date_added,date_modified,width,height,orientation,datetaken`是否存在、类型、扩展厂商字段都**待验证**；这些名称只应作为Dart宽松映射候选。

音频查询多数指定`utils/m.java:32`projection，完整已核实输出列为：

```text
_id, title, album, _display_name, artist, _data, album_id, artist_id,
date_added, date_modified, mime_type, duration, year,
is_alarm, is_music, is_podcast, is_notification, is_ringtone,
_size, track, genre_id
```

其中track通过`CASE track WHEN 0 THEN 2147483647 ELSE track END AS track`替换0；genre_id通过audio_genres_map子查询。实际每列SQLite值类型仍由cursor决定；可为null而省略。分组音频(K=2, NEW_FETCH)及缓存音频使用隐藏目录过滤、音乐筛选（`utils/p.java:35、366–409、427–429、463–464`）。规则：Ringtones目录始终可见；其余要求is_music或is_podcast，并位于smartisan/music/cloud或Music或size>800000或mime_type=audio/x-smartisanos-cua，排除ogg/3gp/ac3；厂商hide_dir bucket_id排除。图片隐藏相册根据`content://smartisanos_gallery/bucket` status=2过滤（`:29、412–413、625–635`）。

注意K=2旧音频专辑查询使用`m.a`同一音轨projection去查询Albums（`utils/p.java:125`）；源码另外声明albums字段表`_id,album,album_art,artist,numsongs,minyear,album_key,maxyear`（`:38`），但该表未被该查询使用。这可能是反编译或原代码兼容缺陷，专辑实际返回列/是否抛异常**待验证**，不要按未使用数组规定线schema。

Dart应以`Map<String,dynamic>`保留未知provider字段，以int保存Java long（不要转double），字符串按UTF-8解码。源排序、隐藏策略属于手机语义，电脑不应自行“补齐”不可见数据。

## 3. 缩略图

### 3.1 OLD_THUMBNAIL type=1，按路径

请求payload：relative 0 int32 count；随后每项int32 UTF-8字节长度+路径字节（`e/a/a/v.java:10–17`实际使用默认Java charset，Android通常UTF-8，编码**待验证**）。K=1图片/2视频/3音频封面（`b/j.java:81–131`）。图片缩放为200x200，EXIF方向3/6/8分别旋转180/90/270，JPEG质量86（`b/j.java:52–73`）；视频读取frameAtTime(-1)，音频读取embeddedPicture。响应payload：

| 相对偏移 | 类型 | 含义 | 证据 |
|---|---|---|---|
| 0 | int32 BE | 结果count | f/j.java:23 |
| 游标q | u8 | status 0有图，1失败 | :27–35 |
| q+1 | int32 BE | pathByteLength P | :36 |
| q+5 | bytes[P] | path，默认charset | :25、37 |
| q+5+P | int32 BE | jpegByteLength J | :38 |
| q+9+P | bytes[J] | JPEG（J=0时无） | :39–40 |

下一项q+=9+P+J。输出迭代Map，顺序未保证（`f/j.java:24`），必须按path匹配。

### 3.2 THUMBNAIL type=8，按media ID

请求payload：relative 0 int32 BE count；每项int64 BE mediaId（`e/a/a/y.java:10–15`）。K=1图片 `_id`、2视频 `_id`、3音频**albumId**（`b/m.java:26、62–73`），音频用`content://media/external/audio/albumart/<id>`；图片/视频MINI_KIND(1)。JPEG质量86（`:79–82`）。响应payload：

| 相对偏移 | 类型 | 含义 | 证据 |
|---|---|---|---|
| 0 | int32 BE | count | f/m.java:24 |
| 游标q | u8 | status 0成功、1失败 | :27–35 |
| q+1 | int64 BE | mediaId / albumId | :36 |
| q+9 | int32 BE | JPEG length J | :37 |
| q+13 | bytes[J] | JPEG | :38–40 |

下一项q+=13+J，结果顺序未保证（`f/m.java:25`）。10线程处理，最多等待20秒（`b/m.java:27、122–126`）；cancel将Future.cancel(true)（`:138–143`）。**待验证反编译异常**：`b/m.java:95–98`finally无条件把结果覆盖为0字节，与前面成功分支`:87–90`冲突，应检查smali或抓包确认；线格式可以确定，但不能保证该APK缩略图必然成功。

序列：媒体列表 -> 电脑`type8,K1,count,ids` -> 手机查MediaStore并JPEG编码 -> 响应count与各id/status/JPEG -> 电脑以id关联缓存，失败status仅影响对应条目。

## 4. 删除媒体记录与扫描新文件

`DELETE type11`请求payload=int32 BE count+count个int64 BE ID（`e/a/a/n.java:10–15`），手机对`content://media/external/object`（失败则Files URI）执行 `_id IN (...)` delete；成功只意味着影响行数>0，**不逐项报告状态**（`utils/p.java:264–289`，`b/b.java:19–23`）。响应payload偏移0一个u8，1成功，0失败（`f/b.java:19–20`）。空ID数组会selection=null，原代码可能删除全部provider记录（`:273–274、289`）；客户端禁止发空删除列表。它是基于MediaStore ID的删除，不等价于Mac SSPDeleteFile的路径/垃圾箱协议。

`SCEN type12`实际是媒体扫描路径（不是场景）：payload=int32 count+每项int32路径长度+路径字节（`e/a/a/w.java:12–22`）。手机给每路径启动`SmartfolderMediaScannerService`，立即返回ASCII `Y`，只代表扫描任务已提交（`b/k.java:20–29`），不能等同于完成入库。结果编码无长度前缀（`f/k.java:19–20`）。

文字序列：电脑经ADB或尚未验证的SSP上传写文件 -> `type12,路径列表` -> 手机启动扫描服务 -> 响应Y -> MediaStore完成更新 -> 手机媒体增量通知 -> 电脑更新库。

## 5. MonitorFolder / WatchCallback 当前APK实现

`WATCH type10`payload=int32 count，循环int32字节长度+路径字符串；空列表解析返回null（`e/a/a/z.java:12–22`）。K=1注册，其余K注销（`b/n.java:21–31`）。EventManager尚未初始化时响应ASCII N；注册完成响应Y（`:18–19、33`；`f/n.java:19–20`）。watch路径若是MediaStore三种external content URI，构造ContentObserver，其他构造FileObserver（`utils/r.java:18–28`）。

文件路径观察实际上监控`externalStorageAbsolutePath + suppliedPath`（`utils/h.java:10、34–36`），所以当前APK普通目录watch须发送相对存储根的`/DCIM`之类路径，而HTTP下载须绝对路径。不能混用。FileObserver mask=4040=0xFC8；event剥去高16位，回传path=suppliedPath+"/"+name（name为null时回传suppliedPath）（`:18、27–30`）。它不是递归子树观察，源码只对给定目录创建一个FileObserver。

通知使用公共3字节`[9,2,1]`，内容UTF-8 JSON单键对象，value是观察路径/子路径（`c/g.java:26–33、75`）：

| event数值 | JSON键 | 源码 |
|---:|---|---|
| 8 | CLOSE_WRITE | c/g.java:51–52 |
| 64 | MOVED_FROM | :53–54 |
| 128 | MOVED_TO | :55–56 |
| 256 | CREATE | :57–58 |
| 512 | DELETE | :59–60 |
| 1024 | DELETE_SELF | :61–62 |
| 2048 | MOVE_SELF | :63–64 |
| 其他(如0) | UPDATE | :65–66 |

示例`{"CLOSE_WRITE":"/DCIM/new.jpg"}`。rename是两个独立MOVED_FROM/MOVED_TO事件，没有cookie/配对字段。注销停止FileObserver并删除watch map（`c/g.java:79–91`）。Mac存在`SSPMonitorFolderRequest/ResponseHeader/Response`、`SSPWatchCallbackItem`（`ssp_classes.txt:132–135、166`），与此功能相关，但不能等同当前JSON结构或强行填其protobuf字段。

普通MediaStore `utils/d.java`的onChange会发UPDATE URI（`:24–26`），但`startWatching/stopWatching`实现为空（`:39–45`），没有注册ContentObserver代码，故通过type10对content URI观察是否会真的收到回调**待验证**。

另一路全局媒体增量通知更明确：`utils/m.java:48–61`注册content://media/external、厂商隐藏目录/隐藏相册observer，合并200ms变化；比较新旧cursor，输出added/deleted，视频另可能updated（`:132–186`）。公共通知头`[9,3,1]`，body未压缩UTF-8 JSON，schema：

```json
{
 "IMAGE":{"added":[],"deleted":[]},
 "VIDEO":{"added":[],"deleted":[],"updated":[]},
 "AUDIO":{"added":[],"deleted":[]}
}
```

VIDEO.updated键仅在相关变化时出现（`:147–149`）；各数组记录是provider columns转换的同类对象（`:240–255`）。added/deleted仅保留_size>0的记录（`:118–129`）。字典键使用enum名字IMAGE/VIDEO/AUDIO（`:181–183`）。

所有通知发送到EventManager记录的一个会话id，经session pool找到IoSession.write，**没有携带订阅request的标识，也没有广播全部session**（`c/c.java:33–35、48–58`）。类别订阅列表虽被维护，但发送时不检查类别是否在列表中（`:54–58`），电脑必须对type9异步消息随时分发。

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

## 6. 剪贴板：只有Mac证据，当前APK没有处理逻辑

Mac类名支持读、写、单条删除、全部清空、变化通知：`SSPGetClipboardRequest/Response`（`ssp_classes.txt:95–97`），`SSPPostClipboardRequest/Response`（`:141–143`），`SSPDeleteClipboardRequest/Response`（`:70–72`），`SSPClearClipboardRequest/Response`（`:61–63`），`SSPClipboard/SSPClipboardChange`（`:64–65`）。`SmartFinderCore.strings.txt:16422–16426`显示SFClipboard.content为NSData、mstimestamp为int64；protobuf属性content/mstimestamp、clipboardArray、clipboard出现`:16748–16755`。

不能由这些名称得出content是UTF-8文本还是任意data、timestamp毫秒定义、记录ID、排序、最大长度、通知注册条件、请求type或protobuf tag。所有均**待验证**。当前APK没有android ClipboardManager或对应请求；为兼容当前手机端不能启用尚未核实的SSP剪贴板消息。

待验证文字序列：电脑`GetClipboardRequest` -> 手机`GetClipboardResponse(clipboardArray)`；电脑`PostClipboardRequest(clipboard)` -> 手机`PostClipboardResponse` -> `SSPClipboardChange`通知；单条删除与清空各请求 -> 响应。它们是Mac功能名支持的调查方向，不是可实现的现成wire spec。

## 主要第一手来源

- Android请求业务实现：`b/d.java`、`b/i.java`、`b/m.java`、`b/j.java`、`b/n.java`、`b/k.java`、`b/b.java`。
- Android解析/序列化：`e/a/a/{n,p,u,v,w,y,z}.java`、`f/{a,b,d,h,i,j,k,m,n}.java`。
- Android HTTP服务：`d/d.java`、`d/g.java`，媒体provider及JSON：`utils/p.java`、`utils/m.java`，文件监听：`utils/h.java`、`utils/r.java`、`c/g.java`、`c/c.java`。
- Mac本地二进制提取结果：`dumps/ssp_classes.txt`、`dumps/SmartFinderCore.strings.txt`。类名和字符串仅证明符号存在及语义线索；它们不能取代protobuf descriptor、反汇编或线上抓包。
