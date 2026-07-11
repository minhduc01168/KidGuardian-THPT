import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/entities/daily_summary.dart';
import 'package:kidguardian/domain/repositories/summary_repository.dart';
import 'package:kidguardian/presentation/features/summary/bloc/summary_bloc.dart';
import 'package:kidguardian/presentation/features/summary/bloc/summary_event.dart';
import 'package:kidguardian/presentation/features/summary/bloc/summary_state.dart';

class MockSummaryRepository extends Mock implements SummaryRepository {}

void main() {
  late SummaryBloc bloc;
  late MockSummaryRepository mockSummaryRepository;

  setUp(() {
    mockSummaryRepository = MockSummaryRepository();
    bloc = SummaryBloc(summaryRepository: mockSummaryRepository);
  });

  tearDown(() {
    bloc.close();
  });

  DailySummary makeSummary({
    String summaryId = 'summary1',
    String childUid = 'child1',
    String familyId = 'fam1',
    String date = '2026-05-31',
  }) {
    return DailySummary(
      summaryId: summaryId,
      childUid: childUid,
      familyId: familyId,
      date: date,
      totalMinutes: 120,
      usageByApp: const {'TikTok': 60, 'YouTube': 40, 'Game': 20},
      topApps: const ['TikTok', 'YouTube', 'Game'],
      alertCount: 2,
      violationCount: 1,
      sent: false,
    );
  }

  group('SummaryBloc', () {
    test('initial state is SummaryInitial', () {
      expect(bloc.state, isA<SummaryInitial>());
    });

    group('LoadDailySummary', () {
      blocTest<SummaryBloc, SummaryState>(
        'emits [SummaryLoading, SummaryLoaded] with existing summary when available',
        build: () {
          when(() => mockSummaryRepository.hasSummaryForDate('child1', any()))
              .thenAnswer((_) async => true);
          when(() => mockSummaryRepository.getSummariesByChild('child1', limit: 1))
              .thenAnswer((_) async => [makeSummary()]);
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadDailySummary(
          childUid: 'child1',
          familyId: 'fam1',
        )),
        expect: () => [
          isA<SummaryLoading>(),
          isA<SummaryLoaded>()
              .having((s) => s.summary.summaryId, 'summaryId', 'summary1'),
        ],
      );

      blocTest<SummaryBloc, SummaryState>(
        'generates new summary when none exists for today',
        build: () {
          when(() => mockSummaryRepository.hasSummaryForDate('child1', any()))
              .thenAnswer((_) async => false);
          when(() => mockSummaryRepository.generateDailySummary(
                'child1',
                'fam1',
                any(),
              )).thenAnswer((_) async => makeSummary());
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadDailySummary(
          childUid: 'child1',
          familyId: 'fam1',
        )),
        expect: () => [
          isA<SummaryLoading>(),
          isA<SummaryLoaded>()
              .having((s) => s.summary.summaryId, 'summaryId', 'summary1'),
        ],
      );

      blocTest<SummaryBloc, SummaryState>(
        'generates summary when hasSummaryForDate returns true but list is empty',
        build: () {
          when(() => mockSummaryRepository.hasSummaryForDate('child1', any()))
              .thenAnswer((_) async => true);
          when(() => mockSummaryRepository.getSummariesByChild('child1', limit: 1))
              .thenAnswer((_) async => []);
          when(() => mockSummaryRepository.generateDailySummary(
                'child1',
                'fam1',
                any(),
              )).thenAnswer((_) async => makeSummary());
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadDailySummary(
          childUid: 'child1',
          familyId: 'fam1',
        )),
        expect: () => [
          isA<SummaryLoading>(),
          isA<SummaryLoaded>(),
        ],
      );

      blocTest<SummaryBloc, SummaryState>(
        'emits [SummaryLoading, SummaryError] on failure',
        build: () {
          when(() => mockSummaryRepository.hasSummaryForDate(any(), any()))
              .thenThrow(Exception('DB error'));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadDailySummary(
          childUid: 'child1',
          familyId: 'fam1',
        )),
        expect: () => [
          isA<SummaryLoading>(),
          isA<SummaryError>().having(
            (e) => e.message,
            'message',
            'DB error',
          ),
        ],
      );
    });

    group('LoadSummaryHistory', () {
      blocTest<SummaryBloc, SummaryState>(
        'emits [SummaryLoading, SummaryHistoryLoaded] on success',
        build: () {
          when(() => mockSummaryRepository.getSummariesByFamily('fam1'))
              .thenAnswer((_) async => [
                    makeSummary(date: '2026-05-31'),
                    makeSummary(
                      summaryId: 'summary2',
                      date: '2026-05-30',
                    ),
                  ]);
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadSummaryHistory(familyId: 'fam1')),
        expect: () => [
          isA<SummaryLoading>(),
          isA<SummaryHistoryLoaded>()
              .having((s) => s.summaries.length, 'summaries length', 2),
        ],
      );

      blocTest<SummaryBloc, SummaryState>(
        'emits [SummaryLoading, SummaryHistoryLoaded] with empty list',
        build: () {
          when(() => mockSummaryRepository.getSummariesByFamily('fam1'))
              .thenAnswer((_) async => []);
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadSummaryHistory(familyId: 'fam1')),
        expect: () => [
          isA<SummaryLoading>(),
          isA<SummaryHistoryLoaded>()
              .having((s) => s.summaries, 'summaries', isEmpty),
        ],
      );

      blocTest<SummaryBloc, SummaryState>(
        'emits [SummaryLoading, SummaryError] on failure',
        build: () {
          when(() => mockSummaryRepository.getSummariesByFamily(any()))
              .thenThrow(Exception('Network error'));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadSummaryHistory(familyId: 'fam1')),
        expect: () => [
          isA<SummaryLoading>(),
          isA<SummaryError>().having(
            (e) => e.message,
            'message',
            'Network error',
          ),
        ],
      );
    });

    group('GenerateSummary', () {
      blocTest<SummaryBloc, SummaryState>(
        'emits [SummaryLoading, SummaryGenerated] on success',
        build: () {
          when(() => mockSummaryRepository.generateDailySummary(
                'child1',
                'fam1',
                '2026-05-31',
              )).thenAnswer((_) async => makeSummary());
          return bloc;
        },
        act: (bloc) => bloc.add(const GenerateSummary(
          childUid: 'child1',
          familyId: 'fam1',
          date: '2026-05-31',
        )),
        expect: () => [
          isA<SummaryLoading>(),
          isA<SummaryGenerated>()
              .having((s) => s.summary.summaryId, 'summaryId', 'summary1'),
        ],
      );

      blocTest<SummaryBloc, SummaryState>(
        'emits [SummaryLoading, SummaryError] on failure',
        build: () {
          when(() => mockSummaryRepository.generateDailySummary(
                any(),
                any(),
                any(),
              )).thenThrow(Exception('Generation failed'));
          return bloc;
        },
        act: (bloc) => bloc.add(const GenerateSummary(
          childUid: 'child1',
          familyId: 'fam1',
          date: '2026-05-31',
        )),
        expect: () => [
          isA<SummaryLoading>(),
          isA<SummaryError>().having(
            (e) => e.message,
            'message',
            'Generation failed',
          ),
        ],
      );
    });
  });
}
