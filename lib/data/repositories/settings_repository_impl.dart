import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const _keyThemeMode = 'settings_theme_mode';
  static const _keyLocale = 'settings_locale';
  static const _keyNotificationsEnabled = 'settings_notifications_enabled';
  static const _keyAlertSoundsEnabled = 'settings_alert_sounds_enabled';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<ThemeMode> getThemeMode() async {
    final prefs = await _getPrefs();
    final value = prefs.getString(_keyThemeMode);
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyThemeMode, mode.name);
  }

  @override
  Future<Locale> getLocale() async {
    final prefs = await _getPrefs();
    final code = prefs.getString(_keyLocale);
    if (code != null && code.isNotEmpty) {
      return Locale(code);
    }
    return const Locale('vi');
  }

  @override
  Future<void> setLocale(Locale locale) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyLocale, locale.languageCode);
  }

  @override
  Future<bool> getNotificationsEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  @override
  Future<bool> getAlertSoundsEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyAlertSoundsEnabled) ?? true;
  }

  @override
  Future<void> setAlertSoundsEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyAlertSoundsEnabled, enabled);
  }
}
