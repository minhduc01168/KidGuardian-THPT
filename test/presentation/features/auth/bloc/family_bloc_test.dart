import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/entities/family.dart';
import 'package:kidguardian/domain/entities/user.dart';
import 'package:kidguardian/domain/repositories/auth_repository.dart';
import 'package:kidguardian/domain/repositories/family_repository.dart';
import 'package:kidguardian/presentation/features/auth/bloc/family_bloc.dart';
import 'package:kidguardian/presentation/features/auth/bloc/family_event.dart';
import 'package:kidguardian/presentation/features/auth/bloc/family_state.dart';

class MockFamilyRepository extends Mock implements FamilyRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeFamily extends Fake implements Family {}

class FakeUser extends Fake implements User {}

void main() {
  late FamilyBloc bloc;
  late MockFamilyRepository mockFamilyRepository;
  late MockAuthRepository mockAuthRepository;

  final testFamily = Family(
    familyId: 'family1',
    parentUid: 'parent1',
    childUids: const ['child1'],
    linkingCode: 'ABC123',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  final testChild = User(
    uid: 'child1',
    email: 'child@example.com',
    displayName: 'Child',
    role: UserRole.child,
    familyId: 'family1',
    linkedTo: 'parent1',
    createdAt: DateTime(2024, 1, 1),
  );

  final testChildNoFamily = User(
    uid: 'child1',
    email: 'child@example.com',
    displayName: 'Child',
    role: UserRole.child,
    createdAt: DateTime(2024, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(FakeFamily());
    registerFallbackValue(FakeUser());
  });

  setUp(() {
    mockFamilyRepository = MockFamilyRepository();
    mockAuthRepository = MockAuthRepository();
  });

  tearDown(() async {
    await bloc.close();
  });

  FamilyBloc createBloc() {
    return FamilyBloc(
      familyRepository: mockFamilyRepository,
      authRepository: mockAuthRepository,
    );
  }

  group('FamilyBloc', () {
    test('initial state is FamilyInitial', () {
      bloc = createBloc();
      expect(bloc.state, isA<FamilyInitial>());
    });

    group('CreateFamilyRequested', () {
      blocTest<FamilyBloc, FamilyState>(
        'emits [FamilyLoading, FamilyCreated] when create succeeds',
        build: () {
          when(() => mockFamilyRepository.createFamily('parent1'))
              .thenAnswer((_) async => testFamily);
          return createBloc();
        },
        act: (bloc) => bloc.add(const CreateFamilyRequested(parentUid: 'parent1')),
        expect: () => [
          isA<FamilyLoading>(),
          isA<FamilyCreated>().having(
            (s) => s.family,
            'family',
            testFamily,
          ),
        ],
      );

      blocTest<FamilyBloc, FamilyState>(
        'emits [FamilyLoading, FamilyError] when create fails',
        build: () {
          when(() => mockFamilyRepository.createFamily(any()))
              .thenThrow(Exception('Creation failed'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const CreateFamilyRequested(parentUid: 'parent1')),
        expect: () => [
          isA<FamilyLoading>(),
          isA<FamilyError>().having(
            (s) => s.message,
            'message',
            'Creation failed',
          ),
        ],
      );
    });

    group('LoadFamilyRequested', () {
      blocTest<FamilyBloc, FamilyState>(
        'emits [FamilyLoading, FamilyLoaded] when family exists',
        build: () {
          when(() => mockFamilyRepository.getFamilyByParent('parent1'))
              .thenAnswer((_) async => testFamily);
          return createBloc();
        },
        act: (bloc) => bloc.add(const LoadFamilyRequested(parentUid: 'parent1')),
        expect: () => [
          isA<FamilyLoading>(),
          isA<FamilyLoaded>().having(
            (s) => s.family,
            'family',
            testFamily,
          ),
        ],
      );

      blocTest<FamilyBloc, FamilyState>(
        'emits [FamilyLoading, FamilyError] when family does not exist',
        build: () {
          when(() => mockFamilyRepository.getFamilyByParent('parent1'))
              .thenAnswer((_) async => null);
          return createBloc();
        },
        act: (bloc) => bloc.add(const LoadFamilyRequested(parentUid: 'parent1')),
        expect: () => [
          isA<FamilyLoading>(),
          isA<FamilyError>().having(
            (s) => s.message,
            'message',
            'Chưa tạo gia đình',
          ),
        ],
      );

      blocTest<FamilyBloc, FamilyState>(
        'emits [FamilyLoading, FamilyError] when repository throws',
        build: () {
          when(() => mockFamilyRepository.getFamilyByParent(any()))
              .thenThrow(Exception('Network error'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const LoadFamilyRequested(parentUid: 'parent1')),
        expect: () => [
          isA<FamilyLoading>(),
          isA<FamilyError>().having(
            (s) => s.message,
            'message',
            'Network error',
          ),
        ],
      );
    });

    group('GenerateLinkingCodeRequested', () {
      blocTest<FamilyBloc, FamilyState>(
        'emits [FamilyLoading, LinkingCodeGenerated] when generation succeeds',
        build: () {
          when(() => mockFamilyRepository.generateLinkingCode('family1'))
              .thenAnswer((_) async => 'XYZ789');
          return createBloc();
        },
        act: (bloc) =>
            bloc.add(const GenerateLinkingCodeRequested(familyId: 'family1')),
        expect: () => [
          isA<FamilyLoading>(),
          isA<LinkingCodeGenerated>().having(
            (s) => s.linkingCode,
            'linkingCode',
            'XYZ789',
          ),
        ],
      );

      blocTest<FamilyBloc, FamilyState>(
        'emits [FamilyLoading, FamilyError] when generation fails',
        build: () {
          when(() => mockFamilyRepository.generateLinkingCode(any()))
              .thenThrow(Exception('Generation failed'));
          return createBloc();
        },
        act: (bloc) =>
            bloc.add(const GenerateLinkingCodeRequested(familyId: 'family1')),
        expect: () => [
          isA<FamilyLoading>(),
          isA<FamilyError>().having(
            (s) => s.message,
            'message',
            'Generation failed',
          ),
        ],
      );
    });

    group('CreateChildAccountRequested', () {
      blocTest<FamilyBloc, FamilyState>(
        'emits [FamilyLoading, ChildAccountCreated] when creation succeeds',
        build: () {
          when(() => mockAuthRepository.createChildAccount('Child', 10, 'family1'))
              .thenAnswer((_) async => testChild);
          when(() => mockFamilyRepository.addChildToFamily('family1', 'child1'))
              .thenAnswer((_) async => testFamily);
          when(() => mockFamilyRepository.getFamily('family1'))
              .thenAnswer((_) async => testFamily);
          return createBloc();
        },
        act: (bloc) => bloc.add(const CreateChildAccountRequested(
          name: 'Child',
          age: 10,
          familyId: 'family1',
        )),
        expect: () => [
          isA<FamilyLoading>(),
          isA<ChildAccountCreated>()
              .having((s) => s.child, 'child', testChild)
              .having((s) => s.linkingCode, 'linkingCode', 'ABC123'),
        ],
      );

      blocTest<FamilyBloc, FamilyState>(
        'emits [FamilyLoading, ChildAccountCreated] with empty linkingCode when family has no code',
        build: () {
          final familyNoCode = Family(
            familyId: 'family1',
            parentUid: 'parent1',
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          );
          when(() => mockAuthRepository.createChildAccount('Child', 10, 'family1'))
              .thenAnswer((_) async => testChild);
          when(() => mockFamilyRepository.addChildToFamily('family1', 'child1'))
              .thenAnswer((_) async => familyNoCode);
          when(() => mockFamilyRepository.getFamily('family1'))
              .thenAnswer((_) async => familyNoCode);
          return createBloc();
        },
        act: (bloc) => bloc.add(const CreateChildAccountRequested(
          name: 'Child',
          age: 10,
          familyId: 'family1',
        )),
        expect: () => [
          isA<FamilyLoading>(),
          isA<ChildAccountCreated>()
              .having((s) => s.child, 'child', testChild)
              .having((s) => s.linkingCode, 'linkingCode', ''),
        ],
      );

      blocTest<FamilyBloc, FamilyState>(
        'emits [FamilyLoading, ChildAccountCreated] with empty linkingCode when getFamily returns null',
        build: () {
          when(() => mockAuthRepository.createChildAccount('Child', 10, 'family1'))
              .thenAnswer((_) async => testChild);
          when(() => mockFamilyRepository.addChildToFamily('family1', 'child1'))
              .thenAnswer((_) async => testFamily);
          when(() => mockFamilyRepository.getFamily('family1'))
              .thenAnswer((_) async => null);
          return createBloc();
        },
        act: (bloc) => bloc.add(const CreateChildAccountRequested(
          name: 'Child',
          age: 10,
          familyId: 'family1',
        )),
        expect: () => [
          isA<FamilyLoading>(),
          isA<ChildAccountCreated>()
              .having((s) => s.child, 'child', testChild)
              .having((s) => s.linkingCode, 'linkingCode', ''),
        ],
      );

      blocTest<FamilyBloc, FamilyState>(
        'emits [FamilyLoading, FamilyError] when createChildAccount fails',
        build: () {
          when(() => mockAuthRepository.createChildAccount(any(), any(), any()))
              .thenThrow(Exception('Account creation failed'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const CreateChildAccountRequested(
          name: 'Child',
          age: 10,
          familyId: 'family1',
        )),
        expect: () => [
          isA<FamilyLoading>(),
          isA<FamilyError>().having(
            (s) => s.message,
            'message',
            'Account creation failed',
          ),
        ],
      );

      blocTest<FamilyBloc, FamilyState>(
        'emits [FamilyLoading, FamilyError] when addChildToFamily fails',
        build: () {
          when(() => mockAuthRepository.createChildAccount('Child', 10, 'family1'))
              .thenAnswer((_) async => testChild);
          when(() => mockFamilyRepository.addChildToFamily('family1', 'child1'))
              .thenThrow(Exception('Add child failed'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const CreateChildAccountRequested(
          name: 'Child',
          age: 10,
          familyId: 'family1',
        )),
        expect: () => [
          isA<FamilyLoading>(),
          isA<FamilyError>().having(
            (s) => s.message,
            'message',
            'Add child failed',
          ),
        ],
      );
    });

    group('LinkChildToFamilyRequested', () {
      blocTest<FamilyBloc, FamilyState>(
        'emits [FamilyLoading, ChildLinkedToFamily] when linking succeeds',
        build: () {
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => testChildNoFamily);
          when(() => mockFamilyRepository.getFamilyByLinkingCode('ABC123'))
              .thenAnswer((_) async => testFamily);
          when(() => mockFamilyRepository.addChildToFamily('family1', 'child1'))
              .thenAnswer((_) async => testFamily);
          when(() => mockAuthRepository.linkChildToFamily('child1', 'family1'))
              .thenAnswer((_) async {});
          when(() => mockFamilyRepository.getFamily('family1'))
              .thenAnswer((_) async => testFamily);
          return createBloc();
        },
        act: (bloc) => bloc.add(const LinkChildToFamilyRequested(
          linkingCode: 'ABC123',
          childUid: 'child1',
        )),
        expect: () => [
          isA<FamilyLoading>(),
          isA<ChildLinkedToFamily>().having(
            (s) => s.family,
            'family',
            testFamily,
          ),
        ],
      );

      blocTest<FamilyBloc, FamilyState>(
        'emits [FamilyLoading, FamilyError] when child already has family',
        build: () {
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => testChild);
          return createBloc();
        },
        act: (bloc) => bloc.add(const LinkChildToFamilyRequested(
          linkingCode: 'ABC123',
          childUid: 'child1',
        )),
        expect: () => [
          isA<FamilyLoading>(),
          isA<FamilyError>().having(
            (s) => s.message,
            'message',
            'Tài khoản đã được liên kết với gia đình khác',
          ),
        ],
      );

      blocTest<FamilyBloc, FamilyState>(
        'emits [FamilyLoading, FamilyError] when linking code is invalid',
        build: () {
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => testChildNoFamily);
          when(() => mockFamilyRepository.getFamilyByLinkingCode('INVALID'))
              .thenAnswer((_) async => null);
          return createBloc();
        },
        act: (bloc) => bloc.add(const LinkChildToFamilyRequested(
          linkingCode: 'INVALID',
          childUid: 'child1',
        )),
        expect: () => [
          isA<FamilyLoading>(),
          isA<FamilyError>().having(
            (s) => s.message,
            'message',
            'Mã liên kết không hợp lệ',
          ),
        ],
      );

      blocTest<FamilyBloc, FamilyState>(
        'emits [FamilyLoading, FamilyError] when getFamily returns null after linking',
        build: () {
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => testChildNoFamily);
          when(() => mockFamilyRepository.getFamilyByLinkingCode('ABC123'))
              .thenAnswer((_) async => testFamily);
          when(() => mockFamilyRepository.addChildToFamily('family1', 'child1'))
              .thenAnswer((_) async => testFamily);
          when(() => mockAuthRepository.linkChildToFamily('child1', 'family1'))
              .thenAnswer((_) async {});
          when(() => mockFamilyRepository.getFamily('family1'))
              .thenAnswer((_) async => null);
          return createBloc();
        },
        act: (bloc) => bloc.add(const LinkChildToFamilyRequested(
          linkingCode: 'ABC123',
          childUid: 'child1',
        )),
        expect: () => [
          isA<FamilyLoading>(),
          isA<FamilyError>().having(
            (s) => s.message,
            'message',
            'Không thể liên kết tài khoản',
          ),
        ],
      );

      blocTest<FamilyBloc, FamilyState>(
        'emits [FamilyLoading, FamilyError] when getCurrentUser returns null',
        build: () {
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => null);
          when(() => mockFamilyRepository.getFamilyByLinkingCode('ABC123'))
              .thenAnswer((_) async => testFamily);
          when(() => mockFamilyRepository.addChildToFamily('family1', 'child1'))
              .thenAnswer((_) async => testFamily);
          when(() => mockAuthRepository.linkChildToFamily('child1', 'family1'))
              .thenAnswer((_) async {});
          when(() => mockFamilyRepository.getFamily('family1'))
              .thenAnswer((_) async => testFamily);
          return createBloc();
        },
        act: (bloc) => bloc.add(const LinkChildToFamilyRequested(
          linkingCode: 'ABC123',
          childUid: 'child1',
        )),
        expect: () => [
          isA<FamilyLoading>(),
          isA<ChildLinkedToFamily>().having(
            (s) => s.family,
            'family',
            testFamily,
          ),
        ],
      );

      blocTest<FamilyBloc, FamilyState>(
        'emits [FamilyLoading, FamilyError] when repository throws',
        build: () {
          when(() => mockAuthRepository.getCurrentUser())
              .thenThrow(Exception('Database error'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const LinkChildToFamilyRequested(
          linkingCode: 'ABC123',
          childUid: 'child1',
        )),
        expect: () => [
          isA<FamilyLoading>(),
          isA<FamilyError>().having(
            (s) => s.message,
            'message',
            'Database error',
          ),
        ],
      );
    });

    group('RemoveChildFromFamilyRequested', () {
      blocTest<FamilyBloc, FamilyState>(
        'emits [FamilyLoading, ChildRemovedFromFamily] when removal succeeds',
        build: () {
          when(() => mockFamilyRepository.removeChildFromFamily('family1', 'child1'))
              .thenAnswer((_) async {});
          when(() => mockFamilyRepository.getFamily('family1'))
              .thenAnswer((_) async => testFamily);
          return createBloc();
        },
        act: (bloc) => bloc.add(const RemoveChildFromFamilyRequested(
          familyId: 'family1',
          childUid: 'child1',
        )),
        expect: () => [
          isA<FamilyLoading>(),
          isA<ChildRemovedFromFamily>().having(
            (s) => s.family,
            'family',
            testFamily,
          ),
        ],
      );

      blocTest<FamilyBloc, FamilyState>(
        'emits [FamilyLoading, FamilyError] when getFamily returns null after removal',
        build: () {
          when(() => mockFamilyRepository.removeChildFromFamily('family1', 'child1'))
              .thenAnswer((_) async {});
          when(() => mockFamilyRepository.getFamily('family1'))
              .thenAnswer((_) async => null);
          return createBloc();
        },
        act: (bloc) => bloc.add(const RemoveChildFromFamilyRequested(
          familyId: 'family1',
          childUid: 'child1',
        )),
        expect: () => [
          isA<FamilyLoading>(),
          isA<FamilyError>().having(
            (s) => s.message,
            'message',
            'Không thể cập nhật gia đình',
          ),
        ],
      );

      blocTest<FamilyBloc, FamilyState>(
        'emits [FamilyLoading, FamilyError] when removal fails',
        build: () {
          when(() => mockFamilyRepository.removeChildFromFamily(any(), any()))
              .thenThrow(Exception('Removal failed'));
          return createBloc();
        },
        act: (bloc) => bloc.add(const RemoveChildFromFamilyRequested(
          familyId: 'family1',
          childUid: 'child1',
        )),
        expect: () => [
          isA<FamilyLoading>(),
          isA<FamilyError>().having(
            (s) => s.message,
            'message',
            'Removal failed',
          ),
        ],
      );
    });
  });
}
