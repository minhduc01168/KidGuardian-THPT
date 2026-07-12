import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:kidguardian/platform/android/accessibility_channel.dart';
import 'package:kidguardian/domain/usecases/smart_lock/check_app_access_usecase.dart';
import 'package:kidguardian/domain/usecases/smart_lock/block_app_usecase.dart';
import 'package:kidguardian/domain/usecases/smart_lock/schedule_checker.dart';
import 'package:kidguardian/domain/entities/usage_log.dart';
import 'package:kidguardian/domain/repositories/usage_repository.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';
import 'package:kidguardian/data/repositories/smart_lock_repository.dart';
import 'package:kidguardian/data/models/smart_lock_settings_model.dart';
import 'package:kidguardian/data/models/monitored_app_model.dart';
import 'package:kidguardian/core/utils/app_utils.dart';
import 'package:intl/intl.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

// Events
abstract class AppMonitorEvent extends Equatable {
  const AppMonitorEvent();

  @override
  List<Object> get props => [];
}

class StartMonitoring extends AppMonitorEvent {
  final String familyId;
  final String childUid;

  const StartMonitoring(this.familyId, this.childUid);

  @override
  List<Object> get props => [familyId, childUid];
}

class AppEventReceived extends AppMonitorEvent {
  final Map<String, dynamic> event;
  const AppEventReceived(this.event);

  @override
  List<Object> get props => [event];
}

class KeywordDetectedEvent extends AppMonitorEvent {
  final String keyword;
  final String packageName;
  final String textContext;

  const KeywordDetectedEvent({
    required this.keyword,
    required this.packageName,
    required this.textContext,
  });

  @override
  List<Object> get props => [keyword, packageName, textContext];
}

class CheckCurrentAppLimit extends AppMonitorEvent {
  const CheckCurrentAppLimit();
}

// States
abstract class AppMonitorState extends Equatable {
  const AppMonitorState();

  @override
  List<Object?> get props => [];
}

class AppMonitorInitial extends AppMonitorState {}
class AppMonitorRunning extends AppMonitorState {}
class KeywordAlertEmitted extends AppMonitorState {
  final String keyword;
  final String packageName;
  final String textContext;

  const KeywordAlertEmitted({
    required this.keyword,
    required this.packageName,
    required this.textContext,
  });

  @override
  List<Object?> get props => [keyword, packageName, textContext];
}
class AppBlockedState extends AppMonitorState {
  final String appPackageName;
  final String appName;
  final String? iconUrl;
  final int limitMinutes;
  final int usedMinutes;
  final DateTime resetTime;
  final String? familyId;
  final String? childUid;
  final String? parentUid;
  final String? blockReason;
  final String? scheduleName;

  const AppBlockedState({
    required this.appPackageName,
    required this.appName,
    this.iconUrl,
    required this.limitMinutes,
    required this.usedMinutes,
    required this.resetTime,
    this.familyId,
    this.childUid,
    this.parentUid,
    this.blockReason,
    this.scheduleName,
  });

  @override
  List<Object?> get props => [
        appPackageName,
        appName,
        iconUrl,
        limitMinutes,
        usedMinutes,
        resetTime,
        familyId,
        childUid,
        parentUid,
        blockReason,
        scheduleName,
      ];
}

class AppMonitorBloc extends Bloc<AppMonitorEvent, AppMonitorState> {
  final CheckAppAccessUseCase checkAppAccessUseCase;
  final BlockAppUseCase blockAppUseCase;
  final UsageRepository usageRepository;
  final SmartLockRepository smartLockRepository;
  final ScheduleChecker scheduleChecker;
  final AlertRepository alertRepository;

  StreamSubscription? _accessibilitySubscription;
  StreamSubscription? _keywordsSubscription;
  // P2: Timer for continuous time checking
  Timer? _limitCheckTimer;
  String? _familyId;
  String? _childUid;

