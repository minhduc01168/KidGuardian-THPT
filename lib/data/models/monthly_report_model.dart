import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/monthly_report.dart';

class MonthlyReportModel extends MonthlyReport {
  const MonthlyReportModel({
    required super.reportId,
    required super.childUid,
    required super.familyId,
    required super.monthStartDate,
    required super.monthEndDate,
    required super.totalMinutes,
    required super.previousMonthMinutes,
    required super.usageByApp,
    required super.previousMonthUsageByApp,
    required super.weeklyBreakdown,
    required super.topApps,
    super.alertCount,
    super.violationCount,
    required super.percentChange,
    super.improvements,
    super.concerns,
    required super.generatedAt,
  });

  factory MonthlyReportModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MonthlyReportModel(
      reportId: doc.id,
      childUid: data['childUid'] ?? '',
      familyId: data['familyId'] ?? '',
      monthStartDate: data['monthStartDate'] ?? '',
      monthEndDate: data['monthEndDate'] ?? '',
      totalMinutes: data['totalMinutes'] ?? 0,
      previousMonthMinutes: data['previousMonthMinutes'] ?? 0,
      usageByApp: Map<String, int>.from(data['usageByApp'] ?? {}),
      previousMonthUsageByApp:
          Map<String, int>.from(data['previousMonthUsageByApp'] ?? {}),
      weeklyBreakdown: Map<String, int>.from(data['weeklyBreakdown'] ?? {}),
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
      'monthStartDate': monthStartDate,
      'monthEndDate': monthEndDate,
      'totalMinutes': totalMinutes,
      'previousMonthMinutes': previousMonthMinutes,
      'usageByApp': usageByApp,
      'previousMonthUsageByApp': previousMonthUsageByApp,
      'weeklyBreakdown': weeklyBreakdown,
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
