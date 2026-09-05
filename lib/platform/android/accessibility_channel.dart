import 'dart:convert';
import 'package:flutter/services.dart';

/// AccessibilityChannel — Cầu nối Flutter ↔ Android Native
///
/// FIX C1: Thêm startMonitorService() / stopMonitorService()
/// FIX C2: Thêm moveToHome() thay thế moveTaskToBack()
class AccessibilityChannel {
  static const MethodChannel _methodChannel =
      MethodChannel('com.kidguardian/accessibility');
  static const EventChannel _eventChannel =
      EventChannel('com.kidguardian/accessibility_events');

  /// Cập nhật danh sách app bị khoá trong Native
  static Future<void> updateBlockedApps(List<String> apps) async {
    try {
      await _methodChannel.invokeMethod('updateBlockedApps', {'apps': apps});
    } on PlatformException catch (e) {
      print('Failed to update blocked apps: ${e.message}');
    }
  }

  /// Cập nhật giới hạn thời gian từng app (package → phút)
  static Future<void> updateAppLimits(Map<String, int> limits) async {
    try {
      await _methodChannel.invokeMethod('updateAppLimits', {'limits': limits});
    } on PlatformException catch (e) {
      print('Failed to update app limits: ${e.message}');
    }
  }

  /// Cập nhật danh sách từ khoá cần theo dõi
  static Future<void> updateKeywords(List<String> keywords) async {
    try {
      await _methodChannel.invokeMethod('updateKeywords', {'keywords': keywords});
    } on PlatformException catch (e) {
      print('Failed to update keywords: ${e.message}');
    }
  }

  /// FIX #1+#5 Native: Push danh sách package được giám sát xuống Kotlin
  /// để Native filter app events ngay tại tầng dưới, giảm tải Dart runtime.
  static Future<void> updateMonitoredPackages(List<String> packages) async {
    try {
      await _methodChannel.invokeMethod('updateMonitoredPackages', {'packages': packages});
    } on PlatformException catch (e) {
      print('Failed to update monitored packages: ${e.message}');
    }
  }

  /// FIX C2: Ép thiết bị về Home Screen thực sự (thay thế moveTaskToBack)
  /// Native sẽ gọi performGlobalAction(GLOBAL_ACTION_HOME)
  static Future<void> moveToHome() async {
    try {
      await _methodChannel.invokeMethod('moveToHome');
    } on PlatformException catch (e) {
      print('Failed to move to home: ${e.message}');
    }
  }

  /// FIX C1: Khởi động MonitorForegroundService — giữ BroadcastReceiver sống
  static Future<void> startMonitorService() async {
    try {
      await _methodChannel.invokeMethod('startMonitorService');
    } on PlatformException catch (e) {
      print('Failed to start monitor service: ${e.message}');
    }
  }

  /// Dừng MonitorForegroundService khi phụ huynh tắt tính năng giám sát
  static Future<void> stopMonitorService() async {
    try {
      await _methodChannel.invokeMethod('stopMonitorService');
    } on PlatformException catch (e) {
      print('Failed to stop monitor service: ${e.message}');
    }
  }

  /// Kiểm tra xem Quyền Accessibility Service đã được người dùng bật trong Settings chưa
  static Future<bool> isAccessibilityPermissionGranted() async {
    try {
      final bool? isGranted = await _methodChannel.invokeMethod('isAccessibilityPermissionGranted');
      return isGranted ?? false;
    } on PlatformException catch (e) {
      print('Failed to check accessibility permission: ${e.message}');
      return false;
    }
  }

  /// Mở màn hình Cài đặt Trợ năng (Accessibility Settings) của Android
  static Future<void> openAccessibilitySettings() async {
    try {
      await _methodChannel.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (e) {
      print('Failed to open accessibility settings: ${e.message}');
    }
  }

  /// Đọc và xóa toàn bộ log sử dụng ngoại tuyến trong Kotlin SharedPreferences
  static Future<List<Map<String, dynamic>>> getAndClearOfflineUsageLogs() async {
    try {
      final List<dynamic>? logsJsonList = await _methodChannel.invokeMethod('getAndClearOfflineUsageLogs');
      if (logsJsonList == null || logsJsonList.isEmpty) return [];
      return logsJsonList.map((item) {
        try {
          if (item is String) {
            return Map<String, dynamic>.from(jsonDecode(item));
          } else if (item is Map) {
            return Map<String, dynamic>.from(item);
          }
        } catch (e) {
          print('Skipping malformed offline log item: $e');
        }
        return <String, dynamic>{};
      }).where((m) => m.isNotEmpty).toList();
    } on PlatformException catch (e) {
      print('Failed to get offline usage logs: ${e.message}');
      return [];
    }
  }

  /// Giữ lại để tương thích ngược với code cũ
  @Deprecated('Dùng moveToHome() thay thế')
  static Future<void> moveTaskToBack() async {
    try {
      await _methodChannel.invokeMethod('moveTaskToBack');
    } on PlatformException catch (e) {
      print('Failed to move task to back: ${e.message}');
    }
  }

  /// Stream nhận events từ Native (app_event, keyword_detected, blocked)
  static Stream<Map<String, dynamic>> get accessibilityEvents {
    return _eventChannel.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event);
    });
  }
}
