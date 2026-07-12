import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

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
        (s) => s.name.toLowerCase() == (data['status'] ?? '').toString().toLowerCase(),
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
  Stream<List<TimeRequest>> watchAllRequests({required String familyId});
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
          .add(request.toMap())
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => throw TimeoutException('Offline sync'),
          );
    } catch (e) {
      if (e is TimeoutException) return; // Proceed since data is cached locally
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
        .collection('families')
        .doc(familyId)
        .collection('children')
        .snapshots()
        .switchMap((childrenSnapshot) {
      if (childrenSnapshot.docs.isEmpty) {
        return Stream.value(<TimeRequest>[]);
      }
      final streams = childrenSnapshot.docs.map((childDoc) {
        final childUid = childDoc.id;
        return _firestore
            .collection('families')
            .doc(familyId)
            .collection('children')
            .doc(childUid)
            .collection('timeRequests')
            .snapshots()
            .map((snapshot) {
          return snapshot.docs
              .map((doc) => TimeRequest.fromFirestore(doc))
              .where((req) => req.status == TimeRequestStatus.pending)
              .toList();
        }).handleError((error) {
          debugPrint('[watchPendingRequests] Error reading timeRequests for $childUid: $error');
          return <TimeRequest>[];
        });
      }).toList();

      return Rx.combineLatestList(streams).map((listOfLists) {
        final combined = listOfLists.expand((list) => list).toList();
        combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return combined.take(50).toList();
      }).handleError((error) {
        debugPrint('[watchPendingRequests] combineLatestList error: $error');
        return <TimeRequest>[];
      });
    }).handleError((error) {
      debugPrint('[watchPendingRequests] switchMap outer error: $error');
      return <TimeRequest>[];
    });
  }

  @override
  Stream<List<TimeRequest>> watchAllRequests({required String familyId}) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .snapshots()
        .switchMap((childrenSnapshot) {
      if (childrenSnapshot.docs.isEmpty) {
        return Stream.value(<TimeRequest>[]);
      }
      final streams = childrenSnapshot.docs.map((childDoc) {
        final childUid = childDoc.id;
        return _firestore
            .collection('families')
            .doc(familyId)
            .collection('children')
            .doc(childUid)
            .collection('timeRequests')
            .snapshots()
            .map((snapshot) {
          return snapshot.docs.map((doc) => TimeRequest.fromFirestore(doc)).toList();
        }).handleError((error) {
          debugPrint('[watchAllRequests] Error reading timeRequests for $childUid: $error');
          return <TimeRequest>[];
        });
      }).toList();

      return Rx.combineLatestList(streams).map((listOfLists) {
        final combined = listOfLists.expand((list) => list).toList();
        combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return combined.take(50).toList();
      }).handleError((error) {
        debugPrint('[watchAllRequests] combineLatestList error: $error');
        return <TimeRequest>[];
      });
    }).handleError((error) {
      debugPrint('[watchAllRequests] switchMap outer error: $error');
      return <TimeRequest>[];
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
      }).timeout(
        const Duration(seconds: 3),
        onTimeout: () => throw TimeoutException('Offline sync'),
      );
    } catch (e) {
      if (e is TimeoutException) return;
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
      }).timeout(
        const Duration(seconds: 3),
        onTimeout: () => throw TimeoutException('Offline sync'),
      );
    } catch (e) {
      if (e is TimeoutException) return;
      throw Exception('Failed to reject request: $e');
    }
  }
}
