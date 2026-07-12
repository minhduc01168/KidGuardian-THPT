import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kidguardian/data/repositories/usage_repository_impl.dart';
import 'package:kidguardian/domain/entities/usage_log.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late UsageRepositoryImpl repository;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockUsageLogsCollection;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockUsageLogsCollection = MockCollectionReference();

    when(() => mockFirestore.collection('usage_logs')).thenReturn(mockUsageLogsCollection);

    repository = UsageRepositoryImpl(firestore: mockFirestore);
  });

  group('UsageRepositoryImpl', () {
    final startTime = DateTime(2026, 5, 16, 10, 0);
    final endTime = DateTime(2026, 5, 16, 10, 30);
    final log = UsageLog(
      docId: '',
      childUid: 'child1',
      familyId: 'family1',
      appPackage: 'com.example.app',
      appName: 'Example App',
      startTime: startTime,
      endTime: endTime,
      durationMinutes: 30,
      date: '2026-05-16',
    );

    test('logUsage should add data to collection', () async {
      // arrange
      final mockDocRef = MockDocumentReference();
      when(() => mockDocRef.id).thenReturn('mock-id-123');
      when(() => mockUsageLogsCollection.add(any())).thenAnswer((_) async => mockDocRef);

      // act
      await repository.logUsage(log);

      // assert
      verify(() => mockUsageLogsCollection.add(any())).called(1);
    });

    test('getUsageByChild Server-Side Index mode', () async {
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDoc1 = MockQueryDocumentSnapshot();

      when(() => mockUsageLogsCollection.where(any(),
              isEqualTo: any(named: 'isEqualTo'),
              isGreaterThanOrEqualTo: any(named: 'isGreaterThanOrEqualTo'),
              isLessThanOrEqualTo: any(named: 'isLessThanOrEqualTo')))
          .thenReturn(mockUsageLogsCollection);
      when(() => mockUsageLogsCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(() => mockQuerySnapshot.docs).thenReturn([mockDoc1]);

      when(() => mockDoc1.id).thenReturn('log-1');
      when(() => mockDoc1.data()).thenReturn({
        'childUid': 'child1',
        'familyId': 'family1',
        'appPackage': 'com.youtube',
        'appName': 'YouTube',
        'startTime': Timestamp.fromDate(DateTime(2026, 5, 16, 10, 0)),
        'endTime': Timestamp.fromDate(DateTime(2026, 5, 16, 11, 0)),
        'durationMinutes': 60,
        'date': '2026-05-16',
      });

      final result = await repository.getUsageByChild('child1', '2026-05-16');

      expect(result.length, 1);
      expect(result.first.date, '2026-05-16');
    });

    test('getUsageByChild RAM Fallback mode when failed-precondition thrown', () async {
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDoc1 = MockQueryDocumentSnapshot();
      final mockDoc2 = MockQueryDocumentSnapshot();

      var callCount = 0;
      when(() => mockUsageLogsCollection.where(any(),
              isEqualTo: any(named: 'isEqualTo'),
              isGreaterThanOrEqualTo: any(named: 'isGreaterThanOrEqualTo'),
              isLessThanOrEqualTo: any(named: 'isLessThanOrEqualTo')))
          .thenAnswer((invocation) {
        return mockUsageLogsCollection;
      });

      when(() => mockUsageLogsCollection.get()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw FirebaseException(plugin: 'cloud_firestore', code: 'failed-precondition', message: 'Index missing');
        }
        return mockQuerySnapshot;
      });
      when(() => mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);

      when(() => mockDoc1.id).thenReturn('log-1');
      when(() => mockDoc1.data()).thenReturn({
        'childUid': 'child1',
        'familyId': 'family1',
        'appPackage': 'com.youtube',
        'appName': 'YouTube',
        'startTime': Timestamp.fromDate(DateTime(2026, 5, 16, 10, 0)),
        'endTime': Timestamp.fromDate(DateTime(2026, 5, 16, 11, 0)),
        'durationMinutes': 60,
        'date': '2026-05-16',
      });

      when(() => mockDoc2.id).thenReturn('log-2');
      when(() => mockDoc2.data()).thenReturn({
        'childUid': 'child1',
        'familyId': 'family1',
        'appPackage': 'com.youtube',
        'appName': 'YouTube',
        'startTime': Timestamp.fromDate(DateTime(2026, 5, 15, 10, 0)),
        'endTime': Timestamp.fromDate(DateTime(2026, 5, 15, 11, 0)),
        'durationMinutes': 60,
        'date': '2026-05-15', // outside date
      });

      final result = await repository.getUsageByChild('child1', '2026-05-16');

      expect(result.length, 1);
      expect(result.first.date, '2026-05-16');
    });

    test('getUsageByDateRange RAM Fallback mode when index missing', () async {
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDoc1 = MockQueryDocumentSnapshot();
      final mockDoc2 = MockQueryDocumentSnapshot();

      var callCount = 0;
      when(() => mockUsageLogsCollection.where(any(),
              isEqualTo: any(named: 'isEqualTo'),
              isGreaterThanOrEqualTo: any(named: 'isGreaterThanOrEqualTo'),
              isLessThanOrEqualTo: any(named: 'isLessThanOrEqualTo')))
          .thenReturn(mockUsageLogsCollection);
      when(() => mockUsageLogsCollection.get()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw FirebaseException(plugin: 'cloud_firestore', code: 'failed-precondition');
        }
        return mockQuerySnapshot;
      });
      when(() => mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);

      when(() => mockDoc1.id).thenReturn('log-1');
      when(() => mockDoc1.data()).thenReturn({
        'childUid': 'child1',
        'familyId': 'family1',
        'appPackage': 'com.youtube',
        'appName': 'YouTube',
        'startTime': Timestamp.fromDate(DateTime(2026, 5, 16, 10, 0)),
        'endTime': Timestamp.fromDate(DateTime(2026, 5, 16, 11, 0)),
        'durationMinutes': 60,
        'date': '2026-05-16',
      });

      when(() => mockDoc2.id).thenReturn('log-2');
      when(() => mockDoc2.data()).thenReturn({
        'childUid': 'child1',
        'familyId': 'family1',
        'appPackage': 'com.youtube',
        'appName': 'YouTube',
        'startTime': Timestamp.fromDate(DateTime(2026, 5, 10, 10, 0)),
        'endTime': Timestamp.fromDate(DateTime(2026, 5, 10, 11, 0)),
        'durationMinutes': 60,
        'date': '2026-05-10', // outside target date range
      });

      final result = await repository.getUsageByDateRange('child1', '2026-05-15', '2026-05-20');

      expect(result.length, 1);
      expect(result.first.date, '2026-05-16');
    });

    test('getUsageByDateRange should return empty list on error', () async {
      when(() => mockUsageLogsCollection.where(any(),
              isEqualTo: any(named: 'isEqualTo'),
              isGreaterThanOrEqualTo: any(named: 'isGreaterThanOrEqualTo'),
              isLessThanOrEqualTo: any(named: 'isLessThanOrEqualTo')))
          .thenReturn(mockUsageLogsCollection);
      when(() => mockUsageLogsCollection.get()).thenThrow(Exception('Network error'));

      final result = await repository.getUsageByDateRange('child1', '2026-05-15', '2026-05-20');

      expect(result, isEmpty);
    });
  });
}
