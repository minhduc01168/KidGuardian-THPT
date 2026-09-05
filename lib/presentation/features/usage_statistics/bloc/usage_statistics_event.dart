import 'package:equatable/equatable.dart';

enum TimePeriod { hour, day, week }

abstract class UsageStatisticsEvent extends Equatable {
  const UsageStatisticsEvent();

  @override
  List<Object?> get props => [];
}

class LoadUsageStats extends UsageStatisticsEvent {
  final String childUid;
  final DateTime startDate;
  final DateTime endDate;
  final String? familyId;

  const LoadUsageStats({
    required this.childUid,
    required this.startDate,
    required this.endDate,
    this.familyId,
  });

  @override
  List<Object?> get props => [childUid, startDate, endDate, familyId];
}

class ChangeTimePeriod extends UsageStatisticsEvent {
  final String childUid;
  final TimePeriod period;
  final String? familyId;

  const ChangeTimePeriod({
    required this.childUid,
    required this.period,
    this.familyId,
  });

  @override
  List<Object?> get props => [childUid, period, familyId];
}

class SelectDateRange extends UsageStatisticsEvent {
  final String childUid;
  final DateTime startDate;
  final DateTime endDate;
  final String? familyId;

  const SelectDateRange({
    required this.childUid,
    required this.startDate,
    required this.endDate,
    this.familyId,
  });

  @override
  List<Object?> get props => [childUid, startDate, endDate, familyId];
}

class ExportUsageData extends UsageStatisticsEvent {
  final String childUid;
  final DateTime startDate;
  final DateTime endDate;
  final ExportFormat format;
  final String? familyId;

  const ExportUsageData({
    required this.childUid,
    required this.startDate,
    required this.endDate,
    required this.format,
    this.familyId,
  });

  @override
  List<Object?> get props => [childUid, startDate, endDate, format, familyId];
}

enum ExportFormat { csv, pdf }
