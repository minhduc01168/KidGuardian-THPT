import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HourlyUsageChart extends StatelessWidget {
  final Map<int, int> hourlyUsage;

  const HourlyUsageChart({super.key, required this.hourlyUsage});

  @override
  Widget build(BuildContext context) {
    if (hourlyUsage.isEmpty) {
      return const Center(
        child: Text('Không có dữ liệu'),
      );
    }

    final maxY = hourlyUsage.values
        .fold<int>(0, (max, v) => v > max ? v : max)
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
                return BarTooltipItem(
                  '${group.x.toInt()}h\n${rod.toY.toInt()} phút',
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
                  final hour = value.toInt();
                  if (hour % 3 == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('${hour}h',
                          style: const TextStyle(fontSize: 10)),
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
          barGroups: List.generate(24, (index) {
            final minutes = hourlyUsage[index] ?? 0;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: minutes.toDouble(),
                  color: minutes > 0
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                  width: 12,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
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
