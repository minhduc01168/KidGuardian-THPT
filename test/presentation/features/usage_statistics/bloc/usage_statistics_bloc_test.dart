import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/entities/usage_log.dart';
import 'package:kidguardian/domain/repositories/usage_repository.dart';
import 'package:kidguardian/presentation/features/usage_statistics/bloc/usage_statistics_bloc.dart';
import 'package:kidguardian/presentation/features/usage_statistics/bloc/usage_statistics_event.dart';
import 'package:kidguardian/presentation/features/usage_statistics/bloc/usage_statistics_state.dart';

class MockUsageRepository extends Mock implements UsageRepository {}

void main() {
  late MockUsageRepository mockRepository;
  late UsageStatisticsBloc bloc;

  setUp(() {
    mockRepository = MockUsageRepository();
    bloc = UsageStatisticsBloc(usageRepository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  final now = DateTime(2026, 5, 16);
  final weekAgo = now.subtract(const Duration(days: 7));
  final startDateStr =
      '${weekAgo.year}-${weekAgo.month.toString().padLeft(2, '0')}-${weekAgo.day.toString().padLeft(2, '0')}';
  final endDateStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  final testLogs = [
    UsageLog(
      docId: '1',
      childUid: 'child1',
      familyId: 'family1',
      appPackage: 'com.tiktok',
      appName: 'TikTok',
      startTime: now,
      endTime: now.add(const Duration(minutes: 30)),
      durationMinutes: 30,
      date: endDateStr,
    ),
    UsageLog(
      docId: '2',
      childUid: 'child1',
      familyId: 'family1',
      appPackage: 'com.facebook',
      appName: 'Facebook',
      startTime: now.add(const Duration(hours: 2)),
      endTime: now.add(const Duration(hours: 2, minutes: 45)),
      durationMinutes: 45,
      date: endDateStr,
    ),
  ];

  group('UsageStatisticsBloc', () {
    blocTest<UsageStatisticsBloc, UsageStatisticsState>(
      'emits [Loading, Loaded] when LoadUsageStats succeeds',
      build: () {
        when(() => mockRepository.getUsageByDateRange(
              'child1',
              startDateStr,
              endDateStr,
            )).thenAnswer((_) async => testLogs);
        return bloc;
      },
      act: (bloc) => bloc.add(LoadUsageStats(
        childUid: 'child1',
        startDate: weekAgo,
        endDate: now,
      )),
      expect: () => [
        isA<UsageStatisticsLoading>(),
        isA<UsageStatisticsLoaded>()
            .having((s) => s.totalMinutes, 'totalMinutes', 75)
            .having((s) => s.mostUsedApps.length, 'mostUsedApps', 2)
            .having((s) => s.selectedPeriod, 'selectedPeriod', TimePeriod.day),
      ],
    );

    blocTest<UsageStatisticsBloc, UsageStatisticsState>(
      'emits [Loading, Error] when LoadUsageStats fails',
      build: () {
        when(() => mockRepository.getUsageByDateRange(
              'child1',
              startDateStr,
              endDateStr,
            )).thenThrow(Exception('Network error'));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadUsageStats(
        childUid: 'child1',
        startDate: weekAgo,
        endDate: now,
      )),
      expect: () => [
        isA<UsageStatisticsLoading>(),
        isA<UsageStatisticsError>(),
      ],
    );

    blocTest<UsageStatisticsBloc, UsageStatisticsState>(
      'emits Loaded with updated period when ChangeTimePeriod',
      build: () {
        when(() => mockRepository.getUsageByDateRange(
              'child1',
              startDateStr,
              endDateStr,
            )).thenAnswer((_) async => testLogs);
        return bloc;
      },
      act: (bloc) async {
        bloc.add(LoadUsageStats(
          childUid: 'child1',
          startDate: weekAgo,
          endDate: now,
        ));
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(ChangeTimePeriod(
          childUid: 'child1',
          period: TimePeriod.week,
        ));
      },
      expect: () => [
        isA<UsageStatisticsLoading>(),
        isA<UsageStatisticsLoaded>(),
        isA<UsageStatisticsLoaded>()
            .having((s) => s.selectedPeriod, 'period', TimePeriod.week),
      ],
    );
  });
}
