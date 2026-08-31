import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';
import 'package:kidguardian/domain/repositories/time_request_repository.dart';
import 'package:kidguardian/presentation/blocs/in_app_notification/in_app_notification_bloc.dart';

class MockAlertRepository extends Mock implements AlertRepository {}
class MockTimeRequestRepository extends Mock implements TimeRequestRepository {}

void main() {
  late InAppNotificationBloc bloc;
  late MockAlertRepository mockAlertRepository;
  late MockTimeRequestRepository mockTimeRequestRepository;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    mockAlertRepository = MockAlertRepository();
    mockTimeRequestRepository = MockTimeRequestRepository();
    when(() => mockAlertRepository.markAlertAsReviewed(
          familyId: any(named: 'familyId'),
          childUid: any(named: 'childUid'),
          alertId: any(named: 'alertId'),
        )).thenAnswer((_) async {});
    bloc = InAppNotificationBloc(
      alertRepository: mockAlertRepository,
      timeRequestRepository: mockTimeRequestRepository,
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
    DateTime? timestamp,
  }) {
    return AlertModel(
      id: id,
      type: 'keyword_detected',
      keyword: keyword,
      packageName: packageName,
      textContext: 'some text',
      timestamp: timestamp ?? DateTime(2026, 5, 31, 10, 0),
      isReviewed: false,
      childUid: childUid,
    );
  }

  group('InAppNotificationBloc', () {
    test('initial state is InAppNotificationInitial', () {
      expect(bloc.state, isA<InAppNotificationInitial>());
    });

    group('LoadInAppNotifications', () {
      blocTest<InAppNotificationBloc, InAppNotificationState>(
        'emits Loading then Loaded with empty list when no alerts',
        build: () {
          when(() => mockAlertRepository.watchAllFamilyAlerts(
                familyId: any(named: 'familyId'),
              )).thenAnswer((_) => Stream.value([]));
          when(() => mockTimeRequestRepository.watchPendingRequests(
                familyId: any(named: 'familyId'),
              )).thenAnswer((_) => Stream.value([]));
          return bloc;
        },
        act: (bloc) =>
            bloc.add(const LoadInAppNotifications(familyId: 'fam1')),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<InAppNotificationLoading>(),
          isA<InAppNotificationLoaded>()
              .having((s) => s.notifications, 'notifications', isEmpty)
              .having((s) => s.unreadCount, 'unreadCount', 0),
        ],
      );

      blocTest<InAppNotificationBloc, InAppNotificationState>(
        'loads alerts from stream and creates notifications',
        build: () {
          final alerts = [
            makeAlert(id: 'a1', keyword: 'violence', timestamp: DateTime(2026, 5, 31, 10)),
            makeAlert(id: 'a2', keyword: 'drug', timestamp: DateTime(2026, 5, 31, 11)),
          ];
          when(() => mockAlertRepository.watchAllFamilyAlerts(
                familyId: any(named: 'familyId'),
              )).thenAnswer((_) => Stream.value(alerts));
          when(() => mockTimeRequestRepository.watchPendingRequests(
                familyId: any(named: 'familyId'),
              )).thenAnswer((_) => Stream.value([]));
          return bloc;
        },
        act: (bloc) =>
            bloc.add(const LoadInAppNotifications(familyId: 'fam1')),
        wait: const Duration(milliseconds: 200),
        expect: () => [
          isA<InAppNotificationLoading>(),
          isA<InAppNotificationLoaded>()
              .having((s) => s.unreadCount, 'initial empty', 0),
          isA<InAppNotificationLoaded>()
              .having((s) => s.notifications.length, 'notifications.length', 2)
              .having((s) => s.unreadCount, 'unreadCount', 2),
        ],
      );

      blocTest<InAppNotificationBloc, InAppNotificationState>(
        'sorts notifications by timestamp descending',
        build: () {
          final alerts = [
            makeAlert(id: 'a1', timestamp: DateTime(2026, 5, 31, 10)),
            makeAlert(id: 'a2', timestamp: DateTime(2026, 5, 31, 12)),
            makeAlert(id: 'a3', timestamp: DateTime(2026, 5, 31, 11)),
          ];
          when(() => mockAlertRepository.watchAllFamilyAlerts(
                familyId: any(named: 'familyId'),
              )).thenAnswer((_) => Stream.value(alerts));
          when(() => mockTimeRequestRepository.watchPendingRequests(
                familyId: any(named: 'familyId'),
              )).thenAnswer((_) => Stream.value([]));
          return bloc;
        },
        act: (bloc) =>
            bloc.add(const LoadInAppNotifications(familyId: 'fam1')),
        wait: const Duration(milliseconds: 200),
        expect: () => [
          isA<InAppNotificationLoading>(),
          isA<InAppNotificationLoaded>(),
          isA<InAppNotificationLoaded>().having(
            (s) => s.notifications.map((n) => n.id).toList(),
            'sorted ids',
            ['a2', 'a3', 'a1'],
          ),
        ],
      );
    });

    group('MarkInAppNotificationAsRead', () {
      blocTest<InAppNotificationBloc, InAppNotificationState>(
        'marks single notification as read and updates unreadCount',
        build: () {
          final alerts = [
            makeAlert(id: 'a1', timestamp: DateTime(2026, 5, 31, 10)),
            makeAlert(id: 'a2', timestamp: DateTime(2026, 5, 31, 11)),
          ];
          when(() => mockAlertRepository.watchAllFamilyAlerts(
                familyId: any(named: 'familyId'),
              )).thenAnswer((_) => Stream.value(alerts));
          when(() => mockTimeRequestRepository.watchPendingRequests(
                familyId: any(named: 'familyId'),
              )).thenAnswer((_) => Stream.value([]));
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const LoadInAppNotifications(familyId: 'fam1'));
          await Future<void>.delayed(const Duration(milliseconds: 200));
          bloc.add(const MarkInAppNotificationAsRead(
            notificationId: 'a1',
            type: 'alert',
          ));
        },
        wait: const Duration(milliseconds: 200),
        expect: () => [
          isA<InAppNotificationLoading>(),
          isA<InAppNotificationLoaded>().having((s) => s.unreadCount, 'initial empty', 0),
          isA<InAppNotificationLoaded>().having((s) => s.unreadCount, 'loaded', 2),
          isA<InAppNotificationLoaded>()
              .having((s) => s.unreadCount, 'after mark', 1)
              .having(
                (s) => s.notifications.firstWhere((n) => n.id == 'a1').isRead,
                'a1 isRead',
                true,
              ),
        ],
      );
    });

    group('MarkAllInAppNotificationsAsRead', () {
      blocTest<InAppNotificationBloc, InAppNotificationState>(
        'marks all notifications as read',
        build: () {
          final alerts = [
            makeAlert(id: 'a1', timestamp: DateTime(2026, 5, 31, 10)),
            makeAlert(id: 'a2', timestamp: DateTime(2026, 5, 31, 11)),
          ];
          when(() => mockAlertRepository.watchAllFamilyAlerts(
                familyId: any(named: 'familyId'),
              )).thenAnswer((_) => Stream.value(alerts));
          when(() => mockTimeRequestRepository.watchPendingRequests(
                familyId: any(named: 'familyId'),
              )).thenAnswer((_) => Stream.value([]));
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const LoadInAppNotifications(familyId: 'fam1'));
          await Future<void>.delayed(const Duration(milliseconds: 200));
          bloc.add(MarkAllInAppNotificationsAsRead());
        },
        wait: const Duration(milliseconds: 200),
        expect: () => [
          isA<InAppNotificationLoading>(),
          isA<InAppNotificationLoaded>().having((s) => s.unreadCount, 'initial empty', 0),
          isA<InAppNotificationLoaded>().having((s) => s.unreadCount, 'loaded', 2),
          isA<InAppNotificationLoaded>()
              .having((s) => s.unreadCount, 'after mark all', 0)
              .having(
                (s) => s.notifications.every((n) => n.isRead),
                'all read',
                true,
              ),
        ],
      );
    });

    group('InAppNotificationReceived', () {
      test('InAppNotification model supports copyWith for isRead', () {
        final notification = InAppNotification(
          id: 'n1',
          type: 'alert',
          title: 'Test',
          body: 'Body',
          timestamp: DateTime(2026, 5, 31),
          isRead: false,
        );
        final readNotification = notification.copyWith(isRead: true);
        expect(readNotification.isRead, true);
        expect(readNotification.id, 'n1');
      });

      test('InAppNotification model equality works correctly', () {
        final n1 = InAppNotification(
          id: 'n1',
          type: 'alert',
          title: 'Test',
          body: 'Body',
          timestamp: DateTime(2026, 5, 31),
        );
        final n2 = InAppNotification(
          id: 'n1',
          type: 'alert',
          title: 'Test',
          body: 'Body',
          timestamp: DateTime(2026, 5, 31),
        );
        expect(n1, equals(n2));
      });

      test('MarkInAppNotificationAsRead event stores correct props', () {
        const event = MarkInAppNotificationAsRead(
          notificationId: 'n1',
          type: 'alert',
        );
        expect(event.notificationId, 'n1');
        expect(event.type, 'alert');
        expect(event.props, ['n1', 'alert']);
      });
    });

    group('close', () {
      test('cancels subscriptions on close', () async {
        when(() => mockAlertRepository.watchAllFamilyAlerts(
              familyId: any(named: 'familyId'),
            )).thenAnswer((_) => Stream.value([]));
        when(() => mockTimeRequestRepository.watchPendingRequests(
              familyId: any(named: 'familyId'),
            )).thenAnswer((_) => Stream.value([]));

        bloc.add(const LoadInAppNotifications(familyId: 'fam1'));
        await Future.delayed(const Duration(milliseconds: 50));
        await bloc.close();
      });
    });
  });
}
