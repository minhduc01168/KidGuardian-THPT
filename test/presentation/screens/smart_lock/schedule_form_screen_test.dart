import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/data/repositories/smart_lock_repository.dart';
import 'package:kidguardian/data/models/schedule_model.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_bloc.dart';
import 'package:kidguardian/presentation/screens/smart_lock/schedule_form_screen.dart';

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

  Widget buildTestWidget({ScheduleModel? existingSchedule}) {
    when(() => mockRepository.saveSchedule(any(), any(), any()))
        .thenAnswer((_) async {});

    return MaterialApp(
      home: BlocProvider<SmartLockBloc>(
        create: (_) => SmartLockBloc(repository: mockRepository),
        child: ScheduleFormScreen(
          familyId: 'family1',
          childId: 'child1',
          existingSchedule: existingSchedule,
        ),
      ),
    );
  }

  group('ScheduleFormScreen', () {
    testWidgets('should show form fields', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Tạo lịch trình'), findsOneWidget);
      expect(find.text('Tên lịch trình'), findsOneWidget);
      expect(find.text('Giờ bắt đầu'), findsOneWidget);
      expect(find.text('Giờ kết thúc'), findsOneWidget);
      expect(find.text('Ngày áp dụng'), findsOneWidget);
    });

    testWidgets('should show save button', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Lưu'), findsOneWidget);
    });

    testWidgets('should show template buttons', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Giờ ngủ'), findsOneWidget);
      expect(find.text('Giờ học bài'), findsOneWidget);
    });

    testWidgets('should populate form when editing existing schedule', (tester) async {
      final existingSchedule = ScheduleModel(
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
      );

      await tester.pumpWidget(buildTestWidget(existingSchedule: existingSchedule));
      await tester.pumpAndSettle();

      expect(find.text('Chỉnh sửa lịch trình'), findsOneWidget);
      expect(find.text('Giờ ngủ'), findsOneWidget);
    });
  });
}
