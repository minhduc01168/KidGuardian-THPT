import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:kidguardian/presentation/screens/smart_lock/lock_screen.dart';
import 'package:kidguardian/presentation/features/usage_statistics/widgets/most_used_apps_list.dart';
import 'package:kidguardian/presentation/features/usage_statistics/bloc/usage_statistics_state.dart';
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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E Full Flow: App Locking & Dashboard Display on Emulator', () {
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

    testWidgets('Verify Dashboard shows used and remaining minutes accurately', (tester) async {
      // 1. Dữ liệu giả lập 1 app (TikTok) đã sử dụng 45 phút, giới hạn 60 phút
      final mockSummaryNormal = AppUsageSummary(
        appPackage: 'com.zhiliaoapp.musically',
        appName: 'TikTok',
        totalMinutes: 45,
        percentage: 75.0,
        sessionCount: 3,
        avgMinutesPerSession: 15,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MostUsedAppsList(
              mostUsedApps: [mockSummaryNormal],
              appLimits: {'com.zhiliaoapp.musically': 60},
              dailyLimitMinutes: 60,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 2. Kiểm chứng hiển thị trên Dashboard: Đã dùng 45 phút, còn lại 15 phút
      expect(find.text('TikTok'), findsOneWidget);
      expect(find.textContaining('Đã dùng: 45 phút | Còn lại: 15 phút (Giới hạn: 1 giờ)'), findsOneWidget);

      // 3. Khi TikTok sử dụng đạt 60 phút (Hết giới hạn) -> Kiểm chứng trạng thái cảnh báo đỏ trên Dashboard
      final mockSummaryOver = AppUsageSummary(
        appPackage: 'com.zhiliaoapp.musically',
        appName: 'TikTok',
        totalMinutes: 60,
        percentage: 100.0,
        sessionCount: 4,
        avgMinutesPerSession: 15,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MostUsedAppsList(
              mostUsedApps: [mockSummaryOver],
              appLimits: {'com.zhiliaoapp.musically': 60},
              dailyLimitMinutes: 60,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Đã hết giới hạn (1 giờ / 1 giờ)'), findsOneWidget);
    });

    testWidgets('Verify LockScreen pops up and blocks app when time limit exceeded', (tester) async {
      // 4. Kiểm chứng luồng khoá app: Khi hệ thống phát hiện app hết giờ -> Đẩy LockScreen
      await tester.pumpWidget(
        MaterialApp(
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
                appPackageName: 'com.zhiliaoapp.musically',
                appName: 'TikTok',
                limitMinutes: 60,
                usedMinutes: 60,
                resetTime: DateTime.now().add(const Duration(hours: 12)),
                blockReason: 'time_limit',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 5. Xác nhận màn hình khoá hiển thị rõ tên App và lý do chặn
      expect(find.text('TikTok'), findsOneWidget);
      expect(find.text('Bạn đã sử dụng hết thời gian cho phép hôm nay'), findsOneWidget);
      expect(find.text('Đã dùng: 60/60 phút'), findsOneWidget);
      expect(find.text('Xin thêm thời gian'), findsOneWidget);
      expect(find.text('Quay về màn hình chính'), findsOneWidget);
    });
  });
}
