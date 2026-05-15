import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/usage_log.dart';

class UsageLogModel extends UsageLog {
  const UsageLogModel({
    required super.docId,
    required super.childUid,
    required super.familyId,
    required super.appPackage,
    required super.appName,
    required super.startTime,
    required super.endTime,
    required super.durationMinutes,
    required super.date,
  });

  factory UsageLogModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UsageLogModel(
      docId: doc.id,
      childUid: data['childUid'] ?? '',
      familyId: data['familyId'] ?? '',
      appPackage: data['appPackage'] ?? '',
      appName: data['appName'] ?? '',
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationMinutes: data['durationMinutes'] ?? 0,
      date: data['date'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'childUid': childUid,
      'familyId': familyId,
      'appPackage': appPackage,
      'appName': appName,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'durationMinutes': durationMinutes,
      'date': date,
    };
  }
}
