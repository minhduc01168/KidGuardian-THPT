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
        const Divider(),
        _buildQuietHoursSection(context),
        const Divider(),
        _buildSoundSection(context),
      ],
    );
  }

  Widget _buildQuietHoursSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Giờ yên lặng'),
          subtitle: const Text('Tắt thông báo trong khoảng thời gian này'),
          value: settings.quietHoursEnabled,
          onChanged: (value) {
            onSave(settings.copyWith(quietHoursEnabled: value));
          },
        ),
        if (settings.quietHoursEnabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTimePicker(
                    context,
                    label: 'Bắt đầu',
                    hour: settings.quietHoursStart,
                    onSelected: (hour) {
                      onSave(settings.copyWith(quietHoursStart: hour));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimePicker(
                    context,
                    label: 'Kết thúc',
                    hour: settings.quietHoursEnd,
                    onSelected: (hour) {
                      onSave(settings.copyWith(quietHoursEnd: hour));
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTimePicker(
    BuildContext context, {
    required String label,
    required int hour,
    required Function(int) onSelected,
  }) {
    return ListTile(
      title: Text(label),
      subtitle: Text('${hour.toString().padLeft(2, '0')}:00'),
      trailing: const Icon(Icons.access_time),
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: 0),
        );
        if (picked != null) {
          onSelected(picked.hour);
        }
      },
    );
  }

  Widget _buildSoundSection(BuildContext context) {
    final sounds = [
      {'id': 'default', 'name': 'Mặc định'},
      {'id': 'gentle', 'name': 'Nhẹ nhàng'},
      {'id': 'urgent', 'name': 'Khẩn cấp'},
      {'id': 'silent', 'name': 'Im lặng'},
    ];

    return ListTile(
      title: const Text('Âm thanh thông báo'),
      subtitle: Text(
        sounds.firstWhere(
          (s) => s['id'] == settings.notificationSound,
          orElse: () => sounds.first,
        )['name']!,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (ctx) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Chọn âm thanh thông báo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...sounds.map((sound) => RadioListTile<String>(
                        title: Text(sound['name']!),
                        value: sound['id']!,
                        groupValue: settings.notificationSound,
                        onChanged: (value) {
                          if (value != null) {
                            onSave(settings.copyWith(
                                notificationSound: value));
                            Navigator.pop(ctx);
                          }
                        },
                      )),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
