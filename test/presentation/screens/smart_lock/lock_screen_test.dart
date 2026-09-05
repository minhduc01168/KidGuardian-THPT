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

  // Use a reset time in the future to ensure countdown is displayed
  final resetTime = DateTime.now().add(const Duration(hours: 2));

  Widget buildLockScreen({
    String appName = 'TikTok',
    String appPackageName = 'com.zhiliaoapp.musically',
    String? iconUrl,
    int limitMinutes = 60,
    int usedMinutes = 60,
  }) {
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
          child: LockScreen(
            appPackageName: appPackageName,
            appName: appName,
            iconUrl: iconUrl,
            limitMinutes: limitMinutes,
            usedMinutes: usedMinutes,
            resetTime: resetTime,
          ),
        ),
      ),
    );
  }

  group('LockScreen', () {
    testWidgets('displays app name instead of package name', (tester) async {
      await tester.pumpWidget(buildLockScreen(appName: 'TikTok'));
      expect(find.text('TikTok'), findsOneWidget);
      expect(find.text('com.zhiliaoapp.musically'), findsNothing);
    });

    testWidgets('displays block reason message', (tester) async {
      await tester.pumpWidget(buildLockScreen());
      expect(
        find.text('Bạn đã sử dụng hết thời gian cho phép hôm nay'),
        findsOneWidget,
      );
    });

    testWidgets('displays usage stats', (tester) async {
      await tester.pumpWidget(buildLockScreen(
        limitMinutes: 60,
        usedMinutes: 45,
      ));
      expect(find.text('Đã dùng: 45/60 phút'), findsOneWidget);
    });

    testWidgets('displays countdown timer widget', (tester) async {
      await tester.pumpWidget(buildLockScreen());
      expect(find.textContaining('Còn lại:'), findsOneWidget);
    });

    testWidgets('displays "Quay về màn hình chính" button', (tester) async {
      await tester.pumpWidget(buildLockScreen());
      expect(find.text('Quay về màn hình chính'), findsOneWidget);
    });

    testWidgets('displays "Xin thêm thời gian" button', (tester) async {
      await tester.pumpWidget(buildLockScreen());
      expect(find.text('Xin thêm thời gian'), findsOneWidget);
    });

    testWidgets('displays "Liên hệ khẩn cấp" button', (tester) async {
      await tester.pumpWidget(buildLockScreen());
      expect(find.text('Liên hệ khẩn cấp'), findsOneWidget);
    });

    testWidgets('PopScope prevents back navigation', (tester) async {
      await tester.pumpWidget(buildLockScreen());
      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, isFalse);
    });

    testWidgets('lock screen uses gradient background', (tester) async {
      await tester.pumpWidget(buildLockScreen());
      expect(find.byType(LinearGradient), findsNothing);
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(SafeArea),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.gradient, isA<LinearGradient>());
    });
  });
}
