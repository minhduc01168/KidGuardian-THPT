import 'package:flutter/material.dart';
import '../utils/usage_statistics_helper.dart';

class PeakUsageCard extends StatelessWidget {
  final List<int> peakHours;
  final String peakDay;
  final int totalMinutes;

  const PeakUsageCard({
    super.key,
    required this.peakHours,
    required this.peakDay,
    required this.totalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thống kê nhanh',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              context,
              icon: Icons.access_time,
              label: 'Tổng thời gian sử dụng',
              value: UsageStatisticsHelper.formatDuration(totalMinutes),
            ),
            const Divider(),
            if (peakHours.isNotEmpty) ...[
              _buildStatRow(
                context,
                icon: Icons.trending_up,
                label: 'Giờ cao điểm',
                value: peakHours.map((h) => '${h}h').join(', '),
              ),
              const Divider(),
            ],
            if (peakDay.isNotEmpty)
              _buildStatRow(
                context,
                icon: Icons.calendar_today,
                label: 'Ngày sử dụng nhiều nhất',
                value: peakDay,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
