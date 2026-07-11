import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {}

class ThemeModeChanged extends SettingsEvent {
  final ThemeMode themeMode;

  const ThemeModeChanged(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

class LocaleChanged extends SettingsEvent {
  final Locale locale;

  const LocaleChanged(this.locale);

  @override
  List<Object?> get props => [locale];
}

class NotificationsToggled extends SettingsEvent {
  final bool enabled;

  const NotificationsToggled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class AlertSoundsToggled extends SettingsEvent {
  final bool enabled;

  const AlertSoundsToggled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}
