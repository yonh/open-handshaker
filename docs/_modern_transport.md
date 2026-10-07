# macOS 端 SSP v2：现代帧与 01/02 握手

这是从 macOS SmartFinderCore 方法反汇编、Proto descriptor 和常量读出的 **另一套** SSP 传输。`D/` 指 `handshaker_analysis/dumps/`。所有具体偏移从下列本地反汇编核实；未由本 APK 支持的现代帧不能直接发送给本 APK `10086` 旧协议入口。Modern hostSmartSyncProtocolVersion 字符串确认为 `"2"`（`D/modern_transport.constants.txt:2`）。下面标为“推断”的手机侧行为，仅由 mac 接收逻辑推得，没有现代手机源码佐证。

## 1. 现代主机→手机帧

Wi-Fi 的 `SFWifiDevice sendData:withSessionId:withFlag:` 和 USB 的同名方法都依次 append `u32be(sessionId)`、`u8(flag)`、`u32be(data.length)`、`data`（`D/modern_transport.disasm.txt:33–69,166–202`）。Wi-Fi 将完整缓冲交给 socket；USB写入libusb bulkOut（同文件 `78–84,223–241`）。没有旧协议的“先4字节总长度再flag”包装。

| wire 偏移 | 长度 | 类型 | 意义 | 证据 |
|---:|---:|---|---|---|
| 0 | 4 | u32be | sessionId；请求/响应关联标识 | `D/modern_transport.disasm.txt:33–40` |
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

- `0`：unsigned握手01/02，data是Protobuf，01使用sessionId=1，02先以1初始化再加1故sessionId=2（`D/modern_transport.disasm.txt:1226–1227,1284–1324,1732–1733,2038–2087`）。
- `1`：普通命令。`SFGenericDevice sendRequestData:withSessionId:error:` 计算 `getSignatureForData(protobufBytes)`，先append签名再append原protobuf，并以flag1调用sendData（同文件 `5658–5694`）。因此wire `9…136` 是128字节签名，protobuf从`137`开始；签名覆盖 **protobuf原字节**，不覆盖外层sessionId、flag、length。
- `3`：裸文件bytes。`SFGenericDevice sendFileData:withSessionId:error:` 使用flag3，将原始data直接交给sendData；本方法不计算RSA签名（同文件 `5776–5791`）。手机对应实现、是否仅允许已有文件上传session使用、如何限定长度须进一步验证，不能把裸文件内容当Protobuf解析。

`getSignatureForData` 对输入bytes做SHA256，再`RSA_sign(NID_sha256=0x2a0,hash,32,...)`，RSA签名为PKCS#1 v1.5，与旧APK `SHA256withRSA` 算法相同（同文件 `1111–1144`）。mac `SFGenericDevice init` 为每device实例生成1024bit RSA、exponent=65537并保存为 `efxi`，使用signing_mutex串行签名（同文件 `7271–7308`）。不要把现代derivedKey理解为替代RSA签名的AES key；这些已核实路径仍使用 `efxi` RSA private key签名。

**实现建议**：显式区分旧ADB framed命令和现代v2 transport，不依靠“看到第4byte=0/1”自动识别，因为现代第0–3字节是sessionId而非长度。

## 2. 现代手机→主机帧：物理chunk与逻辑消息

Wi-Fi后台 `messageReadingThreadMain` 从offset0取u32be sessionId、offset4取u16be chunkLen，从offset6取chunkData；对不完整的数据保留remainingData再累积（`D/modern_transport.disasm.txt:5888–5983`，主要取字段 `5910–5922`）。USB后台具有相同代码结构；本文偏移的可引用证据以Wi-Fi为准。

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

## 3. HandShakeRequest01/Response01

现代request01序列化的是Protobuf；字段tag与类型由真实descriptor读出（`D/ssp_descriptors.raw.txt:100–111`），不存在固定二进制offset，下面的tag不能误当wire byte偏移。

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

赋值代码证据：public key/MD5/AES `D/modern_transport.disasm.txt:371–574`；type、UUID、Name、Timestamp `620–704`；版本、md5、enckey、model `708–772`；heartbeat `775–783`。版本literal见 `D/modern_transport.constants.txt:2–3`。heartbeatTimeoutSecond初始化读NSUserDefaults后限制到10…180秒（`D/modern_transport.disasm.txt:7239–7270`）；本机实际值/偏好设置键待验证。