  String? _currentAppPackage;
  DateTime? _currentAppStartTime;
  // P11: Cache last known limits
  bool _isMonitoring = false;
  SmartLockSettingsModel? _settings;
  List<MonitoredAppModel> _monitoredApps = [];

  Future<void> _loadMonitoredApps() async {
    if (_familyId == null || _childUid == null) return;
    try {
      _monitoredApps = await smartLockRepository.getMonitoredApps(_familyId!, _childUid!);
      // FIX #1+#5 Native: Push monitored package list xuống Kotlin để filter tại tầng native
      final monitoredPackages = _monitoredApps
          .where((a) => a.isMonitored)
          .map((a) => a.appPackageName)
          .toList();
      await AccessibilityChannel.updateMonitoredPackages(monitoredPackages);
      debugPrint('AppMonitorBloc: Pushed ${monitoredPackages.length} monitored packages to native');
    } catch (e) {
      debugPrint('AppMonitorBloc._loadMonitoredApps error: $e');
    }
  }

  bool _isAppAllowedToLog(String packageName) {
    // Luôn chặn app hệ thống trước tiên
    if (AppUtils.isSystemOrUnmonitoredApp(packageName)) return false;
    // Nếu danh sách chưa load → chặn tất cả (fail-safe)
    if (_monitoredApps.isEmpty) return false;
    // Closed-by-default: App phải TỒN TẠI trong list VÀ có isMonitored = true
    final found = _monitoredApps.where((a) => a.appPackageName == packageName);
    return found.isNotEmpty && found.first.isMonitored;
  }

  // P12: Cooldown map to prevent spamming createAppBlockedAlert (5 mins per app)
  final Map<String, DateTime> _lastAlertSentMap = {};

  Future<void> _sendBlockedAlertIfNeeded(String packageName, String reason) async {
    if (_familyId == null || _childUid == null) return;
    final lastSent = _lastAlertSentMap[packageName];
    final now = DateTime.now();
    if (lastSent == null || now.difference(lastSent).inMinutes >= 5) {
      _lastAlertSentMap[packageName] = now;
      await alertRepository.createAppBlockedAlert(
        familyId: _familyId!,
        childUid: _childUid!,
        packageName: packageName,
        reason: reason,
      );
    }
  }

  AppMonitorBloc({
    required this.checkAppAccessUseCase,
    required this.blockAppUseCase,
    required this.usageRepository,
    required this.smartLockRepository,
    required this.scheduleChecker,
    required this.alertRepository,
  }) : super(AppMonitorInitial()) {
    on<StartMonitoring>(_onStartMonitoring);
    on<AppEventReceived>(_onAppEventReceived);
    on<KeywordDetectedEvent>(_onKeywordDetected);
    on<CheckCurrentAppLimit>(_onCheckCurrentAppLimit);
  }

