import 'package:equatable/equatable.dart';

class WeeklyReport extends Equatable {
  final String reportId;
  final String childUid;
  final String familyId;
  final String weekStartDate;
  final String weekEndDate;
  final int totalMinutes;
  final int previousWeekMinutes;
  final Map<String, int> usageByApp;
  final Map<String, int> previousWeekUsageByApp;
  final List<String> topApps;
  final int alertCount;
  final int violationCount;
  final double percentChange;
  final List<String> improvements;
  final List<String> concerns;
  final DateTime generatedAt;

  const WeeklyReport({
    required this.reportId,
    required this.childUid,
    required this.familyId,
    required this.weekStartDate,
    required this.weekEndDate,
    required this.totalMinutes,
    required this.previousWeekMinutes,
    required this.usageByApp,
    required this.previousWeekUsageByApp,
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
        weekStartDate,
        weekEndDate,
        totalMinutes,
        previousWeekMinutes,
        usageByApp,
        previousWeekUsageByApp,
        topApps,
        alertCount,
        violationCount,
        percentChange,
        improvements,
        concerns,
        generatedAt,
      ];
}
