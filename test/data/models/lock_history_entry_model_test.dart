import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/data/models/lock_history_entry_model.dart';

void main() {
  group('LockHistoryEntryModel', () {
    test('fromJson creates model with all fields', () {
      final json = {
        'id': 'entry1',
        'appPackageName': 'com.tiktok',
        'appName': 'TikTok',
        'reason': 'time_limit',
        'scheduleName': null,
        'lockedAt': '2026-05-16T10:00:00.000',
        'unlockedAt': '2026-05-16T11:00:00.000',
        'durationMinutes': 60,
      };

      final model = LockHistoryEntryModel.fromJson(json);

      expect(model.id, 'entry1');
      expect(model.appPackageName, 'com.tiktok');
      expect(model.appName, 'TikTok');
      expect(model.reason, 'time_limit');
      expect(model.scheduleName, isNull);
      expect(model.lockedAt, isNotNull);
      expect(model.unlockedAt, isNotNull);
      expect(model.durationMinutes, 60);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'lockedAt': '2026-05-16T10:00:00.000',
      };

      final model = LockHistoryEntryModel.fromJson(json);

      expect(model.id, '');
      expect(model.appPackageName, '');
      expect(model.appName, '');
      expect(model.reason, 'time_limit');
      expect(model.scheduleName, isNull);
      expect(model.unlockedAt, isNull);
      expect(model.durationMinutes, isNull);
    });

    test('fromJson handles DateTime objects', () {
      final now = DateTime.now();
      final json = {
        'lockedAt': now,
        'unlockedAt': now.add(const Duration(hours: 1)),
      };

      final model = LockHistoryEntryModel.fromJson(json);
      expect(model.lockedAt, now);
      expect(model.unlockedAt, isNotNull);
    });

    test('fromJson handles num types flexibly', () {
      final json = {
        'lockedAt': '2026-05-16T10:00:00.000',
        'durationMinutes': 60.5,
      };

      final model = LockHistoryEntryModel.fromJson(json);
      expect(model.durationMinutes, 60);
    });

    test('toJson serializes all fields', () {
      final model = LockHistoryEntryModel(
        id: 'entry1',
        appPackageName: 'com.tiktok',
        appName: 'TikTok',
        reason: 'schedule',
        scheduleName: 'Giờ ngủ',
        lockedAt: DateTime(2026, 5, 16, 10),
        unlockedAt: DateTime(2026, 5, 16, 11),
        durationMinutes: 60,
      );

      final json = model.toJson();

      expect(json['id'], 'entry1');
      expect(json['appPackageName'], 'com.tiktok');
      expect(json['appName'], 'TikTok');
      expect(json['reason'], 'schedule');
      expect(json['scheduleName'], 'Giờ ngủ');
      expect(json['durationMinutes'], 60);
    });

    test('copyWith creates new instance with updated fields', () {
      final model = LockHistoryEntryModel(
        id: 'entry1',
        appPackageName: 'com.tiktok',
        appName: 'TikTok',
        reason: 'time_limit',
        lockedAt: DateTime(2026, 5, 16, 10),
      );

      final updated = model.copyWith(
        unlockedAt: DateTime(2026, 5, 16, 11),
        durationMinutes: 60,
      );

      expect(updated.id, 'entry1');
      expect(updated.unlockedAt, isNotNull);
      expect(updated.durationMinutes, 60);
    });

    test('equality works correctly', () {
      final now = DateTime.now();
      final model1 = LockHistoryEntryModel(
        id: 'entry1',
        appPackageName: 'com.tiktok',
        appName: 'TikTok',
        reason: 'time_limit',
        lockedAt: now,
      );
      final model2 = LockHistoryEntryModel(
        id: 'entry1',
        appPackageName: 'com.tiktok',
        appName: 'TikTok',
        reason: 'time_limit',
        lockedAt: now,
      );
      expect(model1, model2);
    });
  });
}
