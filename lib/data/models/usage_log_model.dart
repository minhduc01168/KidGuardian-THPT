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

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  factory UsageLogModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = (doc.data() as Map<String, dynamic>?) ?? {};
    return UsageLogModel(
      docId: doc.id,
      childUid: data['childUid']?.toString() ?? '',
      familyId: data['familyId']?.toString() ?? '',
      appPackage: data['appPackage']?.toString() ?? '',
      appName: data['appName']?.toString() ?? '',
      startTime: _parseDateTime(data['startTime']),
      endTime: _parseDateTime(data['endTime']),
      durationMinutes: (data['durationMinutes'] is num)
          ? (data['durationMinutes'] as num).toInt()
          : int.tryParse(data['durationMinutes']?.toString() ?? '0') ?? 0,
      date: data['date']?.toString() ?? '',
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
