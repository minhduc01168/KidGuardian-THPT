import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DailyUsageChart extends StatelessWidget {
  final Map<String, int> dailyUsage;

  const DailyUsageChart({super.key, required this.dailyUsage});

  @override
  Widget build(BuildContext context) {
    if (dailyUsage.isEmpty) {
      return const Center(
        child: Text('Không có dữ liệu'),
      );
    }

    final sortedEntries = dailyUsage.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final maxY = sortedEntries
        .fold<int>(0, (max, e) => e.value > max ? e.value : max)
        .toDouble();

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final date = sortedEntries[spot.x.toInt()].key;
                  return LineTooltipItem(
                    '$date\n${spot.y.toInt()} phút',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }).toList();
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
                  if (index >= 0 && index < sortedEntries.length) {
                    final date = sortedEntries[index].key;
                    try {
                      final parsed = DateTime.parse(date);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(DateFormat('dd/MM').format(parsed),
                            style: const TextStyle(fontSize: 10)),
                      );
                    } catch (_) {
                      return const SizedBox.shrink();
                    }
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
          minX: 0,
          maxX: (sortedEntries.length - 1).toDouble(),
          minY: 0,
          maxY: maxY * 1.2,
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(sortedEntries.length, (index) {
                return FlSpot(
                    index.toDouble(), sortedEntries[index].value.toDouble());
              }),
              isCurved: true,
              color: Theme.of(context).primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Theme.of(context).primaryColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
