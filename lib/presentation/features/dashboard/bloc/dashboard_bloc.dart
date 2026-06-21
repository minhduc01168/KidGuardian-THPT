import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/usage_log.dart';
import '../../../../domain/repositories/family_repository.dart';
import '../../../../domain/repositories/usage_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final UsageRepository _usageRepository;
  final FamilyRepository _familyRepository;

  DashboardBloc({
    required UsageRepository usageRepository,
    required FamilyRepository familyRepository,
  })  : _usageRepository = usageRepository,
        _familyRepository = familyRepository,
        super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<LoadChildUsage>(_onLoadChildUsage);
    on<LoadUsageChart>(_onLoadUsageChart);
    on<RefreshDashboard>(_onRefreshDashboard);
  }

  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final family = await _familyRepository.getFamily(event.familyId);
      if (family == null) {
        emit(const DashboardError(message: 'Không tìm thấy thông tin gia đình'));
        return;
      }

      final today = _getDateString(DateTime.now());
      final yesterday = _getDateString(
        DateTime.now().subtract(const Duration(days: 1)),
      );

      int totalToday = 0;
      int totalYesterday = 0;
      Map<String, int> usageByApp = {};
      final List<UsageLog> allLogs = [];
      final Map<String, int> dailyTotals = {};

      final weekAgo = _getDateString(
        DateTime.now().subtract(const Duration(days: 7)),
      );

      await Future.wait(family.childUids.map((childUid) async {
        final results = await Future.wait([
          _usageRepository.getTotalUsageMinutes(childUid, today),
          _usageRepository.getTotalUsageMinutes(childUid, yesterday),
          _usageRepository.getUsageByApp(childUid, today),
          _usageRepository.getUsageByChild(childUid, today),
          _usageRepository.getUsageByDateRange(childUid, weekAgo, today),
        ]);

        totalToday += results[0] as int;
        totalYesterday += results[1] as int;

        final childUsage = results[2] as Map<String, int>;
        childUsage.forEach((app, minutes) {
          usageByApp[app] = (usageByApp[app] ?? 0) + minutes;
        });

        final logs = results[3] as List<UsageLog>;
        allLogs.addAll(logs);

        final weekLogs = results[4] as List<UsageLog>;
        for (final log in weekLogs) {
          dailyTotals[log.date] =
              (dailyTotals[log.date] ?? 0) + log.durationMinutes;
        }
      }));

      emit(DashboardLoaded(
        totalMinutesToday: totalToday,
        totalMinutesYesterday: totalYesterday,
        usageByApp: usageByApp,
        recentLogs: allLogs,
        childUids: family.childUids,
        dailyTotals: dailyTotals,
      ));
    } catch (e) {
      emit(DashboardError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadChildUsage(
    LoadChildUsage event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final yesterday = _getDateString(
        DateTime.now().subtract(const Duration(days: 1)),
      );
      
      final weekAgo = _getDateString(
        DateTime.now().subtract(const Duration(days: 7)),
      );

      final results = await Future.wait([
        _usageRepository.getTotalUsageMinutes(event.childUid, event.date),
        _usageRepository.getUsageByApp(event.childUid, event.date),
        _usageRepository.getUsageByChild(event.childUid, event.date),
        _usageRepository.getTotalUsageMinutes(event.childUid, yesterday),
        _usageRepository.getUsageByDateRange(event.childUid, weekAgo, event.date),
      ]);

      final totalMinutes = results[0] as int;
      final usageByApp = results[1] as Map<String, int>;
      final logs = results[2] as List<UsageLog>;
      final totalYesterday = results[3] as int;
      final weekLogs = results[4] as List<UsageLog>;

      final Map<String, int> dailyTotals = {};
      for (final log in weekLogs) {
        dailyTotals[log.date] =
            (dailyTotals[log.date] ?? 0) + log.durationMinutes;
      }

      emit(DashboardLoaded(
        totalMinutesToday: totalMinutes,
        totalMinutesYesterday: totalYesterday,
        usageByApp: usageByApp,
        recentLogs: logs,
        childUids: [event.childUid],
        dailyTotals: dailyTotals,
      ));
    } catch (e) {
      emit(DashboardError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadUsageChart(
    LoadUsageChart event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final logs = await _usageRepository.getUsageByDateRange(
        event.childUid,
        event.startDate,
        event.endDate,
      );

      // Calculate daily totals
      final Map<String, int> dailyTotals = {};
      for (final log in logs) {
        dailyTotals[log.date] =
            (dailyTotals[log.date] ?? 0) + log.durationMinutes;
      }

      // Calculate app totals
      final Map<String, int> appTotals = {};
      for (final log in logs) {
        appTotals[log.appName] =
            (appTotals[log.appName] ?? 0) + log.durationMinutes;
      }

      emit(UsageChartData(
        logs: logs,
        dailyTotals: dailyTotals,
        appTotals: appTotals,
      ));
    } catch (e) {
      emit(DashboardError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRefreshDashboard(
    RefreshDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    add(LoadDashboard(familyId: event.familyId));
  }
}
