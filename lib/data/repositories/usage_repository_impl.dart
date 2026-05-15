import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/usage_log.dart';
import '../../domain/repositories/usage_repository.dart';
import '../models/usage_log_model.dart';

class UsageRepositoryImpl implements UsageRepository {
  final FirebaseFirestore _firestore;

  UsageRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<UsageLog>> getUsageByChild(String childUid, String date) async {
    try {
      final query = await _firestore
          .collection('usage_logs')
          .where('childUid', isEqualTo: childUid)
          .where('date', isEqualTo: date)
          .orderBy('startTime', descending: true)
          .get();

      return query.docs.map((doc) => UsageLogModel.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<UsageLog>> getUsageByFamily(String familyId, String date) async {
    try {
      final query = await _firestore
          .collection('usage_logs')
          .where('familyId', isEqualTo: familyId)
          .where('date', isEqualTo: date)
          .orderBy('startTime', descending: true)
          .get();

      return query.docs.map((doc) => UsageLogModel.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<UsageLog>> getUsageByDateRange(
    String childUid,
    String startDate,
    String endDate,
  ) async {
    try {
      final query = await _firestore
          .collection('usage_logs')
          .where('childUid', isEqualTo: childUid)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .orderBy('date', descending: true)
          .get();

      return query.docs.map((doc) => UsageLogModel.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<int> getTotalUsageMinutes(String childUid, String date) async {
    final logs = await getUsageByChild(childUid, date);
    int total = 0;
    for (final log in logs) {
      total += log.durationMinutes;
    }
    return total;
  }

  @override
  Future<Map<String, int>> getUsageByApp(String childUid, String date) async {
    final logs = await getUsageByChild(childUid, date);
    final Map<String, int> usageByApp = {};

    for (final log in logs) {
      usageByApp[log.appPackage] =
          (usageByApp[log.appPackage] ?? 0) + log.durationMinutes;
    }

    return usageByApp;
  }

  @override
  Future<void> logUsage(UsageLog log) async {
    await _firestore.collection('usage_logs').add(
          UsageLogModel(
            docId: '',
            childUid: log.childUid,
            familyId: log.familyId,
            appPackage: log.appPackage,
            appName: log.appName,
            startTime: log.startTime,
            endTime: log.endTime,
            durationMinutes: log.durationMinutes,
            date: log.date,
          ).toMap(),
        );
  }
}
