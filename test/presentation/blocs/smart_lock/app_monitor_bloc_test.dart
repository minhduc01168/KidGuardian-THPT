import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/app_monitor_bloc.dart';
import 'package:kidguardian/domain/usecases/smart_lock/check_app_access_usecase.dart';
import 'package:kidguardian/domain/usecases/smart_lock/block_app_usecase.dart';
import 'package:kidguardian/domain/usecases/smart_lock/schedule_checker.dart';
import 'package:kidguardian/domain/repositories/usage_repository.dart';
import 'package:kidguardian/data/repositories/smart_lock_repository.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';

class MockCheckAppAccessUseCase extends Mock implements CheckAppAccessUseCase {}
class MockBlockAppUseCase extends Mock implements BlockAppUseCase {}
class MockUsageRepository extends Mock implements UsageRepository {}
class MockSmartLockRepository extends Mock implements SmartLockRepository {}
class MockScheduleChecker extends Mock implements ScheduleChecker {}
class MockAlertRepository extends Mock implements AlertRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppMonitorBloc bloc;
  late MockCheckAppAccessUseCase mockCheckAppAccessUseCase;
  late MockBlockAppUseCase mockBlockAppUseCase;
  late MockUsageRepository mockUsageRepository;
  late MockSmartLockRepository mockSmartLockRepository;
  late MockScheduleChecker mockScheduleChecker;
  late MockAlertRepository mockAlertRepository;

  setUp(() {
    mockCheckAppAccessUseCase = MockCheckAppAccessUseCase();
    mockBlockAppUseCase = MockBlockAppUseCase();
    mockUsageRepository = MockUsageRepository();
    mockSmartLockRepository = MockSmartLockRepository();
    mockScheduleChecker = MockScheduleChecker();
    mockAlertRepository = MockAlertRepository();

    bloc = AppMonitorBloc(
      checkAppAccessUseCase: mockCheckAppAccessUseCase,
      blockAppUseCase: mockBlockAppUseCase,
      usageRepository: mockUsageRepository,
      smartLockRepository: mockSmartLockRepository,
      scheduleChecker: mockScheduleChecker,
      alertRepository: mockAlertRepository,
    );
  });

  tearDown(() {
    // bloc.close(); // avoid channel issues
  });

  group('AppMonitorBloc', () {
    test('initial state is AppMonitorInitial', () {
      expect(bloc.state, AppMonitorInitial());
    });

    test('emits AppMonitorRunning when StartMonitoring is added', () {
      bloc.add(StartMonitoring('family1', 'child1'));
      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AppMonitorRunning>(),
        ]),
      );
    }, skip: true);

    test('emits AppBlockedState when app_blocked event is received', () {
      when(() => mockSmartLockRepository.getAppTimeLimits(any(), any()))
          .thenAnswer((_) async => []);
      when(() => mockUsageRepository.getUsageByApp(any(), any()))
          .thenAnswer((_) async => {});

      bloc.add(AppEventReceived({
        'type': 'app_blocked',
        'packageName': 'com.test.app',
      }));

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AppBlockedState>(),
        ]),
      );
    });
  });

  group('AppBlockedState extended fields', () {
    test('AppBlockedState contains all required fields', () {
      final now = DateTime.now();
      final resetTime = DateTime(now.year, now.month, now.day + 1);
      final state = AppBlockedState(
        appPackageName: 'com.zhiliaoapp.musically',
        appName: 'TikTok',
        iconUrl: null,
        limitMinutes: 60,
        usedMinutes: 60,
        resetTime: resetTime,
      );

      expect(state.appPackageName, 'com.zhiliaoapp.musically');
      expect(state.appName, 'TikTok');
      expect(state.iconUrl, isNull);
      expect(state.limitMinutes, 60);
      expect(state.usedMinutes, 60);
      expect(state.resetTime, resetTime);
    });

    test('AppBlockedState with iconUrl', () {
      final now = DateTime.now();
      final resetTime = DateTime(now.year, now.month, now.day + 1);
      final state = AppBlockedState(
        appPackageName: 'com.zhiliaoapp.musically',
        appName: 'TikTok',
        iconUrl: 'https://example.com/icon.png',
        limitMinutes: 30,
        usedMinutes: 30,
        resetTime: resetTime,
      );

      expect(state.iconUrl, 'https://example.com/icon.png');
    });

    test('AppBlockedState props include all fields for equality', () {
      final now = DateTime.now();
      final resetTime = DateTime(now.year, now.month, now.day + 1);
      final state1 = AppBlockedState(
        appPackageName: 'com.test.app',
        appName: 'TestApp',
        limitMinutes: 60,
        usedMinutes: 45,
        resetTime: resetTime,
      );
      final state2 = AppBlockedState(
        appPackageName: 'com.test.app',
        appName: 'TestApp',
        limitMinutes: 60,
        usedMinutes: 45,
        resetTime: resetTime,
      );

      expect(state1, equals(state2));
      expect(state1.props.length, 11);
    });

    test('AppBlockedState equality with different usedMinutes', () {
      final now = DateTime.now();
      final resetTime = DateTime(now.year, now.month, now.day + 1);
      final state1 = AppBlockedState(
        appPackageName: 'com.test.app',
        appName: 'TestApp',
        limitMinutes: 60,
        usedMinutes: 45,
        resetTime: resetTime,
      );
      final state2 = AppBlockedState(
        appPackageName: 'com.test.app',
        appName: 'TestApp',
        limitMinutes: 60,
        usedMinutes: 60,
        resetTime: resetTime,
      );

      expect(state1, isNot(equals(state2)));
    });
  });

  group('AppBlockedState - blockReason', () {
    test('AppBlockedState with time_limit blockReason', () {
      final now = DateTime.now();
      final resetTime = DateTime(now.year, now.month, now.day + 1);
      final state = AppBlockedState(
        appPackageName: 'com.test.app',
        appName: 'TestApp',
        limitMinutes: 60,
        usedMinutes: 60,
        resetTime: resetTime,
        blockReason: 'time_limit',
      );

      expect(state.blockReason, 'time_limit');
    });

    test('AppBlockedState with schedule blockReason', () {
      final now = DateTime.now();
      final resetTime = DateTime(now.year, now.month, now.day + 1);
      final state = AppBlockedState(
        appPackageName: 'com.test.app',
        appName: 'TestApp',
        limitMinutes: 0,
        usedMinutes: 0,
        resetTime: resetTime,
        blockReason: 'schedule',
        scheduleName: 'Giờ ngủ',
      );

      expect(state.blockReason, 'schedule');
      expect(state.scheduleName, 'Giờ ngủ');
    });

    test('AppBlockedState default blockReason is null', () {
      final now = DateTime.now();
      final resetTime = DateTime(now.year, now.month, now.day + 1);
      final state = AppBlockedState(
        appPackageName: 'com.test.app',
        appName: 'TestApp',
        limitMinutes: 60,
        usedMinutes: 60,
        resetTime: resetTime,
      );

      expect(state.blockReason, isNull);
    });

    test('AppBlockedState props include blockReason and scheduleName', () {
      final now = DateTime.now();
      final resetTime = DateTime(now.year, now.month, now.day + 1);
      final state1 = AppBlockedState(
        appPackageName: 'com.test.app',
        appName: 'TestApp',
        limitMinutes: 60,
        usedMinutes: 60,
        resetTime: resetTime,
        blockReason: 'schedule',
        scheduleName: 'Giờ ngủ',
      );
      final state2 = AppBlockedState(
        appPackageName: 'com.test.app',
        appName: 'TestApp',
        limitMinutes: 60,
        usedMinutes: 60,
        resetTime: resetTime,
        blockReason: 'schedule',
        scheduleName: 'Giờ học bài',
      );

      expect(state1, isNot(equals(state2)));
    });

    test('should save keyword alert to AlertRepository when KeywordDetectedEvent is added', () async {
      when(() => mockSmartLockRepository.getSmartLockSettings(any(), any()))
          .thenAnswer((_) async => null);
      when(() => mockAlertRepository.createKeywordAlert(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
            keyword: any(named: 'keyword'),
            packageName: any(named: 'packageName'),
            textContext: any(named: 'textContext'),
          )).thenAnswer((_) async {});

      // Start monitoring to set familyId and childUid
      bloc.add(const StartMonitoring('family1', 'child1'));
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(const KeywordDetectedEvent(
        keyword: 'tự tử',
        packageName: 'com.test.app',
        textContext: 'tôi muốn tự tử',
      ));
      
      await Future.delayed(const Duration(milliseconds: 100));

      verify(() => mockAlertRepository.createKeywordAlert(
            familyId: 'family1',
            childUid: 'child1',
            keyword: 'tự tử',
            packageName: 'com.test.app',
            textContext: 'tôi muốn tự tử',
          )).called(1);
    });
  });
}
