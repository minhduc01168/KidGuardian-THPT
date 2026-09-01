import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/entities/user.dart';
import 'package:kidguardian/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:kidguardian/presentation/features/auth/bloc/auth_state.dart';
import 'package:kidguardian/presentation/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:kidguardian/presentation/features/dashboard/bloc/dashboard_event.dart';
import 'package:kidguardian/presentation/features/dashboard/bloc/dashboard_state.dart';
import 'package:kidguardian/presentation/blocs/in_app_notification/in_app_notification_bloc.dart';
import 'package:kidguardian/presentation/features/dashboard/screens/parent_dashboard.dart';

import 'package:kidguardian/presentation/features/auth/bloc/auth_event.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}
class MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState> implements DashboardBloc {}
class MockInAppNotificationBloc extends MockBloc<InAppNotificationEvent, InAppNotificationState> implements InAppNotificationBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockDashboardBloc mockDashboardBloc;
  late MockInAppNotificationBloc mockInAppNotificationBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockDashboardBloc = MockDashboardBloc();
    mockInAppNotificationBloc = MockInAppNotificationBloc();
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<DashboardBloc>.value(value: mockDashboardBloc),
        BlocProvider<InAppNotificationBloc>.value(value: mockInAppNotificationBloc),
      ],
      child: const MaterialApp(
        home: ParentDashboard(),
      ),
    );
  }

  testWidgets('ParentDashboard renders loading state correctly', (WidgetTester tester) async {
    when(() => mockAuthBloc.state).thenReturn(
      AuthAuthenticated(user: User(uid: 'p1', role: UserRole.parent, email: 'test@test.com', displayName: 'Test Parent', familyId: 'f1', createdAt: DateTime.now())),
    );
    when(() => mockDashboardBloc.state).thenReturn(DashboardLoading());
    when(() => mockInAppNotificationBloc.state).thenReturn(InAppNotificationInitial());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('ParentDashboard renders loaded state with animations and glassmorphism UI correctly', (WidgetTester tester) async {
    when(() => mockAuthBloc.state).thenReturn(
      AuthAuthenticated(user: User(uid: 'p1', role: UserRole.parent, email: 'test@test.com', displayName: 'Test Parent', familyId: 'f1', createdAt: DateTime.now())),
    );
    when(() => mockDashboardBloc.state).thenReturn(
      const DashboardLoaded(
        usageByApp: {},
        appTimeLimits: {},
        recentLogs: [],
        totalMinutesToday: 120,
        totalMinutesYesterday: 60,
        childUids: ['c1'],
        dailyTotals: {},
      ),
    );
    when(() => mockInAppNotificationBloc.state).thenReturn(InAppNotificationInitial());

    await tester.pumpWidget(createWidgetUnderTest());
    // Pump multiple times to allow TweenAnimationBuilder to finish
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify Welcome Card renders with user name
    expect(find.textContaining('Test Parent'), findsOneWidget);
    expect(find.textContaining('Sẵn sàng giám sát an toàn hôm nay?'), findsOneWidget);

    // Verify Summary Cards render animated numbers
    expect(find.text('Hôm nay'), findsOneWidget);
    expect(find.text('120 phút'), findsOneWidget);
    expect(find.text('Hôm qua'), findsOneWidget);
    expect(find.text('60 phút'), findsOneWidget);

    // Verify Change Indicator
    expect(find.text('+100.0% so với hôm qua'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);

    // Verify Quick Actions Grid
    expect(find.text('Mã liên kết'), findsOneWidget);
    expect(find.text('Tổng kết'), findsOneWidget);
    expect(find.text('Khóa ứng dụng'), findsOneWidget);
    expect(find.text('Báo cáo tuần'), findsOneWidget);
    expect(find.text('Cảnh báo'), findsOneWidget);
    expect(find.text('Yêu cầu'), findsOneWidget);
    expect(find.text('Báo cáo tháng'), findsOneWidget);
  });
}
