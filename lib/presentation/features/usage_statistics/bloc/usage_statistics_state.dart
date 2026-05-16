import 'package:equatable/equatable.dart';
import '../../../../domain/entities/usage_log.dart';
import 'usage_statistics_event.dart';

class AppUsageSummary extends Equatable {
  final String appName;
  final String appPackage;
  final int totalMinutes;
  final double percentage;
  final int sessionCount;
  final int avgMinutesPerSession;

  const AppUsageSummary({
    required this.appName,
    required this.appPackage,
    required this.totalMinutes,
    required this.percentage,
    required this.sessionCount,
    required this.avgMinutesPerSession,
  });

  @override
  List<Object?> get props => [
        appName,
        appPackage,
        totalMinutes,
        percentage,
        sessionCount,
        avgMinutesPerSession,
      ];
}

abstract class UsageStatisticsState extends Equatable {
  const UsageStatisticsState();

  @override
  List<Object?> get props => [];
}

class UsageStatisticsInitial extends UsageStatisticsState {}

class UsageStatisticsLoading extends UsageStatisticsState {}

class UsageStatisticsLoaded extends UsageStatisticsState {
  final Map<int, int> hourlyUsage;
  final Map<String, int> dailyUsage;
  final Map<String, int> weeklyUsage;
  final Map<String, int> usageByApp;
  final List<int> peakHours;
  final String peakDay;
  final List<AppUsageSummary> mostUsedApps;
  final int totalMinutes;
  final TimePeriod selectedPeriod;
  final DateTime startDate;
  final DateTime endDate;
  final List<UsageLog> logs;

  const UsageStatisticsLoaded({
    required this.hourlyUsage,
    required this.dailyUsage,
    required this.weeklyUsage,
    required this.usageByApp,
    required this.peakHours,
    required this.peakDay,
    required this.mostUsedApps,
    required this.totalMinutes,
    required this.selectedPeriod,
    required this.startDate,
    required this.endDate,
    required this.logs,
  });

  @override
  List<Object?> get props => [
        hourlyUsage,
        dailyUsage,
        weeklyUsage,
        usageByApp,
        peakHours,
        peakDay,
        mostUsedApps,
        totalMinutes,
        selectedPeriod,
        startDate,
        endDate,
        logs,
      ];
}

class UsageStatisticsError extends UsageStatisticsState {
  final String message;

  const UsageStatisticsError({required this.message});

  @override
  List<Object?> get props => [message];
}

class UsageDataExported extends UsageStatisticsState {
  final String filePath;
  final ExportFormat format;

  const UsageDataExported({
    required this.filePath,
    required this.format,
  });

  @override
  List<Object?> get props => [filePath, format];
}
