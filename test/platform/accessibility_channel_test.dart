import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/platform/android/accessibility_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.kidguardian/accessibility');
  final List<MethodCall> methodCalls = [];

  setUp(() {
    methodCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      methodCalls.add(call);
      return true;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('AccessibilityChannel — FIX C1 & C2', () {
    test('startMonitorService() gọi đúng method trên native', () async {
      await AccessibilityChannel.startMonitorService();
      expect(methodCalls.length, 1);
      expect(methodCalls.first.method, 'startMonitorService');
    });

    test('stopMonitorService() gọi đúng method trên native', () async {
      await AccessibilityChannel.stopMonitorService();
      expect(methodCalls.first.method, 'stopMonitorService');
    });

    test('moveToHome() gọi moveToHome thay vì moveTaskToBack', () async {
      await AccessibilityChannel.moveToHome();
      expect(methodCalls.first.method, 'moveToHome');
    });

    test('updateBlockedApps() gửi đúng list apps', () async {
      await AccessibilityChannel.updateBlockedApps(
          ['com.tiktok.app', 'com.facebook.katana']);
      expect(methodCalls.first.method, 'updateBlockedApps');
      final apps = (methodCalls.first.arguments as Map)['apps'] as List;
      expect(apps.length, 2);
      expect(apps, contains('com.tiktok.app'));
    });

    test('updateBlockedApps() không throw khi native lỗi', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'ERROR', message: 'Native error');
      });
      // Không throw — chỉ in lỗi
      expect(
        () async => await AccessibilityChannel.updateBlockedApps(['com.tiktok.app']),
        returnsNormally,
      );
    });

    test('updateKeywords() gửi đúng keywords', () async {
      await AccessibilityChannel.updateKeywords(['tự tử', 'cờ bạc']);
      expect(methodCalls.first.method, 'updateKeywords');
      final kw = (methodCalls.first.arguments as Map)['keywords'] as List;
      expect(kw, containsAll(['tự tử', 'cờ bạc']));
    });

    test('updateAppLimits() gửi đúng map limits', () async {
      await AccessibilityChannel.updateAppLimits({'com.tiktok.app': 60});
      expect(methodCalls.first.method, 'updateAppLimits');
      final limits = (methodCalls.first.arguments as Map)['limits'] as Map;
      expect(limits['com.tiktok.app'], 60);
    });
  });
}
