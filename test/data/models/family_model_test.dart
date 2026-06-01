import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kidguardian/data/models/family_model.dart';
import 'package:kidguardian/domain/entities/family.dart';

void main() {
  group('FamilyModel', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    final tCreatedAt = DateTime(2026, 1, 15);
    final tUpdatedAt = DateTime(2026, 5, 30);
    final tModel = FamilyModel(
      familyId: 'family1',
      parentUid: 'parent1',
      childUids: ['child1', 'child2'],
      linkingCode: 'ABC123',
      createdAt: tCreatedAt,
      updatedAt: tUpdatedAt,
    );

    test('should be a subclass of Family entity', () {
      expect(tModel, isA<Family>());
    });

    group('constructor', () {
      test('should use default values for optional fields', () {
        final model = FamilyModel(
          familyId: 'f1',
          parentUid: 'p1',
          createdAt: tCreatedAt,
          updatedAt: tUpdatedAt,
        );

        expect(model.childUids, <String>[]);
        expect(model.linkingCode, isNull);
      });
    });

    group('fromFirestore', () {
      test('should return valid model from Firestore document', () async {
        await fakeFirestore.collection('families').doc('family1').set({
          'familyId': 'family1',
          'parentUid': 'parent1',
          'childUids': ['child1', 'child2'],
          'linkingCode': 'ABC123',
          'createdAt': Timestamp.fromDate(tCreatedAt),
          'updatedAt': Timestamp.fromDate(tUpdatedAt),
        });

        final doc =
            await fakeFirestore.collection('families').doc('family1').get();
        final result = FamilyModel.fromFirestore(doc);

        expect(result.familyId, 'family1');
        expect(result.parentUid, 'parent1');
        expect(result.childUids, ['child1', 'child2']);
        expect(result.linkingCode, 'ABC123');
        expect(result.createdAt, tCreatedAt);
        expect(result.updatedAt, tUpdatedAt);
      });

      test('should use defaults when fields are missing', () async {
        await fakeFirestore.collection('families').doc('family2').set({});

        final doc =
            await fakeFirestore.collection('families').doc('family2').get();
        final result = FamilyModel.fromFirestore(doc);

        expect(result.familyId, '');
        expect(result.parentUid, '');
        expect(result.childUids, <String>[]);
        expect(result.linkingCode, isNull);
      });

      test('should fallback to DateTime.now when timestamps are null', () async {
        await fakeFirestore.collection('families').doc('family3').set({
          'createdAt': null,
          'updatedAt': null,
        });

        final before = DateTime.now();
        final doc =
            await fakeFirestore.collection('families').doc('family3').get();
        final result = FamilyModel.fromFirestore(doc);
        final after = DateTime.now();

        expect(
          result.createdAt.isAfter(before) ||
              result.createdAt.isAtSameMomentAs(before),
          true,
        );
        expect(
          result.updatedAt.isBefore(after) ||
              result.updatedAt.isAtSameMomentAs(after),
          true,
        );
      });

      test('should handle empty childUids list', () async {
        await fakeFirestore.collection('families').doc('family4').set({
          'childUids': [],
        });

        final doc =
            await fakeFirestore.collection('families').doc('family4').get();
        final result = FamilyModel.fromFirestore(doc);

        expect(result.childUids, isEmpty);
      });
    });

    group('toMap', () {
      test('should return a valid map', () {
        final result = tModel.toMap();

        expect(result['familyId'], 'family1');
        expect(result['parentUid'], 'parent1');
        expect(result['childUids'], ['child1', 'child2']);
        expect(result['linkingCode'], 'ABC123');
        expect(result['createdAt'], isA<FieldValue>());
        expect(result['updatedAt'], isA<FieldValue>());
      });
    });

    group('copyWith', () {
      test('should return same values when no arguments provided', () {
        final result = tModel.copyWith();

        expect(result.familyId, tModel.familyId);
        expect(result.parentUid, tModel.parentUid);
        expect(result.childUids, tModel.childUids);
        expect(result.linkingCode, tModel.linkingCode);
        expect(result.createdAt, tModel.createdAt);
        expect(result.updatedAt, tModel.updatedAt);
      });

      test('should override specified fields', () {
        final newDate = DateTime(2026, 6, 1);
        final result = tModel.copyWith(
          familyId: 'family2',
          parentUid: 'parent2',
          childUids: ['child3'],
          linkingCode: 'XYZ789',
          createdAt: newDate,
          updatedAt: newDate,
        );

        expect(result.familyId, 'family2');
        expect(result.parentUid, 'parent2');
        expect(result.childUids, ['child3']);
        expect(result.linkingCode, 'XYZ789');
        expect(result.createdAt, newDate);
        expect(result.updatedAt, newDate);
      });
    });

    group('Equatable', () {
      test('should be equal when all fields match', () {
        final model1 = FamilyModel(
          familyId: 'f1',
          parentUid: 'p1',
          childUids: ['c1'],
          linkingCode: 'ABC',
          createdAt: tCreatedAt,
          updatedAt: tUpdatedAt,
        );
        final model2 = FamilyModel(
          familyId: 'f1',
          parentUid: 'p1',
          childUids: ['c1'],
          linkingCode: 'ABC',
          createdAt: tCreatedAt,
          updatedAt: tUpdatedAt,
        );

        expect(model1, model2);
      });

      test('should not be equal when fields differ', () {
        final model1 = FamilyModel(
          familyId: 'f1',
          parentUid: 'p1',
          createdAt: tCreatedAt,
          updatedAt: tUpdatedAt,
        );
        final model2 = FamilyModel(
          familyId: 'f2',
          parentUid: 'p1',
          createdAt: tCreatedAt,
          updatedAt: tUpdatedAt,
        );

        expect(model1, isNot(model2));
      });
    });
  });
}
