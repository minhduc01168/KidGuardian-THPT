import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kidguardian/data/models/weekly_report_model.dart';
import 'package:kidguardian/domain/entities/weekly_report.dart';

void main() {
  group('WeeklyReportModel', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    final tGeneratedAt = DateTime(2026, 5, 30, 8, 0);
    final tModel = WeeklyReportModel(
      reportId: 'report1',
      childUid: 'child1',
      familyId: 'family1',
      weekStartDate: '2026-05-24',
      weekEndDate: '2026-05-30',
      totalMinutes: 600,
      previousWeekMinutes: 500,
      usageByApp: {'com.example.app1': 300, 'com.example.app2': 300},
      previousWeekUsageByApp: {'com.example.app1': 250, 'com.example.app2': 250},
      topApps: ['com.example.app1', 'com.example.app2'],
      alertCount: 3,
      violationCount: 1,
      percentChange: 20.0,
      improvements: ['Giảm thời gian sử dụng game'],
      concerns: ['Tăng thời gian mạng xã hội'],
      generatedAt: tGeneratedAt,
    );

    test('should be a subclass of WeeklyReport entity', () {
      expect(tModel, isA<WeeklyReport>());
    });

    group('constructor', () {
      test('should use default values for optional fields', () {
        final model = WeeklyReportModel(
          reportId: 'r1',
          childUid: 'c1',
          familyId: 'f1',
          weekStartDate: '2026-01-01',
          weekEndDate: '2026-01-07',
          totalMinutes: 0,
          previousWeekMinutes: 0,
          usageByApp: {},
          previousWeekUsageByApp: {},
          topApps: [],
          percentChange: 0,
          generatedAt: tGeneratedAt,
        );

        expect(model.alertCount, 0);
        expect(model.violationCount, 0);
        expect(model.improvements, <String>[]);
        expect(model.concerns, <String>[]);
      });
    });

    group('fromFirestore', () {
      test('should return valid model from Firestore document', () async {
        await fakeFirestore.collection('weeklyReports').doc('report1').set({
          'childUid': 'child1',
          'familyId': 'family1',
          'weekStartDate': '2026-05-24',
          'weekEndDate': '2026-05-30',
          'totalMinutes': 600,
          'previousWeekMinutes': 500,
          'usageByApp': {'com.example.app1': 300, 'com.example.app2': 300},
          'previousWeekUsageByApp': {
            'com.example.app1': 250,
            'com.example.app2': 250,
          },
          'topApps': ['com.example.app1', 'com.example.app2'],
          'alertCount': 3,
          'violationCount': 1,
          'percentChange': 20.0,
          'improvements': ['Giảm thời gian sử dụng game'],
          'concerns': ['Tăng thời gian mạng xã hội'],
          'generatedAt': Timestamp.fromDate(tGeneratedAt),
        });

        final doc = await fakeFirestore
            .collection('weeklyReports')
            .doc('report1')
            .get();
        final result = WeeklyReportModel.fromFirestore(doc);

        expect(result.reportId, 'report1');
        expect(result.childUid, 'child1');
        expect(result.familyId, 'family1');
        expect(result.weekStartDate, '2026-05-24');
        expect(result.weekEndDate, '2026-05-30');
        expect(result.totalMinutes, 600);
        expect(result.previousWeekMinutes, 500);
        expect(result.usageByApp, {
          'com.example.app1': 300,
          'com.example.app2': 300,
        });
        expect(result.previousWeekUsageByApp, {
          'com.example.app1': 250,
          'com.example.app2': 250,
        });
        expect(result.topApps, ['com.example.app1', 'com.example.app2']);
        expect(result.alertCount, 3);
        expect(result.violationCount, 1);
        expect(result.percentChange, 20.0);
        expect(result.improvements, ['Giảm thời gian sử dụng game']);
        expect(result.concerns, ['Tăng thời gian mạng xã hội']);
        expect(result.generatedAt, tGeneratedAt);
      });

      test('should use defaults when fields are missing', () async {
        await fakeFirestore.collection('weeklyReports').doc('report2').set({});

        final doc = await fakeFirestore
            .collection('weeklyReports')
            .doc('report2')
            .get();
        final result = WeeklyReportModel.fromFirestore(doc);

        expect(result.reportId, 'report2');
        expect(result.childUid, '');
        expect(result.familyId, '');
        expect(result.weekStartDate, '');
        expect(result.weekEndDate, '');
        expect(result.totalMinutes, 0);
        expect(result.previousWeekMinutes, 0);
        expect(result.usageByApp, <String, int>{});
        expect(result.previousWeekUsageByApp, <String, int>{});
        expect(result.topApps, <String>[]);
        expect(result.alertCount, 0);
        expect(result.violationCount, 0);
        expect(result.percentChange, 0.0);
        expect(result.improvements, <String>[]);
        expect(result.concerns, <String>[]);
      });

      test('should convert int percentChange to double', () async {
        await fakeFirestore.collection('weeklyReports').doc('report3').set({
          'percentChange': 15,
        });

        final doc = await fakeFirestore
            .collection('weeklyReports')
            .doc('report3')
            .get();
        final result = WeeklyReportModel.fromFirestore(doc);

        expect(result.percentChange, 15.0);
        expect(result.percentChange, isA<double>());
      });

      test('should fallback to DateTime.now when generatedAt is null', () async {
        await fakeFirestore.collection('weeklyReports').doc('report4').set({
          'generatedAt': null,
        });

        final before = DateTime.now();
        final doc = await fakeFirestore
            .collection('weeklyReports')
            .doc('report4')
            .get();
        final result = WeeklyReportModel.fromFirestore(doc);
        final after = DateTime.now();

        expect(
          result.generatedAt.isAfter(before) ||
              result.generatedAt.isAtSameMomentAs(before),
          true,
        );
        expect(
          result.generatedAt.isBefore(after) ||
              result.generatedAt.isAtSameMomentAs(after),
          true,
        );
      });
    });

    group('toMap', () {
      test('should return a valid map', () {
        final result = tModel.toMap();

        expect(result['childUid'], 'child1');
        expect(result['familyId'], 'family1');
        expect(result['weekStartDate'], '2026-05-24');
        expect(result['weekEndDate'], '2026-05-30');
        expect(result['totalMinutes'], 600);
        expect(result['previousWeekMinutes'], 500);
        expect(result['usageByApp'], {
          'com.example.app1': 300,
          'com.example.app2': 300,
        });
        expect(result['previousWeekUsageByApp'], {
          'com.example.app1': 250,
          'com.example.app2': 250,
        });
        expect(result['topApps'], ['com.example.app1', 'com.example.app2']);
        expect(result['alertCount'], 3);
        expect(result['violationCount'], 1);
        expect(result['percentChange'], 20.0);
        expect(result['improvements'], ['Giảm thời gian sử dụng game']);
        expect(result['concerns'], ['Tăng thời gian mạng xã hội']);
        expect(result['generatedAt'], isA<Timestamp>());
      });

      test('should not include reportId in map', () {
        final result = tModel.toMap();
        expect(result.containsKey('reportId'), false);
      });
    });

    group('Equatable', () {
      test('should be equal when all fields match', () {
        final model1 = WeeklyReportModel(
          reportId: 'r1',
          childUid: 'c1',
          familyId: 'f1',
          weekStartDate: '2026-01-01',
          weekEndDate: '2026-01-07',
          totalMinutes: 100,
          previousWeekMinutes: 80,
          usageByApp: {'app': 100},
          previousWeekUsageByApp: {'app': 80},
          topApps: ['app'],
          percentChange: 25.0,
          generatedAt: tGeneratedAt,
        );
        final model2 = WeeklyReportModel(
          reportId: 'r1',
          childUid: 'c1',
          familyId: 'f1',
          weekStartDate: '2026-01-01',
          weekEndDate: '2026-01-07',
          totalMinutes: 100,
          previousWeekMinutes: 80,
          usageByApp: {'app': 100},
          previousWeekUsageByApp: {'app': 80},
          topApps: ['app'],
          percentChange: 25.0,
          generatedAt: tGeneratedAt,
        );

        expect(model1, model2);
      });

      test('should not be equal when fields differ', () {
        final model1 = WeeklyReportModel(
          reportId: 'r1',
          childUid: 'c1',
          familyId: 'f1',
          weekStartDate: '2026-01-01',
          weekEndDate: '2026-01-07',
          totalMinutes: 100,
          previousWeekMinutes: 80,
          usageByApp: {},
          previousWeekUsageByApp: {},
          topApps: [],
          percentChange: 25.0,
          generatedAt: tGeneratedAt,
        );
        final model2 = WeeklyReportModel(
          reportId: 'r2',
          childUid: 'c1',
          familyId: 'f1',
          weekStartDate: '2026-01-01',
          weekEndDate: '2026-01-07',
          totalMinutes: 100,
          previousWeekMinutes: 80,
          usageByApp: {},
          previousWeekUsageByApp: {},
          topApps: [],
          percentChange: 25.0,
          generatedAt: tGeneratedAt,
        );

        expect(model1, isNot(model2));
      });
    });
  });
}
