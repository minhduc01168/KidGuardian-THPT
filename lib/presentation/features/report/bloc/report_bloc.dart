import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/report_repository.dart';
import 'report_event.dart';
import 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final ReportRepository _reportRepository;

  ReportBloc({required ReportRepository reportRepository})
      : _reportRepository = reportRepository,
        super(ReportInitial()) {
    on<GenerateWeeklyReport>(_onGenerateWeeklyReport);
    on<LoadReportHistory>(_onLoadReportHistory);
    on<LoadLatestReport>(_onLoadLatestReport);
  }

  Future<void> _onGenerateWeeklyReport(
    GenerateWeeklyReport event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());
    try {
      final report = await _reportRepository.generateWeeklyReport(
        event.childUid,
        event.familyId,
      );
      emit(ReportGenerated(report: report));
    } catch (e) {
      emit(ReportError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadReportHistory(
    LoadReportHistory event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());
    try {
      final reports = await _reportRepository.getReportsByFamily(
        event.familyId,
      );
      emit(ReportHistoryLoaded(reports: reports));
    } catch (e) {
      emit(ReportError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadLatestReport(
    LoadLatestReport event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());
    try {
      final report = await _reportRepository.getLatestReport(event.childUid);
      if (report != null) {
        emit(ReportLoaded(report: report));
      } else {
        emit(const ReportError(message: 'Chưa có báo cáo'));
      }
    } catch (e) {
      emit(ReportError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }
}
