import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kidguardian/data/models/daily_summary_model.dart';
import 'package:kidguardian/domain/entities/daily_summary.dart';

void main() {
  group('DailySummaryModel', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    final sentAt = DateTime(2026, 5, 30, 18, 0);
    final tModel = DailySummaryModel(
      summaryId: 'sum1',
      childUid: 'child1',
      familyId: 'family1',
      date: '2026-05-30',
      totalMinutes: 120,
      usageByApp: {'com.example.app1': 60, 'com.example.app2': 60},
      topApps: ['com.example.app1', 'com.example.app2'],
      alertCount: 2,
      violationCount: 1,
      sent: true,
      sentAt: sentAt,
    );

    test('should be a subclass of DailySummary entity', () {
      expect(tModel, isA<DailySummary>());
    });

    group('constructor', () {
      test('should use default values for optional fields', () {
        const model = DailySummaryModel(
          summaryId: 's1',
          childUid: 'c1',
          familyId: 'f1',
          date: '2026-01-01',
          totalMinutes: 0,
          usageByApp: {},
          topApps: [],
        );

        expect(model.alertCount, 0);
        expect(model.violationCount, 0);
        expect(model.sent, false);
        expect(model.sentAt, isNull);
      });
    });

    group('fromFirestore', () {
      test('should return valid model from Firestore document', () async {
        await fakeFirestore.collection('dailySummaries').doc('sum1').set({
          'childUid': 'child1',
          'familyId': 'family1',
          'date': '2026-05-30',
          'totalMinutes': 120,
          'usageByApp': {'com.example.app1': 60, 'com.example.app2': 60},
          'topApps': ['com.example.app1', 'com.example.app2'],
          'alertCount': 2,
          'violationCount': 1,
          'sent': true,
          'sentAt': Timestamp.fromDate(sentAt),
        });

        final doc =
            await fakeFirestore.collection('dailySummaries').doc('sum1').get();
        final result = DailySummaryModel.fromFirestore(doc);

        expect(result.summaryId, 'sum1');
        expect(result.childUid, 'child1');
        expect(result.familyId, 'family1');
        expect(result.date, '2026-05-30');
        expect(result.totalMinutes, 120);
        expect(result.usageByApp, {
          'com.example.app1': 60,
          'com.example.app2': 60,
        });
        expect(result.topApps, ['com.example.app1', 'com.example.app2']);
        expect(result.alertCount, 2);
        expect(result.violationCount, 1);
        expect(result.sent, true);
        expect(result.sentAt, sentAt);
      });

      test('should use defaults when fields are missing', () async {
        await fakeFirestore.collection('dailySummaries').doc('sum2').set({});

        final doc =
            await fakeFirestore.collection('dailySummaries').doc('sum2').get();
        final result = DailySummaryModel.fromFirestore(doc);

        expect(result.summaryId, 'sum2');
        expect(result.childUid, '');
        expect(result.familyId, '');
        expect(result.date, '');
        expect(result.totalMinutes, 0);
        expect(result.usageByApp, <String, int>{});
        expect(result.topApps, <String>[]);
        expect(result.alertCount, 0);
        expect(result.violationCount, 0);
        expect(result.sent, false);
        expect(result.sentAt, isNull);
      });

      test('should handle null sentAt', () async {
        await fakeFirestore.collection('dailySummaries').doc('sum3').set({
          'childUid': 'child1',
          'sentAt': null,
        });

        final doc =
            await fakeFirestore.collection('dailySummaries').doc('sum3').get();
        final result = DailySummaryModel.fromFirestore(doc);

        expect(result.sentAt, isNull);
      });
    });

    group('toMap', () {
      test('should return a valid map', () {
        final result = tModel.toMap();

        expect(result['childUid'], 'child1');
        expect(result['familyId'], 'family1');
        expect(result['date'], '2026-05-30');
        expect(result['totalMinutes'], 120);
        expect(result['usageByApp'], {
          'com.example.app1': 60,
          'com.example.app2': 60,
        });
        expect(result['topApps'], ['com.example.app1', 'com.example.app2']);
        expect(result['alertCount'], 2);
        expect(result['violationCount'], 1);
        expect(result['sent'], true);
        expect(result['sentAt'], isA<Timestamp>());
      });

      test('should return null sentAt when not set', () {
        const model = DailySummaryModel(
          summaryId: 's1',
          childUid: 'c1',
          familyId: 'f1',
          date: '2026-01-01',
          totalMinutes: 0,
          usageByApp: {},
          topApps: [],
        );

        final result = model.toMap();
        expect(result['sentAt'], isNull);
      });

      test('should not include summaryId in map', () {
        final result = tModel.toMap();
        expect(result.containsKey('summaryId'), false);
      });
    });

    group('Equatable', () {
      test('should be equal when all fields match', () {
        final model1 = DailySummaryModel(
          summaryId: 's1',
          childUid: 'c1',
          familyId: 'f1',
          date: '2026-01-01',
          totalMinutes: 60,
          usageByApp: {'app': 60},
          topApps: ['app'],
        );
        final model2 = DailySummaryModel(
          summaryId: 's1',
          childUid: 'c1',
          familyId: 'f1',
          date: '2026-01-01',
          totalMinutes: 60,
          usageByApp: {'app': 60},
          topApps: ['app'],
        );

        expect(model1, model2);
      });

      test('should not be equal when fields differ', () {
        final model1 = DailySummaryModel(
          summaryId: 's1',
          childUid: 'c1',
          familyId: 'f1',
          date: '2026-01-01',
          totalMinutes: 60,
          usageByApp: {},
          topApps: [],
        );
        final model2 = DailySummaryModel(
          summaryId: 's2',
          childUid: 'c1',
          familyId: 'f1',
          date: '2026-01-01',
          totalMinutes: 60,
          usageByApp: {},
          topApps: [],
        );

        expect(model1, isNot(model2));
      });
    });
  });
}
