import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';
import 'package:kidguardian/presentation/blocs/alert_history/alert_history_bloc.dart';

class MockAlertRepository extends Mock implements AlertRepository {}

void main() {
  late AlertHistoryBloc bloc;
  late MockAlertRepository mockAlertRepository;

  setUp(() {
    mockAlertRepository = MockAlertRepository();
    bloc = AlertHistoryBloc(alertRepository: mockAlertRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('AlertHistoryBloc', () {
    test('initial state is AlertHistoryInitial', () {
      expect(bloc.state, isA<AlertHistoryInitial>());
    });

    test('LoadAlerts starts listening and emits AlertHistoryLoaded', () async {
      when(() => mockAlertRepository.watchNewAlerts(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
          )).thenAnswer((_) => Stream.value([]));

      bloc.add(const LoadAlerts(familyId: 'family1', childUid: 'child1'));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<AlertHistoryLoaded>());
      final state = bloc.state as AlertHistoryLoaded;
      expect(state.filteredAlerts, isEmpty);
      expect(state.filterStatus, AlertFilterStatus.all);
    });

    test('FilterByStatus filters unreviewed alerts', () async {
      final alerts = [
        AlertModel(
          id: '1', type: 'keyword_detected', keyword: 'test',
          packageName: 'com.test', textContext: 'text',
          isReviewed: false,
        ),
        AlertModel(
          id: '2', type: 'keyword_detected', keyword: 'test2',
          packageName: 'com.test', textContext: 'text2',
          isReviewed: true,
        ),
      ];

      when(() => mockAlertRepository.watchNewAlerts(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
          )).thenAnswer((_) => Stream.value(alerts));

      bloc.add(const LoadAlerts(familyId: 'family1', childUid: 'child1'));
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(const FilterByStatus(AlertFilterStatus.unreviewed));
      await Future.delayed(const Duration(milliseconds: 100));

      final state = bloc.state as AlertHistoryLoaded;
      expect(state.filteredAlerts.length, 1);
      expect(state.filteredAlerts.first.id, '1');
    });

    test('FilterByStatus filters reviewed alerts', () async {
      final alerts = [
        AlertModel(
          id: '1', type: 'keyword_detected', keyword: 'test',
          packageName: 'com.test', textContext: 'text',
          isReviewed: false,
        ),
        AlertModel(
          id: '2', type: 'keyword_detected', keyword: 'test2',
          packageName: 'com.test', textContext: 'text2',
          isReviewed: true,
        ),
      ];

      when(() => mockAlertRepository.watchNewAlerts(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
          )).thenAnswer((_) => Stream.value(alerts));

      bloc.add(const LoadAlerts(familyId: 'family1', childUid: 'child1'));
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(const FilterByStatus(AlertFilterStatus.reviewed));
      await Future.delayed(const Duration(milliseconds: 100));

      final state = bloc.state as AlertHistoryLoaded;
      expect(state.filteredAlerts.length, 1);
      expect(state.filteredAlerts.first.id, '2');
    });

    test('MarkAlertReviewed calls repository', () async {
      when(() => mockAlertRepository.watchNewAlerts(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
          )).thenAnswer((_) => Stream.value([]));
      when(() => mockAlertRepository.markAlertAsReviewed(
            familyId: any(named: 'familyId'),
            childUid: any(named: 'childUid'),
            alertId: any(named: 'alertId'),
          )).thenAnswer((_) async {});

      bloc.add(const LoadAlerts(familyId: 'family1', childUid: 'child1'));
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(const MarkAlertReviewedEvent(
        familyId: 'family1',
        childUid: 'child1',
        alertId: 'alert1',
      ));
      await Future.delayed(const Duration(milliseconds: 100));

      verify(() => mockAlertRepository.markAlertAsReviewed(
            familyId: 'family1',
            childUid: 'child1',
            alertId: 'alert1',
          )).called(1);
    });
  });
}
