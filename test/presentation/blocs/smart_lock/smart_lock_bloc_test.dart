import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/data/repositories/smart_lock_repository.dart';
import 'package:kidguardian/data/models/app_time_limit_model.dart';
import 'package:kidguardian/data/models/monitored_app_model.dart';
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
}
