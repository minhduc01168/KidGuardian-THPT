import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/usage_repository.dart';
import '../utils/usage_statistics_helper.dart';
import '../utils/usage_exporter.dart';
import 'usage_statistics_event.dart';
import 'usage_statistics_state.dart';

class UsageStatisticsBloc
    extends Bloc<UsageStatisticsEvent, UsageStatisticsState> {
  final UsageRepository _usageRepository;

  UsageStatisticsBloc({required UsageRepository usageRepository})
      : _usageRepository = usageRepository,
        super(UsageStatisticsInitial()) {
    on<LoadUsageStats>(_onLoadUsageStats);
    on<ChangeTimePeriod>(_onChangeTimePeriod);
    on<SelectDateRange>(_onSelectDateRange);
    on<ExportUsageData>(_onExportUsageData);
  }

  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _onLoadUsageStats(
    LoadUsageStats event,
    Emitter<UsageStatisticsState> emit,
  ) async {
    emit(UsageStatisticsLoading());
    try {
      final startDateStr = _getDateString(event.startDate);
      final endDateStr = _getDateString(event.endDate);

      final logs = await _usageRepository.getUsageByDateRange(
        event.childUid,
        startDateStr,
        endDateStr,
      );

      final hourlyUsage = UsageStatisticsHelper.groupByHour(logs);
      final dailyUsage = UsageStatisticsHelper.groupByDay(logs);
      final weeklyUsage = UsageStatisticsHelper.groupByWeek(logs);
      final usageByApp = UsageStatisticsHelper.groupByApp(logs);
      final peakHours = UsageStatisticsHelper.findPeakHours(hourlyUsage);
      final peakDay = UsageStatisticsHelper.findPeakDay(dailyUsage);
      final mostUsedApps =
          UsageStatisticsHelper.buildMostUsedApps(logs, usageByApp);
      final totalMinutes =
          usageByApp.values.fold<int>(0, (sum, m) => sum + m);

      emit(UsageStatisticsLoaded(
        hourlyUsage: hourlyUsage,
        dailyUsage: dailyUsage,
        weeklyUsage: weeklyUsage,
        usageByApp: usageByApp,
        peakHours: peakHours,
        peakDay: peakDay,
        mostUsedApps: mostUsedApps,
        totalMinutes: totalMinutes,
        selectedPeriod: TimePeriod.day,
        startDate: event.startDate,
        endDate: event.endDate,
        logs: logs,
      ));
    } catch (e) {
      emit(UsageStatisticsError(
          message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onChangeTimePeriod(
    ChangeTimePeriod event,
    Emitter<UsageStatisticsState> emit,
  ) async {
    final currentState = state;
    if (currentState is UsageStatisticsLoaded) {
      emit(UsageStatisticsLoaded(
        hourlyUsage: currentState.hourlyUsage,
        dailyUsage: currentState.dailyUsage,
        weeklyUsage: currentState.weeklyUsage,
        usageByApp: currentState.usageByApp,
        peakHours: currentState.peakHours,
        peakDay: currentState.peakDay,
        mostUsedApps: currentState.mostUsedApps,
        totalMinutes: currentState.totalMinutes,
        selectedPeriod: event.period,
        startDate: currentState.startDate,
        endDate: currentState.endDate,
        logs: currentState.logs,
      ));
    }
  }

  Future<void> _onSelectDateRange(
    SelectDateRange event,
    Emitter<UsageStatisticsState> emit,
  ) async {
    add(LoadUsageStats(
      childUid: event.childUid,
      startDate: event.startDate,
      endDate: event.endDate,
    ));
  }

  Future<void> _onExportUsageData(
    ExportUsageData event,
    Emitter<UsageStatisticsState> emit,
  ) async {
    try {
      final startDateStr = _getDateString(event.startDate);
      final endDateStr = _getDateString(event.endDate);

      final logs = await _usageRepository.getUsageByDateRange(
        event.childUid,
        startDateStr,
        endDateStr,
      );

      final dateRange =
          UsageStatisticsHelper.formatDateRange(event.startDate, event.endDate);

      String filePath;
      if (event.format == ExportFormat.csv) {
        filePath = await UsageExporter.exportToCsv(logs, dateRange);
      } else {
        filePath = await UsageExporter.exportToPdf(logs, dateRange);
      }

      emit(UsageDataExported(filePath: filePath, format: event.format));
    } catch (e) {
      emit(UsageStatisticsError(
          message: 'Xuất dữ liệu thất bại: ${e.toString()}'));
    }
  }
}
