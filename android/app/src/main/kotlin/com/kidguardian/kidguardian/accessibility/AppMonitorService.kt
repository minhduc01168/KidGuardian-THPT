package com.kidguardian.kidguardian.accessibility

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.provider.Settings
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.TextView
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
        private const val KEYWORD_COOLDOWN_MS = 60_000L

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
    }

    private var currentPackageName: String? = null
    private var activeAppStartMillis: Long = 0L
    private var lastExtractedText = ""
    // BUG-2 FIX: Native overlay view được quản lý bởi WindowManager
    private var blockOverlayView: View? = null
    private val windowManager: WindowManager by lazy {
        getSystemService(Context.WINDOW_SERVICE) as WindowManager
    }

    // BUG-2 FIX: Hiển overlay đè lên app bị chặn — độc lập với Flutter UI
    private fun showNativeBlockOverlay(packageName: String) {
        if (!Settings.canDrawOverlays(this)) {
            Log.w(TAG, "showNativeBlockOverlay: SYSTEM_ALERT_WINDOW not granted, skipping overlay")
            return
        }
        hideNativeBlockOverlay() // Xoá overlay cũ nếu có
        try {
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
                PixelFormat.TRANSLUCENT
            )
            val view = LayoutInflater.from(this).inflate(R.layout.native_block_overlay, null)
            view.findViewById<TextView>(R.id.app_name_text)?.text = packageName
            windowManager.addView(view, params)
            blockOverlayView = view
            Log.d(TAG, "BUG-2: showNativeBlockOverlay() — showing overlay for $packageName")
        } catch (e: Exception) {
            Log.e(TAG, "showNativeBlockOverlay error", e)
        }
    }

    // BUG-2 FIX: Ẩn overlay khi app được unblock
    private fun hideNativeBlockOverlay() {
        blockOverlayView?.let {
            try {
                windowManager.removeView(it)
                Log.d(TAG, "BUG-2: hideNativeBlockOverlay() — overlay removed")
            } catch (e: Exception) {
                Log.w(TAG, "hideNativeBlockOverlay: could not remove view", e)
            }
        }
        blockOverlayView = null
    }


    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return

            if (isSystemPackage(packageName)) return

            if (currentPackageName != packageName) {
                if (currentPackageName != null) {
                    val durationMs = System.currentTimeMillis() - activeAppStartMillis
                    // FIX #1+#5 Native: Lưu offline log cho monitored apps (Nếu rỗng → theo dõi tất cả user apps)
                    val prevIsMonitored = monitoredPackages.isEmpty() || monitoredPackages.contains(currentPackageName!!)
                    if (activeAppStartMillis > 0 && durationMs >= 5000 && !isSystemPackage(currentPackageName!!) && prevIsMonitored) {
                        saveOfflineUsageLog(currentPackageName!!, activeAppStartMillis, System.currentTimeMillis(), durationMs / 1000)
                    }
                    if (prevIsMonitored) {
                        sendAppEvent(currentPackageName!!, "closed")
                    }
                }

                currentPackageName = packageName
                activeAppStartMillis = System.currentTimeMillis()
                lastExtractedText = ""
                Log.d(TAG, "Window State Changed: $packageName")

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
        } else if (event?.eventType == AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED) {
            val packageName = event.packageName?.toString() ?: return
            if (isSystemPackage(packageName)) return

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
            // Chỉ scan khi source là EditText hoặc SearchInput
            val packageName = event.packageName?.toString() ?: return
            if (isSystemPackage(packageName)) return

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
     * FIX C2 + BUG-2 FIX: Khoá app bằng cách ép về Home Screen và hiển native overlay.
     * Native overlay độc lập Flutter UI — chặn triệt để dù KidGuardian ở background.
     */
    private fun blockApp(packageName: String) {
        Log.d(TAG, "BUG-2: blockApp() — $packageName")
        // 1. Ép về Home ngay lập tức
        performGlobalAction(GLOBAL_ACTION_HOME)
        // 2. Hiển native overlay đè lên app bị chặn (không cần Flutter nhìn thấy)
        showNativeBlockOverlay(packageName)
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
        // BUG-2 FIX: Xóa overlay khi service bị hủy
        hideNativeBlockOverlay()
        if (instance == this) instance = null
    }
}
