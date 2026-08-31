package com.kidguardian.kidguardian.accessibility

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Toast
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.kidguardian.kidguardian.R
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
        // GAP Fix: Nâng Cooldown từ 1 phút lên 5 phút để tránh cạn kiệt Firestore Writes Quota
        private const val KEYWORD_COOLDOWN_MS = 300_000L

        var blockedApps = mutableSetOf<String>()
        var appLimits = mutableMapOf<String, Int>()
        // FIX #1+#5 Native: Danh sách các app được phụ huynh bật giám sát (Closed-by-default).
        @Volatile
        var monitoredPackages = setOf<String>()

        fun loadMonitoredPackagesFromPrefs(context: Context) {
            val prefs = context.getSharedPreferences("kidguardian_native_prefs", Context.MODE_PRIVATE)
            val savedSet = prefs.getStringSet("monitored_packages", null)
            if (savedSet != null) {
                monitoredPackages = savedSet.toSet()
                android.util.Log.d("AppMonitorService", "Loaded ${monitoredPackages.size} monitored packages from SharedPreferences")
            }
        }

        // BUG-A FIX: Persist và restore blockedApps qua SharedPreferences
        // Đảm bảo danh sách chặn không bị reset khi AccessibilityService restart
        private const val KEY_BLOCKED_APPS = "blocked_apps"

        fun saveBlockedAppsToPrefs(context: Context) {
            val prefs = context.getSharedPreferences("kidguardian_native_prefs", Context.MODE_PRIVATE)
            prefs.edit().putStringSet(KEY_BLOCKED_APPS, blockedApps.toSet()).apply()
            android.util.Log.d("AppMonitorService", "Saved ${blockedApps.size} blocked apps to SharedPreferences")
        }

        fun loadBlockedAppsFromPrefs(context: Context) {
            val prefs = context.getSharedPreferences("kidguardian_native_prefs", Context.MODE_PRIVATE)
            val savedSet = prefs.getStringSet(KEY_BLOCKED_APPS, null)
            if (savedSet != null) {
                blockedApps.clear()
                blockedApps.addAll(savedSet)
                android.util.Log.d("AppMonitorService", "Restored ${blockedApps.size} blocked apps from SharedPreferences: $savedSet")
            }
        }

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
            // BUG-1 FIX: ĐÃ XÓA com.google.android.googlequicksearchbox
            // App này cần được giám sát keyword vì là Google Search mặc định
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

        /** Trả về giá trị cooldown hiện tại — dùng để Unit Test có thể verify */
        fun getCooldownMs(): Long = KEYWORD_COOLDOWN_MS

        /** Chỉ dùng trong Unit Test — xóa toàn bộ cooldown state */
        fun clearCooldownsForTest() {
            synchronized(cooldownLock) {
                keywordAlertCooldown.clear()
            }
        }
    }

    private var currentPackageName: String? = null
    private var activeAppStartMillis: Long = 0L
    private var lastExtractedText = ""
    // FIX: Đã gỡ bỏ blockOverlayView và windowManager (Native Overlay rác)

    // ── Midnight Rollover Fix ─────────────────────────────────────────────────
    // Handler kiểm tra định kỳ mỗi 30 giây xem trẻ có đang dùng app bị chặn không.
    // Giải quyết kịch bản: trẻ mở app lúc 23:59, đến 00:00 vào khung giờ cấm
    // nhưng AccessibilityService không có event mới → app không bị văng ra.
    private val midnightCheckHandler = Handler(Looper.getMainLooper())
    private val CHECK_INTERVAL_MS = 30_000L // 30 giây

    private val midnightRolloverRunnable = object : Runnable {
        override fun run() {
            val pkg = currentPackageName
            if (pkg != null && blockedApps.contains(pkg)) {
                Log.d(TAG, "[MidnightRollover] App $pkg vẫn đang mở trong khung giờ cấm → kích hoạt block")
                blockApp(pkg)
            }
            // Lên lịch lại lần kiểm tra tiếp theo
            midnightCheckHandler.postDelayed(this, CHECK_INTERVAL_MS)
        }
    }

    /** Phơi ra để Unit Test có thể kiểm tra logic rollover */
    fun getCheckIntervalMs(): Long = CHECK_INTERVAL_MS

    /**
     * Giả lập việc kiểm tra rollover để Unit Test không cần đợi 30 giây.
     * Trả về true nếu đã kích hoạt block, false nếu không cần.
     */
    fun checkAndBlockIfNeeded(): Boolean {
        val pkg = currentPackageName
        return if (pkg != null && blockedApps.contains(pkg)) {
            blockApp(pkg)
            true
        } else {
            false
        }
    }




    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return

            // BUG-B FIX: Không bao giờ tự chặn chính app KidGuardian
            if (packageName == applicationContext.packageName) return

            val isSystem = isSystemPackage(packageName)

            if (currentPackageName != packageName) {
                if (currentPackageName != null) {
                    val durationMs = System.currentTimeMillis() - activeAppStartMillis
                    // FIX #1+#5 Native: Lưu offline log cho monitored apps (Nếu rỗng → theo dõi tất cả user apps)
                    val prevIsMonitored = monitoredPackages.isEmpty() || monitoredPackages.contains(currentPackageName!!)
                    val prevIsSystem = isSystemPackage(currentPackageName!!)
                    if (activeAppStartMillis > 0 && durationMs >= 5000 && !prevIsSystem && prevIsMonitored) {
                        saveOfflineUsageLog(currentPackageName!!, activeAppStartMillis, System.currentTimeMillis(), durationMs / 1000)
                    }
                    if (prevIsMonitored && !prevIsSystem) {
                        sendAppEvent(currentPackageName!!, "closed")
                    }
                }

                currentPackageName = packageName
                activeAppStartMillis = System.currentTimeMillis()
                lastExtractedText = ""
                Log.d(TAG, "Window State Changed: $packageName")

                if (!isSystem) {
                    // FIX #1+#5 Native: Gửi 'opened' event lên Flutter (Nếu rỗng → theo dõi tất cả user apps).
                    val isMonitored = monitoredPackages.isEmpty() || monitoredPackages.contains(packageName)
                    if (isMonitored) {
                        sendAppEvent(packageName, "opened")
                    } else {
                        Log.d(TAG, "Skipping non-monitored app event (native filter): $packageName")
                    }

                    if (blockedApps.contains(packageName)) {
                        blockApp(packageName)
                    }

                    // BUG-1 FIX: Với Chrome và Google Search, scan URL bar khi app mở
                    // vì TYPE_VIEW_TEXT_CHANGED không fire cho address bar
                    if (packageName == "com.android.chrome" || packageName == "com.google.android.googlequicksearchbox") {
                        val root = rootInActiveWindow
                        if (root != null) {
                            val query = extractBrowserSearchQuery(root)
                            if (!query.isNullOrBlank() && query != lastExtractedText) {
                                lastExtractedText = query
                                checkTextForKeywords(query, packageName)
                            }
                            root.recycle()
                        }
                    }
                }
            }
        } else if (event?.eventType == AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED) {
            val packageName = event.packageName?.toString() ?: return
            // GAP Fix: Chỉ theo dõi text trên Chrome và Google Search, KHÔNG giám sát các app khác
            val isKeywordMonitorTarget = packageName == "com.android.chrome" ||
                    packageName == "com.google.android.googlequicksearchbox"
            if (!isKeywordMonitorTarget) return

            val source = event.source
            if (source == null) return

            try {
                val extractedText = extractTextFromNode(source, maxDepth = 3)
                if (extractedText.isNotBlank() && extractedText != lastExtractedText) {
                    lastExtractedText = extractedText
                    checkTextForKeywords(extractedText, packageName)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error extracting text from input source", e)
            } finally {
                source.recycle()
            }
        } else if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) {
            // GAP Fix: Chỉ xử lý Chrome và Google Search — tự động lọc bỏ tất cả app khác
            val packageName = event.packageName?.toString() ?: return
            val isKeywordMonitorTarget = packageName == "com.android.chrome" ||
                    packageName == "com.google.android.googlequicksearchbox"
            if (!isKeywordMonitorTarget) return

            val source = event.source ?: return
            val className = source.className?.toString() ?: ""
            if (className.contains("EditText", ignoreCase = true) || className.contains("Search", ignoreCase = true)) {
                try {
                    val extractedText = extractTextFromNode(source, maxDepth = 3)
                    if (extractedText.isNotBlank() && extractedText != lastExtractedText) {
                        lastExtractedText = extractedText
                        checkTextForKeywords(extractedText, packageName)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error extracting text from content change node", e)
                } finally {
                    source.recycle()
                }
            } else {
                // BUG-1 FIX: Với Chrome, thử lấy URL/search query từ address bar
                // kể cả khi class không phải EditText
                if (packageName == "com.android.chrome") {
                    try {
                        val query = extractBrowserSearchQuery(source)
                        if (!query.isNullOrBlank() && query != lastExtractedText) {
                            lastExtractedText = query
                            checkTextForKeywords(query, packageName)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error extracting Chrome URL bar text", e)
                    } finally {
                        source.recycle()
                    }
                } else {
                    source.recycle()
                }
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

    // BUG-1 FIX: Lấy search query từ Chrome/Google Search address bar
    // bằng cách tìm kiếm theo resource ID của các node phổ biến
    private fun extractBrowserSearchQuery(rootNode: AccessibilityNodeInfo?): String? {
        if (rootNode == null) return null
        val knownUrlBarIds = listOf(
            "com.android.chrome:id/url_bar",
            "com.android.chrome:id/search_box_text",
            "org.chromium.chrome:id/url_bar",
            "com.google.android.googlequicksearchbox:id/search_box_text",
            "com.google.android.googlequicksearchbox:id/text"
        )
        for (resourceId in knownUrlBarIds) {
            try {
                val nodes = rootNode.findAccessibilityNodeInfosByViewId(resourceId)
                if (nodes != null && nodes.isNotEmpty()) {
                    val text = nodes.first().text?.toString()
                    nodes.forEach { it.recycle() }
                    if (!text.isNullOrBlank()) return text
                }
            } catch (e: Exception) {
                Log.w(TAG, "extractBrowserSearchQuery error for $resourceId: ${e.message}")
            }
        }
        return null
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
     * FIX: Khoá app bằng cách ép về Home Screen và hiện Toast.
     * BUG-2 FIX: Self-exclusion guard — KidGuardian KHÔNG BAO GIỜ tự chặn chính mình.
     */
    private fun blockApp(packageName: String) {
        // BUG-2 FIX: Bảo vệ tuyệt đối — không chặn chính KidGuardian app ở tầng native
        if (packageName == "com.kidguardian.kidguardian" || packageName.isBlank()) {
            Log.w(TAG, "blockApp() — Bỏ qua self-block cho: $packageName")
            return
        }
        
        Log.d(TAG, "blockApp() — Kicked to Home: $packageName")
        // 1. Ép về Home ngay lập tức để cắt truy cập
        performGlobalAction(GLOBAL_ACTION_HOME)
        
        // 2. Hiện thông báo ngắn gọn cho trẻ
        Toast.makeText(this, "Đã hết thời gian sử dụng ứng dụng này!", Toast.LENGTH_SHORT).show()
        
        // 3. Báo cho Flutter cập nhật UI (hiện LockScreen) qua LocalBroadcast
        val broadcastIntent = Intent(com.kidguardian.kidguardian.service.MonitorForegroundService.ACTION_APP_EVENT).apply {
            putExtra(EXTRA_PACKAGE_NAME, packageName)
            putExtra(EXTRA_EVENT_TYPE, "blocked")
        }
        LocalBroadcastManager.getInstance(this).sendBroadcast(broadcastIntent)
        
        // 4. Forward trực tiếp lên Flutter EventSink
        com.kidguardian.kidguardian.service.MonitorForegroundService.sendEventDirectly(mapOf(
            "type" to "app_event",
            "packageName" to packageName,
            "appName" to packageName,
            "eventType" to "blocked",
        ))
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
        loadMonitoredPackagesFromPrefs(this)
        // BUG-A FIX: Khôi phục danh sách ứng dụng bị chặn sau khi service restart
        loadBlockedAppsFromPrefs(this)
        val info = AccessibilityServiceInfo()
        info.eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.flags = AccessibilityServiceInfo.DEFAULT
        this.serviceInfo = info
        // Midnight Rollover Fix: Bắt đầu vòng kiểm tra định kỳ
        midnightCheckHandler.postDelayed(midnightRolloverRunnable, CHECK_INTERVAL_MS)
        Log.d(TAG, "Accessibility Service Connected ✅ (blocked: ${blockedApps.size} apps, rollover check: every ${CHECK_INTERVAL_MS/1000}s)")
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility Service Interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        // Midnight Rollover Fix: Dừng handler để tránh memory leak
        midnightCheckHandler.removeCallbacks(midnightRolloverRunnable)
        if (instance == this) instance = null
    }
}
