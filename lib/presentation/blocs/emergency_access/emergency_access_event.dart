import 'package:equatable/equatable.dart';

abstract class EmergencyAccessEvent extends Equatable {
  const EmergencyAccessEvent();

  @override
  List<Object?> get props => [];
}

class LoadEmergencyHistory extends EmergencyAccessEvent {
  final String familyId;

  const LoadEmergencyHistory({required this.familyId});

  @override
  List<Object?> get props => [familyId];
}

class LoadEmergencyContacts extends EmergencyAccessEvent {
  final String parentUid;

  const LoadEmergencyContacts({required this.parentUid});

  @override
  List<Object?> get props => [parentUid];
}

class UpdateEmergencyPhone extends EmergencyAccessEvent {
  final String parentUid;
  final String phoneNumber;

  const UpdateEmergencyPhone({
    required this.parentUid,
    required this.phoneNumber,
  });

  @override
  List<Object?> get props => [parentUid, phoneNumber];
}

class ActivateEmergency extends EmergencyAccessEvent {
  final String childUid;
  final String familyId;
  final String action;
  final String phoneNumber;
  final String appPackageName;

  const ActivateEmergency({
    required this.childUid,
    required this.familyId,
    required this.action,
    required this.phoneNumber,
    required this.appPackageName,
  });

  @override
  List<Object?> get props => [childUid, familyId, action, phoneNumber, appPackageName];
}

class DeactivateEmergency extends EmergencyAccessEvent {
  final String childUid;

  const DeactivateEmergency({required this.childUid});

  @override
  List<Object?> get props => [childUid];
}

class ListenEmergencyState extends EmergencyAccessEvent {}

class EmergencyTimerUpdated extends EmergencyAccessEvent {
  final int remainingSeconds;

  const EmergencyTimerUpdated({required this.remainingSeconds});

  @override
  List<Object?> get props => [remainingSeconds];
}
