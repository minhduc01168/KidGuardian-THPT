import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../domain/entities/usage_log.dart';
import '../../../../domain/repositories/usage_repository.dart';

class AppUsageDetailScreen extends StatefulWidget {
  final String childUid;
  final String appName;
  final int totalMinutes;

  const AppUsageDetailScreen({
    super.key,
    required this.childUid,
    required this.appName,
    required this.totalMinutes,
  });

  @override
  State<AppUsageDetailScreen> createState() => _AppUsageDetailScreenState();
}

class _AppUsageDetailScreenState extends State<AppUsageDetailScreen> {
  List<UsageLog> _logs = [];
  Map<String, int> _dailyUsage = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final usageRepo = context.read<UsageRepository>();
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final startDate =
        '${weekAgo.year}-${weekAgo.month.toString().padLeft(2, '0')}-${weekAgo.day.toString().padLeft(2, '0')}';
    final endDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final allLogs = await usageRepo.getUsageByDateRange(
      widget.childUid,
      startDate,
      endDate,
    );

    final appLogs =
        allLogs.where((log) => log.appName == widget.appName).toList();

    final Map<String, int> dailyUsage = {};
    for (final log in appLogs) {
      dailyUsage[log.date] = (dailyUsage[log.date] ?? 0) + log.durationMinutes;
    }

    if (mounted) {
      setState(() {
        _logs = appLogs;
        _dailyUsage = dailyUsage;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColor = AppUtils.getAppColor(widget.appName);
    final hours = widget.totalMinutes ~/ 60;
    final minutes = widget.totalMinutes % 60;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appName),
        backgroundColor: appColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [appColor, appColor.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          AppUtils.getAppIcon(widget.appName),
                          size: 48,
                          color: Colors.white,
                        ),
                        SizedBox(height: 16),
                        Text(
                          widget.appName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          hours > 0
                              ? '$hours giờ $minutes phút hôm nay'
                              : '$minutes phút hôm nay',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Weekly chart
                  Text(
                    'Biểu đồ 7 ngày',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        height: 200,
                        child: _buildWeeklyChart(appColor),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Statistics
                  Text(
                    'Thống kê',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Trung bình/ngày',
                          value: _dailyUsage.isNotEmpty
                              ? '${(_dailyUsage.values.fold(0, (sum, val) => sum + val) / _dailyUsage.length).round()} phút'
                              : '0 phút',
                          icon: Icons.calculate,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Ngày sử dụng',
                          value: '${_dailyUsage.length} ngày',
                          icon: Icons.calendar_today,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Nhiều nhất',
                          value: _dailyUsage.isNotEmpty
                              ? '${_dailyUsage.values.reduce((a, b) => a > b ? a : b)} phút'
                              : '0 phút',
                          icon: Icons.trending_up,
                          color: AppColors.warning,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Tổng tuần',
                          value: '${widget.totalMinutes} phút',
                          icon: Icons.summarize,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Recent sessions
                  Text(
                    'Phiên sử dụng gần đây',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  if (_logs.isEmpty)
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Chưa có dữ liệu',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._logs.take(10).map((log) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: appColor.withOpacity(0.1),
                              child: Icon(
                                AppUtils.getAppIcon(widget.appName),
                                color: appColor,
                              ),
                            ),
                            title: Text(
                              '${log.startTime.hour}:${log.startTime.minute.toString().padLeft(2, '0')} - ${log.endTime.hour}:${log.endTime.minute.toString().padLeft(2, '0')}',
                            ),
                            subtitle: Text(log.date),
                            trailing: Text(
                              '${log.durationMinutes} phút',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: appColor,
                              ),
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }

  Widget _buildWeeklyChart(Color appColor) {
    if (_dailyUsage.isEmpty) {
      return Center(
        child: Text(
          'Chưa có dữ liệu',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final sortedEntries = _dailyUsage.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final spots = sortedEntries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value.toDouble());
    }).toList();

    return BarChart(
      BarChartData(
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
        barGroups: spots.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.y,
                color: appColor,
                width: 24,
                borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final entry = sortedEntries[group.x];
              return BarTooltipItem(
                '${entry.key}\n${rod.toY.toInt()} phút',
                TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
