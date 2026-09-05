import '../../../domain/repositories/usage_repository.dart';
import '../../../domain/repositories/family_repository.dart';

class LoadDashboardDataUseCase {
  final UsageRepository _usageRepository;
  final FamilyRepository _familyRepository;

  LoadDashboardDataUseCase(this._usageRepository, this._familyRepository);

  Future<DashboardData> execute({
    required String familyId,
    required String childUid,
  }) async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final usageLogs = await _usageRepository.getUsageByChild(childUid, dateStr);

    final totalMinutes = usageLogs.fold<int>(
      0,
      (sum, log) => sum + log.durationMinutes,
    );

    final usageByApp = <String, int>{};
    for (final log in usageLogs) {
      usageByApp[log.appName] =
          (usageByApp[log.appName] ?? 0) + log.durationMinutes;
    }

    final dailyTotals = <String, int>{};
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final dayLogs = await _usageRepository.getUsageByChild(childUid, dateKey);
      dailyTotals[dateKey] =
          dayLogs.fold<int>(0, (sum, log) => sum + log.durationMinutes);
    }

    return DashboardData(
      totalMinutesToday: totalMinutes,
      usageByApp: usageByApp,
      dailyTotals: dailyTotals,
      recentLogs: usageLogs,
    );
  }
}

class DashboardData {
  final int totalMinutesToday;
  final Map<String, int> usageByApp;
  final Map<String, int> dailyTotals;
  final List<dynamic> recentLogs;

  const DashboardData({
    required this.totalMinutesToday,
    required this.usageByApp,
    required this.dailyTotals,
    required this.recentLogs,
  });
}
