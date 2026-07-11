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

  const LoadUsageStats({
    required this.childUid,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [childUid, startDate, endDate];
}

class ChangeTimePeriod extends UsageStatisticsEvent {
  final String childUid;
  final TimePeriod period;

  const ChangeTimePeriod({
    required this.childUid,
    required this.period,
  });

  @override
  List<Object?> get props => [childUid, period];
}

class SelectDateRange extends UsageStatisticsEvent {
  final String childUid;
  final DateTime startDate;
  final DateTime endDate;

  const SelectDateRange({
    required this.childUid,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [childUid, startDate, endDate];
}

class ExportUsageData extends UsageStatisticsEvent {
  final String childUid;
  final DateTime startDate;
  final DateTime endDate;
  final ExportFormat format;

  const ExportUsageData({
    required this.childUid,
    required this.startDate,
    required this.endDate,
    required this.format,
  });

  @override
  List<Object?> get props => [childUid, startDate, endDate, format];
}

enum ExportFormat { csv, pdf }
