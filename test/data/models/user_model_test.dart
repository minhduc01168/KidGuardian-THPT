import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kidguardian/data/models/user_model.dart';
import 'package:kidguardian/domain/entities/user.dart';

void main() {
  group('UserModel', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    final tCreatedAt = DateTime(2026, 3, 15);
    final tModel = UserModel(
      uid: 'user1',
      email: 'parent@example.com',
      displayName: 'Parent User',
      role: UserRole.parent,
      familyId: 'family1',
      linkedTo: 'child1',
      createdAt: tCreatedAt,
    );

    test('should be a subclass of User entity', () {
      expect(tModel, isA<User>());
    });

    group('constructor', () {
      test('should create parent user with optional fields', () {
        final model = UserModel(
          uid: 'u1',
          email: 'p@test.com',
          displayName: 'Parent',
          role: UserRole.parent,
          createdAt: tCreatedAt,
        );

        expect(model.role, UserRole.parent);
        expect(model.familyId, isNull);
        expect(model.linkedTo, isNull);
      });

      test('should create child user with optional fields', () {
        final model = UserModel(
          uid: 'u2',
          email: 'c@test.com',
          displayName: 'Child',
          role: UserRole.child,
          familyId: 'f1',
          linkedTo: 'parent1',
          createdAt: tCreatedAt,
        );

        expect(model.role, UserRole.child);
        expect(model.familyId, 'f1');
        expect(model.linkedTo, 'parent1');
      });
    });

    group('fromFirestore', () {
      test('should return valid parent model from Firestore document', () async {
        await fakeFirestore.collection('users').doc('user1').set({
          'uid': 'user1',
          'email': 'parent@example.com',
          'displayName': 'Parent User',
          'role': 'parent',
          'familyId': 'family1',
          'linkedTo': 'child1',
          'createdAt': Timestamp.fromDate(tCreatedAt),
        });

        final doc =
            await fakeFirestore.collection('users').doc('user1').get();
        final result = UserModel.fromFirestore(doc);

        expect(result.uid, 'user1');
        expect(result.email, 'parent@example.com');
        expect(result.displayName, 'Parent User');
        expect(result.role, UserRole.parent);
        expect(result.familyId, 'family1');
        expect(result.linkedTo, 'child1');
        expect(result.createdAt, tCreatedAt);
      });

      test('should return child role when role is not parent', () async {
        await fakeFirestore.collection('users').doc('user2').set({
          'uid': 'user2',
          'email': 'child@example.com',
          'displayName': 'Child User',
          'role': 'child',
          'familyId': 'family1',
          'linkedTo': 'parent1',
          'createdAt': Timestamp.fromDate(tCreatedAt),
        });

        final doc =
            await fakeFirestore.collection('users').doc('user2').get();
        final result = UserModel.fromFirestore(doc);

        expect(result.role, UserRole.child);
      });

      test('should default to child role for unknown role string', () async {
        await fakeFirestore.collection('users').doc('user3').set({
          'role': 'admin',
        });

        final doc =
            await fakeFirestore.collection('users').doc('user3').get();
        final result = UserModel.fromFirestore(doc);

        expect(result.role, UserRole.child);
      });

      test('should use defaults when fields are missing', () async {
        await fakeFirestore.collection('users').doc('user4').set({});

        final doc =
            await fakeFirestore.collection('users').doc('user4').get();
        final result = UserModel.fromFirestore(doc);

        expect(result.uid, '');
        expect(result.email, '');
        expect(result.displayName, '');
        expect(result.role, UserRole.child);
        expect(result.familyId, isNull);
        expect(result.linkedTo, isNull);
      });

      test('should fallback to DateTime.now when createdAt is null', () async {
        await fakeFirestore.collection('users').doc('user5').set({
          'createdAt': null,
        });

        final before = DateTime.now();
        final doc =
            await fakeFirestore.collection('users').doc('user5').get();
        final result = UserModel.fromFirestore(doc);
        final after = DateTime.now();

        expect(
          result.createdAt.isAfter(before) ||
              result.createdAt.isAtSameMomentAs(before),
          true,
        );
        expect(
          result.createdAt.isBefore(after) ||
              result.createdAt.isAtSameMomentAs(after),
          true,
        );
      });
    });

    group('toMap', () {
      test('should return a valid map for parent user', () {
        final result = tModel.toMap();

        expect(result['uid'], 'user1');
        expect(result['email'], 'parent@example.com');
        expect(result['displayName'], 'Parent User');
        expect(result['role'], 'parent');
        expect(result['familyId'], 'family1');
        expect(result['linkedTo'], 'child1');
        expect(result['createdAt'], isA<FieldValue>());
      });

      test('should return child role string for child user', () {
        final model = UserModel(
          uid: 'u2',
          email: 'c@test.com',
          displayName: 'Child',
          role: UserRole.child,
          createdAt: tCreatedAt,
        );

        final result = model.toMap();
        expect(result['role'], 'child');
      });

      test('should handle null optional fields', () {
        final model = UserModel(
          uid: 'u1',
          email: 'p@test.com',
          displayName: 'Parent',
          role: UserRole.parent,
          createdAt: tCreatedAt,
        );

        final result = model.toMap();
        expect(result['familyId'], isNull);
        expect(result['linkedTo'], isNull);
      });
    });

    group('Equatable', () {
      test('should be equal when all fields match', () {
        final model1 = UserModel(
          uid: 'u1',
          email: 'e@test.com',
          displayName: 'Name',
          role: UserRole.parent,
          familyId: 'f1',
          linkedTo: 'l1',
          createdAt: tCreatedAt,
        );
        final model2 = UserModel(
          uid: 'u1',
          email: 'e@test.com',
          displayName: 'Name',
          role: UserRole.parent,
          familyId: 'f1',
          linkedTo: 'l1',
          createdAt: tCreatedAt,
        );

        expect(model1, model2);
      });

      test('should not be equal when fields differ', () {
        final model1 = UserModel(
          uid: 'u1',
          email: 'e@test.com',
          displayName: 'Name',
          role: UserRole.parent,
          createdAt: tCreatedAt,
        );
        final model2 = UserModel(
          uid: 'u2',
          email: 'e@test.com',
          displayName: 'Name',
          role: UserRole.parent,
          createdAt: tCreatedAt,
        );

        expect(model1, isNot(model2));
      });
    });
  });
}
