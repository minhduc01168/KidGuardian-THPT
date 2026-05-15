package com.kidguardian.kidguardian.accessibility

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.content.Context
import android.content.SharedPreferences

class AppMonitorService : AccessibilityService() {

    companion object {
        private const val TAG = "AppMonitorService"
        const val ACTION_APP_BLOCKED = "com.kidguardian.kidguardian.ACTION_APP_BLOCKED"
        const val ACTION_APP_EVENT = "com.kidguardian.kidguardian.ACTION_APP_EVENT"
        const val EXTRA_PACKAGE_NAME = "package_name"
        const val EXTRA_EVENT_TYPE = "event_type"
        
        // This should be updated via MethodChannel from Flutter
        var blockedApps = mutableSetOf<String>()
        var appLimits = mutableMapOf<String, Int>()
    }

    private var currentPackageName: String? = null
    private var lastEventTime: Long = 0

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
            
            // Basic tracking logic - this can be enhanced
            if (currentPackageName != packageName) {
                // Notify closed for previous app
                if (currentPackageName != null) {
                    sendAppEvent(currentPackageName!!, "closed")
                }

                currentPackageName = packageName
                lastEventTime = System.currentTimeMillis()
                Log.d(TAG, "Window State Changed: $packageName")
                
                // Notify opened for new app
                sendAppEvent(packageName, "opened")
                
                // If this app is in the blocked list (managed by Flutter logic)
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
        // Go to home screen to effectively block the app
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(homeIntent)
        
        // Broadcast to MainActivity so Flutter can show Lock Screen
        val broadcastIntent = Intent(ACTION_APP_BLOCKED).apply {
            putExtra(EXTRA_PACKAGE_NAME, packageName)
        }
        sendBroadcast(broadcastIntent)
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility Service Interrupted")
    }
}
