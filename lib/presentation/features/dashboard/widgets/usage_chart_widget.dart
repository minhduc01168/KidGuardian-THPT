import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_utils.dart';

enum ChartView { daily, weekly }

class UsageChartWidget extends StatefulWidget {
  final Map<String, int> dailyTotals;
  final Map<String, int> appTotals;

  const UsageChartWidget({
    super.key,
    required this.dailyTotals,
    required this.appTotals,
  });

  @override
  State<UsageChartWidget> createState() => _UsageChartWidgetState();
}

class _UsageChartWidgetState extends State<UsageChartWidget> {
  ChartView _currentView = ChartView.daily;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Biểu đồ sử dụng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SegmentedButton<ChartView>(
                  segments: [
                    ButtonSegment(
                      value: ChartView.daily,
                      label: Text('Ngày'),
                    ),
                    ButtonSegment(
                      value: ChartView.weekly,
                      label: Text('Tuần'),
                    ),
                  ],
                  selected: {_currentView},
                  onSelectionChanged: (Set<ChartView> selected) {
                    setState(() {
                      _currentView = selected.first;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 24),
            if (_currentView == ChartView.daily)
              _buildDailyChart()
            else
              _buildWeeklyChart(),
            SizedBox(height: 24),
            _buildAppUsageBarChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChart() {
    if (widget.dailyTotals.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Chưa có dữ liệu',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final sortedEntries = widget.dailyTotals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final spots = sortedEntries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value.toDouble());
    }).toList();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 30,
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}p',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < sortedEntries.length) {
                    final date = sortedEntries[value.toInt()].key;
                    final parts = date.split('-');
                    return Text(
                      '${parts[2]}/${parts[1]}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    );
                  }
                  return Text('');
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.primary,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final entry = sortedEntries[spot.x.toInt()];
                  return LineTooltipItem(
                    '${entry.key}\n${spot.y.toInt()} phút',
                    TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    if (widget.dailyTotals.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Chưa có dữ liệu',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    // Group by week
    final Map<String, int> weeklyTotals = {};
    widget.dailyTotals.forEach((date, minutes) {
      final parts = date.split('-');
      final dateTime = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final weekStart = dateTime.subtract(Duration(days: dateTime.weekday - 1));
      final weekKey =
          '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
      weeklyTotals[weekKey] = (weeklyTotals[weekKey] ?? 0) + minutes;
    });

    final sortedEntries = weeklyTotals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final spots = sortedEntries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value.toDouble());
    }).toList();

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 60,
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}p',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < sortedEntries.length) {
                    final date = sortedEntries[value.toInt()].key;
                    final parts = date.split('-');
                    return Text(
                      'T${parts[2]}/${parts[1]}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    );
                  }
                  return Text('');
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: spots.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.y,
                  color: AppColors.primary,
                  width: 20,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final entry = sortedEntries[group.x];
                return BarTooltipItem(
                  'Tuần ${entry.key}\n${rod.toY.toInt()} phút',
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppUsageBarChart() {
    if (widget.appTotals.isEmpty) {
      return SizedBox.shrink();
    }

    final sortedEntries = widget.appTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxMinutes = sortedEntries.first.value.toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sử dụng theo ứng dụng',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        ...sortedEntries.map((entry) {
          final percent = maxMinutes > 0 ? entry.value / maxMinutes : 0.0;
          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text(
                      '${entry.value} phút',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percent,
                  backgroundColor: AppColors.divider.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getAppColor(entry.key),
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _getAppColor(String appName) {
    return AppUtils.getAppColor(appName);
  }
}
