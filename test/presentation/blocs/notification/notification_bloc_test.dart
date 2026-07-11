import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';
import 'package:kidguardian/domain/repositories/time_request_repository.dart';
import 'package:kidguardian/presentation/blocs/notification/notification_bloc.dart';

class MockAlertRepository extends Mock implements AlertRepository {}
class MockTimeRequestRepository extends Mock implements TimeRequestRepository {}
class MockFlutterLocalNotificationsPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class FakeInitializationSettings extends Fake implements InitializationSettings {}
class FakeNotificationDetails extends Fake implements NotificationDetails {}

void main() {
  late NotificationBloc bloc;
  late MockAlertRepository mockAlertRepository;
  late MockTimeRequestRepository mockTimeRequestRepository;
  late MockFlutterLocalNotificationsPlugin mockNotificationsPlugin;

  setUpAll(() {
    registerFallbackValue(FakeInitializationSettings());
    registerFallbackValue(FakeNotificationDetails());
  });

  setUp(() {
    mockAlertRepository = MockAlertRepository();
    mockTimeRequestRepository = MockTimeRequestRepository();
    mockNotificationsPlugin = MockFlutterLocalNotificationsPlugin();

    when(() => mockNotificationsPlugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse:
              any(named: 'onDidReceiveNotificationResponse'),
        )).thenAnswer((_) async => true);
    when(() => mockNotificationsPlugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        )).thenAnswer((_) async {});
    when(() => mockNotificationsPlugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
        )).thenAnswer((_) async {});

    bloc = NotificationBloc(
      alertRepository: mockAlertRepository,
      timeRequestRepository: mockTimeRequestRepository,
      notificationsPlugin: mockNotificationsPlugin,
    );
  });

  tearDown(() {
    bloc.close();
  });

  AlertModel makeAlert({
    String id = 'alert1',
    String keyword = 'danger',
    String packageName = 'com.tiktok',
    String childUid = 'child1',
  }) {
    return AlertModel(
      id: id,
      type: 'keyword_detected',
      keyword: keyword,
      packageName: packageName,
      textContext: 'some text',
      timestamp: DateTime(2026, 5, 31),
      isReviewed: false,
      childUid: childUid,
    );
  }

  group('NotificationBloc', () {
    test('initial state is NotificationInitial', () {
      expect(bloc.state, isA<NotificationInitial>());
    });

    test('initializeNotifications calls plugin initialize', () async {
      await bloc.initializeNotifications();
      verify(() => mockNotificationsPlugin.initialize(
            settings: any(named: 'settings'),
            onDidReceiveNotificationResponse:
                any(named: 'onDidReceiveNotificationResponse'),
          )).called(1);
    });

    blocTest<NotificationBloc, NotificationState>(
      'StartAlertListening emits NotificationListening',
      build: () {
        when(() => mockAlertRepository.watchAllFamilyAlerts(
              familyId: any(named: 'familyId'),
            )).thenAnswer((_) => Stream.value([]));
        return bloc;
      },
      act: (bloc) => bloc.add(const StartAlertListening(familyId: 'fam1')),
      expect: () => [isA<NotificationListening>()],
    );

    blocTest<NotificationBloc, NotificationState>(
      'StopAlertListening emits NotificationInitial',
      build: () {
        when(() => mockAlertRepository.watchAllFamilyAlerts(
              familyId: any(named: 'familyId'),
            )).thenAnswer((_) => Stream.value([]));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const StartAlertListening(familyId: 'fam1'));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(StopAlertListening());
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<NotificationListening>(),
        isA<NotificationInitial>(),
      ],
    );

    blocTest<NotificationBloc, NotificationState>(
      'stream alerts trigger AlertReceived and update pending count',
      build: () {
        when(() => mockAlertRepository.watchAllFamilyAlerts(
              familyId: any(named: 'familyId'),
            )).thenAnswer((_) => Stream.value([makeAlert(id: 'alert1')]));
        return bloc;
      },
      act: (bloc) => bloc.add(const StartAlertListening(familyId: 'fam1')),
      wait: const Duration(milliseconds: 200),
      expect: () => [
        isA<NotificationListening>().having(
          (s) => s.pendingAlertCount,
          'initial',
          0,
        ),
        isA<NotificationListening>().having(
          (s) => s.pendingAlertCount,
          'after alert',
          1,
        ),
      ],
      verify: (_) {
        verify(() => mockNotificationsPlugin.show(
              id: any(named: 'id'),
              title: any(named: 'title'),
              body: any(named: 'body'),
              notificationDetails: any(named: 'notificationDetails'),
              payload: any(named: 'payload'),
            )).called(1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'MarkAlertReviewed calls repository and decrements pending count',
      build: () {
        when(() => mockAlertRepository.watchAllFamilyAlerts(
              familyId: any(named: 'familyId'),
            )).thenAnswer((_) => Stream.value([makeAlert(id: 'alert1')]));
        when(() => mockAlertRepository.markAlertAsReviewed(
              familyId: any(named: 'familyId'),
              childUid: any(named: 'childUid'),
              alertId: any(named: 'alertId'),
            )).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const StartAlertListening(familyId: 'fam1'));
        await Future.delayed(const Duration(milliseconds: 200));
        bloc.add(const MarkAlertReviewed(
          familyId: 'fam1',
          childUid: 'child1',
          alertId: 'alert1',
        ));
      },
      wait: const Duration(milliseconds: 200),
      expect: () => [
        isA<NotificationListening>().having(
          (s) => s.pendingAlertCount,
          'initial',
          0,
        ),
        isA<NotificationListening>().having(
          (s) => s.pendingAlertCount,
          'after alert',
          1,
        ),
        isA<NotificationListening>().having(
          (s) => s.pendingAlertCount,
          'after reviewed',
          0,
        ),
      ],
      verify: (_) {
        verify(() => mockAlertRepository.markAlertAsReviewed(
              familyId: 'fam1',
              childUid: 'child1',
              alertId: 'alert1',
            )).called(1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'MarkAlertReviewed emits error when repository throws',
      build: () {
        when(() => mockAlertRepository.watchAllFamilyAlerts(
              familyId: any(named: 'familyId'),
            )).thenAnswer((_) => Stream.value([]));
        when(() => mockAlertRepository.markAlertAsReviewed(
              familyId: any(named: 'familyId'),
              childUid: any(named: 'childUid'),
              alertId: any(named: 'alertId'),
            )).thenThrow(Exception('DB error'));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const StartAlertListening(familyId: 'fam1'));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const MarkAlertReviewed(
          familyId: 'fam1',
          childUid: 'child1',
          alertId: 'alert1',
        ));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<NotificationListening>(),
        isA<NotificationError>().having(
          (e) => e.message,
          'message',
          'Failed to mark alert as reviewed',
        ),
      ],
    );

    blocTest<NotificationBloc, NotificationState>(
      'QuickApproveRequest calls repository and emits listening state',
      build: () {
        when(() => mockAlertRepository.watchAllFamilyAlerts(
              familyId: any(named: 'familyId'),
            )).thenAnswer((_) => Stream.value([]));
        when(() => mockTimeRequestRepository.approveRequest(
              familyId: any(named: 'familyId'),
              childUid: any(named: 'childUid'),
              requestId: any(named: 'requestId'),
              response: any(named: 'response'),
            )).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const StartAlertListening(familyId: 'fam1'));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const QuickApproveRequest(
          familyId: 'fam1',
          childUid: 'child1',
          requestId: 'req1',
        ));
      },
      wait: const Duration(milliseconds: 200),
      expect: () => [
        isA<NotificationListening>(),
      ],
      verify: (_) {
        verify(() => mockTimeRequestRepository.approveRequest(
              familyId: 'fam1',
              childUid: 'child1',
              requestId: 'req1',
              response: any(named: 'response'),
            )).called(1);
        verify(() => mockNotificationsPlugin.show(
              id: any(named: 'id'),
              title: 'Đã duyệt yêu cầu',
              body: any(named: 'body'),
              notificationDetails: any(named: 'notificationDetails'),
            )).called(1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'QuickApproveRequest emits error when repository throws',
      build: () {
        when(() => mockAlertRepository.watchAllFamilyAlerts(
              familyId: any(named: 'familyId'),
            )).thenAnswer((_) => Stream.value([]));
        when(() => mockTimeRequestRepository.approveRequest(
              familyId: any(named: 'familyId'),
              childUid: any(named: 'childUid'),
              requestId: any(named: 'requestId'),
              response: any(named: 'response'),
            )).thenThrow(Exception('Approve error'));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const StartAlertListening(familyId: 'fam1'));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const QuickApproveRequest(
          familyId: 'fam1',
          childUid: 'child1',
          requestId: 'req1',
        ));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<NotificationListening>(),
        isA<NotificationError>().having(
          (e) => e.message,
          'message',
          'Failed to approve request',
        ),
      ],
    );

    blocTest<NotificationBloc, NotificationState>(
      'QuickRejectRequest calls repository and emits listening state',
      build: () {
        when(() => mockAlertRepository.watchAllFamilyAlerts(
              familyId: any(named: 'familyId'),
            )).thenAnswer((_) => Stream.value([]));
        when(() => mockTimeRequestRepository.rejectRequest(
              familyId: any(named: 'familyId'),
              childUid: any(named: 'childUid'),
              requestId: any(named: 'requestId'),
              response: any(named: 'response'),
            )).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const StartAlertListening(familyId: 'fam1'));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const QuickRejectRequest(
          familyId: 'fam1',
          childUid: 'child1',
          requestId: 'req1',
        ));
      },
      wait: const Duration(milliseconds: 200),
      expect: () => [
        isA<NotificationListening>(),
      ],
      verify: (_) {
        verify(() => mockTimeRequestRepository.rejectRequest(
              familyId: 'fam1',
              childUid: 'child1',
              requestId: 'req1',
              response: any(named: 'response'),
            )).called(1);
        verify(() => mockNotificationsPlugin.show(
              id: any(named: 'id'),
              title: 'Đã từ chối yêu cầu',
              body: any(named: 'body'),
              notificationDetails: any(named: 'notificationDetails'),
            )).called(1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'QuickRejectRequest emits error when repository throws',
      build: () {
        when(() => mockAlertRepository.watchAllFamilyAlerts(
              familyId: any(named: 'familyId'),
            )).thenAnswer((_) => Stream.value([]));
        when(() => mockTimeRequestRepository.rejectRequest(
              familyId: any(named: 'familyId'),
              childUid: any(named: 'childUid'),
              requestId: any(named: 'requestId'),
              response: any(named: 'response'),
            )).thenThrow(Exception('Reject error'));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const StartAlertListening(familyId: 'fam1'));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const QuickRejectRequest(
          familyId: 'fam1',
          childUid: 'child1',
          requestId: 'req1',
        ));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<NotificationListening>(),
        isA<NotificationError>().having(
          (e) => e.message,
          'message',
          'Failed to reject request',
        ),
      ],
    );
  });
}
