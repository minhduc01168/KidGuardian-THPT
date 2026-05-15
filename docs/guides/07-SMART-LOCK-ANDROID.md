# Bài 7: Smart Lock Android
# Hướng Dẫn Implement Smart Lock

---

## 1. Tổng Quan

### 1.1 Smart Lock Là Gì?
- Tính năng khóa ứng dụng khi hết thời gian cho phép
- Hiển thị màn hình chặn khi trẻ cố truy cập app bị khóa
- Cho phép phụ huynh đặt giới hạn thời gian

### 1.2 Các App Cần Khóa
- TikTok (com.zhiliaoapp.musically)
- Facebook (com.facebook.katana)
- Instagram (com.instagram.android)
- Messenger (com.facebook.orca)
- Zalo (com.zing.zalo)
- YouTube (com.google.android.youtube)

### 1.3 Thách Thức
- Android hạn chế quyền truy cập app khác
- Cần nhiều quyền đặc biệt
- Google Play có thể reject app

---

## 2. Các Approach

### 2.1 Accessibility Service
**Ưu điểm:**
- Phát hiện app đang chạy real-time
- Có thể hiển thị overlay

**Nhược điểm:**
- Cần user bật thủ công
- Google có thể reject

### 2.2 UsageStats API
**Ưu điểm:**
- Official Android API
- Dễ sử dụng

**Nhược điểm:**
- Cần user cấp quyền
- Chỉ đọc statistics, không block

### 2.3 Overlay Window
**Ưu điểm:**
- Hiển thị trên mọi app
- Không thể dismiss

**Nhược điểm:**
- Cần SYSTEM_ALERT_WINDOW permission

---

## 3. Implementation

### 3.1 Android Manifest

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Permissions -->
    <uses-permission android:name="android.permission.BIND_ACCESSIBILITY_SERVICE" />
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.PACKAGE_USAGE_STATS" />
    
    <application>
        <!-- Accessibility Service -->
        <service
            android:name=".accessibility.AppMonitorService"
            android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE"
            android:exported="false">
            <intent-filter>
                <action android:name="android.accessibilityservice.AccessibilityService" />
            </intent-filter>
            <meta-data
                android:name="android.accessibilityservice"
                android:resource="@xml/accessibility_service_config" />
        </service>
        
        <!-- Foreground Service -->
        <service
            android:name=".service.MonitorService"
            android:foregroundServiceType="specialUse"
            android:exported="false" />
    </application>
</manifest>
```

### 3.2 Accessibility Service Config

```xml
<!-- android/app/src/main/res/xml/accessibility_service_config.xml -->
<accessibility-service xmlns:android="http://schemas.android.com/apk/res/android"
    android:accessibilityEventTypes="typeWindowStateChanged"
    android:accessibilityFeedbackType="feedbackGeneric"
    android:accessibilityFlags="flagDefault"
    android:canRetrieveWindowContent="true"
    android:notificationTimeout="100"
    android:packageNames="com.zhiliaoapp.musically,com.facebook.katana" />
```

### 3.3 Accessibility Service

```kotlin
// android/app/src/main/kotlin/com/kidguardian/accessibility/AppMonitorService.kt
package com.kidguardian.accessibility

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.content.Intent
import com.kidguardian.service.MonitorService

class AppMonitorService : AccessibilityService() {
    
