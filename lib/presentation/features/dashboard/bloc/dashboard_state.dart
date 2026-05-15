import 'package:equatable/equatable.dart';
import '../../../../domain/entities/usage_log.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final int totalMinutesToday;
  final int totalMinutesYesterday;
  final Map<String, int> usageByApp;
  final List<UsageLog> recentLogs;
  final List<String> childUids;
  final Map<String, int> dailyTotals;

  const DashboardLoaded({
    required this.totalMinutesToday,
    required this.totalMinutesYesterday,
    required this.usageByApp,
    required this.recentLogs,
    required this.childUids,
    this.dailyTotals = const {},
  });

  int get totalMinutesLastWeek {
    if (dailyTotals.isEmpty) return 0;
    // Sum of last 7 days excluding today
    final today = DateTime.now().toString().substring(0, 10);
    int total = 0;
    dailyTotals.forEach((date, minutes) {
      if (date != today) total += minutes;
    });
    return total;
  }

  double get percentChangeFromYesterday {
    if (totalMinutesYesterday == 0) return 0;
    return ((totalMinutesToday - totalMinutesYesterday) /
            totalMinutesYesterday *
            100)
        .roundToDouble();
  }

  double get percentChangeFromLastWeek {
    if (totalMinutesLastWeek == 0) return 0;
    final avgLastWeek = totalMinutesLastWeek / 7;
    return ((totalMinutesToday - avgLastWeek) / avgLastWeek * 100)
        .roundToDouble();
  }

  @override
  List<Object?> get props => [
        totalMinutesToday,
        totalMinutesYesterday,
        usageByApp,
        recentLogs,
        childUids,
        dailyTotals,
      ];
}

class UsageChartData extends DashboardState {
  final List<UsageLog> logs;
  final Map<String, int> dailyTotals;
  final Map<String, int> appTotals;

  const UsageChartData({
    required this.logs,
    required this.dailyTotals,
    required this.appTotals,
  });

  @override
  List<Object?> get props => [logs, dailyTotals, appTotals];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}
