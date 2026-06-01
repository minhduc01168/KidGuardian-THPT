import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:kidguardian/data/repositories/family_repository_impl.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FamilyRepositoryImpl repository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = FamilyRepositoryImpl(firestore: fakeFirestore);
  });

  /// Helper to pre-create a user document so update() works on fake_cloud_firestore
  Future<void> createUser(String uid, {String? familyId}) async {
    final data = <String, dynamic>{
      'uid': uid,
      'email': '$uid@test.com',
    };
    if (familyId != null) data['familyId'] = familyId;
    await fakeFirestore.collection('users').doc(uid).set(data);
  }

  group('FamilyRepositoryImpl', () {
    group('createFamily', () {
      test('should create a family document in Firestore', () async {
        await createUser('parent-uid-1');

        final family = await repository.createFamily('parent-uid-1');

        expect(family.parentUid, 'parent-uid-1');
        expect(family.childUids, isEmpty);
        expect(family.familyId, isNotEmpty);
        expect(family.linkingCode, isNotEmpty);
      });

      test('should update parent user document with familyId', () async {
        await createUser('parent-uid-1');

        final family = await repository.createFamily('parent-uid-1');

        final userDoc = await fakeFirestore.collection('users').doc('parent-uid-1').get();
        expect(userDoc.data()!['familyId'], family.familyId);
      });

      test('should generate a 6-character linking code', () async {
        await createUser('parent-uid-1');

        final family = await repository.createFamily('parent-uid-1');

        expect(family.linkingCode!.length, 6);
      });
    });

    group('getFamily', () {
      test('should return family when it exists', () async {
        await createUser('parent-uid-1');
        final created = await repository.createFamily('parent-uid-1');

        final result = await repository.getFamily(created.familyId);

        expect(result, isNotNull);
        expect(result!.parentUid, 'parent-uid-1');
      });

      test('should return null when family does not exist', () async {
        final result = await repository.getFamily('non-existent-id');

        expect(result, isNull);
      });
    });

    group('getFamilyByParent', () {
      test('should return family by parent uid', () async {
        await createUser('parent-uid-1');
        await repository.createFamily('parent-uid-1');

        final result = await repository.getFamilyByParent('parent-uid-1');

        expect(result, isNotNull);
        expect(result!.parentUid, 'parent-uid-1');
      });

      test('should return null when no family exists for parent', () async {
        final result = await repository.getFamilyByParent('non-existent-parent');

        expect(result, isNull);
      });
    });

    group('addChildToFamily', () {
      test('should add child to family childUids', () async {
        await createUser('parent-uid-1');
        await createUser('child-uid-1');
        final family = await repository.createFamily('parent-uid-1');

        final updated = await repository.addChildToFamily(family.familyId, 'child-uid-1');

        expect(updated.childUids, contains('child-uid-1'));
      });

      test('should update child user document with familyId', () async {
        await createUser('parent-uid-1');
        await createUser('child-uid-1');
        final family = await repository.createFamily('parent-uid-1');

        await repository.addChildToFamily(family.familyId, 'child-uid-1');

        final userDoc = await fakeFirestore.collection('users').doc('child-uid-1').get();
        expect(userDoc.data()!['familyId'], family.familyId);
      });

      test('should add multiple children', () async {
        await createUser('parent-uid-1');
        await createUser('child-uid-1');
        await createUser('child-uid-2');
        final family = await repository.createFamily('parent-uid-1');

        await repository.addChildToFamily(family.familyId, 'child-uid-1');
        final updated = await repository.addChildToFamily(family.familyId, 'child-uid-2');

        expect(updated.childUids.length, 2);
        expect(updated.childUids, containsAll(['child-uid-1', 'child-uid-2']));
      });
    });

    group('removeChildFromFamily', () {
      test('should remove child from family childUids', () async {
        await createUser('parent-uid-1');
        await createUser('child-uid-1');
        final family = await repository.createFamily('parent-uid-1');
        await repository.addChildToFamily(family.familyId, 'child-uid-1');

        await repository.removeChildFromFamily(family.familyId, 'child-uid-1');

        final updatedFamily = await repository.getFamily(family.familyId);
        expect(updatedFamily!.childUids, isNot(contains('child-uid-1')));
      });

      test('should remove familyId from child user document', () async {
        await createUser('parent-uid-1');
        await createUser('child-uid-1', familyId: 'fam-1');
        final family = await repository.createFamily('parent-uid-1');

        await repository.removeChildFromFamily(family.familyId, 'child-uid-1');

        final userDoc = await fakeFirestore.collection('users').doc('child-uid-1').get();
        expect(userDoc.data()!.containsKey('familyId'), isFalse);
      });
    });

    group('getFamilyByLinkingCode', () {
      test('should return family by linking code', () async {
        await createUser('parent-uid-1');
        final family = await repository.createFamily('parent-uid-1');

        final result = await repository.getFamilyByLinkingCode(family.linkingCode!);

        expect(result, isNotNull);
        expect(result!.familyId, family.familyId);
      });

      test('should return null for non-existent linking code', () async {
        final result = await repository.getFamilyByLinkingCode('INVALID');

        expect(result, isNull);
      });
    });

    group('generateLinkingCode', () {
      test('should generate a new linking code for the family', () async {
        await createUser('parent-uid-1');
        final family = await repository.createFamily('parent-uid-1');

        final newCode = await repository.generateLinkingCode(family.familyId);

        expect(newCode, isNotEmpty);
        expect(newCode.length, 6);
      });

      test('should update the family document with new linking code', () async {
        await createUser('parent-uid-1');
        final family = await repository.createFamily('parent-uid-1');

        final newCode = await repository.generateLinkingCode(family.familyId);

        final updatedFamily = await repository.getFamily(family.familyId);
        expect(updatedFamily!.linkingCode, newCode);
      });
    });
  });
}