RSA public key封装同旧握手：`PEM_write_bio_RSAPublicKey`生成PKCS#1 public key文本，去换行，把Base64文本用空格补到32的倍数，AES-256-CBC（无PKCS7）使用固定key和IV；DER MD5和密文分别放入tag8/9，此处不再附旧握手的独立u32密文长度（同文件 `371–575,749–758`；常量 `D/adb_transport.constants.txt:28–29`；空白常量 `D/modern_transport.cfstrings.txt:5–7`）。

```text
key = 28e3ee32b0de27ef6bc29792054ef9739ce8e87bb495f2ea0d72d4f4f40b3bde
iv  = 2b9e34d4e1d9088994939ec4e3e960c5
```

主机发session1、flag0 request01，等Response01，使用SSPHandShakeResponse01解析；成功缓存对象 `theResponse01`、标 `_aoaHandShaking01OK=true`，设置apkVersion/apkVersionName及usbSerial（`D/modern_transport.disasm.txt:1209–1324,1590–1645`）。Response01字段由descriptor精确确认：type32、apkVersion(tag2 string)、apkVersionName(3 string)、clientTimestamp(4 uint64)、clientSmartSyncProtocolVersion(5 string)、clientMinHostVersion(6 string)、deviceUuid(7 string)、deviceName(8 string)、usbSerial(9 string)、isSmartisanDevice(10 bool)、clientMinHostVersionCode(11 uint64)（`D/ssp_descriptors.raw.txt:112–123`）。

这一步主要交换公钥和能力/身份；需要02阶段成功结果验证后才标整个连接可用，普通sendRequestData先检查aoaHandShakeOk（`D/modern_transport.disasm.txt:5635–5657`）。

## 4. TrustType 与 HandShakeRequest02/Response02

TrustType enum已从descriptor原始数值表恢复，非字符串猜测（`D/ssp_descriptors.raw.txt:466–472`）：

| 值 | 原始名称 | 可由mac确认的行为 |
|---:|---|---|
| 1 | TrustWaiting | 继续等待手机后续02响应；mac可能通知阻塞状态 |
| 2 | TrustUnknow | 新信任record/default Request02使用这个值，原拼写就是Unknow |
| 3 | TrustNo | 被拒绝，结束02，返回失败 |
| 4 | TrustOnce | 保存response的derivedKey与trust_type=4，然后处理result |
| 5 | TrustAlways | 保存response的derivedKey与trust_type=5，然后处理result |
| 6 | TrustRemove | enum有该值；握手02这里不按成功处理，移除具体流程待验证 |

`getRequest02WithError` 设置type默认值33、hostUuid、trustType=2（`D/modern_transport.disasm.txt:828–870`）。最终发送前，`sendHandShakeRequest02` 以response01.deviceUuid查找SFDeviceTrustStore record；新record设TrustUnknow2，已有record将 `record.trust_type` 和 `record.derived_key` 填入request02（同文件 `1744–1784,1915–1997`）。类型31/32/33/34由enum表确认（`D/ssp_descriptors.raw.txt:430–433`）。

Request02 Proto布局（均optional，descriptor：`D/ssp_descriptors.raw.txt:124–128`）：tag1 type(enum默认33)、tag2 hostUuid(string)、tag3 derivedKey(bytes)、tag4 trustType(enum默认Waiting1，mac通常显式设置2或stored value)。区分“Proto默认1”与“业务构造函数设2”。

Response02 Proto布局（均optional，descriptor：同文件 `129–135`）：tag1 type(enum默认34)、tag2 trustType(enum默认1)、tag3 deviceUuid(string)、tag4 deviceName(string)、tag5 derivedKey(bytes)、tag6 result(string)。

mac发session2、flag0 request02，循环读response02。TrustWaiting1分支调用通知block，sleep1秒再读；TrustNo3结束失败；TrustOnce4和TrustAlways5保存record值及derivedKey，调用store.save，再检查result（`D/modern_transport.disasm.txt:2953–2980,3140–3291,3450–3467`）。只有解析成功响应而且result证明通过才置aoaHandShakeOk=true。不能仅看到TrustAlways5就跳过RSA成功证明。

### 4.1 result证明与derivedKey的区别

