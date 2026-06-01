import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/usecases/auth/logout_usecase.dart';
import 'package:kidguardian/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LogoutUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LogoutUseCase(mockRepository);
  });

  group('LogoutUseCase', () {
    test('should call repository logout', () async {
      when(() => mockRepository.logout()).thenAnswer((_) async {});

      await useCase.execute();

      verify(() => mockRepository.logout()).called(1);
    });

    test('should propagate repository exception on logout failure', () async {
      when(() => mockRepository.logout())
          .thenThrow(Exception('Đăng xuất thất bại'));

      expect(
        () => useCase.execute(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Đăng xuất thất bại'),
        )),
      );
    });
  });
}
