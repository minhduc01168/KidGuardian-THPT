import 'package:equatable/equatable.dart';
import '../../../../domain/entities/user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  
  const LoginRequested({required this.email, required this.password});
  
  @override
  List<Object?> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final UserRole role;
  
  const RegisterRequested({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
  });
  
  @override
  List<Object?> get props => [email, password, name, role];
}

class LogoutRequested extends AuthEvent {}

class ResetPasswordRequested extends AuthEvent {
  final String email;
  
  const ResetPasswordRequested({required this.email});
  
  @override
  List<Object?> get props => [email];
}

class AuthStateChanged extends AuthEvent {
  final User? user;
  
  const AuthStateChanged({this.user});
  
  @override
  List<Object?> get props => [user];
}

class LinkChildToFamily extends AuthEvent {
  final String linkingCode;
  final String childUid;
  
  const LinkChildToFamily({
    required this.linkingCode,
    required this.childUid,
  });
  
  @override
  List<Object?> get props => [linkingCode, childUid];
}

class UpdateProfileRequested extends AuthEvent {
  final String uid;
  final String? displayName;
  
  const UpdateProfileRequested({
    required this.uid,
    this.displayName,
  });
  
  @override
  List<Object?> get props => [uid, displayName];
}
