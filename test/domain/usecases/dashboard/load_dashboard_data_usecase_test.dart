import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/repositories/usage_repository.dart';
import 'package:kidguardian/domain/repositories/family_repository.dart';
import 'package:kidguardian/domain/entities/usage_log.dart';
import 'package:kidguardian/domain/usecases/dashboard/load_dashboard_data_usecase.dart';

abstract class _UsageRepositoryWithGetLogs implements UsageRepository {
  Future<List<UsageLog>> getUsageLogs({required String childUid, required String date});
}

class MockUsageRepository extends Mock implements _UsageRepositoryWithGetLogs {}

class MockFamilyRepository extends Mock implements FamilyRepository {}

void main() {
  late LoadDashboardDataUseCase useCase;
  late MockUsageRepository mockUsageRepository;
  late MockFamilyRepository mockFamilyRepository;

  setUp(() {
    mockUsageRepository = MockUsageRepository();
    mockFamilyRepository = MockFamilyRepository();
    useCase = LoadDashboardDataUseCase(mockUsageRepository, mockFamilyRepository);
  });

  UsageLog _makeLog({
    String appName = 'TikTok',
    int durationMinutes = 30,
    String date = '2026-05-31',
  }) {
    return UsageLog(
      docId: 'doc1',
      childUid: 'child1',
      familyId: 'fam1',
      appPackage: 'com.example.app',
      appName: appName,
      startTime: DateTime(2026, 5, 31, 10, 0),
      endTime: DateTime(2026, 5, 31, 10, durationMinutes),
      durationMinutes: durationMinutes,
      date: date,
    );
  }

  void stubGetUsageLogsForAllDates(List<UsageLog> todayLogs) {
    when(() => mockUsageRepository.getUsageLogs(
          childUid: any(named: 'childUid'),
          date: any(named: 'date'),
        )).thenAnswer((_) async => <UsageLog>[]);
    when(() => mockUsageRepository.getUsageLogs(
          childUid: 'child1',
          date: any(named: 'date'),
        )).thenAnswer((_) async => todayLogs);
  }

  group('LoadDashboardDataUseCase', () {
    test('returns DashboardData with correct totalMinutesToday', () async {
      final logs = [
        _makeLog(appName: 'TikTok', durationMinutes: 30),
        _makeLog(appName: 'YouTube', durationMinutes: 45),
      ];

      when(() => mockUsageRepository.getUsageLogs(
            childUid: any(named: 'childUid'),
            date: any(named: 'date'),
          )).thenAnswer((_) async => <UsageLog>[]);

      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      when(() => mockUsageRepository.getUsageLogs(
            childUid: 'child1',
            date: dateStr,
          )).thenAnswer((_) async => logs);

      final result = await useCase.execute(familyId: 'fam1', childUid: 'child1');

      expect(result.totalMinutesToday, 75);
    });

    test('returns DashboardData with correct usageByApp', () async {
      final logs = [
        _makeLog(appName: 'TikTok', durationMinutes: 30),
        _makeLog(appName: 'TikTok', durationMinutes: 20),
        _makeLog(appName: 'YouTube', durationMinutes: 45),
      ];

      when(() => mockUsageRepository.getUsageLogs(
            childUid: any(named: 'childUid'),
            date: any(named: 'date'),
          )).thenAnswer((_) async => <UsageLog>[]);

      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      when(() => mockUsageRepository.getUsageLogs(
            childUid: 'child1',
            date: dateStr,
          )).thenAnswer((_) async => logs);

      final result = await useCase.execute(familyId: 'fam1', childUid: 'child1');

      expect(result.usageByApp, {'TikTok': 50, 'YouTube': 45});
    });

    test('returns DashboardData with dailyTotals for 7 days', () async {
      when(() => mockUsageRepository.getUsageLogs(
            childUid: any(named: 'childUid'),
            date: any(named: 'date'),
          )).thenAnswer((_) async => <UsageLog>[]);

      final result = await useCase.execute(familyId: 'fam1', childUid: 'child1');

      expect(result.dailyTotals.length, 7);
    });

    test('returns DashboardData with empty data when no logs', () async {
      when(() => mockUsageRepository.getUsageLogs(
            childUid: any(named: 'childUid'),
            date: any(named: 'date'),
          )).thenAnswer((_) async => <UsageLog>[]);

      final result = await useCase.execute(familyId: 'fam1', childUid: 'child1');

      expect(result.totalMinutesToday, 0);
      expect(result.usageByApp, isEmpty);
      expect(result.recentLogs, isEmpty);
    });

    test('returns recentLogs from today usage', () async {
      final logs = [_makeLog()];

      when(() => mockUsageRepository.getUsageLogs(
            childUid: any(named: 'childUid'),
            date: any(named: 'date'),
          )).thenAnswer((_) async => <UsageLog>[]);

      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      when(() => mockUsageRepository.getUsageLogs(
            childUid: 'child1',
            date: dateStr,
          )).thenAnswer((_) async => logs);

      final result = await useCase.execute(familyId: 'fam1', childUid: 'child1');

      expect(result.recentLogs, logs);
    });

    test('propagates exception from repository', () async {
      when(() => mockUsageRepository.getUsageLogs(
            childUid: any(named: 'childUid'),
            date: any(named: 'date'),
          )).thenThrow(Exception('Network error'));

      expect(
        () => useCase.execute(familyId: 'fam1', childUid: 'child1'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
