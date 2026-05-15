import 'package:flutter/services.dart';

class AccessibilityChannel {
  static const MethodChannel _methodChannel =
      MethodChannel('com.kidguardian/accessibility');
  static const EventChannel _eventChannel =
      EventChannel('com.kidguardian/accessibility_events');

  static Future<void> updateBlockedApps(List<String> apps) async {
    try {
      await _methodChannel.invokeMethod('updateBlockedApps', {'apps': apps});
    } on PlatformException catch (e) {
      print('Failed to update blocked apps: ${e.message}');
    }
  }

  static Future<void> updateAppLimits(Map<String, int> limits) async {
    try {
      await _methodChannel.invokeMethod('updateAppLimits', {'limits': limits});
    } on PlatformException catch (e) {
      print('Failed to update app limits: ${e.message}');
    }
  }

  static Stream<Map<String, dynamic>> get accessibilityEvents {
    return _eventChannel.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event);
    });
  }
}
