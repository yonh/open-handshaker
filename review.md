# open-handshaker 独立代码审查报告

范围：`dev` @ `95850eb`，lib/ssp/、lib/agent/、lib/host/（controller/discovery/push_hub/photo_sync/idea_pills/pages）、lib/agent_ui/、android/ Kotlin、goal.md 对照。
仅报告，未改码。每条含 file:line + 为什么是真实缺陷 + 复现路径。

## 🔴 Blocker / High

### #1 [BLOCKER] 下载静默截断：socket 断开 = 半成品落盘
`lib/ssp/client.dart:465-497`
`_fileBodyCtl` 在 `_onDone`/`_onError` 时关闭 → `await for (chunk in bodyCtl.stream)` 正常退出循环 → 只检查 `header==null`/`aborted`/md5，**没有 `received < expected` 校验** → `rename(tmp→local)`。needMd5=false 且无 dataMd5 时（默认路径）半截文件直接交付。
复现：下载 1GB 视频中途杀 agent → `download()` 返回 `total:expected`、TransferTask completed、本地文件只有前 N 字节。

### #2 [HIGH] 信任落盘早于 proof 校验 → 永久信任绕过
`lib/ssp/client.dart:290-322` vs `:323-336` × `lib/ssp/server.dart:265-272`
`store.add(record)+save()` 在 L300-301（resp01 拿到 uuid 即持久化）；`Trust.always+derivedKey` 写入+`save()` 在 L318-322；`_verifyResultProof` 在 L323 才跑。流氓设备回 Trust.always+任意 derivedKey+伪造 result → handshake 抛错**但记录已入库**；下次连接 `record!=null` 跳过 `approveUnknownDevice`（L275-279）→ agent 端 `existing.derivedKey==req.derivedKey && trustType∈{once,always}` → 秒过。一次握手失败 = 终身免确认。（proof 用 host 公钥加密"ok"本身可伪造，公钥广播。）
复现：假 agent 在 Response02 回 `Trust.always`+垃圾 result → host 报错 → 重连 → 无弹窗直接 connected。

### #3 [HIGH] :19999 HTTP 端点零鉴权 → 局域网任意文件读
`lib/agent/http_file_server.dart:55-75`
`GET /?file_path=` 无认证无路径限定，绑 0.0.0.0。同网段 `curl 'http://phone:19999/?file_path=/data/data/...'` 读 agent 进程权限内任意文件（Range 支持 → 精确窃取）。

### #4 [HIGH] Agent 端下载整文件进内存 → OOM
`lib/agent/agent_handlers.dart:199-237`
`body = Uint8List.fromList(await raf.read(len))` + `md5Hex(body)` 双重驻留；几 GB 视频直接打爆 isolate。上传侧分段，下载侧不分段。
复现：host 下载 4K 视频 → agent 内存暴涨崩溃。

### #5 [HIGH] Agent 文件操作零路径沙箱（含 ../）
`lib/agent/agent_handlers.dart:199-302` + `lib/agent/providers/files_provider.dart:23-120` + `MainActivity.kt:113-133,448-457`
`download/delete/rename/createFolder/listDir/uploadHeader/exportApk` 全部直接消费 host 给的绝对路径，无 externalStorage 根前缀、无 `..` 归一化校验。host 私钥一旦泄露（见 #30）= 手机全盘读写删。

### #6 [HIGH] monitorFolder 注销失效 → 每次导航永久泄漏 watcher
`lib/agent/agent_handlers.dart:303-343` × `lib/host/pages/files_page.dart:98-120` × `lib/host/idea_pills.dart:51,193`
`_watchFolder(session, sessionId, path)` 以**该请求的 sessionId** 为 key；`unregister` 走新 sid → `_unwatchFolder(新sid)` 永远找不到 → `_watchers`/`_monitoredFolders`/`_folderWatchers` 只增不减。文件页每切目录、IdeaPills 每次 stop 都在 agent 上永久留一个 `Directory.watch` + 对旧 sid 持续推送。
复现：连切 10 个目录 → agent `_watchers` 10 项全活、推送风暴导致 host 反复 reload。

### #7 [HIGH] watcher/push 不绑 session 生命周期 → 断连后推死 socket
`lib/agent/agent_handlers.dart:324-343` + `lib/ssp/server.dart:236-239`
`_emitEvent`→`session.push`→`socket.add` 对已关 socket → unhandled async error；`_watchers` 在 `_drop`/`close` 不清，Timer 持续触发。
复现：监控目录时 host 断网 → 手机侧目录一变动 → agent 异步异常（release 下可能崩）。

