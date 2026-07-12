import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/usage_log.dart';
import '../../../../domain/repositories/family_repository.dart';
import '../../../../domain/repositories/usage_repository.dart';
import '../../../../data/repositories/smart_lock_repository.dart';
import '../../../../core/utils/app_utils.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final UsageRepository _usageRepository;
  final FamilyRepository _familyRepository;
  final SmartLockRepository? _smartLockRepository;

  DashboardBloc({
    required UsageRepository usageRepository,
    required FamilyRepository familyRepository,
    SmartLockRepository? smartLockRepository,
  })  : _usageRepository = usageRepository,
        _familyRepository = familyRepository,
        _smartLockRepository = smartLockRepository,
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
      final Map<String, int> appTimeLimits = {};

      final now = DateTime.now();
      final dayKeys = [
        'monday', 'tuesday', 'wednesday', 'thursday',
        'friday', 'saturday', 'sunday',
      ];
      final dayOfWeek = dayKeys[now.weekday - 1];

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

        totalYesterday += results[1] as int;
        totalToday += results[0] as int;

        final childUsage = results[2] as Map<String, int>;
        childUsage.forEach((app, minutes) {
          if (!AppUtils.isSystemOrUnmonitoredApp(app)) {
            final cleanName = AppUtils.getAppName(app);
            usageByApp[cleanName] = (usageByApp[cleanName] ?? 0) + minutes;
          }
        });

        final logs = results[3] as List<UsageLog>;
        for (final log in logs) {
          final pkg = log.appPackage.isNotEmpty ? log.appPackage : log.appName;
          if (!AppUtils.isSystemOrUnmonitoredApp(pkg)) {
            allLogs.add(log.copyWith(appName: AppUtils.getAppNameFromLog(log.appPackage, log.appName)));
          }
        }

        final weekLogs = results[4] as List<UsageLog>;
        for (final log in weekLogs) {
          final pkg = log.appPackage.isNotEmpty ? log.appPackage : log.appName;
          if (!AppUtils.isSystemOrUnmonitoredApp(pkg)) {
            dailyTotals[log.date] =
                (dailyTotals[log.date] ?? 0) + log.durationMinutes;
          }
        }

        if (_smartLockRepository != null) {
          try {
            final limits = await _smartLockRepository.getAppTimeLimits(
              event.familyId,
              childUid,
            );
            for (final limit in limits) {
              int limitMin = 0;
              if (limit.limits.containsKey(dayOfWeek)) {
                limitMin = limit.limits[dayOfWeek]!;
              } else if (limit.limits.containsKey('everyday')) {
                limitMin = limit.limits['everyday']!;
              }
              if (limitMin > 0) {
                appTimeLimits[limit.appPackageName] = limitMin;
                appTimeLimits[AppUtils.getAppName(limit.appPackageName)] = limitMin;
              }
            }
          } catch (e) {
            // Ignore error when loading time limits
          }
        }
      }));

      if (usageByApp.isNotEmpty) {
        totalToday = usageByApp.values.fold(0, (sum, val) => sum + val);
      }

      emit(DashboardLoaded(
        totalMinutesToday: totalToday,
        totalMinutesYesterday: totalYesterday,
        usageByApp: usageByApp,
        recentLogs: allLogs,
        childUids: family.childUids,
        dailyTotals: dailyTotals,
        appTimeLimits: appTimeLimits,
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

      final usageByAppRaw = results[1] as Map<String, int>;
      final logsRaw = results[2] as List<UsageLog>;
      final totalYesterday = results[3] as int;
      final weekLogs = results[4] as List<UsageLog>;

      final Map<String, int> usageByApp = {};
      usageByAppRaw.forEach((app, minutes) {
        if (!AppUtils.isSystemOrUnmonitoredApp(app)) {
          final cleanName = AppUtils.getAppName(app);
          usageByApp[cleanName] = (usageByApp[cleanName] ?? 0) + minutes;
        }
      });

      final List<UsageLog> logs = [];
      for (final log in logsRaw) {
        final pkg = log.appPackage.isNotEmpty ? log.appPackage : log.appName;
        if (!AppUtils.isSystemOrUnmonitoredApp(pkg)) {
          logs.add(log.copyWith(appName: AppUtils.getAppNameFromLog(log.appPackage, log.appName)));
        }
      }

      int totalMinutes = results[0] as int;
      if (usageByApp.isNotEmpty) {
        totalMinutes = usageByApp.values.fold(0, (sum, val) => sum + val);
      }

      final Map<String, int> dailyTotals = {};
      for (final log in weekLogs) {
        final pkg = log.appPackage.isNotEmpty ? log.appPackage : log.appName;
        if (!AppUtils.isSystemOrUnmonitoredApp(pkg)) {
          dailyTotals[log.date] =
              (dailyTotals[log.date] ?? 0) + log.durationMinutes;
        }
      }

      final Map<String, int> appTimeLimits = {};
      if (_smartLockRepository != null && event.familyId != null) {
        try {
          final now = DateTime.now();
          final dayKeys = [
            'monday', 'tuesday', 'wednesday', 'thursday',
            'friday', 'saturday', 'sunday',
          ];
          final dayOfWeek = dayKeys[now.weekday - 1];
          final limits = await _smartLockRepository.getAppTimeLimits(
            event.familyId!,
            event.childUid,
          );
          for (final limit in limits) {
            int limitMin = 0;
            if (limit.limits.containsKey(dayOfWeek)) {
              limitMin = limit.limits[dayOfWeek]!;
            } else if (limit.limits.containsKey('everyday')) {
              limitMin = limit.limits['everyday']!;
            }
            if (limitMin > 0) {
              appTimeLimits[limit.appPackageName] = limitMin;
              appTimeLimits[AppUtils.getAppName(limit.appPackageName)] = limitMin;
            }
          }
        } catch (e) {
          // Ignore limit check error
        }
      }

      emit(DashboardLoaded(
        totalMinutesToday: totalMinutes,
        totalMinutesYesterday: totalYesterday,
        usageByApp: usageByApp,
        recentLogs: logs,
        childUids: [event.childUid],
        dailyTotals: dailyTotals,
        appTimeLimits: appTimeLimits,
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
      final logsRaw = await _usageRepository.getUsageByDateRange(
        event.childUid,
        event.startDate,
        event.endDate,
      );

      final List<UsageLog> logs = [];
      for (final log in logsRaw) {
        final pkg = log.appPackage.isNotEmpty ? log.appPackage : log.appName;
        if (!AppUtils.isSystemOrUnmonitoredApp(pkg)) {
          logs.add(log.copyWith(appName: AppUtils.getAppNameFromLog(log.appPackage, log.appName)));
        }
      }

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
