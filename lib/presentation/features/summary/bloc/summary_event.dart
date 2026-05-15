import 'package:equatable/equatable.dart';

abstract class SummaryEvent extends Equatable {
  const SummaryEvent();

  @override
  List<Object?> get props => [];
}

class LoadDailySummary extends SummaryEvent {
  final String childUid;
  final String familyId;

  const LoadDailySummary({
    required this.childUid,
    required this.familyId,
  });

  @override
  List<Object?> get props => [childUid, familyId];
}

class LoadSummaryHistory extends SummaryEvent {
  final String familyId;

  const LoadSummaryHistory({required this.familyId});

  @override
  List<Object?> get props => [familyId];
}

class GenerateSummary extends SummaryEvent {
  final String childUid;
  final String familyId;
  final String date;

  const GenerateSummary({
    required this.childUid,
    required this.familyId,
    required this.date,
  });

  @override
  List<Object?> get props => [childUid, familyId, date];
}
