import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/repositories/usage_repository.dart';
import 'package:kidguardian/domain/entities/usage_log.dart';
import 'package:kidguardian/domain/usecases/dashboard/load_child_usage_usecase.dart';

abstract class _UsageRepositoryWithGetLogs implements UsageRepository {
  Future<List<UsageLog>> getUsageLogs({required String childUid, required String date});
}

class MockUsageRepository extends Mock implements _UsageRepositoryWithGetLogs {}

void main() {
  late LoadChildUsageUseCase useCase;
  late MockUsageRepository mockRepository;

  setUp(() {
    mockRepository = MockUsageRepository();
    useCase = LoadChildUsageUseCase(mockRepository);
  });

  UsageLog _makeLog({
    String appName = 'TikTok',
    int durationMinutes = 30,
    String childUid = 'child1',
  }) {
    return UsageLog(
      docId: 'doc1',
      childUid: childUid,
      familyId: 'fam1',
      appPackage: 'com.example.app',
      appName: appName,
      startTime: DateTime(2026, 5, 31, 10, 0),
      endTime: DateTime(2026, 5, 31, 10, durationMinutes),
      durationMinutes: durationMinutes,
      date: '2026-05-31',
    );
  }

  group('LoadChildUsageUseCase', () {
    test('throws when childUid is empty', () async {
      expect(
        () => useCase.execute(childUid: '', date: '2026-05-31'),
        throwsA(predicate((e) =>
            e is Exception && e.toString().contains('Child UID không hợp lệ'))),
      );
    });

    test('throws when date is empty', () async {
      expect(
        () => useCase.execute(childUid: 'child1', date: ''),
        throwsA(predicate((e) =>
            e is Exception && e.toString().contains('Ngày không hợp lệ'))),
      );
    });

    test('returns ChildUsageData with correct totalMinutes', () async {
      final logs = [
        _makeLog(durationMinutes: 30),
        _makeLog(durationMinutes: 45),
      ];

      when(() => mockRepository.getUsageLogs(
            childUid: 'child1',
            date: '2026-05-31',
          )).thenAnswer((_) async => logs);

      final result = await useCase.execute(childUid: 'child1', date: '2026-05-31');

      expect(result.totalMinutes, 75);
    });

    test('returns ChildUsageData with correct usageByApp', () async {
      final logs = [
        _makeLog(appName: 'TikTok', durationMinutes: 30),
        _makeLog(appName: 'TikTok', durationMinutes: 20),
        _makeLog(appName: 'YouTube', durationMinutes: 45),
      ];

      when(() => mockRepository.getUsageLogs(
            childUid: 'child1',
            date: '2026-05-31',
          )).thenAnswer((_) async => logs);

      final result = await useCase.execute(childUid: 'child1', date: '2026-05-31');

      expect(result.usageByApp, {'TikTok': 50, 'YouTube': 45});
    });

    test('returns ChildUsageData with logs list', () async {
      final logs = [_makeLog()];

      when(() => mockRepository.getUsageLogs(
            childUid: 'child1',
            date: '2026-05-31',
          )).thenAnswer((_) async => logs);

      final result = await useCase.execute(childUid: 'child1', date: '2026-05-31');

      expect(result.logs, logs);
    });

    test('returns empty data when no logs found', () async {
      when(() => mockRepository.getUsageLogs(
            childUid: 'child1',
            date: '2026-05-31',
          )).thenAnswer((_) async => <UsageLog>[]);

      final result = await useCase.execute(childUid: 'child1', date: '2026-05-31');

      expect(result.totalMinutes, 0);
      expect(result.usageByApp, isEmpty);
      expect(result.logs, isEmpty);
    });

    test('propagates exception from repository', () async {
      when(() => mockRepository.getUsageLogs(
            childUid: 'child1',
            date: '2026-05-31',
          )).thenThrow(Exception('Network error'));

      expect(
        () => useCase.execute(childUid: 'child1', date: '2026-05-31'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
