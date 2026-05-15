import 'package:equatable/equatable.dart';
import '../../../../domain/entities/family.dart';
import '../../../../domain/entities/user.dart';

abstract class FamilyState extends Equatable {
  const FamilyState();

  @override
  List<Object?> get props => [];
}

class FamilyInitial extends FamilyState {}

class FamilyLoading extends FamilyState {}

class FamilyLoaded extends FamilyState {
  final Family family;

  const FamilyLoaded({required this.family});

  @override
  List<Object?> get props => [family];
}

class FamilyCreated extends FamilyState {
  final Family family;

  const FamilyCreated({required this.family});

  @override
  List<Object?> get props => [family];
}

class LinkingCodeGenerated extends FamilyState {
  final String linkingCode;

  const LinkingCodeGenerated({required this.linkingCode});

  @override
  List<Object?> get props => [linkingCode];
}

class ChildAccountCreated extends FamilyState {
  final User child;
  final String linkingCode;

  const ChildAccountCreated({
    required this.child,
    required this.linkingCode,
  });

  @override
  List<Object?> get props => [child, linkingCode];
}

class ChildLinkedToFamily extends FamilyState {
  final Family family;

  const ChildLinkedToFamily({required this.family});

  @override
  List<Object?> get props => [family];
}

class FamilyError extends FamilyState {
  final String message;

  const FamilyError({required this.message});

  @override
  List<Object?> get props => [message];
}
