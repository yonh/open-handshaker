# 现代 SSP Protobuf 模式：从 mac 二进制恢复的完整 schema

本节是在 Java ADBForward 旧命令通道之外，直接从所提供的 mac `SmartFinderCore` 未剥离 Mach-O 恢复的 **69 个消息、328 个字段、8 个枚举**。来源为 `handshaker_analysis/Contents/Frameworks/SmartFinderCore.framework/Versions/A/SmartFinderCore`，未使用网络与第三方推测。下文 `dumps/` 是 `handshaker_analysis/dumps/`。

## 1. 恢复方法和证据边界

`+[SSP... descriptor]` 将静态 `_descriptor.fields.*`、fieldCount 与 descriptorFlags 传给 GPBDescriptor。`LC_SEGMENT_64` 建立 VM 地址→文件偏移；`nm -nm` 提供非外部静态符号的地址；读取原始 field records。复核用反汇编保存为 `dumps/ssp_descriptors.disasm.txt`，全部原始字段十六进制与解码保存在 `dumps/ssp_descriptors.raw.txt`，机器可读版本为 `dumps/ssp_descriptors.json`。

descriptorFlags 的 bit0 表示 records 含 8 字节 default union：有默认值结构的每 record 40 字节，否则 32 字节。GPB runtime `initWithFieldDescription:includesDefault:syntax:` 明确在 includesDefault 时先将指针 +8。除 union 外字段结构为：`namePtr@0:ptr64`、`typeSpecific@8:ptr64`、`number@16:u32`、`hasIndex@20:i32`、`storageOffset@24:u32`、`flags@28:u16`、`datatype@30:u8`、`padding@31:u8`。**这些是本机 descriptor 内存布局，不是线字段偏移。** number/name/type 从 GPBFieldDescriptor getter 的代码核实。

flags：required=0x01、repeated=0x02、optional=0x08、hasDefault=0x10；其他位原样留在 raw evidence，不凭位名推断其协议意义。所有 recovered repeated 字段都是 string/message，不涉及 packed scalar。本文表中的字段名是 Objective-C 属性名（如 `register_p`、`fileArray`），原始 .proto 的文本拼写可能不同，但数字 tag 与线类型不受名字影响。重建稿有意保留 repeated 字段的 ObjC `Array` 后缀：`filesArray`、`imageArray` 等是普通 repeated message 属性名，不代表额外数组封装/计数字段；线编码仍是该 tag 的多次 key+length+message。

**已恢复的是消息 schema；不能单凭 metadata 确认现代通道的帧头、会话标识、加密模式、消息 direction 和每个字段的业务单位。** 与 Java `[command,subtype,version]` 不能混用。时间戳的 `ms/seconds`、checksum 字符串是否 hex、gzip 数据包范围等须从 operation 实现进一步核实。

## 2. Dart 编解码规则和字段动态偏移

这些消息是 Protobuf，不存在每字段固定字节偏移，也不保证每次字段顺序相同。每项使用 `key=varint((tag<<3)|wireType)`；要能跳过未知 tag，并按 number 查 schema。

| protobuf 类型 | wireType | value编码 | 一个字段从当前 body+p 开始的范围 |
|---|---:|---|---|
| bool、enum、uint32、uint64、int32、int64 | 0 | 无符号base128 varint；int32/int64为two's-complement，负值通常10字节；bool 0/1 | `key[kl] || value[vl]`；next=`p+kl+vl` |
| sint32/sint64 | 0 | ZigZag之后varint（本 SSP 字段没有此类型） | 同上 |
| string | 2 | UTF-8 bytes；先varint byteLength | `key[kl] || n[varint nl] || UTF8[n]`；next=`p+kl+nl+n` |
| bytes | 2 | 不解释内容；先varint byteLength | 同上 |
| 嵌套message/repeated message | 2 | 完整嵌套 protobuf 消息；每项独立 key+length+payload | 同上，重复字段多次出现，不加数组count |
| double | 1 | IEEE754 64bit **小端** | `key[kl] || LE64[8]`；next=`p+kl+8` |

wireType table 来自二进制 `_GPBWireFormatForType.format`，含 `(0,5,5,5,1,1,1,0,0,0,0,0,0,2,2,2,3,0)`；datatype 0..17 通过 `_MergeSingleFieldFromCodedInputStream` 的 jump table 分支分别调用 ReadBool/ReadFixed32/ReadSFixed32/ReadFloat/ReadFixed64/ReadSFixed64/ReadDouble/ReadInt32/ReadInt64/ReadSInt32/ReadSInt64/ReadUInt32/ReadUInt64/ReadBytes/ReadString/ReadMessage/ReadGroup/ReadEnum 核对（`dumps/ssp_descriptors.raw.txt:486-505`；jump-table分支反汇编见`dumps/ssp_descriptors.disasm.txt:7100`）。

这是 proto2 presence：optional 未设置时 getter 返回默认值，但 hasX=false，序列化省略；显式设置为默认值时 hasX=true，序列化会发送该字段；clear 恢复缺失状态。保留 presence，不能仅凭值等于 default 删除字段。**尤其 tag=1 type 必须明确编码**，否则独立解析为 SSPRequest 时默认值为 HeartBeatRequest=1，不能可靠按具体 message 的默认 type 推断路由。required clipboard tag=2 必须存在。uint64 在 Dart 中用 protobuf生成器的`fixnum.Int64`位表示或BigInt，保留全部64位；Dart signed int不足以表示大于2^63-1的正uint64。数值不经JSON double，在JS编译目标尤其保留精度。

## 3. RequestType：完整现代注册编号

与旧 ADB 数字不同。所有现代 request/response 都在 protobuf **tag=1** 放 SSPRequestType enum，key=08（wire0），不是固定头第一个 byte。

