import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/data/models/smart_lock_settings_model.dart';

void main() {
  group('SmartLockSettingsModel', () {
    test('fromJson creates model with all fields', () {
      final json = {
        'isEnabled': false,
        'defaultTimeLimitMinutes': 90,
        'notifyOnTimeRequest': false,
        'notifyOnAppBlocked': true,
        'notifyOnLimitReached': false,
        'notifyOnScheduleViolation': true,
        'quietHoursEnabled': true,
        'quietHoursStart': 23,
        'quietHoursEnd': 6,
        'notificationSound': 'gentle',
        'updatedAt': '2026-05-16T10:00:00.000',
      };

      final model = SmartLockSettingsModel.fromJson(json);

      expect(model.isEnabled, false);
      expect(model.defaultTimeLimitMinutes, 90);
      expect(model.notifyOnTimeRequest, false);
      expect(model.notifyOnAppBlocked, true);
      expect(model.notifyOnLimitReached, false);
      expect(model.notifyOnScheduleViolation, true);
      expect(model.quietHoursEnabled, true);
      expect(model.quietHoursStart, 23);
      expect(model.quietHoursEnd, 6);
      expect(model.notificationSound, 'gentle');
      expect(model.updatedAt, isNotNull);
    });

    test('fromJson uses defaults for missing fields', () {
      final json = <String, dynamic>{};
      final model = SmartLockSettingsModel.fromJson(json);

      expect(model.isEnabled, true);
      expect(model.defaultTimeLimitMinutes, 60);
      expect(model.notifyOnTimeRequest, true);
      expect(model.notifyOnAppBlocked, true);
      expect(model.notifyOnLimitReached, true);
      expect(model.notifyOnScheduleViolation, true);
      expect(model.quietHoursEnabled, false);
      expect(model.quietHoursStart, 22);
      expect(model.quietHoursEnd, 7);
      expect(model.notificationSound, 'default');
      expect(model.updatedAt, isNull);
    });

    test('fromJson handles num types flexibly', () {
      final json = {
        'defaultTimeLimitMinutes': 90.0,
      };
      final model = SmartLockSettingsModel.fromJson(json);
      expect(model.defaultTimeLimitMinutes, 90);
    });

    test('toJson serializes all fields', () {
      const model = SmartLockSettingsModel(
        isEnabled: false,
        defaultTimeLimitMinutes: 120,
        notifyOnTimeRequest: false,
        notifyOnAppBlocked: false,
        notifyOnLimitReached: false,
        notifyOnScheduleViolation: false,
        quietHoursEnabled: true,
        quietHoursStart: 23,
        quietHoursEnd: 6,
        notificationSound: 'urgent',
      );

      final json = model.toJson();

      expect(json['isEnabled'], false);
      expect(json['defaultTimeLimitMinutes'], 120);
      expect(json['notifyOnTimeRequest'], false);
      expect(json['notifyOnAppBlocked'], false);
      expect(json['notifyOnLimitReached'], false);
      expect(json['notifyOnScheduleViolation'], false);
      expect(json['quietHoursEnabled'], true);
      expect(json['quietHoursStart'], 23);
      expect(json['quietHoursEnd'], 6);
      expect(json['notificationSound'], 'urgent');
    });

    test('copyWith creates new instance with updated fields', () {
      const model = SmartLockSettingsModel();
      final updated = model.copyWith(
        isEnabled: false,
        defaultTimeLimitMinutes: 120,
        quietHoursEnabled: true,
        quietHoursStart: 23,
      );

      expect(updated.isEnabled, false);
      expect(updated.defaultTimeLimitMinutes, 120);
      expect(updated.notifyOnTimeRequest, true);
      expect(updated.quietHoursEnabled, true);
      expect(updated.quietHoursStart, 23);
    });

    test('default constructor has correct defaults', () {
      const model = SmartLockSettingsModel();
      expect(model.isEnabled, true);
      expect(model.defaultTimeLimitMinutes, 60);
      expect(model.notifyOnTimeRequest, true);
      expect(model.notifyOnAppBlocked, true);
      expect(model.notifyOnLimitReached, true);
      expect(model.notifyOnScheduleViolation, true);
      expect(model.quietHoursEnabled, false);
      expect(model.quietHoursStart, 22);
      expect(model.quietHoursEnd, 7);
      expect(model.notificationSound, 'default');
      expect(model.updatedAt, isNull);
    });

    test('equality works correctly', () {
      const model1 = SmartLockSettingsModel();
      const model2 = SmartLockSettingsModel();
      expect(model1, model2);
    });

    test('equality differs when fields differ', () {
      const model1 = SmartLockSettingsModel();
      const model2 = SmartLockSettingsModel(isEnabled: false);
      expect(model1, isNot(model2));
    });
  });
}
