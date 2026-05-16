import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:kidguardian/platform/android/accessibility_channel.dart';
import 'package:kidguardian/domain/usecases/smart_lock/check_app_access_usecase.dart';
import 'package:kidguardian/domain/usecases/smart_lock/block_app_usecase.dart';
import 'package:kidguardian/domain/usecases/smart_lock/schedule_checker.dart';
import 'package:kidguardian/domain/entities/usage_log.dart';
import 'package:kidguardian/domain/repositories/usage_repository.dart';
import 'package:kidguardian/data/repositories/smart_lock_repository.dart';
import 'package:intl/intl.dart';

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
class AppBlockedState extends AppMonitorState {
  final String appPackageName;
  final String appName;
  final String? iconUrl;
  final int limitMinutes;
  final int usedMinutes;
  final DateTime resetTime;
  final String? familyId;
  final String? childUid;
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
        blockReason,
        scheduleName,
      ];
}

// P9: App name mapping for common apps
const _appNameMap = {
  'com.zhiliaoapp.musically': 'TikTok',
  'com.facebook.katana': 'Facebook',
  'com.google.android.youtube': 'YouTube',
  'com.instagram.android': 'Instagram',
  'com.zing.zalo': 'Zalo',
  'com.roblox.client': 'Roblox',
  'com.dts.freefireth': 'Free Fire',
};

class AppMonitorBloc extends Bloc<AppMonitorEvent, AppMonitorState> {
  final CheckAppAccessUseCase checkAppAccessUseCase;
  final BlockAppUseCase blockAppUseCase;
  final UsageRepository usageRepository;
  final SmartLockRepository smartLockRepository;
  final ScheduleChecker scheduleChecker;

  StreamSubscription? _accessibilitySubscription;
  // P2: Timer for continuous time checking
  Timer? _limitCheckTimer;
  String? _familyId;
  String? _childUid;

  String? _currentAppPackage;
  DateTime? _currentAppStartTime;
  // P11: Cache last known limits
  bool _isMonitoring = false;

  AppMonitorBloc({
    required this.checkAppAccessUseCase,
    required this.blockAppUseCase,
    required this.usageRepository,
    required this.smartLockRepository,
    required this.scheduleChecker,
  }) : super(AppMonitorInitial()) {
    on<StartMonitoring>(_onStartMonitoring);
    on<AppEventReceived>(_onAppEventReceived);
    on<CheckCurrentAppLimit>(_onCheckCurrentAppLimit);
  }

  void _onStartMonitoring(StartMonitoring event, Emitter<AppMonitorState> emit) {
    _familyId = event.familyId;
    _childUid = event.childUid;
    _isMonitoring = true;

    _accessibilitySubscription?.cancel();
    _accessibilitySubscription = AccessibilityChannel.accessibilityEvents.listen((data) {
      add(AppEventReceived(data));
    });

    // P2: Start periodic limit check every 30 seconds
    _limitCheckTimer?.cancel();
    _limitCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isMonitoring) {
        add(const CheckCurrentAppLimit());
      }
    });

    emit(AppMonitorRunning());
  }

  // P2: Continuous time checking
  Future<void> _onCheckCurrentAppLimit(CheckCurrentAppLimit event, Emitter<AppMonitorState> emit) async {
    if (_currentAppPackage == null || _familyId == null || _childUid == null) return;

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

    if (packageName == null) return;

    if (type == 'app_blocked') {
      // D1: Re-show lock screen when user returns to app
      final blockedState = await _buildBlockedState(packageName);
      emit(blockedState);
      return;
    }

    if (type == 'app_event') {
      final eventType = event.event['event_type'];

      if (eventType == 'opened') {
        // Log previous app if exists
        _logCurrentAppUsage();

        _currentAppPackage = packageName;
        _currentAppStartTime = DateTime.now();

        // Check if new app is allowed
        if (_familyId != null && _childUid != null) {
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

  Future<AppBlockedState> _buildBlockedState(
    String packageName, {
    String? blockReason,
    String? scheduleName,
    DateTime? scheduleEndTime,
  }) async {
    final appName = _appNameMap[packageName] ?? packageName;
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
      blockReason: blockReason,
      scheduleName: scheduleName,
    );
  }

  void _logCurrentAppUsage() {
    if (_currentAppPackage != null && _currentAppStartTime != null && _childUid != null && _familyId != null) {
      final now = DateTime.now();
      final durationSeconds = now.difference(_currentAppStartTime!).inSeconds;
      final durationMinutes = (durationSeconds / 60).ceil();

      if (durationSeconds >= 30) {
        final log = UsageLog(
          docId: '',
          childUid: _childUid!,
          familyId: _familyId!,
          appPackage: _currentAppPackage!,
          appName: _appNameMap[_currentAppPackage!] ?? _currentAppPackage!,
          startTime: _currentAppStartTime!,
          endTime: now,
          durationMinutes: durationMinutes,
          date: DateFormat('yyyy-MM-dd').format(now),
        );
        usageRepository.logUsage(log);
      }
    }
  }

  @override
  Future<void> close() {
    _isMonitoring = false;
    _accessibilitySubscription?.cancel();
    _limitCheckTimer?.cancel();
    _logCurrentAppUsage();
    return super.close();
  }
}
