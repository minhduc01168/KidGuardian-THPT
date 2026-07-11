import 'package:flutter/material.dart';
import 'package:kidguardian/data/models/lock_history_entry_model.dart';
import 'package:intl/intl.dart';

class LockHistoryCard extends StatelessWidget {
  final LockHistoryEntryModel entry;

  const LockHistoryCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.appName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getReasonText(),
                    style: TextStyle(
                      color: _getReasonColor(),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getTimeText(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getReasonColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getReasonIcon(),
        color: _getReasonColor(),
        size: 24,
      ),
    );
  }

  String _getReasonText() {
    switch (entry.reason) {
      case 'time_limit':
        return 'Đã hết giới hạn thời gian';
      case 'schedule':
        return 'Đang trong ${entry.scheduleName ?? "lịch trình"}';
      case 'manual':
        return 'Khoá thủ công';
      default:
        return 'Đã bị khoá';
    }
  }

  Color _getReasonColor() {
    switch (entry.reason) {
      case 'time_limit':
        return Colors.orange;
      case 'schedule':
        return Colors.purple;
      case 'manual':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getReasonIcon() {
    switch (entry.reason) {
      case 'time_limit':
        return Icons.timer_off;
      case 'schedule':
        return Icons.schedule;
      case 'manual':
        return Icons.lock;
      default:
        return Icons.block;
    }
  }

  String _getTimeText() {
    final lockedTime = DateFormat('HH:mm - dd/MM/yyyy').format(entry.lockedAt);
    if (entry.unlockedAt != null) {
      final unlockedTime =
          DateFormat('HH:mm').format(entry.unlockedAt!);
      return 'Khoá lúc $lockedTime · Mở lúc $unlockedTime';
    }
    return 'Khoá lúc $lockedTime';
  }
}
