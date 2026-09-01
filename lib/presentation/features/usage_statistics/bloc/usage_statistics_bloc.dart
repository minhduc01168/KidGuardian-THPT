import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../data/repositories/smart_lock_repository.dart';
import '../../../../domain/entities/usage_log.dart';
import '../../../../domain/repositories/usage_repository.dart';
import '../utils/usage_statistics_helper.dart';
import '../utils/usage_exporter.dart';
import 'usage_statistics_event.dart';
import 'usage_statistics_state.dart';

class UsageStatisticsBloc
    extends Bloc<UsageStatisticsEvent, UsageStatisticsState> {
  final UsageRepository _usageRepository;
  final SmartLockRepository? _smartLockRepository;

  UsageStatisticsBloc({
    required UsageRepository usageRepository,
    SmartLockRepository? smartLockRepository,
  })  : _usageRepository = usageRepository,
        _smartLockRepository = smartLockRepository,
        super(UsageStatisticsInitial()) {
    on<LoadUsageStats>(_onLoadUsageStats);
    on<ChangeTimePeriod>(_onChangeTimePeriod);
    on<SelectDateRange>(_onSelectDateRange);
    on<ExportUsageData>(_onExportUsageData);
  }

  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static final Set<String> _defaultPopularPackages = {
    'com.zhiliaoapp.musically',
    'TikTok',
    'com.facebook.katana',
    'Facebook',
    'com.google.android.youtube',
    'YouTube',
    'com.instagram.android',
    'Instagram',
    'com.instagram.barcelona',
    'Threads',
    'com.android.chrome',
    'Google Chrome',
    'com.zing.zalo',
    'Zalo',
    'com.roblox.client',
    'Roblox',
    'com.dts.freefireth',
    'Free Fire',
  };

  Set<String> _buildPackageSet(List<dynamic> apps) {
    final set = <String>{};
    for (final app in apps) {
      final isMonitored = (app.isMonitored ?? true) as bool;
      if (isMonitored) {
        final pkg = app.appPackageName as String;
        set.add(pkg);
        final name = (app.appName as String?);
        if (name != null && name.isNotEmpty) set.add(name);
        set.add(AppUtils.getAppName(pkg));
      }
    }
    return set;
  }

  Future<Set<String>> _getMonitoredPackages(String? familyId, String childUid) async {
    if (_smartLockRepository == null || familyId == null) {
      return _defaultPopularPackages;
    }
    try {
      final configuredApps = await _smartLockRepository!.getMonitoredApps(familyId, childUid);
      final popularApps = _smartLockRepository!.getPopularMonitoredApps();
      
      final Map<String, dynamic> mergedApps = {};
      for (var app in popularApps) {
        mergedApps[app.appPackageName] = app;
      }
      for (var app in configuredApps) {
        if (mergedApps.containsKey(app.appPackageName)) {
           mergedApps[app.appPackageName] = mergedApps[app.appPackageName]!.copyWith(isMonitored: app.isMonitored);
        }
      }
      return _buildPackageSet(mergedApps.values.toList());
    } catch (e) {
      return _defaultPopularPackages;
    }
  }

  bool _isAppAllowed(String packageOrName, Set<String> monitoredPackages) {
    if (AppUtils.isSystemOrUnmonitoredApp(packageOrName)) return false;
    final cleanName = AppUtils.getAppName(packageOrName);
    return monitoredPackages.contains(packageOrName) || monitoredPackages.contains(cleanName);
  }

  Future<void> _onLoadUsageStats(
    LoadUsageStats event,
    Emitter<UsageStatisticsState> emit,
  ) async {
    emit(UsageStatisticsLoading());
    try {
      final startDateStr = _getDateString(event.startDate);
      final endDateStr = _getDateString(event.endDate);

      final monitoredPackages = await _getMonitoredPackages(event.familyId, event.childUid);

      final logsRaw = await _usageRepository.getUsageByDateRange(
        event.childUid,
        startDateStr,
        endDateStr,
      );

      final List<UsageLog> logs = [];
      for (final log in logsRaw) {
        final pkg = log.appPackage.isNotEmpty ? log.appPackage : log.appName;
        if (_isAppAllowed(pkg, monitoredPackages)) {
          logs.add(log.copyWith(appName: AppUtils.getAppNameFromLog(log.appPackage, log.appName)));
        }
      }

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
        familyId: event.familyId,
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
        familyId: currentState.familyId,
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
      familyId: event.familyId,
    ));
  }

  Future<void> _onExportUsageData(
    ExportUsageData event,
    Emitter<UsageStatisticsState> emit,
  ) async {
    try {
      final startDateStr = _getDateString(event.startDate);
      final endDateStr = _getDateString(event.endDate);

      final monitoredPackages = await _getMonitoredPackages(event.familyId, event.childUid);

      final logsRaw = await _usageRepository.getUsageByDateRange(
        event.childUid,
        startDateStr,
        endDateStr,
      );

      final List<UsageLog> logs = [];
      for (final log in logsRaw) {
        final pkg = log.appPackage.isNotEmpty ? log.appPackage : log.appName;
        if (_isAppAllowed(pkg, monitoredPackages)) {
          logs.add(log.copyWith(appName: AppUtils.getAppNameFromLog(log.appPackage, log.appName)));
        }
      }

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
