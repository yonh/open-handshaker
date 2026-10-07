package dev.openhandshaker.handshaker_open

import android.app.ActivityManager
import android.app.KeyguardManager
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.database.ContentObserver
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.StatFs
import android.provider.MediaStore
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

/// Android platform side of the contract in lib/agent/platform_contract.dart.
/// Channel names and map keys MUST match the Dart call sites in
/// lib/agent/providers/channel_providers.dart.
class MainActivity : FlutterActivity() {

    private val channelProviders = "open_handshaker/providers"
    private val channelService = "open_handshaker/agent_service"
    private val channelEvents = "open_handshaker/events"

    private var eventSink: EventChannel.EventSink? = null
    private var mediaObserver: ContentObserver? = null
    private var clipListener: ClipboardManager.OnPrimaryClipChangedListener? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, channelProviders
        ).setMethodCallHandler { call, result ->
            try {
                handleProvider(call, result)
            } catch (t: Throwable) {
                result.error(t.javaClass.simpleName, t.message, null)
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, channelService
        ).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "startService" -> {
                        AgentForegroundService.start(
                            this,
                            call.argument<String>("title") ?: "HandShaker",
                            call.argument<String>("text") ?: "互联服务运行中"
                        )
                        result.success(null)
                    }
                    "stopService" -> {
                        AgentForegroundService.stop(this)
                        result.success(null)
                    }
                    "isServiceRunning" ->
                        result.success(AgentForegroundService.running)
                    else -> result.notImplemented()
                }
            } catch (t: Throwable) {
                result.error(t.javaClass.simpleName, t.message, null)
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger, channelEvents
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(args: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                registerObservers()
            }

            override fun onCancel(args: Any?) {
                unregisterObservers()
                eventSink = null
            }
        })
    }

    // ---------------- providers ----------------

    private fun handleProvider(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getDeviceInfo" -> result.success(deviceInfo())
            "getPhotoLibrary" ->
                result.success(mediaLibrary(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, call, 1))
            "getVideoLibrary" ->
                result.success(mediaLibrary(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, call, 2))
            "getAudioLibrary" ->
                result.success(mediaLibrary(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, call, 3))
            "getThumbnail" -> result.success(thumbnails(call))
            "listDir" -> result.success(listDir(call))
            "fileExists" -> result.success(
                mapOf("exist" to File(call.argument<String>("path") ?: "").exists())
            )
            "fileCount" -> result.success(
                File(call.argument<String>("path") ?: "")
                    .walkTopDown().count().let { it - 1 }
            )
            "createFolder" -> result.success(
                mapOf("succeed" to File(call.argument<String>("path") ?: "")
                    .mkdirs().let { it || File(call.argument<String>("path") ?: "").exists() })
            )
            "rename" -> result.success(mapOf("succeed" to run {
                val f = File(call.argument<String>("path") ?: "")
                val name = call.argument<String>("newName") ?: ""
                f.renameTo(File(f.parentFile, name))
            }))
            "delete" -> result.success(
                mapOf("succeed" to File(call.argument<String>("path") ?: "")
                    .deleteRecursively())
            )
            "getInstalledApps" -> result.success(installedApps())
            "uninstallApp" -> {
                val pkg = call.argument<String>("packageName") ?: ""
                val i = Intent(Intent.ACTION_DELETE, Uri.parse("package:$pkg"))
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(i)
                result.success(null)
            }
            "exportApk" -> result.success(exportApk(call))
            "getClipboard" -> result.success(
                mapOf("content" to clipboardText())
            )
            "setClipboard" -> {
                val cm = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                cm.setPrimaryClip(
                    ClipData.newPlainText(
                        "handshaker", call.argument<String>("content") ?: ""
                    )
                )
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun deviceInfo(): Map<String, Any?> {
        val pm = packageManager
        val actManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val mem = ActivityManager.MemoryInfo().also { actManager.getMemoryInfo(it) }
        val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val ext = Environment.getExternalStorageDirectory()
        val stat = StatFs(ext.absolutePath)
        val pInfo = pm.getPackageInfo(packageName, 0)
        val km = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        val readGranted = if (Build.VERSION.SDK_INT >= 33) {
            checkSelfPermission(android.Manifest.permission.READ_MEDIA_IMAGES) ==
                PackageManager.PERMISSION_GRANTED
        } else {
            checkSelfPermission(android.Manifest.permission.READ_EXTERNAL_STORAGE) ==
                PackageManager.PERMISSION_GRANTED
        }
        val manageGranted = Build.VERSION.SDK_INT >= 30 &&
            Environment.isExternalStorageManager()
        val perm = when {
            manageGranted -> 3
            readGranted -> 1
            else -> 0
        }
        val deviceName = try {
            Settings.Global.getString(contentResolver, "device_name")
                ?: Settings.Secure.getString(contentResolver, "bluetooth_name")
                ?: Build.MODEL
        } catch (_: Throwable) {
            Build.MODEL
        }
        return mapOf(
            "phoneModel" to Build.MODEL,
            "phoneColor" to "",
            "phoneName" to deviceName,
            "productBrand" to Build.BRAND,
            "productManufacturer" to Build.MANUFACTURER,
            "smartisanVersion" to "",
            "phoneLocked" to km.isDeviceLocked,
            "diskSize" to stat.totalBytes,
            "usedDiskSize" to (stat.totalBytes - stat.availableBytes),
            "ramSize" to mem.totalMem,
            "batteryPercentage" to bm.getIntProperty(
                BatteryManager.BATTERY_PROPERTY_CAPACITY
            ),
            "externalStoragePath" to ext.absolutePath,
            "externalStoragePermission" to perm,
            "extDiskSize" to 0L,
            "extUsedDiskSize" to 0L,
            "phoneId" to Settings.Secure.getString(
                contentResolver, Settings.Secure.ANDROID_ID
            ),
            "audioSize" to 0L, "picVideoSize" to 0L, "downloadSize" to 0L,
            "otherSize" to 0L, "appSize" to 0L, "cacheSize" to cacheDir.length(),
            "apkVersionName" to pInfo.versionName,
            "apkVersion" to if (Build.VERSION.SDK_INT >= 28)
                pInfo.longVersionCode else @Suppress("DEPRECATION") pInfo.versionCode.toLong(),
            "apkVersionCode" to if (Build.VERSION.SDK_INT >= 28)
                pInfo.longVersionCode else @Suppress("DEPRECATION") pInfo.versionCode.toLong()
        )
    }

    private fun mediaLibrary(
        uri: Uri, call: MethodCall, mediaType: Int
    ): Map<String, Any?> {
        val start = call.argument<Int>("start") ?: 0
        val count = call.argument<Int>("count") ?: Int.MAX_VALUE
        val albums = LinkedHashMap<String, MutableList<Map<String, Any?>>>()
        val baseCols = mutableListOf(
            MediaStore.MediaColumns._ID,
            MediaStore.MediaColumns.DISPLAY_NAME,
            MediaStore.MediaColumns.DATA,
            MediaStore.MediaColumns.MIME_TYPE,
            MediaStore.MediaColumns.SIZE,
            MediaStore.MediaColumns.DATE_ADDED,
            MediaStore.MediaColumns.DATE_MODIFIED,
            MediaStore.MediaColumns.TITLE,
        )
        // 音频表没有 WIDTH/HEIGHT/BUCKET 列，分开拼 projection 防止
        // 部分 ROM 的 provider 对未知列报错。
        if (mediaType == 3) {
            baseCols += MediaStore.Audio.AudioColumns.ALBUM
            baseCols += MediaStore.Audio.AudioColumns.ALBUM_ID
            baseCols += MediaStore.Audio.AudioColumns.ARTIST
            baseCols += MediaStore.Audio.AudioColumns.DURATION
        } else {
            baseCols += MediaStore.MediaColumns.BUCKET_DISPLAY_NAME
            baseCols += MediaStore.MediaColumns.BUCKET_ID
            baseCols += MediaStore.MediaColumns.WIDTH
            baseCols += MediaStore.MediaColumns.HEIGHT
            baseCols += MediaStore.MediaColumns.DURATION
        }
        contentResolver.query(
            uri, baseCols.toTypedArray(), null, null,
            "${MediaStore.MediaColumns.DATE_MODIFIED} DESC"
        )?.use { c ->
            var idx = 0
            var taken = 0
            while (c.moveToNext() && taken < count) {
                if (idx++ < start) continue
                taken++
                fun col(n: String): Int = c.getColumnIndex(n)
                fun str(n: String): String =
                    col(n).takeIf { it >= 0 }?.let { c.getString(it) } ?: ""
                fun lng(n: String): Long =
                    col(n).takeIf { it >= 0 }?.let { c.getLong(it) } ?: 0L
                val bucket = if (mediaType == 3)
                    str(MediaStore.Audio.AudioColumns.ALBUM).ifEmpty { "音乐" }
                else
                    str(MediaStore.MediaColumns.BUCKET_DISPLAY_NAME)
                        .ifEmpty { "其他" }
                val albumIdCol = if (mediaType == 3)
                    MediaStore.Audio.AudioColumns.ALBUM_ID
                else MediaStore.MediaColumns.BUCKET_ID
                val item = mutableMapOf<String, Any?>(
                    "mediaId" to lng(MediaStore.MediaColumns._ID),
                    "fileName" to str(MediaStore.MediaColumns.DISPLAY_NAME),
                    "path" to str(MediaStore.MediaColumns.DATA),
                    "mimeType" to str(MediaStore.MediaColumns.MIME_TYPE),
                    "fileSize" to lng(MediaStore.MediaColumns.SIZE),
                    "createdTimestamp" to lng(MediaStore.MediaColumns.DATE_ADDED),
                    "modifiedTimestamp" to lng(MediaStore.MediaColumns.DATE_MODIFIED),
                    "width" to lng(MediaStore.MediaColumns.WIDTH),
                    "height" to lng(MediaStore.MediaColumns.HEIGHT),
                    "durationMs" to lng(MediaStore.MediaColumns.DURATION),
                    "title" to str(MediaStore.MediaColumns.TITLE),
                    "albumName" to bucket,
                    "albumId" to lng(albumIdCol),
                    "artist" to if (mediaType == 3)
                        str(MediaStore.Audio.AudioColumns.ARTIST) else "",
                )
                albums.getOrPut(bucket) { mutableListOf() }.add(item)
            }
        }
        return mapOf("albums" to albums.map { (name, files) ->
            mapOf("name" to name, "albumId" to name.hashCode().toLong(),
                "path" to "", "files" to files)
        })
    }

    private fun thumbnails(call: MethodCall): Map<String, Any?> {
        val ids = call.argument<List<Int>>("ids") ?: emptyList()
        val mediaType = call.argument<Int>("mediaType") ?: 1
        val out = mutableListOf<Map<String, Any?>>()
        val dir = File(cacheDir, "thumbnails").apply { mkdirs() }
        for (id in ids) {
            val bmp: Bitmap? = when (mediaType) {
                1 -> thumbnailFromUri(
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)
                2 -> thumbnailFromUri(
                    MediaStore.Video.Media.EXTERNAL_CONTENT_URI, id)
                else -> audioAlbumArt(id.toLong())
            }
            if (bmp != null) {
                val f = File(dir, "$id.png")
                FileOutputStream(f).use {
                    bmp.compress(Bitmap.CompressFormat.PNG, 90, it)
                }
                val bytes = FileInputStream(f).readBytes()
                out.add(mapOf("mediaId" to id, "path" to f.absolutePath,
                    "bytes" to bytes))
            }
        }
        return mapOf("thumbnails" to out)
    }

    private fun thumbnailFromUri(base: Uri, id: Int): Bitmap? {
        val uri = Uri.withAppendedPath(base, id.toString())
        return try {
            if (Build.VERSION.SDK_INT >= 29) {
                contentResolver.loadThumbnail(
                    uri, android.util.Size(256, 256), null)
            } else {
                MediaStore.Images.Thumbnails.getThumbnail(
                    contentResolver, id.toLong(),
                    MediaStore.Images.Thumbnails.MINI_KIND, null)
            }
        } catch (_: Throwable) {
            null
        }
    }

    private fun audioAlbumArt(albumId: Long): Bitmap? {
        return try {
            val retriever = MediaMetadataRetriever()
            val uri = Uri.withAppendedPath(
                MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI, albumId.toString())
            retriever.setDataSource(this, uri)
            val pic = retriever.embeddedPicture
            retriever.release()
            pic?.let {
                android.graphics.BitmapFactory.decodeByteArray(it, 0, it.size)
            }
        } catch (_: Throwable) {
            null
        }
    }

    private fun listDir(call: MethodCall): Map<String, Any?> {
        val path = call.argument<String>("path") ?: ""
        val showHidden = call.argument<Boolean>("showHidden") ?: false
        val maxDepth = call.argument<Int>("maxDepth") ?: 1
        val root = File(path)
        val files = mutableListOf<Map<String, Any?>>()
        if (root.exists()) {
            root.walkTopDown().maxDepth(maxDepth).forEach { f ->
                if (f == root) return@forEach
                if (!showHidden && f.name.startsWith(".")) return@forEach
                files.add(mapOf(
                    "path" to f.absolutePath,
                    "fileName" to f.name,
                    "name" to f.name,
                    "fileSize" to if (f.isFile) f.length() else 0L,
                    "isDirectory" to f.isDirectory,
                    "fileType" to if (f.isDirectory) 2 else 0,
                    "mimeType" to mimeFor(f),
                    "createdTimestamp" to f.lastModified() / 1000,
                    "modifiedTimestamp" to f.lastModified() / 1000,
                    "childrenCount" to
                        (f.listFiles()?.size ?: 0)
                ))
            }
        }
        return mapOf("files" to files)
    }

    private fun mimeFor(f: File): String {
        if (f.isDirectory) return ""
        val ext = f.extension.lowercase()
        return mapOf(
            "jpg" to "image/jpeg", "jpeg" to "image/jpeg",
            "png" to "image/png", "gif" to "image/gif",
            "webp" to "image/webp", "mp4" to "video/mp4",
            "mkv" to "video/x-matroska", "mp3" to "audio/mpeg",
            "m4a" to "audio/mp4", "flac" to "audio/flac",
            "txt" to "text/plain", "md" to "text/markdown",
            "pdf" to "application/pdf", "apk" to
                "application/vnd.android.package-archive",
            "zip" to "application/zip"
        )[ext] ?: "application/octet-stream"
    }

    private fun installedApps(): List<Map<String, Any?>> {
        val pm = packageManager
        val iconDir = File(cacheDir, "icons").apply { mkdirs() }
        return pm.getInstalledApplications(PackageManager.GET_META_DATA)
            .mapNotNull { app ->
                try {
                    val info = pm.getPackageInfo(app.packageName, 0)
                    val iconFile = File(iconDir, "${app.packageName}.png")
                    if (!iconFile.exists()) {
                        drawableToBitmap(app.loadIcon(pm))?.let { bmp ->
                            FileOutputStream(iconFile).use {
                                bmp.compress(Bitmap.CompressFormat.PNG, 100, it)
                            }
                        }
                    }
                    mapOf(
                        "packageName" to app.packageName,
                        "label" to app.loadLabel(pm).toString(),
                        "versionName" to (info.versionName ?: ""),
                        "versionCode" to (if (Build.VERSION.SDK_INT >= 28)
                            info.longVersionCode
                        else @Suppress("DEPRECATION") info.versionCode.toLong()),
                        "apkPath" to app.sourceDir,
                        "size" to File(app.sourceDir).length(),
                        "iconPath" to
                            if (iconFile.exists()) iconFile.absolutePath else ""
                    )
                } catch (_: Throwable) {
                    null
                }
            }
    }

    private fun drawableToBitmap(d: Drawable): Bitmap? {
        if (d is BitmapDrawable && d.bitmap != null) return d.bitmap
        val w = d.intrinsicWidth.takeIf { it > 0 } ?: 96
        val h = d.intrinsicHeight.takeIf { it > 0 } ?: 96
        return try {
            val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bmp)
            d.setBounds(0, 0, w, h)
            d.draw(canvas)
            bmp
        } catch (_: Throwable) {
            null
        }
    }

    private fun exportApk(call: MethodCall): Map<String, Any?> {
        val pkg = call.argument<String>("packageName") ?: ""
        val dest = call.argument<String>("destPath") ?: ""
        val src = packageManager.getApplicationInfo(pkg, 0).sourceDir
        FileInputStream(src).use { inp ->
            File(dest).parentFile?.mkdirs()
            FileOutputStream(dest).use { out -> inp.copyTo(out) }
        }
        return mapOf("path" to dest)
    }

    private fun clipboardText(): String {
        val cm = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = cm.primaryClip
        return clip?.takeIf { it.itemCount > 0 }
            ?.getItemAt(0)?.coerceToText(this)?.toString() ?: ""
    }

    // ---------------- events ----------------

    private fun registerObservers() {
        val handler = Handler(Looper.getMainLooper())
        if (mediaObserver == null) {
            val obs = object : ContentObserver(handler) {
                override fun onChange(selfChange: Boolean, uri: Uri?) {
                    val t = when {
                        uri.toString()
                            .contains("images") -> 1
                        uri.toString()
                            .contains("video") -> 2
                        else -> 3
                    }
                    eventSink?.success(
                        mapOf("event" to "mediaChange", "mediaType" to t))
                }
            }
            contentResolver.registerContentObserver(
                MediaStore.EXTERNAL_CONTENT_URI, true, obs)
            mediaObserver = obs
        }
        if (clipListener == null) {
            val cm = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            val l = ClipboardManager.OnPrimaryClipChangedListener {
                eventSink?.success(mapOf(
                    "event" to "clipboard",
                    "content" to clipboardText()))
            }
            cm.addPrimaryClipChangedListener(l)
            clipListener = l
        }
    }

    private fun unregisterObservers() {
        mediaObserver?.let { contentResolver.unregisterContentObserver(it) }
        mediaObserver = null
        clipListener?.let {
            (getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager)
                .removePrimaryClipChangedListener(it)
        }
        clipListener = null
    }
}
