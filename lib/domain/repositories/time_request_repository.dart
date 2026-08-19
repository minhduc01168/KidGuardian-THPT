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
    // BUG-4 FIX: Dùng collectionGroup query thay vì double switchMap
    // switchMap cũ restart toàn bộ stream mỗi khi family doc thay đổi
    // → gây _RequestsUpdated emit liên tục → UI hiện lặp
    return _firestore
        .collectionGroup('timeRequests')
        .where('familyId', isEqualTo: familyId)
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => TimeRequest.fromFirestore(doc)).toList())
        .distinct((prev, next) {
      // Chỉ emit khi danh sách ID thực sự thay đổi
      final prevIds = prev.map((r) => r.id).join(',');
      final nextIds = next.map((r) => r.id).join(',');
      return prevIds == nextIds;
    });
  }

  @override
  Stream<List<TimeRequest>> watchAllRequests({required String familyId}) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .snapshots()
        .switchMap((familySnapshot) {
      final familyData = familySnapshot.data() ?? {};
      final List<dynamic> rawChildUids = familyData['childUids'] ?? [];
      final Set<String> childUids = rawChildUids.map((e) => e.toString()).toSet();

      return _firestore
          .collection('families')
          .doc(familyId)
          .collection('children')
          .snapshots()
          .switchMap((childrenSnapshot) {
        final allChildUids = Set<String>.from(childUids);
        for (final doc in childrenSnapshot.docs) {
          allChildUids.add(doc.id);
        }

        if (allChildUids.isEmpty) {
          return Stream.value(<TimeRequest>[]);
        }

        final streams = allChildUids.map((childUid) {
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
        });
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
      final reqDocRef = _firestore
          .collection('families')
          .doc(familyId)
          .collection('children')
          .doc(childUid)
          .collection('timeRequests')
          .doc(requestId);

      final reqSnap = await reqDocRef.get();
      if (reqSnap.exists) {
        final reqData = reqSnap.data() ?? {};
        final appPackageName = reqData['appPackageName'] as String? ?? '';
        final requestedMinutes = reqData['requestedMinutes'] as int? ?? 0;
        final appName = reqData['appName'] as String? ?? '';

        if (appPackageName.isNotEmpty && requestedMinutes > 0) {
          final limitRef = _firestore
              .collection('families')
              .doc(familyId)
              .collection('children')
              .doc(childUid)
              .collection('timeLimits')
              .doc(appPackageName);

          final limitSnap = await limitRef.get();
          const dayKeys = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
          final dayOfWeek = dayKeys[DateTime.now().weekday - 1];

          if (limitSnap.exists) {
            final limitData = limitSnap.data() ?? {};
            final Map<String, dynamic> limits = Map<String, dynamic>.from(limitData['limits'] ?? {});
            final int currentLimit = (limits[dayOfWeek] as int?) ?? (limits['everyday'] as int?) ?? 60;
            limits[dayOfWeek] = currentLimit + requestedMinutes;
            await limitRef.set({
              'appPackageName': appPackageName,
              'appName': appName.isNotEmpty ? appName : (limitData['appName'] ?? appPackageName),
              'limits': limits,
              'isBlocked': false,
            }, SetOptions(merge: true));
          } else {
            await limitRef.set({
              'appPackageName': appPackageName,
              'appName': appName,
              'limits': {
                dayOfWeek: 60 + requestedMinutes,
              },
              'isBlocked': false,
            });
          }
          debugPrint('[approveRequest] Added $requestedMinutes mins to $appPackageName limit ($dayOfWeek)');
        }
      }

      await reqDocRef.update({
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
