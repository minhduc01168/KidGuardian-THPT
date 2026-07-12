package com.kidguardian.kidguardian.accessibility

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import kotlin.math.max
import kotlin.math.min

class AppMonitorService : AccessibilityService() {

    // Singleton instance để MainActivity có thể gọi forceGoHome() trực tiếp
    companion object {

        private const val TAG = "AppMonitorService"
        const val ACTION_APP_BLOCKED = "com.kidguardian.kidguardian.ACTION_APP_BLOCKED"
        const val ACTION_APP_EVENT = "com.kidguardian.kidguardian.ACTION_APP_EVENT"
        const val EXTRA_PACKAGE_NAME = "package_name"
        const val EXTRA_APP_NAME = "app_name"
        const val EXTRA_EVENT_TYPE = "event_type"
        const val ACTION_KEYWORD_DETECTED = "com.kidguardian.kidguardian.ACTION_KEYWORD_DETECTED"
        const val EXTRA_KEYWORD = "keyword"
        const val EXTRA_TEXT_CONTEXT = "text_context"

        // Singleton để gọi forceGoHome() từ MainActivity
        @Volatile
        var instance: AppMonitorService? = null

        private const val MAX_TREE_DEPTH = 20
        private const val KEYWORD_COOLDOWN_MS = 60_000L

        var blockedApps = mutableSetOf<String>()
        var appLimits = mutableMapOf<String, Int>()
        // FIX #1+#5 Native: Danh sách các app được phụ huynh bật giám sát.
        // Khi rỗng (chưa load), cho qua Flutter để Flutter tự filter.
        // Khi đã có data → chặn tại native, giảm tải Dart runtime.
        @Volatile
        var monitoredPackages = setOf<String>()
        @Volatile
        private var _monitoredKeywords = setOf("tự tử", "đánh nhau", "cờ bạc", "ma túy")
        var monitoredKeywords: Set<String>
            get() = _monitoredKeywords
            set(value) {
                synchronized(this) {
                    _monitoredKeywords = value.toSet()
                }
            }

        private val keywordAlertCooldown = mutableMapOf<String, Long>()
        private val cooldownLock = Any()

        private val SYSTEM_PACKAGES = setOf(
            "com.android.systemui",
            "com.google.android.googlequicksearchbox",
            "com.android.launcher",
            "com.android.launcher2",
            "com.android.launcher3",
            "com.google.android.apps.nexuslauncher",
            "com.sec.android.app.launcher",
            "com.huawei.android.launcher",
            "com.miui.home",
            "com.android.inputmethod.latin",
            "com.google.android.inputmethod.latin",
            "com.android.inputmethod.lazyswipe",
            "com.android.settings",
            "com.android.vending",
            "com.google.android.packageinstaller",
            "com.android.packageinstaller",
            "com.google.android.permissioncontroller",
            "com.android.permissioncontroller",
            "android"
        )

        private fun isSystemPackage(packageName: String): Boolean {
            if (SYSTEM_PACKAGES.contains(packageName)) return true
            if (packageName.startsWith("com.android.") && !packageName.contains("kidguardian") && !packageName.contains("chrome")) return true
            if (packageName.startsWith("com.google.android.inputmethod")) return true
            if (packageName.contains("permissioncontroller") || packageName.contains("packageinstaller")) return true
            return false
        }

        fun isOnCooldown(keyword: String, packageName: String): Boolean {
            val key = "$packageName:$keyword"
            synchronized(cooldownLock) {
                val lastAlert = keywordAlertCooldown[key] ?: return false
                return System.currentTimeMillis() - lastAlert < KEYWORD_COOLDOWN_MS
            }
        }

        fun recordKeywordAlert(keyword: String, packageName: String) {
            val key = "$packageName:$keyword"
            synchronized(cooldownLock) {
                keywordAlertCooldown[key] = System.currentTimeMillis()
            }
        }
    }

    private var currentPackageName: String? = null
    private var activeAppStartMillis: Long = 0L
    private var lastExtractedText = ""


    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return

            if (isSystemPackage(packageName)) return

