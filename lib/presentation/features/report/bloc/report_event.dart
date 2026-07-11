import 'package:equatable/equatable.dart';
import '../../../../domain/entities/weekly_report.dart';

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

class SendReportByEmail extends ReportEvent {
  final String recipientEmail;
  final WeeklyReport report;
  final String childName;

  const SendReportByEmail({
    required this.recipientEmail,
    required this.report,
    required this.childName,
  });

  @override
  List<Object?> get props => [recipientEmail, report, childName];
}

class UpdateEmailPreference extends ReportEvent {
  final String uid;
  final bool enabled;

  const UpdateEmailPreference({
    required this.uid,
    required this.enabled,
  });

  @override
  List<Object?> get props => [uid, enabled];
}

class LoadEmailPreference extends ReportEvent {
  final String uid;

  const LoadEmailPreference({required this.uid});

  @override
  List<Object?> get props => [uid];
}
