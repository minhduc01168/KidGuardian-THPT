import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/presentation/widgets/smart_lock/time_picker_bottom_sheet.dart';

void main() {
  testWidgets('TimePickerBottomSheet displays everyday picker correctly', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TimePickerBottomSheet(
          initialLimits: const {'everyday': 60},
          onSave: (_) {},
        ),
      ),
    ));

    expect(find.text('Mỗi ngày như nhau'), findsOneWidget);
    expect(find.text('60 phút'), findsOneWidget);
  });
}
