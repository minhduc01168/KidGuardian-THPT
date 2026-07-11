import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final Locale locale;
  final bool notificationsEnabled;
  final bool alertSoundsEnabled;
  final bool isLoading;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('vi'),
    this.notificationsEnabled = true,
    this.alertSoundsEnabled = true,
    this.isLoading = true,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? notificationsEnabled,
    bool? alertSoundsEnabled,
    bool? isLoading,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      alertSoundsEnabled: alertSoundsEnabled ?? this.alertSoundsEnabled,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        locale,
        notificationsEnabled,
        alertSoundsEnabled,
        isLoading,
      ];
}
