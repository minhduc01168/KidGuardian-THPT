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

class AppMonitorBloc extends Bloc<AppMonitorEvent, AppMonitorState> {
  final CheckAppAccessUseCase checkAppAccessUseCase;
  final BlockAppUseCase blockAppUseCase;
  final UsageRepository usageRepository;

  StreamSubscription? _accessibilitySubscription;
  String? _familyId;
  String? _childUid;

  String? _currentAppPackage;
  DateTime? _currentAppStartTime;

  AppMonitorBloc({
    required this.checkAppAccessUseCase,
    required this.blockAppUseCase,
    required this.usageRepository,
  }) : super(AppMonitorInitial()) {
    on<StartMonitoring>(_onStartMonitoring);
    on<AppEventReceived>(_onAppEventReceived);
  }

  void _onStartMonitoring(StartMonitoring event, Emitter<AppMonitorState> emit) {
    _familyId = event.familyId;
    _childUid = event.childUid;

    _accessibilitySubscription?.cancel();
    _accessibilitySubscription = AccessibilityChannel.accessibilityEvents.listen((data) {
      add(AppEventReceived(data));
    });

    emit(AppMonitorRunning());
  }

  Future<void> _onAppEventReceived(AppEventReceived event, Emitter<AppMonitorState> emit) async {
    final type = event.event['type'];
    final packageName = event.event['packageName'] as String?;

    if (packageName == null) return;

    if (type == 'app_blocked') {
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
          final isAllowed = await checkAppAccessUseCase.execute(
            familyId: _familyId!,
            childUid: _childUid!,
            appPackageName: packageName,
          );

          if (!isAllowed) {
            await blockAppUseCase.execute(appPackageName: packageName);
            emit(AppBlockedState(packageName));
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
      final duration = now.difference(_currentAppStartTime!).inMinutes;

      if (duration >= 1) { // Only log if used for at least 1 minute
        final log = UsageLog(
          docId: '',
          childUid: _childUid!,
          familyId: _familyId!,
          appPackage: _currentAppPackage!,
          appName: _currentAppPackage!, // We might need to map package to name later
          startTime: _currentAppStartTime!,
          endTime: now,
          durationMinutes: duration,
          date: DateFormat('yyyy-MM-dd').format(now),
        );
        usageRepository.logUsage(log);
      }
    }
  }

  @override
  Future<void> close() {
    _accessibilitySubscription?.cancel();
    _logCurrentAppUsage();
    return super.close();
  }
}
