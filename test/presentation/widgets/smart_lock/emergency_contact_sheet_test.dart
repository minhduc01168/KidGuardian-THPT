import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/domain/usecases/smart_lock/emergency_access_manager.dart';
import 'package:kidguardian/data/datasources/remote/emergency_log_source.dart';
import 'package:kidguardian/presentation/widgets/smart_lock/emergency_contact_sheet.dart';

class FakeEmergencyLogSource extends EmergencyLogSource {
  FakeEmergencyLogSource() : super(firestore: null);

  @override
  Future<String?> getParentPhoneNumber(String parentUid) async {
    return '0901234567';
  }

  @override
  Future<String?> getParentName(String parentUid) async {
    return 'Nguyễn Văn A';
  }

  @override
  Future<void> logEmergencyStart({
    required String childUid,
    required String familyId,
    required String action,
    required String phoneNumber,
    required String appPackageName,
  }) async {}

  @override
  Future<void> logEmergencyEnd({
    required String childUid,
    required int durationSeconds,
  }) async {}
}

void main() {
  Widget buildSheet({
    String? familyId,
    String? childUid,
    String? parentUid,
    String? appPackageName,
    EmergencyLogSource? logSource,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => EmergencyContactSheet(
                  familyId: familyId ?? 'f1',
                  childUid: childUid ?? 'c1',
                  parentUid: parentUid,
                  appPackageName: appPackageName ?? 'com.test.app',
                  logSource: logSource ?? FakeEmergencyLogSource(),
                ),
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
      await tester.pumpWidget(buildSheet(parentUid: 'p1'));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Liên hệ khẩn cấp'), findsOneWidget);
    });

    testWidgets('displays subtitle', (tester) async {
      await tester.pumpWidget(buildSheet(parentUid: 'p1'));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Liên hệ trực tiếp với phụ huynh'), findsOneWidget);
    });

    testWidgets('displays parent name and phone', (tester) async {
      await tester.pumpWidget(buildSheet(parentUid: 'p1'));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Nguyễn Văn A'), findsOneWidget);
      expect(find.text('0901234567'), findsOneWidget);
    });

    testWidgets('displays call button', (tester) async {
      await tester.pumpWidget(buildSheet(parentUid: 'p1'));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Gọi điện'), findsOneWidget);
    });

    testWidgets('displays message button', (tester) async {
      await tester.pumpWidget(buildSheet(parentUid: 'p1'));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Nhắn tin'), findsOneWidget);
    });

    testWidgets('displays close button', (tester) async {
      await tester.pumpWidget(buildSheet(parentUid: 'p1'));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Đóng'), findsOneWidget);
    });

    testWidgets('shows error when no parentUid', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa liên kết tài khoản phụ huynh'), findsOneWidget);
    });

    testWidgets('close button dismisses sheet', (tester) async {
      await tester.pumpWidget(buildSheet(parentUid: 'p1'));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      expect(find.text('Liên hệ khẩn cấp'), findsNothing);
    });
  });

  group('EmergencyAccessManager', () {
    test('initial state is inactive', () {
      final manager = EmergencyAccessManager();
      manager.reset();
      expect(manager.isActive, false);
      expect(manager.canActivate, true);
      expect(manager.remainingSeconds, 0);
    });

    test('activate sets isActive to true', () {
      final manager = EmergencyAccessManager();
      manager.reset();
      manager.activate();
      expect(manager.isActive, true);
      expect(manager.remainingSeconds, 300);
      manager.deactivate();
    });

    test('cannot activate when already active', () {
      final manager = EmergencyAccessManager();
      manager.reset();
      manager.activate();
      expect(manager.canActivate, false);
      manager.deactivate();
    });

    test('deactivate sets cooldown', () {
      final manager = EmergencyAccessManager();
      manager.reset();
      manager.activate();
      manager.deactivate();
      expect(manager.isActive, false);
      expect(manager.cooldownUntil, isNotNull);
      expect(manager.canActivate, false);
    });
  });
}
