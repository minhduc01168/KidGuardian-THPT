import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:kidguardian/presentation/features/dashboard/screens/child_dashboard.dart';
import 'package:kidguardian/presentation/features/dashboard/screens/parent_dashboard.dart';
import 'package:kidguardian/presentation/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:kidguardian/presentation/features/dashboard/bloc/dashboard_event.dart';
import 'package:kidguardian/presentation/features/dashboard/bloc/dashboard_state.dart';
import 'package:kidguardian/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:kidguardian/presentation/features/auth/bloc/auth_event.dart';
import 'package:kidguardian/presentation/features/auth/bloc/auth_state.dart';
import 'package:kidguardian/presentation/blocs/in_app_notification/in_app_notification_bloc.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_bloc.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_event.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_state.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/app_monitor_bloc.dart';
import 'package:kidguardian/data/models/app_time_limit_model.dart';
import 'package:kidguardian/presentation/features/help/bloc/help_bloc.dart';
import 'package:kidguardian/presentation/features/help/bloc/help_event.dart';
import 'package:kidguardian/presentation/features/help/bloc/help_state.dart';
import 'package:kidguardian/domain/entities/user.dart';
import 'package:kidguardian/domain/entities/usage_log.dart';
import 'package:kidguardian/domain/repositories/family_repository.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}
class MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState> implements DashboardBloc {}
class MockInAppNotificationBloc extends MockBloc<InAppNotificationEvent, InAppNotificationState> implements InAppNotificationBloc {}
class MockSmartLockBloc extends MockBloc<SmartLockEvent, SmartLockState> implements SmartLockBloc {}
class MockAppMonitorBloc extends MockBloc<AppMonitorEvent, AppMonitorState> implements AppMonitorBloc {}
class MockHelpBloc extends MockBloc<HelpEvent, HelpState> implements HelpBloc {}
class MockFamilyRepository extends Mock implements FamilyRepository {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E Dashboard UI/UX Verification on Emulator', () {
    late MockAuthBloc mockAuthBloc;
    late MockDashboardBloc mockDashboardBloc;
    late MockInAppNotificationBloc mockInAppNotificationBloc;
    late MockSmartLockBloc mockSmartLockBloc;
    late MockAppMonitorBloc mockAppMonitorBloc;
    late MockHelpBloc mockHelpBloc;
    late MockFamilyRepository mockFamilyRepository;

    final now = DateTime.now();
    final mockChildUser = User(
      uid: 'child123',
      email: 'child@test.com',
      displayName: 'Bé Minh',
      role: UserRole.child,
      familyId: 'fam123',
      createdAt: now,
    );

    final mockParentUser = User(
      uid: 'parent123',
      email: 'parent@test.com',
      displayName: 'Bố Minh',
      role: UserRole.parent,
      familyId: 'fam123',
      createdAt: now,
    );

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      mockDashboardBloc = MockDashboardBloc();
      mockInAppNotificationBloc = MockInAppNotificationBloc();
      mockSmartLockBloc = MockSmartLockBloc();
      mockAppMonitorBloc = MockAppMonitorBloc();
      mockHelpBloc = MockHelpBloc();
      mockFamilyRepository = MockFamilyRepository();

