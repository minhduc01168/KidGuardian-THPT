import 'package:equatable/equatable.dart';
import '../../../../domain/entities/daily_summary.dart';

abstract class SummaryState extends Equatable {
  const SummaryState();

  @override
  List<Object?> get props => [];
}

class SummaryInitial extends SummaryState {}

class SummaryLoading extends SummaryState {}

class SummaryLoaded extends SummaryState {
  final DailySummary summary;

  const SummaryLoaded({required this.summary});

  @override
  List<Object?> get props => [summary];
}

class SummaryHistoryLoaded extends SummaryState {
  final List<DailySummary> summaries;

  const SummaryHistoryLoaded({required this.summaries});

  @override
  List<Object?> get props => [summaries];
}

class SummaryGenerated extends SummaryState {
  final DailySummary summary;

  const SummaryGenerated({required this.summary});

  @override
  List<Object?> get props => [summary];
}

class SummaryError extends SummaryState {
  final String message;

  const SummaryError({required this.message});

  @override
  List<Object?> get props => [message];
}
