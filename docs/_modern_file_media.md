# 现代Mac SSP 文件流与功能语义（汇编核实）

本文补充 `_file_media.md` 中只依据Mac类名而标“待验证”的内容。第一手证据从SmartFinderCore x86_64 Mach-O的ObjC反汇编提取保存到 `handshaker_analysis/dumps/modern_file_media.disasm.txt`（下简称 **M**），每个方法前有original_disasm_lines，可回溯原 `/tmp/handshaker_core_disasm.txt`；地址原样保留。立即数/CFString另保存在 `modern_file_media.constants.txt`（下简称 **C**）。现代SSP使用protobuf；准确tag/type交由descriptor还原章节，不把它和APK的 `[cmd,subtype,version]` 自定义JSON消息混为一种。

## 1. 已核实的传输边界与分块

`SSPFileTransferObject`在Mac中是本地对象，只有`file`和`hostPath`属性及其getter/setter（M:9460–9520，以`-[SSPFileTransferObject file]`标签定位；汇编地址0xb3460–0xb353c）。实际分块路径**不把SSPFileTransferObject序列化为protobuf块**：writeThreadMain直接调用上传操作`readFileDataWithSize:hasMoreData:`，该函数返回`NSFileHandle.readDataOfLength(size)`的NSData，随后发给`device.sendFileData(data,sessionId,error)`（M:10860–10899；地址0x43a3a–0x43b1a）。

现代请求包 `sendRequestData`先计算签名并拼到protobuf前，送入`sendData`时flag=1；文件块 `sendFileData`直接送入相同函数、flag=3，无签名，没有块内offset/count/protobuf字段（M:14147附近，地址0x92940–0x929ba；M:5057–5070，地址0x927db–0x92802）。这里的flag=3是现代传输层标记，不是旧APK的type=3 GET。现代外层帧的sessionId/flag/长度布局见主文档帧章节。

USB与Wi-Fi `maxDataPackageSize()`均返回`0x3ff7=16375`（M:823、1557）。writeThreadMain按此大小读文件，尾块为剩余字节。因此这份Mac客户端的文件数据payload通常<=16375；没有证据表明手机必须强制同样大小，重实现可先遵循该数值。文件块使用**同一个请求sessionId**，顺序写入，文件游标只在发送侧的NSFileHandle中记录；断点续传由请求中的range表达，不是逐块offset。

普通现代响应/文件ResponseHeader还有内层8字节BE长度：`SSPRequestOperation.appendData`从lenData取[0,8)，`CFSwapInt64BigToHost`得到protobuf长度N，累积N字节后完成（M:2003；地址0x7e7bb–0x7e8bd）。上传/下载特化header parser也先取8字节、BE转为dataLength，然后把剩余内容交给相应ResponseHeader protobuf（M:4234、4334，地址0x904ae–0x907bb；M:7140、7240附近，地址0xa81f6–0xa8554）。

```text
响应头的逻辑流：
 relative 0 .. 7     uint64 BE N（protobuf字节数）
 relative 8 .. 8+N-1 ResponseHeader protobuf
 后续传输payload    文件原始字节（按外层session路由的不同块）
```

它是**逻辑流**的结构，不能假设每个TCP read或USB bulk read等于一个header/块。普通operation lenData能积攒不足8字节，文件特化parser则源码未见不足8字节保护；Dart应正确缓冲拆包，不能复制该薄弱点。文件header与body被客户端不同阶段解释，服务端若将它们拼在同一次operation.appendData参数中，现有Mac parser是否正确分割**待验证**；兼容服务端宜确保header逻辑payload精确结束于8+N，再发body数据帧。

## 2. 原生SSP上传流程（已核实Mac发送行为）

上传构造器先确认源文件存在且为普通文件，打开NSFileHandle（M:3541开始，地址0x8fa3e–0x8fb8c）。它构造：

