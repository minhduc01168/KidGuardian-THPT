import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kidguardian/data/repositories/usage_repository_impl.dart';
import 'package:kidguardian/domain/entities/usage_log.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}

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
      when(() => mockUsageLogsCollection.add(any())).thenAnswer((_) async => MockDocumentReference());

      // act
      await repository.logUsage(log);

      // assert
      verify(() => mockUsageLogsCollection.add(any())).called(1);
    });
  });
}
