import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/entities/weekly_report.dart';
import 'package:kidguardian/domain/repositories/report_repository.dart';
import 'package:kidguardian/presentation/features/report/bloc/report_bloc.dart';
import 'package:kidguardian/presentation/features/report/bloc/report_event.dart';
import 'package:kidguardian/presentation/features/report/bloc/report_state.dart';

class MockReportRepository extends Mock implements ReportRepository {}

void main() {
  late ReportBloc bloc;
  late MockReportRepository mockReportRepository;

  setUpAll(() {
    registerFallbackValue(WeeklyReport(
      reportId: '',
      childUid: '',
      familyId: '',
      weekStartDate: '',
      weekEndDate: '',
      totalMinutes: 0,
      previousWeekMinutes: 0,
      usageByApp: const {},
      previousWeekUsageByApp: const {},
      topApps: const [],
      percentChange: 0,
      generatedAt: DateTime(2000),
    ));
  });

  setUp(() {
    mockReportRepository = MockReportRepository();
    bloc = ReportBloc(reportRepository: mockReportRepository);
  });

  tearDown(() {
    bloc.close();
  });

  WeeklyReport makeReport({
    String reportId = 'report1',
    String childUid = 'child1',
    String familyId = 'fam1',
  }) {
    return WeeklyReport(
      reportId: reportId,
      childUid: childUid,
      familyId: familyId,
      weekStartDate: '2026-05-25',
      weekEndDate: '2026-05-31',
      totalMinutes: 300,
      previousWeekMinutes: 250,
      usageByApp: const {'TikTok': 120, 'YouTube': 90},
      previousWeekUsageByApp: const {'TikTok': 100, 'YouTube': 80},
      topApps: const ['TikTok', 'YouTube'],
      alertCount: 3,
      violationCount: 1,
      percentChange: 20.0,
      improvements: const ['Less TikTok usage'],
      concerns: const ['YouTube increased'],
      generatedAt: DateTime(2026, 5, 31),
    );
  }

  group('ReportBloc', () {
    test('initial state is ReportInitial', () {
      expect(bloc.state, isA<ReportInitial>());
    });

    group('GenerateWeeklyReport', () {
      blocTest<ReportBloc, ReportState>(
        'emits [ReportLoading, ReportGenerated] on success',
        build: () {
          when(() => mockReportRepository.generateWeeklyReport('child1', 'fam1'))
              .thenAnswer((_) async => makeReport());
          return bloc;
        },
        act: (bloc) => bloc.add(const GenerateWeeklyReport(
          childUid: 'child1',
          familyId: 'fam1',
        )),
        expect: () => [
          isA<ReportLoading>(),
          isA<ReportGenerated>()
              .having((s) => s.report.reportId, 'reportId', 'report1'),
        ],
      );

      blocTest<ReportBloc, ReportState>(
        'emits [ReportLoading, ReportError] on failure',
        build: () {
          when(() => mockReportRepository.generateWeeklyReport(any(), any()))
              .thenThrow(Exception('Generation failed'));
          return bloc;
        },
        act: (bloc) => bloc.add(const GenerateWeeklyReport(
          childUid: 'child1',
          familyId: 'fam1',
        )),
        expect: () => [
          isA<ReportLoading>(),
          isA<ReportError>().having(
            (e) => e.message,
            'message',
            'Generation failed',
          ),
        ],
      );
    });

    group('LoadReportHistory', () {
      blocTest<ReportBloc, ReportState>(
        'emits [ReportLoading, ReportHistoryLoaded] on success',
        build: () {
          when(() => mockReportRepository.getReportsByFamily('fam1'))
              .thenAnswer((_) async => [makeReport(), makeReport(reportId: 'report2')]);
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadReportHistory(familyId: 'fam1')),
        expect: () => [
          isA<ReportLoading>(),
          isA<ReportHistoryLoaded>()
              .having((s) => s.reports.length, 'reports length', 2),
        ],
      );

      blocTest<ReportBloc, ReportState>(
        'emits [ReportLoading, ReportHistoryLoaded] with empty list when no reports',
        build: () {
          when(() => mockReportRepository.getReportsByFamily('fam1'))
              .thenAnswer((_) async => []);
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadReportHistory(familyId: 'fam1')),
        expect: () => [
          isA<ReportLoading>(),
          isA<ReportHistoryLoaded>()
              .having((s) => s.reports, 'reports', isEmpty),
        ],
      );

      blocTest<ReportBloc, ReportState>(
        'emits [ReportLoading, ReportError] on failure',
        build: () {
          when(() => mockReportRepository.getReportsByFamily(any()))
              .thenThrow(Exception('Load failed'));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadReportHistory(familyId: 'fam1')),
        expect: () => [
          isA<ReportLoading>(),
          isA<ReportError>().having(
            (e) => e.message,
            'message',
            'Load failed',
          ),
        ],
      );
    });

    group('LoadLatestReport', () {
      blocTest<ReportBloc, ReportState>(
        'emits [ReportLoading, ReportLoaded] when report exists',
        build: () {
          when(() => mockReportRepository.getLatestReport('child1'))
              .thenAnswer((_) async => makeReport());
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadLatestReport(childUid: 'child1')),
        expect: () => [
          isA<ReportLoading>(),
          isA<ReportLoaded>()
              .having((s) => s.report.reportId, 'reportId', 'report1'),
        ],
      );

      blocTest<ReportBloc, ReportState>(
        'emits [ReportLoading, ReportError] when no report found',
        build: () {
          when(() => mockReportRepository.getLatestReport('child1'))
              .thenAnswer((_) async => null);
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadLatestReport(childUid: 'child1')),
        expect: () => [
          isA<ReportLoading>(),
          isA<ReportError>().having(
            (e) => e.message,
            'message',
            'Chưa có báo cáo',
          ),
        ],
      );

      blocTest<ReportBloc, ReportState>(
        'emits [ReportLoading, ReportError] on failure',
        build: () {
          when(() => mockReportRepository.getLatestReport(any()))
              .thenThrow(Exception('DB error'));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadLatestReport(childUid: 'child1')),
        expect: () => [
          isA<ReportLoading>(),
          isA<ReportError>().having(
            (e) => e.message,
            'message',
            'DB error',
          ),
        ],
      );
    });

    group('SendReportByEmail', () {
      blocTest<ReportBloc, ReportState>(
        'emits ReportEmailSent when email sent successfully',
        build: () {
          when(() => mockReportRepository.sendReportByEmail(
                recipientEmail: any(named: 'recipientEmail'),
                report: any(named: 'report'),
                childName: any(named: 'childName'),
              )).thenAnswer((_) async => true);
          return bloc;
        },
        act: (bloc) => bloc.add(SendReportByEmail(
          recipientEmail: 'parent@example.com',
          report: makeReport(),
          childName: 'Tom',
        )),
        expect: () => [
          isA<ReportEmailSent>(),
        ],
      );

      blocTest<ReportBloc, ReportState>(
        'emits ReportError when email sending returns false',
        build: () {
          when(() => mockReportRepository.sendReportByEmail(
                recipientEmail: any(named: 'recipientEmail'),
                report: any(named: 'report'),
                childName: any(named: 'childName'),
              )).thenAnswer((_) async => false);
          return bloc;
        },
        act: (bloc) => bloc.add(SendReportByEmail(
          recipientEmail: 'parent@example.com',
          report: makeReport(),
          childName: 'Tom',
        )),
        expect: () => [
          isA<ReportError>().having(
            (e) => e.message,
            'message',
            'Không thể gửi email',
          ),
        ],
      );

      blocTest<ReportBloc, ReportState>(
        'emits ReportError on exception',
        build: () {
          when(() => mockReportRepository.sendReportByEmail(
                recipientEmail: any(named: 'recipientEmail'),
                report: any(named: 'report'),
                childName: any(named: 'childName'),
              )).thenThrow(Exception('SMTP error'));
          return bloc;
        },
        act: (bloc) => bloc.add(SendReportByEmail(
          recipientEmail: 'parent@example.com',
          report: makeReport(),
          childName: 'Tom',
        )),
        expect: () => [
          isA<ReportError>().having(
            (e) => e.message,
            'message',
            'SMTP error',
          ),
        ],
      );
    });

    group('UpdateEmailPreference', () {
      blocTest<ReportBloc, ReportState>(
        'emits EmailPreferenceUpdated on success',
        build: () {
          when(() => mockReportRepository.updateEmailPreference(
                uid: any(named: 'uid'),
                enabled: any(named: 'enabled'),
              )).thenAnswer((_) async => true);
          return bloc;
        },
        act: (bloc) => bloc.add(const UpdateEmailPreference(
          uid: 'user1',
          enabled: true,
        )),
        expect: () => [
          isA<EmailPreferenceUpdated>()
              .having((s) => s.enabled, 'enabled', true),
        ],
      );

      blocTest<ReportBloc, ReportState>(
        'emits EmailPreferenceUpdated with false when disabled',
        build: () {
          when(() => mockReportRepository.updateEmailPreference(
                uid: any(named: 'uid'),
                enabled: any(named: 'enabled'),
              )).thenAnswer((_) async => true);
          return bloc;
        },
        act: (bloc) => bloc.add(const UpdateEmailPreference(
          uid: 'user1',
          enabled: false,
        )),
        expect: () => [
          isA<EmailPreferenceUpdated>()
              .having((s) => s.enabled, 'enabled', false),
        ],
      );

      blocTest<ReportBloc, ReportState>(
        'emits ReportError when update returns false',
        build: () {
          when(() => mockReportRepository.updateEmailPreference(
                uid: any(named: 'uid'),
                enabled: any(named: 'enabled'),
              )).thenAnswer((_) async => false);
          return bloc;
        },
        act: (bloc) => bloc.add(const UpdateEmailPreference(
          uid: 'user1',
          enabled: true,
        )),
        expect: () => [
          isA<ReportError>().having(
            (e) => e.message,
            'message',
            'Không thể cập nhật cài đặt',
          ),
        ],
      );

      blocTest<ReportBloc, ReportState>(
        'emits ReportError on exception',
        build: () {
          when(() => mockReportRepository.updateEmailPreference(
                uid: any(named: 'uid'),
                enabled: any(named: 'enabled'),
              )).thenThrow(Exception('DB error'));
          return bloc;
        },
        act: (bloc) => bloc.add(const UpdateEmailPreference(
          uid: 'user1',
          enabled: true,
        )),
        expect: () => [
          isA<ReportError>().having(
            (e) => e.message,
            'message',
            'DB error',
          ),
        ],
      );
    });

    group('LoadEmailPreference', () {
      blocTest<ReportBloc, ReportState>(
        'emits EmailPreferenceLoaded with true when preference is enabled',
        build: () {
          when(() => mockReportRepository.getEmailPreference('user1'))
              .thenAnswer((_) async => true);
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadEmailPreference(uid: 'user1')),
        expect: () => [
          isA<EmailPreferenceLoaded>()
              .having((s) => s.enabled, 'enabled', true),
        ],
      );

      blocTest<ReportBloc, ReportState>(
        'emits EmailPreferenceLoaded with false when preference is disabled',
        build: () {
          when(() => mockReportRepository.getEmailPreference('user1'))
              .thenAnswer((_) async => false);
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadEmailPreference(uid: 'user1')),
        expect: () => [
          isA<EmailPreferenceLoaded>()
              .having((s) => s.enabled, 'enabled', false),
        ],
      );

      blocTest<ReportBloc, ReportState>(
        'emits EmailPreferenceLoaded with false on exception',
        build: () {
          when(() => mockReportRepository.getEmailPreference(any()))
              .thenThrow(Exception('DB error'));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadEmailPreference(uid: 'user1')),
        expect: () => [
          isA<EmailPreferenceLoaded>()
              .having((s) => s.enabled, 'enabled', false),
        ],
      );
    });
  });
}