字段结构复核：`dumps/ssp_descriptors.disasm.txt:6607`、`dumps/ssp_descriptors.disasm.txt:6892`、`dumps/ssp_descriptors.disasm.txt:6861`；flags见 `dumps/ssp_descriptors.disasm.txt:6922` 与 `dumps/ssp_descriptors.disasm.txt:6941`。


| 值 | 真实枚举名 | descriptor 默认使用该编号的类 |
|---:|---|---|
| 1 | HeartBeatRequest | SSPRequest, SSPHeartBeatRequest, SSPHeartBeatResponse；`dumps/ssp_descriptors.raw.txt:400` |
| 2 | GetDeviceInfoRequest | SSPGetDeviceInfoRequest, SSPGetDeviceInfoResponse；`dumps/ssp_descriptors.raw.txt:401` |
| 3 | GetThumbnailRequest | SSPGetThumbnailRequest, SSPGetThumbnailResponse；`dumps/ssp_descriptors.raw.txt:402` |
| 4 | GetPhotoLibRequest | SSPGetPhotoLibraryRequest, SSPGetPhotoLibraryResponse；`dumps/ssp_descriptors.raw.txt:403` |
| 5 | GetVideoLibRequest | SSPGetVideoLibraryRequest, SSPGetVideoLibraryResponse；`dumps/ssp_descriptors.raw.txt:404` |
| 6 | GetAudioLibRequest | SSPGetAudioLibraryRequest, SSPGetAudioLibraryResponse；`dumps/ssp_descriptors.raw.txt:405` |
| 7 | GetDirFilesRequest | SSPGetDirFilesRequest, SSPGetDirFilesResponse；`dumps/ssp_descriptors.raw.txt:406` |
| 8 | GetFileCountRequest | SSPGetFileCountRequest, SSPGetFileCountResponse；`dumps/ssp_descriptors.raw.txt:407` |
| 9 | GetFileExistRequest | SSPFileExistRequest, SSPFileExistResponse；`dumps/ssp_descriptors.raw.txt:408` |
| 10 | GetCreateFolderRequest | SSPCreateFolderRequest, SSPCreateFolderResponse；`dumps/ssp_descriptors.raw.txt:409` |
| 11 | GetRenameFileRequest | SSPRenameFileRequest, SSPRenameFileResponse；`dumps/ssp_descriptors.raw.txt:410` |
| 12 | GetDownloadFileRequest | SSPDownloadFileRequest；`dumps/ssp_descriptors.raw.txt:411` |
| 13 | GetDownloadFileResponseHeader | SSPDownloadFileResponseHeader；`dumps/ssp_descriptors.raw.txt:412` |
| 14 | GetDownloadFileResponseBody | 无独立 message descriptor；需查 operation 原始数据路径；`dumps/ssp_descriptors.raw.txt:413` |
| 15 | GetUploadFileRequestHeader | SSPUploadFileRequest；`dumps/ssp_descriptors.raw.txt:414` |
| 16 | GetUploadFileResponseHeader | 存在同名 SSPUploadFileResponseHeader 类，但默认编号18；16线上使用待验证；`dumps/ssp_descriptors.raw.txt:415` |
| 17 | GetUploadFileRequestBody | 无独立 message descriptor；需查 operation 原始数据路径；`dumps/ssp_descriptors.raw.txt:416` |
| 18 | GetUploadFileResponse | SSPUploadFileResponseHeader, SSPUploadFileResponse；`dumps/ssp_descriptors.raw.txt:417` |
| 19 | GetDeleteFileRequest | SSPDeleteFileRequest, SSPDeleteFileResponse；`dumps/ssp_descriptors.raw.txt:418` |
| 20 | PhotoLibChange | SSPPhotoLibraryChange；`dumps/ssp_descriptors.raw.txt:419` |
| 21 | AudioLibChange | SSPAudioLibraryChange；`dumps/ssp_descriptors.raw.txt:420` |
| 22 | VideoLibChange | SSPVideoLibraryChange；`dumps/ssp_descriptors.raw.txt:421` |
| 23 | MonitorFolderRequest | SSPMonitorFolderRequest；`dumps/ssp_descriptors.raw.txt:422` |
| 24 | MonitorFolderResponseHeader | SSPMonitorFolderResponseHeader；`dumps/ssp_descriptors.raw.txt:423` |
| 25 | MonitorFolderResponse | SSPMonitorFolderResponse；`dumps/ssp_descriptors.raw.txt:424` |
| 26 | GetClipboardRequest | SSPGetClipboardRequest, SSPGetClipboardResponse；`dumps/ssp_descriptors.raw.txt:425` |
| 27 | PostClipboardRequest | SSPPostClipboardRequest, SSPPostClipboardResponse；`dumps/ssp_descriptors.raw.txt:426` |
| 28 | ClearClipboardRequest | SSPClearClipboardRequest, SSPClearClipboardResponse；`dumps/ssp_descriptors.raw.txt:427` |
| 29 | DeleteClipboardRequest | SSPDeleteClipboardRequest, SSPDeleteClipboardResponse；`dumps/ssp_descriptors.raw.txt:428` |
| 30 | ClipboardChange | SSPClipboardChange；`dumps/ssp_descriptors.raw.txt:429` |
| 31 | HandshakeRequest01 | SSPHandShakeRequest01；`dumps/ssp_descriptors.raw.txt:430` |
| 32 | HandshakeResponse01 | SSPHandShakeResponse01；`dumps/ssp_descriptors.raw.txt:431` |
| 33 | HandshakeRequest02 | SSPHandShakeRequest02；`dumps/ssp_descriptors.raw.txt:432` |
| 34 | HandshakeResponse02 | SSPHandShakeResponse02；`dumps/ssp_descriptors.raw.txt:433` |
| 35 | QuitRequest | SSPQuitRequest；`dumps/ssp_descriptors.raw.txt:434` |
| 36 | CancelRequest | SSPCancelRequest；`dumps/ssp_descriptors.raw.txt:435` |
| 37 | PhotoSyncRequest | SSPPhotoSyncRequest, SSPPhotoSyncResponse；`dumps/ssp_descriptors.raw.txt:436` |
| 38 | FileChange | SSPFileChange；`dumps/ssp_descriptors.raw.txt:437` |
| 39 | SyncMonitorRequest | SSPSyncMonitorRequest, SSPSyncMonitorResponse；`dumps/ssp_descriptors.raw.txt:438` |
| 40 | UpdateFileInfo | SSPUpdateFileRequest；`dumps/ssp_descriptors.raw.txt:439` |
| 41 | UpdateFileInfoResponse | SSPUpdateFileResponse；`dumps/ssp_descriptors.raw.txt:440` |

