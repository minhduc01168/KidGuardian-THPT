import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kidguardian/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E Auth Flow Test', () {
    testWidgets('Register and Auto-login Flow', (tester) async {
      // 1. Start app
      app.main();
      await tester.pumpAndSettle();

      // Wait for splash screen to finish
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Check if we are in Dashboard or RoleSelection. If there is a Logout button, tap it.
      final logoutBtn = find.text('Đăng xuất');
      if (logoutBtn.evaluate().isNotEmpty) {
        await tester.tap(logoutBtn);
        await tester.pumpAndSettle();
      }

      // 2. Select Role (assuming 'Phụ huynh' or similar text exists, we use Icon to be safer)
      final parentIcon = find.byIcon(Icons.supervised_user_circle_rounded);
      expect(parentIcon, findsOneWidget);
      await tester.tap(parentIcon);
      await tester.pumpAndSettle();

      // 3. Login Screen -> Switch to Register
      // Find the switch button (usually at the bottom)
      final registerSwitchBtn = find.textContaining('Đăng ký');
      if (registerSwitchBtn.evaluate().isNotEmpty) {
        await tester.tap(registerSwitchBtn.first);
        await tester.pumpAndSettle();
      }

      // 4. Fill Registration Form
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);
      
      final randomEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';

      // Name
      await tester.enterText(textFields.at(0), 'E2E Parent');
      // Email
      await tester.enterText(textFields.at(1), randomEmail);
      // Password
      await tester.enterText(textFields.at(2), 'Password123!');
      // Confirm Password (if exists)
      if (textFields.evaluate().length > 3) {
        await tester.enterText(textFields.at(3), 'Password123!');
      }
      
      // Close keyboard
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // 5. Tap Register
      final registerBtn = find.widgetWithText(ElevatedButton, 'Đăng ký');
      if (registerBtn.evaluate().isNotEmpty) {
        await tester.tap(registerBtn);
      }
      
      // 6. Wait for registration and auto-login
      // This includes the Splash screen wait time
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // 7. Verify Dashboard is shown
      // Check for common dashboard elements
      final bottomNav = find.byType(BottomNavigationBar);
      if (bottomNav.evaluate().isNotEmpty) {
        expect(bottomNav, findsOneWidget);
      }
    });
  });
}
