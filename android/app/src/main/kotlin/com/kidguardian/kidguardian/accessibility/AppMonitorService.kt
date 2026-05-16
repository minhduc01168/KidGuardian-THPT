package com.kidguardian.kidguardian.accessibility

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent

class AppMonitorService : AccessibilityService() {

    companion object {
        private const val TAG = "AppMonitorService"
        const val ACTION_APP_BLOCKED = "com.kidguardian.kidguardian.ACTION_APP_BLOCKED"
        const val ACTION_APP_EVENT = "com.kidguardian.kidguardian.ACTION_APP_EVENT"
        const val EXTRA_PACKAGE_NAME = "package_name"
        const val EXTRA_EVENT_TYPE = "event_type"

        var blockedApps = mutableSetOf<String>()
        var appLimits = mutableMapOf<String, Int>()

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
    }

    private var currentPackageName: String? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        val info = AccessibilityServiceInfo()
        info.eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
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
                Log.d(TAG, "Window State Changed: $packageName")

                sendAppEvent(packageName, "opened")

                if (blockedApps.contains(packageName)) {
                    blockApp(packageName)
                }
            }
        }
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
        // D1 Approach 2: Use moveTaskToBack instead of Home Intent
        // This keeps the task in recent apps so we can re-show lock screen on resume
        val broadcastIntent = Intent(ACTION_APP_BLOCKED).apply {
            putExtra(EXTRA_PACKAGE_NAME, packageName)
        }
        sendBroadcast(broadcastIntent)
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility Service Interrupted")
    }
}
