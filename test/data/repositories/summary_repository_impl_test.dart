import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kidguardian/data/repositories/summary_repository_impl.dart';
import 'package:kidguardian/domain/entities/usage_log.dart';
import 'package:kidguardian/domain/repositories/usage_repository.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}
class MockUsageRepository extends Mock implements UsageRepository {}
class MockAlertRepository extends Mock implements AlertRepository {}

void main() {
  late SummaryRepositoryImpl repository;
  late MockFirebaseFirestore mockFirestore;
  late MockUsageRepository mockUsageRepository;
  late MockAlertRepository mockAlertRepository;
  late MockCollectionReference mockSummariesCollection;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockUsageRepository = MockUsageRepository();
    mockAlertRepository = MockAlertRepository();
    mockSummariesCollection = MockCollectionReference();

    when(() => mockFirestore.collection('daily_summaries')).thenReturn(mockSummariesCollection);

    repository = SummaryRepositoryImpl(
      firestore: mockFirestore,
      usageRepository: mockUsageRepository,
      alertRepository: mockAlertRepository,
    );
  });

  group('SummaryRepositoryImpl', () {
    group('getSummariesByChild', () {
      test('should return empty list when no summaries exist', () async {
        final mockQuerySnapshot = MockQuerySnapshot();
        when(() => mockSummariesCollection.where('childUid', isEqualTo: any(named: 'isEqualTo')))
            .thenReturn(mockSummariesCollection);
        when(() => mockSummariesCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(() => mockQuerySnapshot.docs).thenReturn([]);

        final result = await repository.getSummariesByChild('child-1');

        expect(result, isEmpty);
      });

      test('should return summaries when they exist', () async {
        final mockQuerySnapshot = MockQuerySnapshot();
        final mockDoc = MockQueryDocumentSnapshot();

        when(() => mockSummariesCollection.where('childUid', isEqualTo: any(named: 'isEqualTo')))
            .thenReturn(mockSummariesCollection);
        when(() => mockSummariesCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(() => mockQuerySnapshot.docs).thenReturn([mockDoc]);
        when(() => mockDoc.id).thenReturn('summary-1');
        when(() => mockDoc.data()).thenReturn({
          'childUid': 'child-1',
          'familyId': 'family-1',
          'date': '2026-05-24',
          'totalMinutes': 90,
          'usageByApp': {'YouTube': 60, 'TikTok': 30},
          'topApps': ['YouTube', 'TikTok'],
          'alertCount': 2,
          'violationCount': 0,
          'sent': false,
        });

        final result = await repository.getSummariesByChild('child-1');

        expect(result.length, 1);
        expect(result.first.childUid, 'child-1');
        expect(result.first.totalMinutes, 90);
      });

      test('should return empty list on error', () async {
        when(() => mockSummariesCollection.where('childUid', isEqualTo: any(named: 'isEqualTo')))
            .thenReturn(mockSummariesCollection);
        when(() => mockSummariesCollection.get()).thenThrow(Exception('Network error'));

        final result = await repository.getSummariesByChild('child-1');

        expect(result, isEmpty);
      });
    });

    group('getSummariesByFamily', () {
      test('should return empty list when no summaries exist', () async {
        final mockQuerySnapshot = MockQuerySnapshot();
        when(() => mockSummariesCollection.where('familyId', isEqualTo: any(named: 'isEqualTo')))
            .thenReturn(mockSummariesCollection);
        when(() => mockSummariesCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(() => mockQuerySnapshot.docs).thenReturn([]);

        final result = await repository.getSummariesByFamily('family-1');

        expect(result, isEmpty);
      });

      test('should return empty list on error', () async {
        when(() => mockSummariesCollection.where('familyId', isEqualTo: any(named: 'isEqualTo')))
            .thenReturn(mockSummariesCollection);
        when(() => mockSummariesCollection.get()).thenThrow(Exception('Firestore error'));

        final result = await repository.getSummariesByFamily('family-1');

        expect(result, isEmpty);
      });
    });

    group('hasSummaryForDate', () {
      test('should return true when summary exists', () async {
        final mockQuerySnapshot = MockQuerySnapshot();
        final mockDoc = MockQueryDocumentSnapshot();

        when(() => mockDoc.data()).thenReturn({'date': '2026-05-24'});
        when(() => mockSummariesCollection.where('childUid', isEqualTo: any(named: 'isEqualTo')))
            .thenReturn(mockSummariesCollection);
        when(() => mockSummariesCollection.where('date', isEqualTo: any(named: 'isEqualTo')))
            .thenReturn(mockSummariesCollection);
        when(() => mockSummariesCollection.limit(1)).thenReturn(mockSummariesCollection);
        when(() => mockSummariesCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(() => mockQuerySnapshot.docs).thenReturn([mockDoc]);

        final result = await repository.hasSummaryForDate('child-1', '2026-05-24');

        expect(result, isTrue);
      });

      test('should return false when no summary exists', () async {
        final mockQuerySnapshot = MockQuerySnapshot();

        when(() => mockSummariesCollection.where('childUid', isEqualTo: any(named: 'isEqualTo')))
            .thenReturn(mockSummariesCollection);
        when(() => mockSummariesCollection.where('date', isEqualTo: any(named: 'isEqualTo')))
            .thenReturn(mockSummariesCollection);
        when(() => mockSummariesCollection.limit(1)).thenReturn(mockSummariesCollection);
        when(() => mockSummariesCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(() => mockQuerySnapshot.docs).thenReturn([]);

        final result = await repository.hasSummaryForDate('child-1', '2026-05-24');

        expect(result, isFalse);
      });
    });

    group('markAsSent', () {
      test('should update document with sent flag', () async {
        final mockDocRef = MockDocumentReference();
        when(() => mockSummariesCollection.doc('summary-1')).thenReturn(mockDocRef);
        when(() => mockDocRef.update(any())).thenAnswer((_) async {});

        await repository.markAsSent('summary-1');

        final captured = verify(() => mockDocRef.update(captureAny())).captured;
        final updateMap = captured.first as Map;
        expect(updateMap['sent'], isTrue);
        expect(updateMap.containsKey('sentAt'), isTrue);
      });
    });

    group('generateDailySummary', () {
      test('should generate new summary when none exists', () async {
        // hasSummaryForDate returns false
        final mockQuerySnapshotEmpty = MockQuerySnapshot();
        when(() => mockSummariesCollection.where('childUid', isEqualTo: any(named: 'isEqualTo')))
            .thenReturn(mockSummariesCollection);
        when(() => mockSummariesCollection.where('date', isEqualTo: any(named: 'isEqualTo')))
            .thenReturn(mockSummariesCollection);
        when(() => mockSummariesCollection.limit(any())).thenReturn(mockSummariesCollection);
        when(() => mockSummariesCollection.get()).thenAnswer((_) async => mockQuerySnapshotEmpty);
        when(() => mockQuerySnapshotEmpty.docs).thenReturn([]);

        // Usage repository returns logs
        when(() => mockUsageRepository.getUsageByChild('child-1', '2026-05-24'))
            .thenAnswer((_) async => [
                  UsageLog(
                    docId: 'log-1',
                    childUid: 'child-1',
                    familyId: 'family-1',
                    appPackage: 'com.google.android.youtube',
                    appName: 'YouTube',
                    startTime: DateTime(2026, 5, 24, 10, 0),
                    endTime: DateTime(2026, 5, 24, 11, 30),
                    durationMinutes: 90,
                    date: '2026-05-24',
                  ),
                ]);

        // Alert repository returns empty stream
        when(() => mockAlertRepository.watchAllAlerts(
              familyId: 'family-1',
              childUid: 'child-1',
            )).thenAnswer((_) => Stream.value([]));

        // Mock add for saving
        final mockDocRef = MockDocumentReference();
        when(() => mockSummariesCollection.add(any())).thenAnswer((_) async => mockDocRef);
        when(() => mockDocRef.id).thenReturn('new-summary-id');

        final result = await repository.generateDailySummary('child-1', 'family-1', '2026-05-24');

        expect(result, isNotNull);
        expect(result.childUid, 'child-1');
        expect(result.familyId, 'family-1');
        expect(result.totalMinutes, 90);
      });

      test('should filter out unmonitored apps like Gmail and LinkedIn from daily summary', () async {
        final mockQuerySnapshotEmpty = MockQuerySnapshot();
        when(() => mockSummariesCollection.where('childUid', isEqualTo: any(named: 'isEqualTo')))
            .thenReturn(mockSummariesCollection);
        when(() => mockSummariesCollection.where('date', isEqualTo: any(named: 'isEqualTo')))
            .thenReturn(mockSummariesCollection);
        when(() => mockSummariesCollection.limit(any())).thenReturn(mockSummariesCollection);
        when(() => mockSummariesCollection.get()).thenAnswer((_) async => mockQuerySnapshotEmpty);
        when(() => mockQuerySnapshotEmpty.docs).thenReturn([]);

        when(() => mockUsageRepository.getUsageByChild('child-1', '2026-05-24'))
            .thenAnswer((_) async => [
                  UsageLog(
                    docId: 'log-1',
                    childUid: 'child-1',
                    familyId: 'family-1',
                    appPackage: 'com.zhiliaoapp.musically',
                    appName: 'TikTok',
                    startTime: DateTime(2026, 5, 24, 10, 0),
                    endTime: DateTime(2026, 5, 24, 11, 30),
                    durationMinutes: 90, // Monitored
                    date: '2026-05-24',
                  ),
                  UsageLog(
                    docId: 'log-2',
                    childUid: 'child-1',
                    familyId: 'family-1',
                    appPackage: 'com.google.android.gm',
                    appName: 'Gmail',
                    startTime: DateTime(2026, 5, 24, 12, 0),
                    endTime: DateTime(2026, 5, 24, 12, 30),
                    durationMinutes: 30, // Not in default popular list
                    date: '2026-05-24',
                  ),
                  UsageLog(
                    docId: 'log-3',
                    childUid: 'child-1',
                    familyId: 'family-1',
                    appPackage: 'com.linkedin.android',
                    appName: 'LinkedIn',
                    startTime: DateTime(2026, 5, 24, 13, 0),
                    endTime: DateTime(2026, 5, 24, 13, 20),
                    durationMinutes: 20, // Not in default popular list
                    date: '2026-05-24',
                  ),
                ]);

        when(() => mockAlertRepository.watchAllAlerts(
              familyId: 'family-1',
              childUid: 'child-1',
            )).thenAnswer((_) => Stream.value([]));

        final mockDocRef = MockDocumentReference();
        when(() => mockSummariesCollection.add(any())).thenAnswer((_) async => mockDocRef);
        when(() => mockDocRef.id).thenReturn('new-summary-id');

        final result = await repository.generateDailySummary('child-1', 'family-1', '2026-05-24');

        expect(result.totalMinutes, 90); // Only TikTok (90) should be counted, Gmail(30) + LinkedIn(20) excluded
        expect(result.usageByApp.keys, contains('TikTok'));
        expect(result.usageByApp.keys, isNot(contains('Gmail')));
        expect(result.usageByApp.keys, isNot(contains('LinkedIn')));
      });
    });
  });
}
