import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidguardian/data/repositories/settings_repository_impl.dart';

void main() {
  late SettingsRepositoryImpl repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = SettingsRepositoryImpl();
  });

  group('SettingsRepositoryImpl', () {
    group('getThemeMode', () {
      test('should return system theme mode by default', () async {
        final result = await repository.getThemeMode();

        expect(result, ThemeMode.system);
      });

      test('should return dark theme mode when set', () async {
        SharedPreferences.setMockInitialValues({'settings_theme_mode': 'dark'});

        final result = await repository.getThemeMode();

        expect(result, ThemeMode.dark);
      });

      test('should return light theme mode when set', () async {
        SharedPreferences.setMockInitialValues({'settings_theme_mode': 'light'});

        final result = await repository.getThemeMode();

        expect(result, ThemeMode.light);
      });
    });

    group('setThemeMode', () {
      test('should save dark theme mode', () async {
        await repository.setThemeMode(ThemeMode.dark);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('settings_theme_mode'), 'dark');
      });

      test('should save light theme mode', () async {
        await repository.setThemeMode(ThemeMode.light);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('settings_theme_mode'), 'light');
      });

      test('should save system theme mode', () async {
        await repository.setThemeMode(ThemeMode.system);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('settings_theme_mode'), 'system');
      });
    });

    group('getLocale', () {
      test('should return Vietnamese locale by default', () async {
        final result = await repository.getLocale();

        expect(result, const Locale('vi'));
      });

      test('should return saved locale when set', () async {
        SharedPreferences.setMockInitialValues({'settings_locale': 'en'});

        final result = await repository.getLocale();

        expect(result, const Locale('en'));
      });
    });

    group('setLocale', () {
      test('should save locale language code', () async {
        await repository.setLocale(const Locale('en'));

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('settings_locale'), 'en');
      });

      test('should save Vietnamese locale', () async {
        await repository.setLocale(const Locale('vi'));

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('settings_locale'), 'vi');
      });
    });

    group('getNotificationsEnabled', () {
      test('should return true by default', () async {
        final result = await repository.getNotificationsEnabled();

        expect(result, isTrue);
      });

      test('should return false when disabled', () async {
        SharedPreferences.setMockInitialValues({'settings_notifications_enabled': false});

        final result = await repository.getNotificationsEnabled();

        expect(result, isFalse);
      });

      test('should return true when enabled', () async {
        SharedPreferences.setMockInitialValues({'settings_notifications_enabled': true});

        final result = await repository.getNotificationsEnabled();

        expect(result, isTrue);
      });
    });

    group('setNotificationsEnabled', () {
      test('should save notifications enabled state', () async {
        await repository.setNotificationsEnabled(false);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('settings_notifications_enabled'), isFalse);
      });

      test('should save notifications disabled state', () async {
        await repository.setNotificationsEnabled(true);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('settings_notifications_enabled'), isTrue);
      });
    });

    group('getAlertSoundsEnabled', () {
      test('should return true by default', () async {
        final result = await repository.getAlertSoundsEnabled();

        expect(result, isTrue);
      });

      test('should return false when disabled', () async {
        SharedPreferences.setMockInitialValues({'settings_alert_sounds_enabled': false});

        final result = await repository.getAlertSoundsEnabled();

        expect(result, isFalse);
      });

      test('should return true when enabled', () async {
        SharedPreferences.setMockInitialValues({'settings_alert_sounds_enabled': true});

        final result = await repository.getAlertSoundsEnabled();

        expect(result, isTrue);
      });
    });

    group('setAlertSoundsEnabled', () {
      test('should save alert sounds enabled state', () async {
        await repository.setAlertSoundsEnabled(false);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('settings_alert_sounds_enabled'), isFalse);
      });

      test('should save alert sounds disabled state', () async {
        await repository.setAlertSoundsEnabled(true);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('settings_alert_sounds_enabled'), isTrue);
      });
    });
  });
}
