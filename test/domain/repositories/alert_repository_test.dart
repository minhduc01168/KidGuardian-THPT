import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late AlertRepositoryImpl repository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = AlertRepositoryImpl(firestore: fakeFirestore);
  });

  group('AlertRepository', () {
    test('createKeywordAlert should add document to Firestore', () async {
      final familyId = 'family1';
      final childUid = 'child1';
      final keyword = 'tự tử';
      final packageName = 'com.facebook.katana';
      final textContext = 'Đây là một đoạn text chứa từ khóa tự tử';

      await repository.createKeywordAlert(
        familyId: familyId,
        childUid: childUid,
        keyword: keyword,
        packageName: packageName,
        textContext: textContext,
      );

      final snapshot = await fakeFirestore
          .collection('families')
          .doc(familyId)
          .collection('children')
          .doc(childUid)
          .collection('alerts')
          .get();

      expect(snapshot.docs.length, 1);
      final doc = snapshot.docs.first.data();
      expect(doc['type'], 'keyword_detected');
      expect(doc['keyword'], keyword);
      expect(doc['packageName'], packageName);
      expect(doc['textContext'], textContext);
      expect(doc['isReviewed'], false);
      expect(doc['timestamp'], isNotNull);
    });
  });
}
