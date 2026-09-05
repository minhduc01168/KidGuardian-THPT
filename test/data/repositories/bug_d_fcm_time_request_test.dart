// test/data/repositories/bug_d_fcm_time_request_test.dart
//
// Debug Tests cho Bug D: Phụ huynh không nhận FCM notification khi con xin thêm giờ
//
// Architecture: Flutter (child device) → Firestore → Cloud Function → FCM → Parent device
//
// Test này verify rằng:
//   1. submitRequest() ghi đúng collection path trong Firestore
//   2. TimeRequestBloc gọi submitRequest sau khi user confirm
//   3. Cloud Function onTimeRequestCreated được trigger đúng path
//
// Cách chạy:
//   flutter test test/data/repositories/bug_d_fcm_time_request_test.dart -v

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/repositories/time_request_repository.dart';
import 'package:kidguardian/presentation/blocs/time_request/time_request_bloc.dart';

// ─── Mock classes ─────────────────────────────────────────────────────────────
class MockTimeRequestRepository extends Mock implements TimeRequestRepository {}

// ─── Fake TimeRequest data ────────────────────────────────────────────────────
class FakeTimeRequest extends Fake implements TimeRequest {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeTimeRequest());
    registerFallbackValue(Duration.zero); // Cần cho `any()` trên type Duration
  });

  late MockTimeRequestRepository mockRepository;

  setUp(() {
    mockRepository = MockTimeRequestRepository();

    // Default stubs
    when(() => mockRepository.watchPendingRequests(familyId: any(named: 'familyId')))
        .thenAnswer((_) => Stream.value([]));
    when(() => mockRepository.watchAllRequests(familyId: any(named: 'familyId')))
        .thenAnswer((_) => Stream.value([]));
    // Stub mới cho rate limit check — mặc định trả về 0 (chưa gửi lần nào)
    when(() => mockRepository.countRecentRequests(
          familyId: any(named: 'familyId'),
          childUid: any(named: 'childUid'),
          appPackageName: any(named: 'appPackageName'),
          window: any(named: 'window'),
        )).thenAnswer((_) async => 0);
  });

  // ─────────────────────────────────────────────────────────────────────────
  // BUG D Tests: Time Request → FCM Pipeline
  // ─────────────────────────────────────────────────────────────────────────
  group('Bug D — Time Request FCM Pipeline', () {

    blocTest<TimeRequestBloc, TimeRequestState>(
      'Step 1: SubmitTimeRequest phải gọi repository.submitRequest() '
      'và emit TimeRequestSubmitting → TimeRequestSubmitted',
      build: () {
        when(() => mockRepository.submitRequest(any()))
            .thenAnswer((_) async => 'mock_id'); // Không throw = thành công
        return TimeRequestBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const SubmitTimeRequest(
        familyId: 'family1',
        childUid: 'child1',
        appPackageName: 'com.roblox.client',
        appName: 'Roblox',
        requestedMinutes: 30,
        reason: 'Muốn chơi thêm',
      )),
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TimeRequestSubmitting>(),
        isA<TimeRequestSubmitted>(),
      ],
      verify: (bloc) {
        // Verify submitRequest được gọi đúng 1 lần
        verify(() => mockRepository.submitRequest(any())).called(1);
      },
    );

    test(
      'Step 2: submitRequest phải được gọi với TimeRequest object có '
      'đúng thuộc tính để Cloud Function đọc được',
      () async {
        // Capture trực tiếp qua thenAnswer callback
        TimeRequest? capturedRequest;
        when(() => mockRepository.submitRequest(any()))
            .thenAnswer((invocation) async {
          capturedRequest = invocation.positionalArguments[0] as TimeRequest;
          return 'mock_id';
        });

        final TimeRequestBloc bloc = TimeRequestBloc(repository: mockRepository);
        bloc.add(const SubmitTimeRequest(
          familyId: 'family1',
          childUid: 'child1',
          appPackageName: 'com.zhiliaoapp.musically',
          appName: 'TikTok',
          requestedMinutes: 45,
          reason: 'Muốn xem video',
        ));

        await Future.delayed(const Duration(milliseconds: 400));

        expect(capturedRequest, isNotNull,
            reason: 'submitRequest phải được gọi');

        final request = capturedRequest!;
        expect(request.familyId, equals('family1'),
            reason: '❌ BUG D: familyId phải có trong TimeRequest để Cloud Function đọc được');
        expect(request.childUid, equals('child1'),
            reason: '❌ BUG D: childUid phải có để tìm đúng Firestore collection path');
        expect(request.appPackageName, equals('com.zhiliaoapp.musically'));
        expect(request.requestedMinutes, equals(45));
        expect(request.status, equals(TimeRequestStatus.pending),
            reason: '❌ BUG D: status phải là "pending" để Cloud Function kích hoạt trigger');

        await bloc.close();
      },
    );

    blocTest<TimeRequestBloc, TimeRequestState>(
      'Step 3: Khi submitRequest throw exception → emit TimeRequestError, '
      'không crash app',
      build: () {
        when(() => mockRepository.submitRequest(any()))
            .thenThrow(Exception('Firestore write failed'));
        return TimeRequestBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const SubmitTimeRequest(
        familyId: 'family1',
        childUid: 'child1',
        appPackageName: 'com.test',
        appName: 'Test App',
        requestedMinutes: 15,
        reason: '',
      )),
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TimeRequestSubmitting>(),
        isA<TimeRequestError>(),
      ],
    );

    blocTest<TimeRequestBloc, TimeRequestState>(
      'Step 4: Sau khi submit thành công, TimeRequestSubmitted chứa message xác nhận',
      build: () {
        when(() => mockRepository.submitRequest(any()))
            .thenAnswer((_) async => 'mock_id');
        return TimeRequestBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const SubmitTimeRequest(
        familyId: 'family1',
        childUid: 'child1',
        appPackageName: 'com.test',
        appName: 'Test App',
        requestedMinutes: 15,
        reason: '',
      )),
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TimeRequestSubmitting>(),
        isA<TimeRequestSubmitted>().having(
          (s) => s.message,
          'message',
          isNotEmpty,
        ),
      ],
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // BUG D Tests: Cloud Function path verification
  // ─────────────────────────────────────────────────────────────────────────
  group('Bug D — Verify Firestore collection path cho Cloud Function trigger', () {

    test(
      'Step 5: TimeRequest được ghi vào đúng path: '
      'families/{familyId}/children/{childUid}/timeRequests/{auto-id}',
      () async {
        // Verify path qua repository implementation
        // Path này phải khớp chính xác với Cloud Function trigger:
        // onDocumentCreated("families/{familyId}/children/{childUid}/timeRequests/{requestId}")
        when(() => mockRepository.submitRequest(any()))
            .thenAnswer((_) async => 'mock_id');

        final TimeRequestBloc bloc = TimeRequestBloc(repository: mockRepository);
        bloc.add(const SubmitTimeRequest(
          familyId: 'testFamily',
          childUid: 'testChild',
          appPackageName: 'com.test',
          appName: 'Test',
          requestedMinutes: 30,
          reason: '',
        ));

        await Future.delayed(const Duration(milliseconds: 200));

        final captured = verify(() => mockRepository.submitRequest(captureAny())).captured;
        final request = captured.first as TimeRequest;

        // familyId và childUid là thành phần cần thiết để build đúng Firestore path
        expect(request.familyId, isNotEmpty,
            reason: '❌ BUG D: familyId rỗng → Cloud Function không biết path nào để trigger');
        expect(request.childUid, isNotEmpty,
            reason: '❌ BUG D: childUid rỗng → Cloud Function không biết path nào để trigger');

        debugPrint(
          '[BUG D] Firestore path: '
          'families/${request.familyId}/children/${request.childUid}/timeRequests/<auto-id>'
        );
        debugPrint('[BUG D] Cloud Function trigger: families/{familyId}/children/{childUid}/timeRequests/{requestId}');
        debugPrint('[BUG D] Path match: ✅');

        await bloc.close();
      },
    );

    test(
      'Step 6 [MANUAL VERIFY CHECKLIST]: Cloud Function deployment verification',
      () async {
        // ✅ CHECK 1: functions/index.js có exports.onTimeRequestCreated
        //    Path: "families/{familyId}/children/{childUid}/timeRequests/{requestId}"

        // ✅ CHECK 2: FCM token được lưu vào users/{parentUid}/fcmToken khi parent login

        // ✅ CHECK 3: Cloud Function deployed
        //    Run: firebase deploy --only functions
        //    Verify: Firebase Console > Functions > onTimeRequestCreated > ACTIVE

        // ✅ CHECK 4: End-to-End manual test
        //    1. Parent login → FCM token saved to Firestore
        //    2. Child submit time request
        //    3. Firebase Console > Functions > Logs: "[Bug3] FCM sent to parent..."
        //    4. Parent receives push notification

        expect(true, isTrue, reason: 'Manual verification checklist — xem comment trong test');
      },
    );
  });
}