      when(() => mockInAppNotificationBloc.state).thenReturn(InAppNotificationInitial());
      when(() => mockSmartLockBloc.state).thenReturn(SmartLockInitial());
      when(() => mockAppMonitorBloc.state).thenReturn(AppMonitorInitial());
      when(() => mockHelpBloc.state).thenReturn(HelpInitial());
      when(() => mockFamilyRepository.getFamily(any())).thenAnswer((_) async => null);
    });

    testWidgets('Verify ChildDashboard renders normalized app names, PieChart Legend, and over-limit warnings', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(user: mockChildUser));
      final loadedState = SmartLockLoaded([
        AppTimeLimitModel(
          appPackageName: 'com.zhiliaoapp.musically',
          appName: 'TikTok',
          limits: {'everyday': 60, 'sunday': 60, 'monday': 60, 'tuesday': 60, 'wednesday': 60, 'thursday': 60, 'friday': 60, 'saturday': 60},
        ),
      ]);
      when(() => mockSmartLockBloc.state).thenReturn(loadedState);
      whenListen(
        mockSmartLockBloc,
        Stream.fromIterable([loadedState]),
        initialState: loadedState,
      );
      when(() => mockDashboardBloc.state).thenReturn(DashboardLoaded(
        totalMinutesToday: 90,
        totalMinutesYesterday: 60,
        usageByApp: {
          'TikTok': 60,
          'Facebook': 30,
        },
        recentLogs: [
          UsageLog(
            docId: 'doc1',
            childUid: 'child123',
            familyId: 'fam123',
            appPackage: 'com.zhiliaoapp.musically',
            appName: 'TikTok',
            startTime: now,
            endTime: now,
            durationMinutes: 60,
            date: '2026-07-12',
          ),
        ],
        childUids: ['child123'],
        appTimeLimits: {
          'com.zhiliaoapp.musically': 60,
          'TikTok': 60,
          'com.facebook.katana': 120,
          'Facebook': 120,
        },
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<FamilyRepository>(create: (_) => mockFamilyRepository),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
                BlocProvider<DashboardBloc>.value(value: mockDashboardBloc),
                BlocProvider<InAppNotificationBloc>.value(value: mockInAppNotificationBloc),
                BlocProvider<SmartLockBloc>.value(value: mockSmartLockBloc),
                BlocProvider<AppMonitorBloc>.value(value: mockAppMonitorBloc),
                BlocProvider<HelpBloc>.value(value: mockHelpBloc),
              ],
              child: const ChildDashboard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to bring PieChart Legend and AppUsage list into view
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // Verify clean normalized app names
      expect(find.text('TikTok'), findsWidgets);
      expect(find.text('Facebook'), findsWidgets);

      // Verify Pie Chart & Legend section title
      expect(find.text('Ứng dụng đã sử dụng'), findsOneWidget);

      // Verify red over-limit warning on TikTok
      expect(find.textContaining('Đã hết giờ (60 / 60 phút)'), findsOneWidget);
    });

    testWidgets('Verify ParentDashboard renders compact Recent Activity UI (max 5 items)', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(user: mockParentUser));
      when(() => mockDashboardBloc.state).thenReturn(DashboardLoaded(
        totalMinutesToday: 150,
        totalMinutesYesterday: 120,
        usageByApp: {
          'TikTok': 60,
          'YouTube': 50,
          'Zalo': 40,
        },
        recentLogs: [
          UsageLog(docId: 'doc1', childUid: 'c1', familyId: 'f1', appPackage: 'pkg1', appName: 'TikTok', startTime: now, endTime: now, durationMinutes: 30, date: '2026-07-12'),
          UsageLog(docId: 'doc2', childUid: 'c1', familyId: 'f1', appPackage: 'pkg2', appName: 'YouTube', startTime: now, endTime: now, durationMinutes: 20, date: '2026-07-12'),
          UsageLog(docId: 'doc3', childUid: 'c1', familyId: 'f1', appPackage: 'pkg3', appName: 'Zalo', startTime: now, endTime: now, durationMinutes: 15, date: '2026-07-12'),
          UsageLog(docId: 'doc4', childUid: 'c1', familyId: 'f1', appPackage: 'pkg4', appName: 'Roblox', startTime: now, endTime: now, durationMinutes: 10, date: '2026-07-12'),
          UsageLog(docId: 'doc5', childUid: 'c1', familyId: 'f1', appPackage: 'pkg5', appName: 'Facebook', startTime: now, endTime: now, durationMinutes: 5, date: '2026-07-12'),
          UsageLog(docId: 'doc6', childUid: 'c1', familyId: 'f1', appPackage: 'pkg6', appName: 'Instagram', startTime: now, endTime: now, durationMinutes: 3, date: '2026-07-12'),
        ],
        childUids: ['c1'],
        appTimeLimits: {},
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<FamilyRepository>(create: (_) => mockFamilyRepository),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
                BlocProvider<DashboardBloc>.value(value: mockDashboardBloc),
                BlocProvider<InAppNotificationBloc>.value(value: mockInAppNotificationBloc),
                BlocProvider<SmartLockBloc>.value(value: mockSmartLockBloc),
                BlocProvider<AppMonitorBloc>.value(value: mockAppMonitorBloc),
                BlocProvider<HelpBloc>.value(value: mockHelpBloc),
              ],
              child: const ParentDashboard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to bring Recent Activity into view
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -800));
      await tester.pumpAndSettle();

      // Verify compact Recent Activity section title
      expect(find.text('Hoạt động gần đây'), findsOneWidget);

      // Verify top 5 are rendered in the compact list
      expect(find.text('TikTok'), findsWidgets);
      expect(find.text('YouTube'), findsWidgets);
      expect(find.text('Zalo'), findsWidgets);
      expect(find.text('Roblox'), findsWidgets);
      expect(find.text('Facebook'), findsWidgets);

      // Verify 6th item is NOT rendered due to the compact max 5 limit
      expect(find.text('Instagram'), findsNothing);
    });
  });
}
