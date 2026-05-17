import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';
import 'package:kidguardian/presentation/blocs/notification/notification_bloc.dart';

class MockAlertRepository extends Mock implements AlertRepository {}
class MockFlutterLocalNotificationsPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class FakeInitializationSettings extends Fake implements InitializationSettings {}
class FakeNotificationDetails extends Fake implements NotificationDetails {}
class FakeNotificationResponse extends Fake implements NotificationResponse {}

void main() {
  late NotificationBloc bloc;
  late MockAlertRepository mockAlertRepository;
  late MockFlutterLocalNotificationsPlugin mockNotificationsPlugin;

  setUpAll(() {
    registerFallbackValue(FakeInitializationSettings());
    registerFallbackValue(FakeNotificationDetails());
    registerFallbackValue(FakeNotificationResponse());
  });

  setUp(() {
    mockAlertRepository = MockAlertRepository();
    mockNotificationsPlugin = MockFlutterLocalNotificationsPlugin();
    
    when(() => mockNotificationsPlugin.initialize(
      settings: any(named: 'settings'),
      onDidReceiveNotificationResponse: any(named: 'onDidReceiveNotificationResponse'),
    )).thenAnswer((_) async => true);
    when(() => mockNotificationsPlugin.show(
      id: any(named: 'id'),
      title: any(named: 'title'),
      body: any(named: 'body'),
      notificationDetails: any(named: 'notificationDetails'),
      payload: any(named: 'payload'),
    )).thenAnswer((_) async {});

    bloc = NotificationBloc(
      alertRepository: mockAlertRepository,
      notificationsPlugin: mockNotificationsPlugin,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('NotificationBloc', () {
    test('initial state is NotificationInitial', () {
      expect(bloc.state, isA<NotificationInitial>());
    });

    test('initializeNotifications calls plugin initialize', () async {
      await bloc.initializeNotifications();
      verify(() => mockNotificationsPlugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(named: 'onDidReceiveNotificationResponse'),
      )).called(1);
    });

    test('StartAlertListening emits NotificationListening state', () async {
      when(() => mockAlertRepository.watchNewAlerts(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
          )).thenAnswer((_) => Stream.value([]));

      bloc.add(const StartAlertListening(familyId: 'family1', childUid: 'child1'));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<NotificationListening>());
    });

    test('StopAlertListening emits NotificationInitial state', () async {
      when(() => mockAlertRepository.watchNewAlerts(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
          )).thenAnswer((_) => Stream.value([]));

      bloc.add(const StartAlertListening(familyId: 'family1', childUid: 'child1'));
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(StopAlertListening());
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<NotificationInitial>());
    });

    test('MarkAlertReviewed calls repository and updates state', () async {
      when(() => mockAlertRepository.watchNewAlerts(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
          )).thenAnswer((_) => Stream.value([]));
      when(() => mockAlertRepository.markAlertAsReviewed(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
            alertId: any(named: 'alertId'),
          )).thenAnswer((_) async {});

      bloc.add(const StartAlertListening(familyId: 'family1', childUid: 'child1'));
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(const MarkAlertReviewed(
        familyId: 'family1',
        childUid: 'child1',
        alertId: 'alert1',
      ));
      await Future.delayed(const Duration(milliseconds: 100));

      verify(() => mockAlertRepository.markAlertAsReviewed(
            familyId: 'family1',
            childUid: 'child1',
            alertId: 'alert1',
          )).called(1);
    });
  });
}
