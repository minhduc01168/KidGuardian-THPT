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
import 'package:kidguardian/data/repositories/smart_lock_repository.dart';
import 'package:kidguardian/data/models/monitored_app_model.dart';

class MockUsageRepository extends Mock implements UsageRepository {}
class MockFamilyRepository extends Mock implements FamilyRepository {}
class MockSmartLockRepository extends Mock implements SmartLockRepository {}

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
    final pkg = appName == 'YouTube' ? 'com.google.android.youtube' : 'com.zhiliaoapp.musically';
    return UsageLog(
      docId: 'doc1',
      childUid: childUid,
      familyId: 'fam1',
      appPackage: pkg,
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

      blocTest<DashboardBloc, DashboardState>(
        'emits DashboardLoaded with usageByApp strictly filtered by monitoredApps (isMonitored == true)',
        build: () {
          final mockSmartLock = MockSmartLockRepository();
          when(() => mockFamilyRepository.getFamily(any()))
              .thenAnswer((_) async => makeFamily(childUids: ['child1']));
          when(() => mockUsageRepository.getTotalUsageMinutes(any(), any()))
              .thenAnswer((_) async => 100);
          when(() => mockUsageRepository.getUsageByApp('child1', any()))
              .thenAnswer((_) async => {
                'com.google.android.youtube': 40,
                'com.unmonitored.game': 60,
              });
          when(() => mockUsageRepository.getUsageByChild(any(), any()))
              .thenAnswer((_) async => <UsageLog>[]);
          when(() => mockUsageRepository.getUsageByDateRange(any(), any(), any()))
              .thenAnswer((_) async => <UsageLog>[]);
          when(() => mockSmartLock.getMonitoredApps('fam1', 'child1'))
              .thenAnswer((_) async => [
                MonitoredAppModel(
                  appPackageName: 'com.google.android.youtube',
                  appName: 'YouTube',
                  isMonitored: true,
                ),
                MonitoredAppModel(
                  appPackageName: 'com.unmonitored.game',
                  appName: 'Unmonitored Game',
                  isMonitored: false,
                ),
              ]);
          when(() => mockSmartLock.getAppTimeLimits(any(), any()))
              .thenAnswer((_) async => []);

          return DashboardBloc(
            usageRepository: mockUsageRepository,
            familyRepository: mockFamilyRepository,
            smartLockRepository: mockSmartLock,
          );
        },
        act: (bloc) => bloc.add(const LoadDashboard(familyId: 'fam1')),
        expect: () => [
          isA<DashboardLoading>(),
          isA<DashboardLoaded>().having(
            (s) => s.usageByApp,
            'usageByApp',
            {'YouTube': 40},
          ).having(
            (s) => s.totalMinutesToday,
            'totalMinutesToday',
            40,
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

    group('Monitored Apps Filtering (Gmail, LinkedIn, etc.)', () {
      blocTest<DashboardBloc, DashboardState>(
        'excludes unmonitored apps like Gmail and LinkedIn from Dashboard when not in monitored list',
        build: () {
          final mockSmartLock = MockSmartLockRepository();
          when(() => mockFamilyRepository.getFamily(any()))
              .thenAnswer((_) async => makeFamily(childUids: ['child1']));
          when(() => mockUsageRepository.getTotalUsageMinutes(any(), any()))
              .thenAnswer((_) async => 120);
          when(() => mockUsageRepository.getUsageByApp('child1', any()))
              .thenAnswer((_) async => {
                'com.google.android.gm': 45, // Gmail
                'com.linkedin.android': 30,  // LinkedIn
                'com.zhiliaoapp.musically': 45, // TikTok (Monitored)
              });
          when(() => mockUsageRepository.getUsageByChild(any(), any()))
              .thenAnswer((_) async => <UsageLog>[]);
          when(() => mockUsageRepository.getUsageByDateRange(any(), any(), any()))
              .thenAnswer((_) async => <UsageLog>[]);
          when(() => mockSmartLock.getMonitoredApps('fam1', 'child1'))
              .thenAnswer((_) async => [
                MonitoredAppModel(
                  appPackageName: 'com.zhiliaoapp.musically',
                  appName: 'TikTok',
                  isMonitored: true,
                ),
              ]);
          when(() => mockSmartLock.getAppTimeLimits(any(), any()))
              .thenAnswer((_) async => []);

          return DashboardBloc(
            usageRepository: mockUsageRepository,
            familyRepository: mockFamilyRepository,
            smartLockRepository: mockSmartLock,
          );
        },
        act: (bloc) => bloc.add(const LoadDashboard(familyId: 'fam1')),
        expect: () => [
          isA<DashboardLoading>(),
          isA<DashboardLoaded>().having(
            (s) => s.usageByApp,
            'usageByApp excludes Gmail and LinkedIn',
            {'TikTok': 45},
          ).having(
            (s) => s.totalMinutesToday,
            'totalMinutesToday counts only TikTok',
            45,
          ),
        ],
      );
    });

    group('Bug #3 Dashboard Chart Filter', () {
      blocTest<DashboardBloc, DashboardState>(
        'allows non-system apps like Chrome and Free Fire when monitoredApps is empty',
        build: () {
          final mockSmartLock = MockSmartLockRepository();
          when(() => mockFamilyRepository.getFamily(any()))
              .thenAnswer((_) async => makeFamily(childUids: ['child1']));
          when(() => mockUsageRepository.getTotalUsageMinutes(any(), any()))
              .thenAnswer((_) async => 100);
          when(() => mockUsageRepository.getUsageByApp('child1', any()))
              .thenAnswer((_) async => {
                'com.android.settings': 20, // System app -> Excluded
                'com.android.chrome': 40,   // Non-system -> Included
                'com.dts.freefireth': 60,   // Non-system -> Included
              });
          when(() => mockUsageRepository.getUsageByChild(any(), any()))
              .thenAnswer((_) async => <UsageLog>[]);
          when(() => mockUsageRepository.getUsageByDateRange(any(), any(), any()))
              .thenAnswer((_) async => <UsageLog>[]);
          when(() => mockSmartLock.getMonitoredApps('fam1', 'child1'))
              .thenAnswer((_) async => []); // Empty monitored list
          when(() => mockSmartLock.getAppTimeLimits(any(), any()))
              .thenAnswer((_) async => []);

          return DashboardBloc(
            usageRepository: mockUsageRepository,
            familyRepository: mockFamilyRepository,
            smartLockRepository: mockSmartLock,
          );
        },
        act: (bloc) => bloc.add(const LoadDashboard(familyId: 'fam1')),
        expect: () => [
          isA<DashboardLoading>(),
          isA<DashboardLoaded>().having(
            (s) => s.usageByApp,
            'usageByApp includes Chrome and FreeFire, excludes Settings',
            {
              'Google Chrome': 40,
              'Freefireth': 60,
            },
          ).having(
            (s) => s.totalMinutesToday,
            'totalMinutesToday counts Chrome and FreeFire',
            100,
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
