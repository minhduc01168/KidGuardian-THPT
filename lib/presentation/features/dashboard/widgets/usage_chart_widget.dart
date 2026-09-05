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
    // BUG-C FIX: Kiểm tra cả appTotals và dailyTotals để đưa ra empty state đúng
    final bool hasAppData = widget.appTotals.isNotEmpty &&
        widget.appTotals.values.any((v) => v > 0);
    if (!hasAppData) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'Chưa có dữ liệu hôm nay',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              if (widget.dailyTotals.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Tổng tuần: ${widget.dailyTotals.values.fold(0, (a, b) => a + b)} phút',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final sortedEntries = widget.appTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = sortedEntries.take(5).toList();
    final total = widget.appTotals.values.fold(0, (sum, val) => sum + val);
    if (total == 0) {
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

    final roundedPercents = <String, int>{};
    int sumRounded = 0;
    String maxAppKey = '';
    int maxAppVal = -1;

    for (final entry in widget.appTotals.entries) {
      final val = entry.value;
      if (val > maxAppVal) {
        maxAppVal = val;
        maxAppKey = entry.key;
      }
      final rounded = total > 0 ? (val / total * 100).round() : 0;
      roundedPercents[entry.key] = rounded;
      sumRounded += rounded;
    }

    if (sumRounded > 0 && maxAppKey.isNotEmpty && sumRounded != 100) {
      final diff = 100 - sumRounded;
      roundedPercents[maxAppKey] = (roundedPercents[maxAppKey]! + diff).clamp(0, 100);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: PieChart(
              PieChartData(
                sections: widget.appTotals.entries.map((appEntry) {
                  final percent = roundedPercents[appEntry.key] ?? 0;
                  final color = AppUtils.getAppColor(appEntry.key);
                  return PieChartSectionData(
                    value: appEntry.value.toDouble() > 0 ? appEntry.value.toDouble() : 0.1,
                    showTitle: percent >= 5,
                    title: '${percent}%',
                    color: color,
                    radius: 45,
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: topEntries.map((entry) {
                final percent = (entry.value / total * 100).toStringAsFixed(0);
                final color = AppUtils.getAppColor(entry.key);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$percent% (${entry.value}p)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
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
                    Text(AppUtils.getAppName(entry.key)),
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
