import 'package:flutter/material.dart';

class DaySelector extends StatelessWidget {
  final Map<String, bool> selectedDays;
  final ValueChanged<Map<String, bool>> onChanged;

  static const _days = [
    'monday', 'tuesday', 'wednesday', 'thursday',
    'friday', 'saturday', 'sunday',
  ];

  static const _dayLabels = {
    'monday': 'T2',
    'tuesday': 'T3',
    'wednesday': 'T4',
    'thursday': 'T5',
    'friday': 'T6',
    'saturday': 'T7',
    'sunday': 'CN',
  };

  const DaySelector({
    super.key,
    required this.selectedDays,
    required this.onChanged,
  });

  void _toggleDay(String day) {
    final updated = Map<String, bool>.from(selectedDays);
    updated[day] = !(updated[day] ?? false);
    onChanged(updated);
  }

  void _selectAll() {
    final updated = Map<String, bool>.from(selectedDays);
    for (final day in _days) {
      updated[day] = true;
    }
    onChanged(updated);
  }

  void _selectNone() {
    final updated = Map<String, bool>.from(selectedDays);
    for (final day in _days) {
      updated[day] = false;
    }
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _days.every((day) => selectedDays[day] == true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ngày áp dụng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: allSelected ? _selectNone : _selectAll,
              child: Text(allSelected ? 'Bỏ chọn' : 'Chọn tất cả'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _days.map((day) {
            final isSelected = selectedDays[day] ?? false;
            return ActionChip(
              label: Text(
                _dayLabels[day]!,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
              onPressed: () => _toggleDay(day),
            );
          }).toList(),
        ),
      ],
    );
  }
}
