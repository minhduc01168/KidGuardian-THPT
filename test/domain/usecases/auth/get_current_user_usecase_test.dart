import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:kidguardian/domain/repositories/auth_repository.dart';
import 'package:kidguardian/domain/entities/user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late GetCurrentUserUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = GetCurrentUserUseCase(mockRepository);
  });

  final tUser = User(
    uid: 'u1',
    email: 'test@example.com',
    displayName: 'Test User',
    role: UserRole.parent,
    familyId: 'f1',
    createdAt: DateTime(2024, 1, 1),
  );

  group('GetCurrentUserUseCase', () {
    test('should return current user when logged in', () async {
      when(() => mockRepository.getCurrentUser())
          .thenAnswer((_) async => tUser);

      final result = await useCase.execute();

      expect(result, tUser);
      verify(() => mockRepository.getCurrentUser()).called(1);
    });

    test('should return null when no user is logged in', () async {
      when(() => mockRepository.getCurrentUser())
          .thenAnswer((_) async => null);

      final result = await useCase.execute();

      expect(result, isNull);
      verify(() => mockRepository.getCurrentUser()).called(1);
    });

    test('should propagate repository exception on failure', () async {
      when(() => mockRepository.getCurrentUser())
          .thenThrow(Exception('Lỗi xác thực'));

      expect(
        () => useCase.execute(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Lỗi xác thực'),
        )),
      );
    });

    test('should expose authStateChanges stream from repository', () {
      final stream = Stream<User?>.fromIterable([tUser, null]);
      when(() => mockRepository.authStateChanges).thenAnswer((_) => stream);

      final result = useCase.authStateChanges;

      expect(result, emitsInOrder([tUser, null]));
    });
  });
}
