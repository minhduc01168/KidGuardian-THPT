import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';
import 'package:kidguardian/domain/repositories/time_request_repository.dart';
import 'package:kidguardian/domain/usecases/notification/initialize_notifications_usecase.dart';

abstract class _AlertRepositoryWithStream implements AlertRepository {
  Stream<List<AlertModel>> getAlertsStream(String familyId);
}

abstract class _TimeRequestRepositoryWithStream implements TimeRequestRepository {
  Stream<List<TimeRequest>> getRequestsStream(String familyId);
}

class MockAlertRepository extends Mock implements _AlertRepositoryWithStream {}

class MockTimeRequestRepository extends Mock implements _TimeRequestRepositoryWithStream {}

void main() {
  late InitializeNotificationsUseCase useCase;
  late MockAlertRepository mockAlertRepository;
  late MockTimeRequestRepository mockTimeRequestRepository;

  setUp(() {
    mockAlertRepository = MockAlertRepository();
    mockTimeRequestRepository = MockTimeRequestRepository();
    useCase = InitializeNotificationsUseCase(
      mockAlertRepository,
      mockTimeRequestRepository,
    );
  });

  group('InitializeNotificationsUseCase', () {
    test('throws when familyId is empty', () async {
      expect(
        () => useCase.execute(familyId: ''),
        throwsA(predicate((e) =>
            e is Exception &&
            e.toString().contains('Family ID không hợp lệ'))),
      );
    });

    test('calls getAlertsStream with familyId', () async {
      when(() => mockAlertRepository.getAlertsStream(any()))
          .thenAnswer((_) => const Stream.empty());
      when(() => mockTimeRequestRepository.getRequestsStream(any()))
          .thenAnswer((_) => const Stream.empty());

      await useCase.execute(familyId: 'fam1');

      verify(() => mockAlertRepository.getAlertsStream('fam1')).called(1);
    });

    test('calls getRequestsStream with familyId', () async {
      when(() => mockAlertRepository.getAlertsStream(any()))
          .thenAnswer((_) => const Stream.empty());
      when(() => mockTimeRequestRepository.getRequestsStream(any()))
          .thenAnswer((_) => const Stream.empty());

      await useCase.execute(familyId: 'fam1');

      verify(() => mockTimeRequestRepository.getRequestsStream('fam1')).called(1);
    });

    test('propagates exception from alert repository', () async {
      when(() => mockAlertRepository.getAlertsStream(any()))
          .thenThrow(Exception('Stream error'));

      expect(
        () => useCase.execute(familyId: 'fam1'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
