import '../../../domain/entities/user.dart';
import '../../../domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  Future<User> execute(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email và mật khẩu không được để trống');
    }
    if (!_isValidEmail(email)) {
      throw Exception('Email không hợp lệ');
    }
    return await _repository.login(email, password);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
