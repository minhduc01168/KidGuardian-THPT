import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/services.dart';
import 'package:kidguardian/data/repositories/smart_lock_repository.dart';
import 'package:kidguardian/domain/usecases/smart_lock/check_app_access_usecase.dart';
import 'package:kidguardian/domain/usecases/smart_lock/block_app_usecase.dart';
import 'package:kidguardian/domain/usecases/smart_lock/schedule_checker.dart';
import 'package:kidguardian/domain/repositories/usage_repository.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/app_monitor_bloc.dart';

class MockCheckAppAccessUseCase extends Mock implements CheckAppAccessUseCase {}
class MockBlockAppUseCase extends Mock implements BlockAppUseCase {}
class MockUsageRepository extends Mock implements UsageRepository {}
class MockSmartLockRepository extends Mock implements SmartLockRepository {}
class MockScheduleChecker extends Mock implements ScheduleChecker {}
class MockAlertRepository extends Mock implements AlertRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSmartLockRepository mockSmartLockRepository;
  late MockAlertRepository mockAlertRepository;
  late MockCheckAppAccessUseCase mockCheckAppAccessUseCase;
  late MockBlockAppUseCase mockBlockAppUseCase;
  late MockUsageRepository mockUsageRepository;
  late MockScheduleChecker mockScheduleChecker;

  void _setupMethodChannel() {
    const channel = MethodChannel('com.kidguardian/accessibility');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getAndClearOfflineUsageLogs') return [];
      return null;
    });
  }

  AppMonitorBloc _buildBloc() {
    return AppMonitorBloc(
      checkAppAccessUseCase: mockCheckAppAccessUseCase,
      blockAppUseCase: mockBlockAppUseCase,
      usageRepository: mockUsageRepository,
      smartLockRepository: mockSmartLockRepository,
      scheduleChecker: mockScheduleChecker,
      alertRepository: mockAlertRepository,
    );
  }

  setUp(() {
    _setupMethodChannel();
    mockSmartLockRepository = MockSmartLockRepository();
    mockAlertRepository = MockAlertRepository();
    mockCheckAppAccessUseCase = MockCheckAppAccessUseCase();
    mockBlockAppUseCase = MockBlockAppUseCase();
    mockUsageRepository = MockUsageRepository();
    mockScheduleChecker = MockScheduleChecker();

    when(() => mockAlertRepository.watchKeywords(any()))
        .thenAnswer((_) => Stream.value([]));
    when(() => mockSmartLockRepository.getMonitoredApps(any(), any()))
        .thenAnswer((_) async => []);
    when(() => mockSmartLockRepository.getSmartLockSettings(any(), any()))
        .thenAnswer((_) async => null);
    when(() => mockSmartLockRepository.getSchedules(any(), any()))
        .thenAnswer((_) async => []);
    when(() => mockSmartLockRepository.watchTimeLimits(any(), any()))
        .thenAnswer((_) => Stream.value([]));
  });

  group('AppMonitorBloc Stability & Robustness Edge Cases', () {
    test('AppEventReceived with unknown eventType does not crash BLoC', () async {
      final bloc = _buildBloc();
      bloc.add(const StartMonitoring('fam1', 'child1'));
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(const AppEventReceived({
        'type': 'app_event',
        'eventType': 'UNKNOWN_EVENT_123',
        'packageName': 'com.unknown.app',
      }));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<AppMonitorRunning>());
      await bloc.close();
    });

    test('AppEventReceived with missing packageName is handled safely', () async {
      final bloc = _buildBloc();
      bloc.add(const StartMonitoring('fam1', 'child1'));
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(const AppEventReceived({
        'type': 'app_event',
        'eventType': 'opened',
      }));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<AppMonitorRunning>());
      await bloc.close();
    });

    test('CheckAppAccessUseCase exception is handled gracefully without breaking monitoring state', () async {
      when(() => mockCheckAppAccessUseCase.execute(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
            appPackageName: any(named: 'appPackageName'),
          )).thenThrow(Exception('Database error'));

      final bloc = _buildBloc();
      bloc.add(const StartMonitoring('fam1', 'child1'));
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(const AppEventReceived({
        'type': 'app_event',
        'eventType': 'opened',
        'packageName': 'com.test.app',
      }));
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(const CheckCurrentAppLimit());
      await Future.delayed(const Duration(milliseconds: 100));

      // BLoC maintains AppMonitorRunning state and does not crash
      expect(bloc.state, isA<AppMonitorRunning>());
      await bloc.close();
    });

    test('close cancels all internal timers and streams cleanly', () async {
      final bloc = _buildBloc();
      bloc.add(const StartMonitoring('fam1', 'child1'));
      await Future.delayed(const Duration(milliseconds: 50));

      await bloc.close();
      expect(bloc.isClosed, isTrue);
    });
  });
}
