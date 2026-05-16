import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/data/models/smart_lock_settings_model.dart';
import 'package:kidguardian/presentation/widgets/smart_lock/notification_preferences_section.dart';

void main() {
  group('NotificationPreferencesSection', () {
    Widget buildTestWidget(SmartLockSettingsModel settings) {
      return MaterialApp(
        home: Scaffold(
          body: NotificationPreferencesSection(
            settings: settings,
            onSave: (_) {},
          ),
        ),
      );
    }

    testWidgets('displays all notification toggles', (tester) async {
      await tester.pumpWidget(buildTestWidget(const SmartLockSettingsModel()));
      await tester.pumpAndSettle();

      expect(find.text('Yêu cầu thêm thời gian'), findsOneWidget);
      expect(find.text('Khoá ứng dụng'), findsOneWidget);
      expect(find.text('Hết giới hạn'), findsOneWidget);
      expect(find.text('Vi phạm lịch trình'), findsOneWidget);
    });

    testWidgets('displays correct toggle states', (tester) async {
      const settings = SmartLockSettingsModel(
        notifyOnTimeRequest: true,
        notifyOnAppBlocked: false,
        notifyOnLimitReached: true,
        notifyOnScheduleViolation: false,
      );

      await tester.pumpWidget(buildTestWidget(settings));
      await tester.pumpAndSettle();

      final switches = tester.widgetList<SwitchListTile>(
        find.byType(SwitchListTile),
      );

      final switchList = switches.toList();
      expect(switchList[0].value, true);
      expect(switchList[1].value, false);
      expect(switchList[2].value, true);
      expect(switchList[3].value, false);
    });

    testWidgets('displays Vietnamese descriptions', (tester) async {
      await tester.pumpWidget(buildTestWidget(const SmartLockSettingsModel()));
      await tester.pumpAndSettle();

      expect(
        find.text('Thông báo khi trẻ yêu cầu thêm thời gian'),
        findsOneWidget,
      );
      expect(
        find.text('Thông báo khi trẻ bị khoá ứng dụng'),
        findsOneWidget,
      );
      expect(
        find.text('Thông báo khi trẻ sử dụng hết giới hạn'),
        findsOneWidget,
      );
      expect(
        find.text('Thông báo khi trẻ vi phạm lịch trình'),
        findsOneWidget,
      );
    });
  });
}
