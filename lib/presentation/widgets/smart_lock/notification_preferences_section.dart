import 'package:flutter/material.dart';
import 'package:kidguardian/data/models/smart_lock_settings_model.dart';

class NotificationPreferencesSection extends StatelessWidget {
  final SmartLockSettingsModel settings;
  final Function(SmartLockSettingsModel) onSave;

  const NotificationPreferencesSection({
    super.key,
    required this.settings,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Yêu cầu thêm thời gian'),
          subtitle: const Text('Thông báo khi trẻ yêu cầu thêm thời gian'),
          value: settings.notifyOnTimeRequest,
          onChanged: (value) {
            onSave(settings.copyWith(notifyOnTimeRequest: value));
          },
        ),
        SwitchListTile(
          title: const Text('Khoá ứng dụng'),
          subtitle: const Text('Thông báo khi trẻ bị khoá ứng dụng'),
          value: settings.notifyOnAppBlocked,
          onChanged: (value) {
            onSave(settings.copyWith(notifyOnAppBlocked: value));
          },
        ),
        SwitchListTile(
          title: const Text('Hết giới hạn'),
          subtitle: const Text('Thông báo khi trẻ sử dụng hết giới hạn'),
          value: settings.notifyOnLimitReached,
          onChanged: (value) {
            onSave(settings.copyWith(notifyOnLimitReached: value));
          },
        ),
        SwitchListTile(
          title: const Text('Vi phạm lịch trình'),
          subtitle: const Text('Thông báo khi trẻ vi phạm lịch trình'),
          value: settings.notifyOnScheduleViolation,
          onChanged: (value) {
            onSave(settings.copyWith(notifyOnScheduleViolation: value));
          },
        ),
      ],
    );
  }
}
