import 'package:flutter/foundation.dart';
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
      debugPrint('[Debug Read] getUsageByChild -> Querying usage_logs for childUid: $childUid, date: $date');
      try {
        final query = await _firestore
            .collection('usage_logs')
            .where('childUid', isEqualTo: childUid)
            .where('date', isEqualTo: date)
            .get();

        final logs = query.docs
            .map((doc) => UsageLogModel.fromFirestore(doc))
            .toList();
        logs.sort((a, b) => b.startTime.compareTo(a.startTime));
        debugPrint('[Debug Read] getUsageByChild (Server-Side Index) -> Found ${logs.length} logs for date $date');
        return logs;
      } on FirebaseException catch (fe) {
        if (fe.code == 'failed-precondition' || fe.message?.contains('index') == true) {
          debugPrint('[Debug Read Warning] Composite Index chưa tạo cho childUid+date. Fallback sang RAM filtering.');
          final query = await _firestore
              .collection('usage_logs')
              .where('childUid', isEqualTo: childUid)
              .get();

          final logs = query.docs
              .map((doc) => UsageLogModel.fromFirestore(doc))
              .where((log) => log.date == date)
              .toList();
          logs.sort((a, b) => b.startTime.compareTo(a.startTime));
          debugPrint('[Debug Read] getUsageByChild (RAM Fallback) -> Found ${logs.length} logs for date $date');
          return logs;
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('[Debug Read Error] getUsageByChild ($childUid, $date): $e');
      return [];
    }
  }

  @override
  Future<List<UsageLog>> getUsageByFamily(String familyId, String date) async {
    try {
      debugPrint('[Debug Read] getUsageByFamily -> Querying usage_logs for familyId: $familyId, date: $date');
      try {
        final query = await _firestore
            .collection('usage_logs')
            .where('familyId', isEqualTo: familyId)
            .where('date', isEqualTo: date)
            .get();

        final logs = query.docs
            .map((doc) => UsageLogModel.fromFirestore(doc))
            .toList();
        logs.sort((a, b) => b.startTime.compareTo(a.startTime));
        debugPrint('[Debug Read] getUsageByFamily (Server-Side Index) -> Found ${logs.length} logs for date $date');
        return logs;
      } on FirebaseException catch (fe) {
        if (fe.code == 'failed-precondition' || fe.message?.contains('index') == true) {
          debugPrint('[Debug Read Warning] Composite Index chưa tạo cho familyId+date. Fallback sang RAM filtering.');
          final query = await _firestore
              .collection('usage_logs')
              .where('familyId', isEqualTo: familyId)
              .get();

          final logs = query.docs
              .map((doc) => UsageLogModel.fromFirestore(doc))
              .where((log) => log.date == date)
              .toList();
          logs.sort((a, b) => b.startTime.compareTo(a.startTime));
          debugPrint('[Debug Read] getUsageByFamily (RAM Fallback) -> Found ${logs.length} logs for date $date');
          return logs;
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('[Debug Read Error] getUsageByFamily ($familyId, $date): $e');
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
      debugPrint('[Debug Read] getUsageByDateRange -> childUid: $childUid, range: $startDate -> $endDate');
      // FIX: Không dùng inequality query trên date khi đã có where childUid
      // để tránh Firestore tự động chèn orderBy(date) yêu cầu Composite Index.
      // Query theo childUid (dùng single-field index mặc định), sau đó filter trên RAM.
      final query = await _firestore
          .collection('usage_logs')
          .where('childUid', isEqualTo: childUid)
          .get();

      final logs = query.docs
          .map((doc) => UsageLogModel.fromFirestore(doc))
          .where((log) =>
              log.date.compareTo(startDate) >= 0 &&
              log.date.compareTo(endDate) <= 0)
          .toList();
      logs.sort((a, b) => b.date.compareTo(a.date));
      debugPrint('[Debug Read] getUsageByDateRange -> Found ${logs.length} logs');
      return logs;
    } catch (e) {
      debugPrint('[Debug Read Error] getUsageByDateRange: $e');
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
      // Ưu tiên dùng appPackage, fallback sang appName nếu package rỗng
      // để tránh key là "" gây hiển thị "Ứng dụng không xác định" trên dashboard
      final key = log.appPackage.isNotEmpty ? log.appPackage : log.appName;
      if (key.isNotEmpty) {
        usageByApp[key] = (usageByApp[key] ?? 0) + log.durationMinutes;
      }
    }

    return usageByApp;
  }

  @override
  Future<void> logUsage(UsageLog log) async {
    try {
      debugPrint('[Debug Write] logUsage -> Attempting to add usage log for app: ${log.appPackage} (${log.durationMinutes} minutes on ${log.date})');
      final docRef = await _firestore.collection('usage_logs').add(
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
      debugPrint('[Debug Write] logUsage -> Successfully added usage log to Firestore with Doc ID: ${docRef.id}');
    } catch (e) {
      debugPrint('[Debug Write Error] Failed to log usage for ${log.appPackage}: $e');
    }
  }
}