- `SSPUploadFileRequest.type = operation.type`。
- `file.path = 目标路径`，`file.fileSize = 本地文件size`，`file.modifiedTimestamp/createdTimestamp = Unix epoch秒整数`；这里timeIntervalSince1970转换为整数后设置，没有乘1000（M:3711–3810；0x8fca0–0x8fe12）。
- `file.isDirectory = false`；`file.checksum = getMD5WithFilePath(本地源)`（M:3832附近；0x8fe43–0x8febe）。
- `request.file = file`，`request.dataMd5 = ""`，`request.isSync = 入参`（M:3840–3865；0x8feec–0x8ff31）。空字符串通过CFString对象地址0x2ae958直接解码确认（C:3）。因此不要误把上传dataMd5宣称为当前Mac实际传完整文件MD5；它在file.checksum。
- `bodySize = file.fileSize`，进度回调保存于operation（0x8ff57–0x8ff97）。当前构造器未设置request.range或gzip；完整上传从NSFileHandle offset0开始。

writeThreadMain首先发送请求一次，将didSendRequestData置true（0x436d1–0x43923）。收到 `8-byte N + SSPUploadFileResponseHeader` 后读ready：ready=false先markCancel并转换errorCode后结束；ready=true设置isReadyToUploadFileData=true（M:4401、4572；0x908a2–0x90bf4）。errorCode至少显式识别5、6、8、9、10；具体枚举由schema章节解释，不根据Mac NSError数字强行猜。

ready=true后，writeThreadMain持续读取<=16375原始字节，并调用sendFileData同sessionId、flag3（M:10860–10899）。`readFileDataWithSize`以NSFileHandle offsetInFile与request.file.fileSize比较，设置hasMoreData=false/true；没有range-offset字段嵌在每块（M:4707–4747；0x90e2b–0x90eee）。

**完成语义非常关键**：发送尾块后writeThreadMain调用markSent（M:11048），上传operation覆写markSent后直接`callFinishBlockWithError:nil`（M:4126–4134；0x90341–0x90358）。该Mac实现的成功回调代表“全部文件数据已送出”，没有等待 `SSPUploadFileResponse` 的明确最终确认；class存在不能证明该路径消费它。手机落盘/MD5成功的最终ack是否另有路径**待验证**。Dart重实现若目标是准确复刻Mac，应区分本地发送完成与服务器确认完成。

```text
电脑 -> 手机: flag1/session S，签名 + SSPUploadFileRequest protobuf
手机 -> 电脑: session S，8字节BE N + SSPUploadFileResponseHeader
电脑: 等ready；false则cancel/error；true才开始发送文件
电脑 -> 手机: flag3/session S，原始文件字节块0（<=16375）
电脑 -> 手机: flag3/session S，原始文件字节块1 ... 尾块
电脑: EOF -> markSent -> 本地成功callback、closeFile
[手机最终确认/落盘/校验通知：本路径未消费，待验证]
```

## 3. 原生SSP下载流程（已核实Mac接收行为）

构造 `SSPDownloadFileRequest`：file.path=远端路径；建立SSPDataRange并设offset=0、length=0；needMd5初始false并写入请求；isSync来自入参（M:5577、5648、5663；0xa641a–0xa663b）。length=0用于此客户端的完整文件下载请求，但服务端把0解释成“到EOF”的逻辑需另一端证据验证。

本地缓冲文件附加`.hsdownload`扩展（字符串`SmartFinderCore.strings.txt:16432`，调用0xa664b–0xa6677），创建父目录、删除既有buffer文件，再从头建立新文件供写入（M:5730附近，0xa66b4–0xa689e）；此构造路径不是续传已有buffer。

收到header前，accumulate `8-byte BE N + SSPDownloadFileResponseHeader`；ready=false读errorCode，至少errorCode9特殊转换后cancel/finish；ready=true且header.file.fileSize=0则立即完成（M:7140、7298–7360；0xa82a7–0xa875d）。其他情况进入data阶段。

header存在时每个后续appendData参数都直接 `fileHandle.writeData(data)`，transferedSize += data.length（M:6674–6692；0xa78da–0xa7907）。bodySize取header.range.length，而不是请求原先的0；transferedSize达到header.range.length即完成（M:6863；0xa7bff–0xa7ce4）。这说明**响应range.length必须是实际期望接收数据长度**，不能让Dart根据每块自行推断总长。range.offset未用于这个完整下载路径seek，本地是从0顺序写入。

