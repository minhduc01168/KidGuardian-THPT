import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/summary_repository.dart';
import 'summary_event.dart';
import 'summary_state.dart';

class SummaryBloc extends Bloc<SummaryEvent, SummaryState> {
  final SummaryRepository _summaryRepository;

  SummaryBloc({required SummaryRepository summaryRepository})
      : _summaryRepository = summaryRepository,
        super(SummaryInitial()) {
    on<LoadDailySummary>(_onLoadDailySummary);
    on<LoadSummaryHistory>(_onLoadSummaryHistory);
    on<GenerateSummary>(_onGenerateSummary);
  }

  Future<void> _onLoadDailySummary(
    LoadDailySummary event,
    Emitter<SummaryState> emit,
  ) async {
    emit(SummaryLoading());
    try {
      final today = _getDateString(DateTime.now());
      
      // Check if summary already exists for today
      final hasSummary = await _summaryRepository.hasSummaryForDate(
        event.childUid,
        today,
      );
      
      if (hasSummary) {
        final summaries = await _summaryRepository.getSummariesByChild(
          event.childUid,
          limit: 1,
        );
        if (summaries.isNotEmpty) {
          emit(SummaryLoaded(summary: summaries.first));
          return;
        }
      }
      
      // Generate new summary for today
      final summary = await _summaryRepository.generateDailySummary(
        event.childUid,
        event.familyId,
        today,
      );
      emit(SummaryLoaded(summary: summary));
    } catch (e) {
      emit(SummaryError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadSummaryHistory(
    LoadSummaryHistory event,
    Emitter<SummaryState> emit,
  ) async {
    emit(SummaryLoading());
    try {
      final summaries = await _summaryRepository.getSummariesByFamily(
        event.familyId,
      );
      emit(SummaryHistoryLoaded(summaries: summaries));
    } catch (e) {
      emit(SummaryError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onGenerateSummary(
    GenerateSummary event,
    Emitter<SummaryState> emit,
  ) async {
    emit(SummaryLoading());
    try {
      final summary = await _summaryRepository.generateDailySummary(
        event.childUid,
        event.familyId,
        event.date,
      );
      emit(SummaryGenerated(summary: summary));
    } catch (e) {
      emit(SummaryError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