    private val blockedApps = mutableSetOf<String>()
    
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString()
            if (packageName != null && isBlockedApp(packageName)) {
                onAppBlocked(packageName)
            }
        }
    }
    
    override fun onInterrupt() {
        // Handle interruption
    }
    
    private fun isBlockedApp(packageName: String): Boolean {
        return blockedApps.contains(packageName)
    }
    
    private fun onAppBlocked(packageName: String) {
        // Send event to Flutter via MethodChannel
        val intent = Intent("com.kidguardian.APP_BLOCKED")
        intent.putExtra("packageName", packageName)
        sendBroadcast(intent)
        
        // Show lock screen
        showLockScreen(packageName)
    }
    
    private fun showLockScreen(packageName: String) {
        // Start MonitorService to show overlay
        val intent = Intent(this, MonitorService::class.java)
        intent.putExtra("packageName", packageName)
        startService(intent)
    }
    
    fun updateBlockedApps(apps: List<String>) {
        blockedApps.clear()
        blockedApps.addAll(apps)
    }
}
```

### 3.4 Monitor Service

```kotlin
// android/app/src/main/kotlin/com/kidguardian/service/MonitorService.kt
package com.kidguardian.service

import android.app.*
import android.content.Intent
import android.graphics.PixelFormat
import android.os.IBinder
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import com.kidguardian.R

class MonitorService : Service() {
    
    private lateinit var windowManager: WindowManager
    private var lockView: View? = null
    
    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val packageName = intent?.getStringExtra("packageName")
        if (packageName != null) {
            showLockScreen(packageName)
        }
        return START_NOT_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    private fun showLockScreen(packageName: String) {
        if (lockView != null) return
        
        lockView = LayoutInflater.from(this).inflate(R.layout.lock_screen, null)
        
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT
        )
        
        windowManager.addView(lockView, params)
        
        // Setup buttons
        setupLockScreenButtons(packageName)
    }
    
    private fun setupLockScreenButtons(packageName: String) {
        lockView?.findViewById<View>(R.id.btnRequestTime)?.setOnClickListener {
            requestMoreTime(packageName)
        }
        
        lockView?.findViewById<View>(R.id.btnEmergency)?.setOnClickListener {
            openEmergencyAccess()
        }
    }
    
    private fun requestMoreTime(packageName: String) {
        // Send request to Flutter
        val intent = Intent("com.kidguardian.REQUEST_TIME")
        intent.putExtra("packageName", packageName)
        sendBroadcast(intent)
    }
    
    private fun openEmergencyAccess() {
        // Open phone app for emergency call
        val intent = Intent(Intent.ACTION_DIAL)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
    }
    
    fun dismissLockScreen() {
        if (lockView != null) {
            windowManager.removeView(lockView)
            lockView = null
        }
    }
    
    override fun onDestroy() {
        dismissLockScreen()
        super.onDestroy()
    }
}
```

### 3.5 Lock Screen Layout

```xml
<!-- android/app/src/main/res/layout/lock_screen.xml -->
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="#FF000000"
    android:gravity="center"
    android:orientation="vertical"
    android:padding="32dp">
    
    <ImageView
        android:layout_width="100dp"
        android:layout_height="100dp"
        android:src="@drawable/ic_lock"
        android:contentDescription="Lock icon" />
    
    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginTop="24dp"
        android:text="Ứng dụng đã bị khóa"
        android:textColor="#FFFFFF"
        android:textSize="24sp"
        android:textStyle="bold" />
    
    <TextView
        android:id="@+id/tvReason"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginTop="16dp"
        android:text="Bạn đã hết thời gian sử dụng hôm nay"
        android:textColor="#CCCCCC"
        android:textSize="16sp"
        android:gravity="center" />
    
    <Button
        android:id="@+id/btnRequestTime"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="32dp"
        android:text="Xin thêm 15 phút"
        android:backgroundTint="#4CAF50" />
    
    <Button
        android:id="@+id/btnEmergency"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="16dp"
        android:text="Gọi khẩn cấp"
        android:backgroundTint="#FF5722" />
</LinearLayout>
```

---

## 4. Flutter Integration

### 4.1 Platform Channel

```dart
// lib/platform/android/smart_lock_channel.dart
import 'package:flutter/services.dart';

class SmartLockChannel {
  static const MethodChannel _channel = 
    MethodChannel('com.kidguardian/smart_lock');
  
  static const EventChannel _eventChannel = 
    EventChannel('com.kidguardian/smart_lock_events');
  
