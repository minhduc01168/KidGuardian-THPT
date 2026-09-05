import 'package:equatable/equatable.dart';

abstract class FamilyEvent extends Equatable {
  const FamilyEvent();

  @override
  List<Object?> get props => [];
}

class CreateFamilyRequested extends FamilyEvent {
  final String parentUid;

  const CreateFamilyRequested({required this.parentUid});

  @override
  List<Object?> get props => [parentUid];
}

class LoadFamilyRequested extends FamilyEvent {
  final String parentUid;

  const LoadFamilyRequested({required this.parentUid});

  @override
  List<Object?> get props => [parentUid];
}

class GenerateLinkingCodeRequested extends FamilyEvent {
  final String familyId;

  const GenerateLinkingCodeRequested({required this.familyId});

  @override
  List<Object?> get props => [familyId];
}



class LinkChildToFamilyRequested extends FamilyEvent {
  final String linkingCode;
  final String childUid;

  const LinkChildToFamilyRequested({
    required this.linkingCode,
    required this.childUid,
  });

  @override
  List<Object?> get props => [linkingCode, childUid];
}

class RemoveChildFromFamilyRequested extends FamilyEvent {
  final String familyId;
  final String childUid;

  const RemoveChildFromFamilyRequested({
    required this.familyId,
    required this.childUid,
  });

  @override
  List<Object?> get props => [familyId, childUid];
}
