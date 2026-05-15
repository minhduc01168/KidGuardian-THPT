import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/daily_summary.dart';

class DailySummaryModel extends DailySummary {
  const DailySummaryModel({
    required super.summaryId,
    required super.childUid,
    required super.familyId,
    required super.date,
    required super.totalMinutes,
    required super.usageByApp,
    required super.topApps,
    super.alertCount,
    super.violationCount,
    super.sent,
    super.sentAt,
  });

  factory DailySummaryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DailySummaryModel(
      summaryId: doc.id,
      childUid: data['childUid'] ?? '',
      familyId: data['familyId'] ?? '',
      date: data['date'] ?? '',
      totalMinutes: data['totalMinutes'] ?? 0,
      usageByApp: Map<String, int>.from(data['usageByApp'] ?? {}),
      topApps: List<String>.from(data['topApps'] ?? []),
      alertCount: data['alertCount'] ?? 0,
      violationCount: data['violationCount'] ?? 0,
      sent: data['sent'] ?? false,
      sentAt: (data['sentAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'childUid': childUid,
      'familyId': familyId,
      'date': date,
      'totalMinutes': totalMinutes,
      'usageByApp': usageByApp,
      'topApps': topApps,
      'alertCount': alertCount,
      'violationCount': violationCount,
      'sent': sent,
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
    };
  }
}
