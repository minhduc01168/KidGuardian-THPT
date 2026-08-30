// test/presentation/widgets/child_analytics_widget_test.dart
//
// Unit Tests cho ChildAnalyticsWidget — Analytics Two-way Tracking

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidguardian/presentation/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:kidguardian/presentation/features/dashboard/bloc/dashboard_event.dart';
import 'package:kidguardian/presentation/features/dashboard/bloc/dashboard_state.dart';
import 'package:kidguardian/presentation/features/dashboard/widgets/child_analytics_widget.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────
class MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

class FakeDashboardEvent extends Fake implements DashboardEvent {}

// ─── Helpers ──────────────────────────────────────────────────────────────────
DashboardLoaded _makeLoadedState({
  int totalToday = 0,
  Map<String, int> usageByApp = const {},
  Map<String, int> dailyTotals = const {},
}) {
  return DashboardLoaded(
    totalMinutesToday: totalToday,
    totalMinutesYesterday: 0,
    usageByApp: usageByApp,
    recentLogs: const [],
    childUids: const [],
    dailyTotals: dailyTotals,
    appTimeLimits: const {},
  );
}

Future<void> _pumpWidget(
  WidgetTester tester,
  MockDashboardBloc bloc, {
  String childUid = 'child-001',
  String title = 'Thống kê sử dụng',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<DashboardBloc>.value(
        value: bloc,
        child: Scaffold(
          body: ChildAnalyticsWidget(childUid: childUid, title: title),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDashboardEvent());
  });

  late MockDashboardBloc mockBloc;

  setUp(() {
    mockBloc = MockDashboardBloc();
  });

  tearDown(() {
    mockBloc.close();
  });

  // ─────────────────────────────────────────────────────────────────────────
  // GROUP 1: Loading & Empty states
  // ─────────────────────────────────────────────────────────────────────────
  group('ChildAnalyticsWidget — Loading & Empty states', () {

    testWidgets('hiển thị loading spinner khi DashboardLoading', (tester) async {
      whenListen<DashboardState>(
        mockBloc,
        Stream<DashboardState>.fromIterable([DashboardLoading()]),
        initialState: DashboardLoading(),
      );

      await _pumpWidget(tester, mockBloc);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hiển thị empty state khi DashboardLoaded rỗng', (tester) async {
      // DashboardLoaded với data rỗng → render _buildAnalyticsContent nhưng chưa có chart
      // (DashboardInitial → _buildEmptyState — block đang chờ load)
      final emptyState = _makeLoadedState();
      whenListen<DashboardState>(
        mockBloc,
        Stream<DashboardState>.empty(),
        initialState: emptyState,
      );

      await _pumpWidget(tester, mockBloc);

      // Loaded state với rỗng → hiển thị summary cards
      expect(find.text('Hôm nay'), findsOneWidget);
    });

    testWidgets('hiển thị error state khi DashboardError', (tester) async {
      const errorState = DashboardError(message: 'Network error');
      whenListen<DashboardState>(
        mockBloc,
        Stream<DashboardState>.empty(),
        initialState: errorState,
      );

      await _pumpWidget(tester, mockBloc);

      expect(find.text('Không thể tải dữ liệu'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // GROUP 2: Summary Cards
  // ─────────────────────────────────────────────────────────────────────────
  group('ChildAnalyticsWidget — Summary Cards', () {

    testWidgets('hiển thị 3 summary card labels', (tester) async {
      final state = _makeLoadedState(
        totalToday: 45,
        dailyTotals: {'2026-08-24': 30, '2026-08-25': 60},
      );
      whenListen<DashboardState>(
        mockBloc,
        Stream<DashboardState>.empty(),
        initialState: state,
      );

      await _pumpWidget(tester, mockBloc);

      expect(find.text('Hôm nay'), findsOneWidget);
      expect(find.text('7 ngày'), findsOneWidget);
      expect(find.text('Trung bình'), findsOneWidget);
    });

    testWidgets('hiển thị đúng số phút hôm nay', (tester) async {
      final state = _makeLoadedState(totalToday: 75);
      whenListen<DashboardState>(
        mockBloc,
        Stream<DashboardState>.empty(),
        initialState: state,
      );

      await _pumpWidget(tester, mockBloc);

      expect(find.text('75'), findsOneWidget);
    });

    testWidgets('tính đúng tổng 7 ngày (30+45+60=135)', (tester) async {
      final state = _makeLoadedState(
        dailyTotals: {
          '2026-08-24': 30,
          '2026-08-25': 45,
          '2026-08-26': 60,
        },
      );
      whenListen<DashboardState>(
        mockBloc,
        Stream<DashboardState>.empty(),
        initialState: state,
      );

      await _pumpWidget(tester, mockBloc);

      expect(find.text('135'), findsOneWidget);
    });

    testWidgets('hiển thị số 0 khi không có data', (tester) async {
      final state = _makeLoadedState(totalToday: 0);
      whenListen<DashboardState>(
        mockBloc,
        Stream<DashboardState>.empty(),
        initialState: state,
      );

      await _pumpWidget(tester, mockBloc);

      // Multiple '0' expected (today=0, week=0, avg=0)
      expect(find.text('0'), findsWidgets);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // GROUP 3: Client-side App Filtering
  // ─────────────────────────────────────────────────────────────────────────
  group('ChildAnalyticsWidget — App Filtering', () {

    testWidgets('render không crash khi có cả monitored và system app', (tester) async {
      final state = _makeLoadedState(
        usageByApp: {
          'com.zhiliaoapp.musically': 45,  // TikTok — ✅
          'com.android.settings': 10,       // System — ❌ bị lọc
          'com.facebook.katana': 30,         // Facebook — ✅
        },
      );
      whenListen<DashboardState>(
        mockBloc,
        Stream<DashboardState>.empty(),
        initialState: state,
      );

      await _pumpWidget(tester, mockBloc);

      expect(find.byType(ChildAnalyticsWidget), findsOneWidget);
      // Không crash = test pass
    });

    testWidgets('render không crash khi tất cả app đều có 0 phút', (tester) async {
      final state = _makeLoadedState(
        usageByApp: {
          'com.zhiliaoapp.musically': 0,
          'com.facebook.katana': 0,
        },
      );
      whenListen<DashboardState>(
        mockBloc,
        Stream<DashboardState>.empty(),
        initialState: state,
      );

      await _pumpWidget(tester, mockBloc);

      // Khi tất cả app = 0, hiển thị empty chart placeholder
      expect(find.byType(ChildAnalyticsWidget), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // GROUP 4: Daily list
  // ─────────────────────────────────────────────────────────────────────────
  group('ChildAnalyticsWidget — Daily list', () {

    testWidgets('hiển thị header "7 ngày gần nhất" khi có dailyTotals', (tester) async {
      final state = _makeLoadedState(
        dailyTotals: {'2026-08-28': 45, '2026-08-29': 60},
      );
      whenListen<DashboardState>(
        mockBloc,
        Stream<DashboardState>.empty(),
        initialState: state,
      );

      await _pumpWidget(tester, mockBloc);

      expect(find.text('7 ngày gần nhất'), findsOneWidget);
    });

    testWidgets('ẩn danh sách ngày khi dailyTotals rỗng', (tester) async {
      final state = _makeLoadedState(dailyTotals: {});
      whenListen<DashboardState>(
        mockBloc,
        Stream<DashboardState>.empty(),
        initialState: state,
      );

      await _pumpWidget(tester, mockBloc);

      expect(find.text('7 ngày gần nhất'), findsNothing);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // GROUP 5: Bloc interaction
  // ─────────────────────────────────────────────────────────────────────────
  group('ChildAnalyticsWidget — Bloc interaction', () {

    testWidgets('gửi LoadChildUsage event khi build', (tester) async {
      whenListen<DashboardState>(
        mockBloc,
        Stream<DashboardState>.empty(),
        initialState: DashboardInitial(),
      );

      await _pumpWidget(tester, mockBloc, childUid: 'test-child-123');

      verify(
        () => mockBloc.add(any(that: isA<LoadChildUsage>())),
      ).called(1);
    });

    testWidgets('tiêu đề mặc định "Thống kê sử dụng" được render trong loaded state', (tester) async {
      final state = _makeLoadedState(totalToday: 10);
      whenListen<DashboardState>(
        mockBloc,
        Stream<DashboardState>.empty(),
        initialState: state,
      );

      await _pumpWidget(tester, mockBloc);

      expect(find.text('Thống kê sử dụng'), findsOneWidget);
    });

    testWidgets('tiêu đề tùy chỉnh được render đúng', (tester) async {
      final state = _makeLoadedState(totalToday: 10);
      whenListen<DashboardState>(
        mockBloc,
        Stream<DashboardState>.empty(),
        initialState: state,
      );

      await _pumpWidget(tester, mockBloc, title: 'Thống kê của tôi');

      expect(find.text('Thống kê của tôi'), findsOneWidget);
    });

    testWidgets('hiển thị mô tả "Chỉ thống kê 8 ứng dụng MXH"', (tester) async {
      final state = _makeLoadedState(totalToday: 10);
      whenListen<DashboardState>(
        mockBloc,
        Stream<DashboardState>.empty(),
        initialState: state,
      );

      await _pumpWidget(tester, mockBloc);

      expect(
        find.text('Chỉ thống kê 8 ứng dụng MXH được giám sát'),
        findsOneWidget,
      );
    });
  });
}
