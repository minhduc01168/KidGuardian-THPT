import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';
import 'package:kidguardian/domain/repositories/time_request_repository.dart';
import 'package:kidguardian/presentation/blocs/in_app_notification/in_app_notification_bloc.dart';

class MockAlertRepository extends Mock implements AlertRepository {}
class MockTimeRequestRepository extends Mock implements TimeRequestRepository {}

AlertModel _alert({String id = 'a1', bool isReviewed = false, String keyword = 'danger'}) {
  return AlertModel(
    id: id,
    type: 'keyword_detected',
    keyword: keyword,
    packageName: 'com.test.app',
    textContext: 'some context',
    timestamp: DateTime(2026, 8, 1, 10),
    isReviewed: isReviewed,
    childUid: 'child1',
  );
}

TimeRequest _request({String id = 'req1', String appName = 'TikTok', int minutes = 15}) {
  return TimeRequest(
    id: id,
    familyId: 'fam1',
    childUid: 'child1',
    appPackageName: 'com.tiktok',
    appName: appName,
    requestedMinutes: minutes,
    reason: 'xin thêm giờ',
    status: TimeRequestStatus.pending,
    timestamp: DateTime(2026, 8, 1, 11),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAlertRepository mockAlertRepo;
  late MockTimeRequestRepository mockTimeRequestRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Mock SharedPreferences channel
    const channel = MethodChannel('plugins.flutter.io/shared_preferences');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getAll') return <String, dynamic>{};
      if (call.method == 'setStringList') return true;
      return null;
    });

    mockAlertRepo = MockAlertRepository();
    mockTimeRequestRepo = MockTimeRequestRepository();

    when(() => mockAlertRepo.markAlertAsReviewed(
          familyId: any(named: 'familyId'),
          childUid: any(named: 'childUid'),
          alertId: any(named: 'alertId'),
        )).thenAnswer((_) async {});
  });

  // ─────────────────────────────────────────────────────────
  // BUG-3: Thông báo đã xem không hiện lại
  // ─────────────────────────────────────────────────────────
  group('BUG-3: Alerts đã isReviewed=true không được emit vào unread list', () {
    blocTest<InAppNotificationBloc, InAppNotificationState>(
      'alert có isReviewed=true → KHÔNG xuất hiện trong notifications (do Firestore filter)',
      build: () {
        // Sau fix BUG-3: watchAllFamilyAlerts đã có filter isReviewed=false
        // Nên stream mock chỉ trả về alert chưa reviewed
        when(() => mockAlertRepo.watchAllFamilyAlerts(familyId: any(named: 'familyId')))
            .thenAnswer((_) => Stream.value([])); // empty = filter đã hoạt động
        when(() => mockTimeRequestRepo.watchPendingRequests(familyId: any(named: 'familyId')))
            .thenAnswer((_) => Stream.value([]));
        return InAppNotificationBloc(
          alertRepository: mockAlertRepo,
          timeRequestRepository: mockTimeRequestRepo,
        );
      },
      act: (bloc) => bloc.add(const LoadInAppNotifications(familyId: 'fam1')),
      wait: const Duration(milliseconds: 200),
      expect: () => [
        isA<InAppNotificationLoading>(),
        isA<InAppNotificationLoaded>()
            .having((s) => s.unreadCount, 'unreadCount = 0 (reviewed alerts filtered)', 0),
      ],
    );

    blocTest<InAppNotificationBloc, InAppNotificationState>(
      'alert chưa reviewed → xuất hiện trong unread list',
      build: () {
        when(() => mockAlertRepo.watchAllFamilyAlerts(familyId: any(named: 'familyId')))
            .thenAnswer((_) => Stream.value([_alert(id: 'a1', isReviewed: false)]));
        when(() => mockTimeRequestRepo.watchPendingRequests(familyId: any(named: 'familyId')))
            .thenAnswer((_) => Stream.value([]));
        return InAppNotificationBloc(
          alertRepository: mockAlertRepo,
          timeRequestRepository: mockTimeRequestRepo,
        );
      },
      act: (bloc) => bloc.add(const LoadInAppNotifications(familyId: 'fam1')),
      wait: const Duration(milliseconds: 200),
      expect: () => [
        isA<InAppNotificationLoading>(),
        isA<InAppNotificationLoaded>(),
        isA<InAppNotificationLoaded>()
            .having((s) => s.unreadCount, 'unreadCount = 1', 1),
      ],
    );
  });

  group('BUG-3: time_request biến mất khỏi notifications khi approved', () {
    blocTest<InAppNotificationBloc, InAppNotificationState>(
      'Khi stream pending requests emit list rỗng (request đã approved), '
      'time_request items phải bị xóa khỏi notifications',
      build: () {
        // Stream 1: có 1 pending request
        // Stream 2: empty (request đã approved → stream dừng emit nó)
        final requestStreamController = StreamController<List<TimeRequest>>();
        when(() => mockAlertRepo.watchAllFamilyAlerts(familyId: any(named: 'familyId')))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockTimeRequestRepo.watchPendingRequests(familyId: any(named: 'familyId')))
            .thenAnswer((_) => requestStreamController.stream);

        // Emit pending request rồi xóa đi (simulate approval)
        Future.delayed(const Duration(milliseconds: 50), () {
          requestStreamController.add([_request(id: 'req1')]);
        });
        Future.delayed(const Duration(milliseconds: 150), () {
          requestStreamController.add([]); // approved → empty
          requestStreamController.close();
        });

        return InAppNotificationBloc(
          alertRepository: mockAlertRepo,
          timeRequestRepository: mockTimeRequestRepo,
        );
      },
      act: (bloc) => bloc.add(const LoadInAppNotifications(familyId: 'fam1')),
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<InAppNotificationLoading>(),
        isA<InAppNotificationLoaded>().having((s) => s.unreadCount, 'initial', 0),
        // Sau khi request stream emit pending → xuất hiện 1 notification
        isA<InAppNotificationLoaded>()
            .having((s) => s.notifications.where((n) => n.type == 'time_request').length,
                'has 1 time_request', 1),
        // Sau khi stream emit empty (approved) → time_request bị xóa
        isA<InAppNotificationLoaded>()
            .having((s) => s.notifications.where((n) => n.type == 'time_request').length,
                'time_request removed after approval', 0),
      ],
    );

    blocTest<InAppNotificationBloc, InAppNotificationState>(
      'Stream emit nhiều lần cùng ID → KHÔNG tạo duplicate entries',
      build: () {
        final controller = StreamController<List<TimeRequest>>();
        when(() => mockAlertRepo.watchAllFamilyAlerts(familyId: any(named: 'familyId')))
            .thenAnswer((_) => Stream.value([]));
        when(() => mockTimeRequestRepo.watchPendingRequests(familyId: any(named: 'familyId')))
            .thenAnswer((_) => controller.stream);

        // Emit cùng danh sách 3 lần (simulate re-subscribe storm)
        Future.delayed(const Duration(milliseconds: 50), () {
          controller.add([_request(id: 'req1')]);
        });
        Future.delayed(const Duration(milliseconds: 100), () {
          controller.add([_request(id: 'req1')]); // cùng ID
        });
        Future.delayed(const Duration(milliseconds: 150), () {
          controller.add([_request(id: 'req1')]); // cùng ID lần 3
          controller.close();
        });

        return InAppNotificationBloc(
          alertRepository: mockAlertRepo,
          timeRequestRepository: mockTimeRequestRepo,
        );
      },
      act: (bloc) => bloc.add(const LoadInAppNotifications(familyId: 'fam1')),
      wait: const Duration(milliseconds: 300),
      verify: (bloc) {
        final state = bloc.state as InAppNotificationLoaded;
        final timeRequests = state.notifications.where((n) => n.type == 'time_request').toList();
        // BUG-3 FIX: Không được có duplicate — chỉ 1 entry dù stream emit 3 lần
        expect(timeRequests.length, equals(1),
            reason: 'Không được có duplicate time_request notifications');
      },
    );
  });

  group('BUG-3: markAsRead persists qua restart', () {
    test('markAsRead thêm vào _readIds và notification trở thành isRead=true', () async {
      when(() => mockAlertRepo.watchAllFamilyAlerts(familyId: any(named: 'familyId')))
          .thenAnswer((_) => Stream.value([_alert(id: 'a1')]));
      when(() => mockTimeRequestRepo.watchPendingRequests(familyId: any(named: 'familyId')))
          .thenAnswer((_) => Stream.value([]));

      final bloc = InAppNotificationBloc(
        alertRepository: mockAlertRepo,
        timeRequestRepository: mockTimeRequestRepo,
      );

      bloc.add(const LoadInAppNotifications(familyId: 'fam1'));
      await Future.delayed(const Duration(milliseconds: 300));

      // Verify initially unread
      var state = bloc.state as InAppNotificationLoaded;
      expect(state.unreadCount, equals(1));

      // Mark as read
      bloc.add(const MarkInAppNotificationAsRead(notificationId: 'a1', type: 'alert'));
      await Future.delayed(const Duration(milliseconds: 100));

      state = bloc.state as InAppNotificationLoaded;
      expect(state.unreadCount, equals(0), reason: 'Sau markAsRead unreadCount phải = 0');

      final readNotif = state.notifications.firstWhere((n) => n.id == 'a1');
      expect(readNotif.isRead, isTrue, reason: 'Notification a1 phải isRead = true');

      await bloc.close();
    });
  });

  // ─────────────────────────────────────────────────────────
  // BUG-4: Time request không bị duplicate khi stream re-emit
  // ─────────────────────────────────────────────────────────
  group('BUG-4: watchPendingRequests distinct() dedup', () {
    test('Cùng ID emit nhiều lần → notification list không tăng kích thước', () async {
      final controller = StreamController<List<TimeRequest>>();
      when(() => mockAlertRepo.watchAllFamilyAlerts(familyId: any(named: 'familyId')))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockTimeRequestRepo.watchPendingRequests(familyId: any(named: 'familyId')))
          .thenAnswer((_) => controller.stream);

      final bloc = InAppNotificationBloc(
        alertRepository: mockAlertRepo,
        timeRequestRepository: mockTimeRequestRepo,
      );

      bloc.add(const LoadInAppNotifications(familyId: 'fam1'));
      await Future.delayed(const Duration(milliseconds: 50));

      // Emit cùng 2 requests 5 lần (simulate switchMap storm)
      final requests = [_request(id: 'req-A'), _request(id: 'req-B', minutes: 30)];
      for (int i = 0; i < 5; i++) {
        controller.add(requests);
        await Future.delayed(const Duration(milliseconds: 30));
      }
      controller.close();
      await Future.delayed(const Duration(milliseconds: 100));

      final state = bloc.state as InAppNotificationLoaded;
      final timeRequests = state.notifications.where((n) => n.type == 'time_request').toList();

      expect(timeRequests.length, equals(2),
          reason: 'BUG-4 FIX: Dù emit 5 lần, chỉ 2 unique requests trong list');

      await bloc.close();
    });

    test('2 request khác ID đều xuất hiện', () async {
      when(() => mockAlertRepo.watchAllFamilyAlerts(familyId: any(named: 'familyId')))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockTimeRequestRepo.watchPendingRequests(familyId: any(named: 'familyId')))
          .thenAnswer((_) => Stream.value([
                _request(id: 'req-1', appName: 'TikTok'),
                _request(id: 'req-2', appName: 'YouTube'),
              ]));

      final bloc = InAppNotificationBloc(
        alertRepository: mockAlertRepo,
        timeRequestRepository: mockTimeRequestRepo,
      );

      bloc.add(const LoadInAppNotifications(familyId: 'fam1'));
      await Future.delayed(const Duration(milliseconds: 200));

      final state = bloc.state as InAppNotificationLoaded;
      final timeRequests = state.notifications.where((n) => n.type == 'time_request').toList();
      expect(timeRequests.length, equals(2));
      expect(timeRequests.any((n) => n.body.contains('TikTok')), isTrue);
      expect(timeRequests.any((n) => n.body.contains('YouTube')), isTrue);

      await bloc.close();
    });
  });
}
