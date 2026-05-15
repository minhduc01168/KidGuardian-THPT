import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/weekly_report.dart';
import '../../domain/repositories/report_repository.dart';
import '../../domain/repositories/usage_repository.dart';
import '../models/weekly_report_model.dart';

class ReportRepositoryImpl implements ReportRepository {
  final FirebaseFirestore _firestore;
  final UsageRepository _usageRepository;

  ReportRepositoryImpl({
    FirebaseFirestore? firestore,
    required UsageRepository usageRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _usageRepository = usageRepository;

  @override
  Future<WeeklyReport> generateWeeklyReport(
    String childUid,
    String familyId,
  ) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(Duration(days: 6));
    final previousWeekStart = weekStart.subtract(Duration(days: 7));
    final previousWeekEnd = weekStart.subtract(Duration(days: 1));

    final weekStartStr = _getDateString(weekStart);
    final weekEndStr = _getDateString(weekEnd);
    final prevWeekStartStr = _getDateString(previousWeekStart);
    final prevWeekEndStr = _getDateString(previousWeekEnd);

    // Check if report already exists for this week
    final existingReports = await getReportsByChild(childUid, limit: 1);
    if (existingReports.isNotEmpty) {
      final lastReport = existingReports.first;
      if (lastReport.weekStartDate == weekStartStr) {
        return lastReport;
      }
    }

    // Get current week data
    final currentWeekLogs = await _usageRepository.getUsageByDateRange(
      childUid,
      weekStartStr,
      weekEndStr,
    );

    // Get previous week data
    final previousWeekLogs = await _usageRepository.getUsageByDateRange(
      childUid,
      prevWeekStartStr,
      prevWeekEndStr,
    );

    // Calculate totals
    int totalMinutes = 0;
    int previousWeekMinutes = 0;
    Map<String, int> usageByApp = {};
    Map<String, int> previousWeekUsageByApp = {};

    for (final log in currentWeekLogs) {
      totalMinutes += log.durationMinutes;
      usageByApp[log.appName] =
          (usageByApp[log.appName] ?? 0) + log.durationMinutes;
    }

    for (final log in previousWeekLogs) {
      previousWeekMinutes += log.durationMinutes;
      previousWeekUsageByApp[log.appName] =
          (previousWeekUsageByApp[log.appName] ?? 0) + log.durationMinutes;
    }

    // Calculate percent change
    double percentChange = 0;
    if (previousWeekMinutes > 0) {
      percentChange =
          ((totalMinutes - previousWeekMinutes) / previousWeekMinutes * 100);
    } else if (totalMinutes > 0) {
      percentChange = 100; // First week with usage = 100% increase
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

    // Check per-app changes
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

    // Create report
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

    // Save to Firestore
    final docRef = await _firestore
        .collection('weekly_reports')
        .add(report.toMap());

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

  @override
  Future<List<WeeklyReport>> getReportsByFamily(
    String familyId, {
    int limit = 4,
  }) async {
    try {
      final query = await _firestore
          .collection('weekly_reports')
          .where('familyId', isEqualTo: familyId)
          .orderBy('generatedAt', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => WeeklyReportModel.fromFirestore(doc))
          .toList();
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
          .orderBy('generatedAt', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => WeeklyReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<WeeklyReport?> getLatestReport(String childUid) async {
    final reports = await getReportsByChild(childUid, limit: 1);
    return reports.isNotEmpty ? reports.first : null;
  }

  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