### #8 [HIGH] IdeaPills 双向镜像死循环 + 单 debounce 丢事件
`lib/host/idea_pills.dart:119-168` × `:61-64`
远端事件→下载→本地 watcher→`_onLocalEvent`→上传→远端 watcher→下载… 无内容/大小比对断路器，一次写入即无限互传。`_debounce` 实例级唯一 Timer 被 `_onRemoteEvent`/`_onLocalEvent`/`_emitLocal` 共享，后事件 cancel 前事件 → 丢同步。
复现：开同步后手机侧改一个文件 → `_transfers` 不断追加同文件任务。

### #9 [HIGH] engine.dispose() 杀死共享 PushHub → 全页面推送失联
`lib/host/photo_sync.dart:167-170` + `lib/host/idea_pills.dart:197-200` + `lib/host/pages/photo_sync_page.dart:76` + `lib/host/pages/idea_pills_page.dart:85` + `lib/host/pages/host_shell.dart:39-48`
`scope.pushHub`（共享缓存实例）传入 engine；`dispose()→_hub.dispose()→_sub.cancel()` 取消 `client.pushes` → `_hubCache.hub` 仍指死 hub（getter 只在 api 换身份时重建）→ folderEvents/clipboardChanges/fileChanges 全部静默直到重连。
复现：开相册同步→停止→手机改被监控目录→文件页不再自动刷新。

### #10 [HIGH] connect() 不回收旧 client；旧连接断线信号谋杀新连接
`lib/host/host_controller_impl.dart:164-213`
再次 `connect()` 不清 `_client` → 两 socket/session 并存；旧 client 断线触发 `_onLinkDown` → 把**新** `_client/_api` 置 null + 跳 reconnecting → 自动重连在错误候选上重试。
复现：连 A → 直接点 B → B connected → A socket 超时 → 状态跳 reconnecting。

### #11 [HIGH] 运行时权限从未申请 → 真机媒体库全空
`android/app/src/main/AndroidManifest.xml:10-19` 声明 READ_MEDIA_IMAGES/VIDEO/AUDIO + MANAGE_EXTERNAL_STORAGE，但全工程 **0 处** `requestPermissions`/`ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION`（MainActivity.kt、agent_app.dart 均无）。Android 13+ MediaStore 查询返空 → 照片/音乐/视频/文件页全空 → goal.md Phase 2「存储权限申请/降级处理」未实现，真机验收必死。

### #12 [HIGH] 应用管理 wire 未接通 → 应用页永远占位
`lib/host/pages/apps_page.dart:59-63` + `MainActivity.kt:134-142` + `lib/agent/platform_contract.dart`
Kotlin `getInstalledApps/uninstallApp/exportApk` 已实现，但 `WireAppsSource.load` 直接 `const []`——无 SSP op 也没人接到 :19999 → 真机应用页永远"暂不支持"。goal.md 的应用管理项实质未交付。

### #13 [HIGH] FileChange(38) 推送无人发送 → 相册"自动同步"失效
`lib/agent/agent_handlers.dart:324-336`（唯一 push 点只发 MonitorFolderResponse/type25）× `lib/ssp/requests.dart:261-263` × `lib/host/push_hub.dart:47` × `lib/host/photo_sync.dart:79-85`
SSPFileChange 有 proto、有 decode、host 订阅 `fileChanges`，**agent 端无发送点** → `startMonitoring` 挂死流 → 只能手动 syncOnce。Kotlin MediaStore ContentObserver 到 `open_handshaker/events` 通道后也无 Dart 消费者转 SSP push → 断链点明确。

## 🟡 Medium

### #14 [MEDIUM] `_SessionQueue.next(timeout)` 超时后 waiter 不清 → 晚到响应被吞
`lib/ssp/client.dart:120-130`
`timeout()` 抛异常但 `_waiter` 仍挂着；之后 `push()` 完成死 completer → 消息丢失。handshake02 的 120s 循环（L314-330）和所有 `request()` 30s 超时路径都受影响：resp02 在超时后到达 → 被死 waiter 吃掉 → 下一轮 next() 白白再等 120s。

### #15 [MEDIUM] `_sessions`/`SessionDemux._sessions` 无界增长
`lib/ssp/client.dart:165-166,203-204` + `lib/ssp/modern_transport.dart:201-202`
每请求 allocate 新 sid，queue/reader 永不移除 → 长连接久用 map 单调膨胀；`_uploads` 同理只在 cancel 时清。

### #16 [MEDIUM] push 路径畸形包异常逃逸 `_onData`
`lib/ssp/client.dart:196-200`
`_pushDemux.addChunk`（超 maxMessage 抛 FormatException）不在 try 内 → 逃逸 stream listener → zone unhandled；`_demux` 路径有 catch。伪造长 push（push 位+len=256MB）即可。

