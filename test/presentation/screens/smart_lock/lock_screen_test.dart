import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/presentation/screens/smart_lock/lock_screen.dart';

void main() {
  final resetTime = DateTime(2026, 5, 17, 0, 0, 0);

  Widget buildLockScreen({
    String appName = 'TikTok',
    String appPackageName = 'com.zhiliaoapp.musically',
    String? iconUrl,
    int limitMinutes = 60,
    int usedMinutes = 60,
  }) {
    return MaterialApp(
      home: LockScreen(
        appPackageName: appPackageName,
        appName: appName,
        iconUrl: iconUrl,
        limitMinutes: limitMinutes,
        usedMinutes: usedMinutes,
        resetTime: resetTime,
      ),
    );
  }

  group('LockScreen', () {
    testWidgets('displays app name instead of package name', (tester) async {
      await tester.pumpWidget(buildLockScreen(appName: 'TikTok'));
      expect(find.text('TikTok'), findsOneWidget);
      expect(find.text('com.zhiliaoapp.musically'), findsNothing);
    });

    testWidgets('displays block reason message', (tester) async {
      await tester.pumpWidget(buildLockScreen());
      expect(
        find.text('Bạn đã sử dụng hết thời gian cho phép hôm nay'),
        findsOneWidget,
      );
    });

    testWidgets('displays usage stats', (tester) async {
      await tester.pumpWidget(buildLockScreen(
        limitMinutes: 60,
        usedMinutes: 45,
      ));
      expect(find.text('Đã dùng: 45/60 phút'), findsOneWidget);
    });

    testWidgets('displays countdown timer widget', (tester) async {
      await tester.pumpWidget(buildLockScreen());
      expect(find.textContaining('Còn lại:'), findsOneWidget);
    });

    testWidgets('displays "Quay về màn hình chính" button', (tester) async {
      await tester.pumpWidget(buildLockScreen());
      expect(find.text('Quay về màn hình chính'), findsOneWidget);
    });

    testWidgets('displays "Xin thêm thời gian" button', (tester) async {
      await tester.pumpWidget(buildLockScreen());
      expect(find.text('Xin thêm thời gian'), findsOneWidget);
    });

    testWidgets('displays "Liên hệ khẩn cấp" button', (tester) async {
      await tester.pumpWidget(buildLockScreen());
      expect(find.text('Liên hệ khẩn cấp'), findsOneWidget);
    });

    testWidgets('PopScope prevents back navigation', (tester) async {
      await tester.pumpWidget(buildLockScreen());
      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, isFalse);
    });

    testWidgets('lock screen uses gradient background', (tester) async {
      await tester.pumpWidget(buildLockScreen());
      expect(find.byType(LinearGradient), findsNothing);
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(SafeArea),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.gradient, isA<LinearGradient>());
    });
  });
}
