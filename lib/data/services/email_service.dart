import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/weekly_report.dart';

class EmailService {
  final FirebaseFunctions _functions;

  EmailService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  Future<bool> sendWeeklyReport({
    required String recipientEmail,
    required WeeklyReport report,
    required String childName,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendWeeklyReportEmail');
      final result = await callable.call({
        'recipientEmail': recipientEmail,
        'childName': childName,
        'weekStartDate': report.weekStartDate,
        'weekEndDate': report.weekEndDate,
        'totalMinutes': report.totalMinutes,
        'previousWeekMinutes': report.previousWeekMinutes,
        'percentChange': report.percentChange,
        'topApps': report.topApps,
        'usageByApp': report.usageByApp,
        'improvements': report.improvements,
        'concerns': report.concerns,
      });
      return result.data['success'] == true;
    } catch (e) {
      debugPrint('Error sending weekly report email: $e');
      return false;
    }
  }

  Future<bool> updateEmailPreference({
    required String uid,
    required bool enabled,
  }) async {
    try {
      final callable = _functions.httpsCallable('updateReportEmailPreference');
      await callable.call({
        'uid': uid,
        'enabled': enabled,
      });
      return true;
    } catch (e) {
      debugPrint('Error updating email preference: $e');
      return false;
    }
  }
}
