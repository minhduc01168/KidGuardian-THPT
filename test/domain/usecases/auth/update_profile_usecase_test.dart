import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/usecases/auth/update_profile_usecase.dart';
import 'package:kidguardian/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late UpdateProfileUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = UpdateProfileUseCase(mockRepository);
  });

  group('UpdateProfileUseCase', () {
    test('should call repository updateProfile with uid and displayName',
        () async {
      when(() => mockRepository.updateProfile('u1', displayName: 'New Name'))
          .thenAnswer((_) async {});

      await useCase.execute(uid: 'u1', displayName: 'New Name');

      verify(() => mockRepository.updateProfile('u1', displayName: 'New Name'))
          .called(1);
    });

    test('should call repository updateProfile with uid only', () async {
      when(() => mockRepository.updateProfile('u1'))
          .thenAnswer((_) async {});

      await useCase.execute(uid: 'u1');

      verify(() => mockRepository.updateProfile('u1')).called(1);
    });

    test('should throw when uid is empty', () async {
      expect(
        () => useCase.execute(uid: '', displayName: 'New Name'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('User ID không hợp lệ'),
        )),
      );
    });

    test('should throw when displayName is shorter than 2 characters', () async {
      expect(
        () => useCase.execute(uid: 'u1', displayName: 'A'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Tên phải có ít nhất 2 ký tự'),
        )),
      );
    });

    test('should allow null displayName', () async {
      when(() => mockRepository.updateProfile('u1'))
          .thenAnswer((_) async {});

      await useCase.execute(uid: 'u1', displayName: null);

      verify(() => mockRepository.updateProfile('u1')).called(1);
    });

    test('should propagate repository exception on update failure', () async {
      when(() => mockRepository.updateProfile('u1', displayName: 'New Name'))
          .thenThrow(Exception('Cập nhật thất bại'));

      expect(
        () => useCase.execute(uid: 'u1', displayName: 'New Name'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Cập nhật thất bại'),
        )),
      );
    });
  });
}