若_needMd5=true：MD5_Init -> 每块MD5_Update -> 达到总长后MD5_Final，编码为32个hex字符，与header.dataMd5作case-insensitive比较（M:6734、7004；0xa6d46–0xa6d6e、0xa79b5–0xa7a29、0xa7d13–0xa7fdc）。不匹配报NSError code0x26（0xa807e）。但默认needMd5=false，不能说此Mac客户端每次下载一定校验MD5。

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

## 4. 现代目录与文件操作：调用链已核实

这些功能可用protobuf descriptor给出的消息编码实现，不需要套用旧APK JSON：

| 操作 | Mac实际构造语义 | 第一手证据 M行号/地址 |
|---|---|---|
| 普通目录浏览 | SSPGetDirFilesRequest.dir=SSPFile(path,isDirectory=true)，maxdepth=1 | M:7619附近，0xb136e–0xb13d5 |
| 下载目录递归列举 | 同上，maxdepth=4294967295=0xffffffff（uint32；wire varint为 ff ff ff ff 0f，共5字节） | M:8602附近，0xb24ee–0xb2542 |
| 目录响应 | SSPGetDirFilesResponse.initWithData，遍历fileArray；isDirectory转SFDirectoryFile，否则按fileForSSPFile转换 | M:7812–8150，0xb1735–0xb1de0；递归版0xb2809–0xb2be4 |
| 创建文件夹 | SSPCreateFolderRequest.file=SSPFile(path=入参目录对象.path)；解析SSPCreateFolderResponse | M:927附近，0x6a06b–0x6a0cb，response block随后 |
| 重命名 | sourceFile.path=旧路径；targetFile.path=删除旧末级路径后拼入新名字；解析SSPRenameFileResponse.succeed等 | M:140附近，0x7aa6–0x7c06 |
| 删除 | SSPDeleteFileRequest.file.path=入参路径，同时设isSync和isTrash；解析SSPDeleteFileResponse | M:2352附近，0x8e50e–0x8e55b |

文字序列：普通浏览发dir/maxdepth1 -> 响应fileArray -> 按isDirectory展示；进入子目录再次发其路径。递归上传/下载前可发maxdepth=0xffffffff进行分析。创建/重命名/删除每次发对应protobuf并等待succeed/error。是否执行物理删除、垃圾箱目录、权限检查由手机现代实现决定；isTrash=false/true的服务端具体落盘行为**待验证**，不可用Mac调用参数推定目录。

## 5. 现代剪贴板已经确认的编码与时间戳

`SFClipboard.setStringContent`按NSUTF8StringEncoding=4将文本转NSData，再`gzipDeflate`，存content；stringContent反向gzipInflate再UTF-8（M:14546、14556、14601、14618；0xa1c17–0xa1c64、0xa1cc4–0xa1d2c）。所以SSPClipboard.content用于文本时是**gzip压缩的UTF-8字节**，不是直接UTF-8或base64字符串。

- 获取：SSPGetClipboardRequest仅设置type；收到SSPGetClipboardResponse后遍历clipboardArray，逐条构造SFClipboard（M:3127–3170；0x8f29e–0x8f381）。
- 发布：SSPPostClipboardRequest.clipboard=新SSPClipboard；content直接复制传入SFClipboard.content（M:5185；0xa360b–0xa3637）。mstimestamp由当前NSDate.timeIntervalSince1970先`NSNumber.longLongValue`取整秒，再乘double1000.0后设置（M:5224附近；0xa36ec–0xa372c，C:2）。因此该Mac发布消息实际为**epoch毫秒但精度1秒**，Dart可复刻 `secondsSinceEpoch.floor()*1000`；不要先乘1000再floor而声称逐字节一致。
- 单条删除：SSPDeleteClipboardRequest.clipboard.content与mstimestamp均从目标SFClipboard复制（M:9664–9675；0xc5995–0xc5a2c）；没有看到另设ID，记录定位至少包含这两个字段。
- 清空：SSPClearClipboardRequest只设置type；回调解析SSPClearClipboardResponse.succeed（M:1565–1780；0x7c4c0–0x7c7de）。Post/Delete响应也解析succeed；各准确tags见schema。

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

## 6. 现代MonitorFolder