  // Check if Accessibility Service is enabled
  static Future<bool> isAccessibilityEnabled() async {
    return await _channel.invokeMethod('isAccessibilityEnabled');
  }
  
  // Open Accessibility Settings
  static Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod('openAccessibilitySettings');
  }
  
  // Set blocked apps
  static Future<void> setBlockedApps(List<String> packages) async {
    await _channel.invokeMethod('setBlockedApps', {
      'packages': packages,
    });
  }
  
  // Set time limit
  static Future<void> setTimeLimit(String package, int minutes) async {
    await _channel.invokeMethod('setTimeLimit', {
      'package': package,
      'minutes': minutes,
    });
  }
  
  // Listen to app blocked events
  static Stream<AppBlockedEvent> get onAppBlocked {
    return _eventChannel.receiveBroadcastStream()
      .map((event) => AppBlockedEvent.fromMap(event));
  }
}

class AppBlockedEvent {
  final String packageName;
  final DateTime timestamp;
  
  AppBlockedEvent({required this.packageName, required this.timestamp});
  
  factory AppBlockedEvent.fromMap(Map<dynamic, dynamic> map) {
    return AppBlockedEvent(
      packageName: map['packageName'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }
}
```

### 4.2 Android Method Channel Handler

```kotlin
// android/app/src/main/kotlin/com/kidguardian/MainActivity.kt
package com.kidguardian

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.kidguardian/smart_lock"
    private val EVENT_CHANNEL = "com.kidguardian/smart_lock_events"
    
    private var eventSink: EventChannel.EventSink? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAccessibilityEnabled" -> {
                        result.success(isAccessibilityServiceEnabled())
                    }
                    "openAccessibilitySettings" -> {
                        openAccessibilitySettings()
                        result.success(null)
                    }
                    "setBlockedApps" -> {
                        val packages = call.argument<List<String>>("packages")
                        setBlockedApps(packages ?: emptyList())
                        result.success(null)
                    }
                    "setTimeLimit" -> {
                        val pkg = call.argument<String>("package")
                        val minutes = call.argument<Int>("minutes")
                        setTimeLimit(pkg!!, minutes!!)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        
        // Event Channel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }
                
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }
    
    private fun isAccessibilityServiceEnabled(): Boolean {
        // Check if accessibility service is enabled
        val service = "${packageName}/${packageName}.accessibility.AppMonitorService"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
        return enabledServices?.contains(service) == true
    }
    
    private fun openAccessibilitySettings() {
        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
    }
    
    private fun setBlockedApps(packages: List<String>) {
        // Update blocked apps in accessibility service
        // Implementation depends on how you communicate with the service
    }
    
    private fun setTimeLimit(packageName: String, minutes: Int) {
        // Set time limit for specific app
        // Store in SharedPreferences or send to service
    }
}
```

---

## 5. Usage Tracking

### 5.1 UsageStats Manager

```kotlin
// android/app/src/main/kotlin/com/kidguardian/usage/UsageStatsHelper.kt
package com.kidguardian.usage

import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import java.util.*

class UsageStatsHelper(private val context: Context) {
    
    private val usageStatsManager = context.getSystemService(
        Context.USAGE_STATS_SERVICE
    ) as UsageStatsManager
    
