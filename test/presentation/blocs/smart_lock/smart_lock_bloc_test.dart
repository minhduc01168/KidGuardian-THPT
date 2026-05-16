import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/data/repositories/smart_lock_repository.dart';
import 'package:kidguardian/data/models/app_time_limit_model.dart';
import 'package:kidguardian/data/models/monitored_app_model.dart';
import 'package:kidguardian/data/models/schedule_model.dart';
import 'package:kidguardian/data/models/smart_lock_settings_model.dart';
import 'package:kidguardian/data/models/lock_history_entry_model.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_bloc.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_event.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_state.dart';

class MockSmartLockRepository extends Mock implements SmartLockRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(const MonitoredAppModel(
      appPackageName: '',
      appName: '',
      isMonitored: true,
    ));
    registerFallbackValue(const ScheduleModel(
      id: '',
      name: '',
      type: 'blocked',
      startHour: 0,
      startMinute: 0,
      endHour: 0,
      endMinute: 0,
      days: {},
    ));
    registerFallbackValue(const SmartLockSettingsModel());

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.kidguardian/accessibility'),
      (MethodCall methodCall) async => null,
    );
  });
  late SmartLockBloc bloc;
  late MockSmartLockRepository mockRepository;

  setUp(() {
    mockRepository = MockSmartLockRepository();
    bloc = SmartLockBloc(repository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('SmartLockBloc', () {
    const familyId = 'family1';
    const childId = 'child1';
    
    final popularApps = [
      const AppTimeLimitModel(appPackageName: 'com.facebook', appName: 'Facebook', limits: {}),
      const AppTimeLimitModel(appPackageName: 'com.tiktok', appName: 'TikTok', limits: {}),
    ];
    
    final configuredApps = [
      const AppTimeLimitModel(appPackageName: 'com.tiktok', appName: 'TikTok', limits: {'everyday': 60}),
    ];

    test('initial state is SmartLockInitial', () {
      expect(bloc.state, isA<SmartLockInitial>());
    });

    blocTest<SmartLockBloc, SmartLockState>(
      'emits [SmartLockLoading, SmartLockLoaded] when LoadAppTimeLimits is added',
      build: () {
        when(() => mockRepository.getPopularApps()).thenReturn(popularApps);
        when(() => mockRepository.getAppTimeLimits(familyId, childId))
            .thenAnswer((_) async => configuredApps);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadAppTimeLimits(familyId, childId)),
      expect: () => [
        isA<SmartLockLoading>(),
        isA<SmartLockLoaded>().having((state) => state.apps.length, 'apps count', 2)
            .having((state) => state.apps.first.appName, 'first app is configured one', 'TikTok'),
      ],
    );

    blocTest<SmartLockBloc, SmartLockState>(
      'emits [SmartLockActionSuccess, SmartLockLoaded] when SaveAppTimeLimit is added',
      build: () {
        when(() => mockRepository.saveAppTimeLimit(familyId, childId, configuredApps.first))
            .thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(SaveAppTimeLimit(familyId, childId, configuredApps.first)),
      expect: () => [
        isA<SmartLockActionSuccess>(),
        isA<SmartLockLoaded>(),
      ],
    );
  });

  group('SmartLockBloc - Monitored Apps', () {
    late SmartLockBloc bloc;
    late MockSmartLockRepository mockRepository;

    const familyId = 'family1';
    const childId = 'child1';

    final popularMonitoredApps = [
      const MonitoredAppModel(
        appPackageName: 'com.tiktok',
        appName: 'TikTok',
        isMonitored: true,
      ),
      const MonitoredAppModel(
        appPackageName: 'com.facebook',
        appName: 'Facebook',
        isMonitored: true,
      ),
    ];

    final configuredMonitoredApps = [
      const MonitoredAppModel(
        appPackageName: 'com.tiktok',
        appName: 'TikTok',
        isMonitored: false,
      ),
    ];

    setUp(() {
      mockRepository = MockSmartLockRepository();
      bloc = SmartLockBloc(repository: mockRepository);
    });

    tearDown(() {
      bloc.close();
    });

    blocTest<SmartLockBloc, SmartLockState>(
      'emits [SmartLockLoading, MonitoredAppsLoaded] when LoadMonitoredApps is added',
      build: () {
        when(() => mockRepository.getPopularMonitoredApps())
            .thenReturn(popularMonitoredApps);
        when(() => mockRepository.getMonitoredApps(familyId, childId))
            .thenAnswer((_) async => configuredMonitoredApps);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadMonitoredApps(familyId, childId)),
      expect: () => [
        isA<SmartLockLoading>(),
        isA<MonitoredAppsLoaded>().having(
          (state) => state.apps.length,
          'apps count',
          2,
        ),
      ],
    );

    blocTest<SmartLockBloc, SmartLockState>(
      'emits [MonitoredAppsLoaded, MonitoredAppsLoaded] when ToggleMonitoredApp is added',
      build: () {
        when(() => mockRepository.getPopularMonitoredApps())
            .thenReturn(popularMonitoredApps);
        when(() => mockRepository.getMonitoredApps(familyId, childId))
            .thenAnswer((_) async => configuredMonitoredApps);
        when(() => mockRepository.toggleMonitoredApp(familyId, childId, 'com.tiktok', true))
            .thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const LoadMonitoredApps(familyId, childId));
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(const ToggleMonitoredApp(familyId, childId, 'com.tiktok', true));
      },
      expect: () => [
        isA<SmartLockLoading>(),
        isA<MonitoredAppsLoaded>(),
        isA<MonitoredAppsLoaded>(),
      ],
    );

    blocTest<SmartLockBloc, SmartLockState>(
      'emits [MonitoredAppsLoaded] when AddCustomApp is added',
      build: () {
        when(() => mockRepository.getPopularMonitoredApps())
            .thenReturn(popularMonitoredApps);
        when(() => mockRepository.getMonitoredApps(familyId, childId))
            .thenAnswer((_) async => []);
        when(() => mockRepository.addCustomApp(familyId, childId, any()))
            .thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const LoadMonitoredApps(familyId, childId));
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(const AddCustomApp(familyId, childId, 'com.custom.app', 'Custom App'));
      },
      expect: () => [
        isA<SmartLockLoading>(),
        isA<MonitoredAppsLoaded>(),
        isA<MonitoredAppsLoaded>().having(
          (state) => state.apps.any((a) => a.appPackageName == 'com.custom.app'),
          'contains custom app',
          true,
        ),
      ],
    );
  });

  group('SmartLockBloc - Schedules', () {
    late SmartLockBloc bloc;
    late MockSmartLockRepository mockRepository;

    const familyId = 'family1';
    const childId = 'child1';

    final tSchedule = ScheduleModel(
      id: 'schedule1',
      name: 'Giờ ngủ',
      type: 'blocked',
      startHour: 21,
      startMinute: 0,
      endHour: 6,
      endMinute: 0,
      days: const {
        'monday': true,
        'tuesday': true,
        'wednesday': true,
        'thursday': true,
        'friday': true,
        'saturday': true,
        'sunday': true,
      },
      isEnabled: true,
    );

    setUp(() {
      mockRepository = MockSmartLockRepository();
      bloc = SmartLockBloc(repository: mockRepository);
    });

    tearDown(() {
      bloc.close();
    });

    blocTest<SmartLockBloc, SmartLockState>(
      'emits [SmartLockLoading, SchedulesLoaded] when LoadSchedules is added',
      build: () {
        when(() => mockRepository.getSchedules(familyId, childId))
            .thenAnswer((_) async => [tSchedule]);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadSchedules(familyId, childId)),
      expect: () => [
        isA<SmartLockLoading>(),
        isA<SchedulesLoaded>().having(
          (state) => state.schedules.length,
          'schedules count',
          1,
        ),
      ],
    );

    blocTest<SmartLockBloc, SmartLockState>(
      'emits [SmartLockActionSuccess, SchedulesLoaded] when SaveSchedule is added',
      build: () {
        when(() => mockRepository.saveSchedule(familyId, childId, any()))
            .thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(SaveSchedule(familyId, childId, tSchedule)),
      expect: () => [
        isA<SmartLockActionSuccess>(),
        isA<SchedulesLoaded>(),
      ],
    );

    blocTest<SmartLockBloc, SmartLockState>(
      'emits [SmartLockActionSuccess, SchedulesLoaded] when DeleteSchedule is added',
      build: () {
        when(() => mockRepository.deleteSchedule(familyId, childId, 'schedule1'))
            .thenAnswer((_) async {});
        return bloc;
      },
      seed: () => SchedulesLoaded([tSchedule]),
      act: (bloc) => bloc.add(const DeleteSchedule(familyId, childId, 'schedule1')),
      expect: () => [
        isA<SmartLockActionSuccess>(),
        isA<SchedulesLoaded>().having(
          (state) => state.schedules.length,
          'schedules count after delete',
          0,
        ),
      ],
    );

    blocTest<SmartLockBloc, SmartLockState>(
      'emits [SmartLockError, SchedulesLoaded] when SaveSchedule fails',
      build: () {
        when(() => mockRepository.saveSchedule(familyId, childId, any()))
            .thenThrow(Exception('Firestore error'));
        return bloc;
      },
      act: (bloc) => bloc.add(SaveSchedule(familyId, childId, tSchedule)),
      expect: () => [
        isA<SmartLockError>(),
        isA<SchedulesLoaded>(),
      ],
    );

    blocTest<SmartLockBloc, SmartLockState>(
      'emits [SmartLockError, SchedulesLoaded] when DeleteSchedule fails',
      build: () {
        when(() => mockRepository.deleteSchedule(familyId, childId, 'schedule1'))
            .thenThrow(Exception('Firestore error'));
        return bloc;
      },
      seed: () => SchedulesLoaded([tSchedule]),
      act: (bloc) => bloc.add(const DeleteSchedule(familyId, childId, 'schedule1')),
      expect: () => [
        isA<SmartLockError>(),
        isA<SchedulesLoaded>(),
      ],
    );

    // Smart Lock Settings tests

    blocTest<SmartLockBloc, SmartLockState>(
      'emits [SmartLockLoading, SmartLockSettingsLoaded] when LoadSmartLockSettings succeeds',
      build: () {
        when(() => mockRepository.getSmartLockSettings(familyId, childId))
            .thenAnswer((_) async => const SmartLockSettingsModel(
                  isEnabled: false,
                  defaultTimeLimitMinutes: 90,
                ));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadSmartLockSettings(familyId, childId)),
      expect: () => [
        isA<SmartLockLoading>(),
        isA<SmartLockSettingsLoaded>()
            .having((s) => s.settings.isEnabled, 'isEnabled', false)
            .having((s) => s.settings.defaultTimeLimitMinutes, 'defaultTimeLimit', 90),
      ],
    );

    blocTest<SmartLockBloc, SmartLockState>(
      'emits [SmartLockLoading, SmartLockSettingsLoaded] with defaults when settings null',
      build: () {
        when(() => mockRepository.getSmartLockSettings(familyId, childId))
            .thenAnswer((_) async => null);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadSmartLockSettings(familyId, childId)),
      expect: () => [
        isA<SmartLockLoading>(),
        isA<SmartLockSettingsLoaded>()
            .having((s) => s.settings.isEnabled, 'isEnabled', true)
            .having((s) => s.settings.defaultTimeLimitMinutes, 'defaultTimeLimit', 60),
      ],
    );

    blocTest<SmartLockBloc, SmartLockState>(
      'emits [SmartLockActionSuccess, SmartLockSettingsLoaded] when SaveSmartLockSettings succeeds',
      build: () {
        when(() => mockRepository.saveSmartLockSettings(familyId, childId, any()))
            .thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(const SaveSmartLockSettings(
        familyId,
        childId,
        SmartLockSettingsModel(isEnabled: false),
      )),
      expect: () => [
        isA<SmartLockActionSuccess>(),
        isA<SmartLockSettingsLoaded>()
            .having((s) => s.settings.isEnabled, 'isEnabled', false),
      ],
    );

    blocTest<SmartLockBloc, SmartLockState>(
      'emits [SmartLockError, SmartLockSettingsLoaded] when SaveSmartLockSettings fails',
      build: () {
        when(() => mockRepository.saveSmartLockSettings(familyId, childId, any()))
            .thenThrow(Exception('Firestore error'));
        return bloc;
      },
      act: (bloc) => bloc.add(const SaveSmartLockSettings(
        familyId,
        childId,
        SmartLockSettingsModel(),
      )),
      expect: () => [
        isA<SmartLockError>(),
        isA<SmartLockSettingsLoaded>(),
      ],
    );

    // Lock History tests

    blocTest<SmartLockBloc, SmartLockState>(
      'emits [SmartLockLoading, LockHistoryLoaded] when LoadLockHistory succeeds',
      build: () {
        when(() => mockRepository.getLockHistory(familyId, childId))
            .thenAnswer((_) async => [
                  LockHistoryEntryModel(
                    id: 'entry1',
                    appPackageName: 'com.tiktok',
                    appName: 'TikTok',
                    reason: 'time_limit',
                    lockedAt: DateTime(2026, 5, 16, 10),
                  ),
                ]);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadLockHistory(familyId, childId)),
      expect: () => [
        isA<SmartLockLoading>(),
        isA<LockHistoryLoaded>()
            .having((s) => s.history.length, 'history count', 1),
      ],
    );

    blocTest<SmartLockBloc, SmartLockState>(
      'emits [SmartLockError] when LoadLockHistory fails',
      build: () {
        when(() => mockRepository.getLockHistory(familyId, childId))
            .thenThrow(Exception('Firestore error'));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadLockHistory(familyId, childId)),
      expect: () => [
        isA<SmartLockLoading>(),
        isA<SmartLockError>(),
      ],
    );
  });
}