`SSPMonitorFolderRequestOperation`建立file.path，去掉末尾`/`，设置request.file，`register_p=true/false`由入参isRegister决定（M:14738–14931；0x8009f–0x8028d）；响应回调将数据按SSPMonitorFolderResponseHeader解析，再返回本地SSPWatchCallbackItem(path)（M:15045–15100；0x80477–0x8056e）。这个WatchCallbackItem是本地callback模型，不能凭名字宣称为线上protobuf或套用APK type9 JSON。

线上结构（`ssp_descriptors.raw.txt:253–263`）：Request `type#1=23,file#2:SSPFile,register_p#3:bool`；ResponseHeader `type#1=24,succeed#2:bool,errorMessage#3:string`；后续push Response `type#1=25,eventArray#2:SSPFileEvent[]`。每个event含`file#1:SSPFile,event#2:SSPFileEventType`（同文件:95–97）；event值为1Create、2Delete、3CloseWrite、4MovedFrom、5MovedTo、6DeleteSelf、7MoveSelf、8DirChanged（同文件:441–449），**不是旧APK FileObserver位掩码**。

文字序列：电脑 -> MonitorFolderRequest(file.path,register_p=true) -> 手机 -> MonitorFolderResponseHeader(succeed/errorMessage)；Mac将path与observerCallbacks建立关联；手机随后独立push MonitorFolderResponse(eventArray)；注销发送同path register_p=false并等待Header。Mac push路由确实解析type25，但只取`eventArray.firstObject`，再读event.file.path，按路径前缀和event值路由本地watchCallbackItems（M:12345–12375、12400–12422、12694；0x634fd–0x635a3、0x6363a–0x636ae、0x63c88）。schema允许一帧多个event，Dart应遍历整个数组；Mac只取首项不能证明手机必发单事件。监听是否递归、路径前缀边界、目录变更合并策略均**现代手机效果待验证**。

## 实现边界

汇编确认的是**Mac客户端预期和发送行为**；当前APK不包含现代protobuf守护服务，不能验证现代手机端是否允许range>0、非默认gzip、最终上传ack、异常恢复等。文档应同时给出两套格式的已核实范围，不让“Dart从零实现”误以为当前APK支持现代SSP所有消息。实际互通还需：针对目标手机端版本抓包；验证ResponseHeader和body拆分；验证大文件>4GiB、空文件、失连取消；验证同session多块顺序及range续传。


## 7. 现代媒体库、缩略图与变化通知

本节的 **D** 指 `handshaker_analysis/dumps/ssp_descriptors.raw.txt`。`#n`是protobuf字段号而不是固定字节偏移；所有列表是repeated message，字符串为UTF-8 length-delimited，bytes为原始length-delimited，ID为uint64 varint。现代媒体请求/响应是protobuf，没有旧APK的JSON/gzip布局。

### 7.1 完整媒体库读取

| 功能/type | 线上请求 -> 响应字段 | Mac消费行为与第一手证据 |
|---|---|---|
| 照片库/4 | Request仅`type#1=4`；Response `type#1=4,imageArray#2:SSPImageFile[],albumArray#3:SSPImageAlbum[],cameraAlbumId#4:uint64` | 构造器只设type，cameraDir是Mac本地捕获值（M:25036–25136，0xa3c02–0xa3cd0）；解析Response后检查hasCameraAlbumId，创建相册，再遍历imageArray，按albumId归组（M:25281–25381、25477–25530、25730–25783、26205–26233；0xa3fe3–0xa4217、0xa441f–0xa4552、0xa4987–0xa4aba、0xa53c8–0xa5468）。字段证据D:306–312。 |
| 视频库/5 | Request仅`type#1=5`；Response `type#1=5,videoArray#2:SSPVideoFile[],albumArray#3:SSPVideoAlbum[]` | 构造器只设type，cameraDir/sdcardCameraDir用于本地分类（M:22177–22304，0x9a5fe–0x9a74b）；先albumArray建相册，再videoArray建SFVideoFile，按albumId归组（M:22465–22473、22575–22589、22755–22784、22896–22949、23302–23330）。字段证据D:313–318。 |
| 音频库/6 | Request仅`type#1=6`；Response `type#1=6,audioArray#2:SSPAudioFile[],albumArray#3:SSPAudioAlbum[]` | 构造器只设type（M:23874–23947，0xa1f42–0xa1fa8）；先建立SFAudioAlbum，再建立SFAudioFile，以albumId关联children和album属性（M:24074–24082、24168–24243、24370–24423、24492–24528；0xa2252–0xa2284、0xa2464–0xa261c、0xa28ba–0xa29ed、0xa2b75–0xa2c41）。字段证据D:319–324。 |

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

