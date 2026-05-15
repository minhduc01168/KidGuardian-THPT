import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/data/models/app_time_limit_model.dart';
import 'package:kidguardian/presentation/widgets/smart_lock/app_limit_item.dart';

void main() {
  testWidgets('AppLimitItem displays correctly with everyday limit', (WidgetTester tester) async {
    const app = AppTimeLimitModel(
      appPackageName: 'com.tiktok',
      appName: 'TikTok',
      limits: {'everyday': 60},
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppLimitItem(app: app, onTap: () {}),
      ),
    ));

    expect(find.text('TikTok'), findsOneWidget);
    expect(find.text('60 phút / ngày'), findsOneWidget);
  });

  testWidgets('AppLimitItem displays correctly without limit', (WidgetTester tester) async {
    const app = AppTimeLimitModel(
      appPackageName: 'com.tiktok',
      appName: 'TikTok',
      limits: {},
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppLimitItem(app: app, onTap: () {}),
      ),
    ));

    expect(find.text('TikTok'), findsOneWidget);
    expect(find.text('Chưa cài đặt'), findsOneWidget);
  });
}
