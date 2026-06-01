import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/repositories/notification_repository.dart';
import 'package:kidguardian/presentation/blocs/notification_history/notification_history_bloc.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  late NotificationHistoryBloc bloc;
  late MockNotificationRepository mockRepository;

  setUp(() {
    mockRepository = MockNotificationRepository();
    bloc = NotificationHistoryBloc(notificationRepository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('NotificationHistoryBloc', () {
    test('initial state is NotificationHistoryInitial', () {
      expect(bloc.state, isA<NotificationHistoryInitial>());
    });

    test('LoadNotifications starts listening and emits loaded state',
        () async {
      when(() => mockRepository.watchAllNotifications(
            familyId: any(named: 'familyId'),
          )).thenAnswer((_) => Stream.value([]));

      bloc.add(const LoadNotifications(familyId: 'family1'));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<NotificationHistoryLoaded>());
      final state = bloc.state as NotificationHistoryLoaded;
      expect(state.filteredNotifications, isEmpty);
      expect(state.filterStatus, NotificationFilterStatus.all);
      expect(state.unreadCount, 0);
    });

    test('emits notifications sorted by date from stream', () async {
      final notifications = [
        NotificationModel(
          id: '1',
          familyId: 'family1',
          childUid: 'child1',
          type: NotificationType.alert,
          title: 'Alert 1',
          body: 'Body 1',
          timestamp: DateTime(2026, 5, 17, 10, 0),
          isRead: false,
        ),
        NotificationModel(
          id: '2',
          familyId: 'family1',
          childUid: 'child1',
          type: NotificationType.timeRequest,
          title: 'Request 1',
          body: 'Body 2',
          timestamp: DateTime(2026, 5, 17, 9, 0),
          isRead: true,
        ),
      ];

      when(() => mockRepository.watchAllNotifications(
            familyId: any(named: 'familyId'),
          )).thenAnswer((_) => Stream.value(notifications));

      bloc.add(const LoadNotifications(familyId: 'family1'));
      await Future.delayed(const Duration(milliseconds: 100));

      final state = bloc.state as NotificationHistoryLoaded;
      expect(state.filteredNotifications.length, 2);
      expect(state.unreadCount, 1);
    });

    test('FilterByReadStatus filters unread notifications', () async {
      final notifications = [
        NotificationModel(
          id: '1',
          familyId: 'family1',
          childUid: 'child1',
          type: NotificationType.alert,
          title: 'Alert 1',
          body: 'Body 1',
          timestamp: DateTime(2026, 5, 17, 10, 0),
          isRead: false,
        ),
        NotificationModel(
          id: '2',
          familyId: 'family1',
          childUid: 'child1',
          type: NotificationType.timeRequest,
          title: 'Request 1',
          body: 'Body 2',
          timestamp: DateTime(2026, 5, 17, 9, 0),
          isRead: true,
        ),
      ];

      when(() => mockRepository.watchAllNotifications(
            familyId: any(named: 'familyId'),
          )).thenAnswer((_) => Stream.value(notifications));

      bloc.add(const LoadNotifications(familyId: 'family1'));
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(const FilterByReadStatus(NotificationFilterStatus.unread));
      await Future.delayed(const Duration(milliseconds: 100));

      final state = bloc.state as NotificationHistoryLoaded;
      expect(state.filteredNotifications.length, 1);
      expect(state.filteredNotifications.first.id, '1');
    });

    test('FilterByReadStatus filters read notifications', () async {
      final notifications = [
        NotificationModel(
          id: '1',
          familyId: 'family1',
          childUid: 'child1',
          type: NotificationType.alert,
          title: 'Alert 1',
          body: 'Body 1',
          timestamp: DateTime(2026, 5, 17, 10, 0),
          isRead: false,
        ),
        NotificationModel(
          id: '2',
          familyId: 'family1',
          childUid: 'child1',
          type: NotificationType.timeRequest,
          title: 'Request 1',
          body: 'Body 2',
          timestamp: DateTime(2026, 5, 17, 9, 0),
          isRead: true,
        ),
      ];

      when(() => mockRepository.watchAllNotifications(
            familyId: any(named: 'familyId'),
          )).thenAnswer((_) => Stream.value(notifications));

      bloc.add(const LoadNotifications(familyId: 'family1'));
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(const FilterByReadStatus(NotificationFilterStatus.read));
      await Future.delayed(const Duration(milliseconds: 100));

      final state = bloc.state as NotificationHistoryLoaded;
      expect(state.filteredNotifications.length, 1);
      expect(state.filteredNotifications.first.id, '2');
    });

    test('FilterByType filters by notification type', () async {
      final notifications = [
        NotificationModel(
          id: '1',
          familyId: 'family1',
          childUid: 'child1',
          type: NotificationType.alert,
          title: 'Alert 1',
          body: 'Body 1',
          timestamp: DateTime(2026, 5, 17, 10, 0),
          isRead: false,
        ),
        NotificationModel(
          id: '2',
          familyId: 'family1',
          childUid: 'child1',
          type: NotificationType.timeRequest,
          title: 'Request 1',
          body: 'Body 2',
          timestamp: DateTime(2026, 5, 17, 9, 0),
          isRead: false,
        ),
      ];

      when(() => mockRepository.watchAllNotifications(
            familyId: any(named: 'familyId'),
          )).thenAnswer((_) => Stream.value(notifications));

      bloc.add(const LoadNotifications(familyId: 'family1'));
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(const FilterByType(NotificationType.alert));
      await Future.delayed(const Duration(milliseconds: 100));

      final state = bloc.state as NotificationHistoryLoaded;
      expect(state.filteredNotifications.length, 1);
      expect(state.filteredNotifications.first.type, NotificationType.alert);
    });

    test('MarkAsReadEvent calls repository', () async {
      when(() => mockRepository.watchAllNotifications(
            familyId: any(named: 'familyId'),
          )).thenAnswer((_) => Stream.value([]));
      when(() => mockRepository.markAsRead(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
            notificationId: any(named: 'notificationId'),
          )).thenAnswer((_) async {});

      bloc.add(const LoadNotifications(familyId: 'family1'));
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(const MarkAsReadEvent(
        familyId: 'family1',
        childUid: 'child1',
        notificationId: 'notif1',
      ));
      await Future.delayed(const Duration(milliseconds: 100));

      verify(() => mockRepository.markAsRead(
            familyId: 'family1',
            childUid: 'child1',
            notificationId: 'notif1',
          )).called(1);
    });

    test('MarkAllAsReadEvent calls repository', () async {
      when(() => mockRepository.watchAllNotifications(
            familyId: any(named: 'familyId'),
          )).thenAnswer((_) => Stream.value([]));
      when(() => mockRepository.markAllAsRead(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
          )).thenAnswer((_) async {});

      bloc.add(const LoadNotifications(familyId: 'family1'));
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(const MarkAllAsReadEvent(
        familyId: 'family1',
        childUid: 'child1',
      ));
      await Future.delayed(const Duration(milliseconds: 100));

      verify(() => mockRepository.markAllAsRead(
            familyId: 'family1',
            childUid: 'child1',
          )).called(1);
    });

    test('ClearOldNotificationsEvent calls repository with correct date',
        () async {
      when(() => mockRepository.watchAllNotifications(
            familyId: any(named: 'familyId'),
          )).thenAnswer((_) => Stream.value([]));
      when(() => mockRepository.clearOldNotifications(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
            olderThan: any(named: 'olderThan'),
          )).thenAnswer((_) async {});

      bloc.add(const LoadNotifications(familyId: 'family1'));
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(const ClearOldNotificationsEvent(
        familyId: 'family1',
        childUid: 'child1',
        daysOld: 30,
      ));
      await Future.delayed(const Duration(milliseconds: 100));

      verify(() => mockRepository.clearOldNotifications(
            familyId: 'family1',
            childUid: 'child1',
            olderThan: any(named: 'olderThan'),
          )).called(1);
    });

    test('emits error state when markAsRead fails', () async {
      when(() => mockRepository.watchAllNotifications(
            familyId: any(named: 'familyId'),
          )).thenAnswer((_) => Stream.value([]));
      when(() => mockRepository.markAsRead(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
            notificationId: any(named: 'notificationId'),
          )).thenThrow(Exception('Failed'));

      bloc.add(const LoadNotifications(familyId: 'family1'));
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(const MarkAsReadEvent(
        familyId: 'family1',
        childUid: 'child1',
        notificationId: 'notif1',
      ));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<NotificationHistoryError>());
    });
  });
}
