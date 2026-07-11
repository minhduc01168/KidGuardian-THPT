import 'package:intl/intl.dart';
import '../../../../domain/entities/usage_log.dart';
import '../bloc/usage_statistics_state.dart';

class UsageStatisticsHelper {
  static Map<int, int> groupByHour(List<UsageLog> logs) {
    final Map<int, int> result = {};
    for (final log in logs) {
      final hour = log.startTime.hour;
      result[hour] = (result[hour] ?? 0) + log.durationMinutes;
    }
    return result;
  }

  static Map<String, int> groupByDay(List<UsageLog> logs) {
    final Map<String, int> result = {};
    for (final log in logs) {
      result[log.date] = (result[log.date] ?? 0) + log.durationMinutes;
    }
    return result;
  }

  static Map<String, int> groupByWeek(List<UsageLog> logs) {
    final Map<String, int> result = {};
    final dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    for (final log in logs) {
      final dayIndex = log.startTime.weekday - 1;
      final dayName = dayNames[dayIndex];
      result[dayName] = (result[dayName] ?? 0) + log.durationMinutes;
    }
    return result;
  }

  static Map<String, int> groupByApp(List<UsageLog> logs) {
    final Map<String, int> result = {};
    for (final log in logs) {
      result[log.appName] = (result[log.appName] ?? 0) + log.durationMinutes;
    }
    return result;
  }

  static List<int> findPeakHours(Map<int, int> hourlyUsage, {int count = 3}) {
    if (hourlyUsage.isEmpty) return [];
    final sorted = hourlyUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(count).map((e) => e.key).toList();
  }

  static String findPeakDay(Map<String, int> dailyUsage) {
    if (dailyUsage.isEmpty) return '';
    return dailyUsage.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  static String formatDuration(int minutes) {
    if (minutes < 60) return '$minutes phút';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '$hours giờ';
    return '$hours giờ $remainingMinutes phút';
  }

  static List<AppUsageSummary> buildMostUsedApps(
    List<UsageLog> logs,
    Map<String, int> usageByApp,
  ) {
    final totalMinutes = usageByApp.values.fold<int>(
      0,
      (sum, minutes) => sum + minutes,
    );

    final Map<String, List<UsageLog>> logsByApp = {};
    for (final log in logs) {
      logsByApp.putIfAbsent(log.appName, () => []).add(log);
    }

    final List<AppUsageSummary> summaries = [];
    for (final entry in usageByApp.entries) {
      final appLogs = logsByApp[entry.key] ?? [];
      final sessionCount = appLogs.length;
      final percentage =
          totalMinutes > 0 ? (entry.value / totalMinutes * 100) : 0.0;
      final avgMinutes =
          sessionCount > 0 ? (entry.value / sessionCount).round() : 0;

      summaries.add(AppUsageSummary(
        appName: entry.key,
        appPackage: appLogs.isNotEmpty ? appLogs.first.appPackage : '',
        totalMinutes: entry.value,
        percentage: percentage,
        sessionCount: sessionCount,
        avgMinutesPerSession: avgMinutes,
      ));
    }

    summaries.sort((a, b) => b.totalMinutes.compareTo(a.totalMinutes));
    return summaries;
  }

  static String formatDateRange(DateTime start, DateTime end) {
    final startStr = DateFormat('dd/MM/yyyy').format(start);
    final endStr = DateFormat('dd/MM/yyyy').format(end);
    return '$startStr - $endStr';
  }
}
