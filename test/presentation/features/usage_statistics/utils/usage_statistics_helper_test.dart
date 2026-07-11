import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/presentation/features/usage_statistics/utils/usage_statistics_helper.dart';
import 'package:kidguardian/domain/entities/usage_log.dart';

void main() {
  group('UsageStatisticsHelper', () {
    final now = DateTime(2026, 5, 16, 14, 30);
    final logs = [
      UsageLog(
        docId: '1',
        childUid: 'child1',
        familyId: 'family1',
        appPackage: 'com.tiktok',
        appName: 'TikTok',
        startTime: now,
        endTime: now.add(const Duration(minutes: 30)),
        durationMinutes: 30,
        date: '2026-05-16',
      ),
      UsageLog(
        docId: '2',
        childUid: 'child1',
        familyId: 'family1',
        appPackage: 'com.facebook',
        appName: 'Facebook',
        startTime: now.add(const Duration(hours: 1)),
        endTime: now.add(const Duration(hours: 1, minutes: 45)),
        durationMinutes: 45,
        date: '2026-05-16',
      ),
      UsageLog(
        docId: '3',
        childUid: 'child1',
        familyId: 'family1',
        appPackage: 'com.tiktok',
        appName: 'TikTok',
        startTime: now.subtract(const Duration(days: 1)),
        endTime: now.subtract(const Duration(days: 1, minutes: -20)),
        durationMinutes: 20,
        date: '2026-05-15',
      ),
    ];

    test('groupByHour groups logs by hour', () {
      final result = UsageStatisticsHelper.groupByHour(logs);
      expect(result[14], 50); // TikTok (30) + Facebook (20) at hour 14
      expect(result[15], 45); // Facebook at hour 15
    });

    test('groupByDay groups logs by date', () {
      final result = UsageStatisticsHelper.groupByDay(logs);
      expect(result['2026-05-16'], 75);
      expect(result['2026-05-15'], 20);
    });

    test('groupByWeek groups logs by day of week', () {
      final result = UsageStatisticsHelper.groupByWeek(logs);
      // May 16, 2026 is Saturday (weekday 6) -> T7
      // May 15, 2026 is Friday (weekday 5) -> T6
      expect(result.containsKey('T7'), true);
      expect(result['T7'], 75); // Saturday: TikTok 30 + Facebook 45
      expect(result.containsKey('T6'), true);
      expect(result['T6'], 20); // Friday: TikTok 20
    });

    test('groupByApp groups logs by app name', () {
      final result = UsageStatisticsHelper.groupByApp(logs);
      expect(result['TikTok'], 50);
      expect(result['Facebook'], 45);
    });

    test('findPeakHours returns top 3 hours', () {
      final hourlyUsage = {10: 60, 14: 120, 20: 90, 8: 30};
      final result = UsageStatisticsHelper.findPeakHours(hourlyUsage);
      expect(result, [14, 20, 10]);
    });

    test('findPeakHours returns empty for empty input', () {
      final result = UsageStatisticsHelper.findPeakHours({});
      expect(result, isEmpty);
    });

    test('findPeakDay returns day with highest usage', () {
      final dailyUsage = {
        '2026-05-14': 60,
        '2026-05-15': 120,
        '2026-05-16': 90,
      };
      final result = UsageStatisticsHelper.findPeakDay(dailyUsage);
      expect(result, '2026-05-15');
    });

    test('findPeakDay returns empty for empty input', () {
      final result = UsageStatisticsHelper.findPeakDay({});
      expect(result, '');
    });

    test('formatDuration formats minutes correctly', () {
      expect(UsageStatisticsHelper.formatDuration(30), '30 phút');
      expect(UsageStatisticsHelper.formatDuration(60), '1 giờ');
      expect(UsageStatisticsHelper.formatDuration(90), '1 giờ 30 phút');
      expect(UsageStatisticsHelper.formatDuration(120), '2 giờ');
    });

    test('buildMostUsedApps creates sorted list', () {
      final usageByApp = {'TikTok': 50, 'Facebook': 45};
      final result =
          UsageStatisticsHelper.buildMostUsedApps(logs, usageByApp);
      expect(result.length, 2);
      expect(result[0].appName, 'TikTok');
      expect(result[0].totalMinutes, 50);
      expect(result[0].sessionCount, 2);
      expect(result[1].appName, 'Facebook');
      expect(result[1].totalMinutes, 45);
      expect(result[1].sessionCount, 1);
    });

    test('buildMostUsedApps calculates percentage correctly', () {
      final usageByApp = {'TikTok': 50, 'Facebook': 50};
      final result =
          UsageStatisticsHelper.buildMostUsedApps(logs, usageByApp);
      expect(result[0].percentage, 50.0);
      expect(result[1].percentage, 50.0);
    });

    test('buildMostUsedApps handles empty input', () {
      final result = UsageStatisticsHelper.buildMostUsedApps([], {});
      expect(result, isEmpty);
    });

    test('formatDateRange formats dates correctly', () {
      final start = DateTime(2026, 5, 10);
      final end = DateTime(2026, 5, 16);
      final result = UsageStatisticsHelper.formatDateRange(start, end);
      expect(result, '10/05/2026 - 16/05/2026');
    });
  });
}
