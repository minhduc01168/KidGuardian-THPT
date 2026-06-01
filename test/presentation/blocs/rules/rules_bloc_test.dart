import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/data/models/auto_approval_rule_model.dart';
import 'package:kidguardian/domain/repositories/rules_repository.dart';
import 'package:kidguardian/presentation/blocs/rules/rules_bloc.dart';

class MockRulesRepository extends Mock implements RulesRepository {}

class FakeAutoApprovalRule extends Fake implements AutoApprovalRule {}

void main() {
  late MockRulesRepository mockRulesRepository;

  setUpAll(() {
    registerFallbackValue(FakeAutoApprovalRule());
  });

  setUp(() {
    mockRulesRepository = MockRulesRepository();
  });

  group('RulesBloc', () {
    test('initial state is RulesInitial when rules exist', () async {
      final rule = AutoApprovalRule(
        id: 'test-id',
        familyId: 'test-family-id',
        maxAutoApproveMinutes: 30,
        dailyAutoApproveLimit: 3,
        isEnabled: true,
      );

      when(() => mockRulesRepository.watchRules('test-family-id'))
          .thenAnswer((_) => Stream.value(rule));

      final rulesBloc = RulesBloc(
        repository: mockRulesRepository,
        familyId: 'test-family-id',
      );

      await Future.delayed(Duration.zero);
      expect(rulesBloc.state, isA<RulesLoaded>());
      rulesBloc.close();
    });

    test('loads rules successfully', () async {
      final rule = AutoApprovalRule(
        id: 'test-id',
        familyId: 'test-family-id',
        maxAutoApproveMinutes: 30,
        dailyAutoApproveLimit: 3,
        isEnabled: true,
      );

      when(() => mockRulesRepository.watchRules('test-family-id'))
          .thenAnswer((_) => Stream.value(rule));

      final rulesBloc = RulesBloc(
        repository: mockRulesRepository,
        familyId: 'test-family-id',
      );

      await expectLater(
        rulesBloc.stream,
        emitsInOrder([
          isA<RulesLoading>(),
          isA<RulesLoaded>(),
        ]),
      );

      rulesBloc.close();
    });

    test('updates max minutes', () async {
      final rule = AutoApprovalRule(
        id: 'test-id',
        familyId: 'test-family-id',
        maxAutoApproveMinutes: 30,
        dailyAutoApproveLimit: 3,
        isEnabled: true,
      );

      when(() => mockRulesRepository.watchRules('test-family-id'))
          .thenAnswer((_) => Stream.value(rule));

      final rulesBloc = RulesBloc(
        repository: mockRulesRepository,
        familyId: 'test-family-id',
      );

      await Future.delayed(Duration.zero);
      rulesBloc.add(UpdateMaxMinutes(45));

      await expectLater(
        rulesBloc.stream,
        emits(isA<RulesLoaded>()),
      );

      final state = rulesBloc.state as RulesLoaded;
      expect(state.rule.maxAutoApproveMinutes, 45);
      rulesBloc.close();
    });

    test('updates daily limit', () async {
      final rule = AutoApprovalRule(
        id: 'test-id',
        familyId: 'test-family-id',
        maxAutoApproveMinutes: 30,
        dailyAutoApproveLimit: 3,
        isEnabled: true,
      );

      when(() => mockRulesRepository.watchRules('test-family-id'))
          .thenAnswer((_) => Stream.value(rule));

      final rulesBloc = RulesBloc(
        repository: mockRulesRepository,
        familyId: 'test-family-id',
      );

      await Future.delayed(Duration.zero);
      rulesBloc.add(UpdateDailyLimit(5));

      await expectLater(
        rulesBloc.stream,
        emits(isA<RulesLoaded>()),
      );

      final state = rulesBloc.state as RulesLoaded;
      expect(state.rule.dailyAutoApproveLimit, 5);
      rulesBloc.close();
    });

    test('toggles rules enabled', () async {
      final rule = AutoApprovalRule(
        id: 'test-id',
        familyId: 'test-family-id',
        maxAutoApproveMinutes: 30,
        dailyAutoApproveLimit: 3,
        isEnabled: false,
      );

      when(() => mockRulesRepository.watchRules('test-family-id'))
          .thenAnswer((_) => Stream.value(rule));

      final rulesBloc = RulesBloc(
        repository: mockRulesRepository,
        familyId: 'test-family-id',
      );

      await Future.delayed(Duration.zero);
      rulesBloc.add(ToggleRulesEnabled(true));

      await expectLater(
        rulesBloc.stream,
        emits(isA<RulesLoaded>()),
      );

      final state = rulesBloc.state as RulesLoaded;
      expect(state.rule.isEnabled, true);
      rulesBloc.close();
    });

    test('saves rules successfully', () async {
      final rule = AutoApprovalRule(
        id: 'test-id',
        familyId: 'test-family-id',
        maxAutoApproveMinutes: 30,
        dailyAutoApproveLimit: 3,
        isEnabled: true,
      );

      when(() => mockRulesRepository.watchRules('test-family-id'))
          .thenAnswer((_) => Stream.value(rule));
      when(() => mockRulesRepository.saveRules(any()))
          .thenAnswer((_) => Future.value());

      final rulesBloc = RulesBloc(
        repository: mockRulesRepository,
        familyId: 'test-family-id',
      );

      await Future.delayed(Duration.zero);
      rulesBloc.add(SaveRules());

      await expectLater(
        rulesBloc.stream,
        emitsInOrder([
          isA<RulesSaving>(),
          isA<RulesSaved>(),
        ]),
      );

      rulesBloc.close();
    });
  });
}
