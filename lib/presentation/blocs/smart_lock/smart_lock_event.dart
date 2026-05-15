import 'package:equatable/equatable.dart';
import 'package:kidguardian/data/models/app_time_limit_model.dart';

abstract class SmartLockEvent extends Equatable {
  const SmartLockEvent();

  @override
  List<Object> get props => [];
}

class LoadAppTimeLimits extends SmartLockEvent {
  final String familyId;
  final String childId;

  const LoadAppTimeLimits(this.familyId, this.childId);

  @override
  List<Object> get props => [familyId, childId];
}

class SaveAppTimeLimit extends SmartLockEvent {
  final String familyId;
  final String childId;
  final AppTimeLimitModel limit;

  const SaveAppTimeLimit(this.familyId, this.childId, this.limit);

  @override
  List<Object> get props => [familyId, childId, limit];
}
