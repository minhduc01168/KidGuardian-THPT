import 'package:equatable/equatable.dart';

class UsageLog extends Equatable {
  final String docId;
  final String childUid;
  final String familyId;
  final String appPackage;
  final String appName;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final String date;

  const UsageLog({
    required this.docId,
    required this.childUid,
    required this.familyId,
    required this.appPackage,
    required this.appName,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.date,
  });

  UsageLog copyWith({
    String? docId,
    String? childUid,
    String? familyId,
    String? appPackage,
    String? appName,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? date,
  }) {
    return UsageLog(
      docId: docId ?? this.docId,
      childUid: childUid ?? this.childUid,
      familyId: familyId ?? this.familyId,
      appPackage: appPackage ?? this.appPackage,
      appName: appName ?? this.appName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      date: date ?? this.date,
    );
  }

  @override
  List<Object?> get props => [
        docId,
        childUid,
        familyId,
        appPackage,
        appName,
        startTime,
        endTime,
        durationMinutes,
        date,
      ];
}
