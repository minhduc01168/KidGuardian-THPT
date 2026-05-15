# Technical Research Document
# Smart Lock Implementation on Android

**Version:** 1.0  
**Date:** 2026-05-12  
**Status:** Draft  

---

## 1. Executive Summary

This document researches technical approaches for implementing Smart Lock (app blocking) functionality on Android for the KidGuardian application. The goal is to block specific social media apps (TikTok, Facebook, Instagram, Messenger, Zalo, Locket, YouTube) when time limits are reached.

---

## 2. Requirements

### 2.1 Functional Requirements

- Monitor which app is currently in foreground
- Block specific social media apps when time limit reached
- Display lock screen overlay when app is blocked
- Allow emergency access to phone/SMS
- Track app usage time accurately

### 2.2 Non-Functional Requirements

- Must work on Android 5.0+ (API 21+)
- Minimal battery drain
- Cannot be easily bypassed by child
- Must comply with Google Play policies

---

## 3. Technical Approaches

### 3.1 Accessibility Service

**Description:** Android Accessibility Service can monitor UI events and detect when apps come to foreground.

**Implementation:**
```kotlin
class AppMonitorService : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString()
            // Check if app is blocked
        }
    }
}
```

**Pros:**
- Real-time app detection
- Works across all apps
- Can display overlay windows

**Cons:**
- Requires user to manually enable in Settings
- Google may reject apps misusing Accessibility Service
- Battery impact

**Google Play Policy:**
- Must have legitimate accessibility purpose
- Cannot be used solely for app blocking
- Risk of rejection

**Risk Level:** HIGH

---

### 3.2 UsageStats API

**Description:** Android UsageStatsManager provides app usage statistics.

**Implementation:**
```kotlin
val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
val now = System.currentTimeMillis()
val stats = usageStatsManager.queryUsageStats(
    UsageStatsManager.INTERVAL_DAILY,
    now - 1000 * 60,
    now
)
```

**Pros:**
- Official Android API
- No special permissions (just Usage Access)
- Accurate usage data

**Cons:**
- Requires user to grant Usage Access permission
- Cannot block apps directly
- Only provides statistics, not real-time monitoring

**Risk Level:** LOW

---

### 3.3 Device Admin API

**Description:** Device Administration API provides device-level control.

**Implementation:**
```kotlin
class KidGuardianDeviceAdmin : DeviceAdminReceiver() {
    // Handle admin events
}

// In Activity
val devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
val componentName = ComponentName(this, KidGuardianDeviceAdmin::class.java)
```

**Pros:**
- Strong control over device
- Can lock device, wipe data
- Persistent after reboot

**Cons:**
- Requires user to set as Device Admin
- Cannot block individual apps (only lock device)
- Overkill for our use case

**Risk Level:** MEDIUM

---

### 3.4 Overlay Window

**Description:** Display a system-level overlay window on top of blocked apps.

**Implementation:**
```kotlin
// Add permission in AndroidManifest
// <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />

val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
val params = WindowManager.LayoutParams(
    WindowManager.LayoutParams.MATCH_PARENT,
    WindowManager.LayoutParams.MATCH_PARENT,
    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
    PixelFormat.TRANSLUCENT
)
val lockView = LayoutInflater.from(this).inflate(R.layout.lock_screen, null)
windowManager.addView(lockView, params)
```

**Pros:**
- Cannot be dismissed by child
- Works on top of any app
- Customizable UI

**Cons:**
- Requires SYSTEM_ALERT_WINDOW permission
- User must grant "Draw over other apps" permission
- May interfere with other apps

**Risk Level:** MEDIUM

---

### 3.5 Background Service + Timer

**Description:** Run a background service that monitors app usage and enforces limits.

**Implementation:**
```kotlin
class AppMonitorService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private val checkInterval = 1000L // 1 second
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, createNotification())
        startMonitoring()
        return START_STICKY
    }
    
    private fun startMonitoring() {
        handler.postDelayed(object : Runnable {
            override fun run() {
                checkCurrentApp()
                handler.postDelayed(this, checkInterval)
            }
        }, checkInterval)
    }
}
```

**Pros:**
- Continuous monitoring
- Can enforce time limits in real-time
- Works with other approaches

**Cons:**
- Battery drain
- May be killed by system
- Requires FOREGROUND_SERVICE permission

**Risk Level:** LOW

---

## 4. Recommended Approach

### 4.1 Hybrid Approach

Combine multiple approaches for robust implementation:

```
┌─────────────────────────────────────────────────────────────┐
│                    Smart Lock Architecture                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐    ┌─────────────────┐               │
│  │ UsageStats API  │    │  Background     │               │
│  │ (Data Source)   │    │  Service        │               │
│  └────────┬────────┘    └────────┬────────┘               │
│           │                      │                         │
│           ▼                      ▼                         │
│  ┌─────────────────────────────────────────────────────┐  │
│  │              App Monitor Service                     │  │
│  │  - Check current foreground app                      │  │
│  │  - Track usage time                                  │  │
│  │  - Enforce time limits                               │  │
│  └─────────────────────────────────────────────────────┘  │
│                          │                                  │
│                          ▼                                  │
│  ┌─────────────────────────────────────────────────────┐  │
│  │              Overlay Window                          │  │
│  │  - Display lock screen                               │  │
│  │  - Show remaining time                               │  │
│  │  - Request more time button                          │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 Implementation Strategy

**Phase 1: Basic Monitoring**
1. Implement UsageStats API for usage tracking
2. Create background service for monitoring
3. Add basic time tracking

**Phase 2: App Blocking**
1. Implement overlay window
2. Add lock screen UI
3. Integrate with Firebase for time limits

**Phase 3: Advanced Features**
1. Add schedule support
2. Implement emergency access
3. Add bypass prevention

---

## 5. Flutter Integration

### 5.1 Platform Channels

```dart
// Flutter side
class SmartLockChannel {
  static const MethodChannel _channel = 
    MethodChannel('com.kidguardian/smart_lock');
  
