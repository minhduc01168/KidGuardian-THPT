import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/presentation/widgets/smart_lock/emergency_contact_sheet.dart';

void main() {
  Widget buildSheet() {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => const EmergencyContactSheet(),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  group('EmergencyContactSheet', () {
    testWidgets('displays title', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Liên hệ khẩn cấp'), findsOneWidget);
    });

    testWidgets('displays subtitle', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(
        find.text('Liên hệ trực tiếp với phụ huynh'),
        findsOneWidget,
      );
    });

    testWidgets('displays call button', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Gọi điện'), findsOneWidget);
    });

    testWidgets('displays message button', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Nhắn tin'), findsOneWidget);
    });

    testWidgets('displays close button', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Đóng'), findsOneWidget);
    });

    testWidgets('displays parent contact section', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Phụ huynh'), findsOneWidget);
    });

    testWidgets('close button dismisses sheet', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      expect(find.text('Liên hệ khẩn cấp'), findsNothing);
    });
  });
}