    fun getUsageStats(startTime: Long, endTime: Long): List<UsageStats> {
        return usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )
    }
    
    fun getTodayUsage(packageName: String): Long {
        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()
        
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )
        
        return stats
            .filter { it.packageName == packageName }
            .sumOf { it.totalTimeInForeground }
    }
    
    fun isUsagePermissionGranted(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) 
            as android.app.AppOpsManager
        val mode = appOps.checkOpNoThrow(
            android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            context.packageName
        )
        return mode == android.app.AppOpsManager.MODE_ALLOWED
    }
    
    fun openUsageSettings() {
        context.startActivity(
            android.content.Intent(
                android.provider.Settings.ACTION_USAGE_ACCESS_SETTINGS
            ).apply {
                flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK
            }
        )
    }
}
```

---

## 6. Setup Guide

### 6.1 Bước 1: Kiểm Tra Permissions

```dart
// Check and request permissions
Future<void> checkPermissions() async {
  // Check Accessibility
  final isAccessibilityEnabled = await SmartLockChannel.isAccessibilityEnabled();
  if (!isAccessibilityEnabled) {
    // Show dialog to guide user
    showAccessibilityDialog();
  }
  
  // Check Usage Permission
  final isUsagePermissionGranted = await UsageStatsChannel.isPermissionGranted();
  if (!isUsagePermissionGranted) {
    // Show dialog to guide user
    showUsagePermissionDialog();
  }
}
```

### 6.2 Bước 2: Cài Đặt Blocked Apps

```dart
// Set blocked apps
Future<void> setupBlockedApps() async {
  final blockedApps = [
    'com.zhiliaoapp.musically',  // TikTok
    'com.facebook.katana',        // Facebook
    'com.instagram.android',      // Instagram
    'com.facebook.orca',          // Messenger
    'com.zing.zalo',              // Zalo
    'com.google.android.youtube', // YouTube
  ];
  
  await SmartLockChannel.setBlockedApps(blockedApps);
}
```

### 6.3 Bước 3: Đặt Time Limit

```dart
// Set time limit for app
Future<void> setTimeLimit(String package, int minutes) async {
  await SmartLockChannel.setTimeLimit(package, minutes);
}
```

---

## 7. Xử Lý Sự Cố

### 7.1 Accessibility Service Bị Tắt

```dart
// Check and show dialog
void showAccessibilityDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Cần cấp quyền'),
      content: Text('Vui lòng bật Accessibility Service cho KidGuardian'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            SmartLockChannel.openAccessibilitySettings();
            Navigator.pop(context);
          },
          child: Text('Mở Settings'),
        ),
      ],
    ),
  );
}
```

### 7.2 Overlay Permission

```dart
// Check overlay permission
Future<bool> checkOverlayPermission() async {
  return await MethodChannel('com.kidguardian/overlay')
    .invokeMethod('canDrawOverlays');
}

// Request overlay permission
Future<void> requestOverlayPermission() async {
  await MethodChannel('com.kidguardian/overlay')
    .invokeMethod('requestOverlayPermission');
}
```

---

## 8. Testing

### 8.1 Test trên Device Thật

1. Cài app lên device thật
2. Bật Accessibility Service
3. Mở app bị block
4. Kiểm tra lock screen có hiện không

### 8.2 Test Cases

| Test Case | Expected Result |
|-----------|----------------|
| Mở TikTok khi hết giờ | Lock screen hiện |
| Nhấn "Xin thêm giờ" | Gửi request đến parent |
| Nhấn "Gọi khẩn cấp" | Mở phone app |
| Bật lại Accessibility | App hoạt động bình thường |

---

## 9. Lưu Ý Quan Trọng

### 9.1 Google Play Policy
- Phải có lý do chính đáng cho Accessibility Service
- Không collect data không cần thiết
- Cho phép user disable bất kỳ lúc nào

### 9.2 Battery Optimization
- Sử dụng foreground service
- Giảm frequency khi screen off
- Batch Firestore writes

### 9.3 Security
- Không lưu password trong code
- Encrypt sensitive data
- Validate input từ Flutter

---

## 10. Tài Liệu Tham Khảo

- Android Accessibility Service: https://developer.android.com/guide/topics/ui/accessibility/service
- UsageStats API: https://developer.android.com/reference/android/app/usage/UsageStatsManager
- Overlay Windows: https://developer.android.com/reference/android/view/WindowManager
- Flutter Platform Channels: https://docs.flutter.dev/development/platform-integration/platform-channels

---

**Bài Tiếp Theo:** [Testing](08-TESTING.md)
