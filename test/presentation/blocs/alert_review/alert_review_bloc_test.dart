import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';
import 'package:kidguardian/presentation/blocs/alert_review/alert_review_bloc.dart';

class MockAlertRepository extends Mock implements AlertRepository {}

void main() {
  late AlertReviewBloc bloc;
  late MockAlertRepository mockAlertRepository;

  setUp(() {
    mockAlertRepository = MockAlertRepository();
    bloc = AlertReviewBloc(alertRepository: mockAlertRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('AlertReviewBloc', () {
    test('initial state is AlertReviewInitial', () {
      expect(bloc.state, isA<AlertReviewInitial>());
    });

    test('LoadAlertDetail emits AlertReviewLoaded when alert found', () async {
      final alert = AlertModel(
        id: 'alert1',
        type: 'keyword_detected',
        keyword: 'test',
        packageName: 'com.test',
        textContext: 'context',
        isReviewed: false,
      );

      when(() => mockAlertRepository.getAlert(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
            alertId: any(named: 'alertId'),
          )).thenAnswer((_) async => alert);

      bloc.add(const LoadAlertDetail(
        familyId: 'family1',
        childUid: 'child1',
        alertId: 'alert1',
      ));
      await Future.delayed(const Duration(milliseconds: 200));

      expect(bloc.state, isA<AlertReviewLoaded>());
      final state = bloc.state as AlertReviewLoaded;
      expect(state.alert.id, 'alert1');
    });

    test('LoadAlertDetail emits AlertReviewError when alert not found', () async {
      when(() => mockAlertRepository.getAlert(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
            alertId: any(named: 'alertId'),
          )).thenAnswer((_) async => null);

      bloc.add(const LoadAlertDetail(
        familyId: 'family1',
        childUid: 'child1',
        alertId: 'alert1',
      ));
      await Future.delayed(const Duration(milliseconds: 200));

      expect(bloc.state, isA<AlertReviewError>());
    });

    test('MarkAsReviewed calls repository and reloads alert', () async {
      final alert = AlertModel(
        id: 'alert1',
        type: 'keyword_detected',
        keyword: 'test',
        packageName: 'com.test',
        textContext: 'context',
        isReviewed: false,
      );

      when(() => mockAlertRepository.getAlert(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
            alertId: any(named: 'alertId'),
          )).thenAnswer((_) async => alert);
      when(() => mockAlertRepository.markAlertAsReviewed(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
            alertId: any(named: 'alertId'),
          )).thenAnswer((_) async {});

      bloc.add(const LoadAlertDetail(
        familyId: 'family1',
        childUid: 'child1',
        alertId: 'alert1',
      ));
      await Future.delayed(const Duration(milliseconds: 200));

      bloc.add(const MarkAsReviewed(
        familyId: 'family1',
        childUid: 'child1',
        alertId: 'alert1',
      ));
      await Future.delayed(const Duration(milliseconds: 200));

      verify(() => mockAlertRepository.markAlertAsReviewed(
            familyId: 'family1',
            childUid: 'child1',
            alertId: 'alert1',
          )).called(1);
    });

    test('AddNotes calls repository and reloads alert', () async {
      final alert = AlertModel(
        id: 'alert1',
        type: 'keyword_detected',
        keyword: 'test',
        packageName: 'com.test',
        textContext: 'context',
        isReviewed: false,
      );

      when(() => mockAlertRepository.getAlert(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
            alertId: any(named: 'alertId'),
          )).thenAnswer((_) async => alert);
      when(() => mockAlertRepository.addNotesToAlert(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
            alertId: any(named: 'alertId'),
            notes: any(named: 'notes'),
          )).thenAnswer((_) async {});

      bloc.add(const LoadAlertDetail(
        familyId: 'family1',
        childUid: 'child1',
        alertId: 'alert1',
      ));
      await Future.delayed(const Duration(milliseconds: 200));

      bloc.add(const AddNotes(
        familyId: 'family1',
        childUid: 'child1',
        alertId: 'alert1',
        notes: 'This is a test note',
      ));
      await Future.delayed(const Duration(milliseconds: 200));

      verify(() => mockAlertRepository.addNotesToAlert(
            familyId: 'family1',
            childUid: 'child1',
            alertId: 'alert1',
            notes: 'This is a test note',
          )).called(1);
    });

    test('DismissAlert calls repository and reloads alert', () async {
      final alert = AlertModel(
        id: 'alert1',
        type: 'keyword_detected',
        keyword: 'test',
        packageName: 'com.test',
        textContext: 'context',
        isReviewed: false,
      );

      when(() => mockAlertRepository.getAlert(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
            alertId: any(named: 'alertId'),
          )).thenAnswer((_) async => alert);
      when(() => mockAlertRepository.dismissAlert(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
            alertId: any(named: 'alertId'),
          )).thenAnswer((_) async {});

      bloc.add(const LoadAlertDetail(
        familyId: 'family1',
        childUid: 'child1',
        alertId: 'alert1',
      ));
      await Future.delayed(const Duration(milliseconds: 200));

      bloc.add(const DismissAlert(
        familyId: 'family1',
        childUid: 'child1',
        alertId: 'alert1',
      ));
      await Future.delayed(const Duration(milliseconds: 200));

      verify(() => mockAlertRepository.dismissAlert(
            familyId: 'family1',
            childUid: 'child1',
            alertId: 'alert1',
          )).called(1);
    });
  });
}
