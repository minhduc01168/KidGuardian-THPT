import 'package:equatable/equatable.dart';
import 'package:kidguardian/data/models/app_time_limit_model.dart';
import 'package:kidguardian/data/models/monitored_app_model.dart';

abstract class SmartLockState extends Equatable {
  const SmartLockState();
  
  @override
  List<Object> get props => [];
}

class SmartLockInitial extends SmartLockState {}

class SmartLockLoading extends SmartLockState {}

class SmartLockLoaded extends SmartLockState {
  final List<AppTimeLimitModel> apps;

  const SmartLockLoaded(this.apps);

  @override
  List<Object> get props => [apps];
}

class MonitoredAppsLoaded extends SmartLockState {
  final List<MonitoredAppModel> apps;

  const MonitoredAppsLoaded(this.apps);

  @override
  List<Object> get props => [apps];
}

class SmartLockActionSuccess extends SmartLockState {
  final String message;

  const SmartLockActionSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class SmartLockError extends SmartLockState {
  final String message;

  const SmartLockError(this.message);

  @override
  List<Object> get props => [message];
}
