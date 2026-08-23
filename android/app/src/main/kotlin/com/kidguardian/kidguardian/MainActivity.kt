package com.kidguardian.kidguardian

import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.kidguardian.kidguardian.accessibility.AppMonitorService
import com.kidguardian.kidguardian.service.MonitorForegroundService

/**
 * MainActivity — Flutter host activity (ĐÃ SỬA lỗi C1)
 *
 * THAY ĐỔI CHÍNH:
 * - Gỡ bỏ BroadcastReceiver khỏi onStart/onStop (nguyên nhân gốc của lỗi C1)
 * - BroadcastReceiver nay nằm trong MonitorForegroundService (chạy ngầm bền vững)
 * - EventSink được chia sẻ qua MonitorForegroundService.eventSink (singleton)
 * - Thêm MethodChannel handler: startMonitorService / stopMonitorService
 */
class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.kidguardian/accessibility"
    private val EVENT_CHANNEL = "com.kidguardian/accessibility_events"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Method Channel: Flutter → Native commands ──────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateBlockedApps" -> {
                        val apps = call.argument<List<String>>("apps")
                        if (apps != null) {
                            AppMonitorService.blockedApps.clear()
                            AppMonitorService.blockedApps.addAll(apps)
                            // BUG-A FIX: Persist blocked apps để khôi phục khi service restart
                            AppMonitorService.saveBlockedAppsToPrefs(this)
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGS", "Apps list is null", null)
                        }
                    }
                    "updateAppLimits" -> {
                        val limits = call.argument<Map<String, Int>>("limits")
                        if (limits != null) {
                            AppMonitorService.appLimits.clear()
                            AppMonitorService.appLimits.putAll(limits)
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGS", "Limits map is null", null)
                        }
                    }
                    "updateKeywords" -> {
                        val keywords = call.argument<List<String>>("keywords")
                        if (keywords != null) {
                            val filtered = keywords.filter { it.isNotBlank() }
                            AppMonitorService.monitoredKeywords = filtered.toSet()
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGS", "Keywords list is null", null)
                        }
                    }
                    // FIX #1+#5 Native: Cập nhật danh sách app được giám sát từ Flutter & lưu SharedPreferences
                    "updateMonitoredPackages" -> {
                        val packages = call.argument<List<String>>("packages")
                        if (packages != null) {
                            val packageSet = packages.toSet()
                            AppMonitorService.monitoredPackages = packageSet
                            getSharedPreferences("kidguardian_native_prefs", Context.MODE_PRIVATE)
                                .edit()
                                .putStringSet("monitored_packages", packageSet)
                                .apply()
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGS", "Packages list is null", null)
                        }
                    }
                    // FIX C2: Thay moveTaskToBack bằng lệnh trực tiếp qua AppMonitorService
                    "moveToHome" -> {
                        AppMonitorService.instance?.forceGoHome()
                        result.success(true)
                    }
                    // C1: Khởi động / dừng ForegroundService từ Flutter
                    "startMonitorService" -> {
                        startMonitorForegroundService()
                        result.success(true)
                    }
                    "stopMonitorService" -> {
                        stopMonitorForegroundService()
                        result.success(true)
                    }
                    "getAndClearOfflineUsageLogs" -> {
                        val prefs = getSharedPreferences("KidGuardianOfflinePrefs", Context.MODE_PRIVATE)
                        val logsSet = prefs.getStringSet("offline_usage_logs", emptySet()) ?: emptySet()
                        val logsList = logsSet.toList()
                        prefs.edit().remove("offline_usage_logs").apply()
                        result.success(logsList)
                    }
                    "isAccessibilityPermissionGranted" -> {
                        val enabledServices = Settings.Secure.getString(
                            contentResolver,
                            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
                        )
                        val isEnabled = enabledServices?.contains(packageName) == true
                        result.success(isEnabled)
                    }
                    "openAccessibilitySettings" -> {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                    // Giữ lại để không break code cũ
                    "moveTaskToBack" -> {
                        moveTaskToBack(true)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // ── Event Channel: Native → Flutter events ─────────────────────────
        // EventSink được gán vào MonitorForegroundService.eventSink để
        // ForegroundService có thể gửi events kể cả khi Activity ở nền
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    MonitorForegroundService.eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    MonitorForegroundService.eventSink = null
                }
            })
    }

    private fun startMonitorForegroundService() {
        val intent = Intent(this, MonitorForegroundService::class.java).apply {
            action = MonitorForegroundService.ACTION_START
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopMonitorForegroundService() {
        val intent = Intent(this, MonitorForegroundService::class.java).apply {
            action = MonitorForegroundService.ACTION_STOP
        }
        startService(intent)
    }
}
