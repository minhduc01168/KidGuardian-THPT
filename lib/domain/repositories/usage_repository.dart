import '../entities/usage_log.dart';

abstract class UsageRepository {
  Future<List<UsageLog>> getUsageByChild(String childUid, String date);
  Future<List<UsageLog>> getUsageByFamily(String familyId, String date);
  Future<List<UsageLog>> getUsageByDateRange(
    String childUid,
    String startDate,
    String endDate,
  );
  Future<int> getTotalUsageMinutes(String childUid, String date);
  Future<Map<String, int>> getUsageByApp(String childUid, String date);
  Future<void> logUsage(UsageLog log);
}
