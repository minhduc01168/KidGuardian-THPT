import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/usecases/auth/link_child_usecase.dart';
import 'package:kidguardian/domain/repositories/auth_repository.dart';
import 'package:kidguardian/domain/repositories/family_repository.dart';
import 'package:kidguardian/domain/entities/family.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockFamilyRepository extends Mock implements FamilyRepository {}

void main() {
  late LinkChildUseCase useCase;
  late MockAuthRepository mockAuthRepository;
  late MockFamilyRepository mockFamilyRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockFamilyRepository = MockFamilyRepository();
    useCase = LinkChildUseCase(mockAuthRepository, mockFamilyRepository);
  });

  final tFamily = Family(
    familyId: 'f1',
    parentUid: 'p1',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  group('LinkChildUseCase', () {
    test('should link child to family when valid code is provided', () async {
      when(() => mockFamilyRepository.getFamilyByLinkingCode('ABC123'))
          .thenAnswer((_) async => tFamily);
      when(() => mockAuthRepository.linkChildToFamily('c1', 'f1'))
          .thenAnswer((_) async {});

      await useCase.execute(linkingCode: 'ABC123', childUid: 'c1');

      verify(() => mockFamilyRepository.getFamilyByLinkingCode('ABC123'))
          .called(1);
      verify(() => mockAuthRepository.linkChildToFamily('c1', 'f1')).called(1);
    });

    test('should throw when linkingCode is empty', () async {
      expect(
        () => useCase.execute(linkingCode: '', childUid: 'c1'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Vui lòng nhập mã liên kết'),
        )),
      );
      verifyNever(() => mockFamilyRepository.getFamilyByLinkingCode(any()));
      verifyNever(() => mockAuthRepository.linkChildToFamily(any(), any()));
    });

    test('should throw when childUid is empty', () async {
      expect(
        () => useCase.execute(linkingCode: 'ABC123', childUid: ''),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('User ID không hợp lệ'),
        )),
      );
      verifyNever(() => mockFamilyRepository.getFamilyByLinkingCode(any()));
      verifyNever(() => mockAuthRepository.linkChildToFamily(any(), any()));
    });

    test('should throw when linkingCode is invalid (family not found)', () async {
      when(() => mockFamilyRepository.getFamilyByLinkingCode('INVALID'))
          .thenAnswer((_) async => null);

      expect(
        () => useCase.execute(linkingCode: 'INVALID', childUid: 'c1'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Mã liên kết không hợp lệ'),
        )),
      );
      verifyNever(() => mockAuthRepository.linkChildToFamily(any(), any()));
    });

    test('should propagate repository exception on link failure', () async {
      when(() => mockFamilyRepository.getFamilyByLinkingCode('ABC123'))
          .thenAnswer((_) async => tFamily);
      when(() => mockAuthRepository.linkChildToFamily('c1', 'f1'))
          .thenThrow(Exception('Liên kết thất bại'));

      expect(
        () => useCase.execute(linkingCode: 'ABC123', childUid: 'c1'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Liên kết thất bại'),
        )),
      );
    });
  });
}
