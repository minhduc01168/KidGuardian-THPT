import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/app_monitor_bloc.dart';
import 'package:kidguardian/domain/usecases/smart_lock/check_app_access_usecase.dart';
import 'package:kidguardian/domain/usecases/smart_lock/block_app_usecase.dart';
import 'package:kidguardian/domain/repositories/usage_repository.dart';
import 'package:kidguardian/data/repositories/smart_lock_repository.dart';

class MockCheckAppAccessUseCase extends Mock implements CheckAppAccessUseCase {}
class MockBlockAppUseCase extends Mock implements BlockAppUseCase {}
class MockUsageRepository extends Mock implements UsageRepository {}
class MockSmartLockRepository extends Mock implements SmartLockRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppMonitorBloc bloc;
  late MockCheckAppAccessUseCase mockCheckAppAccessUseCase;
  late MockBlockAppUseCase mockBlockAppUseCase;
  late MockUsageRepository mockUsageRepository;
  late MockSmartLockRepository mockSmartLockRepository;

  setUp(() {
    mockCheckAppAccessUseCase = MockCheckAppAccessUseCase();
    mockBlockAppUseCase = MockBlockAppUseCase();
    mockUsageRepository = MockUsageRepository();
    mockSmartLockRepository = MockSmartLockRepository();

    bloc = AppMonitorBloc(
      checkAppAccessUseCase: mockCheckAppAccessUseCase,
      blockAppUseCase: mockBlockAppUseCase,
      usageRepository: mockUsageRepository,
      smartLockRepository: mockSmartLockRepository,
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
      expect(state1.props.length, 8);
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
}
