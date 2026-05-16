import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/data/repositories/smart_lock_repository.dart';
import 'package:kidguardian/data/models/smart_lock_settings_model.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_bloc.dart';
import 'package:kidguardian/presentation/screens/smart_lock/smart_lock_settings_screen.dart';

class MockSmartLockRepository extends Mock implements SmartLockRepository {}

void main() {
  late MockSmartLockRepository mockRepository;

  setUp(() {
    mockRepository = MockSmartLockRepository();
    registerFallbackValue(const SmartLockSettingsModel());
  });

  Widget buildTestWidget({SmartLockSettingsModel? settings}) {
    when(() => mockRepository.getSmartLockSettings(any(), any()))
        .thenAnswer((_) async => settings);
    when(() => mockRepository.saveSmartLockSettings(any(), any(), any()))
        .thenAnswer((_) async {});
    when(() => mockRepository.getLockHistory(any(), any()))
        .thenAnswer((_) async => []);

    return MaterialApp(
      home: BlocProvider<SmartLockBloc>(
        create: (_) => SmartLockBloc(repository: mockRepository),
        child: const SmartLockSettingsScreen(
          familyId: 'family1',
          childId: 'child1',
          childName: 'Test Child',
        ),
      ),
    );
  }

  group('SmartLockSettingsScreen', () {
    testWidgets('displays app bar title', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        settings: const SmartLockSettingsModel(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Cài đặt Smart Lock'), findsOneWidget);
    });

    testWidgets('displays all settings sections', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        settings: const SmartLockSettingsModel(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Bật Smart Lock'), findsOneWidget);
      expect(find.text('Giới hạn thời gian mặc định'), findsOneWidget);
      expect(find.text('Tuỳ chọn thông báo'), findsOneWidget);
    });

    testWidgets('displays default time limit', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        settings: const SmartLockSettingsModel(defaultTimeLimitMinutes: 90),
      ));
      await tester.pumpAndSettle();

      expect(find.text('90 phút'), findsOneWidget);
    });

    testWidgets('displays enabled state text', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        settings: const SmartLockSettingsModel(isEnabled: true),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Smart Lock đang được bật'), findsOneWidget);
    });

    testWidgets('displays disabled state text', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        settings: const SmartLockSettingsModel(isEnabled: false),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Smart Lock đang được tắt'), findsOneWidget);
    });

    testWidgets('displays notification toggles', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        settings: const SmartLockSettingsModel(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Yêu cầu thêm thời gian'), findsOneWidget);
      expect(find.text('Khoá ứng dụng'), findsOneWidget);
      expect(find.text('Hết giới hạn'), findsOneWidget);
      expect(find.text('Vi phạm lịch trình'), findsOneWidget);
    });

    testWidgets('displays Vietnamese labels', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        settings: const SmartLockSettingsModel(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Cài đặt Smart Lock'), findsOneWidget);
      expect(find.text('Bật Smart Lock'), findsOneWidget);
      expect(find.text('Thời gian mặc định'), findsOneWidget);
    });
  });
}
