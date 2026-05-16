import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateRangeSelector extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final Function(DateTime, DateTime) onDateRangeChanged;

  const DateRangeSelector({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onDateRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final startStr = DateFormat('dd/MM/yyyy').format(startDate);
    final endStr = DateFormat('dd/MM/yyyy').format(endDate);

    return InkWell(
      onTap: () => _showDateRangePicker(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today,
                size: 18, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              '$startStr - $endStr',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: startDate,
        end: endDate,
      ),
      locale: const Locale('vi', 'VN'),
      helpText: 'Chọn khoảng thời gian',
      cancelText: 'Hủy',
      confirmText: 'Xác nhận',
    );

    if (picked != null) {
      onDateRangeChanged(picked.start, picked.end);
    }
  }
}
