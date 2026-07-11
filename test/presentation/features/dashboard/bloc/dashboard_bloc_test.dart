import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/entities/usage_log.dart';
import 'package:kidguardian/domain/entities/family.dart';
import 'package:kidguardian/domain/repositories/usage_repository.dart';
import 'package:kidguardian/domain/repositories/family_repository.dart';
import 'package:kidguardian/presentation/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:kidguardian/presentation/features/dashboard/bloc/dashboard_event.dart';
import 'package:kidguardian/presentation/features/dashboard/bloc/dashboard_state.dart';

class MockUsageRepository extends Mock implements UsageRepository {}
class MockFamilyRepository extends Mock implements FamilyRepository {}

void main() {
  late DashboardBloc bloc;
  late MockUsageRepository mockUsageRepository;
  late MockFamilyRepository mockFamilyRepository;

  setUp(() {
    mockUsageRepository = MockUsageRepository();
    mockFamilyRepository = MockFamilyRepository();
    bloc = DashboardBloc(
      usageRepository: mockUsageRepository,
      familyRepository: mockFamilyRepository,
    );
  });

  tearDown(() {
    bloc.close();
  });

  UsageLog makeLog({
    String appName = 'TikTok',
    int durationMinutes = 30,
    String date = '2026-05-31',
    String childUid = 'child1',
  }) {
    return UsageLog(
      docId: 'doc1',
      childUid: childUid,
      familyId: 'fam1',
      appPackage: 'com.example.app',
      appName: appName,
      startTime: DateTime(2026, 5, 31, 10, 0),
      endTime: DateTime(2026, 5, 31, 10, durationMinutes),
      durationMinutes: durationMinutes,
      date: date,
    );
  }

  Family makeFamily({List<String> childUids = const ['child1']}) {
    return Family(
      familyId: 'fam1',
      parentUid: 'parent1',
      childUids: childUids,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  group('DashboardBloc', () {
    test('initial state is DashboardInitial', () {
      expect(bloc.state, isA<DashboardInitial>());
    });

    group('LoadDashboard', () {
      blocTest<DashboardBloc, DashboardState>(
        'emits [DashboardLoading, DashboardError] when family not found',
        build: () {
          when(() => mockFamilyRepository.getFamily(any()))
              .thenAnswer((_) async => null);
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadDashboard(familyId: 'fam1')),
        expect: () => [
          isA<DashboardLoading>(),
          isA<DashboardError>().having(
            (e) => e.message,
            'message',
            contains('Không tìm thấy thông tin gia đình'),
          ),
        ],
      );

      blocTest<DashboardBloc, DashboardState>(
        'emits [DashboardLoading, DashboardLoaded] on success',
        build: () {
          when(() => mockFamilyRepository.getFamily(any()))
              .thenAnswer((_) async => makeFamily());
          when(() => mockUsageRepository.getTotalUsageMinutes(any(), any()))
              .thenAnswer((_) async => 60);
          when(() => mockUsageRepository.getUsageByApp(any(), any()))
              .thenAnswer((_) async => {});
          when(() => mockUsageRepository.getUsageByChild(any(), any()))
              .thenAnswer((_) async => <UsageLog>[]);
          when(() => mockUsageRepository.getUsageByDateRange(any(), any(), any()))
              .thenAnswer((_) async => <UsageLog>[]);
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadDashboard(familyId: 'fam1')),
        expect: () => [
          isA<DashboardLoading>(),
          isA<DashboardLoaded>()
              .having((s) => s.totalMinutesToday, 'totalMinutesToday', 60)
              .having((s) => s.childUids, 'childUids', ['child1']),
        ],
      );

      blocTest<DashboardBloc, DashboardState>(
        'emits DashboardLoaded with usageByApp aggregated across children',
        build: () {
          when(() => mockFamilyRepository.getFamily(any()))
              .thenAnswer((_) async => makeFamily(childUids: ['child1', 'child2']));
          when(() => mockUsageRepository.getTotalUsageMinutes(any(), any()))
              .thenAnswer((_) async => 0);
          when(() => mockUsageRepository.getUsageByApp('child1', any()))
              .thenAnswer((_) async => {'TikTok': 30});
          when(() => mockUsageRepository.getUsageByApp('child2', any()))
              .thenAnswer((_) async => {'TikTok': 20, 'YouTube': 15});
          when(() => mockUsageRepository.getUsageByChild(any(), any()))
              .thenAnswer((_) async => <UsageLog>[]);
          when(() => mockUsageRepository.getUsageByDateRange(any(), any(), any()))
              .thenAnswer((_) async => <UsageLog>[]);
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadDashboard(familyId: 'fam1')),
        expect: () => [
          isA<DashboardLoading>(),
          isA<DashboardLoaded>().having(
            (s) => s.usageByApp,
            'usageByApp',
            {'TikTok': 50, 'YouTube': 15},
          ),
        ],
      );

      blocTest<DashboardBloc, DashboardState>(
        'emits DashboardError on exception',
        build: () {
          when(() => mockFamilyRepository.getFamily(any()))
              .thenThrow(Exception('Network error'));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadDashboard(familyId: 'fam1')),
        expect: () => [
          isA<DashboardLoading>(),
          isA<DashboardError>().having(
            (e) => e.message,
            'message',
            'Network error',
          ),
        ],
      );
    });

    group('LoadChildUsage', () {
      blocTest<DashboardBloc, DashboardState>(
        'emits [DashboardLoading, DashboardLoaded] for child usage',
        build: () {
          when(() => mockUsageRepository.getUsageByApp('child1', '2026-05-31'))
              .thenAnswer((_) async => {'YouTube': 90});
          when(() => mockUsageRepository.getUsageByChild('child1', '2026-05-31'))
              .thenAnswer((_) async => [makeLog(durationMinutes: 90)]);
          when(() => mockUsageRepository.getUsageByDateRange(any(), any(), any()))
              .thenAnswer((_) async => <UsageLog>[]);
          when(() => mockUsageRepository.getTotalUsageMinutes(any(), any()))
              .thenAnswer((invocation) async {
            final childUid = invocation.positionalArguments[0] as String;
            final date = invocation.positionalArguments[1] as String;
            if (childUid == 'child1' && date == '2026-05-31') return 90;
            return 45;
          });
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadChildUsage(
          childUid: 'child1',
          date: '2026-05-31',
        )),
        expect: () => [
          isA<DashboardLoading>(),
          isA<DashboardLoaded>()
              .having((s) => s.totalMinutesToday, 'totalMinutesToday', 90)
              .having((s) => s.childUids, 'childUids', ['child1'])
              .having((s) => s.usageByApp, 'usageByApp', {'YouTube': 90}),
        ],
      );

      blocTest<DashboardBloc, DashboardState>(
        'emits DashboardError on exception',
        build: () {
          when(() => mockUsageRepository.getTotalUsageMinutes(any(), any()))
              .thenThrow(Exception('DB error'));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadChildUsage(
          childUid: 'child1',
          date: '2026-05-31',
        )),
        expect: () => [
          isA<DashboardLoading>(),
          isA<DashboardError>().having(
            (e) => e.message,
            'message',
            'DB error',
          ),
        ],
      );
    });

    group('LoadUsageChart', () {
      blocTest<DashboardBloc, DashboardState>(
        'emits [DashboardLoading, UsageChartData] on success',
        build: () {
          final logs = [
            makeLog(appName: 'TikTok', durationMinutes: 30, date: '2026-05-30'),
            makeLog(appName: 'YouTube', durationMinutes: 45, date: '2026-05-31'),
            makeLog(appName: 'TikTok', durationMinutes: 20, date: '2026-05-31'),
          ];
          when(() => mockUsageRepository.getUsageByDateRange(
                'child1',
                '2026-05-25',
                '2026-05-31',
              )).thenAnswer((_) async => logs);
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadUsageChart(
          childUid: 'child1',
          startDate: '2026-05-25',
          endDate: '2026-05-31',
        )),
        expect: () => [
          isA<DashboardLoading>(),
          isA<UsageChartData>()
              .having((s) => s.dailyTotals, 'dailyTotals', {
                '2026-05-30': 30,
                '2026-05-31': 65,
              })
              .having((s) => s.appTotals, 'appTotals', {
                'TikTok': 50,
                'YouTube': 45,
              }),
        ],
      );

      blocTest<DashboardBloc, DashboardState>(
        'emits DashboardError on exception',
        build: () {
          when(() => mockUsageRepository.getUsageByDateRange(any(), any(), any()))
              .thenThrow(Exception('Chart error'));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadUsageChart(
          childUid: 'child1',
          startDate: '2026-05-25',
          endDate: '2026-05-31',
        )),
        expect: () => [
          isA<DashboardLoading>(),
          isA<DashboardError>().having(
            (e) => e.message,
            'message',
            'Chart error',
          ),
        ],
      );
    });

    group('RefreshDashboard', () {
      blocTest<DashboardBloc, DashboardState>(
        'triggers LoadDashboard with same familyId',
        build: () {
          when(() => mockFamilyRepository.getFamily(any()))
              .thenAnswer((_) async => makeFamily());
          when(() => mockUsageRepository.getTotalUsageMinutes(any(), any()))
              .thenAnswer((_) async => 0);
          when(() => mockUsageRepository.getUsageByApp(any(), any()))
              .thenAnswer((_) async => {});
          when(() => mockUsageRepository.getUsageByChild(any(), any()))
              .thenAnswer((_) async => <UsageLog>[]);
          when(() => mockUsageRepository.getUsageByDateRange(any(), any(), any()))
              .thenAnswer((_) async => <UsageLog>[]);
          return bloc;
        },
        act: (bloc) => bloc.add(const RefreshDashboard(familyId: 'fam1')),
        expect: () => [
          isA<DashboardLoading>(),
          isA<DashboardLoaded>(),
        ],
      );
    });
  });
}
