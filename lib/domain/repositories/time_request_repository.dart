import 'package:cloud_firestore/cloud_firestore.dart';

enum TimeRequestStatus { pending, approved, rejected }

class TimeRequest {
  final String id;
  final String familyId;
  final String childUid;
  final String appPackageName;
  final String appName;
  final int requestedMinutes;
  final String reason;
  final TimeRequestStatus status;
  final DateTime timestamp;
  final String? parentResponse;

  TimeRequest({
    required this.id,
    required this.familyId,
    required this.childUid,
    required this.appPackageName,
    required this.appName,
    required this.requestedMinutes,
    required this.reason,
    required this.status,
    required this.timestamp,
    this.parentResponse,
  });

  factory TimeRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TimeRequest(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      childUid: data['childUid'] ?? '',
      appPackageName: data['appPackageName'] ?? '',
      appName: data['appName'] ?? '',
      requestedMinutes: data['requestedMinutes'] ?? 0,
      reason: data['reason'] ?? '',
      status: TimeRequestStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => TimeRequestStatus.pending,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      parentResponse: data['parentResponse'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'childUid': childUid,
      'appPackageName': appPackageName,
      'appName': appName,
      'requestedMinutes': requestedMinutes,
      'reason': reason,
      'status': status.name,
      'timestamp': FieldValue.serverTimestamp(),
      'parentResponse': parentResponse,
    };
  }
}

abstract class TimeRequestRepository {
  Future<void> submitRequest(TimeRequest request);
  Stream<List<TimeRequest>> watchRequests({required String familyId, required String childUid});
  Stream<List<TimeRequest>> watchPendingRequests({required String familyId});
  Future<void> approveRequest({required String familyId, required String childUid, required String requestId, String? response});
  Future<void> rejectRequest({required String familyId, required String childUid, required String requestId, String? response});
}

class TimeRequestRepositoryImpl implements TimeRequestRepository {
  final FirebaseFirestore _firestore;

  TimeRequestRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> submitRequest(TimeRequest request) async {
    try {
      await _firestore
          .collection('families')
          .doc(request.familyId)
          .collection('children')
          .doc(request.childUid)
          .collection('timeRequests')
          .add(request.toMap());
    } catch (e) {
      throw Exception('Failed to submit time request: $e');
    }
  }

  @override
  Stream<List<TimeRequest>> watchRequests({
    required String familyId,
    required String childUid,
  }) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childUid)
        .collection('timeRequests')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TimeRequest.fromFirestore(doc)).toList();
    });
  }

  @override
  Stream<List<TimeRequest>> watchPendingRequests({required String familyId}) {
    return _firestore
        .collectionGroup('timeRequests')
        .where('familyId', isEqualTo: familyId)
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TimeRequest.fromFirestore(doc)).toList();
    });
  }

  @override
  Future<void> approveRequest({
    required String familyId,
    required String childUid,
    required String requestId,
    String? response,
  }) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('children')
          .doc(childUid)
          .collection('timeRequests')
          .doc(requestId)
          .update({
        'status': 'approved',
        'parentResponse': response ?? 'Đã chấp nhận',
      });
    } catch (e) {
      throw Exception('Failed to approve request: $e');
    }
  }

  @override
  Future<void> rejectRequest({
    required String familyId,
    required String childUid,
    required String requestId,
    String? response,
  }) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('children')
          .doc(childUid)
          .collection('timeRequests')
          .doc(requestId)
          .update({
        'status': 'rejected',
        'parentResponse': response ?? 'Đã từ chối',
      });
    } catch (e) {
      throw Exception('Failed to reject request: $e');
    }
  }
}
