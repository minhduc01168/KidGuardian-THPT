import '../../../domain/repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository _repository;

  ResetPasswordUseCase(this._repository);

  Future<void> execute(String email) async {
    if (email.isEmpty) {
      throw Exception('Vui lòng nhập email');
    }
    if (!_isValidEmail(email)) {
      throw Exception('Email không hợp lệ');
    }
    await _repository.resetPassword(email);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