  void _onStartMonitoring(StartMonitoring event, Emitter<AppMonitorState> emit) {
    if (_isMonitoring && _familyId == event.familyId && _childUid == event.childUid) return;
    _familyId = event.familyId;
    _childUid = event.childUid;
    _isMonitoring = true;

    // Khởi động MonitorForegroundService ngay khi bật giám sát cho tài khoản con
    AccessibilityChannel.startMonitorService();
    _syncOfflineLogs();

    _loadSettings();
    _loadMonitoredApps();

    _accessibilitySubscription?.cancel();
    _accessibilitySubscription = AccessibilityChannel.accessibilityEvents.listen((data) {
      if (data['type'] == 'keyword_detected') {
        add(KeywordDetectedEvent(
          keyword: data['keyword'] as String? ?? '',
          packageName: data['packageName'] as String? ?? '',
          textContext: data['textContext'] as String? ?? '',
        ));
      } else {
        add(AppEventReceived(data));
      }
    });

    _keywordsSubscription?.cancel();
    _keywordsSubscription = alertRepository.watchKeywords(_familyId!).listen((keywords) {
      AccessibilityChannel.updateKeywords(keywords);
    });

    // P2: Start periodic limit check every 30 seconds
    _limitCheckTimer?.cancel();
    _limitCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isMonitoring) {
        add(const CheckCurrentAppLimit());
        _syncOfflineLogs();
      }
    });

    _syncInstalledApps();

    emit(AppMonitorRunning());
  }

  Future<void> _syncInstalledApps() async {
    if (_familyId == null || _childUid == null) return;
    try {
      // Trì hoãn 2 giây để đảm bảo ChildDashboard đã mount hoàn tất trước khi gọi Native Plugin Android
      await Future.delayed(const Duration(seconds: 2));
      final List<AppInfo> apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        excludeNonLaunchableApps: true,
        withIcon: false,
      );

      final List<Map<String, dynamic>> appDataList = apps.map((app) {
        return {
          'packageName': app.packageName,
          'appName': app.name,
          'versionName': app.versionName,
        };
      }).toList();

      // Sắp xếp theo packageName để đảm bảo thứ tự nhất quán khi tạo hash
      appDataList.sort((a, b) => (a['packageName'] as String).compareTo(b['packageName'] as String));
      final String currentAppsHash = jsonEncode(appDataList);

      final prefs = await SharedPreferences.getInstance();
      final String cacheKeyHash = 'last_synced_apps_hash_${_childUid}';
      final String cacheKeyTime = 'last_synced_time_${_childUid}';

      final String? cachedHash = prefs.getString(cacheKeyHash);
      final int? cachedTime = prefs.getInt(cacheKeyTime);
      final int nowMs = DateTime.now().millisecondsSinceEpoch;

      // Chỉ đồng bộ lên Firestore nếu danh sách app thay đổi HOẶC đã qua 24 giờ (86400000 ms) kể từ lần sync cuối
      final bool hasChanged = cachedHash != currentAppsHash;
      final bool isExpired = cachedTime == null || (nowMs - cachedTime) > 86400000;

      if (!hasChanged && !isExpired) {
        debugPrint('AppMonitorBloc._syncInstalledApps: Danh sách ứng dụng không đổi và chưa quá 24h, bỏ qua ghi Firestore để tiết kiệm Quota.');
        return;
      }

      await smartLockRepository.saveInstalledApps(_familyId!, _childUid!, appDataList);

      await prefs.setString(cacheKeyHash, currentAppsHash);
      await prefs.setInt(cacheKeyTime, nowMs);
      debugPrint('AppMonitorBloc._syncInstalledApps: Đồng bộ danh sách ${appDataList.length} ứng dụng lên Firestore thành công.');
    } catch (e) {
      debugPrint('AppMonitorBloc._syncInstalledApps error: $e');
    }
  }

  Future<void> _loadSettings() async {
    if (_familyId == null || _childUid == null) return;
    try {
      _settings = await smartLockRepository.getSmartLockSettings(_familyId!, _childUid!);
    } catch (e) {
      debugPrint('AppMonitorBloc._loadSettings error: $e');
    }
  }

  // P2: Continuous time checking
  Future<void> _onCheckCurrentAppLimit(CheckCurrentAppLimit event, Emitter<AppMonitorState> emit) async {
    if (_currentAppPackage == null || _familyId == null || _childUid == null) return;

    // P13: Tự động ghi log định kỳ mỗi 1 phút (>= 60s) khi con sử dụng ứng dụng liên tục
    // Giúp phụ huynh và bé cập nhật số liệu thời gian gần như lập tức kể cả khi Smart Lock tắt
    if (_currentAppStartTime != null) {
      final elapsedSeconds = DateTime.now().difference(_currentAppStartTime!).inSeconds;
      if (elapsedSeconds >= 60) {
        debugPrint('[Debug Write] AppMonitorBloc: App $_currentAppPackage đã mở liên tục $elapsedSeconds giây -> trigger periodic _logCurrentAppUsage()');
        _logCurrentAppUsage();
        _currentAppStartTime = DateTime.now();
      }
    }

    // Check if Smart Lock is enabled for blocking
    if (_settings != null && !_settings!.isEnabled) return;

    try {

      // Check time limits
      final isAllowed = await checkAppAccessUseCase.execute(
        familyId: _familyId!,
        childUid: _childUid!,
        appPackageName: _currentAppPackage!,
      );

      if (!isAllowed) {
        // P5: Log usage before blocking
        _logCurrentAppUsage();
        await blockAppUseCase.execute(appPackageName: _currentAppPackage!);
        // D1: Tell native to move task to back
        await AccessibilityChannel.moveTaskToBack();
        
        // Ghi alert có cooldown
        await _sendBlockedAlertIfNeeded(_currentAppPackage!, 'time_limit');

        final blockedState = await _buildBlockedState(_currentAppPackage!, blockReason: 'time_limit');
        emit(blockedState);
        return;
      }

      // Check schedules
      final schedules = await smartLockRepository.getSchedules(_familyId!, _childUid!);
      final activeSchedule = scheduleChecker.getActiveSchedule(schedules, DateTime.now());
      if (activeSchedule != null) {
        _logCurrentAppUsage();
        await blockAppUseCase.execute(appPackageName: _currentAppPackage!);
        await AccessibilityChannel.moveTaskToBack();
        
        // Ghi alert có cooldown
        await _sendBlockedAlertIfNeeded(_currentAppPackage!, 'schedule (${activeSchedule.name})');

        final blockedState = await _buildBlockedState(
          _currentAppPackage!,
          blockReason: 'schedule',
          scheduleName: activeSchedule.name,
          scheduleEndTime: scheduleChecker.getScheduleEndTime(activeSchedule, DateTime.now()),
        );
        emit(blockedState);
      }
    } catch (e) {
      // P8: Log error for debugging
      debugPrint('AppMonitorBloc._onCheckCurrentAppLimit error: $e');
    }
  }

  Future<void> _onAppEventReceived(AppEventReceived event, Emitter<AppMonitorState> emit) async {
    final type = event.event['type'];
    final packageName = event.event['packageName'] as String?;

    if (packageName == null || !_isAppAllowedToLog(packageName)) return;

    if (type == 'app_event') {
      final eventType = event.event['eventType'] ?? event.event['event_type'];

      if (eventType == 'blocked') {
        // D1: Re-show lock screen when user returns to app
        final blockedState = await _buildBlockedState(packageName);
        emit(blockedState);
        return;
      } else if (eventType == 'opened') {
        // Log previous app if exists
        _logCurrentAppUsage();

        _currentAppPackage = packageName;
        _currentAppStartTime = DateTime.now();

        // Check if new app is allowed
        if (_familyId != null && _childUid != null) {
          // Check if Smart Lock is enabled
          if (_settings != null && !_settings!.isEnabled) return;

          try {
            // Check time limits
            final isAllowed = await checkAppAccessUseCase.execute(
              familyId: _familyId!,
              childUid: _childUid!,
              appPackageName: packageName,
            );

            if (!isAllowed) {
              // P5: Log usage before blocking
              _logCurrentAppUsage();
              await blockAppUseCase.execute(appPackageName: packageName);
              // D1: Tell native to move task to back
              await AccessibilityChannel.moveTaskToBack();
              
              // Ghi alert có cooldown
              await _sendBlockedAlertIfNeeded(packageName, 'time_limit');

              final blockedState = await _buildBlockedState(packageName, blockReason: 'time_limit');
              emit(blockedState);
              return;
            }

            // Check schedules
            final schedules = await smartLockRepository.getSchedules(_familyId!, _childUid!);
            final activeSchedule = scheduleChecker.getActiveSchedule(schedules, DateTime.now());
            if (activeSchedule != null) {
              _logCurrentAppUsage();
              await blockAppUseCase.execute(appPackageName: packageName);
              await AccessibilityChannel.moveTaskToBack();
              
              // Ghi alert có cooldown
              await _sendBlockedAlertIfNeeded(packageName, 'schedule (${activeSchedule.name})');

              final blockedState = await _buildBlockedState(
                packageName,
                blockReason: 'schedule',
                scheduleName: activeSchedule.name,
                scheduleEndTime: scheduleChecker.getScheduleEndTime(activeSchedule, DateTime.now()),
              );
              emit(blockedState);
              return;
            }
          } catch (e) {
            // P8: Log error, fail-open for UX
            debugPrint('AppMonitorBloc._onAppEventReceived check error: $e');
          }
        }
      } else if (eventType == 'closed') {
        if (_currentAppPackage == packageName) {
          _logCurrentAppUsage();
          _currentAppPackage = null;
          _currentAppStartTime = null;
        }
      }
    }
  }

  // P12b: Cooldown map để ngăn spam createKeywordAlert (10 phút/keyword)
  final Map<String, DateTime> _lastKeywordAlertMap = {};

  Future<void> _onKeywordDetected(KeywordDetectedEvent event, Emitter<AppMonitorState> emit) async {
    if (_familyId == null || _childUid == null) return;
    if (event.keyword.isEmpty || event.packageName.isEmpty) return;

    // Cooldown 10 phút/keyword: ngăn spam nếu trẻ gõ cùng từ khóa liên tiếp
    final cooldownKey = '${event.keyword}_${event.packageName}';
    final lastSent = _lastKeywordAlertMap[cooldownKey];
    final now = DateTime.now();
    if (lastSent != null && now.difference(lastSent).inMinutes < 10) {
      debugPrint('AppMonitorBloc: Keyword alert cooldown active for "${event.keyword}", skipping write.');
      return;
    }
    _lastKeywordAlertMap[cooldownKey] = now;

    try {
      await alertRepository.createKeywordAlert(
        familyId: _familyId!,
        childUid: _childUid!,
        keyword: event.keyword,
        packageName: event.packageName,
        textContext: event.textContext,
      );
      debugPrint('Keyword alert saved: ${event.keyword} in ${event.packageName}');
      emit(KeywordAlertEmitted(
        keyword: event.keyword,
        packageName: event.packageName,
        textContext: event.textContext,
      ));
    } catch (e) {
      debugPrint('Error saving keyword alert: $e');
    }
  }

  Future<AppBlockedState> _buildBlockedState(
    String packageName, {
    String? blockReason,
    String? scheduleName,
    DateTime? scheduleEndTime,
  }) async {
    final appName = AppUtils.getAppName(packageName);
    final now = DateTime.now();
    // P1: Use add() instead of day+1 to avoid Dec 31 crash
    final resetTime = scheduleEndTime ?? DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

    int limitMinutes = 0;
    int usedMinutes = 0;

    try {
      if (_familyId != null && _childUid != null) {
        if (blockReason != 'schedule') {
          final limits = await smartLockRepository.getAppTimeLimits(
            _familyId!,
            _childUid!,
          );
          for (final limit in limits) {
            if (limit.appPackageName == packageName) {
              final dayKeys = [
                'monday', 'tuesday', 'wednesday', 'thursday',
                'friday', 'saturday', 'sunday',
              ];
              final dayOfWeek = dayKeys[now.weekday - 1];
              if (limit.limits.containsKey(dayOfWeek)) {
                limitMinutes = limit.limits[dayOfWeek]!;
              } else if (limit.limits.containsKey('everyday')) {
                limitMinutes = limit.limits['everyday']!;
              }
              break;
            }
          }

          final dateStr = DateFormat('yyyy-MM-dd').format(now);
          final appUsages = await usageRepository.getUsageByApp(_childUid!, dateStr);
          usedMinutes = appUsages[packageName] ?? 0;
        }
      }
    } catch (e) {
      // P8: Log error for debugging instead of silent swallow
      debugPrint('AppMonitorBloc._buildBlockedState error: $e');
    }

    return AppBlockedState(
      appPackageName: packageName,
      appName: appName,
      limitMinutes: limitMinutes,
      usedMinutes: usedMinutes,
      resetTime: resetTime,
      familyId: _familyId,
      childUid: _childUid,
      parentUid: await _getParentUid(),
      blockReason: blockReason,
      scheduleName: scheduleName,
    );
  }

  Future<String?> _getParentUid() async {
    if (_familyId == null) return null;
    try {
      final family = await smartLockRepository.getFamily(_familyId!);
      return family?.parentUid;
    } catch (e) {
      debugPrint('AppMonitorBloc._getParentUid error: $e');
      return null;
    }
  }

  Future<void> _syncOfflineLogs() async {
    if (_familyId == null || _childUid == null) return;
    try {
      final offlineLogs = await AccessibilityChannel.getAndClearOfflineUsageLogs();
      if (offlineLogs.isNotEmpty) {
        debugPrint('[Offline Sync] AppMonitorBloc: Tìm thấy ${offlineLogs.length} log sử dụng lúc tắt UI');
        for (final item in offlineLogs) {
          final packageName = item['packageName'] as String? ?? '';
          if (AppUtils.isSystemOrUnmonitoredApp(packageName)) continue;
          final startTimeMs = item['startTime'] as int? ?? 0;
          final endTimeMs = item['endTime'] as int? ?? 0;
          final durationSec = item['durationSeconds'] as int? ?? 0;
          if (packageName.isNotEmpty && startTimeMs > 0 && durationSec >= 5) {
            final startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMs);
            final endTime = endTimeMs > 0 ? DateTime.fromMillisecondsSinceEpoch(endTimeMs) : startTime.add(Duration(seconds: durationSec));
            final durationMinutes = (durationSec / 60).ceil();
            final log = UsageLog(
              docId: '',
              childUid: _childUid!,
              familyId: _familyId!,
              appPackage: packageName,
              appName: AppUtils.getAppName(packageName),
              startTime: startTime,
              endTime: endTime,
              durationMinutes: durationMinutes,
              date: DateFormat('yyyy-MM-dd').format(startTime),
            );
            debugPrint('[Offline Sync] Đồng bộ log: $packageName ($durationMinutes phút)');
            await usageRepository.logUsage(log);
          }
        }
      }
    } catch (e) {
      debugPrint('[Offline Sync] Lỗi khi đồng bộ log offline: $e');
    }
  }

  void _logCurrentAppUsage() {
    if (_currentAppPackage != null && _currentAppStartTime != null && _childUid != null && _familyId != null) {
      if (!_isAppAllowedToLog(_currentAppPackage!)) return;
      final now = DateTime.now();
      final durationSeconds = now.difference(_currentAppStartTime!).inSeconds;
      final durationMinutes = (durationSeconds / 60).ceil();

      if (durationSeconds >= 5) {
        debugPrint('[Debug Write] AppMonitorBloc: Ghi nhận app $_currentAppPackage dùng $durationMinutes phút ($durationSeconds giây)');
        final log = UsageLog(
          docId: '',
          childUid: _childUid!,
          familyId: _familyId!,
          appPackage: _currentAppPackage!,
          appName: AppUtils.getAppName(_currentAppPackage!),
          startTime: _currentAppStartTime!,
          endTime: now,
          durationMinutes: durationMinutes,
          date: DateFormat('yyyy-MM-dd').format(now),
        );
        usageRepository.logUsage(log);
      } else {
        debugPrint('[Debug Write] AppMonitorBloc: Bỏ qua log app $_currentAppPackage do thời gian quá ngắn ($durationSeconds s < 5s)');
      }
    }
  }

  @override
  Future<void> close() {
    _isMonitoring = false;
    _accessibilitySubscription?.cancel();
    _keywordsSubscription?.cancel();
    _limitCheckTimer?.cancel();
    _logCurrentAppUsage();
    return super.close();
  }
}
