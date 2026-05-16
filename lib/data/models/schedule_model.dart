import 'package:equatable/equatable.dart';

class ScheduleModel extends Equatable {
  final String id;
  final String name;
  final String type;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final Map<String, bool> days;
  final bool isEnabled;

  const ScheduleModel({
    required this.id,
    required this.name,
    required this.type,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.days,
    this.isEnabled = true,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    final daysMap = json['days'] as Map<dynamic, dynamic>? ?? {};
    final parsedDays = <String, bool>{};
    daysMap.forEach((key, value) {
      parsedDays[key.toString()] = value == true;
    });

    return ScheduleModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'blocked',
      startHour: (json['startHour'] as num?)?.toInt() ?? 0,
      startMinute: (json['startMinute'] as num?)?.toInt() ?? 0,
      endHour: (json['endHour'] as num?)?.toInt() ?? 0,
      endMinute: (json['endMinute'] as num?)?.toInt() ?? 0,
      days: parsedDays,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'days': days,
      'isEnabled': isEnabled,
    };
  }

  ScheduleModel copyWith({
    String? id,
    String? name,
    String? type,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    Map<String, bool>? days,
    bool? isEnabled,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      days: days ?? this.days,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        startHour,
        startMinute,
        endHour,
        endMinute,
        days,
        isEnabled,
      ];
}
