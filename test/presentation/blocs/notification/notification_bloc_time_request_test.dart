import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';
import 'package:kidguardian/domain/repositories/time_request_repository.dart';
import 'package:kidguardian/presentation/blocs/notification/notification_bloc.dart';

class MockAlertRepository extends Mock implements AlertRepository {}
class MockTimeRequestRepository extends Mock implements TimeRequestRepository {}

// Fake FlutterLocalNotificationsPlugin không cần mock show() phức tạp
// Cập nhật cho flutter_local_notifications v21 (tất cả dùng named parameters)
class FakeNotificationsPlugin extends Fake implements FlutterLocalNotificationsPlugin {
  final List<String?> shownPayloads = [];

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails,
    String? payload,
  }) async {
    shownPayloads.add(payload);
  }

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback? onDidReceiveBackgroundNotificationResponse,
  }) async => true;
}

TimeRequest _makeRequest({
  String id = 'req-1',
  String childUid = 'child-123',
  TimeRequestStatus status = TimeRequestStatus.pending,
}) {
  return TimeRequest(
    id: id,
    familyId: 'family-abc',
    childUid: childUid,
    appPackageName: 'com.zhiliaoapp.musically',
    appName: 'TikTok',
    requestedMinutes: 15,
    reason: 'Muốn xem thêm',
    status: status,
    timestamp: DateTime.now(),
  );
}

void main() {
  late MockAlertRepository mockAlertRepo;
  late MockTimeRequestRepository mockTimeRequestRepo;
  late FakeNotificationsPlugin fakePlugin;
  late StreamController<List<TimeRequest>> requestStreamController;

  setUp(() {
    mockAlertRepo = MockAlertRepository();
    mockTimeRequestRepo = MockTimeRequestRepository();
    fakePlugin = FakeNotificationsPlugin();
    requestStreamController = StreamController<List<TimeRequest>>.broadcast();

    when(() => mockAlertRepo.watchAllFamilyAlerts(familyId: any(named: 'familyId')))
        .thenAnswer((_) => const Stream.empty());

    when(() => mockTimeRequestRepo.watchPendingRequests(
          familyId: any(named: 'familyId'),
        )).thenAnswer((_) => requestStreamController.stream);
  });

  tearDown(() {
    requestStreamController.close();
  });

  NotificationBloc buildBloc() => NotificationBloc(
        alertRepository: mockAlertRepo,
        timeRequestRepository: mockTimeRequestRepo,
        notificationsPlugin: fakePlugin,
      );

  group('NotificationBloc — FIX C3: Time Request Stream Listener', () {
    blocTest<NotificationBloc, NotificationState>(
      'StartTimeRequestListening khởi tạo stream và emit NotificationListening',
      build: buildBloc,
      act: (bloc) {
        bloc.add(const StartTimeRequestListening(
          familyId: 'family-abc',
          childUids: ['child-123'],
        ));
      },
      expect: () => [isA<NotificationListening>()],
    );

    blocTest<NotificationBloc, NotificationState>(
      'Time request mới (pending) → hiển thị local notification',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const StartTimeRequestListening(
          familyId: 'family-abc',
          childUids: ['child-123'],
        ));
        await Future.delayed(const Duration(milliseconds: 100));
        requestStreamController.add([_makeRequest()]);
        await Future.delayed(const Duration(milliseconds: 100));
      },
      expect: () => [
        isA<NotificationListening>(),
        isA<NotificationListening>(),
      ],
      verify: (_) {
        expect(fakePlugin.shownPayloads.length, 1);
        expect(fakePlugin.shownPayloads.first, contains('time_request'));
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'Request cùng ID không trigger notification lần thứ 2 (dedup)',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const StartTimeRequestListening(
          familyId: 'family-abc',
          childUids: ['child-123'],
        ));
        await Future.delayed(const Duration(milliseconds: 50));
        final req = _makeRequest(id: 'req-dup');
        requestStreamController.add([req]);
        await Future.delayed(const Duration(milliseconds: 50));
        requestStreamController.add([req]); // cùng request, không notify lại
        await Future.delayed(const Duration(milliseconds: 50));
      },
      verify: (_) {
        expect(fakePlugin.shownPayloads.length, 1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'Hai request khác ID đều trigger notification',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const StartTimeRequestListening(
          familyId: 'family-abc',
          childUids: ['child-123'],
        ));
        await Future.delayed(const Duration(milliseconds: 50));
        requestStreamController.add([_makeRequest(id: 'req-a')]);
        await Future.delayed(const Duration(milliseconds: 50));
        requestStreamController.add([
          _makeRequest(id: 'req-a'),
          _makeRequest(id: 'req-b'),
        ]);
        await Future.delayed(const Duration(milliseconds: 50));
      },
      verify: (_) {
        expect(fakePlugin.shownPayloads.length, 2); // chỉ req-b là mới
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'StopTimeRequestListening — request sau khi stop không trigger notification',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const StartTimeRequestListening(
          familyId: 'family-abc',
          childUids: ['child-123'],
        ));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(StopTimeRequestListening());
        await Future.delayed(const Duration(milliseconds: 50));
        requestStreamController.add([_makeRequest(id: 'req-after-stop')]);
        await Future.delayed(const Duration(milliseconds: 100));
      },
      verify: (_) {
        expect(fakePlugin.shownPayloads, isEmpty);
      },
    );

    group('QuickApproveRequest / QuickRejectRequest', () {
      setUp(() {
        when(() => mockTimeRequestRepo.approveRequest(
              familyId: any(named: 'familyId'),
              childUid: any(named: 'childUid'),
              requestId: any(named: 'requestId'),
              response: any(named: 'response'),
            )).thenAnswer((_) async {});

        when(() => mockTimeRequestRepo.rejectRequest(
              familyId: any(named: 'familyId'),
              childUid: any(named: 'childUid'),
              requestId: any(named: 'requestId'),
              response: any(named: 'response'),
            )).thenAnswer((_) async {});
      });

      blocTest<NotificationBloc, NotificationState>(
        'QuickApproveRequest gọi repository.approveRequest',
        build: buildBloc,
        act: (bloc) {
          bloc.add(const QuickApproveRequest(
            familyId: 'family-abc',
            childUid: 'child-123',
            requestId: 'req-1',
          ));
        },
        expect: () => [isA<NotificationListening>()],
        verify: (_) {
          verify(() => mockTimeRequestRepo.approveRequest(
                familyId: 'family-abc',
                childUid: 'child-123',
                requestId: 'req-1',
                response: any(named: 'response'),
              )).called(1);
        },
      );

      blocTest<NotificationBloc, NotificationState>(
        'QuickRejectRequest gọi repository.rejectRequest',
        build: buildBloc,
        act: (bloc) {
          bloc.add(const QuickRejectRequest(
            familyId: 'family-abc',
            childUid: 'child-123',
            requestId: 'req-1',
          ));
        },
        expect: () => [isA<NotificationListening>()],
        verify: (_) {
          verify(() => mockTimeRequestRepo.rejectRequest(
                familyId: 'family-abc',
                childUid: 'child-123',
                requestId: 'req-1',
                response: any(named: 'response'),
              )).called(1);
        },
      );
    });
  });
}
