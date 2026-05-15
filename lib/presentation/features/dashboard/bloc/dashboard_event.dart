import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboard extends DashboardEvent {
  final String familyId;

  const LoadDashboard({required this.familyId});

  @override
  List<Object?> get props => [familyId];
}

class LoadChildUsage extends DashboardEvent {
  final String childUid;
  final String date;

  const LoadChildUsage({required this.childUid, required this.date});

  @override
  List<Object?> get props => [childUid, date];
}

class LoadUsageChart extends DashboardEvent {
  final String childUid;
  final String startDate;
  final String endDate;

  const LoadUsageChart({
    required this.childUid,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [childUid, startDate, endDate];
}

class RefreshDashboard extends DashboardEvent {
  final String familyId;

  const RefreshDashboard({required this.familyId});

  @override
  List<Object?> get props => [familyId];
}
