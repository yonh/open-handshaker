package dev.openhandshaker.handshaker_open

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager

/// Foreground service keeping the SSP/HTTP agent daemon alive while the app
/// is in the background. Contract: lib/agent/platform_contract.dart.
class AgentForegroundService : Service() {

    companion object {
        const val channelId = "open_handshaker_agent"
        const val notificationId = 0x4853 // 'HS'
        const val extraTitle = "title"
        const val extraText = "text"
        @Volatile var running = false
            private set

        fun start(context: Context, title: String, text: String) {
            val i = Intent(context, AgentForegroundService::class.java)
                .putExtra(extraTitle, title)
                .putExtra(extraText, text)
            if (Build.VERSION.SDK_INT >= 26) {
                context.startForegroundService(i)
            } else {
                context.startService(i)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, AgentForegroundService::class.java))
        }
    }

    private var wakeLock: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val title = intent?.getStringExtra(extraTitle) ?: "HandShaker"
        val text = intent?.getStringExtra(extraText) ?: "互联服务运行中"
        createChannel()
        startForeground(notificationId, buildNotification(title, text))
        acquireWakeLock()
        running = true
        return START_STICKY
    }

    override fun onDestroy() {
        running = false
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
        super.onDestroy()
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= 26) {
            val ch = NotificationChannel(
                channelId,
                "HandShaker 守护服务",
                NotificationManager.IMPORTANCE_LOW
            ).apply { setShowBadge(false) }
            getSystemService(NotificationManager::class.java)
                ?.createNotificationChannel(ch)
        }
    }

    private fun buildNotification(title: String, text: String): Notification {
        val launch = packageManager.getLaunchIntentForPackage(packageName)
        val pi = PendingIntent.getActivity(
            this, 0, launch,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        return if (Build.VERSION.SDK_INT >= 26) {
            Notification.Builder(this, channelId)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(applicationInfo.icon)
            .setContentIntent(pi)
            .setOngoing(true)
            .build()
    }

    private fun acquireWakeLock() {
        if (wakeLock == null) {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK, "open_handshaker:agent"
            ).apply { setReferenceCounted(false); acquire() }
        }
    }
}
