import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kidguardian/data/repositories/report_repository_impl.dart';
import 'package:kidguardian/data/services/email_service.dart';
import 'package:kidguardian/domain/entities/usage_log.dart';
import 'package:kidguardian/domain/entities/weekly_report.dart';
import 'package:kidguardian/domain/repositories/usage_repository.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}
class MockUsageRepository extends Mock implements UsageRepository {}
class MockEmailService extends Mock implements EmailService {}

class FakeWeeklyReport extends Fake implements WeeklyReport {}

void main() {
  late ReportRepositoryImpl repository;
  late MockFirebaseFirestore mockFirestore;
  late MockUsageRepository mockUsageRepository;
  late MockEmailService mockEmailService;
  late MockCollectionReference mockReportsCollection;

  setUpAll(() {
    registerFallbackValue(FakeWeeklyReport());
  });

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockUsageRepository = MockUsageRepository();
    mockEmailService = MockEmailService();
    mockReportsCollection = MockCollectionReference();

    when(() => mockFirestore.collection('weekly_reports')).thenReturn(mockReportsCollection);

    repository = ReportRepositoryImpl(
      firestore: mockFirestore,
      usageRepository: mockUsageRepository,
      emailService: mockEmailService,
    );
  });

  group('ReportRepositoryImpl', () {
    group('getReportsByChild', () {
      test('should return empty list when no reports exist', () async {
        final mockQuerySnapshot = MockQuerySnapshot();
        when(() => mockReportsCollection.where('childUid', isEqualTo: any(named: 'isEqualTo')))
            .thenReturn(mockReportsCollection);
        when(() => mockReportsCollection.orderBy('generatedAt', descending: true))
            .thenReturn(mockReportsCollection);
        when(() => mockReportsCollection.limit(4)).thenReturn(mockReportsCollection);
        when(() => mockReportsCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(() => mockQuerySnapshot.docs).thenReturn([]);

        final result = await repository.getReportsByChild('child-1');

        expect(result, isEmpty);
      });

      test('should return reports when they exist', () async {
        final mockQuerySnapshot = MockQuerySnapshot();
        final mockDoc = MockQueryDocumentSnapshot();

        when(() => mockReportsCollection.where('childUid', isEqualTo: any(named: 'isEqualTo')))
            .thenReturn(mockReportsCollection);
        when(() => mockReportsCollection.orderBy('generatedAt', descending: true))
            .thenReturn(mockReportsCollection);
        when(() => mockReportsCollection.limit(4)).thenReturn(mockReportsCollection);
        when(() => mockReportsCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(() => mockQuerySnapshot.docs).thenReturn([mockDoc]);
        when(() => mockDoc.id).thenReturn('report-1');
        when(() => mockDoc.data()).thenReturn({
          'childUid': 'child-1',
          'familyId': 'family-1',
          'weekStartDate': '2026-05-18',
          'weekEndDate': '2026-05-24',
          'totalMinutes': 120,
          'previousWeekMinutes': 100,
          'usageByApp': {'YouTube': 60, 'TikTok': 60},
          'previousWeekUsageByApp': {'YouTube': 50, 'TikTok': 50},
          'topApps': ['YouTube', 'TikTok'],
          'percentChange': 20.0,
          'improvements': [],
          'concerns': ['Tăng 20% thời gian sử dụng'],
          'generatedAt': Timestamp.fromDate(DateTime(2026, 5, 24)),
        });

        final result = await repository.getReportsByChild('child-1');

        expect(result.length, 1);
        expect(result.first.childUid, 'child-1');
      });

      test('should return empty list on error', () async {
        when(() => mockReportsCollection.where('childUid', isEqualTo: any(named: 'isEqualTo')))
            .thenReturn(mockReportsCollection);
        when(() => mockReportsCollection.orderBy('generatedAt', descending: true))
            .thenReturn(mockReportsCollection);
        when(() => mockReportsCollection.limit(4)).thenReturn(mockReportsCollection);
        when(() => mockReportsCollection.get()).thenThrow(Exception('Network error'));

        final result = await repository.getReportsByChild('child-1');

        expect(result, isEmpty);
      });
    });

    group('getReportsByFamily', () {
      test('should return empty list when no reports exist', () async {
        final mockQuerySnapshot = MockQuerySnapshot();
        when(() => mockReportsCollection.where('familyId', isEqualTo: any(named: 'isEqualTo')))
            .thenReturn(mockReportsCollection);
        when(() => mockReportsCollection.orderBy('generatedAt', descending: true))
            .thenReturn(mockReportsCollection);
        when(() => mockReportsCollection.limit(4)).thenReturn(mockReportsCollection);
        when(() => mockReportsCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(() => mockQuerySnapshot.docs).thenReturn([]);

        final result = await repository.getReportsByFamily('family-1');

        expect(result, isEmpty);
      });

      test('should return empty list on error', () async {
        when(() => mockReportsCollection.where('familyId', isEqualTo: any(named: 'isEqualTo')))
            .thenReturn(mockReportsCollection);
        when(() => mockReportsCollection.orderBy('generatedAt', descending: true))
            .thenReturn(mockReportsCollection);
        when(() => mockReportsCollection.limit(4)).thenReturn(mockReportsCollection);
        when(() => mockReportsCollection.get()).thenThrow(Exception('Firestore error'));

        final result = await repository.getReportsByFamily('family-1');

        expect(result, isEmpty);
      });
    });

    group('getLatestReport', () {
      test('should return null when no reports exist', () async {
        final mockQuerySnapshot = MockQuerySnapshot();
        when(() => mockReportsCollection.where('childUid', isEqualTo: any(named: 'isEqualTo')))
            .thenReturn(mockReportsCollection);
        when(() => mockReportsCollection.orderBy('generatedAt', descending: true))
            .thenReturn(mockReportsCollection);
        when(() => mockReportsCollection.limit(any())).thenReturn(mockReportsCollection);
        when(() => mockReportsCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(() => mockQuerySnapshot.docs).thenReturn([]);

        final result = await repository.getLatestReport('child-1');

        expect(result, isNull);
      });
    });

    group('sendReportByEmail', () {
      test('should call email service and return result', () async {
        final report = WeeklyReport(
          reportId: 'report-1',
          childUid: 'child-1',
          familyId: 'family-1',
          weekStartDate: '2026-05-18',
          weekEndDate: '2026-05-24',
          totalMinutes: 120,
          previousWeekMinutes: 100,
          usageByApp: {'YouTube': 60},
          previousWeekUsageByApp: {'YouTube': 50},
          topApps: ['YouTube'],
          percentChange: 20.0,
          generatedAt: DateTime(2026, 5, 24),
        );

        when(() => mockEmailService.sendWeeklyReport(
              recipientEmail: 'parent@test.com',
              report: any(named: 'report'),
              childName: 'Child',
            )).thenAnswer((_) async => true);

        final result = await repository.sendReportByEmail(
          recipientEmail: 'parent@test.com',
          report: report,
          childName: 'Child',
        );

        expect(result, isTrue);
      });

      test('should return false when email service fails', () async {
        final report = WeeklyReport(
          reportId: 'report-1',
          childUid: 'child-1',
          familyId: 'family-1',
          weekStartDate: '2026-05-18',
          weekEndDate: '2026-05-24',
          totalMinutes: 120,
          previousWeekMinutes: 100,
          usageByApp: {},
          previousWeekUsageByApp: {},
          topApps: [],
          percentChange: 0,
          generatedAt: DateTime(2026, 5, 24),
        );

        when(() => mockEmailService.sendWeeklyReport(
              recipientEmail: 'parent@test.com',
              report: any(named: 'report'),
              childName: 'Child',
            )).thenAnswer((_) async => false);

        final result = await repository.sendReportByEmail(
          recipientEmail: 'parent@test.com',
          report: report,
          childName: 'Child',
        );

        expect(result, isFalse);
      });
    });

    group('updateEmailPreference', () {
      test('should call email service and return true', () async {
        when(() => mockEmailService.updateEmailPreference(
              uid: 'uid-1',
              enabled: true,
            )).thenAnswer((_) async => true);

        final result = await repository.updateEmailPreference(
          uid: 'uid-1',
          enabled: true,
        );

        expect(result, isTrue);
      });

      test('should return false when service fails', () async {
        when(() => mockEmailService.updateEmailPreference(
              uid: 'uid-1',
              enabled: false,
            )).thenAnswer((_) async => false);

        final result = await repository.updateEmailPreference(
          uid: 'uid-1',
          enabled: false,
        );

        expect(result, isFalse);
      });
    });

    group('getEmailPreference', () {
      test('should return true when email report is enabled', () async {
        final mockUsersCollection = MockCollectionReference();
        final mockUserDoc = MockDocumentReference();
        final mockSnapshot = MockDocumentSnapshot();

        when(() => mockFirestore.collection('users')).thenReturn(mockUsersCollection);
        when(() => mockUsersCollection.doc('uid-1')).thenReturn(mockUserDoc);
        when(() => mockUserDoc.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.exists).thenReturn(true);
        when(() => mockSnapshot.data()).thenReturn({'emailReportEnabled': true});

        final result = await repository.getEmailPreference('uid-1');

        expect(result, isTrue);
      });

      test('should return false when email report is disabled', () async {
        final mockUsersCollection = MockCollectionReference();
        final mockUserDoc = MockDocumentReference();
        final mockSnapshot = MockDocumentSnapshot();

        when(() => mockFirestore.collection('users')).thenReturn(mockUsersCollection);
        when(() => mockUsersCollection.doc('uid-1')).thenReturn(mockUserDoc);
        when(() => mockUserDoc.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.exists).thenReturn(true);
        when(() => mockSnapshot.data()).thenReturn({'emailReportEnabled': false});

        final result = await repository.getEmailPreference('uid-1');

        expect(result, isFalse);
      });

      test('should return false when document does not exist', () async {
        final mockUsersCollection = MockCollectionReference();
        final mockUserDoc = MockDocumentReference();
        final mockSnapshot = MockDocumentSnapshot();

        when(() => mockFirestore.collection('users')).thenReturn(mockUsersCollection);
        when(() => mockUsersCollection.doc('uid-1')).thenReturn(mockUserDoc);
        when(() => mockUserDoc.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.exists).thenReturn(false);

        final result = await repository.getEmailPreference('uid-1');

        expect(result, isFalse);
      });

      test('should return false on error', () async {
        final mockUsersCollection = MockCollectionReference();
        final mockUserDoc = MockDocumentReference();

        when(() => mockFirestore.collection('users')).thenReturn(mockUsersCollection);
        when(() => mockUsersCollection.doc('uid-1')).thenReturn(mockUserDoc);
        when(() => mockUserDoc.get()).thenThrow(Exception('Network error'));

        final result = await repository.getEmailPreference('uid-1');

        expect(result, isFalse);
      });
    });

    group('generateWeeklyReport', () {
      test('should calculate real-time weekly report and save to firestore', () async {
        final mockQuerySnapshot = MockQuerySnapshot();

        when(() => mockReportsCollection.where('childUid', isEqualTo: any(named: 'isEqualTo')))
            .thenReturn(mockReportsCollection);
        when(() => mockReportsCollection.where('weekStartDate', isEqualTo: any(named: 'isEqualTo')))
            .thenReturn(mockReportsCollection);
        when(() => mockReportsCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(() => mockQuerySnapshot.docs).thenReturn([]);

        when(() => mockUsageRepository.getUsageByDateRange(
              any(), any(), any(),
            )).thenAnswer((_) async => [
          UsageLog(
            docId: 'log-1',
            childUid: 'child-1',
            familyId: 'family-1',
            appPackage: 'com.google.android.youtube',
            appName: 'YouTube',
            startTime: DateTime(2026, 5, 20, 10, 0),
            endTime: DateTime(2026, 5, 20, 12, 0),
            durationMinutes: 120,
            date: '2026-05-20',
          ),
        ]);

        final mockDocRef = MockDocumentReference();
        when(() => mockReportsCollection.add(any())).thenAnswer((_) async => mockDocRef);
        when(() => mockDocRef.id).thenReturn('report-1');

        final result = await repository.generateWeeklyReport('child-1', 'family-1');

        expect(result, isNotNull);
        expect(result.childUid, 'child-1');
        expect(result.totalMinutes, 120);
      });

      test('should generate new report when none exists for this week', () async {
        final mockQuerySnapshot = MockQuerySnapshot();
        final mockDocRef = MockDocumentReference();

        when(() => mockReportsCollection.where('childUid', isEqualTo: any(named: 'isEqualTo')))
            .thenReturn(mockReportsCollection);
        when(() => mockReportsCollection.where('weekStartDate', isEqualTo: any(named: 'isEqualTo')))
            .thenReturn(mockReportsCollection);
        when(() => mockReportsCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(() => mockQuerySnapshot.docs).thenReturn([]);

        when(() => mockUsageRepository.getUsageByDateRange(
              any(), any(), any(),
            )).thenAnswer((_) async => [
          UsageLog(
            docId: 'log-1',
            childUid: 'child-1',
            familyId: 'family-1',
            appPackage: 'com.google.android.youtube',
            appName: 'YouTube',
            startTime: DateTime(2026, 5, 20, 10, 0),
            endTime: DateTime(2026, 5, 20, 11, 0),
            durationMinutes: 60,
            date: '2026-05-20',
          ),
        ]);

        when(() => mockReportsCollection.add(any())).thenAnswer((_) async => mockDocRef);
        when(() => mockDocRef.id).thenReturn('new-report-id');

        final result = await repository.generateWeeklyReport('child-1', 'family-1');

        expect(result, isNotNull);
        expect(result.childUid, 'child-1');
        expect(result.familyId, 'family-1');
      });
    });
  });
}
