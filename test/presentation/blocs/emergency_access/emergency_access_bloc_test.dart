import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/data/datasources/remote/emergency_log_source.dart';
import 'package:kidguardian/data/models/emergency_log_model.dart';
import 'package:kidguardian/domain/usecases/smart_lock/emergency_access_manager.dart';
import 'package:kidguardian/presentation/blocs/emergency_access/emergency_access_bloc.dart';
import 'package:kidguardian/presentation/blocs/emergency_access/emergency_access_event.dart';
import 'package:kidguardian/presentation/blocs/emergency_access/emergency_access_state.dart';

class MockEmergencyLogSource extends Mock implements EmergencyLogSource {}

class MockEmergencyAccessManager extends Mock implements EmergencyAccessManager {}

void main() {
  late MockEmergencyLogSource mockLogSource;
  late MockEmergencyAccessManager mockManager;
  late StreamController<int> remainingController;
  late StreamController<EmergencyState> stateController;

  setUp(() {
    mockLogSource = MockEmergencyLogSource();
    mockManager = MockEmergencyAccessManager();
    remainingController = StreamController<int>.broadcast();
    stateController = StreamController<EmergencyState>.broadcast();

    when(() => mockManager.remainingStream)
        .thenAnswer((_) => remainingController.stream);
    when(() => mockManager.stateStream)
        .thenAnswer((_) => stateController.stream);
    when(() => mockManager.canActivate).thenReturn(false);
    when(() => mockManager.isActive).thenReturn(false);
    when(() => mockManager.remainingSeconds).thenReturn(0);
    when(() => mockManager.cooldownUntil).thenReturn(null);
    when(() => mockManager.cooldownRemainingSeconds).thenReturn(0);
  });

  tearDown(() {
    remainingController.close();
    stateController.close();
  });

  EmergencyAccessBloc createBloc() {
    return EmergencyAccessBloc(
      logSource: mockLogSource,
      emergencyManager: mockManager,
    );
  }

  EmergencyLogModel makeLogModel({
    String id = 'log1',
    String childUid = 'child1',
    String familyId = 'fam1',
    String action = 'call',
    String status = 'completed',
  }) {
    return EmergencyLogModel(
      id: id,
      childUid: childUid,
      familyId: familyId,
      action: action,
      phoneNumber: '0901234567',
      appPackageName: 'com.example.app',
      timestamp: DateTime(2026, 5, 31, 10, 0),
      durationSeconds: 300,
      status: status,
    );
  }

  group('EmergencyAccessBloc', () {
    test('initial state is EmergencyAccessInitial', () {
      final bloc = createBloc();
      expect(bloc.state, isA<EmergencyAccessInitial>());
      bloc.close();
    });

    group('LoadEmergencyHistory', () {
      blocTest<EmergencyAccessBloc, EmergencyAccessState>(
        'emits [EmergencyAccessLoading, EmergencyHistoryLoaded] on success',
        setUp: () {
          when(() => mockLogSource.getEmergencyHistory(familyId: 'fam1'))
              .thenAnswer((_) async => [makeLogModel(), makeLogModel(id: 'log2')]);
        },
        build: () => createBloc(),
        act: (bloc) => bloc.add(const LoadEmergencyHistory(familyId: 'fam1')),
        expect: () => [
          isA<EmergencyAccessLoading>(),
          isA<EmergencyHistoryLoaded>()
              .having((s) => s.history.length, 'history length', 2),
        ],
      );

      blocTest<EmergencyAccessBloc, EmergencyAccessState>(
        'emits [EmergencyAccessLoading, EmergencyHistoryLoaded] with empty list',
        setUp: () {
          when(() => mockLogSource.getEmergencyHistory(familyId: 'fam1'))
              .thenAnswer((_) async => []);
        },
        build: () => createBloc(),
        act: (bloc) => bloc.add(const LoadEmergencyHistory(familyId: 'fam1')),
        expect: () => [
          isA<EmergencyAccessLoading>(),
          isA<EmergencyHistoryLoaded>()
              .having((s) => s.history, 'history', isEmpty),
        ],
      );

      blocTest<EmergencyAccessBloc, EmergencyAccessState>(
        'emits [EmergencyAccessLoading, EmergencyAccessError] on failure',
        setUp: () {
          when(() => mockLogSource.getEmergencyHistory(
                familyId: any(named: 'familyId'),
              )).thenThrow(Exception('DB error'));
        },
        build: () => createBloc(),
        act: (bloc) => bloc.add(const LoadEmergencyHistory(familyId: 'fam1')),
        expect: () => [
          isA<EmergencyAccessLoading>(),
          isA<EmergencyAccessError>().having(
            (e) => e.message,
            'message',
            contains('Không thể tải lịch sử'),
          ),
        ],
      );
    });

    group('LoadEmergencyContacts', () {
      blocTest<EmergencyAccessBloc, EmergencyAccessState>(
        'emits [EmergencyAccessLoading, EmergencyContactLoaded] on success',
        setUp: () {
          when(() => mockLogSource.getParentName('parent1'))
              .thenAnswer((_) async => 'John Doe');
          when(() => mockLogSource.getParentPhoneNumber('parent1'))
              .thenAnswer((_) async => '0901234567');
        },
        build: () => createBloc(),
        act: (bloc) =>
            bloc.add(const LoadEmergencyContacts(parentUid: 'parent1')),
        expect: () => [
          isA<EmergencyAccessLoading>(),
          isA<EmergencyContactLoaded>()
              .having((s) => s.parentName, 'parentName', 'John Doe')
              .having((s) => s.parentPhone, 'parentPhone', '0901234567'),
        ],
      );

      blocTest<EmergencyAccessBloc, EmergencyAccessState>(
        'emits EmergencyContactLoaded with null values when not found',
        setUp: () {
          when(() => mockLogSource.getParentName('parent1'))
              .thenAnswer((_) async => null);
          when(() => mockLogSource.getParentPhoneNumber('parent1'))
              .thenAnswer((_) async => null);
        },
        build: () => createBloc(),
        act: (bloc) =>
            bloc.add(const LoadEmergencyContacts(parentUid: 'parent1')),
        expect: () => [
          isA<EmergencyAccessLoading>(),
          isA<EmergencyContactLoaded>()
              .having((s) => s.parentName, 'parentName', isNull)
              .having((s) => s.parentPhone, 'parentPhone', isNull),
        ],
      );

      blocTest<EmergencyAccessBloc, EmergencyAccessState>(
        'emits [EmergencyAccessLoading, EmergencyAccessError] on failure',
        setUp: () {
          when(() => mockLogSource.getParentName(any()))
              .thenThrow(Exception('Network error'));
        },
        build: () => createBloc(),
        act: (bloc) =>
            bloc.add(const LoadEmergencyContacts(parentUid: 'parent1')),
        expect: () => [
          isA<EmergencyAccessLoading>(),
          isA<EmergencyAccessError>().having(
            (e) => e.message,
            'message',
            contains('Không thể tải thông tin liên hệ'),
          ),
        ],
      );
    });

    group('UpdateEmergencyPhone', () {
      blocTest<EmergencyAccessBloc, EmergencyAccessState>(
        'emits [EmergencyAccessLoading, EmergencyAccessSuccess] on success',
        setUp: () {
          when(() => mockLogSource.updateParentPhoneNumber(
                parentUid: 'parent1',
                phoneNumber: '0987654321',
              )).thenAnswer((_) async {});
        },
        build: () => createBloc(),
        act: (bloc) => bloc.add(const UpdateEmergencyPhone(
          parentUid: 'parent1',
          phoneNumber: '0987654321',
        )),
        expect: () => [
          isA<EmergencyAccessLoading>(),
          isA<EmergencyAccessSuccess>().having(
            (s) => s.message,
            'message',
            'Cập nhật số điện thoại thành công',
          ),
        ],
      );

      blocTest<EmergencyAccessBloc, EmergencyAccessState>(
        'emits [EmergencyAccessLoading, EmergencyAccessError] on failure',
        setUp: () {
          when(() => mockLogSource.updateParentPhoneNumber(
                parentUid: any(named: 'parentUid'),
                phoneNumber: any(named: 'phoneNumber'),
              )).thenThrow(Exception('Update failed'));
        },
        build: () => createBloc(),
        act: (bloc) => bloc.add(const UpdateEmergencyPhone(
          parentUid: 'parent1',
          phoneNumber: '0987654321',
        )),
        expect: () => [
          isA<EmergencyAccessLoading>(),
          isA<EmergencyAccessError>().having(
            (e) => e.message,
            'message',
            contains('Không thể cập nhật số điện thoại'),
          ),
        ],
      );
    });

    group('ActivateEmergency', () {
      blocTest<EmergencyAccessBloc, EmergencyAccessState>(
        'emits EmergencyActivated when canActivate is true',
        setUp: () {
          when(() => mockManager.canActivate).thenReturn(true);
          when(() => mockLogSource.logEmergencyStart(
                childUid: any(named: 'childUid'),
                familyId: any(named: 'familyId'),
                action: any(named: 'action'),
                phoneNumber: any(named: 'phoneNumber'),
                appPackageName: any(named: 'appPackageName'),
              )).thenAnswer((_) async {});
        },
        build: () => createBloc(),
        act: (bloc) => bloc.add(const ActivateEmergency(
          childUid: 'child1',
          familyId: 'fam1',
          action: 'call',
          phoneNumber: '0901234567',
          appPackageName: 'com.example.app',
        )),
        expect: () => [
          isA<EmergencyActivated>()
              .having((s) => s.action, 'action', 'call')
              .having((s) => s.phoneNumber, 'phoneNumber', '0901234567'),
        ],
        verify: (_) {
          verify(() => mockManager.activate()).called(1);
          verify(() => mockLogSource.logEmergencyStart(
                childUid: 'child1',
                familyId: 'fam1',
                action: 'call',
                phoneNumber: '0901234567',
                appPackageName: 'com.example.app',
              )).called(1);
        },
      );

      blocTest<EmergencyAccessBloc, EmergencyAccessState>(
        'emits EmergencyAccessError when canActivate is false',
        setUp: () {
          when(() => mockManager.canActivate).thenReturn(false);
        },
        build: () => createBloc(),
        act: (bloc) => bloc.add(const ActivateEmergency(
          childUid: 'child1',
          familyId: 'fam1',
          action: 'call',
          phoneNumber: '0901234567',
          appPackageName: 'com.example.app',
        )),
        expect: () => [
          isA<EmergencyAccessError>().having(
            (e) => e.message,
            'message',
            contains('Không thể kích hoạt lúc này'),
          ),
        ],
        verify: (_) {
          verifyNever(() => mockManager.activate());
        },
      );
    });

    group('DeactivateEmergency', () {
      blocTest<EmergencyAccessBloc, EmergencyAccessState>(
        'emits EmergencyAccessSuccess after deactivation',
        setUp: () {
          when(() => mockManager.remainingSeconds).thenReturn(120);
          when(() => mockLogSource.logEmergencyEnd(
                childUid: any(named: 'childUid'),
                durationSeconds: any(named: 'durationSeconds'),
              )).thenAnswer((_) async {});
        },
        build: () => createBloc(),
        act: (bloc) =>
            bloc.add(const DeactivateEmergency(childUid: 'child1')),
        expect: () => [
          isA<EmergencyAccessSuccess>().having(
            (s) => s.message,
            'message',
            'Đã tắt truy cập khẩn cấp',
          ),
        ],
        verify: (_) {
          verify(() => mockManager.deactivate()).called(1);
          verify(() => mockLogSource.logEmergencyEnd(
                childUid: 'child1',
                durationSeconds: any(named: 'durationSeconds'),
              )).called(1);
        },
      );
    });

    group('ListenEmergencyState', () {
      blocTest<EmergencyAccessBloc, EmergencyAccessState>(
        'emits EmergencyActive when manager is active',
        setUp: () {
          when(() => mockManager.isActive).thenReturn(true);
          when(() => mockManager.remainingSeconds).thenReturn(240);
        },
        build: () => createBloc(),
        act: (bloc) => bloc.add(ListenEmergencyState()),
        expect: () => [
          isA<EmergencyActive>()
              .having((s) => s.remainingSeconds, 'remainingSeconds', 240),
        ],
      );

      blocTest<EmergencyAccessBloc, EmergencyAccessState>(
        'emits EmergencyCooldown when manager has cooldownUntil',
        setUp: () {
          when(() => mockManager.isActive).thenReturn(false);
          when(() => mockManager.cooldownUntil)
              .thenReturn(DateTime.now().add(const Duration(minutes: 10)));
          when(() => mockManager.cooldownRemainingSeconds).thenReturn(600);
        },
        build: () => createBloc(),
        act: (bloc) => bloc.add(ListenEmergencyState()),
        expect: () => [
          isA<EmergencyCooldown>()
              .having((s) => s.cooldownSeconds, 'cooldownSeconds', 600),
        ],
      );

      blocTest<EmergencyAccessBloc, EmergencyAccessState>(
        'emits nothing when manager is inactive and no cooldown',
        build: () => createBloc(),
        act: (bloc) => bloc.add(ListenEmergencyState()),
        expect: () => [],
      );
    });

    group('EmergencyTimerUpdated', () {
      blocTest<EmergencyAccessBloc, EmergencyAccessState>(
        'emits EmergencyActive with updated seconds when currently active',
        setUp: () {
          when(() => mockManager.isActive).thenReturn(true);
        },
        build: () => createBloc(),
        seed: () => const EmergencyActive(
          remainingSeconds: 200,
          action: 'call',
          phoneNumber: '0901234567',
        ),
        act: (bloc) =>
            bloc.add(const EmergencyTimerUpdated(remainingSeconds: 199)),
        expect: () => [
          isA<EmergencyActive>()
              .having((s) => s.remainingSeconds, 'remainingSeconds', 199)
              .having((s) => s.action, 'action', 'call')
              .having(
                  (s) => s.phoneNumber, 'phoneNumber', '0901234567'),
        ],
      );

      blocTest<EmergencyAccessBloc, EmergencyAccessState>(
        'emits nothing when manager is not active',
        setUp: () {
          when(() => mockManager.isActive).thenReturn(false);
        },
        build: () => createBloc(),
        seed: () => const EmergencyActive(
          remainingSeconds: 200,
          action: 'call',
          phoneNumber: '0901234567',
        ),
        act: (bloc) =>
            bloc.add(const EmergencyTimerUpdated(remainingSeconds: 199)),
        expect: () => [],
      );

      blocTest<EmergencyAccessBloc, EmergencyAccessState>(
        'emits nothing when current state is not EmergencyActive',
        setUp: () {
          when(() => mockManager.isActive).thenReturn(true);
        },
        build: () => createBloc(),
        seed: () => EmergencyAccessInitial(),
        act: (bloc) =>
            bloc.add(const EmergencyTimerUpdated(remainingSeconds: 199)),
        expect: () => [],
      );
    });
  });
}
