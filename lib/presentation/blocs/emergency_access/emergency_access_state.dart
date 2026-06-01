import 'package:equatable/equatable.dart';
import 'package:kidguardian/data/models/emergency_log_model.dart';
import 'package:kidguardian/domain/usecases/smart_lock/emergency_access_manager.dart';

abstract class EmergencyAccessState extends Equatable {
  const EmergencyAccessState();

  @override
  List<Object?> get props => [];
}

class EmergencyAccessInitial extends EmergencyAccessState {}

class EmergencyAccessLoading extends EmergencyAccessState {}

class EmergencyHistoryLoaded extends EmergencyAccessState {
  final List<EmergencyLogModel> history;

  const EmergencyHistoryLoaded({required this.history});

  @override
  List<Object?> get props => [history];
}

class EmergencyContactLoaded extends EmergencyAccessState {
  final String? parentName;
  final String? parentPhone;

  const EmergencyContactLoaded({
    this.parentName,
    this.parentPhone,
  });

  @override
  List<Object?> get props => [parentName, parentPhone];
}

class EmergencyActive extends EmergencyAccessState {
  final int remainingSeconds;
  final String action;
  final String phoneNumber;

  const EmergencyActive({
    required this.remainingSeconds,
    required this.action,
    required this.phoneNumber,
  });

  @override
  List<Object?> get props => [remainingSeconds, action, phoneNumber];
}

class EmergencyCooldown extends EmergencyAccessState {
  final int cooldownSeconds;

  const EmergencyCooldown({required this.cooldownSeconds});

  @override
  List<Object?> get props => [cooldownSeconds];
}

class EmergencyActivated extends EmergencyAccessState {
  final String action;
  final String phoneNumber;

  const EmergencyActivated({
    required this.action,
    required this.phoneNumber,
  });

  @override
  List<Object?> get props => [action, phoneNumber];
}

class EmergencyAccessSuccess extends EmergencyAccessState {
  final String message;

  const EmergencyAccessSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class EmergencyAccessError extends EmergencyAccessState {
  final String message;

  const EmergencyAccessError({required this.message});

  @override
  List<Object?> get props => [message];
}
