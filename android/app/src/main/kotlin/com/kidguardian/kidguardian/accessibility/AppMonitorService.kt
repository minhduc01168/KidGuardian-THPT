package com.kidguardian.kidguardian.accessibility

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import kotlin.math.max
import kotlin.math.min

class AppMonitorService : AccessibilityService() {

    companion object {
        private const val TAG = "AppMonitorService"
        const val ACTION_APP_BLOCKED = "com.kidguardian.kidguardian.ACTION_APP_BLOCKED"
        const val ACTION_APP_EVENT = "com.kidguardian.kidguardian.ACTION_APP_EVENT"
        const val EXTRA_PACKAGE_NAME = "package_name"
        const val EXTRA_EVENT_TYPE = "event_type"
        const val ACTION_KEYWORD_DETECTED = "com.kidguardian.kidguardian.ACTION_KEYWORD_DETECTED"
        const val EXTRA_KEYWORD = "keyword"
        const val EXTRA_TEXT_CONTEXT = "text_context"

        private const val MAX_TREE_DEPTH = 20
        private const val KEYWORD_COOLDOWN_MS = 60_000L

        var blockedApps = mutableSetOf<String>()
        var appLimits = mutableMapOf<String, Int>()
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
        )

        private fun isSystemPackage(packageName: String): Boolean {
            if (SYSTEM_PACKAGES.contains(packageName)) return true
            if (packageName.startsWith("com.android.") && !packageName.contains("kidguardian")) return true
            if (packageName.startsWith("com.google.android.inputmethod")) return true
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
    private var lastExtractedText = ""

    override fun onServiceConnected() {
        super.onServiceConnected()
        val info = AccessibilityServiceInfo()
        info.eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.flags = AccessibilityServiceInfo.DEFAULT
        this.serviceInfo = info
        Log.d(TAG, "Accessibility Service Connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return

            if (isSystemPackage(packageName)) return

            if (currentPackageName != packageName) {
                if (currentPackageName != null) {
                    sendAppEvent(currentPackageName!!, "closed")
                }

                currentPackageName = packageName
                lastExtractedText = ""
                Log.d(TAG, "Window State Changed: $packageName")

                sendAppEvent(packageName, "opened")

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
    }

    private fun sendAppEvent(packageName: String, eventType: String) {
        val broadcastIntent = Intent(ACTION_APP_EVENT).apply {
            putExtra(EXTRA_PACKAGE_NAME, packageName)
            putExtra(EXTRA_EVENT_TYPE, eventType)
        }
        sendBroadcast(broadcastIntent)
    }

    private fun blockApp(packageName: String) {
        Log.d(TAG, "Blocking app: $packageName")
        val broadcastIntent = Intent(ACTION_APP_BLOCKED).apply {
            putExtra(EXTRA_PACKAGE_NAME, packageName)
        }
        sendBroadcast(broadcastIntent)
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility Service Interrupted")
    }
}
