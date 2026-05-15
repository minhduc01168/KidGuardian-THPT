import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidguardian/data/repositories/smart_lock_repository.dart';
import 'package:kidguardian/data/models/app_time_limit_model.dart';
import 'smart_lock_event.dart';
import 'smart_lock_state.dart';

class SmartLockBloc extends Bloc<SmartLockEvent, SmartLockState> {
  final SmartLockRepository repository;
  
  List<AppTimeLimitModel> _currentApps = [];

  SmartLockBloc({required this.repository}) : super(SmartLockInitial()) {
    on<LoadAppTimeLimits>(_onLoadAppTimeLimits);
    on<SaveAppTimeLimit>(_onSaveAppTimeLimit);
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
      
      // Get predefined popular apps and merge with configured ones
      final popularApps = repository.getPopularApps();
      final Map<String, AppTimeLimitModel> mergedApps = {};
      
      // Add predefined apps first
      for (var app in popularApps) {
        mergedApps[app.appPackageName] = app;
      }
      
      // Override with configured limits
      for (var app in configuredApps) {
        mergedApps[app.appPackageName] = app;
      }
      
      _currentApps = mergedApps.values.toList()
        ..sort((a, b) {
          // Sort apps with limits to the top
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
      
      // Update local cache
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
      
      // Sort again
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
}