**重要原始差异：** `SSPUploadFileResponseHeader` 的 tag=1 默认值确实为18（GetUploadFileResponse），但 RequestType enum 中 GetUploadFileResponseHeader=16。此处按原始 metadata 记录，实际 operation 是否覆盖为16待验证，不能自行“修正”。GetDownloadFileResponseBody=14、GetUploadFileRequestBody=17 没有独立 Protobuf message descriptor，可能是文件原始数据流的标识，具体 outer frame待验证。

## 4. 其他全部枚举

### SSPFileEventType

`dumps/ssp_descriptors.raw.txt:441`；原始名称保持 Unknow 等拼写。

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

### SSPFileIOError

`dumps/ssp_descriptors.raw.txt:450`；原始名称保持 Unknow 等拼写。

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

### SSPFileIOPermission

`dumps/ssp_descriptors.raw.txt:461`；原始名称保持 Unknow 等拼写。

| 值 | 名称 |
|---:|---|
| 0 | AllowNone |
| 1 | AllowRead |
| 2 | AllowWrite |
| 3 | AllowReadWrite |

### SSPHandShakeTrustType

`dumps/ssp_descriptors.raw.txt:466`；原始名称保持 Unknow 等拼写。

| 值 | 名称 |
|---:|---|
| 1 | TrustWaiting |
| 2 | TrustUnknow |
| 3 | TrustNo |
| 4 | TrustOnce |
| 5 | TrustAlways |
| 6 | TrustRemove |

### SSPCancelErrorCode

`dumps/ssp_descriptors.raw.txt:473`；原始名称保持 Unknow 等拼写。

| 值 | 名称 |
|---:|---|
| 1 | ErrorCodeUnknown |
| 2 | ErrorCodeSdcardRemoved |

### SSPFileType

`dumps/ssp_descriptors.raw.txt:476`；原始名称保持 Unknow 等拼写。

| 值 | 名称 |
|---:|---|
| 0 | Normal |
| 1 | Data |

### SSPFileChangeStatus

`dumps/ssp_descriptors.raw.txt:479`；原始名称保持 Unknow 等拼写。

| 值 | 名称 |
|---:|---|
| 0 | None |
| 1 | Added |
| 2 | Deleted |
| 3 | Modified |
| 4 | InfoModified |
| 5 | FileAndInfoModified |


TrustType 的状态序列应由握手 operation决定；enum只证明 waiting/unknown/no/once/always/remove 数值，不能保证 Java 单阶段RSA握手支持这些信任状态。

## 5. 完整字段表（全部消息）

每张表按 tag 显示，但 decoder 不依赖此顺序。“key hex”是 field key 的varint，不包括 value。每个字段的来源行同时给出原始 record bytes、tag、datatype、flags和默认union，可逐字节复核。enum 字段的类型列用 enum 名称，message 用嵌套类名。无显式默认时 string/bytes为空，numeric/bool为0/false，message未设置，enum按该enum首项。

### SSPFile

`dumps/ssp_descriptors.raw.txt:2`；fieldCount=9。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 0a | path | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:3` |
| 2 | 10 | fileSize | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:4` |
| 3 | 18 | createdTimestamp | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:5` |
| 4 | 20 | modifiedTimestamp | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:6` |
| 6 | 30 | isDirectory | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:7` |
| 7 | 3a | checksum | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:8` |
| 8 | 40 | fileType | SSPFileType | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:9` |
| 9 | 4a | prefixMd5 | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:10` |
| 10 | 52 | extData | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:11` |

### SSPImageFile

`dumps/ssp_descriptors.raw.txt:12`；fieldCount=19。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 0a | path | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:13` |
| 2 | 10 | fileSize | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:14` |
| 3 | 18 | createdTimestamp | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:15` |
| 4 | 20 | modifiedTimestamp | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:16` |
| 5 | 28 | width | uint32 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:17` |
| 6 | 30 | height | uint32 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:18` |
| 7 | 38 | orientation | uint32 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:19` |
| 8 | 40 | mediaId | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:20` |
| 9 | 48 | albumId | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:21` |
| 10 | 52 | mimeType | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:22` |
| 11 | 5a | thumbnail | bytes | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:23` |
| 12 | 62 | albumName | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:24` |
| 13 | 68 | dateTaken | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:25` |
| 14 | 72 | latitude | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:26` |
| 15 | 7a | longitude | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:27` |
| 16 | 82 01 | miniThumbMagic | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:28` |
| 17 | 8a 01 | title | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:29` |
| 18 | 90 01 | getThumbnailError | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:30` |
| 19 | 98 01 | starred | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:31` |

### SSPImageAlbum

