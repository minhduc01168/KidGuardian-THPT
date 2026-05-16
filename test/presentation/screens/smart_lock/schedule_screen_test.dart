import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/data/repositories/smart_lock_repository.dart';
import 'package:kidguardian/data/models/schedule_model.dart';
import 'package:kidguardian/presentation/screens/smart_lock/schedule_screen.dart';

class MockSmartLockRepository extends Mock implements SmartLockRepository {}

void main() {
  late MockSmartLockRepository mockRepository;

  setUp(() {
    mockRepository = MockSmartLockRepository();
    registerFallbackValue(const ScheduleModel(
      id: '',
      name: '',
      type: 'blocked',
      startHour: 0,
      startMinute: 0,
      endHour: 0,
      endMinute: 0,
      days: {},
    ));
  });

  Widget buildTestWidget({List<ScheduleModel>? schedules}) {
    when(() => mockRepository.getSchedules(any(), any()))
        .thenAnswer((_) async => schedules ?? []);
    when(() => mockRepository.deleteSchedule(any(), any(), any()))
        .thenAnswer((_) async {});
    when(() => mockRepository.saveSchedule(any(), any(), any()))
        .thenAnswer((_) async {});

    return MaterialApp(
      home: ScheduleScreen(
        familyId: 'family1',
        childId: 'child1',
        repository: mockRepository,
      ),
    );
  }

  group('ScheduleScreen', () {
    testWidgets('should show empty state when no schedules', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Chưa có lịch trình nào'), findsOneWidget);
      expect(find.text('Thêm lịch trình'), findsOneWidget);
    });

    testWidgets('should show FAB to add schedule', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('should show schedule list when schedules exist', (tester) async {
      final schedules = [
        ScheduleModel(
          id: 'schedule1',
          name: 'Giờ ngủ',
          type: 'blocked',
          startHour: 21,
          startMinute: 0,
          endHour: 6,
          endMinute: 0,
          days: const {
            'monday': true,
            'tuesday': true,
            'wednesday': true,
            'thursday': true,
            'friday': true,
            'saturday': true,
            'sunday': true,
          },
          isEnabled: true,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(schedules: schedules));
      await tester.pumpAndSettle();

      expect(find.text('Giờ ngủ'), findsOneWidget);
      expect(find.text('21:00 - 06:00'), findsOneWidget);
    });

    testWidgets('should show app bar with correct title', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Cài đặt lịch trình'), findsOneWidget);
    });
  });
}
