import '../../domain/entities/user.dart';

abstract class AuthRepository {
  Future<User?> getCurrentUser();
  Future<User> login(String email, String password);
  Future<User> register(String email, String password, String name, UserRole role);
  Future<User> createChildAccount(String name, int age, String familyId);
  Future<void> linkChildToFamily(String childUid, String familyId);
  Future<void> logout();
  Future<void> resetPassword(String email);
  Future<void> updateProfile(String uid, {String? displayName});
  Stream<User?> get authStateChanges;
}
