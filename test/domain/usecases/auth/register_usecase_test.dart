import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/usecases/auth/register_usecase.dart';
import 'package:kidguardian/domain/repositories/auth_repository.dart';
import 'package:kidguardian/domain/entities/user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late RegisterUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = RegisterUseCase(mockRepository);
  });

  setUpAll(() {
    registerFallbackValue(UserRole.parent);
  });

  final tUser = User(
    uid: 'u1',
    email: 'new@example.com',
    displayName: 'New User',
    role: UserRole.parent,
    createdAt: DateTime(2024, 1, 1),
  );

  group('RegisterUseCase', () {
    test('should return User when registration succeeds', () async {
      when(() => mockRepository.register(
            'new@example.com',
            'password123',
            'New User',
            UserRole.parent,
          )).thenAnswer((_) async => tUser);

      final result = await useCase.execute(
        email: 'new@example.com',
        password: 'password123',
        name: 'New User',
        role: UserRole.parent,
      );

      expect(result, tUser);
      verify(() => mockRepository.register(
            'new@example.com',
            'password123',
            'New User',
            UserRole.parent,
          )).called(1);
    });

    test('should throw when email is empty', () async {
      expect(
        () => useCase.execute(
          email: '',
          password: 'password123',
          name: 'New User',
          role: UserRole.parent,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Vui lòng điền đầy đủ thông tin'),
        )),
      );
    });

    test('should throw when password is empty', () async {
      expect(
        () => useCase.execute(
          email: 'new@example.com',
          password: '',
          name: 'New User',
          role: UserRole.parent,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Vui lòng điền đầy đủ thông tin'),
        )),
      );
    });

    test('should throw when name is empty', () async {
      expect(
        () => useCase.execute(
          email: 'new@example.com',
          password: 'password123',
          name: '',
          role: UserRole.parent,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Vui lòng điền đầy đủ thông tin'),
        )),
      );
    });

    test('should throw when email format is invalid', () async {
      expect(
        () => useCase.execute(
          email: 'invalid-email',
          password: 'password123',
          name: 'New User',
          role: UserRole.parent,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Email không hợp lệ'),
        )),
      );
    });

    test('should throw when password is shorter than 6 characters', () async {
      expect(
        () => useCase.execute(
          email: 'new@example.com',
          password: '12345',
          name: 'New User',
          role: UserRole.parent,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Mật khẩu phải có ít nhất 6 ký tự'),
        )),
      );
    });

    test('should throw when name is shorter than 2 characters', () async {
      expect(
        () => useCase.execute(
          email: 'new@example.com',
          password: 'password123',
          name: 'A',
          role: UserRole.parent,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Tên phải có ít nhất 2 ký tự'),
        )),
      );
    });

    test('should work with child role', () async {
      final childUser = User(
        uid: 'u2',
        email: 'child@example.com',
        displayName: 'Child',
        role: UserRole.child,
        createdAt: DateTime(2024, 1, 1),
      );
      when(() => mockRepository.register(
            'child@example.com',
            'password123',
            'Child',
            UserRole.child,
          )).thenAnswer((_) async => childUser);

      final result = await useCase.execute(
        email: 'child@example.com',
        password: 'password123',
        name: 'Child',
        role: UserRole.child,
      );

      expect(result, childUser);
      expect(result.role, UserRole.child);
    });

    test('should propagate repository exception on registration failure',
        () async {
      when(() => mockRepository.register(
            any(),
            any(),
            any(),
            any(),
          )).thenThrow(Exception('Email đã được sử dụng'));

      expect(
        () => useCase.execute(
          email: 'existing@example.com',
          password: 'password123',
          name: 'User',
          role: UserRole.parent,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Email đã được sử dụng'),
        )),
      );
    });
  });
}
