import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/family_repository.dart';

class LinkChildUseCase {
  final AuthRepository _authRepository;
  final FamilyRepository _familyRepository;

  LinkChildUseCase(this._authRepository, this._familyRepository);

  Future<void> execute({
    required String linkingCode,
    required String childUid,
  }) async {
    if (linkingCode.isEmpty) {
      throw Exception('Vui lòng nhập mã liên kết');
    }
    if (childUid.isEmpty) {
      throw Exception('User ID không hợp lệ');
    }

    final family = await _familyRepository.getFamilyByLinkingCode(linkingCode);
    if (family == null) {
      throw Exception('Mã liên kết không hợp lệ');
    }

    await _authRepository.linkChildToFamily(childUid, family.familyId);
  }
}
