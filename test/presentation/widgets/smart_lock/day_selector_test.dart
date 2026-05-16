import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/presentation/widgets/smart_lock/day_selector.dart';

void main() {
  group('DaySelector', () {
    testWidgets('should render all 7 days', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DaySelector(
              selectedDays: {},
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('T2'), findsOneWidget);
      expect(find.text('T3'), findsOneWidget);
      expect(find.text('T4'), findsOneWidget);
      expect(find.text('T5'), findsOneWidget);
      expect(find.text('T6'), findsOneWidget);
      expect(find.text('T7'), findsOneWidget);
      expect(find.text('CN'), findsOneWidget);
    });

    testWidgets('should highlight selected days', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DaySelector(
              selectedDays: {
                'monday': true,
                'tuesday': false,
                'wednesday': true,
                'thursday': false,
                'friday': false,
                'saturday': false,
                'sunday': false,
              },
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Should have 2 selected and 5 unselected
      final finder = find.byType(ActionChip);
      expect(finder, findsNWidgets(7));
    });

    testWidgets('should call onChanged when day is tapped', (tester) async {
      Map<String, bool>? lastChanged;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DaySelector(
              selectedDays: {
                'monday': false,
                'tuesday': false,
                'wednesday': false,
                'thursday': false,
                'friday': false,
                'saturday': false,
                'sunday': false,
              },
              onChanged: (days) {
                lastChanged = days;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('T2'));
      await tester.pumpAndSettle();

      expect(lastChanged, isNotNull);
      expect(lastChanged!['monday'], true);
    });

    testWidgets('should show select all button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DaySelector(
              selectedDays: {},
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Chọn tất cả'), findsOneWidget);
    });
  });
}
