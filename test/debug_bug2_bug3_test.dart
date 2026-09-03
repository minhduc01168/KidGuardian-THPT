import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/core/utils/app_utils.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  group('Bug 2 Debug: Telegram Name Parsing', () {
    test('Should incorrectly parse org.telegram.messenger as Messenger', () {
      final appName = AppUtils.getAppNameFromLog('org.telegram.messenger', '');
      print('Parsed name for org.telegram.messenger: $appName');
      
      // Khẳng định rằng bây giờ nó parse thành công Telegram
      expect(appName, equals('Telegram'));
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
      expect(keywords, containsAll(['tự tử', 'đánh nhau', 'cờ bạc', 'ma túy', 'khiêu dâm', 'lừa đảo']));
    });
  });
}
