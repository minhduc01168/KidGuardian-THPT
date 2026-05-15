import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/weekly_report.dart';

class WeeklyReportModel extends WeeklyReport {
  const WeeklyReportModel({
    required super.reportId,
    required super.childUid,
    required super.familyId,
    required super.weekStartDate,
    required super.weekEndDate,
    required super.totalMinutes,
    required super.previousWeekMinutes,
    required super.usageByApp,
    required super.previousWeekUsageByApp,
    required super.topApps,
    super.alertCount,
    super.violationCount,
    required super.percentChange,
    super.improvements,
    super.concerns,
    required super.generatedAt,
  });

  factory WeeklyReportModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return WeeklyReportModel(
      reportId: doc.id,
      childUid: data['childUid'] ?? '',
      familyId: data['familyId'] ?? '',
      weekStartDate: data['weekStartDate'] ?? '',
      weekEndDate: data['weekEndDate'] ?? '',
      totalMinutes: data['totalMinutes'] ?? 0,
      previousWeekMinutes: data['previousWeekMinutes'] ?? 0,
      usageByApp: Map<String, int>.from(data['usageByApp'] ?? {}),
      previousWeekUsageByApp:
          Map<String, int>.from(data['previousWeekUsageByApp'] ?? {}),
      topApps: List<String>.from(data['topApps'] ?? []),
      alertCount: data['alertCount'] ?? 0,
      violationCount: data['violationCount'] ?? 0,
      percentChange: (data['percentChange'] ?? 0).toDouble(),
      improvements: List<String>.from(data['improvements'] ?? []),
      concerns: List<String>.from(data['concerns'] ?? []),
      generatedAt: (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'childUid': childUid,
      'familyId': familyId,
      'weekStartDate': weekStartDate,
      'weekEndDate': weekEndDate,
      'totalMinutes': totalMinutes,
      'previousWeekMinutes': previousWeekMinutes,
      'usageByApp': usageByApp,
      'previousWeekUsageByApp': previousWeekUsageByApp,
      'topApps': topApps,
      'alertCount': alertCount,
      'violationCount': violationCount,
      'percentChange': percentChange,
      'improvements': improvements,
      'concerns': concerns,
      'generatedAt': Timestamp.fromDate(generatedAt),
    };
  }
}
