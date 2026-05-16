import 'package:equatable/equatable.dart';

class LockHistoryEntryModel extends Equatable {
  final String id;
  final String appPackageName;
  final String appName;
  final String reason;
  final String? scheduleName;
  final DateTime lockedAt;
  final DateTime? unlockedAt;
  final int? durationMinutes;

  const LockHistoryEntryModel({
    required this.id,
    required this.appPackageName,
    required this.appName,
    required this.reason,
    this.scheduleName,
    required this.lockedAt,
    this.unlockedAt,
    this.durationMinutes,
  });

  LockHistoryEntryModel copyWith({
    String? id,
    String? appPackageName,
    String? appName,
    String? reason,
    String? scheduleName,
    DateTime? lockedAt,
    DateTime? unlockedAt,
    int? durationMinutes,
  }) {
    return LockHistoryEntryModel(
      id: id ?? this.id,
      appPackageName: appPackageName ?? this.appPackageName,
      appName: appName ?? this.appName,
      reason: reason ?? this.reason,
      scheduleName: scheduleName ?? this.scheduleName,
      lockedAt: lockedAt ?? this.lockedAt,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  factory LockHistoryEntryModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value != null) return DateTime.parse(value.toString());
      return DateTime.now();
    }

    return LockHistoryEntryModel(
      id: json['id'] as String? ?? '',
      appPackageName: json['appPackageName'] as String? ?? '',
      appName: json['appName'] as String? ?? '',
      reason: json['reason'] as String? ?? 'time_limit',
      scheduleName: json['scheduleName'] as String?,
      lockedAt: parseDate(json['lockedAt']),
      unlockedAt: json['unlockedAt'] != null ? parseDate(json['unlockedAt']) : null,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appPackageName': appPackageName,
      'appName': appName,
      'reason': reason,
      'scheduleName': scheduleName,
      'lockedAt': lockedAt.toIso8601String(),
      'unlockedAt': unlockedAt?.toIso8601String(),
      'durationMinutes': durationMinutes,
    };
  }

  @override
  List<Object?> get props => [
        id,
        appPackageName,
        appName,
        reason,
        scheduleName,
        lockedAt,
        unlockedAt,
        durationMinutes,
      ];
}
