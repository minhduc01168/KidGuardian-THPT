import '../../../domain/repositories/usage_repository.dart';

class LoadChildUsageUseCase {
  final UsageRepository _repository;

  LoadChildUsageUseCase(this._repository);

  Future<ChildUsageData> execute({
    required String childUid,
    required String date,
  }) async {
    if (childUid.isEmpty) {
      throw Exception('Child UID không hợp lệ');
    }
    if (date.isEmpty) {
      throw Exception('Ngày không hợp lệ');
    }

    final usageLogs = await _repository.getUsageByChild(childUid, date);

    final totalMinutes = usageLogs.fold<int>(
      0,
      (sum, log) => sum + log.durationMinutes,
    );

    final usageByApp = <String, int>{};
    for (final log in usageLogs) {
      usageByApp[log.appName] =
          (usageByApp[log.appName] ?? 0) + log.durationMinutes;
    }

    return ChildUsageData(
      totalMinutes: totalMinutes,
      usageByApp: usageByApp,
      logs: usageLogs,
    );
  }
}

class ChildUsageData {
  final int totalMinutes;
  final Map<String, int> usageByApp;
  final List<dynamic> logs;

  const ChildUsageData({
    required this.totalMinutes,
    required this.usageByApp,
    required this.logs,
  });
}
