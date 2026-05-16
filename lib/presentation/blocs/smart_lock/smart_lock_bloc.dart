import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidguardian/data/repositories/smart_lock_repository.dart';
import 'package:kidguardian/data/models/app_time_limit_model.dart';
import 'package:kidguardian/data/models/monitored_app_model.dart';
import 'package:kidguardian/data/models/schedule_model.dart';
import 'package:kidguardian/platform/android/accessibility_channel.dart';
import 'smart_lock_event.dart';
import 'smart_lock_state.dart';

class SmartLockBloc extends Bloc<SmartLockEvent, SmartLockState> {
  final SmartLockRepository repository;

  List<AppTimeLimitModel> _currentApps = [];
  List<MonitoredAppModel> _currentMonitoredApps = [];
  List<ScheduleModel> _currentSchedules = [];

  // P6: Debounce timer for native sync
  Timer? _syncDebounceTimer;

  // P7: Package name validation regex
  static final _packageNameRegex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*){2,}$');

  SmartLockBloc({required this.repository}) : super(SmartLockInitial()) {
    on<LoadAppTimeLimits>(_onLoadAppTimeLimits);
    on<SaveAppTimeLimit>(_onSaveAppTimeLimit);
    on<LoadMonitoredApps>(_onLoadMonitoredApps);
    on<ToggleMonitoredApp>(_onToggleMonitoredApp);
    on<AddCustomApp>(_onAddCustomApp);
    on<LoadSchedules>(_onLoadSchedules);
    on<SaveSchedule>(_onSaveSchedule);
    on<DeleteSchedule>(_onDeleteSchedule);
  }

  Future<void> _onLoadAppTimeLimits(
    LoadAppTimeLimits event,
    Emitter<SmartLockState> emit,
  ) async {
    emit(SmartLockLoading());
    try {
      final configuredApps = await repository.getAppTimeLimits(
        event.familyId,
        event.childId,
      );

      final popularApps = repository.getPopularApps();
      final Map<String, AppTimeLimitModel> mergedApps = {};

      for (var app in popularApps) {
        mergedApps[app.appPackageName] = app;
      }

      for (var app in configuredApps) {
        mergedApps[app.appPackageName] = app;
      }

      _currentApps = mergedApps.values.toList()
        ..sort((a, b) {
          final aHasLimit = a.limits.isNotEmpty ? -1 : 1;
          final bHasLimit = b.limits.isNotEmpty ? -1 : 1;
          if (aHasLimit != bHasLimit) return aHasLimit.compareTo(bHasLimit);
          return a.appName.compareTo(b.appName);
        });

      emit(SmartLockLoaded(_currentApps));
    } catch (e) {
      emit(SmartLockError(e.toString()));
    }
  }

  Future<void> _onSaveAppTimeLimit(
    SaveAppTimeLimit event,
    Emitter<SmartLockState> emit,
  ) async {
    try {
      await repository.saveAppTimeLimit(
        event.familyId,
        event.childId,
        event.limit,
      );

      final index = _currentApps.indexWhere(
        (app) => app.appPackageName == event.limit.appPackageName,
      );

      bool isUpdate = false;
      if (index != -1) {
        if (_currentApps[index].limits.isNotEmpty) {
          isUpdate = true;
        }
        _currentApps[index] = event.limit;
      } else {
        _currentApps.add(event.limit);
      }

      _currentApps.sort((a, b) {
        final aHasLimit = a.limits.isNotEmpty ? -1 : 1;
        final bHasLimit = b.limits.isNotEmpty ? -1 : 1;
        if (aHasLimit != bHasLimit) return aHasLimit.compareTo(bHasLimit);
        return a.appName.compareTo(b.appName);
      });

      if (isUpdate) {
        emit(const SmartLockActionSuccess('Đã cập nhật cài đặt thành công'));
      } else {
        emit(SmartLockActionSuccess('Đã lưu cài đặt thời gian cho ${event.limit.appName} thành công'));
      }
      emit(SmartLockLoaded(List.from(_currentApps)));
    } catch (e) {
      emit(SmartLockError(e.toString()));
      emit(SmartLockLoaded(List.from(_currentApps)));
    }
  }

  // Monitored Apps handlers

  Future<void> _onLoadMonitoredApps(
    LoadMonitoredApps event,
    Emitter<SmartLockState> emit,
  ) async {
    emit(SmartLockLoading());
    try {
      final configuredApps = await repository.getMonitoredApps(
        event.familyId,
        event.childId,
      );

      final popularApps = repository.getPopularMonitoredApps();
      final Map<String, MonitoredAppModel> mergedApps = {};

      for (var app in popularApps) {
        mergedApps[app.appPackageName] = app;
      }

      for (var app in configuredApps) {
        mergedApps[app.appPackageName] = app;
      }

      _currentMonitoredApps = mergedApps.values.toList()
        ..sort((a, b) {
          if (a.isMonitored != b.isMonitored) {
            return a.isMonitored ? -1 : 1;
          }
          return a.appName.compareTo(b.appName);
        });

      // P3: Sync native on initial load
      await _syncBlockedAppsToNative();

      emit(MonitoredAppsLoaded(List.from(_currentMonitoredApps)));
    } catch (e) {
      emit(SmartLockError(e.toString()));
    }
  }

  Future<void> _onToggleMonitoredApp(
    ToggleMonitoredApp event,
    Emitter<SmartLockState> emit,
  ) async {
    try {
      await repository.toggleMonitoredApp(
        event.familyId,
        event.childId,
        event.appPackageName,
        event.isMonitored,
      );

      final index = _currentMonitoredApps.indexWhere(
        (app) => app.appPackageName == event.appPackageName,
      );
      if (index != -1) {
        _currentMonitoredApps[index] = _currentMonitoredApps[index].copyWith(
          isMonitored: event.isMonitored,
        );
      }

      _currentMonitoredApps.sort((a, b) {
        if (a.isMonitored != b.isMonitored) {
          return a.isMonitored ? -1 : 1;
        }
        return a.appName.compareTo(b.appName);
      });

      // P6: Debounce native sync
      _debounceSync();

      emit(MonitoredAppsLoaded(List.from(_currentMonitoredApps)));
    } catch (e) {
      emit(SmartLockError(e.toString()));
      emit(MonitoredAppsLoaded(List.from(_currentMonitoredApps)));
    }
  }

  Future<void> _onAddCustomApp(
    AddCustomApp event,
    Emitter<SmartLockState> emit,
  ) async {
    // P7: Validate package name format
    if (!_packageNameRegex.hasMatch(event.packageName)) {
      emit(const SmartLockError('Package name không hợp lệ. Định dạng: com.example.app'));
      emit(MonitoredAppsLoaded(List.from(_currentMonitoredApps)));
      return;
    }

    // P4: Check for duplicates
    if (_currentMonitoredApps.any((a) => a.appPackageName == event.packageName)) {
      emit(const SmartLockError('Ứng dụng này đã tồn tại trong danh sách'));
      emit(MonitoredAppsLoaded(List.from(_currentMonitoredApps)));
      return;
    }

    try {
      final app = MonitoredAppModel(
        appPackageName: event.packageName,
        appName: event.appName,
        isMonitored: true,
      );

      await repository.addCustomApp(event.familyId, event.childId, app);

      _currentMonitoredApps.add(app);
      _currentMonitoredApps.sort((a, b) {
        if (a.isMonitored != b.isMonitored) {
          return a.isMonitored ? -1 : 1;
        }
        return a.appName.compareTo(b.appName);
      });

      // P6: Debounce native sync
      _debounceSync();

      emit(MonitoredAppsLoaded(List.from(_currentMonitoredApps)));
    } catch (e) {
      emit(SmartLockError(e.toString()));
      emit(MonitoredAppsLoaded(List.from(_currentMonitoredApps)));
    }
  }

  // P6: Debounce native sync to avoid rapid-fire IPC
  void _debounceSync() {
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _syncBlockedAppsToNative();
    });
  }

  Future<void> _syncBlockedAppsToNative() async {
    final monitoredPackageNames = _currentMonitoredApps
        .where((app) => app.isMonitored)
        .map((app) => app.appPackageName)
        .toList();
    await AccessibilityChannel.updateBlockedApps(monitoredPackageNames);
  }

  // Schedule handlers

  Future<void> _onLoadSchedules(
    LoadSchedules event,
    Emitter<SmartLockState> emit,
  ) async {
    emit(SmartLockLoading());
    try {
      _currentSchedules = await repository.getSchedules(
        event.familyId,
        event.childId,
      );
      emit(SchedulesLoaded(List.from(_currentSchedules)));
    } catch (e) {
      emit(SmartLockError(e.toString()));
    }
  }

  Future<void> _onSaveSchedule(
    SaveSchedule event,
    Emitter<SmartLockState> emit,
  ) async {
    try {
      await repository.saveSchedule(
        event.familyId,
        event.childId,
        event.schedule,
      );

      final index = _currentSchedules.indexWhere(
        (s) => s.id == event.schedule.id,
      );

      bool isUpdate = false;
      if (index != -1) {
        isUpdate = true;
        _currentSchedules[index] = event.schedule;
      } else {
        _currentSchedules.add(event.schedule);
      }

      if (isUpdate) {
        emit(const SmartLockActionSuccess('Đã cập nhật lịch trình thành công'));
      } else {
        emit(const SmartLockActionSuccess('Đã lưu lịch trình thành công'));
      }
      emit(SchedulesLoaded(List.from(_currentSchedules)));
    } catch (e) {
      emit(SmartLockError(e.toString()));
      emit(SchedulesLoaded(List.from(_currentSchedules)));
    }
  }

  Future<void> _onDeleteSchedule(
    DeleteSchedule event,
    Emitter<SmartLockState> emit,
  ) async {
    try {
      await repository.deleteSchedule(
        event.familyId,
        event.childId,
        event.scheduleId,
      );

      _currentSchedules.removeWhere((s) => s.id == event.scheduleId);

      emit(const SmartLockActionSuccess('Đã xoá lịch trình thành công'));
      emit(SchedulesLoaded(List.from(_currentSchedules)));
    } catch (e) {
      emit(SmartLockError(e.toString()));
      emit(SchedulesLoaded(List.from(_currentSchedules)));
    }
  }

  @override
  Future<void> close() {
    _syncDebounceTimer?.cancel();
    return super.close();
  }
}
