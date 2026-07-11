import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/repositories/time_request_repository.dart';
import 'package:kidguardian/presentation/blocs/time_request/time_request_bloc.dart';

class MockTimeRequestRepository extends Mock implements TimeRequestRepository {}
class FakeTimeRequest extends Fake implements TimeRequest {}

void main() {
  late TimeRequestBloc bloc;
  late MockTimeRequestRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeTimeRequest());
  });

  setUp(() {
    mockRepository = MockTimeRequestRepository();
    bloc = TimeRequestBloc(repository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('TimeRequestBloc', () {
    test('initial state is TimeRequestInitial', () {
      expect(bloc.state, isA<TimeRequestInitial>());
    });

    test('SubmitTimeRequest emits TimeRequestSubmitted on success', () async {
      when(() => mockRepository.submitRequest(any())).thenAnswer((_) async {});

      bloc.add(const SubmitTimeRequest(
        familyId: 'family1',
        childUid: 'child1',
        appPackageName: 'com.test.app',
        appName: 'TestApp',
        requestedMinutes: 30,
        reason: 'Need more time',
      ));
      await Future.delayed(const Duration(milliseconds: 200));

      expect(bloc.state, isA<TimeRequestSubmitted>());
      final state = bloc.state as TimeRequestSubmitted;
      expect(state.message, contains('đã được gửi'));
    });

    test('SubmitTimeRequest emits TimeRequestError on failure', () async {
      when(() => mockRepository.submitRequest(any())).thenThrow(Exception('Network error'));

      bloc.add(const SubmitTimeRequest(
        familyId: 'family1',
        childUid: 'child1',
        appPackageName: 'com.test.app',
        appName: 'TestApp',
        requestedMinutes: 30,
        reason: 'Need more time',
      ));
      await Future.delayed(const Duration(milliseconds: 200));

      expect(bloc.state, isA<TimeRequestError>());
    });

    test('LoadTimeRequests starts listening and emits TimeRequestsLoaded', () async {
      when(() => mockRepository.watchRequests(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
          )).thenAnswer((_) => Stream.value([]));

      bloc.add(const LoadTimeRequests(familyId: 'family1', childUid: 'child1'));
      await Future.delayed(const Duration(milliseconds: 200));

      expect(bloc.state, isA<TimeRequestsLoaded>());
    });

    test('ApproveTimeRequest calls repository', () async {
      when(() => mockRepository.approveRequest(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
            requestId: any(named: 'requestId'),
            response: any(named: 'response'),
          )).thenAnswer((_) async {});

      bloc.add(const ApproveTimeRequest(
        familyId: 'family1',
        childUid: 'child1',
        requestId: 'request1',
        response: 'Đồng ý',
      ));
      await Future.delayed(const Duration(milliseconds: 200));

      verify(() => mockRepository.approveRequest(
            familyId: 'family1',
            childUid: 'child1',
            requestId: 'request1',
            response: 'Đồng ý',
          )).called(1);
    });

    test('RejectTimeRequest calls repository', () async {
      when(() => mockRepository.rejectRequest(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
            requestId: any(named: 'requestId'),
            response: any(named: 'response'),
          )).thenAnswer((_) async {});

      bloc.add(const RejectTimeRequest(
        familyId: 'family1',
        childUid: 'child1',
        requestId: 'request1',
        response: 'Không đồng ý',
      ));
      await Future.delayed(const Duration(milliseconds: 200));

      verify(() => mockRepository.rejectRequest(
            familyId: 'family1',
            childUid: 'child1',
            requestId: 'request1',
            response: 'Không đồng ý',
          )).called(1);
    });
  });
}
