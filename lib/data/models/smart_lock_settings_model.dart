import 'package:equatable/equatable.dart';

class SmartLockSettingsModel extends Equatable {
  final bool isEnabled;
  final int defaultTimeLimitMinutes;
  final bool notifyOnTimeRequest;
  final bool notifyOnAppBlocked;
  final bool notifyOnLimitReached;
  final bool notifyOnScheduleViolation;
  final DateTime? updatedAt;

  const SmartLockSettingsModel({
    this.isEnabled = true,
    this.defaultTimeLimitMinutes = 60,
    this.notifyOnTimeRequest = true,
    this.notifyOnAppBlocked = true,
    this.notifyOnLimitReached = true,
    this.notifyOnScheduleViolation = true,
    this.updatedAt,
  });

  SmartLockSettingsModel copyWith({
    bool? isEnabled,
    int? defaultTimeLimitMinutes,
    bool? notifyOnTimeRequest,
    bool? notifyOnAppBlocked,
    bool? notifyOnLimitReached,
    bool? notifyOnScheduleViolation,
    DateTime? updatedAt,
  }) {
    return SmartLockSettingsModel(
      isEnabled: isEnabled ?? this.isEnabled,
      defaultTimeLimitMinutes:
          defaultTimeLimitMinutes ?? this.defaultTimeLimitMinutes,
      notifyOnTimeRequest: notifyOnTimeRequest ?? this.notifyOnTimeRequest,
      notifyOnAppBlocked: notifyOnAppBlocked ?? this.notifyOnAppBlocked,
      notifyOnLimitReached: notifyOnLimitReached ?? this.notifyOnLimitReached,
      notifyOnScheduleViolation:
          notifyOnScheduleViolation ?? this.notifyOnScheduleViolation,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory SmartLockSettingsModel.fromJson(Map<String, dynamic> json) {
    return SmartLockSettingsModel(
      isEnabled: json['isEnabled'] as bool? ?? true,
      defaultTimeLimitMinutes:
          (json['defaultTimeLimitMinutes'] as num?)?.toInt() ?? 60,
      notifyOnTimeRequest: json['notifyOnTimeRequest'] as bool? ?? true,
      notifyOnAppBlocked: json['notifyOnAppBlocked'] as bool? ?? true,
      notifyOnLimitReached: json['notifyOnLimitReached'] as bool? ?? true,
      notifyOnScheduleViolation:
          json['notifyOnScheduleViolation'] as bool? ?? true,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is DateTime
              ? json['updatedAt'] as DateTime
              : DateTime.parse(json['updatedAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'defaultTimeLimitMinutes': defaultTimeLimitMinutes,
      'notifyOnTimeRequest': notifyOnTimeRequest,
      'notifyOnAppBlocked': notifyOnAppBlocked,
      'notifyOnLimitReached': notifyOnLimitReached,
      'notifyOnScheduleViolation': notifyOnScheduleViolation,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        isEnabled,
        defaultTimeLimitMinutes,
        notifyOnTimeRequest,
        notifyOnAppBlocked,
        notifyOnLimitReached,
        notifyOnScheduleViolation,
        updatedAt,
      ];
}
