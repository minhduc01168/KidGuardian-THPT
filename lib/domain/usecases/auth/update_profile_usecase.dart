import '../../../domain/repositories/auth_repository.dart';

class UpdateProfileUseCase {
  final AuthRepository _repository;

  UpdateProfileUseCase(this._repository);

  Future<void> execute({
    required String uid,
    String? displayName,
  }) async {
    if (uid.isEmpty) {
      throw Exception('User ID không hợp lệ');
    }
    if (displayName != null && displayName.length < 2) {
      throw Exception('Tên phải có ít nhất 2 ký tự');
    }
    await _repository.updateProfile(uid, displayName: displayName);
  }
}
