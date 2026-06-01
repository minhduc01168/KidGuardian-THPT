import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:kidguardian/data/models/auto_approval_rule_model.dart';
import 'package:kidguardian/domain/repositories/rules_repository.dart';
import 'package:kidguardian/domain/repositories/time_request_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late RulesRepositoryImpl rulesRepository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    rulesRepository = RulesRepositoryImpl(firestore: fakeFirestore);
  });

  group('RulesRepository', () {
    test('getRules returns null when no rules exist', () async {
      final result = await rulesRepository.getRules('test-family-id');
      expect(result, isNull);
    });

    test('saveRules saves rules to Firestore', () async {
      final rule = AutoApprovalRule(
        id: '',
        familyId: 'test-family-id',
        maxAutoApproveMinutes: 30,
        dailyAutoApproveLimit: 3,
        isEnabled: true,
      );

      await rulesRepository.saveRules(rule);

      final savedRule = await rulesRepository.getRules('test-family-id');
      expect(savedRule, isNotNull);
      expect(savedRule!.familyId, 'test-family-id');
      expect(savedRule.maxAutoApproveMinutes, 30);
      expect(savedRule.dailyAutoApproveLimit, 3);
      expect(savedRule.isEnabled, true);
    });

    test('shouldAutoApprove returns false when rules are disabled', () async {
      final rule = AutoApprovalRule(
        id: '',
        familyId: 'test-family-id',
        maxAutoApproveMinutes: 30,
        dailyAutoApproveLimit: 3,
        isEnabled: false,
      );

      await rulesRepository.saveRules(rule);

      final result = await rulesRepository.shouldAutoApprove(
        familyId: 'test-family-id',
        appPackageName: 'com.test.app',
        requestedMinutes: 15,
      );

      expect(result, false);
    });

    test('shouldAutoApprove returns true when all conditions met', () async {
      final rule = AutoApprovalRule(
        id: '',
        familyId: 'test-family-id',
        maxAutoApproveMinutes: 30,
        dailyAutoApproveLimit: 3,
        isEnabled: true,
        appSpecificRules: {'com.test.app': true},
      );

      await rulesRepository.saveRules(rule);

      final result = await rulesRepository.shouldAutoApprove(
        familyId: 'test-family-id',
        appPackageName: 'com.test.app',
        requestedMinutes: 15,
      );

      expect(result, true);
    });

    test('shouldAutoApprove returns false when minutes exceed limit', () async {
      final rule = AutoApprovalRule(
        id: '',
        familyId: 'test-family-id',
        maxAutoApproveMinutes: 30,
        dailyAutoApproveLimit: 3,
        isEnabled: true,
      );

      await rulesRepository.saveRules(rule);

      final result = await rulesRepository.shouldAutoApprove(
        familyId: 'test-family-id',
        appPackageName: 'com.test.app',
        requestedMinutes: 45,
      );

      expect(result, false);
    });

    test('shouldAutoApprove returns false when app is disabled', () async {
      final rule = AutoApprovalRule(
        id: '',
        familyId: 'test-family-id',
        maxAutoApproveMinutes: 30,
        dailyAutoApproveLimit: 3,
        isEnabled: true,
        appSpecificRules: {'com.test.app': false},
      );

      await rulesRepository.saveRules(rule);

      final result = await rulesRepository.shouldAutoApprove(
        familyId: 'test-family-id',
        appPackageName: 'com.test.app',
        requestedMinutes: 15,
      );

      expect(result, false);
    });

    test('logAutoApprovedRequest logs request to Firestore', () async {
      final request = TimeRequest(
        id: 'test-request-id',
        familyId: 'test-family-id',
        childUid: 'test-child-uid',
        appPackageName: 'com.test.app',
        appName: 'Test App',
        requestedMinutes: 15,
        reason: 'Test reason',
        status: TimeRequestStatus.approved,
        timestamp: DateTime.now(),
      );

      await rulesRepository.logAutoApprovedRequest(request);

      final snapshot = await fakeFirestore
          .collection('families')
          .doc('test-family-id')
          .collection('autoApprovalLogs')
          .get();

      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['requestId'], 'test-request-id');
      expect(snapshot.docs.first.data()['appName'], 'Test App');
    });

    test('getTodayAutoApprovedCount returns correct count', () async {
      final request = TimeRequest(
        id: 'test-request-id',
        familyId: 'test-family-id',
        childUid: 'test-child-uid',
        appPackageName: 'com.test.app',
        appName: 'Test App',
        requestedMinutes: 15,
        reason: 'Test reason',
        status: TimeRequestStatus.approved,
        timestamp: DateTime.now(),
      );

      await rulesRepository.logAutoApprovedRequest(request);
      await rulesRepository.logAutoApprovedRequest(request);

      final count = await rulesRepository.getTodayAutoApprovedCount('test-family-id');
      expect(count, 2);
    });
  });
}
