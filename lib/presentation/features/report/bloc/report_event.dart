import 'package:equatable/equatable.dart';

abstract class ReportEvent extends Equatable {
  const ReportEvent();

  @override
  List<Object?> get props => [];
}

class GenerateWeeklyReport extends ReportEvent {
  final String childUid;
  final String familyId;

  const GenerateWeeklyReport({
    required this.childUid,
    required this.familyId,
  });

  @override
  List<Object?> get props => [childUid, familyId];
}

class LoadReportHistory extends ReportEvent {
  final String familyId;

  const LoadReportHistory({required this.familyId});

  @override
  List<Object?> get props => [familyId];
}

class LoadLatestReport extends ReportEvent {
  final String childUid;

  const LoadLatestReport({required this.childUid});

  @override
  List<Object?> get props => [childUid];
}
