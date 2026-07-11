import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_bloc.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_event.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_state.dart';
import 'package:kidguardian/data/models/smart_lock_settings_model.dart';
import 'package:kidguardian/presentation/screens/smart_lock/lock_history_screen.dart';
import 'package:kidguardian/presentation/widgets/smart_lock/notification_preferences_section.dart';

class SmartLockSettingsScreen extends StatefulWidget {
  final String familyId;
  final String childId;
  final String childName;

  const SmartLockSettingsScreen({
    super.key,
    required this.familyId,
    required this.childId,
    required this.childName,
  });

  @override
  State<SmartLockSettingsScreen> createState() =>
      _SmartLockSettingsScreenState();
}

class _SmartLockSettingsScreenState extends State<SmartLockSettingsScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<SmartLockBloc>()
        .add(LoadSmartLockSettings(widget.familyId, widget.childId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt Smart Lock'),
      ),
      body: BlocConsumer<SmartLockBloc, SmartLockState>(
        listener: (context, state) {
          if (state is SmartLockActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is SmartLockError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        buildWhen: (previous, current) {
          return current is SmartLockSettingsLoaded ||
              current is SmartLockLoading;
        },
        builder: (context, state) {
          if (state is SmartLockLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SmartLockSettingsLoaded) {
            return _buildSettings(context, state.settings);
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildSettings(BuildContext context, SmartLockSettingsModel settings) {
    return ListView(
      children: [
        _buildSectionHeader('Bật/tắt Smart Lock'),
        SwitchListTile(
          title: const Text('Bật Smart Lock'),
          subtitle: Text(
            settings.isEnabled
                ? 'Smart Lock đang được bật'
                : 'Smart Lock đang được tắt',
          ),
          value: settings.isEnabled,
          onChanged: (value) {
            if (!value) {
              _showDisableConfirmation(context, settings);
            } else {
              _saveSettings(context, settings.copyWith(isEnabled: true));
            }
          },
        ),
        const Divider(),
        _buildSectionHeader('Giới hạn thời gian mặc định'),
        ListTile(
          title: const Text('Thời gian mặc định'),
          subtitle: Text('${settings.defaultTimeLimitMinutes} phút'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showTimeLimitPicker(context, settings),
        ),
        const Divider(),
        _buildSectionHeader('Tuỳ chọn thông báo'),
        NotificationPreferencesSection(
          settings: settings,
          onSave: (updatedSettings) => _saveSettings(context, updatedSettings),
        ),
        const Divider(),
        _buildSectionHeader('Lịch sử khoá'),
        ListTile(
          title: const Text('Xem lịch sử khoá'),
          subtitle: const Text('Danh sách các lần khoá ứng dụng gần đây'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LockHistoryScreen(
                  familyId: widget.familyId,
                  childId: widget.childId,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showDisableConfirmation(
    BuildContext context,
    SmartLockSettingsModel settings,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tắt Smart Lock?'),
        content: const Text(
          'Khi tắt Smart Lock, tất cả giới hạn thời gian và lịch trình sẽ tạm thời không được áp dụng. Bạn có chắc chắn muốn tắt?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _saveSettings(context, settings.copyWith(isEnabled: false));
            },
            child: const Text('Tắt', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showTimeLimitPicker(
    BuildContext context,
    SmartLockSettingsModel settings,
  ) {
    int selectedMinutes = settings.defaultTimeLimitMinutes;

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Chọn giới hạn thời gian mặc định',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$selectedMinutes phút',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: selectedMinutes.toDouble(),
                    min: 15,
                    max: 240,
                    divisions: 15,
                    label: '$selectedMinutes phút',
                    onChanged: (value) {
                      setModalState(() {
                        selectedMinutes = (value / 15).round() * 15;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Huỷ'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _saveSettings(
                            context,
                            settings.copyWith(
                              defaultTimeLimitMinutes: selectedMinutes,
                            ),
                          );
                        },
                        child: const Text('Lưu'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _saveSettings(
    BuildContext context,
    SmartLockSettingsModel settings,
  ) {
    context.read<SmartLockBloc>().add(
          SaveSmartLockSettings(widget.familyId, widget.childId, settings),
        );
  }
}
