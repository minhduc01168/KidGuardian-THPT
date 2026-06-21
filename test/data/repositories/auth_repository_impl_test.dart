import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidguardian/data/repositories/auth_repository_impl.dart';
import 'package:kidguardian/domain/entities/user.dart' as domain;

class MockFirebaseAuth extends Mock implements firebase.FirebaseAuth {}
class MockUserCredential extends Mock implements firebase.UserCredential {}
class MockFirebaseUser extends Mock implements firebase.User {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late AuthRepositoryImpl repository;
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockUsersCollection;
  late MockDocumentReference mockUserDoc;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockUsersCollection = MockCollectionReference();
    mockUserDoc = MockDocumentReference();

    when(() => mockFirestore.collection('users')).thenReturn(mockUsersCollection);
    when(() => mockUsersCollection.doc(any())).thenReturn(mockUserDoc);

    repository = AuthRepositoryImpl(
      firebaseAuth: mockAuth,
      firestore: mockFirestore,
    );
  });

  group('AuthRepositoryImpl', () {
    group('getCurrentUser', () {
      test('should return null when no user is signed in', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        final result = await repository.getCurrentUser();

        expect(result, isNull);
      });

      test('should return user when user is signed in and exists in Firestore', () async {
        final mockFirebaseUser = MockFirebaseUser();
        when(() => mockAuth.currentUser).thenReturn(mockFirebaseUser);
        when(() => mockFirebaseUser.uid).thenReturn('uid-123');

        final mockSnapshot = MockDocumentSnapshot();
        when(() => mockUserDoc.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.exists).thenReturn(true);
        when(() => mockSnapshot.data()).thenReturn({
          'uid': 'uid-123',
          'email': 'test@test.com',
          'displayName': 'Test User',
          'role': 'parent',
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        });
        when(() => mockSnapshot.id).thenReturn('uid-123');

        final result = await repository.getCurrentUser();

        expect(result, isNotNull);
        expect(result!.uid, 'uid-123');
        expect(result.email, 'test@test.com');
      });

      test('should return null when user exists in Auth but not in Firestore', () async {
        final mockFirebaseUser = MockFirebaseUser();
        when(() => mockAuth.currentUser).thenReturn(mockFirebaseUser);
        when(() => mockFirebaseUser.uid).thenReturn('uid-123');

        final mockSnapshot = MockDocumentSnapshot();
        when(() => mockUserDoc.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.exists).thenReturn(false);

        final result = await repository.getCurrentUser();

        expect(result, isNull);
      });
    });

    group('login', () {
      test('should return user on successful login', () async {
        final mockCredential = MockUserCredential();
        final mockFirebaseUser = MockFirebaseUser();

        when(() => mockAuth.signInWithEmailAndPassword(
              email: 'test@test.com',
              password: 'password123',
            )).thenAnswer((_) async => mockCredential);
        when(() => mockCredential.user).thenReturn(mockFirebaseUser);
        when(() => mockFirebaseUser.uid).thenReturn('uid-123');
        when(() => mockFirebaseUser.email).thenReturn('test@test.com');
        when(() => mockFirebaseUser.displayName).thenReturn('Test User');

        final mockSnapshot = MockDocumentSnapshot();
        when(() => mockUserDoc.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.exists).thenReturn(true);
        when(() => mockSnapshot.data()).thenReturn({
          'uid': 'uid-123',
          'email': 'test@test.com',
          'displayName': 'Test User',
          'role': 'parent',
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        });
        when(() => mockSnapshot.id).thenReturn('uid-123');

        final result = await repository.login('test@test.com', 'password123');

        expect(result, isNotNull);
        expect(result.uid, 'uid-123');
      });

      test('should create Firestore document when user not in Firestore', () async {
        final mockCredential = MockUserCredential();
        final mockFirebaseUser = MockFirebaseUser();

        when(() => mockAuth.signInWithEmailAndPassword(
              email: 'test@test.com',
              password: 'password123',
            )).thenAnswer((_) async => mockCredential);
        when(() => mockCredential.user).thenReturn(mockFirebaseUser);
        when(() => mockFirebaseUser.uid).thenReturn('uid-123');
        when(() => mockFirebaseUser.email).thenReturn('test@test.com');
        when(() => mockFirebaseUser.displayName).thenReturn('Test User');

        final mockSnapshot = MockDocumentSnapshot();
        when(() => mockUserDoc.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.exists).thenReturn(false);
        when(() => mockUserDoc.set(any())).thenAnswer((_) async {});

        final result = await repository.login('test@test.com', 'password123');

        expect(result, isNotNull);
        expect(result.uid, 'uid-123');
        verify(() => mockUserDoc.set(any())).called(1);
      });

      test('should throw when credential user is null', () async {
        final mockCredential = MockUserCredential();

        when(() => mockAuth.signInWithEmailAndPassword(
              email: 'test@test.com',
              password: 'password123',
            )).thenAnswer((_) async => mockCredential);
        when(() => mockCredential.user).thenReturn(null);

        expect(
          () => repository.login('test@test.com', 'password123'),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw Vietnamese message on user-not-found', () async {
        when(() => mockAuth.signInWithEmailAndPassword(
              email: 'test@test.com',
              password: 'password123',
            )).thenThrow(firebase.FirebaseAuthException(
          code: 'user-not-found',
          message: 'User not found',
        ));

        expect(
          () => repository.login('test@test.com', 'password123'),
          throwsA(predicate((e) =>
              e is Exception && e.toString().contains('Thông tin đăng nhập không chính xác'))),
        );
      });

      test('should throw Vietnamese message on wrong-password', () async {
        when(() => mockAuth.signInWithEmailAndPassword(
              email: 'test@test.com',
              password: 'wrong',
            )).thenThrow(firebase.FirebaseAuthException(
          code: 'wrong-password',
          message: 'Wrong password',
        ));

        expect(
          () => repository.login('test@test.com', 'wrong'),
          throwsA(predicate((e) =>
              e is Exception && e.toString().contains('Sai mật khẩu'))),
        );
      });

      test('should throw Vietnamese message on invalid-email', () async {
        when(() => mockAuth.signInWithEmailAndPassword(
              email: 'invalid',
              password: 'password',
            )).thenThrow(firebase.FirebaseAuthException(
          code: 'invalid-email',
          message: 'Invalid email',
        ));

        expect(
          () => repository.login('invalid', 'password'),
          throwsA(predicate((e) =>
              e is Exception && e.toString().contains('Định dạng Email không hợp lệ'))),
        );
      });
    });

    group('register', () {
      test('should return user on successful registration', () async {
        final mockCredential = MockUserCredential();
        final mockFirebaseUser = MockFirebaseUser();

        when(() => mockAuth.createUserWithEmailAndPassword(
              email: 'new@test.com',
              password: 'password123',
            )).thenAnswer((_) async => mockCredential);
        when(() => mockCredential.user).thenReturn(mockFirebaseUser);
        when(() => mockFirebaseUser.uid).thenReturn('new-uid');
        when(() => mockFirebaseUser.updateDisplayName('New User'))
            .thenAnswer((_) async {});
        when(() => mockUserDoc.set(any())).thenAnswer((_) async {});

        final result = await repository.register(
          'new@test.com',
          'password123',
          'New User',
          domain.UserRole.parent,
        );

        expect(result, isNotNull);
        expect(result.uid, 'new-uid');
        expect(result.email, 'new@test.com');
        expect(result.displayName, 'New User');
        expect(result.role, domain.UserRole.parent);
      });

      test('should throw Vietnamese message on email-already-in-use', () async {
        when(() => mockAuth.createUserWithEmailAndPassword(
              email: 'existing@test.com',
              password: 'password',
            )).thenThrow(firebase.FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'Email already in use',
        ));

        expect(
          () => repository.register('existing@test.com', 'password', 'Name', domain.UserRole.parent),
          throwsA(predicate((e) =>
              e is Exception && e.toString().contains('Email này đã được đăng ký'))),
        );
      });

      test('should throw Vietnamese message on weak-password', () async {
        when(() => mockAuth.createUserWithEmailAndPassword(
              email: 'test@test.com',
              password: '123',
            )).thenThrow(firebase.FirebaseAuthException(
          code: 'weak-password',
          message: 'Weak password',
        ));

        expect(
          () => repository.register('test@test.com', '123', 'Name', domain.UserRole.parent),
          throwsA(predicate((e) =>
              e is Exception && e.toString().contains('Mật khẩu quá yếu (cần tối thiểu 6 ký tự)'))),
        );
      });

      test('should throw when credential user is null', () async {
        final mockCredential = MockUserCredential();

        when(() => mockAuth.createUserWithEmailAndPassword(
              email: 'test@test.com',
              password: 'password123',
            )).thenAnswer((_) async => mockCredential);
        when(() => mockCredential.user).thenReturn(null);

        expect(
          () => repository.register('test@test.com', 'password123', 'Name', domain.UserRole.parent),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('logout', () {
      test('should call signOut on FirebaseAuth', () async {
        SharedPreferences.setMockInitialValues({});
        when(() => mockAuth.signOut()).thenAnswer((_) async {});

        await repository.logout();

        verify(() => mockAuth.signOut()).called(1);
      });
    });

    group('resetPassword', () {
      test('should call sendPasswordResetEmail', () async {
        when(() => mockAuth.sendPasswordResetEmail(email: 'test@test.com'))
            .thenAnswer((_) async {});

        await repository.resetPassword('test@test.com');

        verify(() => mockAuth.sendPasswordResetEmail(email: 'test@test.com')).called(1);
      });

      test('should throw Vietnamese message on error', () async {
        when(() => mockAuth.sendPasswordResetEmail(email: 'invalid'))
            .thenThrow(firebase.FirebaseAuthException(
          code: 'user-not-found',
          message: 'User not found',
        ));

        expect(
          () => repository.resetPassword('invalid'),
          throwsA(predicate((e) =>
              e is Exception && e.toString().contains('Thông tin đăng nhập không chính xác'))),
        );
      });
    });

    group('updateProfile', () {
      test('should update display name in Firestore', () async {
        final mockFirebaseUser = MockFirebaseUser();
        when(() => mockAuth.currentUser).thenReturn(mockFirebaseUser);
        when(() => mockFirebaseUser.updateDisplayName('New Name'))
            .thenAnswer((_) async {});
        when(() => mockUserDoc.update(any())).thenAnswer((_) async {});

        await repository.updateProfile('uid-123', displayName: 'New Name');

        verify(() => mockUserDoc.update({'displayName': 'New Name'})).called(1);
      });

      test('should not update when no displayName provided', () async {
        await repository.updateProfile('uid-123');

        verifyNever(() => mockUserDoc.update(any()));
      });
    });

    group('linkChildToFamily', () {
      test('should update child document with familyId', () async {
        when(() => mockUserDoc.update(any())).thenAnswer((_) async {});

        await repository.linkChildToFamily('child-uid', 'family-id');

        verify(() => mockUserDoc.update({
          'familyId': 'family-id',
          'linkedTo': 'family-id',
        })).called(1);
      });
    });
  });
}
