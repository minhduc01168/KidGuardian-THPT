import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/app_utils.dart';
import '../../domain/entities/daily_summary.dart';
import '../../domain/repositories/summary_repository.dart';
import '../../domain/repositories/usage_repository.dart';
import '../../domain/repositories/alert_repository.dart';
import '../models/daily_summary_model.dart';

class SummaryRepositoryImpl implements SummaryRepository {
  final FirebaseFirestore _firestore;
  final UsageRepository _usageRepository;
  final AlertRepository? _alertRepository;

  SummaryRepositoryImpl({
    FirebaseFirestore? firestore,
    required UsageRepository usageRepository,
    AlertRepository? alertRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _usageRepository = usageRepository,
        _alertRepository = alertRepository;

  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<DailySummary> generateDailySummary(
    String childUid,
    String familyId,
    String date,
  ) async {
    final isToday = date == _getTodayString();

    // Nếu không phải hôm nay và đã có summary quá khứ → lấy summary đã lưu
    if (!isToday) {
      try {
        final query = await _firestore
            .collection('daily_summaries')
            .where('childUid', isEqualTo: childUid)
            .where('date', isEqualTo: date)
            .get();

        if (query.docs.isNotEmpty) {
          return DailySummaryModel.fromFirestore(query.docs.first);
        }
      } catch (_) {}
    }

    // Lấy dữ liệu usage và lọc bỏ system app / unmonitored apps (KidGuardian, Xm, daemon)
    final rawLogs = await _usageRepository.getUsageByChild(childUid, date);
    final validLogs = rawLogs.where((log) {
      final pkg = log.appPackage.isNotEmpty ? log.appPackage : log.appName;
      return !AppUtils.isSystemOrUnmonitoredApp(pkg);
    }).toList();

    int totalMinutes = 0;
    final Map<String, int> usageByApp = {};

    for (final log in validLogs) {
      totalMinutes += log.durationMinutes;
      final displayName = AppUtils.getAppNameFromLog(log.appPackage, log.appName);
      usageByApp[displayName] = (usageByApp[displayName] ?? 0) + log.durationMinutes;
    }

    // Sort theo thời lượng sử dụng và lấy top 3
    final sortedApps = usageByApp.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topApps = sortedApps.take(3).map((e) => e.key).toList();

    // Lấy số lượng cảnh báo trong ngày
    int alertCount = 0;
    if (_alertRepository != null) {
      try {
        final alertsStream = _alertRepository!.watchAllAlerts(
          familyId: familyId,
          childUid: childUid,
        );
        final alerts = await alertsStream.first;
        alertCount = alerts.where((alert) {
          if (alert.timestamp == null) return false;
          final alertDate = '${alert.timestamp!.year}-${alert.timestamp!.month.toString().padLeft(2, '0')}-${alert.timestamp!.day.toString().padLeft(2, '0')}';
          return alertDate == date;
        }).length;
      } catch (e) {
        alertCount = 0;
      }
    }

    final summary = DailySummaryModel(
      summaryId: '',
      childUid: childUid,
      familyId: familyId,
      date: date,
      totalMinutes: totalMinutes,
      usageByApp: usageByApp,
      topApps: topApps,
      alertCount: alertCount,
      violationCount: 0,
      sent: false,
    );

    // Lưu hoặc cập nhật Firestore
    try {
      final query = await _firestore
          .collection('daily_summaries')
          .where('childUid', isEqualTo: childUid)
          .where('date', isEqualTo: date)
          .get();

      if (query.docs.isNotEmpty) {
        final docId = query.docs.first.id;
        await _firestore.collection('daily_summaries').doc(docId).update(summary.toMap());
        return DailySummaryModel(
          summaryId: docId,
          childUid: childUid,
          familyId: familyId,
          date: date,
          totalMinutes: totalMinutes,
          usageByApp: usageByApp,
          topApps: topApps,
          alertCount: alertCount,
        );
      } else {
        final docRef = await _firestore.collection('daily_summaries').add(summary.toMap());
        return DailySummaryModel(
          summaryId: docRef.id,
          childUid: childUid,
          familyId: familyId,
          date: date,
          totalMinutes: totalMinutes,
          usageByApp: usageByApp,
          topApps: topApps,
          alertCount: alertCount,
        );
      }
    } catch (_) {
      return summary;
    }
  }

  @override
  Future<List<DailySummary>> getSummariesByFamily(
    String familyId, {
    int limit = 7,
  }) async {
    try {
      final query = await _firestore
          .collection('daily_summaries')
          .where('familyId', isEqualTo: familyId)
          .get();

      final list = query.docs
          .map((doc) => DailySummaryModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<DailySummary>> getSummariesByChild(
    String childUid, {
    int limit = 7,
  }) async {
    try {
      final query = await _firestore
          .collection('daily_summaries')
          .where('childUid', isEqualTo: childUid)
          .get();

      final list = query.docs
          .map((doc) => DailySummaryModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> markAsSent(String summaryId) async {
    await _firestore.collection('daily_summaries').doc(summaryId).update({
      'sent': true,
      'sentAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<bool> hasSummaryForDate(String childUid, String date) async {
    try {
      final query = await _firestore
          .collection('daily_summaries')
          .where('childUid', isEqualTo: childUid)
          .get();

      return query.docs.any((doc) => doc.data()['date'] == date);
    } catch (e) {
      return false;
    }
  }
}
