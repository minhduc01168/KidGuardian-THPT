import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidguardian/data/models/schedule_model.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_bloc.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_event.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_state.dart';
import 'package:kidguardian/presentation/widgets/smart_lock/time_range_picker.dart';
import 'package:kidguardian/presentation/widgets/smart_lock/day_selector.dart';

class ScheduleFormScreen extends StatefulWidget {
  final String familyId;
  final String childId;
  final ScheduleModel? existingSchedule;

  const ScheduleFormScreen({
    super.key,
    required this.familyId,
    required this.childId,
    this.existingSchedule,
  });

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  final _nameController = TextEditingController();
  int _startHour = 21;
  int _startMinute = 0;
  int _endHour = 6;
  int _endMinute = 0;
  String _type = 'blocked';
  bool _isEnabled = true;
  Map<String, bool> _days = {
    'monday': true,
    'tuesday': true,
    'wednesday': true,
    'thursday': true,
    'friday': true,
    'saturday': true,
    'sunday': true,
  };

  bool get _isEditing => widget.existingSchedule != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final schedule = widget.existingSchedule!;
      _nameController.text = schedule.name;
      _startHour = schedule.startHour;
      _startMinute = schedule.startMinute;
      _endHour = schedule.endHour;
      _endMinute = schedule.endMinute;
      _type = schedule.type;
      _isEnabled = schedule.isEnabled;
      _days = Map.from(schedule.days);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _applyTemplate(String name, String type, int sh, int sm, int eh, int em, Map<String, bool> days) {
    setState(() {
      _nameController.text = name;
      _type = type;
      _startHour = sh;
      _startMinute = sm;
      _endHour = eh;
      _endMinute = em;
      _days = days;
    });
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên lịch trình')),
      );
      return;
    }

    final hasSelectedDay = _days.values.any((v) => v);
    if (!hasSelectedDay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một ngày')),
      );
      return;
    }

    final schedule = ScheduleModel(
      id: widget.existingSchedule?.id ?? '',
      name: _nameController.text.trim(),
      type: _type,
      startHour: _startHour,
      startMinute: _startMinute,
      endHour: _endHour,
      endMinute: _endMinute,
      days: _days,
      isEnabled: _isEnabled,
    );

    context.read<SmartLockBloc>().add(
      SaveSchedule(widget.familyId, widget.childId, schedule),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa lịch trình' : 'Tạo lịch trình'),
      ),
      body: BlocListener<SmartLockBloc, SmartLockState>(
        listener: (context, state) {
          if (state is SmartLockActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.of(context).pop();
          } else if (state is SmartLockError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Templates
              if (!_isEditing) ...[
                const Text(
                  'Mẫu có sẵn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _applyTemplate(
                          'Giờ ngủ',
                          'blocked',
                          21, 0, 6, 0,
                          {
                            'monday': true,
                            'tuesday': true,
                            'wednesday': true,
                            'thursday': true,
                            'friday': true,
                            'saturday': true,
                            'sunday': true,
                          },
                        ),
                        icon: const Icon(Icons.bedtime),
                        label: const Text('Giờ ngủ'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _applyTemplate(
                          'Giờ học bài',
                          'homework',
                          18, 0, 21, 0,
                          {
                            'monday': true,
                            'tuesday': true,
                            'wednesday': true,
                            'thursday': true,
                            'friday': true,
                            'saturday': false,
                            'sunday': false,
                          },
                        ),
                        icon: const Icon(Icons.school),
                        label: const Text('Giờ học bài'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Name field
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên lịch trình',
                  hintText: 'Nhập tên lịch trình',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
              ),
              const SizedBox(height: 24),

              // Time range picker
              TimeRangePicker(
                startHour: _startHour,
                startMinute: _startMinute,
                endHour: _endHour,
                endMinute: _endMinute,
                onChanged: (sh, sm, eh, em) {
                  setState(() {
                    _startHour = sh;
                    _startMinute = sm;
                    _endHour = eh;
                    _endMinute = em;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Day selector
              DaySelector(
                selectedDays: _days,
                onChanged: (days) {
                  setState(() {
                    _days = days;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Enable/disable toggle
              SwitchListTile(
                title: const Text('Kích hoạt lịch trình'),
                subtitle: const Text('Tắt để tạm ngừng mà không xoá'),
                value: _isEnabled,
                onChanged: (value) {
                  setState(() {
                    _isEnabled = value;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Save button
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Lưu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