三个need*Callback字段位于GetDeviceInfoRequest #5/#6/#7（D:145–156），Mac确实都设置true：M:31362–31376，0x8c822–0x8c865。`SSPManager.registerMediaLibraryChange:withBlock:`只设置本地photo/video/audioCallback，没有构造或enqueue新的网络消息（M:27317–27448，0x4a710–0x4a9af）。因此注册本地观察者与向手机请求推送是两个动作；push何时开始、是否有首次快照竞态仍需手机互通验证。

### 7.2 缩略图请求有ID与路径两种定位

GetThumbnailRequest/Response共用`type#1=3,imageArray#2:SSPImageFile[],videoArray#3:SSPVideoFile[],audioAlbumArray#4:SSPAudioAlbum[]`（D:296–305），各记录也可含thumbnail/getThumbnailError字段。Mac构造行为：

- 照片模式：只创建SSPImageFile并设置mediaId，再append imageArray；本地字典按mediaId匹配响应（M:15399–15430、15753–15768；0x2066–0x210b、0x27b8–0x2807）。
- 视频模式：只创建SSPVideoFile并设置mediaId，append videoArray；同样按mediaId匹配（M:16165–16196；0x2fd6–0x307b）。
- 音频封面：创建SSPAudioAlbum只设置albumId，append audioAlbumArray；按albumId匹配（M:16931–16962；0x3f46–0x3feb）。这不是发送音频文件mediaId。
- 普通目录的图片/视频：按SFImageFile/SFVideoFile的类型放入对应数组，设置path，**显式设置mediaId=0**，本地按path匹配响应（M:17725–17741、17816–17829；0x4f54–0x4fa2、0x5137–0x5178）。音频路径模式未在withFiles构造器中出现；支持情况**待验证**。

收到Response后Mac先读getThumbnailError，再读thumbnail字节，用NSImage.initWithData解码并保留originalData（M:15757–15850，0x27c6–0x29c5；路径模式M:18190–18285，0x58eb–0x5aee）。因此Dart应逐项报告失败，以ID/路径匹配而非请求数组位置；现代响应bytes的具体JPEG/PNG、尺寸、质量、EXIF处理**待验证**，当前Mac消费者不能证明一定为旧APK的JPEG86/200px。

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

### 7.3 媒体push不是完整库替换

| type/消息 | protobuf增量字段（D:325–338） | 路由确认 |
|---|---|---|
| 20 PhotoLibraryChange | `addedImageArray#2,deletedImageArray#3`，均SSPImageFile[] | M:11764–11835；0x6294c–0x62ac5 |
| 21 AudioLibraryChange | `addedAudioArray#2,deletedAudioArray#3:SSPAudioFile[];addedAlbumArray#4:SSPAudioAlbum[]` | M:11942–12013；0x62cdb–0x62e54 |
| 22 VideoLibraryChange | `addedVideoArray#2,deletedVideoArray#3,updatedVideoArray#4`，均SSPVideoFile[] | M:12120–12191；0x6306a–0x631e3 |

SSPManager先用SSPRequest读取type，再解析上述具体protobuf并调用已注册的对应callback；每次push更新lastHeartBeat（M:11547–11568、11926、12104、12282）。照片没有updatedImageArray、音频没有deletedAlbumArray或updatedAudioArray字段，这些变化如何由服务端表达**待验证**。实现者不得为了统一模型生成不存在的线上字段；可在收到已证明的增量后重新获取完整列表。

## 8. 现代辅助文件/同步功能矩阵