### #17 [MEDIUM] upload 对中途截短的文件死循环
`lib/ssp/client.dart:534-555`
`while(sent<total)`，文件中途被截短 `raf.read` 返 0 → 无限发空 flag3 包。应 `if (chunk.isEmpty) break`。

### #18 [MEDIUM] `downloadTmpPath` 用 `localPath.hashCode` → 碰撞/重启失效/跨下载污染
`lib/ssp/client.dart:152-154` + `lib/host/host_controller_impl.dart:307-308`
(a) `String.hashCode` 非稳定持久 ID → 重启后续传找不到旧 .part；(b) 不同 localPath 哈希碰撞 → 并发下载共享 .part 互相污染；(c) 同 localPath 下载**不同** remotePath 时，旧 .part 的 `lengthSync` 被当 resume offset → 错位拼接 → 损坏文件当正品 rename。goal.md 说的 `.hsdownload` 命名也没实现。

### #19 [MEDIUM] download 取消 = 排干整条 wire，大文件取消"无响应"
`lib/ssp/client.dart:461-479` + `lib/host/host_controller_impl.dart:415-424`
取消后仍 `await` 收完 `expected` 全部字节才 throw —— 取消 1GB 已传 100MB → 继续下完才报 cancelled；协议有 `SSPCancelRequest`（upload 在用）却不在 download 发。`pauseTransfer` 同理排干，且只写 flag 不 publish → UI 要等下个 progress tick。

### #20 [MEDIUM] flag3 无 `session.ready` 门 + sid 可猜 → 未握手注入
`lib/ssp/server.dart:213-224` + `lib/agent/agent_handlers.dart:153-172`
`flagFileData` 直接进 handler（signed 才有 ready 校验）；sid 从 3 递增可预测 → 同 LAN 恶意端在上传进行中注入 flag3 到活跃 sid → `writeFromSync` 污染文件。

### #21 [MEDIUM] `unawaited(save())` + 非原子写 → 信任库截断归零
`lib/ssp/trust_store.dart:76-78` × `lib/ssp/server.dart:343,377` × `lib/ssp/client.dart:300,322`
`writeAsString` 非原子；多处 `unawaited(save())` 并发 → 交错写出半 JSON → `load()` 抛 → catch 静默 → 全库视为陌生 → 所有已配对设备强制重配对。应 tmp+rename+串行。

### #22 [MEDIUM] `onFileData` 同步写盘阻塞 isolate
`lib/agent/agent_handlers.dart:153-172`
`writeFromSync` 在 socket 事件回调内同步执行 → 慢盘/大块时整个 isolate 卡（所有 session、心跳、watcher 全停）。

### #23 [MEDIUM] Kotlin 专辑 ID 双命名空间
`android/MainActivity.kt:272-295`
item.albumId = 真 `BUCKET_ID`/`ALBUM_ID`；album.albumId = `name.hashCode().toLong()` → host 按 album id 聚合/过滤时对不上 → 按相册分组错位。

### #24 [MEDIUM] legacy thumbnail 对 subtype 2/3 回写错数组
`lib/agent/legacy_handlers.dart:210-223`
请求读 `videoArray`/`audioAlbumArray` 的 ids，回复却只遍历 `thumbs.imageArray`（恒空）→ 先写 `count=ids.length` 后写 0 项 → 包形畸形、host 端解析错位。legacy 路径视频/音频缩略图永远空。

### #25 [MEDIUM] pairing 对话框不随会话掉线消失 → 二次 complete 崩溃
`lib/agent_ui/agent_app.dart:131-163` × `lib/ssp/server.dart:236-239`
session `_drop` 时 completer 已 `complete(deny)`，但对话框还在；用户再点按钮 → `done.complete()` 第二次 → `StateError: Future already completed` 崩。应先判 `done.isCompleted`。

### #26 [MEDIUM] agent_app setState-after-dispose
`lib/agent_ui/agent_app.dart:50-76`
`_start`/`_stop` 多段 await 后 `setState` 无 mounted 检查（L66/69/75）→ 启动中离开页面或快速开关 → 崩。

### #27 [MEDIUM] `disconnect()` 写死 `_autoReconnect=false` 且 `connect()` 不恢复
`lib/host/host_controller_impl.dart:246-256`
手动断开后 `_autoReconnect` 永久关闭 → 之后手动重连成功、再断链不会自动重连，与 UI 语义（常开）不符。

## 🟢 Low

