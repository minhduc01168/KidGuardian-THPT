import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kidguardian/data/repositories/smart_lock_repository.dart';
import 'package:kidguardian/data/models/app_time_limit_model.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late SmartLockRepository repository;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockFamiliesCollection;
  late MockDocumentReference mockFamilyDoc;
  late MockCollectionReference mockChildrenCollection;
  late MockDocumentReference mockChildDoc;
  late MockCollectionReference mockTimeLimitsCollection;
  late MockDocumentReference mockAppDoc;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockFamiliesCollection = MockCollectionReference();
    mockFamilyDoc = MockDocumentReference();
    mockChildrenCollection = MockCollectionReference();
    mockChildDoc = MockDocumentReference();
    mockTimeLimitsCollection = MockCollectionReference();
    mockAppDoc = MockDocumentReference();

    when(() => mockFirestore.collection('families')).thenReturn(mockFamiliesCollection);
    when(() => mockFamiliesCollection.doc(any())).thenReturn(mockFamilyDoc);
    when(() => mockFamilyDoc.collection('children')).thenReturn(mockChildrenCollection);
    when(() => mockChildrenCollection.doc(any())).thenReturn(mockChildDoc);
    when(() => mockChildDoc.collection('timeLimits')).thenReturn(mockTimeLimitsCollection);
    when(() => mockTimeLimitsCollection.doc(any())).thenReturn(mockAppDoc);

    repository = SmartLockRepository(firestore: mockFirestore);
  });

  group('SmartLockRepository', () {
    const familyId = 'family1';
    const childId = 'child1';
    final limitModel = AppTimeLimitModel(
      appPackageName: 'com.zhiliaoapp.musically',
      appName: 'TikTok',
      limits: const {'everyday': 60},
    );

    test('getAppTimeLimits should return a list of AppTimeLimitModel', () async {
      // arrange
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDocSnapshot = MockQueryDocumentSnapshot();
      
      when(() => mockDocSnapshot.data()).thenReturn({
        'appPackageName': 'com.zhiliaoapp.musically',
        'appName': 'TikTok',
        'limits': {'everyday': 60},
      });
      
      when(() => mockQuerySnapshot.docs).thenReturn([mockDocSnapshot]);
      when(() => mockTimeLimitsCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

      // act
      final result = await repository.getAppTimeLimits(familyId, childId);

      // assert
      expect(result, [limitModel]);
      verify(() => mockTimeLimitsCollection.get()).called(1);
    });

    test('saveAppTimeLimit should set data to correct document', () async {
      // arrange
      when(() => mockAppDoc.set(any())).thenAnswer((_) async {});

      // act
      await repository.saveAppTimeLimit(familyId, childId, limitModel);

      // assert
      verify(() => mockTimeLimitsCollection.doc('com.zhiliaoapp.musically')).called(1);
      verify(() => mockAppDoc.set(limitModel.toJson())).called(1);
    });
  });
}
