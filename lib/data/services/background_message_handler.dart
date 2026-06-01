import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.data}');

  if (message.data['type'] == 'time_request_action') {
    await _processTimeRequestAction(message.data);
  }
}

Future<void> _processTimeRequestAction(Map<String, dynamic> data) async {
  final action = data['action'] as String? ?? '';
  final requestId = data['requestId'] as String? ?? '';
  final familyId = data['familyId'] as String? ?? '';
  final childUid = data['childUid'] as String? ?? '';

  if (requestId.isEmpty || familyId.isEmpty || childUid.isEmpty) {
    debugPrint('Invalid time request action data');
    return;
  }

  try {
    final firestore = FirebaseFirestore.instance;
    final docRef = firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childUid)
        .collection('timeRequests')
        .doc(requestId);

    if (action == 'approve') {
      await docRef.update({
        'status': 'approved',
        'parentResponse': 'Đã duyệt nhanh từ thông báo',
        'processedAt': FieldValue.serverTimestamp(),
      });
    } else if (action == 'reject') {
      await docRef.update({
        'status': 'rejected',
        'parentResponse': 'Đã từ chối nhanh từ thông báo',
        'processedAt': FieldValue.serverTimestamp(),
      });
    }
  } catch (e) {
    debugPrint('Error processing background time request: $e');
  }
}
