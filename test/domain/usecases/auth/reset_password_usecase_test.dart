import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/usecases/auth/reset_password_usecase.dart';
import 'package:kidguardian/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late ResetPasswordUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = ResetPasswordUseCase(mockRepository);
  });

  group('ResetPasswordUseCase', () {
    test('should call repository resetPassword with valid email', () async {
      when(() => mockRepository.resetPassword('test@example.com'))
          .thenAnswer((_) async {});

      await useCase.execute('test@example.com');

      verify(() => mockRepository.resetPassword('test@example.com')).called(1);
    });

    test('should throw when email is empty', () async {
      expect(
        () => useCase.execute(''),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Vui lòng nhập email'),
        )),
      );
    });

    test('should throw when email format is invalid', () async {
      expect(
        () => useCase.execute('invalid-email'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Email không hợp lệ'),
        )),
      );
    });

    test('should throw when email has no @ symbol', () async {
      expect(
        () => useCase.execute('testexample.com'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Email không hợp lệ'),
        )),
      );
    });

    test('should propagate repository exception on reset failure', () async {
      when(() => mockRepository.resetPassword('notfound@example.com'))
          .thenThrow(Exception('Email không tồn tại'));

      expect(
        () => useCase.execute('notfound@example.com'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Email không tồn tại'),
        )),
      );
    });
  });
}
