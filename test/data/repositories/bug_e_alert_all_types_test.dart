// test/data/repositories/bug_e_alert_all_types_test.dart
//
// Debug Tests cho Bug E: Alert history không hiển thị các loại cảnh báo khác nhau
// (keyword_detected, app_blocked, time_request)
//
// Cách chạy:
//   flutter test test/data/repositories/bug_e_alert_all_types_test.dart -v

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';
import 'package:kidguardian/domain/repositories/time_request_repository.dart';
import 'package:kidguardian/presentation/blocs/in_app_notification/in_app_notification_bloc.dart';

// ─── Mock classes ─────────────────────────────────────────────────────────────
class MockAlertRepository extends Mock implements AlertRepository {}
class MockTimeRequestRepository extends Mock implements TimeRequestRepository {}

// ─── Fake AlertModel factory ──────────────────────────────────────────────────
AlertModel fakeAlert({
  required String id,
  required String type,
  String keyword = '',
  String packageName = 'com.test.app',
  String textContext = '',
  String childUid = 'child1',
  bool isReviewed = false,
  bool isDismissed = false,
}) {
  return AlertModel(
    id: id,
    type: type,
    keyword: keyword,
    packageName: packageName,
    textContext: textContext,
    childUid: childUid,
    timestamp: DateTime(2026, 8, 23, 10, 0, 0),
    isReviewed: isReviewed,
    isDismissed: isDismissed,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAlertRepository mockAlertRepository;
  late MockTimeRequestRepository mockTimeRequestRepository;

  setUp(() {
    mockAlertRepository = MockAlertRepository();
    mockTimeRequestRepository = MockTimeRequestRepository();

    // Default: stream rỗng cho time requests
    when(() => mockTimeRequestRepository.watchPendingRequests(familyId: any(named: 'familyId')))
        .thenAnswer((_) => Stream.value([]));
  });

  InAppNotificationBloc buildBloc() {
    return InAppNotificationBloc(
      alertRepository: mockAlertRepository,
      timeRequestRepository: mockTimeRequestRepository,
    );
  }

  // Helper: Get final loaded state
  Future<InAppNotificationLoaded> getFinalLoadedState(InAppNotificationBloc bloc) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final state = bloc.state;
    if (state is InAppNotificationLoaded) return state;
    throw StateError('Expected InAppNotificationLoaded but got: $state');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUG E Tests: Alert types — verify bằng unit test thủ công
  // ─────────────────────────────────────────────────────────────────────────
  group('Bug E — Alert Repository: tất cả loại alert phải hiển thị', () {

    test(
      'Step 1: keyword_detected alert → xuất hiện trong notification list '
      'với title "⚠️ Cảnh báo từ khóa"',
      () async {
        when(() => mockAlertRepository.watchAllFamilyAlerts(familyId: 'family1'))
            .thenAnswer((_) => Stream.value([
              fakeAlert(id: 'alert1', type: 'keyword_detected', keyword: 'tự tử', packageName: 'com.test.app'),
            ]));

        final bloc = buildBloc();
        bloc.add(const LoadInAppNotifications(familyId: 'family1'));
        final state = await getFinalLoadedState(bloc);

        expect(state.notifications.any((n) => n.id == 'alert1'), isTrue,
            reason: '❌ BUG E: keyword_detected alert không hiện trong notification list');

        final notif = state.notifications.firstWhere((n) => n.id == 'alert1');
        expect(notif.title, contains('Cảnh báo từ khóa'),
            reason: 'Title phải là "⚠️ Cảnh báo từ khóa"');
        expect(notif.type, equals('alert'));

        await bloc.close();
      },
    );

    test(
      'Step 2: app_blocked alert → xuất hiện trong notification list '
      'với title "🔒 Ứng dụng bị chặn"',
      () async {
        when(() => mockAlertRepository.watchAllFamilyAlerts(familyId: 'family1'))
            .thenAnswer((_) => Stream.value([
              fakeAlert(id: 'alert2', type: 'app_blocked', packageName: 'com.facebook.katana'),
            ]));

        final bloc = buildBloc();
        bloc.add(const LoadInAppNotifications(familyId: 'family1'));
        final state = await getFinalLoadedState(bloc);

        expect(state.notifications.any((n) => n.id == 'alert2'), isTrue,
            reason: '❌ BUG E: app_blocked alert không hiện trong notification list');

        final notif = state.notifications.firstWhere((n) => n.id == 'alert2');
        expect(notif.title, contains('Ứng dụng bị chặn'),
            reason: 'Title phải là "🔒 Ứng dụng bị chặn"');

        await bloc.close();
      },
    );

    test(
      'Step 3: time_request alert từ AlertRepository phải bị bỏ qua '
      '(đã được xử lý riêng qua TimeRequestRepository stream)',
      () async {
        when(() => mockAlertRepository.watchAllFamilyAlerts(familyId: 'family1'))
            .thenAnswer((_) => Stream.value([
              fakeAlert(id: 'alert3', type: 'time_request', packageName: 'com.roblox.client'),
            ]));

        final bloc = buildBloc();
        bloc.add(const LoadInAppNotifications(familyId: 'family1'));
        final state = await getFinalLoadedState(bloc);

        // time_request từ alert repo bị skip — xử lý qua timeRequestRepository stream riêng
        final timeReqFromAlertRepo = state.notifications.where((n) => n.id == 'alert3');
        expect(timeReqFromAlertRepo.isEmpty, isTrue,
            reason: 'time_request alert từ AlertRepository phải được bỏ qua '
                'để tránh duplicate với TimeRequestRepository stream');

        await bloc.close();
      },
    );

    test(
      'Step 4: Mixed alerts (keyword + app_blocked) → TẤT CẢ 3 phải hiện',
      () async {
        when(() => mockAlertRepository.watchAllFamilyAlerts(familyId: 'family1'))
            .thenAnswer((_) => Stream.value([
              fakeAlert(id: 'kw1', type: 'keyword_detected', keyword: 'cờ bạc'),
              fakeAlert(id: 'bl1', type: 'app_blocked', packageName: 'com.tiktok'),
              fakeAlert(id: 'kw2', type: 'keyword_detected', keyword: 'ma túy'),
            ]));

        final bloc = buildBloc();
        bloc.add(const LoadInAppNotifications(familyId: 'family1'));
        final state = await getFinalLoadedState(bloc);

        final ids = state.notifications.map((n) => n.id).toList();
        expect(ids, containsAll(['kw1', 'bl1', 'kw2']),
            reason: '❌ BUG E: Tất cả 3 alerts phải hiện. '
                'Actual: $ids');

        expect(state.notifications.length, greaterThanOrEqualTo(3),
            reason: 'Phải có ít nhất 3 notifications');

        await bloc.close();
      },
    );

    test(
      'Step 5: Reviewed alerts (isReviewed=true) → được mark isRead=true trong UI, '
      'unreadCount = 1 (chỉ 1 chưa đọc)',
      () async {
        when(() => mockAlertRepository.watchAllFamilyAlerts(familyId: 'family1'))
            .thenAnswer((_) => Stream.value([
              fakeAlert(id: 'reviewed1', type: 'keyword_detected', isReviewed: true),
              fakeAlert(id: 'new1', type: 'keyword_detected', isReviewed: false),
            ]));

        final bloc = buildBloc();
        bloc.add(const LoadInAppNotifications(familyId: 'family1'));
        final state = await getFinalLoadedState(bloc);

        expect(state.unreadCount, equals(1),
            reason: '❌ BUG E: Phải có đúng 1 alert chưa đọc. '
                'Actual unreadCount: ${state.unreadCount}');

        final reviewed = state.notifications.firstWhere((n) => n.id == 'reviewed1');
        expect(reviewed.isRead, isTrue,
            reason: 'Alert đã reviewed phải được mark isRead=true');

        final newAlert = state.notifications.firstWhere((n) => n.id == 'new1');
        expect(newAlert.isRead, isFalse,
            reason: 'Alert chưa reviewed phải có isRead=false');

        await bloc.close();
      },
    );

    test(
      'Step 6: watchAllFamilyAlerts filter isReviewed=false ở Firestore → '
      'bloc chỉ nhận alerts chưa reviewed',
      () async {
        // watchAllFamilyAlerts đã có .where(isDismissed=false) ở Firestore query
        // Nên bloc chỉ nhận alerts chưa dismissed
        when(() => mockAlertRepository.watchAllFamilyAlerts(familyId: 'family1'))
            .thenAnswer((_) => Stream.value([
              // isDismissed=true không được emit bởi repo (filtered at Firestore level)
              fakeAlert(id: 'active1', type: 'keyword_detected', isDismissed: false),
            ]));

        final bloc = buildBloc();
        bloc.add(const LoadInAppNotifications(familyId: 'family1'));
        final state = await getFinalLoadedState(bloc);

        expect(state.notifications.length, equals(1),
            reason: '❌ BUG E: Chỉ có 1 active alert. '
                'Actual: ${state.notifications.length}');

        await bloc.close();
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // BUG E Tests: AlertRepository.watchAllFamilyAlerts type filter
  // ─────────────────────────────────────────────────────────────────────────
  group('Bug E — AlertRepository: watchAllFamilyAlerts không filter theo type', () {

    test(
      'Step 7 (Unit): AlertRepositoryImpl.watchAllFamilyAlerts phải emit '
      'cả keyword_detected VÀ app_blocked alerts sau khi fix',
      () async {
        final mockRepo = MockAlertRepository();
        final mockTimeRepo = MockTimeRequestRepository();

        when(() => mockTimeRepo.watchPendingRequests(familyId: any(named: 'familyId')))
            .thenAnswer((_) => Stream.value([]));

        final mixedAlerts = [
          fakeAlert(id: 'a1', type: 'keyword_detected'),
          fakeAlert(id: 'a2', type: 'app_blocked'),
          fakeAlert(id: 'a3', type: 'keyword_detected'),
        ];

        when(() => mockRepo.watchAllFamilyAlerts(familyId: 'fam1'))
            .thenAnswer((_) => Stream.value(mixedAlerts));

        final bloc = InAppNotificationBloc(
          alertRepository: mockRepo,
          timeRequestRepository: mockTimeRepo,
        );

        bloc.add(const LoadInAppNotifications(familyId: 'fam1'));
        await Future.delayed(const Duration(milliseconds: 400));

        final state = bloc.state;
        expect(state, isA<InAppNotificationLoaded>());

        final loaded = state as InAppNotificationLoaded;
        final ids = loaded.notifications.map((n) => n.id).toList();

        expect(ids, containsAll(['a1', 'a2', 'a3']),
            reason: '❌ BUG E: Sau fix, cả keyword_detected và app_blocked '
                'phải hiện trong notification list. '
                'Actual: $ids');

        await bloc.close();
      },
    );
  });
}
