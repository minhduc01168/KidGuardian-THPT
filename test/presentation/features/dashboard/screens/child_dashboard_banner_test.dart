import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:kidguardian/presentation/features/dashboard/screens/child_dashboard.dart';
import 'package:kidguardian/presentation/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:kidguardian/presentation/features/dashboard/bloc/dashboard_event.dart';
import 'package:kidguardian/presentation/features/dashboard/bloc/dashboard_state.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/app_monitor_bloc.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_bloc.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_event.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_state.dart';
import 'package:kidguardian/presentation/features/help/bloc/help_bloc.dart';
import 'package:kidguardian/presentation/features/help/bloc/help_event.dart';
import 'package:kidguardian/presentation/features/help/bloc/help_state.dart';
import 'package:kidguardian/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:kidguardian/presentation/features/auth/bloc/auth_event.dart';
import 'package:kidguardian/presentation/features/auth/bloc/auth_state.dart';
import 'package:kidguardian/domain/entities/user.dart';

class MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState> implements DashboardBloc {}
class MockAppMonitorBloc extends MockBloc<AppMonitorEvent, AppMonitorState> implements AppMonitorBloc {}
class MockSmartLockBloc extends MockBloc<SmartLockEvent, SmartLockState> implements SmartLockBloc {}
class MockHelpBloc extends MockBloc<HelpEvent, HelpState> implements HelpBloc {}
class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}
class MockUser extends Mock implements User {
  @override
  String get displayName => 'Test Child';
  @override
  String get uid => 'child1';
  @override
  String? get familyId => 'fam1';
  @override
  String get email => 'child@test.com';
}

void main() {
  late MockDashboardBloc dashboardBloc;
  late MockAppMonitorBloc appMonitorBloc;
  late MockSmartLockBloc smartLockBloc;
  late MockHelpBloc helpBloc;
  late MockAuthBloc authBloc;
  late MockUser mockUser;

  setUp(() {
    dashboardBloc = MockDashboardBloc();
    appMonitorBloc = MockAppMonitorBloc();
    smartLockBloc = MockSmartLockBloc();
    helpBloc = MockHelpBloc();
    authBloc = MockAuthBloc();
    mockUser = MockUser();
    
    when(() => appMonitorBloc.state).thenReturn(AppMonitorInitial());
    when(() => smartLockBloc.state).thenReturn(SmartLockInitial());
    when(() => helpBloc.state).thenReturn(HelpInitial());
    when(() => authBloc.state).thenReturn(AuthAuthenticated(user: mockUser));
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<DashboardBloc>.value(value: dashboardBloc),
          BlocProvider<AppMonitorBloc>.value(value: appMonitorBloc),
          BlocProvider<SmartLockBloc>.value(value: smartLockBloc),
          BlocProvider<HelpBloc>.value(value: helpBloc),
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: const Scaffold(
          body: ChildDashboard(),
        ),
      ),
    );
  }

  testWidgets('Should display app with minimum remaining time dynamically', (WidgetTester tester) async {
    when(() => dashboardBloc.state).thenReturn(const DashboardLoaded(
      totalMinutesToday: 40,
      totalMinutesYesterday: 0,
      usageByApp: {
        'Facebook': 10,
        'TikTok': 25,
      },
      recentLogs: [],
      childUids: [],
      appTimeLimits: {
        'com.facebook.katana': 20,
        'Facebook': 20,
        'com.zhiliaoapp.musically': 60,
        'TikTok': 60,
      },
    ));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.textContaining('Thời gian còn lại: 10/20 phút Facebook'), findsOneWidget);
  });
  
  testWidgets('Should display Zalo if Zalo has less remaining time', (WidgetTester tester) async {
    when(() => dashboardBloc.state).thenReturn(const DashboardLoaded(
      totalMinutesToday: 40,
      totalMinutesYesterday: 0,
      usageByApp: {
        'Facebook': 5,
        'Zalo': 2,
      },
      recentLogs: [],
      childUids: [],
      appTimeLimits: {
        'Facebook': 20,
        'Zalo': 5, 
      },
    ));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.textContaining('Thời gian còn lại: 3/5 phút Zalo'), findsOneWidget);
  });
}
