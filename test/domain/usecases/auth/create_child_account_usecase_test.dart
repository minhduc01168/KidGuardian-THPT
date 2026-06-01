import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/usecases/auth/create_child_account_usecase.dart';
import 'package:kidguardian/domain/repositories/auth_repository.dart';
import 'package:kidguardian/domain/entities/user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late CreateChildAccountUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = CreateChildAccountUseCase(mockRepository);
  });

  final tChildUser = User(
    uid: 'c1',
    email: '',
    displayName: 'Child',
    role: UserRole.child,
    familyId: 'f1',
    createdAt: DateTime(2024, 1, 1),
  );

  group('CreateChildAccountUseCase', () {
    test('should return User when child account creation succeeds', () async {
      when(() => mockRepository.createChildAccount('Child', 10, 'f1'))
          .thenAnswer((_) async => tChildUser);

      final result = await useCase.execute(
        name: 'Child',
        age: 10,
        familyId: 'f1',
      );

      expect(result, tChildUser);
      verify(() => mockRepository.createChildAccount('Child', 10, 'f1'))
          .called(1);
    });

    test('should throw when name is empty', () async {
      expect(
        () => useCase.execute(name: '', age: 10, familyId: 'f1'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Tên không được để trống'),
        )),
      );
      verifyNever(() => mockRepository.createChildAccount(any(), any(), any()));
    });

    test('should throw when name is shorter than 2 characters', () async {
      expect(
        () => useCase.execute(name: 'A', age: 10, familyId: 'f1'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Tên phải có ít nhất 2 ký tự'),
        )),
      );
      verifyNever(() => mockRepository.createChildAccount(any(), any(), any()));
    });

    test('should throw when age is below 3', () async {
      expect(
        () => useCase.execute(name: 'Child', age: 2, familyId: 'f1'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Tuổi phải từ 3 đến 18'),
        )),
      );
      verifyNever(() => mockRepository.createChildAccount(any(), any(), any()));
    });

    test('should throw when age is above 18', () async {
      expect(
        () => useCase.execute(name: 'Child', age: 19, familyId: 'f1'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Tuổi phải từ 3 đến 18'),
        )),
      );
      verifyNever(() => mockRepository.createChildAccount(any(), any(), any()));
    });

    test('should throw when familyId is empty', () async {
      expect(
        () => useCase.execute(name: 'Child', age: 10, familyId: ''),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Family ID không hợp lệ'),
        )),
      );
      verifyNever(() => mockRepository.createChildAccount(any(), any(), any()));
    });

    test('should accept age at lower boundary (3)', () async {
      final youngChild = User(
        uid: 'c2',
        email: '',
        displayName: 'Young',
        role: UserRole.child,
        familyId: 'f1',
        createdAt: DateTime(2024, 1, 1),
      );
      when(() => mockRepository.createChildAccount('Young', 3, 'f1'))
          .thenAnswer((_) async => youngChild);

      final result = await useCase.execute(
        name: 'Young',
        age: 3,
        familyId: 'f1',
      );

      expect(result, youngChild);
    });

    test('should accept age at upper boundary (18)', () async {
      final olderChild = User(
        uid: 'c3',
        email: '',
        displayName: 'Older',
        role: UserRole.child,
        familyId: 'f1',
        createdAt: DateTime(2024, 1, 1),
      );
      when(() => mockRepository.createChildAccount('Older', 18, 'f1'))
          .thenAnswer((_) async => olderChild);

      final result = await useCase.execute(
        name: 'Older',
        age: 18,
        familyId: 'f1',
      );

      expect(result, olderChild);
    });

    test('should propagate repository exception on creation failure', () async {
      when(() => mockRepository.createChildAccount('Child', 10, 'f1'))
          .thenThrow(Exception('Tạo tài khoản thất bại'));

      expect(
        () => useCase.execute(name: 'Child', age: 10, familyId: 'f1'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Tạo tài khoản thất bại'),
        )),
      );
    });
  });
}
