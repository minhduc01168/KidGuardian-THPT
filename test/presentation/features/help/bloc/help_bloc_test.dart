import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/entities/faq_item.dart';
import 'package:kidguardian/domain/repositories/help_repository.dart';
import 'package:kidguardian/presentation/features/help/bloc/help_bloc.dart';
import 'package:kidguardian/presentation/features/help/bloc/help_event.dart';
import 'package:kidguardian/presentation/features/help/bloc/help_state.dart';

class MockHelpRepository extends Mock implements HelpRepository {}

void main() {
  late HelpBloc bloc;
  late MockHelpRepository mockHelpRepository;

  setUp(() {
    mockHelpRepository = MockHelpRepository();
    bloc = HelpBloc(helpRepository: mockHelpRepository);
  });

  tearDown(() {
    bloc.close();
  });

  List<FaqItem> makeFaqItems() => [
        const FaqItem(
          question: 'How to use?',
          answer: 'Just follow the guide.',
          category: 'General',
        ),
        const FaqItem(
          question: 'How to reset?',
          answer: 'Go to settings.',
          category: 'Account',
        ),
        const FaqItem(
          question: 'What is KidGuardian?',
          answer: 'A parental control app.',
          category: 'General',
        ),
      ];

  group('HelpBloc', () {
    test('initial state is HelpInitial', () {
      expect(bloc.state, isA<HelpInitial>());
    });

    group('LoadFaq', () {
      blocTest<HelpBloc, HelpState>(
        'emits [HelpLoading, FaqLoaded] on success',
        build: () {
          when(() => mockHelpRepository.getFaqItems())
              .thenReturn(makeFaqItems());
          return bloc;
        },
        act: (bloc) => bloc.add(LoadFaq()),
        expect: () => [
          isA<HelpLoading>(),
          isA<FaqLoaded>()
              .having((s) => s.faqItems.length, 'faqItems length', 3)
              .having((s) => s.categories, 'categories', containsAll(['General', 'Account'])),
        ],
      );

      blocTest<HelpBloc, HelpState>(
        'emits [HelpLoading, HelpError] on exception',
        build: () {
          when(() => mockHelpRepository.getFaqItems())
              .thenThrow(Exception('Failed to load FAQ'));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadFaq()),
        expect: () => [
          isA<HelpLoading>(),
          isA<HelpError>().having(
            (e) => e.message,
            'message',
            contains('Failed to load FAQ'),
          ),
        ],
      );

      blocTest<HelpBloc, HelpState>(
        'extracts unique categories from FAQ items',
        build: () {
          when(() => mockHelpRepository.getFaqItems()).thenReturn([
            const FaqItem(question: 'Q1', answer: 'A1', category: 'Billing'),
            const FaqItem(question: 'Q2', answer: 'A2', category: 'Technical'),
            const FaqItem(question: 'Q3', answer: 'A3', category: 'Billing'),
          ]);
          return bloc;
        },
        act: (bloc) => bloc.add(LoadFaq()),
        expect: () => [
          isA<HelpLoading>(),
          isA<FaqLoaded>().having(
            (s) => s.categories,
            'categories',
            ['Billing', 'Technical'],
          ),
        ],
      );
    });

    group('SendSupportMessage', () {
      blocTest<HelpBloc, HelpState>(
        'emits [HelpLoading, SupportMessageSent] on success',
        build: () {
          when(() => mockHelpRepository.sendSupportMessage(
                name: any(named: 'name'),
                email: any(named: 'email'),
                subject: any(named: 'subject'),
                message: any(named: 'message'),
              )).thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(SendSupportMessage(
          name: 'Test User',
          email: 'test@example.com',
          subject: 'Help needed',
          message: 'I need help with the app.',
        )),
        expect: () => [
          isA<HelpLoading>(),
          isA<SupportMessageSent>(),
        ],
      );

      blocTest<HelpBloc, HelpState>(
        'emits [HelpLoading, HelpError] when sending fails',
        build: () {
          when(() => mockHelpRepository.sendSupportMessage(
                name: any(named: 'name'),
                email: any(named: 'email'),
                subject: any(named: 'subject'),
                message: any(named: 'message'),
              )).thenThrow(Exception('Network error'));
          return bloc;
        },
        act: (bloc) => bloc.add(SendSupportMessage(
          name: 'Test User',
          email: 'test@example.com',
          subject: 'Help needed',
          message: 'I need help.',
        )),
        expect: () => [
          isA<HelpLoading>(),
          isA<HelpError>().having(
            (e) => e.message,
            'message',
            contains('Network error'),
          ),
        ],
      );
    });

    group('LoadAppInfo', () {
      blocTest<HelpBloc, HelpState>(
        'emits [HelpLoading, HelpError] when PackageInfo fails in test env',
        build: () => bloc,
        act: (bloc) => bloc.add(LoadAppInfo()),
        expect: () => [
          isA<HelpLoading>(),
          isA<HelpError>(),
        ],
      );
    });

    group('ToggleFaqItem', () {
      blocTest<HelpBloc, HelpState>(
        'expands FAQ item when currently collapsed',
        build: () {
          when(() => mockHelpRepository.getFaqItems())
              .thenReturn(makeFaqItems());
          return bloc;
        },
        act: (bloc) async {
          bloc.add(LoadFaq());
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(ToggleFaqItem(index: 0));
        },
        expect: () => [
          isA<HelpLoading>(),
          isA<FaqLoaded>().having((s) => s.expandedIndex, 'expandedIndex', -1),
          isA<FaqLoaded>().having((s) => s.expandedIndex, 'expandedIndex', 0),
        ],
      );

      blocTest<HelpBloc, HelpState>(
        'collapses FAQ item when currently expanded',
        build: () {
          when(() => mockHelpRepository.getFaqItems())
              .thenReturn(makeFaqItems());
          return bloc;
        },
        act: (bloc) async {
          bloc.add(LoadFaq());
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(ToggleFaqItem(index: 1));
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(ToggleFaqItem(index: 1));
        },
        expect: () => [
          isA<HelpLoading>(),
          isA<FaqLoaded>().having((s) => s.expandedIndex, 'expandedIndex', -1),
          isA<FaqLoaded>().having((s) => s.expandedIndex, 'expandedIndex', 1),
          isA<FaqLoaded>().having((s) => s.expandedIndex, 'expandedIndex', -1),
        ],
      );

      blocTest<HelpBloc, HelpState>(
        'does nothing when state is not FaqLoaded',
        build: () => bloc,
        seed: () => const HelpError(message: 'error'),
        act: (bloc) => bloc.add(ToggleFaqItem(index: 0)),
        expect: () => [],
      );
    });
  });
}