`dumps/ssp_descriptors.raw.txt:32`；fieldCount=4。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 0a | albumPath | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:33` |
| 2 | 10 | albumId | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:34` |
| 3 | 1a | albumName | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:35` |
| 4 | 22 | coverImage | SSPImageFile | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:36` |

### SSPAudioFile

`dumps/ssp_descriptors.raw.txt:37`；fieldCount=27。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 0a | path | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:38` |
| 2 | 10 | fileSize | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:39` |
| 3 | 18 | createdTimestamp | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:40` |
| 4 | 20 | modifiedTimestamp | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:41` |
| 5 | 28 | mediaId | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:42` |
| 6 | 30 | albumId | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:43` |
| 7 | 3a | title | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:44` |
| 8 | 42 | mimeType | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:45` |
| 9 | 48 | artistId | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:46` |
| 10 | 52 | artist | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:47` |
| 11 | 5a | composer | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:48` |
| 12 | 60 | genre | uint32 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:49` |
| 13 | 6a | comment | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:50` |
| 14 | 72 | copyright | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:51` |
| 15 | 7a | audioCodec | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:52` |
| 16 | 80 01 | track | uint32 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:53` |
| 17 | 89 01 | duration | double | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:54` |
| 18 | 91 01 | startOffset | double | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:55` |
| 19 | 98 01 | year | uint32 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:56` |
| 20 | a0 01 | bitrate | uint32 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:57` |
| 21 | a9 01 | sampleRate | double | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:58` |
| 22 | b0 01 | playCount | uint32 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:59` |
| 23 | b9 01 | rating | double | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:60` |
| 24 | c0 01 | totalFrames | uint32 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:61` |
| 25 | c8 01 | bitspersample | uint32 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:62` |
| 26 | d0 01 | channels | uint32 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:63` |
| 27 | da 01 | genreName | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:64` |

### SSPAudioAlbum

`dumps/ssp_descriptors.raw.txt:65`；fieldCount=8。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 0a | albumPath | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:66` |
| 2 | 10 | albumId | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:67` |
| 3 | 1a | albumName | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:68` |
| 4 | 20 | artistId | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:69` |
| 5 | 2a | artist | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:70` |
| 6 | 30 | year | uint32 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:71` |
| 7 | 3a | thumbnail | bytes | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:72` |
| 8 | 40 | getThumbnailError | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:73` |

### SSPVideoFile

`dumps/ssp_descriptors.raw.txt:74`；fieldCount=13。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 0a | path | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:75` |
| 2 | 10 | fileSize | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:76` |
| 3 | 18 | createdTimestamp | uint32 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:77` |
| 4 | 20 | modifiedTimestamp | uint32 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:78` |
| 5 | 28 | width | uint32 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:79` |
| 6 | 30 | height | uint32 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:80` |
| 7 | 38 | orientation | uint32 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:81` |
| 8 | 40 | mediaId | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:82` |
| 9 | 48 | albumId | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:83` |
| 10 | 52 | mimeType | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:84` |
| 11 | 5a | thumbnail | bytes | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:85` |
| 12 | 60 | getThumbnailError | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:86` |
| 13 | 69 | duration | double | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:87` |

### SSPVideoAlbum

`dumps/ssp_descriptors.raw.txt:88`；fieldCount=3。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 0a | albumPath | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:89` |
| 2 | 10 | albumId | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:90` |
| 3 | 1a | albumName | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:91` |

### SSPDataRange

`dumps/ssp_descriptors.raw.txt:92`；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | offset | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:93` |
| 2 | 10 | length | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:94` |

### SSPFileEvent

`dumps/ssp_descriptors.raw.txt:95`；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 0a | file | SSPFile | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:96` |
| 2 | 10 | event | SSPFileEventType | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:97` |

### SSPRequest

`dumps/ssp_descriptors.raw.txt:98`；fieldCount=1。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:99` |

### SSPHandShakeRequest01

`dumps/ssp_descriptors.raw.txt:100`；fieldCount=11。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 31 (HandshakeRequest01) | `dumps/ssp_descriptors.raw.txt:101` |
| 2 | 12 | hostUuid | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:102` |
| 3 | 1a | hostName | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:103` |
| 4 | 20 | hostTimestamp | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:104` |
| 5 | 2a | hostSmartSyncProtocolVersion | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:105` |
| 6 | 32 | hostAppVersion | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:106` |
| 7 | 3a | hostMinClientVersion | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:107` |
| 8 | 42 | md5 | bytes | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:108` |
| 9 | 4a | enckey | bytes | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:109` |
| 10 | 52 | hostModel | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:110` |
| 11 | 58 | heartbeatTimeoutSecond | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:111` |

### SSPHandShakeResponse01

`dumps/ssp_descriptors.raw.txt:112`；fieldCount=11。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 32 (HandshakeResponse01) | `dumps/ssp_descriptors.raw.txt:113` |
| 2 | 12 | apkVersion | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:114` |
| 3 | 1a | apkVersionName | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:115` |
| 4 | 20 | clientTimestamp | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:116` |
| 5 | 2a | clientSmartSyncProtocolVersion | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:117` |
| 6 | 32 | clientMinHostVersion | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:118` |
| 7 | 3a | deviceUuid | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:119` |
| 8 | 42 | deviceName | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:120` |
| 9 | 4a | usbSerial | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:121` |
| 10 | 50 | isSmartisanDevice | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:122` |
| 11 | 58 | clientMinHostVersionCode | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:123` |

### SSPHandShakeRequest02

