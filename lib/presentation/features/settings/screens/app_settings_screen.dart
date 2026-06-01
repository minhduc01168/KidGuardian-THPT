import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cài đặt ứng dụng'),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              _buildSectionHeader('Giao diện'),
              _buildThemeCard(context, state),
              SizedBox(height: 16),
              _buildSectionHeader('Ngôn ngữ'),
              _buildLanguageCard(context, state),
              SizedBox(height: 16),
              _buildSectionHeader('Thông báo'),
              _buildNotificationCard(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, SettingsState state) {
    return Card(
      child: Column(
        children: [
          RadioListTile<ThemeMode>(
            title: Row(
              children: [
                Icon(Icons.brightness_auto, color: AppColors.primary),
                SizedBox(width: 12),
                Text('Theo hệ thống'),
              ],
            ),
            value: ThemeMode.system,
            groupValue: state.themeMode,
            onChanged: (value) {
              if (value != null) {
                context.read<SettingsBloc>().add(ThemeModeChanged(value));
              }
            },
          ),
          Divider(height: 1),
          RadioListTile<ThemeMode>(
            title: Row(
              children: [
                Icon(Icons.light_mode, color: AppColors.warning),
                SizedBox(width: 12),
                Text('Sáng'),
              ],
            ),
            value: ThemeMode.light,
            groupValue: state.themeMode,
            onChanged: (value) {
              if (value != null) {
                context.read<SettingsBloc>().add(ThemeModeChanged(value));
              }
            },
          ),
          Divider(height: 1),
          RadioListTile<ThemeMode>(
            title: Row(
              children: [
                Icon(Icons.dark_mode, color: Colors.indigo),
                SizedBox(width: 12),
                Text('Tối'),
              ],
            ),
            value: ThemeMode.dark,
            groupValue: state.themeMode,
            onChanged: (value) {
              if (value != null) {
                context.read<SettingsBloc>().add(ThemeModeChanged(value));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(BuildContext context, SettingsState state) {
    return Card(
      child: Column(
        children: [
          RadioListTile<Locale>(
            title: Row(
              children: [
                Text('🇻🇳', style: TextStyle(fontSize: 20)),
                SizedBox(width: 12),
                Text('Tiếng Việt'),
              ],
            ),
            value: const Locale('vi'),
            groupValue: state.locale,
            onChanged: (value) {
              if (value != null) {
                context.read<SettingsBloc>().add(LocaleChanged(value));
              }
            },
          ),
          Divider(height: 1),
          RadioListTile<Locale>(
            title: Row(
              children: [
                Text('🇺🇸', style: TextStyle(fontSize: 20)),
                SizedBox(width: 12),
                Text('English'),
              ],
            ),
            value: const Locale('en'),
            groupValue: state.locale,
            onChanged: (value) {
              if (value != null) {
                context.read<SettingsBloc>().add(LocaleChanged(value));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, SettingsState state) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: Text('Bật thông báo'),
            subtitle: Text('Nhận thông báo từ ứng dụng'),
            value: state.notificationsEnabled,
            onChanged: (value) {
              context.read<SettingsBloc>().add(NotificationsToggled(value));
            },
            secondary: Icon(
              state.notificationsEnabled
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              color: state.notificationsEnabled
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ),
          Divider(height: 1),
          SwitchListTile(
            title: Text('Âm thanh cảnh báo'),
            subtitle: Text('Phát âm thanh khi có cảnh báo'),
            value: state.alertSoundsEnabled,
            onChanged: state.notificationsEnabled
                ? (value) {
                    context
                        .read<SettingsBloc>()
                        .add(AlertSoundsToggled(value));
                  }
                : null,
            secondary: Icon(
              state.alertSoundsEnabled ? Icons.volume_up : Icons.volume_off,
              color: state.alertSoundsEnabled
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
