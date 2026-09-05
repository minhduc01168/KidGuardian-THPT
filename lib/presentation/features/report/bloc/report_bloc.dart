import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/weekly_report.dart';
import '../../../../domain/repositories/report_repository.dart';
import 'report_event.dart';
import 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final ReportRepository _reportRepository;

  ReportBloc({required ReportRepository reportRepository})
      : _reportRepository = reportRepository,
        super(ReportInitial()) {
    on<GenerateWeeklyReport>(_onGenerateWeeklyReport);
    on<GenerateMonthlyReport>(_onGenerateMonthlyReport);
    on<LoadReportHistory>(_onLoadReportHistory);
    on<LoadMonthlyReportHistory>(_onLoadMonthlyReportHistory);
    on<LoadLatestReport>(_onLoadLatestReport);
    on<SendReportByEmail>(_onSendReportByEmail);
    on<UpdateEmailPreference>(_onUpdateEmailPreference);
    on<LoadEmailPreference>(_onLoadEmailPreference);
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
      // FIX #4: Nếu có childUid, filter theo con đó thay vì toàn family
      final List<WeeklyReport> reports;
      if (event.childUid != null && event.childUid!.isNotEmpty) {
        reports = await _reportRepository.getReportsByChild(event.childUid!);
      } else {
        reports = await _reportRepository.getReportsByFamily(event.familyId);
      }
      emit(ReportHistoryLoaded(reports: reports));
    } catch (e) {
      emit(ReportError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onGenerateMonthlyReport(
    GenerateMonthlyReport event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());
    try {
      final report = await _reportRepository.generateMonthlyReport(
        event.childUid,
        event.familyId,
      );
      emit(MonthlyReportGenerated(report: report));
    } catch (e) {
      emit(ReportError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadMonthlyReportHistory(
    LoadMonthlyReportHistory event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());
    try {
      final reports = await _reportRepository.getMonthlyReportsByFamily(
        event.familyId,
      );
      emit(MonthlyReportHistoryLoaded(reports: reports));
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

  Future<void> _onSendReportByEmail(
    SendReportByEmail event,
    Emitter<ReportState> emit,
  ) async {
    try {
      final success = await _reportRepository.sendReportByEmail(
        recipientEmail: event.recipientEmail,
        report: event.report,
        childName: event.childName,
      );
      if (success) {
        emit(const ReportEmailSent());
      } else {
        emit(const ReportError(message: 'Không thể gửi email'));
      }
    } catch (e) {
      emit(ReportError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateEmailPreference(
    UpdateEmailPreference event,
    Emitter<ReportState> emit,
  ) async {
    try {
      final success = await _reportRepository.updateEmailPreference(
        uid: event.uid,
        enabled: event.enabled,
      );
      if (success) {
        emit(EmailPreferenceUpdated(enabled: event.enabled));
      } else {
        emit(const ReportError(message: 'Không thể cập nhật cài đặt'));
      }
    } catch (e) {
      emit(ReportError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadEmailPreference(
    LoadEmailPreference event,
    Emitter<ReportState> emit,
  ) async {
    try {
      final enabled = await _reportRepository.getEmailPreference(event.uid);
      emit(EmailPreferenceLoaded(enabled: enabled));
    } catch (e) {
      emit(EmailPreferenceLoaded(enabled: false));
    }
  }
}
