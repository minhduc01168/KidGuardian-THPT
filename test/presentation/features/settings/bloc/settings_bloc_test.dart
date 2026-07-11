import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/repositories/settings_repository.dart';
import 'package:kidguardian/presentation/features/settings/bloc/settings_bloc.dart';
import 'package:kidguardian/presentation/features/settings/bloc/settings_event.dart';
import 'package:kidguardian/presentation/features/settings/bloc/settings_state.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late SettingsBloc bloc;
  late MockSettingsRepository mockSettingsRepository;

  setUpAll(() {
    registerFallbackValue(ThemeMode.system);
    registerFallbackValue(const Locale('vi'));
  });

  setUp(() {
    mockSettingsRepository = MockSettingsRepository();
    bloc = SettingsBloc(settingsRepository: mockSettingsRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('SettingsBloc', () {
    test('initial state has default values', () {
      expect(bloc.state.themeMode, ThemeMode.system);
      expect(bloc.state.locale, const Locale('vi'));
      expect(bloc.state.notificationsEnabled, true);
      expect(bloc.state.alertSoundsEnabled, true);
      expect(bloc.state.isLoading, true);
    });

    group('LoadSettings', () {
      blocTest<SettingsBloc, SettingsState>(
        'emits state with loaded settings from repository',
        build: () {
          when(() => mockSettingsRepository.getThemeMode())
              .thenAnswer((_) async => ThemeMode.dark);
          when(() => mockSettingsRepository.getLocale())
              .thenAnswer((_) async => const Locale('en'));
          when(() => mockSettingsRepository.getNotificationsEnabled())
              .thenAnswer((_) async => false);
          when(() => mockSettingsRepository.getAlertSoundsEnabled())
              .thenAnswer((_) async => false);
          return bloc;
        },
        act: (bloc) => bloc.add(LoadSettings()),
        expect: () => [
          isA<SettingsState>()
              .having((s) => s.themeMode, 'themeMode', ThemeMode.dark)
              .having((s) => s.locale, 'locale', const Locale('en'))
              .having((s) => s.notificationsEnabled, 'notificationsEnabled', false)
              .having((s) => s.alertSoundsEnabled, 'alertSoundsEnabled', false)
              .having((s) => s.isLoading, 'isLoading', false),
        ],
      );

      blocTest<SettingsBloc, SettingsState>(
        'loads partial settings correctly',
        build: () {
          when(() => mockSettingsRepository.getThemeMode())
              .thenAnswer((_) async => ThemeMode.light);
          when(() => mockSettingsRepository.getLocale())
              .thenAnswer((_) async => const Locale('vi'));
          when(() => mockSettingsRepository.getNotificationsEnabled())
              .thenAnswer((_) async => true);
          when(() => mockSettingsRepository.getAlertSoundsEnabled())
              .thenAnswer((_) async => true);
          return bloc;
        },
        act: (bloc) => bloc.add(LoadSettings()),
        expect: () => [
          isA<SettingsState>()
              .having((s) => s.themeMode, 'themeMode', ThemeMode.light)
              .having((s) => s.notificationsEnabled, 'notificationsEnabled', true)
              .having((s) => s.alertSoundsEnabled, 'alertSoundsEnabled', true),
        ],
      );
    });

    group('ThemeModeChanged', () {
      blocTest<SettingsBloc, SettingsState>(
        'updates theme mode and persists to repository',
        build: () {
          when(() => mockSettingsRepository.setThemeMode(any()))
              .thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(const ThemeModeChanged(ThemeMode.dark)),
        expect: () => [
          isA<SettingsState>().having(
            (s) => s.themeMode,
            'themeMode',
            ThemeMode.dark,
          ),
        ],
        verify: (_) {
          verify(() => mockSettingsRepository.setThemeMode(ThemeMode.dark))
              .called(1);
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'changes from dark to light',
        build: () {
          when(() => mockSettingsRepository.setThemeMode(any()))
              .thenAnswer((_) async {});
          return bloc;
        },
        seed: () => const SettingsState(
          themeMode: ThemeMode.dark,
          isLoading: false,
        ),
        act: (bloc) => bloc.add(const ThemeModeChanged(ThemeMode.light)),
        expect: () => [
          isA<SettingsState>().having(
            (s) => s.themeMode,
            'themeMode',
            ThemeMode.light,
          ),
        ],
      );
    });

    group('LocaleChanged', () {
      blocTest<SettingsBloc, SettingsState>(
        'updates locale and persists to repository',
        build: () {
          when(() => mockSettingsRepository.setLocale(any()))
              .thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(const LocaleChanged(Locale('en'))),
        expect: () => [
          isA<SettingsState>().having(
            (s) => s.locale,
            'locale',
            const Locale('en'),
          ),
        ],
        verify: (_) {
          verify(() => mockSettingsRepository.setLocale(const Locale('en')))
              .called(1);
        },
      );
    });

    group('NotificationsToggled', () {
      blocTest<SettingsBloc, SettingsState>(
        'enables notifications',
        build: () {
          when(() => mockSettingsRepository.setNotificationsEnabled(any()))
              .thenAnswer((_) async {});
          return bloc;
        },
        seed: () => const SettingsState(
          notificationsEnabled: false,
          isLoading: false,
        ),
        act: (bloc) => bloc.add(const NotificationsToggled(true)),
        expect: () => [
          isA<SettingsState>().having(
            (s) => s.notificationsEnabled,
            'notificationsEnabled',
            true,
          ),
        ],
        verify: (_) {
          verify(() => mockSettingsRepository.setNotificationsEnabled(true))
              .called(1);
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'disables notifications',
        build: () {
          when(() => mockSettingsRepository.setNotificationsEnabled(any()))
              .thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(const NotificationsToggled(false)),
        expect: () => [
          isA<SettingsState>().having(
            (s) => s.notificationsEnabled,
            'notificationsEnabled',
            false,
          ),
        ],
        verify: (_) {
          verify(() => mockSettingsRepository.setNotificationsEnabled(false))
              .called(1);
        },
      );
    });

    group('AlertSoundsToggled', () {
      blocTest<SettingsBloc, SettingsState>(
        'enables alert sounds',
        build: () {
          when(() => mockSettingsRepository.setAlertSoundsEnabled(any()))
              .thenAnswer((_) async {});
          return bloc;
        },
        seed: () => const SettingsState(
          alertSoundsEnabled: false,
          isLoading: false,
        ),
        act: (bloc) => bloc.add(const AlertSoundsToggled(true)),
        expect: () => [
          isA<SettingsState>().having(
            (s) => s.alertSoundsEnabled,
            'alertSoundsEnabled',
            true,
          ),
        ],
        verify: (_) {
          verify(() => mockSettingsRepository.setAlertSoundsEnabled(true))
              .called(1);
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'disables alert sounds',
        build: () {
          when(() => mockSettingsRepository.setAlertSoundsEnabled(any()))
              .thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(const AlertSoundsToggled(false)),
        expect: () => [
          isA<SettingsState>().having(
            (s) => s.alertSoundsEnabled,
            'alertSoundsEnabled',
            false,
          ),
        ],
        verify: (_) {
          verify(() => mockSettingsRepository.setAlertSoundsEnabled(false))
              .called(1);
        },
      );
    });
  });
}