`dumps/ssp_descriptors.raw.txt:124`；fieldCount=4。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 33 (HandshakeRequest02) | `dumps/ssp_descriptors.raw.txt:125` |
| 2 | 12 | hostUuid | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:126` |
| 3 | 1a | derivedKey | bytes | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:127` |
| 4 | 20 | trustType | SSPHandShakeTrustType | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:128` |

### SSPHandShakeResponse02

`dumps/ssp_descriptors.raw.txt:129`；fieldCount=6。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 34 (HandshakeResponse02) | `dumps/ssp_descriptors.raw.txt:130` |
| 2 | 10 | trustType | SSPHandShakeTrustType | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:131` |
| 3 | 1a | deviceUuid | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:132` |
| 4 | 22 | deviceName | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:133` |
| 5 | 2a | derivedKey | bytes | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:134` |
| 6 | 32 | result | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:135` |

### SSPHeartBeatRequest

`dumps/ssp_descriptors.raw.txt:136`；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 1 (HeartBeatRequest) | `dumps/ssp_descriptors.raw.txt:137` |
| 2 | 10 | hostTimestamp | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:138` |

### SSPHeartBeatResponse

`dumps/ssp_descriptors.raw.txt:139`；fieldCount=3。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 1 (HeartBeatRequest) | `dumps/ssp_descriptors.raw.txt:140` |
| 2 | 10 | hostTimestamp | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:141` |
| 3 | 18 | clientTimestamp | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:142` |

### SSPQuitRequest

`dumps/ssp_descriptors.raw.txt:143`；fieldCount=1。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 35 (QuitRequest) | `dumps/ssp_descriptors.raw.txt:144` |

### SSPGetDeviceInfoRequest

`dumps/ssp_descriptors.raw.txt:145`；fieldCount=11。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 2 (GetDeviceInfoRequest) | `dumps/ssp_descriptors.raw.txt:146` |
| 2 | 10 | hostTimestamp | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:147` |
| 3 | 1a | hostSmartSyncProtocolVersion | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:148` |
| 4 | 20 | needDeviceInfoCallback | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:149` |
| 5 | 28 | needPhotoLibraryCallback | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:150` |
| 6 | 30 | needAudioLibraryCallback | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:151` |
| 7 | 38 | needVideoLibraryCallback | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:152` |
| 8 | 42 | hostAppVersion | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:153` |
| 9 | 4a | hostMinClientVersion | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:154` |
| 10 | 50 | hostType | uint32 | optional | 1 | `dumps/ssp_descriptors.raw.txt:155` |
| 11 | 58 | hostAppVersionCode | uint32 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:156` |

### SSPGetDeviceInfoResponse

`dumps/ssp_descriptors.raw.txt:157`；fieldCount=36。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 2 (GetDeviceInfoRequest) | `dumps/ssp_descriptors.raw.txt:158` |
| 2 | 10 | hostTimestamp | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:159` |
| 3 | 1a | hostSmartSyncProtocolVersion | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:160` |
| 4 | 22 | apkVersion | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:161` |
| 5 | 28 | clientTimestamp | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:162` |
| 6 | 32 | clientSmartSyncProtocolVersion | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:163` |
| 7 | 3a | hostAppVersion | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:164` |
| 8 | 42 | hostMinClientVersion | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:165` |
| 9 | 4a | phoneModel | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:166` |
| 10 | 52 | phoneColor | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:167` |
| 11 | 58 | diskSize | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:168` |
| 12 | 60 | ramSize | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:169` |
| 13 | 69 | batteryCapacity | double | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:170` |
| 14 | 70 | batteryPercentage | uint32 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:171` |
| 15 | 7a | phoneName | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:172` |
| 16 | 80 01 | usedDiskSize | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:173` |
| 17 | 8a 01 | rootPath | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:174` |
| 18 | 92 01 | productBrand | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:175` |
| 19 | 9a 01 | productManufacturer | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:176` |
| 20 | a2 01 | smartisanVersion | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:177` |
| 21 | a8 01 | phoneLocked | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:178` |
| 22 | b2 01 | clientMinHostVersion | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:179` |
| 23 | ba 01 | apkVersionName | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:180` |
| 24 | c2 01 | externalStoragePath | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:181` |
| 25 | c8 01 | externalStoragePermission | SSPFileIOPermission | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:182` |
| 26 | d0 01 | extDiskSize | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:183` |
| 27 | d8 01 | extUsedDiskSize | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:184` |
| 28 | e2 01 | phoneId | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:185` |
| 29 | e8 01 | audioSize | int64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:186` |
| 30 | f0 01 | picVideoSize | int64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:187` |
| 31 | f8 01 | downloadSize | int64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:188` |
| 32 | 80 02 | otherSize | int64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:189` |
| 33 | 88 02 | appSize | int64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:190` |
| 34 | 90 02 | cacheSize | int64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:191` |
| 35 | 9a 02 | debugBuildTime | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:192` |
| 36 | a0 02 | clientMinHostVersionCode | int64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:193` |

### SSPGetDirFilesRequest

`dumps/ssp_descriptors.raw.txt:194`；fieldCount=3。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 7 (GetDirFilesRequest) | `dumps/ssp_descriptors.raw.txt:195` |
| 2 | 12 | dir | SSPFile | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:196` |
| 3 | 18 | maxdepth | uint32 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:197` |

### SSPGetDirFilesResponse

`dumps/ssp_descriptors.raw.txt:198`；fieldCount=5。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 7 (GetDirFilesRequest) | `dumps/ssp_descriptors.raw.txt:199` |
| 2 | 12 | dir | SSPFile | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:200` |
| 3 | 18 | maxdepth | uint32 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:201` |
| 4 | 20 | timecost | uint32 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:202` |
| 5 | 2a | fileArray | SSPFile | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:203` |

### SSPGetFileCountRequest

`dumps/ssp_descriptors.raw.txt:204`；fieldCount=4。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 8 (GetFileCountRequest) | `dumps/ssp_descriptors.raw.txt:205` |
| 2 | 12 | dir | SSPFile | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:206` |
| 3 | 18 | maxdepth | uint32 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:207` |
| 4 | 22 | exclusionPatternArray | string | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:208` |

