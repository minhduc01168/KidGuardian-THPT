import 'package:equatable/equatable.dart';

class MonthlyReport extends Equatable {
  final String reportId;
  final String childUid;
  final String familyId;
  final String monthStartDate;
  final String monthEndDate;
  final int totalMinutes;
  final int previousMonthMinutes;
  final Map<String, int> usageByApp;
  final Map<String, int> previousMonthUsageByApp;
  final Map<String, int> weeklyBreakdown; // Week 1, Week 2, Week 3, Week 4 totals
  final List<String> topApps;
  final int alertCount;
  final int violationCount;
  final double percentChange;
  final List<String> improvements;
  final List<String> concerns;
  final DateTime generatedAt;

  const MonthlyReport({
    required this.reportId,
    required this.childUid,
    required this.familyId,
    required this.monthStartDate,
    required this.monthEndDate,
    required this.totalMinutes,
    required this.previousMonthMinutes,
    required this.usageByApp,
    required this.previousMonthUsageByApp,
    required this.weeklyBreakdown,
    required this.topApps,
    this.alertCount = 0,
    this.violationCount = 0,
    required this.percentChange,
    this.improvements = const [],
    this.concerns = const [],
    required this.generatedAt,
  });

  @override
  List<Object?> get props => [
        reportId,
        childUid,
        familyId,
        monthStartDate,
        monthEndDate,
        totalMinutes,
        previousMonthMinutes,
        usageByApp,
        previousMonthUsageByApp,
        weeklyBreakdown,
        topApps,
        alertCount,
        violationCount,
        percentChange,
        improvements,
        concerns,
        generatedAt,
      ];
}