            if (currentPackageName != packageName) {
                if (currentPackageName != null) {
                    val durationMs = System.currentTimeMillis() - activeAppStartMillis
                    // FIX #1+#5 Native: Chỉ lưu offline log cho monitored apps
                    val prevIsMonitored = monitoredPackages.isEmpty() || monitoredPackages.contains(currentPackageName!!)
                    if (activeAppStartMillis > 0 && durationMs >= 5000 && !isSystemPackage(currentPackageName!!) && prevIsMonitored) {
                        saveOfflineUsageLog(currentPackageName!!, activeAppStartMillis, System.currentTimeMillis(), durationMs / 1000)
                    }
                    sendAppEvent(currentPackageName!!, "closed")
                }

                currentPackageName = packageName
                activeAppStartMillis = System.currentTimeMillis()
                lastExtractedText = ""
                Log.d(TAG, "Window State Changed: $packageName")

                // FIX #1+#5 Native: Chỉ gửi 'opened' event lên Flutter cho monitored apps.
                // Nếu monitoredPackages rỗng (chưa load) → gửi tất cả, Flutter tự filter.
                val isMonitored = monitoredPackages.isEmpty() || monitoredPackages.contains(packageName)
                if (isMonitored) {
                    sendAppEvent(packageName, "opened")
                } else {
                    Log.d(TAG, "Skipping non-monitored app event (native filter): $packageName")
                }

                if (blockedApps.contains(packageName)) {
                    blockApp(packageName)
                }
            }
        } else if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED ||
                   event?.eventType == AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED) {

            val packageName = event.packageName?.toString() ?: return
            if (isSystemPackage(packageName)) return

            Log.d(TAG, "Content/Text changed in: $packageName, type: ${event.eventType}")

            val source = event.source
            val nodeToScan = source ?: rootInActiveWindow

            if (nodeToScan == null) {
                Log.d(TAG, "No source node available")
                return
            }

            try {
                val extractedText = extractTextFromNode(nodeToScan, maxDepth = MAX_TREE_DEPTH)
                Log.d(TAG, "Extracted text length: ${extractedText.length}, preview: ${extractedText.take(100)}")

                if (extractedText.isNotEmpty() && extractedText != lastExtractedText) {
                    lastExtractedText = extractedText
                    checkTextForKeywords(extractedText, packageName)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error extracting text from accessibility tree", e)
            } finally {
                source?.recycle()
            }
        }
    }

    private fun extractTextFromNode(node: AccessibilityNodeInfo?, maxDepth: Int): String {
        if (node == null || maxDepth <= 0) return ""
        val textBuilder = StringBuilder()

        if (node.text != null) {
            textBuilder.append(node.text.toString()).append(" ")
        }
        if (node.contentDescription != null) {
            textBuilder.append(node.contentDescription.toString()).append(" ")
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (child != null) {
                textBuilder.append(extractTextFromNode(child, maxDepth - 1))
                child.recycle()
            }
        }
        return textBuilder.toString()
    }

    private fun checkTextForKeywords(text: String, packageName: String) {
        val lowerText = text.lowercase()
        val keywordsSnapshot = _monitoredKeywords
        for (keyword in keywordsSnapshot) {
            if (lowerText.contains(keyword.lowercase())) {
                if (isOnCooldown(keyword, packageName)) continue
                Log.d(TAG, "Keyword detected: $keyword in app: $packageName")
                val snippet = extractSnippetAroundKeyword(text, keyword)
                sendKeywordDetectedEvent(keyword, packageName, snippet)
                recordKeywordAlert(keyword, packageName)
            }
        }
    }

    private fun extractSnippetAroundKeyword(text: String, keyword: String): String {
        val lowerText = text.lowercase()
        val lowerKeyword = keyword.lowercase()
        val index = lowerText.indexOf(lowerKeyword)
        if (index == -1) return text.take(200)
        val snippetStart = max(0, index - 50)
        val snippetEnd = min(text.length, index + keyword.length + 150)
        return text.substring(snippetStart, snippetEnd)
    }

    private fun sendKeywordDetectedEvent(keyword: String, packageName: String, contextText: String) {
        val broadcastIntent = Intent(ACTION_KEYWORD_DETECTED).apply {
            putExtra(EXTRA_KEYWORD, keyword)
            putExtra(EXTRA_PACKAGE_NAME, packageName)
            putExtra(EXTRA_TEXT_CONTEXT, contextText)
        }
        LocalBroadcastManager.getInstance(this).sendBroadcast(broadcastIntent)

        com.kidguardian.kidguardian.service.MonitorForegroundService.sendEventDirectly(mapOf(
            "type" to "keyword_detected",
            "packageName" to packageName,
            "keyword" to keyword,
            "textContext" to contextText,
        ))
    }

    private fun sendAppEvent(packageName: String, eventType: String) {
        // Dùng LocalBroadcastManager để MonitorForegroundService nhận được
        val broadcastIntent = Intent(com.kidguardian.kidguardian.service.MonitorForegroundService.ACTION_APP_EVENT).apply {
            putExtra(EXTRA_PACKAGE_NAME, packageName)
            putExtra(EXTRA_EVENT_TYPE, eventType)
        }
        LocalBroadcastManager.getInstance(this).sendBroadcast(broadcastIntent)

        // Đồng thời gửi trực tiếp lên Flutter EventSink bảo đảm 100% không rớt event
        com.kidguardian.kidguardian.service.MonitorForegroundService.sendEventDirectly(mapOf(
            "type" to "app_event",
            "packageName" to packageName,
            "appName" to packageName,
            "eventType" to eventType,
        ))
    }

    private fun saveOfflineUsageLog(packageName: String, startTimeMs: Long, endTimeMs: Long, durationSeconds: Long) {
        try {
            val prefs = getSharedPreferences("KidGuardianOfflinePrefs", Context.MODE_PRIVATE)
            val existingSet = prefs.getStringSet("offline_usage_logs", mutableSetOf()) ?: mutableSetOf()
            val newSet = mutableSetOf<String>().apply { addAll(existingSet) }
            val logJson = """{"packageName":"$packageName","startTime":$startTimeMs,"endTime":$endTimeMs,"durationSeconds":$durationSeconds}"""
            newSet.add(logJson)
            prefs.edit().putStringSet("offline_usage_logs", newSet).apply()
            Log.d(TAG, "Saved offline usage log ($durationSeconds s): $packageName")
        } catch (e: Exception) {
            Log.e(TAG, "Error saving offline usage log", e)
        }
    }

    /**
     * FIX C2: Khoá app bằng cách ép về Home Screen thực sự.
     * Trước đây dùng sendBroadcast() → KidGuardian chỉ hiện LockScreen nhưng TikTok vẫn chạy.
     * Bây giờ: performGlobalAction(HOME) → hệ điều hành ép về màn hình chính ngay lập tức.
     */
    private fun blockApp(packageName: String) {
        Log.d(TAG, "Blocking app (FIX C2): $packageName → forcing HOME")
        // 1. Ép về Home ngay lập tức
        performGlobalAction(GLOBAL_ACTION_HOME)
        // 2. Báo cho Flutter cập nhật UI (hiện LockScreen)
        val broadcastIntent = Intent(com.kidguardian.kidguardian.service.MonitorForegroundService.ACTION_APP_EVENT).apply {
            putExtra(EXTRA_PACKAGE_NAME, packageName)
            putExtra(EXTRA_EVENT_TYPE, "blocked")
        }
        LocalBroadcastManager.getInstance(this).sendBroadcast(broadcastIntent)
    }

    /**
     * Cho phép MainActivity gọi trực tiếp khi nhận lệnh moveToHome từ Flutter.
     */
    fun forceGoHome() {
        Log.d(TAG, "forceGoHome() called from MethodChannel")
        performGlobalAction(GLOBAL_ACTION_HOME)
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        val info = AccessibilityServiceInfo()
        info.eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.flags = AccessibilityServiceInfo.DEFAULT
        this.serviceInfo = info
        Log.d(TAG, "Accessibility Service Connected ✅")
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility Service Interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        if (instance == this) instance = null
    }
}