### #28 [LOW] `channel.close()` 异常路径跳过 `_drop(session)`
`lib/ssp/server.dart:196-198,207-208`：socket 已死时 `channel.close()`（内部 flush）再抛 → `_drop` 不执行 → `_sessions` 僵尸 + `onSessionClosed` 漏发。

### #29 [LOW] `_pendingPairings` key 语义混乱
`lib/ssp/server.dart:133,315,323`：map 以连接 id 为 key，`pendingPairing(sessionId)` 参数名误导；`firstWhere` 时序竞态可 StateError。

### #30 [LOW] host_identity.json 明文 RSA 私钥
`lib/host/host_bootstrap.dart:19-30`：modulus/d/p/q 明文落应用支持目录 → 本机任意进程可读永久冒充 host（#5 放大器）。应 chmod 600/Keychain；且任何 load 失败即整体覆盖重写，容错过激。

### #31 [LOW] manual 候选永不驱逐 + 断开后残留
`lib/host/host_controller_impl.dart:256-260,129-136`：`manual:` 前缀永不淘汰 → 手输错 IP 永久残留候选列表；`_activeCandidate` 置 null 但留列表。

### #32 [LOW] WiFi probe 只验 TCP 通
`lib/host/discovery/wifi_discovery.dart:50-58`：任何占 10086 的非 agent 服务都显示为设备 → 握手失败用户困惑。可做握手01 轻探测。

### #33 [LOW] upload 前整文件读内存
`lib/ssp/client.dart:508`：`md5Hex(await file.readAsBytes())` 大文件峰值内存，改流式 digest。

### #34 [LOW] HostScope `_hubCache` 重建泄漏 + getter 副作用
`lib/host/pages/host_shell.dart:35,39-48`：HostApp 每次 build 新 `_PushHubCache` → 旧 hub 订阅泄漏；getter 内 dispose+new 副作用脆弱。`ClipboardSync` 同样 build 内 `??` 新建 → 旧实例 timer 泄漏。

### #35 [LOW] resume 不过滤 completed/cancelled
`lib/host/host_controller_impl.dart:427-439`：`resumeTransfer` 对 completed/cancelled 任务同样重排入队 → 重下一遍（tmp 已 rename 走则 offset=0 全量重下）。UI 不暴露但 API 可误用。

### #36 [LOW] IdeaPills size-only diff + movedFrom 漏处理
`lib/host/idea_pills.dart:75-97,126-139`：等长内容变更永不双向同步；`movedFrom`(event=4) 落 default → 旧名文件残留本地。

### #37 [LOW] AgentService 半启动泄漏
`lib/agent/agent_service.dart:56-98`：`_start` 中途 bind 失败 → 已绑 socket 不回收 → retry 后旧 socket 未 close 状态半开。

### #38 [LOW] legacy listener 内抛异常逃逸
`lib/ssp/legacy_client.dart:33-44,59-75`：listener 回调内 FormatException 未捕获 → zone error（request() 的 try 只包 await 不包 listener）。

### #39 [LOW] `StreamBuffer.peek` 每帧全量拷贝
`lib/ssp/bytes.dart:63-67`：高频 chunk 下 O(backlog) 复制 → 大文件传输 CPU 浪费（性能缺陷）。

### #40 [LOW] thumbnails 混合 mediaType 只取一
`lib/agent/providers/channel_providers.dart:258-267`：一请求混合 image+video ids 只按一个 type 查 → 另一半全丢（若 host 恒分类型调用则 non-issue）。

## goal.md 对照差距

| goal.md 声明 | 实际 |
|---|---|
| Phase 2「存储权限申请/降级处理」 | ❌ 无任何 requestPermissions（#11） |
| Phase 4「应用管理（列表/卸载/导出 APK）」 | ⚠️ UI 占位 + agent 能力闲置无 wire（#12） |
| Phase 5「相册同步：新照片自动同步」 | ⚠️ FileChange(38) 无人发送，仅手动 syncOnce（#13） |
| Phase 5「MonitorFolder/FileChange 实时推送」 | ⚠️ 推送存在但注销失效+断连推死 socket（#6/#7） |
| 「.hsdownload 续传」 | ⚠️ 实现为 `systemTemp/handshaker_dl_<hashCode>.part`（#18） |
| Phase 2 验收「curl 命中 19999」 | ✅ 但端点零鉴权（#3）— 验收过、安全不过关 |

## 优先级建议

landing 前必修四件：#1（数据正确性）、#2/#3（信任与安全）、#11（真机验收必死）。
长连接可用性三连环：#6/#7/#9。
#8 IdeaPills 循环建议加"静默期+内容哈希"断路器再上线。
