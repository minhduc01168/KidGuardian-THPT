import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';
import 'package:kidguardian/domain/repositories/time_request_repository.dart';
import 'package:kidguardian/domain/usecases/notification/initialize_notifications_usecase.dart';

class MockAlertRepository extends Mock implements AlertRepository {}

class MockTimeRequestRepository extends Mock implements TimeRequestRepository {}

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

    test('calls watchAllFamilyAlerts with familyId', () async {
      when(() => mockAlertRepository.watchAllFamilyAlerts(familyId: any(named: 'familyId')))
          .thenAnswer((_) => const Stream.empty());
      when(() => mockTimeRequestRepository.watchPendingRequests(familyId: any(named: 'familyId')))
          .thenAnswer((_) => const Stream.empty());

      await useCase.execute(familyId: 'fam1');

      verify(() => mockAlertRepository.watchAllFamilyAlerts(familyId: 'fam1')).called(1);
    });

    test('calls watchPendingRequests with familyId', () async {
      when(() => mockAlertRepository.watchAllFamilyAlerts(familyId: any(named: 'familyId')))
          .thenAnswer((_) => const Stream.empty());
      when(() => mockTimeRequestRepository.watchPendingRequests(familyId: any(named: 'familyId')))
          .thenAnswer((_) => const Stream.empty());

      await useCase.execute(familyId: 'fam1');

      verify(() => mockTimeRequestRepository.watchPendingRequests(familyId: 'fam1')).called(1);
    });

    test('propagates exception from alert repository', () async {
      when(() => mockAlertRepository.watchAllFamilyAlerts(familyId: any(named: 'familyId')))
          .thenThrow(Exception('Stream error'));

      expect(
        () => useCase.execute(familyId: 'fam1'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
