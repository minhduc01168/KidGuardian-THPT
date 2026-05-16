import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class EmergencyLogSource {
  final FirebaseFirestore? _firestoreInstance;

  EmergencyLogSource({FirebaseFirestore? firestore})
      : _firestoreInstance = firestore;

  FirebaseFirestore get _firestore => _firestoreInstance ?? FirebaseFirestore.instance;

  Future<void> logEmergencyStart({
    required String childUid,
    required String familyId,
    required String action,
    required String phoneNumber,
    required String appPackageName,
  }) async {
    try {
      await _firestore.collection('emergency_logs').add({
        'childUid': childUid,
        'familyId': familyId,
        'action': action,
        'phoneNumber': phoneNumber,
        'appPackageName': appPackageName,
        'timestamp': FieldValue.serverTimestamp(),
        'durationSeconds': 0,
        'status': 'active',
      });
    } catch (e) {
      debugPrint('EmergencyLogSource.logEmergencyStart error: $e');
    }
  }

  Future<void> logEmergencyEnd({
    required String childUid,
    required int durationSeconds,
  }) async {
    try {
      final query = await _firestore
          .collection('emergency_logs')
          .where('childUid', isEqualTo: childUid)
          .where('status', isEqualTo: 'active')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          'durationSeconds': durationSeconds,
          'status': 'completed',
        });
      }
    } catch (e) {
      debugPrint('EmergencyLogSource.logEmergencyEnd error: $e');
    }
  }

  Future<String?> getParentPhoneNumber(String parentUid) async {
    try {
      final doc = await _firestore.collection('users').doc(parentUid).get();
      if (!doc.exists) return null;
      final data = doc.data();
      return data?['phoneNumber'] as String?;
    } catch (e) {
      debugPrint('EmergencyLogSource.getParentPhoneNumber error: $e');
      return null;
    }
  }

  Future<String?> getParentName(String parentUid) async {
    try {
      final doc = await _firestore.collection('users').doc(parentUid).get();
      if (!doc.exists) return null;
      final data = doc.data();
      return data?['displayName'] as String?;
    } catch (e) {
      debugPrint('EmergencyLogSource.getParentName error: $e');
      return null;
    }
  }
}
