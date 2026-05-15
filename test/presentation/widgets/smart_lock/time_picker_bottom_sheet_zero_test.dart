import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/presentation/widgets/smart_lock/time_picker_bottom_sheet.dart';

void main() {
  testWidgets('TimePickerBottomSheet passes empty map when everyday minutes is 0', (WidgetTester tester) async {
    Map<String, int>? savedLimits;
    
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TimePickerBottomSheet(
          initialLimits: const {'everyday': 0},
          onSave: (limits) {
            savedLimits = limits;
          },
        ),
      ),
    ));

    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    
    expect(savedLimits, isNotNull);
    expect(savedLimits!.isEmpty, isTrue);
  });
}