  static Future<bool> isAccessibilityServiceEnabled() async {
    return await _channel.invokeMethod('isAccessibilityEnabled');
  }
  
  static Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod('openAccessibilitySettings');
  }
  
  static Future<void> setTimeLimit(String appPackage, int minutes) async {
    await _channel.invokeMethod('setTimeLimit', {
      'appPackage': appPackage,
      'minutes': minutes,
    });
  }
  
  static Stream<AppBlockedEvent> get onAppBlocked {
    return _channel.receiveBroadcastStream()
      .map((event) => AppBlockedEvent.fromMap(event));
  }
}
```

### 5.2 Android Side

```kotlin
// MainActivity.kt
class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.kidguardian/smart_lock"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
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
                    "setTimeLimit" -> {
                        val appPackage = call.argument<String>("appPackage")
                        val minutes = call.argument<Int>("minutes")
                        setTimeLimit(appPackage, minutes)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
```

---

## 6. Google Play Compliance

### 6.1 Policy Requirements

**Accessibility Service Usage:**
- Must have legitimate accessibility purpose
- Cannot be used solely for monitoring/blocking
- Must disclose usage in privacy policy

**Mitigation Strategy:**
1. Add accessibility features (screen reader support)
2. Document legitimate use case (child safety)
3. Provide clear privacy policy
4. Allow user to disable anytime

### 6.2 Permission Requests

**Required Permissions:**
```xml
<uses-permission android:name="android.permission.BIND_ACCESSIBILITY_SERVICE" />
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.PACKAGE_USAGE_STATS" />
```

**User Education:**
- Explain why each permission is needed
- Provide step-by-step setup guide
- Show benefits of enabling permissions

---

## 7. Battery Optimization

### 7.1 Strategies

1. **Efficient Polling**
   - Use 5-second intervals instead of 1-second
   - Batch Firestore writes
   - Use JobScheduler for non-critical tasks

2. **Smart Monitoring**
   - Only monitor when screen is on
   - Pause monitoring when device is idle
   - Reduce frequency when no blocked apps running

3. **Foreground Service**
   - Use foreground service for reliability
   - Show persistent notification
   - Optimize notification updates

### 7.2 Implementation

```kotlin
class AppMonitorService : Service() {
    private var isScreenOn = true
    private var checkInterval = 5000L // 5 seconds
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        registerScreenReceiver()
        startForeground(NOTIFICATION_ID, createNotification())
        startMonitoring()
        return START_STICKY
    }
    
    private fun registerScreenReceiver() {
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
        }
        registerReceiver(screenReceiver, filter)
    }
    
    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_ON -> {
                    isScreenOn = true
                    startMonitoring()
                }
                Intent.ACTION_SCREEN_OFF -> {
                    isScreenOn = false
                    stopMonitoring()
                }
            }
        }
    }
}
```

---

## 8. Testing Strategy

### 8.1 Unit Tests

- Test time calculation logic
- Test app detection logic
- Test Firebase integration

### 8.2 Integration Tests

- Test platform channel communication
- Test overlay window display
- Test background service lifecycle

### 8.3 Device Testing

**Test Matrix:**

| Device | Android Version | Status |
|--------|-----------------|--------|
| Samsung Galaxy S10 | Android 11 | ⬜ |
| Pixel 4 | Android 12 | ⬜ |
| Xiaomi Redmi Note 10 | Android 11 | ⬜ |
| OPPO Reno 6 | Android 11 | ⬜ |

### 8.4 Edge Cases

- App killed by system
- Device reboot
- Permission revoked
- Multiple blocked apps
- Quick app switching

---

## 9. Risk Assessment

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Google Play rejection | High | Medium | Follow policies, provide documentation |
| Battery drain complaints | Medium | Medium | Optimize monitoring, user settings |
| Bypass by tech-savvy child | Medium | Low | Multiple detection methods |
| Android version fragmentation | Medium | Medium | Test on multiple versions |
| Permission denial | Medium | Low | Clear explanation, graceful degradation |

---

## 10. Conclusion

### 10.1 Recommended Stack

| Component | Technology |
|-----------|------------|
| App Detection | UsageStats API + Accessibility Service |
| Time Tracking | Background Service + Firestore |
| App Blocking | Overlay Window |
| Data Sync | Firebase Firestore |
| Notifications | FCM + Local Notifications |

### 10.2 Implementation Priority

1. **Week 1:** Basic monitoring with UsageStats
2. **Week 2:** Background service and time tracking
3. **Week 3:** Overlay window and lock screen
4. **Week 4:** Firebase integration and testing

### 10.3 Success Criteria

- [ ] Apps blocked within 1 second of time limit
- [ ] Battery drain < 5% per day
- [ ] Works on Android 5.0+
- [ ] Cannot be easily bypassed
- [ ] Complies with Google Play policies

---

## 11. References

- Android Accessibility Service: https://developer.android.com/guide/topics/ui/accessibility/service
- UsageStats API: https://developer.android.com/reference/android/app/usage/UsageStatsManager
- Device Admin API: https://developer.android.com/guide/topics/admin/device-admin
- Overlay Windows: https://developer.android.com/reference/android/view/WindowManager
- Google Play Policies: https://play.google.com/about/developer-content-policy/

---

**Document Owner:** Technical Team  
**Last Updated:** 2026-05-12  
**Next Review:** 2026-05-19
