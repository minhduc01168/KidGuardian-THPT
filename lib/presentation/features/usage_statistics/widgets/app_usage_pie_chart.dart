import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AppUsagePieChart extends StatelessWidget {
  final Map<String, int> usageByApp;

  const AppUsagePieChart({super.key, required this.usageByApp});

  static const List<Color> _colors = [
    Color(0xFF2196F3),
    Color(0xFFF44336),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFF5722),
    Color(0xFF795548),
  ];

  @override
  Widget build(BuildContext context) {
    if (usageByApp.isEmpty) {
      return const Center(
        child: Text('Không có dữ liệu'),
      );
    }

    final total = usageByApp.values.fold<int>(0, (sum, v) => sum + v);
    final sortedEntries = usageByApp.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SizedBox(
      height: 250,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: List.generate(sortedEntries.length, (index) {
                  final entry = sortedEntries[index];
                  final percentage =
                      total > 0 ? (entry.value / total * 100) : 0.0;
                  return PieChartSectionData(
                    color: _colors[index % _colors.length],
                    value: entry.value.toDouble(),
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(sortedEntries.length, (index) {
              final entry = sortedEntries[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _colors[index % _colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 100,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
