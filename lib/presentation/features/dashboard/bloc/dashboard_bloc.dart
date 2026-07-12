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

  /// Trả về:
  ///   - null: không có bộ lọc (repo chưa inject hoặc familyId null) → chỉ lọc system app
  ///   - empty Set: đã có danh sách nhưng không app nào được bật → show tất cả user app
  ///   - non-empty Set: whitelist chính xác → chỉ show app trong danh sách
  Future<Set<String>?> _getMonitoredPackages(String? familyId, String childUid) async {
    if (_smartLockRepository == null || familyId == null) return null;
    try {
      final monitoredApps = await _smartLockRepository.getMonitoredApps(familyId, childUid);
      if (monitoredApps.isEmpty) return null; // Chưa cấu hình bất kỳ ứng dụng nào → không lọc
      return monitoredApps
          .where((a) => a.isMonitored)
          .map((a) => a.appPackageName)
          .toSet();
    } catch (e) {
      return null; // Lỗi mạng → không lọc, show data bình thường
    }
  }

  bool _isAppAllowed(String packageOrName, Set<String>? monitoredPackages) {
    if (AppUtils.isSystemOrUnmonitoredApp(packageOrName)) return false;
    if (monitoredPackages == null || monitoredPackages.isEmpty) return true;
    final cleanName = AppUtils.getAppName(packageOrName);
    // Match theo package name hoặc display name (ví dụ: "TikTok")
    return monitoredPackages.contains(packageOrName) || monitoredPackages.contains(cleanName);
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

      int totalTodayRaw = 0;
      int totalYesterdayRaw = 0;
      int totalToday = 0;
      int totalYesterday = 0;
      bool hasMonitoredFilter = false;
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
        final monitoredPackages = await _getMonitoredPackages(event.familyId, childUid);
        if ((monitoredPackages?.isNotEmpty ?? false)) {
          hasMonitoredFilter = true;
        }
        final results = await Future.wait([
          _usageRepository.getTotalUsageMinutes(childUid, today),
          _usageRepository.getTotalUsageMinutes(childUid, yesterday),
          _usageRepository.getUsageByApp(childUid, today),
          _usageRepository.getUsageByChild(childUid, today),
          _usageRepository.getUsageByDateRange(childUid, weekAgo, today),
        ]);

        totalTodayRaw += results[0] as int;
        totalYesterdayRaw += results[1] as int;

        // FIX DASHBOARD EMPTY: Nếu hôm nay không có data, fallback sang hôm qua
        // Điều này xảy ra thường xuyên vào buổi sáng sớm hoặc ngày mới
        final todayMinutes = results[0] as int;

        // Lấy usage by app cho ngày có data (hôm nay nếu có, ngược lại fallback hôm qua)
        final childUsageRaw = results[2] as Map<String, int>; // today's usage
        Map<String, int> childUsage = childUsageRaw;
        // Nếu hôm nay không có data, lấy logs hôm qua thay thế
        if (childUsage.isEmpty && todayMinutes == 0) {
          final yesterdayUsage = await _usageRepository.getUsageByApp(childUid, yesterday);
          childUsage = yesterdayUsage;
        }

        // Populate usageByApp (sử dụng childUsage đã được fallback sang hôm qua nếu cần)
        childUsage.forEach((app, minutes) {
          if (_isAppAllowed(app, monitoredPackages)) {
            final cleanName = AppUtils.getAppName(app);
            usageByApp[cleanName] = (usageByApp[cleanName] ?? 0) + minutes;
          }
        });

        // Lấy logs cho hôm nay; fallback sang hôm qua nếu rỗng
        List<UsageLog> logs = results[3] as List<UsageLog>;
        if (logs.isEmpty && todayMinutes == 0) {
          logs = await _usageRepository.getUsageByChild(childUid, yesterday);
        }

        // Populate allLogs (danh sách hoạt động gần đây)
        for (final log in logs) {
          final pkg = log.appPackage.isNotEmpty ? log.appPackage : log.appName;
          if (_isAppAllowed(pkg, monitoredPackages)) {
            allLogs.add(log.copyWith(appName: AppUtils.getAppNameFromLog(log.appPackage, log.appName)));
          }
        }

        final weekLogs = results[4] as List<UsageLog>;
        for (final log in weekLogs) {
          final pkg = log.appPackage.isNotEmpty ? log.appPackage : log.appName;
          if (_isAppAllowed(pkg, monitoredPackages)) {
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
      } else if (hasMonitoredFilter) {
        totalToday = 0;
      } else {
        totalToday = totalTodayRaw;
      }

      if (hasMonitoredFilter) {
        totalYesterday = dailyTotals[yesterday] ?? 0;
      } else {
        totalYesterday = totalYesterdayRaw;
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

      final monitoredPackages = await _getMonitoredPackages(event.familyId, event.childUid);

      final results = await Future.wait([
        _usageRepository.getTotalUsageMinutes(event.childUid, event.date),
        _usageRepository.getUsageByApp(event.childUid, event.date),
        _usageRepository.getUsageByChild(event.childUid, event.date),
        _usageRepository.getTotalUsageMinutes(event.childUid, yesterday),
        _usageRepository.getUsageByDateRange(event.childUid, weekAgo, event.date),
      ]);

      final usageByAppRaw = results[1] as Map<String, int>;
      final logsRaw = results[2] as List<UsageLog>;
      final weekLogs = results[4] as List<UsageLog>;

      final Map<String, int> usageByApp = {};
      usageByAppRaw.forEach((app, minutes) {
        if (_isAppAllowed(app, monitoredPackages)) {
          final cleanName = AppUtils.getAppName(app);
          usageByApp[cleanName] = (usageByApp[cleanName] ?? 0) + minutes;
        }
      });

      final List<UsageLog> logs = [];
      for (final log in logsRaw) {
        final pkg = log.appPackage.isNotEmpty ? log.appPackage : log.appName;
        if (_isAppAllowed(pkg, monitoredPackages)) {
          logs.add(log.copyWith(appName: AppUtils.getAppNameFromLog(log.appPackage, log.appName)));
        }
      }

      int totalMinutes = results[0] as int;
      if (usageByApp.isNotEmpty) {
        totalMinutes = usageByApp.values.fold(0, (sum, val) => sum + val);
      } else if ((monitoredPackages?.isNotEmpty ?? false)) {
        totalMinutes = 0;
      }

      final Map<String, int> dailyTotals = {};
      for (final log in weekLogs) {
        final pkg = log.appPackage.isNotEmpty ? log.appPackage : log.appName;
        if (_isAppAllowed(pkg, monitoredPackages)) {
          dailyTotals[log.date] =
              (dailyTotals[log.date] ?? 0) + log.durationMinutes;
        }
      }

      final int totalYesterday = (monitoredPackages?.isNotEmpty ?? false)
          ? (dailyTotals[yesterday] ?? 0)
          : (results[3] as int);

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
      final monitoredPackages = await _getMonitoredPackages(event.familyId, event.childUid);

      final logsRaw = await _usageRepository.getUsageByDateRange(
        event.childUid,
        event.startDate,
        event.endDate,
      );

      final List<UsageLog> logs = [];
      for (final log in logsRaw) {
        final pkg = log.appPackage.isNotEmpty ? log.appPackage : log.appName;
        if (_isAppAllowed(pkg, monitoredPackages)) {
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
