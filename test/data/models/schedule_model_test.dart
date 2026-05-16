import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/data/models/schedule_model.dart';

void main() {
  group('ScheduleModel', () {
    const tScheduleModel = ScheduleModel(
      id: 'schedule1',
      name: 'Giờ ngủ',
      type: 'blocked',
      startHour: 21,
      startMinute: 0,
      endHour: 6,
      endMinute: 0,
      days: {
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

    test('should return a valid model from JSON', () {
      final Map<String, dynamic> jsonMap = {
        'id': 'schedule1',
        'name': 'Giờ ngủ',
        'type': 'blocked',
        'startHour': 21,
        'startMinute': 0,
        'endHour': 6,
        'endMinute': 0,
        'days': {
          'monday': true,
          'tuesday': true,
          'wednesday': true,
          'thursday': true,
          'friday': true,
          'saturday': true,
          'sunday': true,
        },
        'isEnabled': true,
      };

      final result = ScheduleModel.fromJson(jsonMap);

      expect(result, tScheduleModel);
    });

    test('should handle num types flexibly in fromJson', () {
      final Map<String, dynamic> jsonMap = {
        'id': 'schedule1',
        'name': 'Giờ ngủ',
        'type': 'blocked',
        'startHour': 21.0,
        'startMinute': 0.0,
        'endHour': 6.0,
        'endMinute': 0.0,
        'days': {
          'monday': true,
          'tuesday': true,
        },
        'isEnabled': true,
      };

      final result = ScheduleModel.fromJson(jsonMap);

      expect(result.startHour, 21);
      expect(result.startMinute, 0);
      expect(result.endHour, 6);
      expect(result.endMinute, 0);
    });

    test('should return a JSON map containing proper data', () {
      final result = tScheduleModel.toJson();

      final expectedMap = {
        'id': 'schedule1',
        'name': 'Giờ ngủ',
        'type': 'blocked',
        'startHour': 21,
        'startMinute': 0,
        'endHour': 6,
        'endMinute': 0,
        'days': {
          'monday': true,
          'tuesday': true,
          'wednesday': true,
          'thursday': true,
          'friday': true,
          'saturday': true,
          'sunday': true,
        },
        'isEnabled': true,
      };
      expect(result, expectedMap);
    });

    test('copyWith should return a new object with updated values', () {
      final result = tScheduleModel.copyWith(
        name: 'Giờ học bài',
        type: 'homework',
        startHour: 18,
        endHour: 21,
        isEnabled: false,
      );

      expect(result.name, 'Giờ học bài');
      expect(result.type, 'homework');
      expect(result.startHour, 18);
      expect(result.endHour, 21);
      expect(result.isEnabled, false);
      expect(result.id, tScheduleModel.id);
      expect(result.days, tScheduleModel.days);
    });

    test('copyWith should keep original values when no changes', () {
      final result = tScheduleModel.copyWith();

      expect(result, tScheduleModel);
    });

    test('should handle overnight schedule (endHour < startHour)', () {
      const overnightSchedule = ScheduleModel(
        id: 'schedule1',
        name: 'Giờ ngủ',
        type: 'blocked',
        startHour: 21,
        startMinute: 0,
        endHour: 6,
        endMinute: 0,
        days: {'monday': true},
        isEnabled: true,
      );

      expect(overnightSchedule.startHour, 21);
      expect(overnightSchedule.endHour, 6);
    });

    test('should handle same-day schedule (endHour > startHour)', () {
      const sameDaySchedule = ScheduleModel(
        id: 'schedule1',
        name: 'Giờ học bài',
        type: 'homework',
        startHour: 18,
        startMinute: 0,
        endHour: 21,
        endMinute: 0,
        days: {'monday': true},
        isEnabled: true,
      );

      expect(sameDaySchedule.startHour, 18);
      expect(sameDaySchedule.endHour, 21);
    });

    test('should handle empty days map', () {
      const emptyDaysSchedule = ScheduleModel(
        id: 'schedule1',
        name: 'Test',
        type: 'blocked',
        startHour: 10,
        startMinute: 0,
        endHour: 12,
        endMinute: 0,
        days: {},
        isEnabled: true,
      );

      expect(emptyDaysSchedule.days, isEmpty);
    });

    test('should handle disabled schedule', () {
      const disabledSchedule = ScheduleModel(
        id: 'schedule1',
        name: 'Test',
        type: 'blocked',
        startHour: 10,
        startMinute: 0,
        endHour: 12,
        endMinute: 0,
        days: {'monday': true},
        isEnabled: false,
      );

      expect(disabledSchedule.isEnabled, false);
    });

    test('fromJson should handle missing optional fields with defaults', () {
      final Map<String, dynamic> jsonMap = {
        'id': 'schedule1',
        'name': 'Test',
        'type': 'blocked',
        'startHour': 10,
        'startMinute': 0,
        'endHour': 12,
        'endMinute': 0,
      };

      final result = ScheduleModel.fromJson(jsonMap);

      expect(result.days, isEmpty);
      expect(result.isEnabled, true);
    });

    test('fromJson should handle missing id with empty string', () {
      final Map<String, dynamic> jsonMap = {
        'name': 'Test',
        'type': 'blocked',
        'startHour': 10,
        'startMinute': 0,
        'endHour': 12,
        'endMinute': 0,
      };

      final result = ScheduleModel.fromJson(jsonMap);

      expect(result.id, '');
    });

    test('props should include all fields', () {
      expect(tScheduleModel.props, [
        'schedule1',
        'Giờ ngủ',
        'blocked',
        21,
        0,
        6,
        0,
        {
          'monday': true,
          'tuesday': true,
          'wednesday': true,
          'thursday': true,
          'friday': true,
          'saturday': true,
          'sunday': true,
        },
        true,
      ]);
    });
  });
}
