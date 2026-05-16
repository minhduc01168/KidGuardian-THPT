import 'dart:async';
import 'package:flutter/foundation.dart';

class EmergencyAccessManager {
  static final EmergencyAccessManager _instance = EmergencyAccessManager._();
  factory EmergencyAccessManager() => _instance;
  EmergencyAccessManager._();

  static const Duration emergencyDuration = Duration(minutes: 5);
  static const Duration cooldownDuration = Duration(minutes: 15);

  bool _isActive = false;
  DateTime? _cooldownUntil;
  Timer? _timer;
  int _remainingSeconds = 0;

  final _remainingController = StreamController<int>.broadcast();
  final _stateController = StreamController<EmergencyState>.broadcast();

  Stream<int> get remainingStream => _remainingController.stream;
  Stream<EmergencyState> get stateStream => _stateController.stream;

  bool get isActive => _isActive;
  int get remainingSeconds => _remainingSeconds;
  DateTime? get cooldownUntil => _cooldownUntil;

  bool get canActivate {
    if (_isActive) return false;
    if (_cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!)) {
      return false;
    }
    return true;
  }

  int get cooldownRemainingSeconds {
    if (_cooldownUntil == null) return 0;
    final remaining = _cooldownUntil!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  void _safeAdd<T>(StreamController<T> controller, T value) {
    if (!controller.isClosed) {
      controller.add(value);
    }
  }

  void activate() {
    if (!canActivate) return;

    _isActive = true;
    _remainingSeconds = emergencyDuration.inSeconds;
    _cooldownUntil = null;

    _safeAdd(_remainingController, _remainingSeconds);
    _safeAdd(_stateController, EmergencyState.active);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      _safeAdd(_remainingController, _remainingSeconds);

      if (_remainingSeconds <= 0) {
        _deactivate();
      }
    });

    debugPrint('EmergencyAccessManager: activated for ${emergencyDuration.inMinutes} minutes');
  }

  void _deactivate() {
    _timer?.cancel();
    _timer = null;
    _isActive = false;
    _cooldownUntil = DateTime.now().add(cooldownDuration);
    _remainingSeconds = 0;

    _safeAdd(_stateController, EmergencyState.cooldown);
    debugPrint('EmergencyAccessManager: deactivated, cooldown until $_cooldownUntil');
  }

  void deactivate() {
    if (!_isActive) return;
    _deactivate();
  }

  void dispose() {
    _timer?.cancel();
    // Don't close stream controllers - singleton lives for app lifetime
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _isActive = false;
    _cooldownUntil = null;
    _remainingSeconds = 0;
    _safeAdd(_stateController, EmergencyState.inactive);
  }
}

enum EmergencyState { inactive, active, cooldown }
