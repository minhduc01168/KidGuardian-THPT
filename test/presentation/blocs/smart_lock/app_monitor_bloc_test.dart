import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/services.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/app_monitor_bloc.dart';
import 'package:kidguardian/domain/usecases/smart_lock/check_app_access_usecase.dart';
import 'package:kidguardian/domain/usecases/smart_lock/block_app_usecase.dart';
import 'package:kidguardian/domain/repositories/usage_repository.dart';

class MockCheckAppAccessUseCase extends Mock implements CheckAppAccessUseCase {}
class MockBlockAppUseCase extends Mock implements BlockAppUseCase {}
class MockUsageRepository extends Mock implements UsageRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppMonitorBloc bloc;
  late MockCheckAppAccessUseCase mockCheckAppAccessUseCase;
  late MockBlockAppUseCase mockBlockAppUseCase;
  late MockUsageRepository mockUsageRepository;

  setUp(() {
    mockCheckAppAccessUseCase = MockCheckAppAccessUseCase();
    mockBlockAppUseCase = MockBlockAppUseCase();
    mockUsageRepository = MockUsageRepository();

    bloc = AppMonitorBloc(
      checkAppAccessUseCase: mockCheckAppAccessUseCase,
      blockAppUseCase: mockBlockAppUseCase,
      usageRepository: mockUsageRepository,
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
}
