import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/settings_repository.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;

  SettingsBloc({required SettingsRepository settingsRepository})
      : _settingsRepository = settingsRepository,
        super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<ThemeModeChanged>(_onThemeModeChanged);
    on<LocaleChanged>(_onLocaleChanged);
    on<NotificationsToggled>(_onNotificationsToggled);
    on<AlertSoundsToggled>(_onAlertSoundsToggled);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    final themeMode = await _settingsRepository.getThemeMode();
    final locale = await _settingsRepository.getLocale();
    final notificationsEnabled =
        await _settingsRepository.getNotificationsEnabled();
    final alertSoundsEnabled =
        await _settingsRepository.getAlertSoundsEnabled();

    emit(state.copyWith(
      themeMode: themeMode,
      locale: locale,
      notificationsEnabled: notificationsEnabled,
      alertSoundsEnabled: alertSoundsEnabled,
      isLoading: false,
    ));
  }

  Future<void> _onThemeModeChanged(
    ThemeModeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    await _settingsRepository.setThemeMode(event.themeMode);
    emit(state.copyWith(themeMode: event.themeMode));
  }

  Future<void> _onLocaleChanged(
    LocaleChanged event,
    Emitter<SettingsState> emit,
  ) async {
    await _settingsRepository.setLocale(event.locale);
    emit(state.copyWith(locale: event.locale));
  }

  Future<void> _onNotificationsToggled(
    NotificationsToggled event,
    Emitter<SettingsState> emit,
  ) async {
    await _settingsRepository.setNotificationsEnabled(event.enabled);
    emit(state.copyWith(notificationsEnabled: event.enabled));
  }

  Future<void> _onAlertSoundsToggled(
    AlertSoundsToggled event,
    Emitter<SettingsState> emit,
  ) async {
    await _settingsRepository.setAlertSoundsEnabled(event.enabled);
    emit(state.copyWith(alertSoundsEnabled: event.enabled));
  }
}
