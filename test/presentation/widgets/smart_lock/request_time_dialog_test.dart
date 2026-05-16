import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/presentation/widgets/smart_lock/request_time_dialog.dart';

void main() {
  Widget buildDialog() {
    return const MaterialApp(
      home: Scaffold(
        body: RequestTimeDialog(
          appPackageName: 'com.zhiliaoapp.musically',
          appName: 'TikTok',
        ),
      ),
    );
  }

  group('RequestTimeDialog', () {
    testWidgets('displays dialog title', (tester) async {
      await tester.pumpWidget(buildDialog());
      expect(find.text('Xin thêm thời gian'), findsOneWidget);
    });

    testWidgets('displays app name', (tester) async {
      await tester.pumpWidget(buildDialog());
      expect(find.text('Ứng dụng: TikTok'), findsOneWidget);
    });

    testWidgets('displays minute options as chips', (tester) async {
      await tester.pumpWidget(buildDialog());
      expect(find.text('15 phút'), findsOneWidget);
      expect(find.text('30 phút'), findsOneWidget);
      expect(find.text('60 phút'), findsOneWidget);
    });

    testWidgets('15 phút is selected by default', (tester) async {
      await tester.pumpWidget(buildDialog());
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '15 phút'),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('can select different minute option', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.tap(find.text('30 phút'));
      await tester.pumpAndSettle();
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '30 phút'),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('displays reason text field', (tester) async {
      await tester.pumpWidget(buildDialog());
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('displays submit button', (tester) async {
      await tester.pumpWidget(buildDialog());
      expect(find.text('Gửi yêu cầu'), findsOneWidget);
    });

    testWidgets('displays cancel button', (tester) async {
      await tester.pumpWidget(buildDialog());
      expect(find.text('Hủy'), findsOneWidget);
    });

    testWidgets('can enter reason text', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.enterText(
        find.byType(TextField),
        'Con cần thêm thời gian',
      );
      expect(find.text('Con cần thêm thời gian'), findsOneWidget);
    });
  });
}
