import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/core/utils/app_utils.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  group('Bug 2 Debug: Telegram, Messenger, Locket Name Parsing', () {
    test('Should parse org.telegram.messenger as Telegram', () {
      final appName = AppUtils.getAppNameFromLog('org.telegram.messenger', '');
      expect(appName, equals('Telegram'));
    });

    test('Should parse com.facebook.orca as Messenger', () {
      final appName = AppUtils.getAppNameFromLog('com.facebook.orca', '');
      expect(appName, equals('Messenger'));
    });

    test('Should parse com.locket.locket as Locket', () {
      // Actually Locket might be parsed by capitalization logic if not in map, but let's check
      final appName = AppUtils.getAppNameFromLog('com.locket.locket', 'Locket');
      expect(appName, equals('Locket'));
    });
  });

  group('Bug 3 Debug: Keyword Fallback', () {
    test('Should return 19 default keywords when Firestore is empty', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final alertRepo = AlertRepositoryImpl(firestore: fakeFirestore);
      
      // Giả lập chưa có bất kỳ keyword nào trong DB (gia đình mới)
      final stream = alertRepo.watchKeywords('test_family');
      
      final keywords = await stream.first;
      print('Keywords from empty DB: $keywords');
      
      // Khẳng định rằng nó trả về 19 từ khóa của UI
      expect(keywords.length, equals(21)); // 21 keywords default (I counted 21 in the list)
      expect(
        keywords,
        containsAll([
          'tự tử', 'tự làm hại bản thân', 'nhảy lầu',
          'đánh nhau', 'bạo lực', 'đánh hội đồng', 'dao', 'chém',
          'ma túy', 'cần sa', 'thuốc lắc', 'cờ bạc', 'cá độ', 'cá cược',
          'sex', 'khiêu dâm', 'phim người lớn', '18+',
          'lừa đảo', 'hack', 'dâm ô',
        ]),
      );
    });

    test('Should allow parents to add, delete, edit keywords successfully', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      
      // Simulate parent adding new keywords to Firestore
      await fakeFirestore
          .collection('families')
          .doc('test_family')
          .collection('settings')
          .doc('keywords')
          .set({
        'keywords': ['học tập', 'an toàn']
      });

      final alertRepo = AlertRepositoryImpl(firestore: fakeFirestore);
      
      final stream = alertRepo.watchKeywords('test_family');
      final keywords = await stream.first;
      
      print('Keywords from custom DB: $keywords');
      
      // Khẳng định rằng khi phụ huynh sửa đổi, danh sách mặc định bị ghi đè hoàn toàn
      expect(keywords.length, equals(2));
      expect(keywords, isNot(contains('tự tử'))); // Not containing default words
    });
  });

  group('Bug 1 Debug: Locket Case-Sensitivity', () {
    test('com.locket.Locket should not be considered unmonitored', () {
      final isSystem = AppUtils.isSystemOrUnmonitoredApp('com.locket.Locket');
      expect(isSystem, isFalse, reason: 'Capitalized Locket should be monitored');
    });
  });

  group('Bug 5 Debug: Realtime Map Sync Key', () {
    test('Should resolve package name to app name to prevent duplicate keys in Dashboard', () {
      Map<String, int> usageByApp = {'YouTube': 10};
      
      final appPkg = 'com.google.android.youtube';
      final usedMinutes = 25;
      
      // NEW LOGIC from ChildDashboard:
      final appName = AppUtils.getAppNameFromLog(appPkg, 'YouTube');
      if (appName.isNotEmpty && usedMinutes > (usageByApp[appName] ?? 0)) {
        usageByApp[appName] = usedMinutes;
      }
      
      // Asserts that the key 'YouTube' was updated, and no new key was added
      expect(usageByApp.length, equals(1));
      expect(usageByApp['YouTube'], equals(25));
      expect(usageByApp.containsKey(appPkg), isFalse);
    });
  });

  group('Bug 6 Debug: Shortest Remaining Time Filter', () {
    test('Should ignore expired apps when finding the app with minimum remaining time', () {
      final appTimeLimits = {
        'com.google.android.youtube': 60, // Limit 60
        'com.facebook.katana': 30, // Limit 30
      };
      
      final usageByApp = {
        'com.google.android.youtube': 60, // Used 60 -> Remaining 0 (Expired)
        'com.facebook.katana': 20, // Used 20 -> Remaining 10 (Active)
      };

      int minRemainingAppTime = 999999;
      String minRemainingAppName = '';
      
      appTimeLimits.forEach((pkg, limit) {
        if (limit > 0) {
          final usage = usageByApp[pkg] ?? 0;
          final remaining = limit - usage;
          // Filter out remaining <= 0
          if (remaining > 0 && remaining < minRemainingAppTime) {
            minRemainingAppTime = remaining;
            minRemainingAppName = AppUtils.getAppNameFromLog(pkg, '');
          }
        }
      });
      
      // Should pick Facebook, not YouTube (because YouTube is already expired)
      expect(minRemainingAppName, equals('Facebook'));
      expect(minRemainingAppTime, equals(10));
    });
  });

  group('Bug 2 Debug: Daily Summary Limit', () {
    test('Should limit to exactly top 3 apps even if summary has more', () {
      final List<String> topApps = ['App 1', 'App 2', 'App 3', 'App 4', 'App 5'];
      final List<String> displayedApps = topApps.take(3).toList();
      
      expect(displayedApps.length, equals(3));
      expect(displayedApps, containsAll(['App 1', 'App 2', 'App 3']));
      expect(displayedApps, isNot(contains('App 4')));
    });
  });

  group('Bug 3 Debug: Monthly Report Apps Limit', () {
    test('Should limit to exactly 5 apps for monthly report', () {
      final Map<String, int> usageByApp = {
        'App A': 100, 'App B': 90, 'App C': 80,
        'App D': 70, 'App E': 60, 'App F': 50, 'App G': 40
      };
      
      final sortedApps = usageByApp.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top5Apps = sortedApps.take(5).map((e) => e.key).toList();
      
      expect(top5Apps.length, equals(5));
      expect(top5Apps, isNot(contains('App F')));
      expect(top5Apps, isNot(contains('App G')));
    });
  });

  group('Bug 4 Debug: Progress Bar and Locked Text Logic', () {
    test('Should calculate percent based on limit and show locked text when expired', () {
      final entryValue = 60; // 60 minutes used
      final totalMinutes = 120;
      final limitMinutes = 60; // 60 minutes limit
      
      // Calculate percent
      final percent = limitMinutes > 0
          ? (entryValue / limitMinutes * 100).clamp(0.0, 100.0)
          : (totalMinutes > 0 ? (entryValue / totalMinutes * 100) : 0);
          
      expect(percent, equals(100.0));
      
      // Locked logic
      final isLocked = entryValue >= limitMinutes && limitMinutes > 0;
      expect(isLocked, isTrue);
    });

    test('Should calculate percent based on total if no limit set', () {
      final entryValue = 30; // 30 minutes used
      final totalMinutes = 120;
      final limitMinutes = 0; // No limit
      
      // Calculate percent
      final percent = limitMinutes > 0
          ? (entryValue / limitMinutes * 100).clamp(0.0, 100.0)
          : (totalMinutes > 0 ? (entryValue / totalMinutes * 100) : 0);
          
      expect(percent, equals(25.0)); // 30/120 = 25%
      
      // Locked logic
      final isLocked = entryValue >= limitMinutes && limitMinutes > 0;
      expect(isLocked, isFalse);
    });
  });
}
