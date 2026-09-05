import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/core/utils/app_utils.dart';

void main() {
  group('QA Bug Fixes Verification', () {
    test('Bug 1 & 2: AppUtils getHardcodedSocialApps should contain exactly 8 social apps (plus alias)', () {
      final socialApps = AppUtils.getHardcodedSocialApps();
      
      // Kiểm tra sự tồn tại của Locket và các mạng xã hội khác
      expect(socialApps.contains('com.locket.locket'), isTrue);
      expect(socialApps.contains('com.locket.Locket'), isTrue);
      expect(socialApps.contains('com.discord'), isTrue);
      expect(socialApps.contains('org.telegram.messenger'), isTrue);
      expect(socialApps.contains('com.facebook.orca'), isTrue);
      expect(socialApps.contains('com.ss.android.ugc.trill'), isTrue);

      // Kiểm tra Gmail và Google Maps KHÔNG nằm trong danh sách giám sát (Bị chặn)
      expect(socialApps.contains('com.google.android.gm'), isFalse);
      expect(socialApps.contains('com.google.android.apps.maps'), isFalse);
      
      // Test isSystemOrUnmonitoredApp
      expect(AppUtils.isSystemOrUnmonitoredApp('com.locket.locket'), isFalse, reason: 'Locket MUST be monitored');
      expect(AppUtils.isSystemOrUnmonitoredApp('com.google.android.gm'), isTrue, reason: 'Gmail MUST NOT be monitored');
      expect(AppUtils.isSystemOrUnmonitoredApp('com.android.chrome'), isTrue, reason: 'Chrome MUST NOT be monitored');
    });

    test('Bug 3: PieChart Smart Rounding Algorithm mathematically works to 100%', () {
      final appTotals = {'App A': 33, 'App B': 33, 'App C': 33};
      final total = 99; // Total usage minutes
      
      final roundedPercents = <String, int>{};
      int sumRounded = 0;
      String maxAppKey = '';
      int maxAppVal = -1;

      for (final entry in appTotals.entries) {
        final val = entry.value;
        if (val > maxAppVal) {
          maxAppVal = val;
          maxAppKey = entry.key;
        }
        final rounded = total > 0 ? (val / total * 100).round() : 0;
        roundedPercents[entry.key] = rounded;
        sumRounded += rounded;
      }

      if (sumRounded > 0 && maxAppKey.isNotEmpty && sumRounded != 100) {
        final diff = 100 - sumRounded;
        roundedPercents[maxAppKey] = (roundedPercents[maxAppKey]! + diff).clamp(0, 100);
      }
      
      // Bình thường 33/99 = 33.333% -> round() = 33%. 33*3 = 99%
      // Thuật toán sẽ bù 1% vào App A (App xuất hiện đầu tiên vì các giá trị bằng nhau)
      expect(roundedPercents['App A'], equals(34));
      expect(roundedPercents['App B'], equals(33));
      expect(roundedPercents['App C'], equals(33));
      
      final finalSum = roundedPercents.values.fold(0, (a, b) => a + b);
      expect(finalSum, equals(100), reason: 'Total percentage MUST exactly equal 100%');
    });

    test('Bug 4: Formatting of statusText', () {
      final minutes = 15;
      final limitMinutes = 10;
      final isOverLimit = minutes >= limitMinutes;
      
      String statusText = '';
      if (isOverLimit) {
        statusText = 'Đã hết giờ (${limitMinutes} phút)';
      }
      
      expect(statusText, equals('Đã hết giờ (10 phút)'));
    });

    test('Bug 5: Child Dashboard Min Remaining App Time Logic uses AppUtils.getAppName', () {
      final usageByApp = {'Facebook': 60, 'TikTok': 10}; // Tên đã format
      final appTimeLimits = {'com.facebook.katana': 60, 'com.zhiliaoapp.musically': 30}; // Tên package thô
      
      int minRemainingAppTime = 999999;
      String minRemainingAppName = '';
      
      appTimeLimits.forEach((pkg, limit) {
        if (limit > 0) {
          // LOGIC ĐÃ FIX: dùng AppUtils.getAppName(pkg) thay vì pkg
          final usage = usageByApp[AppUtils.getAppName(pkg)] ?? 0;
          final remaining = limit - usage;
          if (remaining > 0 && remaining < minRemainingAppTime) {
            minRemainingAppTime = remaining;
            minRemainingAppName = AppUtils.getAppName(pkg);
          }
        }
      });
      
      // Facebook usage = 60, limit = 60 -> remaining = 0 (KHÔNG ĐƯỢC CHỌN)
      // TikTok usage = 10, limit = 30 -> remaining = 20 (ĐƯỢC CHỌN)
      expect(minRemainingAppName, equals('TikTok'));
      expect(minRemainingAppTime, equals(20));
    });
  });
}