### SSPGetFileCountResponse

`dumps/ssp_descriptors.raw.txt:209`；fieldCount=5。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 8 (GetFileCountRequest) | `dumps/ssp_descriptors.raw.txt:210` |
| 2 | 12 | dir | SSPFile | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:211` |
| 3 | 18 | maxdepth | uint32 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:212` |
| 4 | 22 | exclusionPatternArray | string | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:213` |
| 5 | 28 | count | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:214` |

### SSPFileExistRequest

`dumps/ssp_descriptors.raw.txt:215`；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 9 (GetFileExistRequest) | `dumps/ssp_descriptors.raw.txt:216` |
| 2 | 12 | file | SSPFile | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:217` |

### SSPFileExistResponse

`dumps/ssp_descriptors.raw.txt:218`；fieldCount=3。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 9 (GetFileExistRequest) | `dumps/ssp_descriptors.raw.txt:219` |
| 2 | 12 | file | SSPFile | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:220` |
| 3 | 18 | exist | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:221` |

### SSPCreateFolderRequest

`dumps/ssp_descriptors.raw.txt:222`；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 10 (GetCreateFolderRequest) | `dumps/ssp_descriptors.raw.txt:223` |
| 2 | 12 | file | SSPFile | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:224` |

### SSPCreateFolderResponse

`dumps/ssp_descriptors.raw.txt:225`；fieldCount=5。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 10 (GetCreateFolderRequest) | `dumps/ssp_descriptors.raw.txt:226` |
| 2 | 12 | file | SSPFile | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:227` |
| 3 | 18 | succeed | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:228` |
| 4 | 20 | errorCode | SSPFileIOError | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:229` |
| 5 | 2a | errorMessage | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:230` |

### SSPRenameFileRequest

`dumps/ssp_descriptors.raw.txt:231`；fieldCount=3。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 11 (GetRenameFileRequest) | `dumps/ssp_descriptors.raw.txt:232` |
| 2 | 12 | sourceFile | SSPFile | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:233` |
| 3 | 1a | targetFile | SSPFile | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:234` |

### SSPRenameFileResponse

`dumps/ssp_descriptors.raw.txt:235`；fieldCount=6。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 11 (GetRenameFileRequest) | `dumps/ssp_descriptors.raw.txt:236` |
| 2 | 12 | sourceFile | SSPFile | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:237` |
| 3 | 1a | targetFile | SSPFile | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:238` |
| 4 | 20 | succeed | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:239` |
| 5 | 28 | errorCode | SSPFileIOError | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:240` |
| 6 | 32 | errorMessage | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:241` |

### SSPDeleteFileRequest

`dumps/ssp_descriptors.raw.txt:242`；fieldCount=4。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 19 (GetDeleteFileRequest) | `dumps/ssp_descriptors.raw.txt:243` |
| 2 | 12 | file | SSPFile | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:244` |
| 3 | 18 | isSync | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:245` |
| 4 | 20 | isTrash | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:246` |

### SSPDeleteFileResponse

`dumps/ssp_descriptors.raw.txt:247`；fieldCount=5。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 19 (GetDeleteFileRequest) | `dumps/ssp_descriptors.raw.txt:248` |
| 2 | 12 | file | SSPFile | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:249` |
| 4 | 20 | succeed | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:250` |
| 5 | 28 | errorCode | SSPFileIOError | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:251` |
| 6 | 32 | errorMessage | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:252` |

### SSPMonitorFolderRequest

`dumps/ssp_descriptors.raw.txt:253`；fieldCount=3。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 23 (MonitorFolderRequest) | `dumps/ssp_descriptors.raw.txt:254` |
| 2 | 12 | file | SSPFile | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:255` |
| 3 | 18 | register_p | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:256` |

### SSPMonitorFolderResponseHeader

`dumps/ssp_descriptors.raw.txt:257`；fieldCount=3。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 24 (MonitorFolderResponseHeader) | `dumps/ssp_descriptors.raw.txt:258` |
| 2 | 10 | succeed | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:259` |
| 3 | 1a | errorMessage | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:260` |

### SSPMonitorFolderResponse

`dumps/ssp_descriptors.raw.txt:261`；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 25 (MonitorFolderResponse) | `dumps/ssp_descriptors.raw.txt:262` |
| 2 | 12 | eventArray | SSPFileEvent | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:263` |

### SSPDownloadFileRequest

`dumps/ssp_descriptors.raw.txt:264`；fieldCount=6。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 12 (GetDownloadFileRequest) | `dumps/ssp_descriptors.raw.txt:265` |
| 2 | 12 | file | SSPFile | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:266` |
| 3 | 1a | range | SSPDataRange | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:267` |
| 4 | 20 | needMd5 | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:268` |
| 5 | 28 | gzip | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:269` |
| 6 | 30 | isSync | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:270` |

### SSPDownloadFileResponseHeader

`dumps/ssp_descriptors.raw.txt:271`；fieldCount=7。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 13 (GetDownloadFileResponseHeader) | `dumps/ssp_descriptors.raw.txt:272` |
| 2 | 12 | file | SSPFile | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:273` |
| 3 | 1a | range | SSPDataRange | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:274` |
| 4 | 20 | needMd5 | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:275` |
| 5 | 2a | dataMd5 | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:276` |
| 6 | 30 | ready | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:277` |
| 7 | 38 | errorCode | SSPFileIOError | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:278` |

### SSPUploadFileRequest

`dumps/ssp_descriptors.raw.txt:279`；fieldCount=5。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 15 (GetUploadFileRequestHeader) | `dumps/ssp_descriptors.raw.txt:280` |
| 2 | 12 | file | SSPFile | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:281` |
| 3 | 1a | dataMd5 | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:282` |
| 4 | 20 | gzip | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:283` |
| 5 | 28 | isSync | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:284` |

