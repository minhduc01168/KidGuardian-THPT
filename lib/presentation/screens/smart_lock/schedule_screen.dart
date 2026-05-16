import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidguardian/data/models/schedule_model.dart';
import 'package:kidguardian/data/repositories/smart_lock_repository.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_bloc.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_event.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_state.dart';

class ScheduleScreen extends StatelessWidget {
  final String familyId;
  final String childId;
  final SmartLockRepository? repository;

  const ScheduleScreen({
    super.key,
    required this.familyId,
    required this.childId,
    this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SmartLockBloc(
        repository: repository ?? SmartLockRepository(),
      )..add(LoadSchedules(familyId, childId)),
      child: _ScheduleView(familyId: familyId, childId: childId),
    );
  }
}

class _ScheduleView extends StatelessWidget {
  final String familyId;
  final String childId;

  const _ScheduleView({
    required this.familyId,
    required this.childId,
  });

  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _getDayLabel(String day) {
    const labels = {
      'monday': 'T2',
      'tuesday': 'T3',
      'wednesday': 'T4',
      'thursday': 'T5',
      'friday': 'T6',
      'saturday': 'T7',
      'sunday': 'CN',
    };
    return labels[day] ?? day;
  }

  String _getDaysSummary(Map<String, bool> days) {
    final activeDays = days.entries.where((e) => e.value).map((e) => _getDayLabel(e.key)).toList();
    if (activeDays.length == 7) return 'Hàng ngày';
    if (activeDays.isEmpty) return 'Không có ngày';
    return activeDays.join(', ');
  }

  void _confirmDelete(BuildContext context, ScheduleModel schedule) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá lịch trình'),
        content: Text('Bạn có chắc muốn xoá lịch trình "${schedule.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<SmartLockBloc>().add(
                DeleteSchedule(familyId, childId, schedule.id),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt lịch trình'),
      ),
      body: BlocConsumer<SmartLockBloc, SmartLockState>(
        listener: (context, state) {
          if (state is SmartLockActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is SmartLockError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        buildWhen: (previous, current) => current is! SmartLockActionSuccess,
        builder: (context, state) {
          if (state is SmartLockLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SchedulesLoaded) {
            if (state.schedules.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.schedule, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có lịch trình nào',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thêm lịch trình để chặn ứng dụng theo thời gian',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to ScheduleFormScreen
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm lịch trình'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.schedules.length,
              itemBuilder: (context, index) {
                final schedule = state.schedules[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: schedule.type == 'homework'
                          ? Colors.blue.shade100
                          : Colors.orange.shade100,
                      child: Icon(
                        schedule.type == 'homework' ? Icons.school : Icons.bedtime,
                        color: schedule.type == 'homework'
                            ? Colors.blue.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                    title: Text(
                      schedule.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${_formatTime(schedule.startHour, schedule.startMinute)} - ${_formatTime(schedule.endHour, schedule.endMinute)}',
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getDaysSummary(schedule.days),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: schedule.isEnabled,
                          onChanged: (value) {
                            final updated = schedule.copyWith(isEnabled: value);
                            context.read<SmartLockBloc>().add(
                              SaveSchedule(familyId, childId, updated),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _confirmDelete(context, schedule),
                        ),
                      ],
                    ),
                    onTap: () {
                      // TODO: Navigate to ScheduleFormScreen for editing
                    },
                  ),
                );
              },
            );
          }

          return const Center(child: Text('Đã xảy ra lỗi'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to ScheduleFormScreen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
