import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:kidguardian/platform/android/accessibility_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('com.kidguardian/accessibility');

  group('AccessibilityChannel - Permission & Settings Tests', () {
    test('isAccessibilityPermissionGranted returns true when native channel returns true', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'isAccessibilityPermissionGranted') {
          return true;
        }
        return null;
      });

      final result = await AccessibilityChannel.isAccessibilityPermissionGranted();
      expect(result, isTrue);
    });

    test('isAccessibilityPermissionGranted returns false when native channel returns false or throws PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'isAccessibilityPermissionGranted') {
          throw PlatformException(code: 'UNAVAILABLE', message: 'Accessibility service check failed');
        }
        return null;
      });

      final result = await AccessibilityChannel.isAccessibilityPermissionGranted();
      expect(result, isFalse);
    });

    test('openAccessibilitySettings does not throw when invoked', () async {
      bool invoked = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'openAccessibilitySettings') {
          invoked = true;
          return true;
        }
        return null;
      });

      await AccessibilityChannel.openAccessibilitySettings();
      expect(invoked, isTrue);
    });
  });
}
