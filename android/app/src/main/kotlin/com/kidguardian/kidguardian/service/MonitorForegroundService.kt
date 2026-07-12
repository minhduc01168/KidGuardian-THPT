package com.kidguardian.kidguardian.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.kidguardian.kidguardian.MainActivity
import com.kidguardian.kidguardian.R
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

/**
 * MonitorForegroundService — Dịch vụ nền liên tục (FIX cho lỗi C1)
 *
 * Mục đích: Giữ BroadcastReceiver sống suốt vòng đời thiết bị,
 * không bị hệ điều hành kill khi KidGuardian chạy nền.
 * Nhận broadcasts từ AppMonitorService và chuyển tiếp lên Flutter qua EventChannel.
 */
class MonitorForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "kidguardian_monitor_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START = "com.kidguardian.START_MONITOR"
        const val ACTION_STOP = "com.kidguardian.STOP_MONITOR"

        // Broadcast actions từ AppMonitorService
        const val ACTION_APP_EVENT = "com.kidguardian.APP_EVENT"
        const val ACTION_KEYWORD_DETECTED = "com.kidguardian.KEYWORD_DETECTED"
        const val EXTRA_PACKAGE_NAME = "packageName"
        const val EXTRA_APP_NAME = "appName"
        const val EXTRA_EVENT_TYPE = "eventType"
        const val EXTRA_KEYWORD = "keyword"

        private const val TAG = "MonitorFGService"

        // Singleton EventSink để giao tiếp với Flutter
        var eventSink: EventChannel.EventSink? = null

        fun sendEventDirectly(data: Map<String, Any>) {
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                eventSink?.success(data)
            }
        }
    }

    private val appEventReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                ACTION_APP_EVENT -> {
                    val packageName = intent.getStringExtra(EXTRA_PACKAGE_NAME) ?: return
                    val appName = intent.getStringExtra(EXTRA_APP_NAME) ?: packageName
                    val eventType = intent.getStringExtra(EXTRA_EVENT_TYPE) ?: "opened"
                    Log.d(TAG, "App event received: $eventType -> $packageName")
                    sendEventToFlutter(mapOf(
                        "type" to "app_event",
                        "packageName" to packageName,
                        "appName" to appName,
                        "eventType" to eventType,
                    ))
                }
                ACTION_KEYWORD_DETECTED -> {
                    val packageName = intent.getStringExtra(EXTRA_PACKAGE_NAME) ?: return
                    val keyword = intent.getStringExtra(EXTRA_KEYWORD) ?: return
                    Log.d(TAG, "Keyword detected: $keyword in $packageName")
                    sendEventToFlutter(mapOf(
                        "type" to "keyword_detected",
                        "packageName" to packageName,
                        "keyword" to keyword,
                    ))
                }
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        registerReceivers()
        Log.i(TAG, "MonitorForegroundService created ✅")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
            else -> {
                startForeground(NOTIFICATION_ID, buildNotification())
                Log.i(TAG, "MonitorForegroundService started in foreground ✅")
            }
        }
        // START_STICKY: hệ điều hành tự restart service nếu bị kill
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceivers()
        eventSink = null
        Log.i(TAG, "MonitorForegroundService destroyed")
    }

    private fun registerReceivers() {
        val filter = IntentFilter().apply {
            addAction(ACTION_APP_EVENT)
            addAction(ACTION_KEYWORD_DETECTED)
        }
        LocalBroadcastManager.getInstance(this).registerReceiver(appEventReceiver, filter)
    }

    private fun unregisterReceivers() {
        try {
            LocalBroadcastManager.getInstance(this).unregisterReceiver(appEventReceiver)
        } catch (e: Exception) {
            Log.w(TAG, "Receiver already unregistered: ${e.message}")
        }
    }

    private fun sendEventToFlutter(data: Map<String, Any>) {
        sendEventDirectly(data)
    }

    private fun buildNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Kura đang bảo vệ")
            .setContentText("Đang giám sát thiết bị của bé 🛡️")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setSilent(true)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Kura Monitor",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Dịch vụ giám sát nền của Kura"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}
