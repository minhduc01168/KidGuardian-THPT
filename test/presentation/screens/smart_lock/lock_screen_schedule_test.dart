import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:kidguardian/presentation/screens/smart_lock/lock_screen.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_bloc.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_event.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_state.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/app_monitor_bloc.dart';
import 'package:kidguardian/domain/repositories/time_request_repository.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';
import 'package:kidguardian/domain/repositories/rules_repository.dart';

class MockSmartLockBloc extends MockBloc<SmartLockEvent, SmartLockState> implements SmartLockBloc {}
class MockAppMonitorBloc extends MockBloc<AppMonitorEvent, AppMonitorState> implements AppMonitorBloc {}
class MockTimeRequestRepository extends Mock implements TimeRequestRepository {}
class MockAlertRepository extends Mock implements AlertRepository {}
class MockRulesRepository extends Mock implements RulesRepository {}

void main() {
  late MockSmartLockBloc mockSmartLockBloc;
  late MockAppMonitorBloc mockAppMonitorBloc;
  late MockTimeRequestRepository mockTimeRequestRepository;
  late MockAlertRepository mockAlertRepository;
  late MockRulesRepository mockRulesRepository;

  setUp(() {
    mockSmartLockBloc = MockSmartLockBloc();
    mockAppMonitorBloc = MockAppMonitorBloc();
    mockTimeRequestRepository = MockTimeRequestRepository();
    mockAlertRepository = MockAlertRepository();
    mockRulesRepository = MockRulesRepository();

    when(() => mockSmartLockBloc.state).thenReturn(SmartLockInitial());
    when(() => mockAppMonitorBloc.state).thenReturn(AppMonitorInitial());
  });

  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      home: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<TimeRequestRepository>(create: (_) => mockTimeRequestRepository),
          RepositoryProvider<AlertRepository>(create: (_) => mockAlertRepository),
          RepositoryProvider<RulesRepository>(create: (_) => mockRulesRepository),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<SmartLockBloc>.value(value: mockSmartLockBloc),
            BlocProvider<AppMonitorBloc>.value(value: mockAppMonitorBloc),
          ],
          child: child,
        ),
      ),
    );
  }

  group('LockScreen - Schedule block reason', () {
    testWidgets('should show schedule reason when blockReason is schedule', (tester) async {
      final resetTime = DateTime.now().add(const Duration(hours: 8));

      await tester.pumpWidget(
        buildTestWidget(
          LockScreen(
            appPackageName: 'com.test.app',
            appName: 'TikTok',
            limitMinutes: 0,
            usedMinutes: 0,
            resetTime: resetTime,
            blockReason: 'schedule',
            scheduleName: 'Giờ ngủ',
          ),
        ),
      );

      expect(find.text('Đang trong giờ ngủ'), findsOneWidget);
    });

    testWidgets('should show homework schedule reason', (tester) async {
      final resetTime = DateTime.now().add(const Duration(hours: 3));

      await tester.pumpWidget(
        buildTestWidget(
          LockScreen(
            appPackageName: 'com.test.app',
            appName: 'TikTok',
            limitMinutes: 0,
            usedMinutes: 0,
            resetTime: resetTime,
            blockReason: 'schedule',
            scheduleName: 'Giờ học bài',
          ),
        ),
      );

      expect(find.text('Đang trong giờ học bài'), findsOneWidget);
    });

    testWidgets('should show time limit reason when blockReason is time_limit', (tester) async {
      final resetTime = DateTime.now().add(const Duration(hours: 6));

      await tester.pumpWidget(
        buildTestWidget(
          LockScreen(
            appPackageName: 'com.test.app',
            appName: 'TikTok',
            limitMinutes: 60,
            usedMinutes: 60,
            resetTime: resetTime,
            blockReason: 'time_limit',
          ),
        ),
      );

      expect(find.text('Bạn đã sử dụng hết thời gian cho phép hôm nay'), findsOneWidget);
    });

    testWidgets('should show time limit reason when blockReason is null (backward compat)', (tester) async {
      final resetTime = DateTime.now().add(const Duration(hours: 6));

      await tester.pumpWidget(
        buildTestWidget(
          LockScreen(
            appPackageName: 'com.test.app',
            appName: 'TikTok',
            limitMinutes: 60,
            usedMinutes: 60,
            resetTime: resetTime,
          ),
        ),
      );

      expect(find.text('Bạn đã sử dụng hết thời gian cho phép hôm nay'), findsOneWidget);
    });

    testWidgets('should not show request time button for schedule blocks', (tester) async {
      final resetTime = DateTime.now().add(const Duration(hours: 8));

      await tester.pumpWidget(
        buildTestWidget(
          LockScreen(
            appPackageName: 'com.test.app',
            appName: 'TikTok',
            limitMinutes: 0,
            usedMinutes: 0,
            resetTime: resetTime,
            blockReason: 'schedule',
            scheduleName: 'Giờ ngủ',
          ),
        ),
      );

      expect(find.text('Xin thêm thời gian'), findsNothing);
    });
  });
}
