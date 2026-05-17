import 'package:cloud_firestore/cloud_firestore.dart';

abstract class AlertRepository {
  Future<void> createKeywordAlert({
    required String familyId,
    required String childUid,
    required String keyword,
    required String packageName,
    required String textContext,
  });
}

class AlertRepositoryImpl implements AlertRepository {
  final FirebaseFirestore _firestore;

  AlertRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> createKeywordAlert({
    required String familyId,
    required String childUid,
    required String keyword,
    required String packageName,
    required String textContext,
  }) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('children')
          .doc(childUid)
          .collection('alerts')
          .add({
        'type': 'keyword_detected',
        'keyword': keyword,
        'packageName': packageName,
        'textContext': textContext,
        'timestamp': FieldValue.serverTimestamp(),
        'isReviewed': false,
      });
    } catch (e) {
      throw Exception('Failed to create keyword alert: $e');
    }
  }
}
