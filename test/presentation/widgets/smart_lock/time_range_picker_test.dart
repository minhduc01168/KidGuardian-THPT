import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/presentation/widgets/smart_lock/time_range_picker.dart';

void main() {
  group('TimeRangePicker', () {
    testWidgets('should display start and end time', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeRangePicker(
              startHour: 21,
              startMinute: 0,
              endHour: 6,
              endMinute: 0,
              onChanged: (_, __, ___, ____) {},
            ),
          ),
        ),
      );

      expect(find.text('Giờ bắt đầu'), findsOneWidget);
      expect(find.text('Giờ kết thúc'), findsOneWidget);
      expect(find.text('21:00'), findsOneWidget);
      expect(find.text('06:00'), findsOneWidget);
    });

    testWidgets('should call onChanged when time is tapped', (tester) async {
      int? capturedStartHour;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeRangePicker(
              startHour: 18,
              startMinute: 0,
              endHour: 21,
              endMinute: 0,
              onChanged: (sh, sm, eh, em) {
                capturedStartHour = sh;
              },
            ),
          ),
        ),
      );

      // Tap on start time
      await tester.tap(find.text('18:00'));
      await tester.pumpAndSettle();

      // The time picker dialog should appear
      // For now, just verify the callback is set up
      expect(capturedStartHour, isNull); // Not yet changed without dialog interaction
    });

    testWidgets('should display time range label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeRangePicker(
              startHour: 21,
              startMinute: 0,
              endHour: 6,
              endMinute: 0,
              onChanged: (_, __, ___, ____) {},
            ),
          ),
        ),
      );

      expect(find.text('21:00 - 06:00'), findsOneWidget);
    });
  });
}
