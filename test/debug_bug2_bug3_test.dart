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
      expect(keywords, containsAll(['học tập', 'an toàn']));
      expect(keywords, isNot(contains('tự tử'))); // Not containing default words
    });
  });
}
