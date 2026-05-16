import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/data/models/schedule_model.dart';
import 'package:kidguardian/domain/usecases/smart_lock/schedule_checker.dart';

void main() {
  late ScheduleChecker checker;

  setUp(() {
    checker = ScheduleChecker();
  });

  ScheduleModel _createSchedule({
    String id = 'schedule1',
    String name = 'Giờ ngủ',
    String type = 'blocked',
    int startHour = 21,
    int startMinute = 0,
    int endHour = 6,
    int endMinute = 0,
    Map<String, bool>? days,
    bool isEnabled = true,
  }) {
    return ScheduleModel(
      id: id,
      name: name,
      type: type,
      startHour: startHour,
      startMinute: startMinute,
      endHour: endHour,
      endMinute: endMinute,
      days: days ??
          {
            'monday': true,
            'tuesday': true,
            'wednesday': true,
            'thursday': true,
            'friday': true,
            'saturday': true,
            'sunday': true,
          },
      isEnabled: isEnabled,
    );
  }

  group('ScheduleChecker', () {
    group('isInBlockedPeriod', () {
      test('should return false when no schedules', () {
        final now = DateTime(2024, 1, 15, 22, 0); // Monday 22:00
        expect(checker.isInBlockedPeriod([], now), false);
      });

      test('should return false when schedule is disabled', () {
        final now = DateTime(2024, 1, 15, 22, 0); // Monday 22:00
        final schedules = [_createSchedule(isEnabled: false)];
        expect(checker.isInBlockedPeriod(schedules, now), false);
      });

      test('should return true when current time is within same-day schedule', () {
        // Monday 19:00, schedule 18:00-21:00
        final now = DateTime(2024, 1, 15, 19, 0);
        final schedules = [
          _createSchedule(startHour: 18, startMinute: 0, endHour: 21, endMinute: 0),
        ];
        expect(checker.isInBlockedPeriod(schedules, now), true);
      });

      test('should return false when current time is outside same-day schedule', () {
        // Monday 22:00, schedule 18:00-21:00
        final now = DateTime(2024, 1, 15, 22, 0);
        final schedules = [
          _createSchedule(startHour: 18, startMinute: 0, endHour: 21, endMinute: 0),
        ];
        expect(checker.isInBlockedPeriod(schedules, now), false);
      });

      test('should return true at exact start time', () {
        // Monday 21:00, schedule 21:00-06:00
        final now = DateTime(2024, 1, 15, 21, 0);
        final schedules = [
          _createSchedule(startHour: 21, startMinute: 0, endHour: 6, endMinute: 0),
        ];
        expect(checker.isInBlockedPeriod(schedules, now), true);
      });

      test('should return false at exact end time', () {
        // Monday 06:00, schedule 21:00-06:00
        final now = DateTime(2024, 1, 15, 6, 0);
        final schedules = [
          _createSchedule(startHour: 21, startMinute: 0, endHour: 6, endMinute: 0),
        ];
        expect(checker.isInBlockedPeriod(schedules, now), false);
      });

      test('should handle overnight schedule - before midnight', () {
        // Monday 23:00, schedule 21:00-06:00
        final now = DateTime(2024, 1, 15, 23, 0);
        final schedules = [
          _createSchedule(startHour: 21, startMinute: 0, endHour: 6, endMinute: 0),
        ];
        expect(checker.isInBlockedPeriod(schedules, now), true);
      });

      test('should handle overnight schedule - after midnight', () {
        // Tuesday 03:00, schedule 21:00-06:00 (Monday is enabled)
        final now = DateTime(2024, 1, 16, 3, 0);
        final schedules = [
          _createSchedule(startHour: 21, startMinute: 0, endHour: 6, endMinute: 0),
        ];
        expect(checker.isInBlockedPeriod(schedules, now), true);
      });

      test('should return false when day is not in schedule', () {
        // Monday 22:00, schedule only on Tuesday
        final now = DateTime(2024, 1, 15, 22, 0); // Monday
        final schedules = [
          _createSchedule(
            days: {
              'monday': false,
              'tuesday': true,
              'wednesday': false,
              'thursday': false,
              'friday': false,
              'saturday': false,
              'sunday': false,
            },
          ),
        ];
        expect(checker.isInBlockedPeriod(schedules, now), false);
      });

      test('should return true when day is in schedule', () {
        // Monday 22:00, schedule on Monday
        final now = DateTime(2024, 1, 15, 22, 0); // Monday
        final schedules = [
          _createSchedule(
            days: {
              'monday': true,
              'tuesday': false,
              'wednesday': false,
              'thursday': false,
              'friday': false,
              'saturday': false,
              'sunday': false,
            },
          ),
        ];
        expect(checker.isInBlockedPeriod(schedules, now), true);
      });

      test('should check multiple schedules and return true if any blocks', () {
        // Monday 19:00
        final now = DateTime(2024, 1, 15, 19, 0);
        final schedules = [
          _createSchedule(
            id: 'schedule1',
            startHour: 10,
            startMinute: 0,
            endHour: 12,
            endMinute: 0,
          ),
          _createSchedule(
            id: 'schedule2',
            startHour: 18,
            startMinute: 0,
            endHour: 21,
            endMinute: 0,
          ),
        ];
        expect(checker.isInBlockedPeriod(schedules, now), true);
      });

      test('should return false when no schedule blocks', () {
        // Monday 15:00
        final now = DateTime(2024, 1, 15, 15, 0);
        final schedules = [
          _createSchedule(
            id: 'schedule1',
            startHour: 10,
            startMinute: 0,
            endHour: 12,
            endMinute: 0,
          ),
          _createSchedule(
            id: 'schedule2',
            startHour: 18,
            startMinute: 0,
            endHour: 21,
            endMinute: 0,
          ),
        ];
        expect(checker.isInBlockedPeriod(schedules, now), false);
      });

      test('should handle schedule with minutes', () {
        // Monday 18:30, schedule 18:15-20:45
        final now = DateTime(2024, 1, 15, 18, 30);
        final schedules = [
          _createSchedule(startHour: 18, startMinute: 15, endHour: 20, endMinute: 45),
        ];
        expect(checker.isInBlockedPeriod(schedules, now), true);
      });

      test('should handle overnight schedule with minutes', () {
        // Monday 21:30, schedule 21:15-06:45
        final now = DateTime(2024, 1, 15, 21, 30);
        final schedules = [
          _createSchedule(startHour: 21, startMinute: 15, endHour: 6, endMinute: 45),
        ];
        expect(checker.isInBlockedPeriod(schedules, now), true);
      });

      test('should handle Sunday to Monday overnight', () {
        // Monday 02:00, schedule enabled on Sunday 22:00-06:00
        final now = DateTime(2024, 1, 15, 2, 0); // Monday
        final schedules = [
          _createSchedule(
            startHour: 22,
            startMinute: 0,
            endHour: 6,
            endMinute: 0,
            days: {
              'monday': false,
              'tuesday': false,
              'wednesday': false,
              'thursday': false,
              'friday': false,
              'saturday': false,
              'sunday': true,
            },
          ),
        ];
        expect(checker.isInBlockedPeriod(schedules, now), true);
      });
    });

    group('getActiveSchedule', () {
      test('should return null when no schedules block', () {
        final now = DateTime(2024, 1, 15, 15, 0);
        final schedules = [
          _createSchedule(startHour: 18, startMinute: 0, endHour: 21, endMinute: 0),
        ];
        expect(checker.getActiveSchedule(schedules, now), null);
      });

      test('should return the active schedule', () {
        final now = DateTime(2024, 1, 15, 19, 0);
        final schedule = _createSchedule(
          startHour: 18,
          startMinute: 0,
          endHour: 21,
          endMinute: 0,
        );
        final schedules = [schedule];
        expect(checker.getActiveSchedule(schedules, now), schedule);
      });

      test('should return first active schedule when multiple block', () {
        final now = DateTime(2024, 1, 15, 19, 0);
        final schedule1 = _createSchedule(
          id: 'schedule1',
          startHour: 10,
          startMinute: 0,
          endHour: 12,
          endMinute: 0,
        );
        final schedule2 = _createSchedule(
          id: 'schedule2',
          startHour: 18,
          startMinute: 0,
          endHour: 21,
          endMinute: 0,
        );
        final schedules = [schedule1, schedule2];
        expect(checker.getActiveSchedule(schedules, now), schedule2);
      });
    });

    group('getScheduleEndTime', () {
      test('should return end time on same day for same-day schedule', () {
        final schedule = _createSchedule(
          startHour: 18,
          startMinute: 0,
          endHour: 21,
          endMinute: 0,
        );
        final now = DateTime(2024, 1, 15, 19, 0); // Monday 19:00
        final endTime = checker.getScheduleEndTime(schedule, now);

        expect(endTime, DateTime(2024, 1, 15, 21, 0));
      });

      test('should return end time on next day for overnight schedule', () {
        final schedule = _createSchedule(
          startHour: 21,
          startMinute: 0,
          endHour: 6,
          endMinute: 0,
        );
        final now = DateTime(2024, 1, 15, 22, 0); // Monday 22:00
        final endTime = checker.getScheduleEndTime(schedule, now);

        expect(endTime, DateTime(2024, 1, 16, 6, 0));
      });

      test('should return end time on same day when after midnight', () {
        final schedule = _createSchedule(
          startHour: 21,
          startMinute: 0,
          endHour: 6,
          endMinute: 0,
        );
        final now = DateTime(2024, 1, 16, 3, 0); // Tuesday 03:00
        final endTime = checker.getScheduleEndTime(schedule, now);

        expect(endTime, DateTime(2024, 1, 16, 6, 0));
      });
    });
  });
}