### SSPUploadFileResponseHeader

`dumps/ssp_descriptors.raw.txt:285`；fieldCount=4。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 18 (GetUploadFileResponse) | `dumps/ssp_descriptors.raw.txt:286` |
| 2 | 12 | file | SSPFile | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:287` |
| 3 | 18 | ready | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:288` |
| 4 | 20 | errorCode | SSPFileIOError | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:289` |

### SSPUploadFileResponse

`dumps/ssp_descriptors.raw.txt:290`；fieldCount=5。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 18 (GetUploadFileResponse) | `dumps/ssp_descriptors.raw.txt:291` |
| 2 | 12 | file | SSPFile | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:292` |
| 3 | 18 | canceled | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:293` |
| 4 | 20 | succeed | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:294` |
| 5 | 28 | errorCode | SSPFileIOError | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:295` |

### SSPGetThumbnailRequest

`dumps/ssp_descriptors.raw.txt:296`；fieldCount=4。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 3 (GetThumbnailRequest) | `dumps/ssp_descriptors.raw.txt:297` |
| 2 | 12 | imageArray | SSPImageFile | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:298` |
| 3 | 1a | videoArray | SSPVideoFile | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:299` |
| 4 | 22 | audioAlbumArray | SSPAudioAlbum | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:300` |

### SSPGetThumbnailResponse

`dumps/ssp_descriptors.raw.txt:301`；fieldCount=4。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 3 (GetThumbnailRequest) | `dumps/ssp_descriptors.raw.txt:302` |
| 2 | 12 | imageArray | SSPImageFile | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:303` |
| 3 | 1a | videoArray | SSPVideoFile | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:304` |
| 4 | 22 | audioAlbumArray | SSPAudioAlbum | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:305` |

### SSPGetPhotoLibraryRequest

`dumps/ssp_descriptors.raw.txt:306`；fieldCount=1。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 4 (GetPhotoLibRequest) | `dumps/ssp_descriptors.raw.txt:307` |

### SSPGetPhotoLibraryResponse

`dumps/ssp_descriptors.raw.txt:308`；fieldCount=4。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 4 (GetPhotoLibRequest) | `dumps/ssp_descriptors.raw.txt:309` |
| 2 | 12 | imageArray | SSPImageFile | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:310` |
| 3 | 1a | albumArray | SSPImageAlbum | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:311` |
| 4 | 20 | cameraAlbumId | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:312` |

### SSPGetVideoLibraryRequest

`dumps/ssp_descriptors.raw.txt:313`；fieldCount=1。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 5 (GetVideoLibRequest) | `dumps/ssp_descriptors.raw.txt:314` |

### SSPGetVideoLibraryResponse

`dumps/ssp_descriptors.raw.txt:315`；fieldCount=3。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 5 (GetVideoLibRequest) | `dumps/ssp_descriptors.raw.txt:316` |
| 2 | 12 | videoArray | SSPVideoFile | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:317` |
| 3 | 1a | albumArray | SSPVideoAlbum | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:318` |

### SSPGetAudioLibraryRequest

`dumps/ssp_descriptors.raw.txt:319`；fieldCount=1。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 6 (GetAudioLibRequest) | `dumps/ssp_descriptors.raw.txt:320` |

### SSPGetAudioLibraryResponse

`dumps/ssp_descriptors.raw.txt:321`；fieldCount=3。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 6 (GetAudioLibRequest) | `dumps/ssp_descriptors.raw.txt:322` |
| 2 | 12 | audioArray | SSPAudioFile | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:323` |
| 3 | 1a | albumArray | SSPAudioAlbum | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:324` |

### SSPPhotoLibraryChange

`dumps/ssp_descriptors.raw.txt:325`；fieldCount=3。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 20 (PhotoLibChange) | `dumps/ssp_descriptors.raw.txt:326` |
| 2 | 12 | addedImageArray | SSPImageFile | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:327` |
| 3 | 1a | deletedImageArray | SSPImageFile | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:328` |

### SSPVideoLibraryChange

`dumps/ssp_descriptors.raw.txt:329`；fieldCount=4。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 22 (VideoLibChange) | `dumps/ssp_descriptors.raw.txt:330` |
| 2 | 12 | addedVideoArray | SSPVideoFile | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:331` |
| 3 | 1a | deletedVideoArray | SSPVideoFile | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:332` |
| 4 | 22 | updatedVideoArray | SSPVideoFile | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:333` |

### SSPAudioLibraryChange

`dumps/ssp_descriptors.raw.txt:334`；fieldCount=4。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 21 (AudioLibChange) | `dumps/ssp_descriptors.raw.txt:335` |
| 2 | 12 | addedAudioArray | SSPAudioFile | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:336` |
| 3 | 1a | deletedAudioArray | SSPAudioFile | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:337` |
| 4 | 22 | addedAlbumArray | SSPAudioAlbum | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:338` |

### SSPClipboard

`dumps/ssp_descriptors.raw.txt:339`；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 0a | content | bytes | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:340` |
| 2 | 10 | mstimestamp | int64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:341` |

### SSPGetClipboardRequest

`dumps/ssp_descriptors.raw.txt:342`；fieldCount=1。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 26 (GetClipboardRequest) | `dumps/ssp_descriptors.raw.txt:343` |

### SSPGetClipboardResponse

`dumps/ssp_descriptors.raw.txt:344`；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 26 (GetClipboardRequest) | `dumps/ssp_descriptors.raw.txt:345` |
| 2 | 12 | clipboardArray | SSPClipboard | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:346` |

### SSPPostClipboardRequest

`dumps/ssp_descriptors.raw.txt:347`；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 27 (PostClipboardRequest) | `dumps/ssp_descriptors.raw.txt:348` |
| 2 | 12 | clipboard | SSPClipboard | required | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:349` |

