import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kidguardian/data/models/auto_approval_rule_model.dart';
import 'package:kidguardian/domain/repositories/time_request_repository.dart';

abstract class RulesRepository {
  Future<AutoApprovalRule?> getRules(String familyId);
  Stream<AutoApprovalRule?> watchRules(String familyId);
  Future<void> saveRules(AutoApprovalRule rule);
  Future<bool> shouldAutoApprove({
    required String familyId,
    required String appPackageName,
    required int requestedMinutes,
  });
  Future<void> logAutoApprovedRequest(TimeRequest request);
  Future<int> getTodayAutoApprovedCount(String familyId);
}

class RulesRepositoryImpl implements RulesRepository {
  final FirebaseFirestore _firestore;

  RulesRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<AutoApprovalRule?> getRules(String familyId) async {
    try {
      final snapshot = await _firestore
          .collection('families')
          .doc(familyId)
          .collection('settings')
          .doc('autoApprovalRules')
          .get();

      if (snapshot.exists) {
        return AutoApprovalRule.fromFirestore(snapshot);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get rules: $e');
    }
  }

  @override
  Stream<AutoApprovalRule?> watchRules(String familyId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('settings')
        .doc('autoApprovalRules')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return AutoApprovalRule.fromFirestore(snapshot);
      }
      return null;
    });
  }

  @override
  Future<void> saveRules(AutoApprovalRule rule) async {
    try {
      await _firestore
          .collection('families')
          .doc(rule.familyId)
          .collection('settings')
          .doc('autoApprovalRules')
          .set(rule.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save rules: $e');
    }
  }

  @override
  Future<bool> shouldAutoApprove({
    required String familyId,
    required String appPackageName,
    required int requestedMinutes,
  }) async {
    try {
      final rule = await getRules(familyId);
      if (rule == null || !rule.isEnabled) {
        return false;
      }

      final isAppEnabled = rule.appSpecificRules[appPackageName] ?? false;
      if (!isAppEnabled) {
        return false;
      }

      if (requestedMinutes > rule.maxAutoApproveMinutes) {
        return false;
      }

      final todayCount = await getTodayAutoApprovedCount(familyId);
      if (todayCount >= rule.dailyAutoApproveLimit) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> logAutoApprovedRequest(TimeRequest request) async {
    try {
      await _firestore
          .collection('families')
          .doc(request.familyId)
          .collection('autoApprovalLogs')
          .add({
        'requestId': request.id,
        'childUid': request.childUid,
        'appPackageName': request.appPackageName,
        'appName': request.appName,
        'requestedMinutes': request.requestedMinutes,
        'reason': request.reason,
        'timestamp': FieldValue.serverTimestamp(),
        'date': '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
      });
    } catch (e) {
      throw Exception('Failed to log auto-approved request: $e');
    }
  }

  @override
  Future<int> getTodayAutoApprovedCount(String familyId) async {
    try {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final snapshot = await _firestore
          .collection('families')
          .doc(familyId)
          .collection('autoApprovalLogs')
          .where('date', isEqualTo: dateStr)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}
