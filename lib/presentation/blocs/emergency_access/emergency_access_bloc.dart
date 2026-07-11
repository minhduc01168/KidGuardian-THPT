import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidguardian/data/datasources/remote/emergency_log_source.dart';
import 'package:kidguardian/domain/usecases/smart_lock/emergency_access_manager.dart';
import 'emergency_access_event.dart';
import 'emergency_access_state.dart';

class EmergencyAccessBloc extends Bloc<EmergencyAccessEvent, EmergencyAccessState> {
  final EmergencyLogSource _logSource;
  final EmergencyAccessManager _emergencyManager;
  StreamSubscription<int>? _timerSubscription;
  StreamSubscription<EmergencyState>? _stateSubscription;

  EmergencyAccessBloc({
    required EmergencyLogSource logSource,
    EmergencyAccessManager? emergencyManager,
  })  : _logSource = logSource,
        _emergencyManager = emergencyManager ?? EmergencyAccessManager(),
        super(EmergencyAccessInitial()) {
    on<LoadEmergencyHistory>(_onLoadHistory);
    on<LoadEmergencyContacts>(_onLoadContacts);
    on<UpdateEmergencyPhone>(_onUpdatePhone);
    on<ActivateEmergency>(_onActivate);
    on<DeactivateEmergency>(_onDeactivate);
    on<ListenEmergencyState>(_onListenState);
    on<EmergencyTimerUpdated>(_onTimerUpdated);

    _listenToEmergencyState();
  }

  void _listenToEmergencyState() {
    _timerSubscription = _emergencyManager.remainingStream.listen((remaining) {
      add(EmergencyTimerUpdated(remainingSeconds: remaining));
    });
    _stateSubscription = _emergencyManager.stateStream.listen((emergencyState) {
      if (emergencyState == EmergencyState.cooldown) {
        add(ListenEmergencyState());
      }
    });
  }

  Future<void> _onLoadHistory(
    LoadEmergencyHistory event,
    Emitter<EmergencyAccessState> emit,
  ) async {
    emit(EmergencyAccessLoading());
    try {
      final history = await _logSource.getEmergencyHistory(
        familyId: event.familyId,
      );
      emit(EmergencyHistoryLoaded(history: history));
    } catch (e) {
      emit(EmergencyAccessError(message: 'Không thể tải lịch sử: $e'));
    }
  }

  Future<void> _onLoadContacts(
    LoadEmergencyContacts event,
    Emitter<EmergencyAccessState> emit,
  ) async {
    emit(EmergencyAccessLoading());
    try {
      final name = await _logSource.getParentName(event.parentUid);
      final phone = await _logSource.getParentPhoneNumber(event.parentUid);
      emit(EmergencyContactLoaded(parentName: name, parentPhone: phone));
    } catch (e) {
      emit(EmergencyAccessError(message: 'Không thể tải thông tin liên hệ: $e'));
    }
  }

  Future<void> _onUpdatePhone(
    UpdateEmergencyPhone event,
    Emitter<EmergencyAccessState> emit,
  ) async {
    emit(EmergencyAccessLoading());
    try {
      await _logSource.updateParentPhoneNumber(
        parentUid: event.parentUid,
        phoneNumber: event.phoneNumber,
      );
      emit(const EmergencyAccessSuccess(message: 'Cập nhật số điện thoại thành công'));
    } catch (e) {
      emit(EmergencyAccessError(message: 'Không thể cập nhật số điện thoại: $e'));
    }
  }

  Future<void> _onActivate(
    ActivateEmergency event,
    Emitter<EmergencyAccessState> emit,
  ) async {
    if (!_emergencyManager.canActivate) {
      emit(const EmergencyAccessError(
        message: 'Không thể kích hoạt lúc này. Vui lòng đợi cooldown.',
      ));
      return;
    }

    _emergencyManager.activate();

    await _logSource.logEmergencyStart(
      childUid: event.childUid,
      familyId: event.familyId,
      action: event.action,
      phoneNumber: event.phoneNumber,
      appPackageName: event.appPackageName,
    );

    emit(EmergencyActivated(
      action: event.action,
      phoneNumber: event.phoneNumber,
    ));
  }

  Future<void> _onDeactivate(
    DeactivateEmergency event,
    Emitter<EmergencyAccessState> emit,
  ) async {
    _emergencyManager.deactivate();

    await _logSource.logEmergencyEnd(
      childUid: event.childUid,
      durationSeconds: EmergencyAccessManager.emergencyDuration.inSeconds -
          _emergencyManager.remainingSeconds,
    );

    emit(const EmergencyAccessSuccess(message: 'Đã tắt truy cập khẩn cấp'));
  }

  void _onListenState(
    ListenEmergencyState event,
    Emitter<EmergencyAccessState> emit,
  ) {
    if (_emergencyManager.isActive) {
      emit(EmergencyActive(
        remainingSeconds: _emergencyManager.remainingSeconds,
        action: '',
        phoneNumber: '',
      ));
    } else if (_emergencyManager.cooldownUntil != null) {
      emit(EmergencyCooldown(
        cooldownSeconds: _emergencyManager.cooldownRemainingSeconds,
      ));
    }
  }

  void _onTimerUpdated(
    EmergencyTimerUpdated event,
    Emitter<EmergencyAccessState> emit,
  ) {
    if (_emergencyManager.isActive) {
      final current = state;
      if (current is EmergencyActive) {
        emit(EmergencyActive(
          remainingSeconds: event.remainingSeconds,
          action: current.action,
          phoneNumber: current.phoneNumber,
        ));
      }
    }
  }

  bool get canActivate => _emergencyManager.canActivate;
  bool get isActive => _emergencyManager.isActive;
  int get remainingSeconds => _emergencyManager.remainingSeconds;

  @override
  Future<void> close() {
    _timerSubscription?.cancel();
    _stateSubscription?.cancel();
    return super.close();
  }
}
