import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.uid,
    required super.email,
    required super.displayName,
    required super.role,
    super.familyId,
    super.linkedTo,
    required super.createdAt,
  });
  
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: data['role'] == 'parent' ? UserRole.parent : UserRole.child,
      familyId: data['familyId'],
      linkedTo: data['linkedTo'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    String? familyId,
    String? linkedTo,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      familyId: familyId ?? this.familyId,
      linkedTo: linkedTo ?? this.linkedTo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role == UserRole.parent ? 'parent' : 'child',
      'familyId': familyId,
      'linkedTo': linkedTo,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
