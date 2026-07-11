import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kidguardian/data/repositories/smart_lock_repository.dart';
import 'package:kidguardian/data/models/app_time_limit_model.dart';
import 'package:kidguardian/data/models/monitored_app_model.dart';
import 'package:kidguardian/data/models/schedule_model.dart';

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

  group('SmartLockRepository - Monitored Apps', () {
    const familyId = 'family1';
    const childId = 'child1';
    late MockCollectionReference mockMonitoredAppsCollection;
    late MockDocumentReference mockMonitoredAppDoc;

    setUp(() {
      mockMonitoredAppsCollection = MockCollectionReference();
      mockMonitoredAppDoc = MockDocumentReference();

      when(() => mockChildDoc.collection('monitoredApps'))
          .thenReturn(mockMonitoredAppsCollection);
      when(() => mockMonitoredAppsCollection.doc(any()))
          .thenReturn(mockMonitoredAppDoc);
    });

    test('getMonitoredApps should return a list of MonitoredAppModel', () async {
      // arrange
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDocSnapshot = MockQueryDocumentSnapshot();

      when(() => mockDocSnapshot.data()).thenReturn({
        'appPackageName': 'com.zhiliaoapp.musically',
        'appName': 'TikTok',
        'isMonitored': true,
      });

      when(() => mockQuerySnapshot.docs).thenReturn([mockDocSnapshot]);
      when(() => mockMonitoredAppsCollection.get())
          .thenAnswer((_) async => mockQuerySnapshot);

      // act
      final result = await repository.getMonitoredApps(familyId, childId);

      // assert
      expect(result, isA<List<MonitoredAppModel>>());
      expect(result.length, 1);
      expect(result.first.appPackageName, 'com.zhiliaoapp.musically');
      expect(result.first.isMonitored, true);
      verify(() => mockMonitoredAppsCollection.get()).called(1);
    });

    test('getMonitoredApps should return empty list when no documents', () async {
      // arrange
      final mockQuerySnapshot = MockQuerySnapshot();
      when(() => mockQuerySnapshot.docs).thenReturn([]);
      when(() => mockMonitoredAppsCollection.get())
          .thenAnswer((_) async => mockQuerySnapshot);

      // act
      final result = await repository.getMonitoredApps(familyId, childId);

      // assert
      expect(result, isEmpty);
    });

    test('toggleMonitoredApp should set data to correct document', () async {
      // arrange
      when(() => mockMonitoredAppDoc.set(any(), any())).thenAnswer((_) async {});

      // act
      await repository.toggleMonitoredApp(
        familyId,
        childId,
        'com.zhiliaoapp.musically',
        false,
      );

      // assert
      verify(() => mockMonitoredAppsCollection.doc('com.zhiliaoapp.musically'))
          .called(1);
      verify(() => mockMonitoredAppDoc.set({'isMonitored': false}, any())).called(1);
    });

    test('addCustomApp should set data to correct document', () async {
      // arrange
      when(() => mockMonitoredAppDoc.set(any())).thenAnswer((_) async {});
      const app = MonitoredAppModel(
        appPackageName: 'com.custom.app',
        appName: 'Custom App',
        isMonitored: true,
      );

      // act
      await repository.addCustomApp(familyId, childId, app);

      // assert
      verify(() => mockMonitoredAppsCollection.doc('com.custom.app')).called(1);
      verify(() => mockMonitoredAppDoc.set(app.toJson())).called(1);
    });

    test('getPopularMonitoredApps should return predefined list', () {
      // act
      final result = repository.getPopularMonitoredApps();

      // assert
      expect(result, isA<List<MonitoredAppModel>>());
      expect(result.length, 7);
      expect(result.every((app) => app.isMonitored), true);
      expect(result.first.appName, 'TikTok');
    });
  });

  group('SmartLockRepository - Schedules', () {
    const familyId = 'family1';
    const childId = 'child1';
    late MockCollectionReference mockSchedulesCollection;
    late MockDocumentReference mockScheduleDoc;

    final tSchedule = ScheduleModel(
      id: 'schedule1',
      name: 'Giờ ngủ',
      type: 'blocked',
      startHour: 21,
      startMinute: 0,
      endHour: 6,
      endMinute: 0,
      days: const {
        'monday': true,
        'tuesday': true,
        'wednesday': true,
        'thursday': true,
        'friday': true,
        'saturday': true,
        'sunday': true,
      },
      isEnabled: true,
    );

    setUp(() {
      mockSchedulesCollection = MockCollectionReference();
      mockScheduleDoc = MockDocumentReference();

      when(() => mockChildDoc.collection('schedules'))
          .thenReturn(mockSchedulesCollection);
      when(() => mockSchedulesCollection.doc(any()))
          .thenReturn(mockScheduleDoc);
    });

    test('getSchedules should return a list of ScheduleModel', () async {
      // arrange
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDocSnapshot = MockQueryDocumentSnapshot();

      when(() => mockDocSnapshot.id).thenReturn('schedule1');
      when(() => mockDocSnapshot.data()).thenReturn({
        'id': 'schedule1',
        'name': 'Giờ ngủ',
        'type': 'blocked',
        'startHour': 21,
        'startMinute': 0,
        'endHour': 6,
        'endMinute': 0,
        'days': {
          'monday': true,
          'tuesday': true,
          'wednesday': true,
          'thursday': true,
          'friday': true,
          'saturday': true,
          'sunday': true,
        },
        'isEnabled': true,
      });

      when(() => mockQuerySnapshot.docs).thenReturn([mockDocSnapshot]);
      when(() => mockSchedulesCollection.get())
          .thenAnswer((_) async => mockQuerySnapshot);

      // act
      final result = await repository.getSchedules(familyId, childId);

      // assert
      expect(result, isA<List<ScheduleModel>>());
      expect(result.length, 1);
      expect(result.first.name, 'Giờ ngủ');
      expect(result.first.type, 'blocked');
      verify(() => mockSchedulesCollection.get()).called(1);
    });

    test('getSchedules should return empty list when no documents', () async {
      // arrange
      final mockQuerySnapshot = MockQuerySnapshot();
      when(() => mockQuerySnapshot.docs).thenReturn([]);
      when(() => mockSchedulesCollection.get())
          .thenAnswer((_) async => mockQuerySnapshot);

      // act
      final result = await repository.getSchedules(familyId, childId);

      // assert
      expect(result, isEmpty);
    });

    test('saveSchedule should set data to correct document', () async {
      // arrange
      when(() => mockScheduleDoc.set(any())).thenAnswer((_) async {});
      when(() => mockSchedulesCollection.doc()).thenReturn(mockScheduleDoc);

      // act
      await repository.saveSchedule(familyId, childId, tSchedule);

      // assert
      verify(() => mockScheduleDoc.set(tSchedule.toJson())).called(1);
    });

    test('saveSchedule should use provided id when not empty', () async {
      // arrange
      when(() => mockScheduleDoc.set(any())).thenAnswer((_) async {});
      when(() => mockSchedulesCollection.doc('schedule1'))
          .thenReturn(mockScheduleDoc);

      // act
      await repository.saveSchedule(familyId, childId, tSchedule);

      // assert
      verify(() => mockSchedulesCollection.doc('schedule1')).called(1);
      verify(() => mockScheduleDoc.set(tSchedule.toJson())).called(1);
    });

    test('deleteSchedule should delete correct document', () async {
      // arrange
      when(() => mockScheduleDoc.delete()).thenAnswer((_) async {});
      when(() => mockSchedulesCollection.doc('schedule1'))
          .thenReturn(mockScheduleDoc);

      // act
      await repository.deleteSchedule(familyId, childId, 'schedule1');

      // assert
      verify(() => mockSchedulesCollection.doc('schedule1')).called(1);
      verify(() => mockScheduleDoc.delete()).called(1);
    });
  });
}
