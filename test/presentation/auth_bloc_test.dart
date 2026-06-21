import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/repositories/auth_repository.dart';
import 'package:kidguardian/domain/repositories/family_repository.dart';
import 'package:kidguardian/data/services/notification_service.dart';
import 'package:kidguardian/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:kidguardian/presentation/features/auth/bloc/auth_event.dart';
import 'package:kidguardian/presentation/features/auth/bloc/auth_state.dart';
import 'package:kidguardian/domain/entities/user.dart';
import 'package:kidguardian/data/models/user_model.dart';
import 'package:kidguardian/data/models/family_model.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockFamilyRepository extends Mock implements FamilyRepository {}
class MockNotificationService extends Mock implements NotificationService {}

void main() {
  setUpAll(() {
    registerFallbackValue(UserRole.parent);
  });

  late MockAuthRepository authRepository;
  late MockFamilyRepository familyRepository;
  late MockNotificationService notificationService;
  late StreamController<User?> authStateController;

  setUp(() {
    authRepository = MockAuthRepository();
    familyRepository = MockFamilyRepository();
    notificationService = MockNotificationService();
    authStateController = StreamController<User?>();

    when(() => authRepository.authStateChanges)
        .thenAnswer((_) => authStateController.stream);
        
    when(() => notificationService.registerToken(any()))
        .thenAnswer((_) async {});
        
    when(() => authRepository.getCurrentUser())
        .thenAnswer((_) async => null);
  });

  tearDown(() {
    authStateController.close();
  });

  group('AuthBloc', () {
    final testUser = UserModel(
      uid: 'uid-123',
      email: 'test@example.com',
      displayName: 'Test User',
      role: UserRole.parent,
      createdAt: DateTime.now(),
      familyId: null, // initially no family
    );

    final testFamily = FamilyModel(
      familyId: 'fam-123',
      parentUid: 'uid-123',
      childUids: [],
      linkingCode: 'CODE123',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] and does NOT call getCurrentUser when parent registers and family is auto-created',
      build: () {
        when(() => authRepository.register(any(), any(), any(), any()))
            .thenAnswer((_) async => testUser);
        when(() => familyRepository.createFamily(any()))
            .thenAnswer((_) async => testFamily);
            
        return AuthBloc(
          authRepository: authRepository,
          familyRepository: familyRepository,
          notificationService: notificationService,
        );
      },
      act: (bloc) => bloc.add(RegisterRequested(
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
        role: UserRole.parent,
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>().having(
          (state) => state.user.familyId,
          'familyId',
          'fam-123',
        ),
      ],
      verify: (_) {
        // verify createFamily was called
        verify(() => familyRepository.createFamily('uid-123')).called(1);
        // verify getCurrentUser was NEVER called because we use copyWith optimization
        verifyNever(() => authRepository.getCurrentUser());
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] and does NOT call getCurrentUser when parent logs in and family is auto-created',
      build: () {
        when(() => authRepository.login(any(), any()))
            .thenAnswer((_) async => testUser);
        when(() => familyRepository.createFamily(any()))
            .thenAnswer((_) async => testFamily);
            
        return AuthBloc(
          authRepository: authRepository,
          familyRepository: familyRepository,
          notificationService: notificationService,
        );
      },
      act: (bloc) => bloc.add(LoginRequested(
        email: 'test@example.com',
        password: 'password123',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>().having(
          (state) => state.user.familyId,
          'familyId',
          'fam-123',
        ),
      ],
      verify: (_) {
        // verify createFamily was called
        verify(() => familyRepository.createFamily('uid-123')).called(1);
        // verify getCurrentUser was NEVER called because we use copyWith optimization
        verifyNever(() => authRepository.getCurrentUser());
      },
    );
  });
}
