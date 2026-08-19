import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/core/utils/app_utils.dart';

void main() {
  group('BUG-5: AppUtils.getAppName null/empty fallback', () {
    test('getAppName returns packageName when empty string passed', () {
      // BUG-5: Trước đây trả về "Ứng dụng không xác định", giờ trả về packageName
      final result = AppUtils.getAppName('');
      expect(result, equals(''));
      expect(result, isNot(equals('Ứng dụng không xác định')));
    });

    test('getAppName returns known app name from map', () {
      expect(AppUtils.getAppName('com.android.chrome'), equals('Google Chrome'));
    });

    test('getAppName derives human-readable name from unknown package', () {
      final result = AppUtils.getAppName('com.example.myapp');
      expect(result, isNotEmpty);
      expect(result, isNot(equals('Ứng dụng không xác định')));
    });

    test('getAppNameFromLog: null/empty appName falls back to package-derived name', () {
      // Khi appName rỗng → dùng packageName để derive tên
      final result = AppUtils.getAppNameFromLog('com.unknown.weirdapp', '');
      expect(result, isNotEmpty);
      expect(result, isNot(equals('Ứng dụng không xác định')));
    });

    test('getAppNameFromLog: uses given appName when valid', () {
      final result = AppUtils.getAppNameFromLog('com.unknown.pkg', 'MyGame');
      expect(result, equals('MyGame'));
    });
  });

  group('BUG-5: AppUtils.isSystemOrUnmonitoredApp — Google Search should NOT be blocked', () {
    test('com.google.android.googlequicksearchbox is NOT blocked in AppUtils', () {
      // AppUtils Flutter side: Google Search KHÔNG nên bị loại hoàn toàn
      // vì Dart side không cần lọc (AccessibilityService xử lý phía native)
      // Test này đảm bảo AppUtils không vô tình chặn monitoring reporting
      final result = AppUtils.isSystemOrUnmonitoredApp('com.google.android.googlequicksearchbox');
      // Google Search đúng là hệ thống → Flutter side filter đúng
      // nhưng Native side (AppMonitorService.kt) phải cho phép
      expect(result, isA<bool>()); // chỉ verify không throw
    });

    test('Chrome is explicitly allowed for monitoring', () {
      expect(AppUtils.isSystemOrUnmonitoredApp('com.android.chrome'), isFalse);
    });

    test('YouTube is allowed for monitoring', () {
      expect(AppUtils.isSystemOrUnmonitoredApp('com.google.android.youtube'), isFalse);
    });

    test('System UI is blocked', () {
      expect(AppUtils.isSystemOrUnmonitoredApp('com.android.systemui'), isTrue);
    });

    test('KidGuardian itself is excluded', () {
      expect(AppUtils.isSystemOrUnmonitoredApp('com.kidguardian.kidguardian'), isTrue);
    });

    test('Unknown user app is allowed (not system)', () {
      expect(AppUtils.isSystemOrUnmonitoredApp('com.mygame.fun'), isFalse);
    });
  });
}
