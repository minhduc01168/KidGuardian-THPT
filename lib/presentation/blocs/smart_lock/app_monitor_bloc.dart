import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kidguardian/platform/android/accessibility_channel.dart';
import 'package:kidguardian/domain/usecases/smart_lock/check_app_access_usecase.dart';
import 'package:kidguardian/domain/usecases/smart_lock/block_app_usecase.dart';
import 'package:kidguardian/domain/entities/usage_log.dart';
import 'package:kidguardian/domain/repositories/usage_repository.dart';
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
  List<Object> get props => [];
}

class AppMonitorInitial extends AppMonitorState {}
class AppMonitorRunning extends AppMonitorState {}
class AppBlockedState extends AppMonitorState {
  final String appPackageName;

  const AppBlockedState(this.appPackageName);

  @override
  List<Object> get props => [appPackageName];
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
        emit(AppBlockedState(_currentAppPackage!));
      }
    } catch (_) {
      // Silently handle - will retry on next timer tick
    }
  }

  Future<void> _onAppEventReceived(AppEventReceived event, Emitter<AppMonitorState> emit) async {
    final type = event.event['type'];
    final packageName = event.event['packageName'] as String?;

    if (packageName == null) return;

    if (type == 'app_blocked') {
      // D1: Re-show lock screen when user returns to app
      emit(AppBlockedState(packageName));
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
              emit(AppBlockedState(packageName));
            }
          } catch (_) {
            // If check fails, allow access (fail-open for UX)
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
