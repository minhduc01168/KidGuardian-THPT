import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/usecases/auth/login_usecase.dart';
import 'package:kidguardian/domain/repositories/auth_repository.dart';
import 'package:kidguardian/domain/entities/user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUseCase(mockRepository);
  });

  final tUser = User(
    uid: 'u1',
    email: 'test@example.com',
    displayName: 'Test User',
    role: UserRole.parent,
    createdAt: DateTime(2024, 1, 1),
  );

  group('LoginUseCase', () {
    test('should return User when login succeeds', () async {
      when(() => mockRepository.login('test@example.com', 'password123'))
          .thenAnswer((_) async => tUser);

      final result = await useCase.execute('test@example.com', 'password123');

      expect(result, tUser);
      verify(() => mockRepository.login('test@example.com', 'password123'))
          .called(1);
    });

    test('should throw when email is empty', () async {
      expect(
        () => useCase.execute('', 'password123'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Email và mật khẩu không được để trống'),
        )),
      );
    });

    test('should throw when password is empty', () async {
      expect(
        () => useCase.execute('test@example.com', ''),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Email và mật khẩu không được để trống'),
        )),
      );
    });

    test('should throw when both email and password are empty', () async {
      expect(
        () => useCase.execute('', ''),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Email và mật khẩu không được để trống'),
        )),
      );
    });

    test('should throw when email format is invalid', () async {
      expect(
        () => useCase.execute('invalid-email', 'password123'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Email không hợp lệ'),
        )),
      );
    });

    test('should throw when email has no domain', () async {
      expect(
        () => useCase.execute('test@', 'password123'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Email không hợp lệ'),
        )),
      );
    });

    test('should propagate repository exception on login failure', () async {
      when(() => mockRepository.login('test@example.com', 'wrong'))
          .thenThrow(Exception('Sai email hoặc mật khẩu'));

      expect(
        () => useCase.execute('test@example.com', 'wrong'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Sai email hoặc mật khẩu'),
        )),
      );
    });
  });
}
