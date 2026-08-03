import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/app_utils.dart';
import '../../domain/entities/weekly_report.dart';
import '../../domain/entities/monthly_report.dart';
import '../../domain/repositories/report_repository.dart';
import '../../domain/repositories/usage_repository.dart';
import '../models/weekly_report_model.dart';
import '../models/monthly_report_model.dart';
import '../services/email_service.dart';

class ReportRepositoryImpl implements ReportRepository {
  final FirebaseFirestore _firestore;
  final UsageRepository _usageRepository;
  final EmailService _emailService;

  ReportRepositoryImpl({
    FirebaseFirestore? firestore,
    required UsageRepository usageRepository,
    EmailService? emailService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _usageRepository = usageRepository,
        _emailService = emailService ?? EmailService();

  @override
  Future<WeeklyReport> generateWeeklyReport(
    String childUid,
    String familyId,
  ) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final previousWeekStart = weekStart.subtract(const Duration(days: 7));
    final previousWeekEnd = weekStart.subtract(const Duration(days: 1));

    final weekStartStr = _getDateString(weekStart);
    final weekEndStr = _getDateString(weekEnd);
    final prevWeekStartStr = _getDateString(previousWeekStart);
    final prevWeekEndStr = _getDateString(previousWeekEnd);

    // Get current week data
    final currentWeekLogsRaw = await _usageRepository.getUsageByDateRange(
      childUid,
      weekStartStr,
      weekEndStr,
    );

    // Get previous week data
    final previousWeekLogsRaw = await _usageRepository.getUsageByDateRange(
      childUid,
      prevWeekStartStr,
      prevWeekEndStr,
    );

    // Lọc bỏ system app / unmonitored apps (KidGuardian, Xm, daemon)
    final currentWeekLogs = currentWeekLogsRaw.where((log) {
      final pkg = log.appPackage.isNotEmpty ? log.appPackage : log.appName;
      return !AppUtils.isSystemOrUnmonitoredApp(pkg);
    }).toList();

    final previousWeekLogs = previousWeekLogsRaw.where((log) {
      final pkg = log.appPackage.isNotEmpty ? log.appPackage : log.appName;
      return !AppUtils.isSystemOrUnmonitoredApp(pkg);
    }).toList();

    // Calculate totals
    int totalMinutes = 0;
    int previousWeekMinutes = 0;
    Map<String, int> usageByApp = {};
    Map<String, int> previousWeekUsageByApp = {};

    for (final log in currentWeekLogs) {
      totalMinutes += log.durationMinutes;
      final displayName = AppUtils.getAppNameFromLog(log.appPackage, log.appName);
      usageByApp[displayName] =
          (usageByApp[displayName] ?? 0) + log.durationMinutes;
    }

    for (final log in previousWeekLogs) {
      previousWeekMinutes += log.durationMinutes;
      final displayName = AppUtils.getAppNameFromLog(log.appPackage, log.appName);
      previousWeekUsageByApp[displayName] =
          (previousWeekUsageByApp[displayName] ?? 0) + log.durationMinutes;
    }

    // Calculate percent change
    double percentChange = 0;
    if (previousWeekMinutes > 0) {
      percentChange =
          ((totalMinutes - previousWeekMinutes) / previousWeekMinutes * 100);
    } else if (totalMinutes > 0) {
      percentChange = 100;
    }

    // Get top apps
    final sortedApps = usageByApp.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topApps = sortedApps.take(3).map((e) => e.key).toList();

    // Generate insights
    final improvements = <String>[];
    final concerns = <String>[];

    if (percentChange < -10) {
      improvements.add('Giảm ${percentChange.abs().toStringAsFixed(0)}% thời gian sử dụng');
    } else if (percentChange > 10) {
      concerns.add('Tăng ${percentChange.toStringAsFixed(0)}% thời gian sử dụng');
    }

    for (final app in topApps) {
      final current = usageByApp[app] ?? 0;
      final previous = previousWeekUsageByApp[app] ?? 0;
      if (previous > 0) {
        final appChange = ((current - previous) / previous * 100);
        if (appChange > 20) {
          concerns.add('$app tăng ${appChange.toStringAsFixed(0)}%');
        } else if (appChange < -20) {
          improvements.add('$app giảm ${appChange.abs().toStringAsFixed(0)}%');
        }
      }
    }

    // Create report model
    final report = WeeklyReportModel(
      reportId: '',
      childUid: childUid,
      familyId: familyId,
      weekStartDate: weekStartStr,
      weekEndDate: weekEndStr,
      totalMinutes: totalMinutes,
      previousWeekMinutes: previousWeekMinutes,
      usageByApp: usageByApp,
      previousWeekUsageByApp: previousWeekUsageByApp,
      topApps: topApps,
      percentChange: percentChange,
      improvements: improvements,
      concerns: concerns,
      generatedAt: now,
    );

    // Save/Update in Firestore
    try {
      final query = await _firestore
          .collection('weekly_reports')
          .where('childUid', isEqualTo: childUid)
          .where('weekStartDate', isEqualTo: weekStartStr)
          .get();

      if (query.docs.isNotEmpty) {
        final docId = query.docs.first.id;
        await _firestore.collection('weekly_reports').doc(docId).update(report.toMap());
        return WeeklyReportModel(
          reportId: docId,
          childUid: childUid,
          familyId: familyId,
          weekStartDate: weekStartStr,
          weekEndDate: weekEndStr,
          totalMinutes: totalMinutes,
          previousWeekMinutes: previousWeekMinutes,
          usageByApp: usageByApp,
          previousWeekUsageByApp: previousWeekUsageByApp,
          topApps: topApps,
          percentChange: percentChange,
          improvements: improvements,
          concerns: concerns,
          generatedAt: now,
        );
      } else {
        final docRef = await _firestore.collection('weekly_reports').add(report.toMap());
        return WeeklyReportModel(
          reportId: docRef.id,
          childUid: childUid,
          familyId: familyId,
          weekStartDate: weekStartStr,
          weekEndDate: weekEndStr,
          totalMinutes: totalMinutes,
          previousWeekMinutes: previousWeekMinutes,
          usageByApp: usageByApp,
          previousWeekUsageByApp: previousWeekUsageByApp,
          topApps: topApps,
          percentChange: percentChange,
          improvements: improvements,
          concerns: concerns,
          generatedAt: now,
        );
      }
    } catch (_) {
      return report;
    }
  }

  @override
  Future<List<WeeklyReport>> getReportsByFamily(
    String familyId, {
    int limit = 4,
  }) async {
    try {
      final query = await _firestore
          .collection('weekly_reports')
          .where('familyId', isEqualTo: familyId)
          .get();

      final list = query.docs
          .map((doc) => WeeklyReportModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
      return list.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<WeeklyReport>> getReportsByChild(
    String childUid, {
    int limit = 4,
  }) async {
    try {
      final query = await _firestore
          .collection('weekly_reports')
          .where('childUid', isEqualTo: childUid)
          .get();

      final list = query.docs
          .map((doc) => WeeklyReportModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
      return list.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<MonthlyReport> generateMonthlyReport(
    String childUid,
    String familyId,
  ) async {
    final now = DateTime.now();
    final monthEnd = now;
    final monthStart = now.subtract(const Duration(days: 29));
    final previousMonthEnd = monthStart.subtract(const Duration(days: 1));
    final previousMonthStart = previousMonthEnd.subtract(const Duration(days: 29));

    final monthStartStr = _getDateString(monthStart);
    final monthEndStr = _getDateString(monthEnd);
    final prevMonthStartStr = _getDateString(previousMonthStart);
    final prevMonthEndStr = _getDateString(previousMonthEnd);

    // Get current month data
    final currentMonthLogsRaw = await _usageRepository.getUsageByDateRange(
      childUid,
      monthStartStr,
      monthEndStr,
    );

    // Get previous month data
    final previousMonthLogsRaw = await _usageRepository.getUsageByDateRange(
      childUid,
      prevMonthStartStr,
      prevMonthEndStr,
    );

    final currentMonthLogs = currentMonthLogsRaw.where((log) {
      final pkg = log.appPackage.isNotEmpty ? log.appPackage : log.appName;
      return !AppUtils.isSystemOrUnmonitoredApp(pkg);
    }).toList();

    final previousMonthLogs = previousMonthLogsRaw.where((log) {
      final pkg = log.appPackage.isNotEmpty ? log.appPackage : log.appName;
      return !AppUtils.isSystemOrUnmonitoredApp(pkg);
    }).toList();

    int totalMinutes = 0;
    int previousMonthMinutes = 0;
    Map<String, int> usageByApp = {};
    Map<String, int> previousMonthUsageByApp = {};
    Map<String, int> weeklyBreakdown = {
      'Tuần 1': 0,
      'Tuần 2': 0,
      'Tuần 3': 0,
      'Tuần 4': 0,
    };

    final normalizedMonthEnd = DateTime(monthEnd.year, monthEnd.month, monthEnd.day);

    for (final log in currentMonthLogs) {
      totalMinutes += log.durationMinutes;
      final displayName = AppUtils.getAppNameFromLog(log.appPackage, log.appName);
      usageByApp[displayName] =
          (usageByApp[displayName] ?? 0) + log.durationMinutes;

      try {
        final parsed = DateTime.parse(log.date);
        final normalizedLogDate = DateTime(parsed.year, parsed.month, parsed.day);
        final daysDiff = normalizedMonthEnd.difference(normalizedLogDate).inDays;
        if (daysDiff <= 7) {
          weeklyBreakdown['Tuần 4'] = (weeklyBreakdown['Tuần 4'] ?? 0) + log.durationMinutes;
        } else if (daysDiff <= 14) {
          weeklyBreakdown['Tuần 3'] = (weeklyBreakdown['Tuần 3'] ?? 0) + log.durationMinutes;
        } else if (daysDiff <= 21) {
          weeklyBreakdown['Tuần 2'] = (weeklyBreakdown['Tuần 2'] ?? 0) + log.durationMinutes;
        } else {
          weeklyBreakdown['Tuần 1'] = (weeklyBreakdown['Tuần 1'] ?? 0) + log.durationMinutes;
        }
      } catch (_) {}
    }

    for (final log in previousMonthLogs) {
      previousMonthMinutes += log.durationMinutes;
      final displayName = AppUtils.getAppNameFromLog(log.appPackage, log.appName);
      previousMonthUsageByApp[displayName] =
          (previousMonthUsageByApp[displayName] ?? 0) + log.durationMinutes;
    }

    double percentChange = 0;
    if (previousMonthMinutes > 0) {
      percentChange =
          ((totalMinutes - previousMonthMinutes) / previousMonthMinutes * 100);
    } else if (totalMinutes > 0) {
      percentChange = 100;
    }

    final sortedApps = usageByApp.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topApps = sortedApps.take(5).map((e) => e.key).toList();

    final improvements = <String>[];
    final concerns = <String>[];

    if (percentChange < -10) {
      improvements.add('Giảm ${percentChange.abs().toStringAsFixed(0)}% thời gian so với 30 ngày trước');
    } else if (percentChange > 10) {
      concerns.add('Tăng ${percentChange.toStringAsFixed(0)}% thời gian so với 30 ngày trước');
    }

    for (final app in topApps.take(3)) {
      final current = usageByApp[app] ?? 0;
      final previous = previousMonthUsageByApp[app] ?? 0;
      if (previous > 0) {
        final appChange = ((current - previous) / previous * 100);
        if (appChange > 25) {
          concerns.add('$app tăng ${appChange.toStringAsFixed(0)}%');
        } else if (appChange < -25) {
          improvements.add('$app giảm ${appChange.abs().toStringAsFixed(0)}%');
        }
      }
    }

    final report = MonthlyReportModel(
      reportId: '',
      childUid: childUid,
      familyId: familyId,
      monthStartDate: monthStartStr,
      monthEndDate: monthEndStr,
      totalMinutes: totalMinutes,
      previousMonthMinutes: previousMonthMinutes,
      usageByApp: usageByApp,
      previousMonthUsageByApp: previousMonthUsageByApp,
      weeklyBreakdown: weeklyBreakdown,
      topApps: topApps,
      percentChange: percentChange,
      improvements: improvements,
      concerns: concerns,
      generatedAt: now,
    );

    try {
      final query = await _firestore
          .collection('monthly_reports')
          .where('childUid', isEqualTo: childUid)
          .where('monthStartDate', isEqualTo: monthStartStr)
          .get();

      if (query.docs.isNotEmpty) {
        final docId = query.docs.first.id;
        await _firestore.collection('monthly_reports').doc(docId).update(report.toMap());
        return MonthlyReportModel(
          reportId: docId,
          childUid: childUid,
          familyId: familyId,
          monthStartDate: monthStartStr,
          monthEndDate: monthEndStr,
          totalMinutes: totalMinutes,
          previousMonthMinutes: previousMonthMinutes,
          usageByApp: usageByApp,
          previousMonthUsageByApp: previousMonthUsageByApp,
          weeklyBreakdown: weeklyBreakdown,
          topApps: topApps,
          percentChange: percentChange,
          improvements: improvements,
          concerns: concerns,
          generatedAt: now,
        );
      } else {
        final docRef = await _firestore.collection('monthly_reports').add(report.toMap());
        return MonthlyReportModel(
          reportId: docRef.id,
          childUid: childUid,
          familyId: familyId,
          monthStartDate: monthStartStr,
          monthEndDate: monthEndStr,
          totalMinutes: totalMinutes,
          previousMonthMinutes: previousMonthMinutes,
          usageByApp: usageByApp,
          previousMonthUsageByApp: previousMonthUsageByApp,
          weeklyBreakdown: weeklyBreakdown,
          topApps: topApps,
          percentChange: percentChange,
          improvements: improvements,
          concerns: concerns,
          generatedAt: now,
        );
      }
    } catch (_) {
      return report;
    }
  }

  @override
  Future<List<MonthlyReport>> getMonthlyReportsByFamily(
    String familyId, {
    int limit = 4,
  }) async {
    try {
      final query = await _firestore
          .collection('monthly_reports')
          .where('familyId', isEqualTo: familyId)
          .get();

      final list = query.docs
          .map((doc) => MonthlyReportModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
      return list.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<MonthlyReport>> getMonthlyReportsByChild(
    String childUid, {
    int limit = 4,
  }) async {
    try {
      final query = await _firestore
          .collection('monthly_reports')
          .where('childUid', isEqualTo: childUid)
          .get();

      final list = query.docs
          .map((doc) => MonthlyReportModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
      return list.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<WeeklyReport?> getLatestReport(String childUid) async {
    final reports = await getReportsByChild(childUid, limit: 1);
    return reports.isNotEmpty ? reports.first : null;
  }

  @override
  Future<bool> sendReportByEmail({
    required String recipientEmail,
    required WeeklyReport report,
    required String childName,
  }) async {
    return await _emailService.sendWeeklyReport(
      recipientEmail: recipientEmail,
      report: report,
      childName: childName,
    );
  }

  @override
  Future<bool> updateEmailPreference({
    required String uid,
    required bool enabled,
  }) async {
    return await _emailService.updateEmailPreference(
      uid: uid,
      enabled: enabled,
    );
  }

  @override
  Future<bool> getEmailPreference(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        return data?['emailReportEnabled'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
