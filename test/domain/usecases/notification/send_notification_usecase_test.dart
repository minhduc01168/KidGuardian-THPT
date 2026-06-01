import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';
import 'package:kidguardian/domain/usecases/notification/send_notification_usecase.dart';

class MockAlertRepository extends Mock implements AlertRepository {}

void main() {
  late SendNotificationUseCase useCase;
  late MockAlertRepository mockRepository;

  setUp(() {
    mockRepository = MockAlertRepository();
    useCase = SendNotificationUseCase(mockRepository);
  });

  group('SendNotificationUseCase', () {
    test('throws when familyId is empty', () async {
      expect(
        () => useCase.execute(
          familyId: '',
          title: 'Test',
          body: 'Body',
        ),
        throwsA(predicate((e) =>
            e is Exception &&
            e.toString().contains('Family ID không hợp lệ'))),
      );
    });

    test('throws when title is empty', () async {
      expect(
        () => useCase.execute(
          familyId: 'fam1',
          title: '',
          body: 'Body',
        ),
        throwsA(predicate((e) =>
            e is Exception &&
            e.toString().contains('Tiêu đề không được để trống'))),
      );
    });

    test('throws when body is empty', () async {
      expect(
        () => useCase.execute(
          familyId: 'fam1',
          title: 'Test',
          body: '',
        ),
        throwsA(predicate((e) =>
            e is Exception &&
            e.toString().contains('Nội dung không được để trống'))),
      );
    });

    test('completes successfully with valid parameters', () async {
      await useCase.execute(
        familyId: 'fam1',
        title: 'Alert',
        body: 'Test body',
      );
    });

    test('completes successfully with optional type parameter', () async {
      await useCase.execute(
        familyId: 'fam1',
        title: 'Alert',
        body: 'Test body',
        type: 'keyword_detected',
      );
    });
  });
}
