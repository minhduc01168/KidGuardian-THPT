import 'package:flutter/material.dart';

abstract class SettingsRepository {
  Future<ThemeMode> getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);
  Future<Locale> getLocale();
  Future<void> setLocale(Locale locale);
  Future<bool> getNotificationsEnabled();
  Future<void> setNotificationsEnabled(bool enabled);
  Future<bool> getAlertSoundsEnabled();
  Future<void> setAlertSoundsEnabled(bool enabled);
}
