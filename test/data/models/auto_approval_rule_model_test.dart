import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kidguardian/data/models/auto_approval_rule_model.dart';

void main() {
  group('AutoApprovalRule', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    const tRule = AutoApprovalRule(
      id: 'rule1',
      familyId: 'family1',
      maxAutoApproveMinutes: 45,
      dailyAutoApproveLimit: 5,
      isEnabled: true,
      appSpecificRules: {'com.example.app1': true, 'com.example.app2': false},
      updatedAt: null,
    );

    group('constructor', () {
      test('should create instance with required fields only', () {
        const rule = AutoApprovalRule(id: 'r1', familyId: 'f1');

        expect(rule.id, 'r1');
        expect(rule.familyId, 'f1');
        expect(rule.maxAutoApproveMinutes, 30);
        expect(rule.dailyAutoApproveLimit, 3);
        expect(rule.isEnabled, false);
        expect(rule.appSpecificRules, const <String, bool>{});
        expect(rule.updatedAt, isNull);
      });

      test('should create instance with all fields', () {
        final now = DateTime(2026, 5, 30);
        final rule = AutoApprovalRule(
          id: 'r1',
          familyId: 'f1',
          maxAutoApproveMinutes: 60,
          dailyAutoApproveLimit: 10,
          isEnabled: true,
          appSpecificRules: {'app1': true},
          updatedAt: now,
        );

        expect(rule.maxAutoApproveMinutes, 60);
        expect(rule.dailyAutoApproveLimit, 10);
        expect(rule.isEnabled, true);
        expect(rule.appSpecificRules, {'app1': true});
        expect(rule.updatedAt, now);
      });
    });

    group('fromFirestore', () {
      test('should return valid model from Firestore document', () async {
        final now = DateTime(2026, 5, 30);
        await fakeFirestore.collection('autoApprovalRules').doc('rule1').set({
          'familyId': 'family1',
          'maxAutoApproveMinutes': 45,
          'dailyAutoApproveLimit': 5,
          'isEnabled': true,
          'appSpecificRules': {
            'com.example.app1': true,
            'com.example.app2': false,
          },
          'updatedAt': Timestamp.fromDate(now),
        });

        final doc =
            await fakeFirestore.collection('autoApprovalRules').doc('rule1').get();
        final result = AutoApprovalRule.fromFirestore(doc);

        expect(result.id, 'rule1');
        expect(result.familyId, 'family1');
        expect(result.maxAutoApproveMinutes, 45);
        expect(result.dailyAutoApproveLimit, 5);
        expect(result.isEnabled, true);
        expect(result.appSpecificRules, {
          'com.example.app1': true,
          'com.example.app2': false,
        });
        expect(result.updatedAt, now);
      });

      test('should use defaults when fields are missing', () async {
        await fakeFirestore.collection('autoApprovalRules').doc('rule2').set({});

        final doc =
            await fakeFirestore.collection('autoApprovalRules').doc('rule2').get();
        final result = AutoApprovalRule.fromFirestore(doc);

        expect(result.id, 'rule2');
        expect(result.familyId, '');
        expect(result.maxAutoApproveMinutes, 30);
        expect(result.dailyAutoApproveLimit, 3);
        expect(result.isEnabled, false);
        expect(result.appSpecificRules, const <String, bool>{});
        expect(result.updatedAt, isNull);
      });

      test('should handle null data gracefully', () async {
        await fakeFirestore
            .collection('autoApprovalRules')
            .doc('rule3')
            .set({'familyId': null});

        final doc =
            await fakeFirestore.collection('autoApprovalRules').doc('rule3').get();
        final result = AutoApprovalRule.fromFirestore(doc);

        expect(result.familyId, '');
      });

      test('should parse appSpecificRules with non-bool values', () async {
        await fakeFirestore.collection('autoApprovalRules').doc('rule4').set({
          'appSpecificRules': {
            'app1': true,
            'app2': 'truthy_string',
            'app3': null,
            'app4': 1,
          },
        });

        final doc =
            await fakeFirestore.collection('autoApprovalRules').doc('rule4').get();
        final result = AutoApprovalRule.fromFirestore(doc);

        expect(result.appSpecificRules['app1'], true);
        expect(result.appSpecificRules['app2'], false);
        expect(result.appSpecificRules['app3'], false);
        expect(result.appSpecificRules['app4'], false);
      });
    });

    group('toMap', () {
      test('should return a valid map', () {
        final result = tRule.toMap();

        expect(result['familyId'], 'family1');
        expect(result['maxAutoApproveMinutes'], 45);
        expect(result['dailyAutoApproveLimit'], 5);
        expect(result['isEnabled'], true);
        expect(result['appSpecificRules'], {
          'com.example.app1': true,
          'com.example.app2': false,
        });
        expect(result['updatedAt'], isA<FieldValue>());
      });

      test('should not include id in map', () {
        final result = tRule.toMap();
        expect(result.containsKey('id'), false);
      });
    });

    group('copyWith', () {
      test('should return same values when no arguments provided', () {
        final result = tRule.copyWith();

        expect(result.id, tRule.id);
        expect(result.familyId, tRule.familyId);
        expect(result.maxAutoApproveMinutes, tRule.maxAutoApproveMinutes);
        expect(result.dailyAutoApproveLimit, tRule.dailyAutoApproveLimit);
        expect(result.isEnabled, tRule.isEnabled);
        expect(result.appSpecificRules, tRule.appSpecificRules);
        expect(result.updatedAt, tRule.updatedAt);
      });

      test('should override specified fields', () {
        final now = DateTime(2026, 6, 1);
        final result = tRule.copyWith(
          id: 'rule2',
          familyId: 'family2',
          maxAutoApproveMinutes: 60,
          dailyAutoApproveLimit: 10,
          isEnabled: false,
          appSpecificRules: {'newApp': true},
          updatedAt: now,
        );

        expect(result.id, 'rule2');
        expect(result.familyId, 'family2');
        expect(result.maxAutoApproveMinutes, 60);
        expect(result.dailyAutoApproveLimit, 10);
        expect(result.isEnabled, false);
        expect(result.appSpecificRules, {'newApp': true});
        expect(result.updatedAt, now);
      });
    });

    group('Equatable', () {
      test('should be equal when all fields match', () {
        const rule1 = AutoApprovalRule(
          id: 'r1',
          familyId: 'f1',
          maxAutoApproveMinutes: 30,
          dailyAutoApproveLimit: 3,
          isEnabled: true,
          appSpecificRules: {'app': true},
        );
        const rule2 = AutoApprovalRule(
          id: 'r1',
          familyId: 'f1',
          maxAutoApproveMinutes: 30,
          dailyAutoApproveLimit: 3,
          isEnabled: true,
          appSpecificRules: {'app': true},
        );

        expect(rule1, rule2);
      });

      test('should not be equal when fields differ', () {
        const rule1 = AutoApprovalRule(id: 'r1', familyId: 'f1');
        const rule2 = AutoApprovalRule(id: 'r2', familyId: 'f1');

        expect(rule1, isNot(rule2));
      });
    });
  });
}
