import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/app_monitor_bloc.dart';
import 'package:kidguardian/domain/entities/usage_log.dart';
import 'package:kidguardian/domain/usecases/smart_lock/check_app_access_usecase.dart';
import 'package:kidguardian/domain/usecases/smart_lock/block_app_usecase.dart';
import 'package:kidguardian/domain/usecases/smart_lock/schedule_checker.dart';
import 'package:kidguardian/domain/repositories/usage_repository.dart';
import 'package:kidguardian/data/repositories/smart_lock_repository.dart';
import 'package:kidguardian/data/models/monitored_app_model.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';

class MockCheckAppAccessUseCase extends Mock implements CheckAppAccessUseCase {}
class MockBlockAppUseCase extends Mock implements BlockAppUseCase {}
class MockUsageRepository extends Mock implements UsageRepository {}
class MockSmartLockRepository extends Mock implements SmartLockRepository {}
class MockScheduleChecker extends Mock implements ScheduleChecker {}
class MockAlertRepository extends Mock implements AlertRepository {}
class FakeUsageLog extends Fake implements UsageLog {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppMonitorBloc bloc;
  late MockCheckAppAccessUseCase mockCheckAppAccessUseCase;
  late MockBlockAppUseCase mockBlockAppUseCase;
  late MockUsageRepository mockUsageRepository;
  late MockSmartLockRepository mockSmartLockRepository;
  late MockScheduleChecker mockScheduleChecker;
  late MockAlertRepository mockAlertRepository;

  setUpAll(() {
    registerFallbackValue(FakeUsageLog());
  });

  setUp(() {
    mockCheckAppAccessUseCase = MockCheckAppAccessUseCase();
    mockBlockAppUseCase = MockBlockAppUseCase();
    mockUsageRepository = MockUsageRepository();
    mockSmartLockRepository = MockSmartLockRepository();
    mockScheduleChecker = MockScheduleChecker();
    mockAlertRepository = MockAlertRepository();

    const MethodChannel channel = MethodChannel('com.kidguardian/accessibility');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getAndClearOfflineUsageLogs') {
        return [];
      }
      return null;
    });

    when(() => mockAlertRepository.watchKeywords(any()))
        .thenAnswer((_) => Stream.value([]));
    when(() => mockSmartLockRepository.getMonitoredApps(any(), any()))
        .thenAnswer((_) async => []);
    when(() => mockSmartLockRepository.getSmartLockSettings(any(), any()))
        .thenAnswer((_) async => null);
    when(() => mockSmartLockRepository.getSchedules(any(), any()))
        .thenAnswer((_) async => []);
    // BUG-4 FIX: Stub watchTimeLimits — required after _timeLimitsSubscription added
    when(() => mockSmartLockRepository.watchTimeLimits(any(), any()))
        .thenAnswer((_) => Stream.value([]));

    bloc = AppMonitorBloc(
      checkAppAccessUseCase: mockCheckAppAccessUseCase,
      blockAppUseCase: mockBlockAppUseCase,
      usageRepository: mockUsageRepository,
      smartLockRepository: mockSmartLockRepository,
      scheduleChecker: mockScheduleChecker,
      alertRepository: mockAlertRepository,
    );
  });

  group('AppMonitorBloc - Edge Cases & Resilience Tests', () {
    test('Open-by-default when monitoredApps is empty: logs user app but ignores system app', () async {
      when(() => mockSmartLockRepository.getMonitoredApps(any(), any()))
          .thenAnswer((_) async => []);
      when(() => mockCheckAppAccessUseCase.execute(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
            appPackageName: any(named: 'appPackageName'),
          )).thenAnswer((_) async => true);
      when(() => mockUsageRepository.logUsage(any())).thenAnswer((_) async {});

      bloc.add(const StartMonitoring('family1', 'child1'));
      await Future.delayed(const Duration(milliseconds: 50));

      // Trigger app event for user app (e.g. YouTube)
      bloc.add(const AppEventReceived({
        'type': 'app_event',
        'eventType': 'opened',
        'packageName': 'com.google.android.youtube',
      }));
      await Future.delayed(const Duration(seconds: 6));

      // Close user app after 6 seconds
      bloc.add(const AppEventReceived({
        'type': 'app_event',
        'eventType': 'closed',
        'packageName': 'com.google.android.youtube',
      }));
      await Future.delayed(const Duration(milliseconds: 50));

      // System app event should be ignored
      bloc.add(const AppEventReceived({
        'type': 'app_event',
        'eventType': 'opened',
        'packageName': 'com.android.settings',
      }));
      await Future.delayed(const Duration(milliseconds: 50));

      verify(() => mockUsageRepository.logUsage(any())).called(1);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('Handles malformed and invalid JSON offline logs gracefully without throwing exception', () async {
      const MethodChannel channel = MethodChannel('com.kidguardian/accessibility');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getAndClearOfflineUsageLogs') {
          return [
            jsonEncode({
              'packageName': 'com.google.android.youtube',
              'startTime': DateTime.now().millisecondsSinceEpoch - 60000,
              'endTime': DateTime.now().millisecondsSinceEpoch,
              'durationSeconds': 60,
            }),
            jsonEncode({
              'packageName': 'com.android.systemui', // system app -> skip
              'startTime': DateTime.now().millisecondsSinceEpoch - 60000,
              'endTime': DateTime.now().millisecondsSinceEpoch,
              'durationSeconds': 60,
            }),
            'INVALID_NOT_JSON_STRING', // malformed item
          ];
        }
        return null;
      });

      when(() => mockUsageRepository.logUsage(any())).thenAnswer((_) async {});

      bloc.add(const StartMonitoring('family1', 'child1'));
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify logUsage was called for the valid user app log without crashing on invalid string
      verify(() => mockUsageRepository.logUsage(any())).called(1);
    });

    test('Monitored apps whitelist filtering: ignores app set to isMonitored=false', () async {
      when(() => mockSmartLockRepository.getMonitoredApps(any(), any()))
          .thenAnswer((_) async => const [
                MonitoredAppModel(
                  appPackageName: 'com.allowed.app',
                  appName: 'Allowed App',
                  isMonitored: true,
                ),
                MonitoredAppModel(
                  appPackageName: 'com.forbidden.app',
                  appName: 'Forbidden App',
                  isMonitored: false,
                ),
              ]);
      when(() => mockCheckAppAccessUseCase.execute(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
            appPackageName: any(named: 'appPackageName'),
          )).thenAnswer((_) async => true);
      when(() => mockUsageRepository.logUsage(any())).thenAnswer((_) async {});

      bloc.add(const StartMonitoring('family1', 'child1'));
      await Future.delayed(const Duration(milliseconds: 50));

      // Event for forbidden app should not trigger logUsage
      bloc.add(const AppEventReceived({
        'type': 'app_event',
        'eventType': 'opened',
        'packageName': 'com.forbidden.app',
      }));
      await Future.delayed(const Duration(seconds: 6));
      bloc.add(const AppEventReceived({
        'type': 'app_event',
        'eventType': 'closed',
        'packageName': 'com.forbidden.app',
      }));
      await Future.delayed(const Duration(milliseconds: 50));

      verifyNever(() => mockUsageRepository.logUsage(any()));
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
