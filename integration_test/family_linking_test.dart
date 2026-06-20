import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kidguardian/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E Family Linking Flow Test', () {
    testWidgets('Child sees link prompt and handles invalid code', (tester) async {
      // 1. Khởi động app
      app.main();
      await tester.pumpAndSettle();

      // Chờ qua màn hình Splash
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Đăng xuất nếu đang đăng nhập
      final logoutBtn = find.text('Đăng xuất');
      if (logoutBtn.evaluate().isNotEmpty) {
        await tester.tap(logoutBtn);
        await tester.pumpAndSettle();
      }

      // 2. Chọn Role Trẻ Em
      final childIcon = find.byIcon(Icons.face_retouching_natural_rounded);
      expect(childIcon, findsOneWidget);
      await tester.tap(childIcon);
      await tester.pumpAndSettle();

      // 3. Chuyển sang Đăng ký
      final registerSwitchBtn = find.textContaining('Đăng ký');
      if (registerSwitchBtn.evaluate().isNotEmpty) {
        await tester.tap(registerSwitchBtn.first);
        await tester.pumpAndSettle();
      }

      // 4. Điền form Đăng ký với vai trò Child
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);
      
      final randomEmail = 'child_${DateTime.now().millisecondsSinceEpoch}@test.com';

      await tester.enterText(textFields.at(0), 'E2E Child');
      await tester.enterText(textFields.at(1), randomEmail);
      await tester.enterText(textFields.at(2), 'Password123!');
      if (textFields.evaluate().length > 3) {
        await tester.enterText(textFields.at(3), 'Password123!');
      }
      
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final registerBtn = find.widgetWithText(ElevatedButton, 'Đăng ký');
      await tester.tap(registerBtn);
      
      // Chờ Firebase đăng ký và Splash screen
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();

      // 5. Kiểm tra Child Dashboard hiện form "Chưa liên kết tài khoản"
      expect(find.text('Chưa liên kết tài khoản'), findsOneWidget);
      expect(find.text('Nhập mã liên kết'), findsWidgets);

      // 6. Bấm vào Nhập mã liên kết
      final enterCodeBtn = find.widgetWithText(ElevatedButton, 'Nhập mã liên kết');
      await tester.tap(enterCodeBtn.first);
      await tester.pumpAndSettle();

      // 7. Nhập mã sai (6 ký tự) để kiểm tra luồng lỗi
      // Màn hình LinkChildScreen có 6 ô nhập liệu
      final codeFields = find.byType(TextFormField);
      expect(codeFields, findsNWidgets(6));

      await tester.enterText(codeFields.at(0), 'I');
      await tester.enterText(codeFields.at(1), 'N');
      await tester.enterText(codeFields.at(2), 'V');
      await tester.enterText(codeFields.at(3), 'A');
      await tester.enterText(codeFields.at(4), 'L');
      await tester.enterText(codeFields.at(5), 'I');
      await tester.pumpAndSettle();

      final linkBtn = find.widgetWithText(ElevatedButton, 'Liên kết');
      await tester.tap(linkBtn);
      
      // Chờ API check Firestore
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Màn hình hiện lỗi do mã không hợp lệ
      expect(find.text('Mã liên kết không hợp lệ'), findsOneWidget);
    });
  });
}