result先检查非空、是否以ASCII `failed` 开头；否则Base64解码，交给 `checkResult`（同文件 `3647–3666,3818–3839,3992–4018`；literal `D/modern_transport.constants.txt:4–5`）。`checkResult`：要求总密文长度能整除 `RSA_size(efxi)`，逐RSA块调用 `RSA_private_decrypt(...,RSA_PKCS1_PADDING=1)`，把正数长度的明文块拼接为UTF-8字符串（`D/modern_transport.disasm.txt:902–918,970–1015`）。只接受字符串 `"ok"` 后设置aoaHandShakeOk（同文件 `4055–4078`）。

result是手机用request01收到的host RSA public key加密后的证明，不是SHA256签名；这一判断由主机private decrypt路径确定。derivedKey是另外一个Proto bytes字段，由Response02返回并存盘，下一次Request02原样发回；mac上述路径没有对derivedKey计算hash、RSA解密或AES解密（同文件 `1984–1997,3156–3174,3232–3250`）。**待验证**：现代手机生成derivedKey的算法、它与hostUuid/public key的绑定、过期/撤销策略、TrustOnce是否应跨重启复用，以及一次授权的精确生命周期；这些不能从mac“保存bytes”代码推导。

## 5. SFDeviceTrustStore 与 mac 生命周期

这次已有真正方法证据，不再只靠类名字符串：defaultStore使用 `NSApplication.applicationSupportFolder` 加 `deviceStore.plist`，再 `storeWithPath`（`D/modern_transport.disasm.txt:4388–4411`；filename literal `D/modern_transport.constants.txt:6`）。initAllWithPath建立devices数组、visibleDevices数组和deviceUUIDs字典，从NSKeyedUnarchiver文件加载；save通过NSKeyedArchiver archiveRootObject:toFile保存devices，然后resetVisibleDevices（同文件 `4621–4677,5501–5519`）。文件虽然叫`.plist`，应视为NSKeyedArchive，不应未经检测就当简单dictionary plist。

02开始时record更新以下内容：deviceUuid/deviceName、apkVersion/apkVersionName、clientMinHostVersion/clientSmartSyncProtocolVersion、last_connection=NSDate.now、isSmartisanDevice、connection_count+1（同文件 `1785–1934`）。新record先addRecord后save（同文件 `1935–1945`），TrustOnce/Always后另保存trust_type和derived_key。对应字段是mac持久化模型，与旧APKutils/j的单个进程static key机制不同。

字典findRecordByDeviceUUID是现代重连信任的入口；SSP手机端信任store没有本地现代APK源码佐证。`TrustRemove`被addRecord检查到存在路径，但删除/可见过滤策略尚未完整分析，标 **待验证**（同文件 `5201` 等）。

## 6. Dart 可实现的现代握手文字序列

1. 新建device transport，生成RSA-1024/e=65537；保存此次device实例的private key。
2. 生成Request01 Proto(type31、身份/版本、MD5/密文公钥、heartbeat设置)；发 `[sid=1][flag=0][u32be protoLen][proto]`。
3. 根据响应chunk格式收集逻辑消息，读u64 totalLen后解析Response01(type32)，取得deviceUuid和能力版本信息。
4. 查本地主机TrustStore：无record则trustType2；有record则放入stored trustType、derivedKey。生成Request02(type33、hostUuid、这些字段)，发 `[sid=2][flag=0][u32be protoLen][proto]`。
5. 连续接收Response02(type34)：Waiting1继续等待；No3结束；Once4/Always5保存手机returned derivedKey并检查result；其它值按未知/失败处理并保留证据。
6. `result`为Base64(RSA public encrypt(UTF8("ok")))；匹配private key解密等于`ok`时才进入ready。
7. ready后普通protobuf request使用新的sessionId、flag1、`signature128 || protobuf`，按sessionId路由response和push。裸上传文件flag3的具体session状态及文件头请结合现代文件传输实现。

**待验证清单**：现代设备网络端口/发现与USB AOAccessory起始步骤；手机侧确认UI及TrustType最终赋值；derivedKey生成/撤销；现代response chunk最大值及各消息长度规则；raw file flag3认证状态；同device实例之外RSA private key寿命；错误/退出是否复位手机public key。上述任何内容都不应自动套用旧APK `10086/19999` 和keep_alive_attr逻辑。
