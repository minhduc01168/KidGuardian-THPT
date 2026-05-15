import '../entities/daily_summary.dart';

abstract class SummaryRepository {
  Future<DailySummary> generateDailySummary(String childUid, String familyId, String date);
  Future<List<DailySummary>> getSummariesByFamily(String familyId, {int limit = 7});
  Future<List<DailySummary>> getSummariesByChild(String childUid, {int limit = 7});
  Future<void> markAsSent(String summaryId);
  Future<bool> hasSummaryForDate(String childUid, String date);
}
