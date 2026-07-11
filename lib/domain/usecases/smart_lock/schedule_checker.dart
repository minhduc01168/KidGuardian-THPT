import 'package:kidguardian/data/models/schedule_model.dart';

class ScheduleChecker {
  static const _dayKeys = [
    'monday', 'tuesday', 'wednesday', 'thursday',
    'friday', 'saturday', 'sunday',
  ];

  String _getDayOfWeekKey(DateTime date) {
    return _dayKeys[date.weekday - 1];
  }

  int _timeToMinutes(int hour, int minute) {
    return hour * 60 + minute;
  }

  bool _isInTimeRange({
    required int currentMinutes,
    required int startMinutes,
    required int endMinutes,
  }) {
    if (endMinutes > startMinutes) {
      // Same-day schedule (e.g., 18:00-21:00)
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else if (endMinutes < startMinutes) {
      // Overnight schedule (e.g., 21:00-06:00)
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    } else {
      // start == end, no valid range
      return false;
    }
  }

  bool _isScheduleActiveOnDay(ScheduleModel schedule, DateTime dateTime) {
    // For overnight schedules, we need to check if the previous day is enabled
    // when current time is before end time
    final currentDay = _getDayOfWeekKey(dateTime);
    final currentMinutes = _timeToMinutes(dateTime.hour, dateTime.minute);
    final startMinutes = _timeToMinutes(schedule.startHour, schedule.startMinute);
    final endMinutes = _timeToMinutes(schedule.endHour, schedule.endMinute);

    final isOvernight = endMinutes < startMinutes;

    if (isOvernight && currentMinutes < endMinutes) {
      // We're in the early morning part of an overnight schedule
      // Check if previous day is enabled
      final previousDayIndex = (dateTime.weekday - 2 + 7) % 7;
      final previousDay = _dayKeys[previousDayIndex];
      return schedule.days[previousDay] ?? false;
    }

    return schedule.days[currentDay] ?? false;
  }

  /// Returns true if current time falls within any active schedule
  bool isInBlockedPeriod(List<ScheduleModel> schedules, DateTime now) {
    return getActiveSchedule(schedules, now) != null;
  }

  /// Returns the first active schedule, or null if none blocks
  ScheduleModel? getActiveSchedule(List<ScheduleModel> schedules, DateTime now) {
    final currentMinutes = _timeToMinutes(now.hour, now.minute);

    for (final schedule in schedules) {
      if (!schedule.isEnabled) continue;

      if (!_isScheduleActiveOnDay(schedule, now)) continue;

      final startMinutes = _timeToMinutes(schedule.startHour, schedule.startMinute);
      final endMinutes = _timeToMinutes(schedule.endHour, schedule.endMinute);

      if (_isInTimeRange(
        currentMinutes: currentMinutes,
        startMinutes: startMinutes,
        endMinutes: endMinutes,
      )) {
        return schedule;
      }
    }

    return null;
  }

  /// Returns the end time of the schedule relative to the given DateTime
  DateTime getScheduleEndTime(ScheduleModel schedule, DateTime now) {
    final currentMinutes = _timeToMinutes(now.hour, now.minute);
    final startMinutes = _timeToMinutes(schedule.startHour, schedule.startMinute);
    final endMinutes = _timeToMinutes(schedule.endHour, schedule.endMinute);

    final isOvernight = endMinutes < startMinutes;

    if (isOvernight) {
      if (currentMinutes >= startMinutes) {
        // Before midnight, end time is tomorrow
        return DateTime(now.year, now.month, now.day + 1,
            schedule.endHour, schedule.endMinute);
      } else {
        // After midnight, end time is today
        return DateTime(now.year, now.month, now.day,
            schedule.endHour, schedule.endMinute);
      }
    } else {
      // Same-day schedule
      return DateTime(now.year, now.month, now.day,
          schedule.endHour, schedule.endMinute);
    }
  }
}
