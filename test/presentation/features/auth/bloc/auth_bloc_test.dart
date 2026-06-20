import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/data/services/notification_service.dart';
import 'package:kidguardian/domain/entities/family.dart';
import 'package:kidguardian/domain/entities/user.dart';
import 'package:kidguardian/domain/repositories/auth_repository.dart';
import 'package:kidguardian/domain/repositories/family_repository.dart';
import 'package:kidguardian/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:kidguardian/presentation/features/auth/bloc/auth_event.dart';
import 'package:kidguardian/presentation/features/auth/bloc/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockFamilyRepository extends Mock implements FamilyRepository {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockFamilyRepository mockFamilyRepository;
  late MockNotificationService mockNotificationService;
  late StreamController<User?> authStateController;

  final testUser = User(
    uid: 'uid123',
    email: 'test@example.com',
    displayName: 'Test User',
    role: UserRole.parent,
    familyId: 'family1',
    createdAt: DateTime(2024, 1, 1),
  );

  final testChild = User(
    uid: 'child123',
    email: 'child@example.com',
    displayName: 'Child User',
    role: UserRole.child,
    familyId: 'family1',
    linkedTo: 'uid123',
    createdAt: DateTime(2024, 1, 1),
  );

  final testFamily = Family(
    familyId: 'family1',
    parentUid: 'uid123',
    childUids: const ['child123'],
    linkingCode: 'ABC123',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(UserRole.parent);
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockFamilyRepository = MockFamilyRepository();
    mockNotificationService = MockNotificationService();
    authStateController = StreamController<User?>();

    when(() => mockAuthRepository.authStateChanges)
        .thenAnswer((_) => authStateController.stream);
    when(() => mockNotificationService.registerToken(any()))
        .thenAnswer((_) async {});
  });

  tearDown(() async {
    await authStateController.close();
  });

  AuthBloc createBloc() {
    return AuthBloc(
      authRepository: mockAuthRepository,
      familyRepository: mockFamilyRepository,
      notificationService: mockNotificationService,
    );
  }

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      final bloc = createBloc();
      expect(bloc.state, isA<AuthInitial>());
      bloc.close();
    });

    group('LoginRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when login succeeds and auto-creates family if parent and familyId is null',
        build: () {
          final parentNoFamily = User(
            uid: 'uid123',
            email: 'test@example.com',
            displayName: 'Test User',
            role: UserRole.parent,
            familyId: null,
            createdAt: DateTime(2024, 1, 1),
          );
          
          when(() => mockAuthRepository.login('test@example.com', 'password123'))
              .thenAnswer((_) async => parentNoFamily);
              
          when(() => mockFamilyRepository.createFamily('uid123'))
              .thenAnswer((_) async => testFamily);
              
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => testUser); // returns user with familyId now
              
          return createBloc();
        },
        act: (bloc) => bloc.add(const LoginRequested(
          email: 'test@example.com',
          password: 'password123',
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthAuthenticated>().having(
            (s) => s.user,
            'user',
            testUser,
          ),
        ],
        verify: (_) {
          verify(() => mockFamilyRepository.createFamily('uid123')).called(1);
          verify(() => mockAuthRepository.getCurrentUser()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when login succeeds for child (no auto-create family)',
        build: () {
          when(() => mockAuthRepository.login('test@example.com', 'password123'))
              .thenAnswer((_) async => testChild);
          return createBloc();
        },
        act: (bloc) => bloc.add(const LoginRequested(
          email: 'test@example.com',
          password: 'password123',
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthAuthenticated>().having(
            (s) => s.user,
            'user',
            testChild,
          ),
        ],
        verify: (_) {
          verifyNever(() => mockFamilyRepository.createFamily(any()));
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when login fails',
        build: () {
          when(() => mockAuthRepository.login('test@example.com', 'wrong'))
              .thenThrow(Exception('Invalid credentials'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const LoginRequested(
          email: 'test@example.com',
          password: 'wrong',
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having(
            (s) => s.message,
            'message',
            'Invalid credentials',
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] on network error',
        build: () {
          when(() => mockAuthRepository.login(any(), any()))
              .thenThrow(Exception('Network error'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const LoginRequested(
          email: 'test@example.com',
          password: 'password123',
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having(
            (s) => s.message,
            'message',
            'Network error',
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'calls registerToken on successful login',
        build: () {
          when(() => mockAuthRepository.login(any(), any()))
              .thenAnswer((_) async => testUser);
          return createBloc();
        },
        act: (bloc) => bloc.add(const LoginRequested(
          email: 'test@example.com',
          password: 'password123',
        )),
        verify: (_) {
          verify(() => mockNotificationService.registerToken('uid123')).called(1);
        },
      );
    });

    group('RegisterRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthRegistrationSuccess] when registration succeeds and calls logout',
        build: () {
          when(() => mockAuthRepository.register(
                'new@example.com',
                'password123',
                'New User',
                UserRole.parent,
              )).thenAnswer((_) async => testUser);
          when(() => mockAuthRepository.logout()).thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(const RegisterRequested(
          email: 'new@example.com',
          password: 'password123',
          name: 'New User',
          role: UserRole.parent,
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthRegistrationSuccess>(),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.logout()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when registration fails',
        build: () {
          when(() => mockAuthRepository.register(
                'existing@example.com',
                'password123',
                'User',
                UserRole.parent,
              )).thenThrow(Exception('Email already in use'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const RegisterRequested(
          email: 'existing@example.com',
          password: 'password123',
          name: 'User',
          role: UserRole.parent,
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having(
            (s) => s.message,
            'message',
            'Email already in use',
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'registers with child role correctly and emits AuthRegistrationSuccess',
        build: () {
          when(() => mockAuthRepository.register(
                'child@example.com',
                'password123',
                'Child',
                UserRole.child,
              )).thenAnswer((_) async => testChild);
          when(() => mockAuthRepository.logout()).thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(const RegisterRequested(
          email: 'child@example.com',
          password: 'password123',
          name: 'Child',
          role: UserRole.child,
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthRegistrationSuccess>(),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.logout()).called(1);
        },
      );
    });

    group('LogoutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthUnauthenticated] when logout succeeds',
        build: () {
          when(() => mockAuthRepository.logout()).thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(LogoutRequested()),
        expect: () => [isA<AuthUnauthenticated>()],
      );
    });

    group('ResetPasswordRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthPasswordResetSent] when reset succeeds',
        build: () {
          when(() => mockAuthRepository.resetPassword('test@example.com'))
              .thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) => bloc.add(const ResetPasswordRequested(
          email: 'test@example.com',
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthPasswordResetSent>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when reset fails',
        build: () {
          when(() => mockAuthRepository.resetPassword('unknown@example.com'))
              .thenThrow(Exception('User not found'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const ResetPasswordRequested(
          email: 'unknown@example.com',
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having(
            (s) => s.message,
            'message',
            'User not found',
          ),
        ],
      );
    });

    group('AuthStateChanged', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthAuthenticated] when user is not null',
        build: () => createBloc(),
        act: (bloc) => bloc.add(AuthStateChanged(user: testUser)),
        expect: () => [
          isA<AuthAuthenticated>().having(
            (s) => s.user,
            'user',
            testUser,
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthUnauthenticated] when user is null',
        build: () => createBloc(),
        act: (bloc) => bloc.add(const AuthStateChanged(user: null)),
        expect: () => [isA<AuthUnauthenticated>()],
      );
      
      blocTest<AuthBloc, AuthState>(
        'ignores AuthStateChanged when registering',
        build: () {
          when(() => mockAuthRepository.register(
                'new@example.com',
                'password123',
                'New User',
                UserRole.parent,
              )).thenAnswer((_) async => testUser);
          when(() => mockAuthRepository.logout()).thenAnswer((_) async {});
          return createBloc();
        },
        act: (bloc) async {
          // This will set _isRegistering to true, then await login
          bloc.add(const RegisterRequested(
            email: 'new@example.com',
            password: 'password123',
            name: 'New User',
            role: UserRole.parent,
          ));
          
          // Before registration completes, simulate the race condition
          bloc.add(AuthStateChanged(user: testUser));
        },
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthRegistrationSuccess>(), // Notice AuthAuthenticated is NOT emitted
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'registers notification token when user is not null',
        build: () => createBloc(),
        act: (bloc) => bloc.add(AuthStateChanged(user: testUser)),
        verify: (_) {
          verify(() => mockNotificationService.registerToken('uid123')).called(1);
        },
      );
    });

    group('LinkChildToFamily', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when linking succeeds',
        build: () {
          when(() => mockFamilyRepository.getFamilyByLinkingCode('ABC123'))
              .thenAnswer((_) async => testFamily);
          when(() => mockAuthRepository.linkChildToFamily('child123', 'family1'))
              .thenAnswer((_) async {});
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => testChild);
          return createBloc();
        },
        act: (bloc) => bloc.add(const LinkChildToFamily(
          linkingCode: 'ABC123',
          childUid: 'child123',
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthAuthenticated>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when linking code is invalid',
        build: () {
          when(() => mockFamilyRepository.getFamilyByLinkingCode('INVALID'))
              .thenAnswer((_) async => null);
          return createBloc();
        },
        act: (bloc) => bloc.add(const LinkChildToFamily(
          linkingCode: 'INVALID',
          childUid: 'child123',
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having(
            (s) => s.message,
            'message',
            'Mã liên kết không hợp lệ',
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when getCurrentUser returns null after linking',
        build: () {
          when(() => mockFamilyRepository.getFamilyByLinkingCode('ABC123'))
              .thenAnswer((_) async => testFamily);
          when(() => mockAuthRepository.linkChildToFamily('child123', 'family1'))
              .thenAnswer((_) async {});
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => null);
          return createBloc();
        },
        act: (bloc) => bloc.add(const LinkChildToFamily(
          linkingCode: 'ABC123',
          childUid: 'child123',
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having(
            (s) => s.message,
            'message',
            'Không thể liên kết tài khoản',
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when repository throws',
        build: () {
          when(() => mockFamilyRepository.getFamilyByLinkingCode(any()))
              .thenThrow(Exception('Database error'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const LinkChildToFamily(
          linkingCode: 'ABC123',
          childUid: 'child123',
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having(
            (s) => s.message,
            'message',
            'Database error',
          ),
        ],
      );
    });

    group('UpdateProfileRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when update succeeds',
        build: () {
          when(() => mockAuthRepository.updateProfile('uid123',
              displayName: 'New Name')).thenAnswer((_) async {});
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => testUser);
          return createBloc();
        },
        act: (bloc) => bloc.add(const UpdateProfileRequested(
          uid: 'uid123',
          displayName: 'New Name',
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthAuthenticated>().having(
            (s) => s.user,
            'user',
            testUser,
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when getCurrentUser returns null',
        build: () {
          when(() => mockAuthRepository.updateProfile(any(),
              displayName: any(named: 'displayName'))).thenAnswer((_) async {});
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => null);
          return createBloc();
        },
        act: (bloc) => bloc.add(const UpdateProfileRequested(
          uid: 'uid123',
          displayName: 'New Name',
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having(
            (s) => s.message,
            'message',
            'Không thể cập nhật thông tin',
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when update throws',
        build: () {
          when(() => mockAuthRepository.updateProfile(any(),
              displayName: any(named: 'displayName'))).thenThrow(
              Exception('Update failed'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const UpdateProfileRequested(
          uid: 'uid123',
          displayName: 'New Name',
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having(
            (s) => s.message,
            'message',
            'Update failed',
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'works with null displayName',
        build: () {
          when(() => mockAuthRepository.updateProfile('uid123'))
              .thenAnswer((_) async {});
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => testUser);
          return createBloc();
        },
        act: (bloc) => bloc.add(const UpdateProfileRequested(
          uid: 'uid123',
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthAuthenticated>(),
        ],
      );
    });

    group('authStateChanges stream integration', () {
      blocTest<AuthBloc, AuthState>(
        'emits AuthAuthenticated when stream emits a user',
        build: () => createBloc(),
        act: (bloc) => authStateController.add(testUser),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<AuthAuthenticated>().having(
            (s) => s.user,
            'user',
            testUser,
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits AuthUnauthenticated when stream emits null',
        build: () => createBloc(),
        act: (bloc) => authStateController.add(null),
        wait: const Duration(milliseconds: 100),
        expect: () => [isA<AuthUnauthenticated>()],
      );
    });
  });
}
