import '../entities/weekly_report.dart';

abstract class ReportRepository {
  Future<WeeklyReport> generateWeeklyReport(String childUid, String familyId);
  Future<List<WeeklyReport>> getReportsByFamily(String familyId, {int limit = 4});
  Future<List<WeeklyReport>> getReportsByChild(String childUid, {int limit = 4});
  Future<WeeklyReport?> getLatestReport(String childUid);
  Future<bool> sendReportByEmail({
    required String recipientEmail,
    required WeeklyReport report,
    required String childName,
  });
  Future<bool> updateEmailPreference({
    required String uid,
    required bool enabled,
  });
  Future<bool> getEmailPreference(String uid);
}
