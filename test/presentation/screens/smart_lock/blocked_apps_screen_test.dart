import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidguardian/data/models/monitored_app_model.dart';
import 'package:kidguardian/data/repositories/smart_lock_repository.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_bloc.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_event.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_state.dart';
import 'package:kidguardian/presentation/screens/smart_lock/blocked_apps_screen.dart';

class MockSmartLockRepository extends Mock implements SmartLockRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSmartLockRepository mockRepository;

  setUp(() {
    mockRepository = MockSmartLockRepository();
  });

  Widget buildScreen() {
    return MaterialApp(
      home: BlockedAppsScreen(
        familyId: 'family1',
        childId: 'child1',
        repository: mockRepository,
      ),
    );
  }

  testWidgets('BlockedAppsScreen displays loading indicator initially',
      (WidgetTester tester) async {
    final completer = Completer<List<MonitoredAppModel>>();
    when(() => mockRepository.getPopularMonitoredApps()).thenReturn([]);
    when(() => mockRepository.getMonitoredApps(any(), any()))
        .thenAnswer((_) => completer.future);

    await tester.pumpWidget(buildScreen());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete([]);
    await tester.pumpAndSettle();
  });

  testWidgets('BlockedAppsScreen displays list of apps after loading',
      (WidgetTester tester) async {
    final apps = [
      const MonitoredAppModel(
        appPackageName: 'com.tiktok',
        appName: 'TikTok',
        isMonitored: true,
      ),
      const MonitoredAppModel(
        appPackageName: 'com.facebook',
        appName: 'Facebook',
        isMonitored: false,
      ),
    ];

    when(() => mockRepository.getPopularMonitoredApps()).thenReturn(apps);
    when(() => mockRepository.getMonitoredApps(any(), any()))
        .thenAnswer((_) async => []);

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('TikTok'), findsOneWidget);
    expect(find.text('Facebook'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNWidgets(2));
  });

  testWidgets('BlockedAppsScreen displays correct toggle states',
      (WidgetTester tester) async {
    final apps = [
      const MonitoredAppModel(
        appPackageName: 'com.tiktok',
        appName: 'TikTok',
        isMonitored: true,
      ),
      const MonitoredAppModel(
        appPackageName: 'com.facebook',
        appName: 'Facebook',
        isMonitored: false,
      ),
    ];

    when(() => mockRepository.getPopularMonitoredApps()).thenReturn(apps);
    when(() => mockRepository.getMonitoredApps(any(), any()))
        .thenAnswer((_) async => []);

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    final switches = tester.widgetList<SwitchListTile>(find.byType(SwitchListTile));
    final switchList = switches.toList();

    expect(switchList[0].value, true);
    expect(switchList[1].value, false);
  });

  testWidgets('BlockedAppsScreen shows add custom app button',
      (WidgetTester tester) async {
    when(() => mockRepository.getPopularMonitoredApps()).thenReturn([]);
    when(() => mockRepository.getMonitoredApps(any(), any()))
        .thenAnswer((_) async => []);

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('BlockedAppsScreen shows empty state when no apps',
      (WidgetTester tester) async {
    when(() => mockRepository.getPopularMonitoredApps()).thenReturn([]);
    when(() => mockRepository.getMonitoredApps(any(), any()))
        .thenAnswer((_) async => []);

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Không có ứng dụng nào để hiển thị'), findsOneWidget);
  });

  testWidgets('BlockedAppsScreen shows Vietnamese status labels',
      (WidgetTester tester) async {
    final apps = [
      const MonitoredAppModel(
        appPackageName: 'com.tiktok',
        appName: 'TikTok',
        isMonitored: true,
      ),
    ];

    when(() => mockRepository.getPopularMonitoredApps()).thenReturn(apps);
    when(() => mockRepository.getMonitoredApps(any(), any()))
        .thenAnswer((_) async => []);

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Đang giám sát'), findsOneWidget);
  });
}
