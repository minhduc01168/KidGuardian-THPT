import 'package:equatable/equatable.dart';

enum UserRole { parent, child }

class User extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String? familyId;
  final String? linkedTo;
  final DateTime createdAt;
  
  const User({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.familyId,
    this.linkedTo,
    required this.createdAt,
  });
  
  @override
  List<Object?> get props => [uid, email, displayName, role, familyId, linkedTo, createdAt];
}
