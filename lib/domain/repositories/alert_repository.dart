import 'package:cloud_firestore/cloud_firestore.dart';

abstract class AlertRepository {
  Future<void> createKeywordAlert({
    required String familyId,
    required String childUid,
    required String keyword,
    required String packageName,
    required String textContext,
  });

  Future<void> createAppBlockedAlert({
    required String familyId,
    required String childUid,
    required String packageName,
    required String reason,
  });

  Future<void> createTimeRequestAlert({
    required String familyId,
    required String childUid,
    required String packageName,
    required int requestedMinutes,
  });

  Stream<List<AlertModel>> watchNewAlerts({
    required String familyId,
    required String childUid,
  });

  Stream<List<AlertModel>> watchAllAlerts({
    required String familyId,
    required String childUid,
  });

  Stream<List<AlertModel>> watchAllFamilyAlerts({
    required String familyId,
  });

  Future<AlertModel?> getAlert({
    required String familyId,
    required String childUid,
    required String alertId,
  });

  Future<void> markAlertAsReviewed({
    required String familyId,
    required String childUid,
    required String alertId,
  });

  Future<void> addNotesToAlert({
    required String familyId,
    required String childUid,
    required String alertId,
    required String notes,
  });

  Future<void> dismissAlert({
    required String familyId,
    required String childUid,
    required String alertId,
  });

  Stream<List<String>> watchKeywords(String familyId);
}

class AlertModel {
  final String id;
  final String type;
  final String keyword;
  final String packageName;
  final String textContext;
  final DateTime? timestamp;
  final bool isReviewed;
  final bool isDismissed;
  final String notes;
  final String childUid;

  AlertModel({
    required this.id,
    required this.type,
    required this.keyword,
    required this.packageName,
    required this.textContext,
    this.timestamp,
    required this.isReviewed,
    this.isDismissed = false,
    this.notes = '',
    this.childUid = '',
  });

  factory AlertModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Extract childUid from document path
    // Path format: families/{familyId}/children/{childUid}/alerts/{alertId}
    String childUid = '';
    final pathSegments = doc.reference.path.split('/');
    if (pathSegments.length >= 4 && pathSegments[2] == 'children') {
      childUid = pathSegments[3];
    }
    
    return AlertModel(
      id: doc.id,
      type: data['type'] ?? '',
      keyword: data['keyword'] ?? '',
      packageName: data['packageName'] ?? '',
      textContext: data['textContext'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      isReviewed: data['isReviewed'] ?? false,
      isDismissed: data['isDismissed'] ?? false,
      notes: data['notes'] ?? '',
      childUid: childUid,
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
        'isDismissed': false,
        'notes': '',
      });
    } catch (e) {
      throw Exception('Failed to create keyword alert: $e');
    }
  }

  @override
  Future<void> createAppBlockedAlert({
    required String familyId,
    required String childUid,
    required String packageName,
    required String reason, // 'time_limit' or 'schedule'
  }) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('children')
          .doc(childUid)
          .collection('alerts')
          .add({
        'type': 'app_blocked',
        'keyword': '',
        'packageName': packageName,
        'textContext': 'App blocked due to: $reason',
        'timestamp': FieldValue.serverTimestamp(),
        'isReviewed': false,
        'isDismissed': false,
        'notes': '',
      });
    } catch (e) {
      throw Exception('Failed to create app blocked alert: $e');
    }
  }

  @override
  Future<void> createTimeRequestAlert({
    required String familyId,
    required String childUid,
    required String packageName,
    required int requestedMinutes,
  }) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('children')
          .doc(childUid)
          .collection('alerts')
          .add({
        'type': 'time_request',
        'keyword': '',
        'packageName': packageName,
        'textContext': 'Yêu cầu thêm $requestedMinutes phút',
        'timestamp': FieldValue.serverTimestamp(),
        'isReviewed': false,
        'isDismissed': false,
        'notes': '',
      });
    } catch (e) {
      throw Exception('Failed to create time request alert: $e');
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
        .where('isDismissed', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AlertModel.fromFirestore(doc)).toList();
    });
  }

  @override
  Stream<List<AlertModel>> watchAllAlerts({
    required String familyId,
    required String childUid,
  }) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childUid)
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AlertModel.fromFirestore(doc)).toList();
    });
  }

  @override
  Stream<List<AlertModel>> watchAllFamilyAlerts({required String familyId}) {
    // Dùng Firestore-level where('familyId') thay vì filter bằng Dart code client-side
    // để tránh đọc toàn bộ collectionGroup rồi mới lọc — gây lãng phí Reads nghiêm trọng
    return _firestore
        .collectionGroup('alerts')
        .where('familyId', isEqualTo: familyId)
        .where('type', isEqualTo: 'keyword_detected')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AlertModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<AlertModel?> getAlert({
    required String familyId,
    required String childUid,
    required String alertId,
  }) async {
    try {
      final doc = await _firestore
          .collection('families')
          .doc(familyId)
          .collection('children')
          .doc(childUid)
          .collection('alerts')
          .doc(alertId)
          .get();
      if (doc.exists) {
        return AlertModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get alert: $e');
    }
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

  @override
  Future<void> addNotesToAlert({
    required String familyId,
    required String childUid,
    required String alertId,
    required String notes,
  }) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('children')
          .doc(childUid)
          .collection('alerts')
          .doc(alertId)
          .update({'notes': notes});
    } catch (e) {
      throw Exception('Failed to add notes to alert: $e');
    }
  }

  @override
  Future<void> dismissAlert({
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
          .update({'isDismissed': true, 'isReviewed': true});
    } catch (e) {
      throw Exception('Failed to dismiss alert: $e');
    }
  }

  @override
  Stream<List<String>> watchKeywords(String familyId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('settings')
        .doc('keywords')
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data()?['keywords'] == null) {
        return ['tự tử', 'đánh nhau', 'cờ bạc', 'ma túy'];
      }
      return List<String>.from(doc.data()!['keywords']);
    });
  }
}
