package com.kidguardian.kidguardian

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.kidguardian.kidguardian.accessibility.AppMonitorService

class MainActivity: FlutterActivity() {
    private val METHOD_CHANNEL = "com.kidguardian/accessibility"
    private val EVENT_CHANNEL = "com.kidguardian/accessibility_events"
    private var eventSink: EventChannel.EventSink? = null

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == AppMonitorService.ACTION_APP_BLOCKED) {
                val packageName = intent.getStringExtra(AppMonitorService.EXTRA_PACKAGE_NAME)
                eventSink?.success(mapOf("type" to "app_blocked", "packageName" to packageName))
            } else if (intent?.action == AppMonitorService.ACTION_APP_EVENT) {
                val packageName = intent.getStringExtra(AppMonitorService.EXTRA_PACKAGE_NAME)
                val eventType = intent.getStringExtra(AppMonitorService.EXTRA_EVENT_TYPE)
                eventSink?.success(mapOf("type" to "app_event", "event_type" to eventType, "packageName" to packageName))
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateBlockedApps" -> {
                    val apps = call.argument<List<String>>("apps")
                    if (apps != null) {
                        AppMonitorService.blockedApps.clear()
                        AppMonitorService.blockedApps.addAll(apps)
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

                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }

    override fun onResume() {
        super.onResume()
        val filter = IntentFilter().apply {
            addAction(AppMonitorService.ACTION_APP_BLOCKED)
            addAction(AppMonitorService.ACTION_APP_EVENT)
        }
        registerReceiver(receiver, filter)
    }

    override fun onPause() {
        super.onPause()
        unregisterReceiver(receiver)
    }
}
