import 'package:equatable/equatable.dart';
import '../../../../domain/entities/weekly_report.dart';

abstract class ReportState extends Equatable {
  const ReportState();

  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {}

class ReportLoading extends ReportState {}

class ReportLoaded extends ReportState {
  final WeeklyReport report;

  const ReportLoaded({required this.report});

  @override
  List<Object?> get props => [report];
}

class ReportHistoryLoaded extends ReportState {
  final List<WeeklyReport> reports;

  const ReportHistoryLoaded({required this.reports});

  @override
  List<Object?> get props => [reports];
}

class ReportGenerated extends ReportState {
  final WeeklyReport report;

  const ReportGenerated({required this.report});

  @override
  List<Object?> get props => [report];
}

class ReportError extends ReportState {
  final String message;

  const ReportError({required this.message});

  @override
  List<Object?> get props => [message];
}
