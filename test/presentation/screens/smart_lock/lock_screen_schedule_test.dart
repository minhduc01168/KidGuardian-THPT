import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/presentation/screens/smart_lock/lock_screen.dart';

void main() {
  group('LockScreen - Schedule block reason', () {
    testWidgets('should show schedule reason when blockReason is schedule', (tester) async {
      // Use a future reset time to avoid countdown issues
      final resetTime = DateTime.now().add(const Duration(hours: 8));

      await tester.pumpWidget(
        MaterialApp(
          home: LockScreen(
            appPackageName: 'com.test.app',
            appName: 'TikTok',
            limitMinutes: 0,
            usedMinutes: 0,
            resetTime: resetTime,
            blockReason: 'schedule',
            scheduleName: 'Giờ ngủ',
          ),
        ),
      );

      expect(find.text('Đang trong giờ ngủ'), findsOneWidget);
    });

    testWidgets('should show homework schedule reason', (tester) async {
      final resetTime = DateTime.now().add(const Duration(hours: 3));

      await tester.pumpWidget(
        MaterialApp(
          home: LockScreen(
            appPackageName: 'com.test.app',
            appName: 'TikTok',
            limitMinutes: 0,
            usedMinutes: 0,
            resetTime: resetTime,
            blockReason: 'schedule',
            scheduleName: 'Giờ học bài',
          ),
        ),
      );

      expect(find.text('Đang trong giờ học bài'), findsOneWidget);
    });

    testWidgets('should show time limit reason when blockReason is time_limit', (tester) async {
      final resetTime = DateTime.now().add(const Duration(hours: 6));

      await tester.pumpWidget(
        MaterialApp(
          home: LockScreen(
            appPackageName: 'com.test.app',
            appName: 'TikTok',
            limitMinutes: 60,
            usedMinutes: 60,
            resetTime: resetTime,
            blockReason: 'time_limit',
          ),
        ),
      );

      expect(find.text('Bạn đã sử dụng hết thời gian cho phép hôm nay'), findsOneWidget);
    });

    testWidgets('should show time limit reason when blockReason is null (backward compat)', (tester) async {
      final resetTime = DateTime.now().add(const Duration(hours: 6));

      await tester.pumpWidget(
        MaterialApp(
          home: LockScreen(
            appPackageName: 'com.test.app',
            appName: 'TikTok',
            limitMinutes: 60,
            usedMinutes: 60,
            resetTime: resetTime,
          ),
        ),
      );

      expect(find.text('Bạn đã sử dụng hết thời gian cho phép hôm nay'), findsOneWidget);
    });

    testWidgets('should not show request time button for schedule blocks', (tester) async {
      final resetTime = DateTime.now().add(const Duration(hours: 8));

      await tester.pumpWidget(
        MaterialApp(
          home: LockScreen(
            appPackageName: 'com.test.app',
            appName: 'TikTok',
            limitMinutes: 0,
            usedMinutes: 0,
            resetTime: resetTime,
            blockReason: 'schedule',
            scheduleName: 'Giờ ngủ',
          ),
        ),
      );

      // Schedule blocks should not show "request more time" button
      expect(find.text('Xin thêm thời gian'), findsNothing);
    });
  });
}