### SSPPostClipboardResponse

`dumps/ssp_descriptors.raw.txt:350`；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 27 (PostClipboardRequest) | `dumps/ssp_descriptors.raw.txt:351` |
| 2 | 10 | succeed | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:352` |

### SSPClearClipboardRequest

`dumps/ssp_descriptors.raw.txt:353`；fieldCount=1。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 28 (ClearClipboardRequest) | `dumps/ssp_descriptors.raw.txt:354` |

### SSPClearClipboardResponse

`dumps/ssp_descriptors.raw.txt:355`；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 28 (ClearClipboardRequest) | `dumps/ssp_descriptors.raw.txt:356` |
| 2 | 10 | succeed | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:357` |

### SSPDeleteClipboardRequest

`dumps/ssp_descriptors.raw.txt:358`；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 29 (DeleteClipboardRequest) | `dumps/ssp_descriptors.raw.txt:359` |
| 2 | 12 | clipboard | SSPClipboard | required | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:360` |

### SSPDeleteClipboardResponse

`dumps/ssp_descriptors.raw.txt:361`；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 29 (DeleteClipboardRequest) | `dumps/ssp_descriptors.raw.txt:362` |
| 2 | 10 | succeed | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:363` |

### SSPClipboardChange

`dumps/ssp_descriptors.raw.txt:364`；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 30 (ClipboardChange) | `dumps/ssp_descriptors.raw.txt:365` |
| 2 | 12 | clipboardArray | SSPClipboard | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:366` |

### SSPCancelRequest

`dumps/ssp_descriptors.raw.txt:367`；fieldCount=3。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 36 (CancelRequest) | `dumps/ssp_descriptors.raw.txt:368` |
| 2 | 10 | sessionId | uint64 | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:369` |
| 3 | 18 | errorCode | SSPCancelErrorCode | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:370` |

### SSPPhotoSyncRequest

`dumps/ssp_descriptors.raw.txt:371`；fieldCount=3。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 37 (PhotoSyncRequest) | `dumps/ssp_descriptors.raw.txt:372` |
| 2 | 12 | pcId | string | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:373` |
| 3 | 1a | filesArray | SSPFile | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:374` |

### SSPPhotoSyncResponse

`dumps/ssp_descriptors.raw.txt:375`；fieldCount=4。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 37 (PhotoSyncRequest) | `dumps/ssp_descriptors.raw.txt:376` |
| 2 | 10 | isFirst | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:377` |
| 3 | 1a | filesArray | SSPFile | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:378` |
| 4 | 20 | isSuccess | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:379` |

### SSPFileChange

`dumps/ssp_descriptors.raw.txt:380`；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 38 (FileChange) | `dumps/ssp_descriptors.raw.txt:381` |
| 2 | 12 | fileChangeItemsArray | SSPFileChangeItem | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:382` |

### SSPFileChangeItem

`dumps/ssp_descriptors.raw.txt:383`；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 0a | file | SSPFile | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:384` |
| 2 | 10 | status | SSPFileChangeStatus | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:385` |

### SSPSyncMonitorRequest

`dumps/ssp_descriptors.raw.txt:386`；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 39 (SyncMonitorRequest) | `dumps/ssp_descriptors.raw.txt:387` |
| 2 | 10 | isSyncMonitor | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:388` |

### SSPSyncMonitorResponse

`dumps/ssp_descriptors.raw.txt:389`；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 39 (SyncMonitorRequest) | `dumps/ssp_descriptors.raw.txt:390` |
| 2 | 10 | isSuccess | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:391` |

### SSPUpdateFileRequest

`dumps/ssp_descriptors.raw.txt:392`；fieldCount=3。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 40 (UpdateFileInfo) | `dumps/ssp_descriptors.raw.txt:393` |
| 2 | 12 | filesArray | SSPFile | repeated | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:394` |
| 3 | 18 | isSync | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:395` |

### SSPUpdateFileResponse

`dumps/ssp_descriptors.raw.txt:396`；fieldCount=2。

| tag | key hex | 属性名 | proto 类型 | rule | 显式默认 | 字段证据 |
|---:|---|---|---|---|---|---|
| 1 | 08 | type | SSPRequestType | optional | 41 (UpdateFileInfoResponse) | `dumps/ssp_descriptors.raw.txt:397` |
| 2 | 10 | isSuccess | bool | optional | —（隐式默认） | `dumps/ssp_descriptors.raw.txt:398` |


## 6. 按功能的现代消息序列（方向与重试细节待 operation复核）

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

## 7. 已交付的可编译schema与复现

`handshaker_open_docs/SmartSyncProtocol.recovered.proto` 是 proto2 重建稿，完整包含69messages/328fields/8enums；保留tag、类型、required/repeated、明确默认值，每message/enum注释引原始证据行。`package recovered.ssp` 是重建稿人工命名；字段名使用ObjC property，字节互通不受名字变化影响。通过本机protoc语法/descriptor_set编译。

复现（从仓库根执行）：

```sh
python3 handshaker_analysis/tools/recover_ssp_descriptors.py
python3 handshaker_analysis/tools/render_ssp_schema_docs.py
protoc --proto_path=handshaker_open_docs --descriptor_set_out=/tmp/ssp.pb handshaker_open_docs/SmartSyncProtocol.recovered.proto
```

extractor要求macOS nm、otool和该版原始二进制；GPB runtime jump-table地址及过滤行范围针对此artifact，不宣称适用其他版本。换版应重新确定metadata结构、符号和runtime分支。

