import '../../../domain/entities/user.dart';
import '../../../domain/repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  Future<User> execute({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      throw Exception('Vui lòng điền đầy đủ thông tin');
    }
    if (!_isValidEmail(email)) {
      throw Exception('Email không hợp lệ');
    }
    if (password.length < 6) {
      throw Exception('Mật khẩu phải có ít nhất 6 ký tự');
    }
    if (name.length < 2) {
      throw Exception('Tên phải có ít nhất 2 ký tự');
    }
    return await _repository.register(email, password, name, role);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