以下消息都经现代通用请求session发送、普通响应采用BE64长度前缀+protobuf；字段布局由descriptor确认，实际构造与消费由Mac汇编进一步限定。`SSPFile`的path/fileSize/时间/isDirectory/checksum/fileType/prefixMd5/extData tags见完整schema。这里不能从一个response成功布尔值证明现代手机具体写入了什么。

| 功能/type | Request字段 -> Response字段（不重复type#1） | Mac实际值、消费与待验证边界 |
|---|---|---|
| GetFileCount /8 | `dir#2:SSPFile,maxdepth#3:uint32,exclusionPatternArray#4:string[]` -> 同名#2/#3/#4，`count#5:uint64`（D:204–214） | dir仅设置path，排除模式数组直接append；**maxdepth=5**，不是目录浏览的1或递归0xffffffff（M:21233–21280，0x8936c–0x89452）。回调读count并返回NSNumber（M:21428–21503，0x896ee–0x8986f）。由字段/调用可推断“统计目录下文件数量”，pattern的glob/正则语法、是否含目录及深度定义**手机效果待验证**。 |
| FileExist /9 | `file#2:SSPFile` -> `file#2,exist#3:bool`（D:215–222） | 请求file只设path（M:21921–21943，0x8a0c6–0x8a133）；解析Response.exist回传bool（M:22045–22084，0x8a2e7–0x8a392）。推断查询该路径存在性；目录、符号链接、无权限路径语义**手机效果待验证**。 |
| UpdateFile /40 ->41 | `filesArray#2:SSPFile[],isSync#3:bool` -> `isSuccess#2:bool`（D:392–398） | 输入SFFile数组逐个`SFFile.transformSSPFileFromFile`，设filesArray与入参isSync，解析SSPUpdateFileResponse.isSuccess（M:18765–18797、18896–18939、19175–19177；0x72281–0x7231a、0x724de–0x725a5、0x729eb–0x729f5）。没有上传raw data路径。推断更新记录/元信息；是否修改物理mtime、数据库extData/收藏/校验值**手机效果待验证**，不可把它代替UploadFile。 |
| PhotoSync /37 | `pcId#2:string,filesArray#3:SSPFile[]` -> `isFirst#2:bool,filesArray#3:SSPFile[],isSuccess#4:bool`（D:371–379） | pcId取macUUID；lastFiles逐项transform为SSPFile（M:20076–20131、20231–20244，0x8800c–0x8811e、0x882cb–0x88305）。响应先检查isSuccess，再检查hasIsFirst/isFirst并遍历filesArray构造本地文件（M:20337–20434、20508–20585，0x884fe–0x8866c、0x887f6–0x8899a）。推断以电脑身份及上次快照进行相册同步协商；返回filesArray的新增/删除/冲突含义、首次同步标记具体服务端算法**手机效果待验证**。 |
| SyncMonitor /39 | `isSyncMonitor#2:bool` -> `isSuccess#2:bool`（D:386–391） | `SSPSyncMonitorSettingRequestOperation`直接复制enabled（M:19504–19534，0x7d5e0–0x7d679），回调检查isSuccess（M:19741–19743）。**SSPPhotoSyncOverRequestOperation也构造同一SSPSyncMonitorRequest**，把syncMonitorEnabled设为isSyncMonitor，消费同一Response（M:26826–26861、27063–27065；0xa8c80–0xa8d34、0xa9101–0xa910b）。没有独立“PhotoSyncOver”线上type，不能另造消息。推断切换同步监听开关；是否持久化、监听路径和生效时机**手机效果待验证**。 |
| FileChange push /38 | 无对应Request；`fileChangeItemsArray#2:SSPFileChangeItem[]`，item `file#1:SSPFile,status#2:enum`（D:380–385） | SSPManager检查type=0x26、解析SSPFileChange并调fileChangeCallback（M:13428–13561，0x64b84–0x64e34）；`registerFileChangedMonitorWithBlock`仅设置本地callback（M:29514–29552，0x672b0–0x67359）。status为None0/Added1/Deleted2/Modified3/InfoModified4/FileAndInfoModified5（D:479–485）。与MonitorFolder的SSPFileEvent不是同一结构；增量可能含文件内容和元信息变化区别，但服务端触发条件、与isSyncMonitor的因果关系**手机效果待验证**。 |

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
