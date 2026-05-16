import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WeeklyUsageChart extends StatelessWidget {
  final Map<String, int> weeklyUsage;

  const WeeklyUsageChart({super.key, required this.weeklyUsage});

  @override
  Widget build(BuildContext context) {
    if (weeklyUsage.isEmpty) {
      return const Center(
        child: Text('Không có dữ liệu'),
      );
    }

    final dayOrder = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final orderedEntries = dayOrder
        .where((day) => weeklyUsage.containsKey(day))
        .map((day) => MapEntry(day, weeklyUsage[day] ?? 0))
        .toList();

    final maxY = orderedEntries
        .fold<int>(0, (max, e) => e.value > max ? e.value : max)
        .toDouble();

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final day = orderedEntries[group.x].key;
                return BarTooltipItem(
                  '$day\n${rod.toY.toInt()} phút',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < orderedEntries.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(orderedEntries[index].key,
                          style: const TextStyle(fontSize: 12)),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}p',
                      style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(
            show: true,
            drawVerticalLine: false,
          ),
          barGroups: List.generate(orderedEntries.length, (index) {
            final minutes = orderedEntries[index].value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: minutes.toDouble(),
                  color: minutes > 0
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                  width: 24,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
