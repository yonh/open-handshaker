/// Contract between the Dart agent layer and the Android platform side
/// (Kotlin). The Kotlin implementation lives under android/ and MUST match
/// these channel names and argument shapes. This file is the single source
/// of truth — keep it in sync with AndroidProviderChannel.
///
/// Channel names
/// -------------
///   open_handshaker/agent_service   start/stop foreground service + notify
///   open_handshaker/providers       media/file/app/clipboard data access
///   open_handshaker/events          EventChannel: clipboard & media changes
///
/// All MethodChannel calls below are on 'open_handshaker/providers' unless
/// noted. Each call returns a value or throws PlatformException(code,
/// message).
abstract final class AgentChannels {
  static const service = 'open_handshaker/agent_service';
  static const providers = 'open_handshaker/providers';
  static const events = 'open_handshaker/events';
}

/// Method catalog on AgentChannels.providers.
///
/// Device info:
///   'getDeviceInfo' {} -> {
///     phoneModel, phoneColor?, phoneName, productBrand,
///     productManufacturer, smartisanVersion?, phoneLocked: bool,
///     diskSize: int, usedDiskSize: int, ramSize: int,
///     batteryPercentage: int, externalStoragePath,
///     externalStoragePermission: int (0 none,1 read,2 write,3 rw),
///     extDiskSize: int, extUsedDiskSize: int, phoneId,
///     audioSize, picVideoSize, downloadSize, otherSize, appSize, cacheSize,
///     apkVersionName, apkVersionCode: int
///   }
///
/// Media libraries (photos/audio/video):
///   'getPhotoLibrary' {start:int, count:int} -> {albums:[{name,files:[F]}]}
///   'getVideoLibrary' {start:int, count:int} -> {albums:[{name,files:[F]}]}
///   'getAudioLibrary' {start:int, count:int} -> {albums:[{name,files:[F]}]}
///   F = media item map: {
///     mediaId: int, fileName, path, mimeType, fileSize: int,
///     createdTimestamp: int(sec), modifiedTimestamp: int(sec),
///     width?, height?, durationMs?, artist?, albumName?,
///     thumbnailPath?: string (a cached thumb file the host can HTTP-GET)
///   }
///   album map for photos/video groups by BUCKET_NAME; audio groups by album.
///
/// Thumbnails:
///   'getThumbnail' {ids:[int...], mediaType:int(1img/2vid/3audio)} ->
///     {thumbnails:[{mediaId:int, path:string}]}  // path = local cache file
///
/// File system (uses Storage Access Framework / MANAGE_EXTERNAL_STORAGE):
///   'listDir' {path, showHidden:bool, filterType:int, maxDepth:int,
///              onlyCount:bool} -> {files:[SSPFile-map]}
///     SSPFile-map = {path,name?,fileName?,fileSize:int,isDirectory:bool,
///                    fileType:int,mimeType,createdTimestamp,modifiedTimestamp,
///                    childrenCount:int}
///   'fileExists' {path} -> {exist:bool}
///   'fileCount' {path} -> int
///   'createFolder' {path} -> {succeed:bool}
///   'rename' {path,newName} -> {succeed:bool}
///   'delete' {path} -> {succeed:bool}
///   NOTE: pure-Dart fallback exists in files_provider.dart for paths that
///   do not need Android permissions; the channel is used only when Dart
///   File I/O fails with Permission denied.
///
/// Installed apps:
///   'getInstalledApps' {} -> [{packageName,label,versionName,versionCode,
///                             apkPath,size:int,iconPath:string}]
///     iconPath points at a PNG extracted to the app cache dir (servable
///     over the HTTP :19999 file endpoint).
///   'uninstallApp' {packageName} -> null   // launches uninstall intent
///   'exportApk' {packageName, destPath} -> {path:string}
///
/// Clipboard:
///   'getClipboard' {} -> {content:string(utf8)}  // '' when empty
///   'setClipboard' {content:string} -> null
///   EventChannel 'open_handshaker/events': emits {event:'clipboard',
///   content:string} on change and {event:'mediaChange', mediaType:int}.
///
/// Foreground service (AgentChannels.service):
///   'startService' {title, text} -> null
///   'stopService' {} -> null
///   'isServiceRunning' {} -> bool
///   Notification must use a low-importance ongoing notification channel
///   'open_handshaker_agent' ("HandShaker 守护服务").
abstract final class AgentMethods {
  static const getDeviceInfo = 'getDeviceInfo';
  static const getPhotoLibrary = 'getPhotoLibrary';
  static const getVideoLibrary = 'getVideoLibrary';
  static const getAudioLibrary = 'getAudioLibrary';
  static const getThumbnail = 'getThumbnail';
  static const listDir = 'listDir';
  static const fileExists = 'fileExists';
  static const fileCount = 'fileCount';
  static const createFolder = 'createFolder';
  static const rename = 'rename';
  static const delete = 'delete';
  static const getInstalledApps = 'getInstalledApps';
  static const uninstallApp = 'uninstallApp';
  static const exportApk = 'exportApk';
  static const getClipboard = 'getClipboard';
  static const setClipboard = 'setClipboard';
}

/// Storage permission escalation flow (called out in goal.md):
/// 1. App first requests READ_MEDIA_* / READ_EXTERNAL_STORAGE at runtime.
/// 2. For arbitrary-path file access the UI offers "管理所有文件" which
///    sends the user to ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION.
/// 3. 'externalStoragePermission' in getDeviceInfo reports the effective
///    level (SAF picker fallback when MANAGE_EXTERNAL_STORAGE is denied).
abstract final class StoragePermissionLevels {
  static const none = 0;
  static const read = 1;
  static const write = 2;
  static const readWrite = 3;
}
