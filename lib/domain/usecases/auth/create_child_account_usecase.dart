import '../../../domain/entities/user.dart';
import '../../../domain/repositories/auth_repository.dart';

class CreateChildAccountUseCase {
  final AuthRepository _repository;

  CreateChildAccountUseCase(this._repository);

  Future<User> execute({
    required String name,
    required int age,
    required String familyId,
  }) async {
    if (name.isEmpty) {
      throw Exception('Tên không được để trống');
    }
    if (name.length < 2) {
      throw Exception('Tên phải có ít nhất 2 ký tự');
    }
    if (age < 3 || age > 18) {
      throw Exception('Tuổi phải từ 3 đến 18');
    }
    if (familyId.isEmpty) {
      throw Exception('Family ID không hợp lệ');
    }
    return await _repository.createChildAccount(name, age, familyId);
  }
}
