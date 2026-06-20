import '../entities/family.dart';
import '../entities/user.dart';

abstract class FamilyRepository {
  Future<Family> createFamily(String parentUid);
  Future<Family?> getFamily(String familyId);
  Future<Family?> getFamilyByParent(String parentUid);
  Future<String> generateLinkingCode(String familyId);
  Future<Family> addChildToFamily(String familyId, String childUid);
  Future<Family?> getFamilyByLinkingCode(String linkingCode);
  Future<void> removeChildFromFamily(String familyId, String childUid);
  Future<List<User>> getChildrenByFamily(String familyId);
}
