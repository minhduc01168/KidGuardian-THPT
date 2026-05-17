import 'package:cloud_firestore/cloud_firestore.dart';

abstract class AlertRepository {
  Future<void> createKeywordAlert({
    required String familyId,
    required String childUid,
    required String keyword,
    required String packageName,
    required String textContext,
  });

  Stream<List<AlertModel>> watchNewAlerts({
    required String familyId,
    required String childUid,
  });

  Future<void> markAlertAsReviewed({
    required String familyId,
    required String childUid,
    required String alertId,
  });
}

class AlertModel {
  final String id;
  final String type;
  final String keyword;
  final String packageName;
  final String textContext;
  final DateTime? timestamp;
  final bool isReviewed;

  AlertModel({
    required this.id,
    required this.type,
    required this.keyword,
    required this.packageName,
    required this.textContext,
    this.timestamp,
    required this.isReviewed,
  });

  factory AlertModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AlertModel(
      id: doc.id,
      type: data['type'] ?? '',
      keyword: data['keyword'] ?? '',
      packageName: data['packageName'] ?? '',
      textContext: data['textContext'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      isReviewed: data['isReviewed'] ?? false,
    );
  }
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

  @override
  Stream<List<AlertModel>> watchNewAlerts({
    required String familyId,
    required String childUid,
  }) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childUid)
        .collection('alerts')
        .where('isReviewed', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AlertModel.fromFirestore(doc)).toList();
    });
  }

  @override
  Future<void> markAlertAsReviewed({
    required String familyId,
    required String childUid,
    required String alertId,
  }) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('children')
          .doc(childUid)
          .collection('alerts')
          .doc(alertId)
          .update({'isReviewed': true});
    } catch (e) {
      throw Exception('Failed to mark alert as reviewed: $e');
    }
  }
}
