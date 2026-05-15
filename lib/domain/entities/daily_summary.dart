import 'package:equatable/equatable.dart';

class DailySummary extends Equatable {
  final String summaryId;
  final String childUid;
  final String familyId;
  final String date;
  final int totalMinutes;
  final Map<String, int> usageByApp;
  final List<String> topApps;
  final int alertCount;
  final int violationCount;
  final bool sent;
  final DateTime? sentAt;

  const DailySummary({
    required this.summaryId,
    required this.childUid,
    required this.familyId,
    required this.date,
    required this.totalMinutes,
    required this.usageByApp,
    required this.topApps,
    this.alertCount = 0,
    this.violationCount = 0,
    this.sent = false,
    this.sentAt,
  });

  @override
  List<Object?> get props => [
        summaryId,
        childUid,
        familyId,
        date,
        totalMinutes,
        usageByApp,
        topApps,
        alertCount,
        violationCount,
        sent,
        sentAt,
      ];
}
