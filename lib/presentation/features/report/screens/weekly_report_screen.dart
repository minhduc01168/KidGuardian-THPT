import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../domain/entities/weekly_report.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../features/auth/bloc/auth_state.dart';
import '../bloc/report_bloc.dart';
import '../bloc/report_event.dart';
import '../bloc/report_state.dart';

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user.familyId != null) {
      context.read<ReportBloc>().add(
            LoadReportHistory(familyId: authState.user.familyId!),
          );
    }
  }

  void _generateReport() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user.familyId != null) {
      context.read<ReportBloc>().add(
            GenerateWeeklyReport(
              childUid: authState.user.uid,
              familyId: authState.user.familyId!,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Báo cáo tuần'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: BlocBuilder<ReportBloc, ReportState>(
        builder: (context, state) {
          if (state is ReportLoading) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is ReportError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  SizedBox(height: 16),
                  Text(state.message),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadReports,
                    child: Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state is ReportHistoryLoaded) {
            return _buildReportList(state.reports);
          }

          if (state is ReportLoaded) {
            return _buildReportDetail(state.report);
          }

          if (state is ReportGenerated) {
            return _buildReportDetail(state.report);
          }

          return _buildEmptyState();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateReport,
        icon: Icon(Icons.add_chart),
        label: Text('Tạo báo cáo'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assessment,
            size: 80,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'Chưa có báo cáo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Nhấn nút để tạo báo cáo tuần đầu tiên',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportList(List<WeeklyReport> reports) {
    if (reports.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async => _loadReports(),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return _ReportCard(
            report: report,
            onTap: () => _showReportDetail(report),
          );
        },
      ),
    );
  }

  void _showReportDetail(WeeklyReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ReportDetailSheet(report: report),
    );
  }

  Widget _buildReportDetail(WeeklyReport report) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.assessment,
                  size: 48,
                  color: Colors.white,
                ),
                SizedBox(height: 16),
                Text(
                  'Báo cáo tuần',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${_formatDate(report.weekStartDate)} - ${_formatDate(report.weekEndDate)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Stats cards
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Tổng thời gian',
                  value: '${report.totalMinutes} phút',
                  icon: Icons.timer,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: 'So với tuần trước',
                  value: '${report.percentChange > 0 ? '+' : ''}${report.percentChange.toStringAsFixed(0)}%',
                  icon: report.percentChange > 0
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color: report.percentChange > 0
                      ? AppColors.error
                      : AppColors.success,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Comparison chart
          Text(
            'So sánh 2 tuần',
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
                child: _buildComparisonChart(report),
              ),
            ),
          ),
          SizedBox(height: 24),

          // Top apps
          if (report.topApps.isNotEmpty) ...[
            Text(
              'Ứng dụng nhiều nhất',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: report.topApps.asMap().entries.map((entry) {
                    final index = entry.key;
                    final app = entry.value;
                    final current = report.usageByApp[app] ?? 0;
                    final previous = report.previousWeekUsageByApp[app] ?? 0;
                    final change = previous > 0
                        ? ((current - previous) / previous * 100)
                        : 0;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            AppUtils.getAppColor(app).withOpacity(0.1),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppUtils.getAppColor(app),
                          ),
                        ),
                      ),
                      title: Text(app),
                      subtitle: Text('$current phút'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (previous > 0)
                            Icon(
                              change > 0
                                  ? Icons.arrow_upward
                                  : change < 0
                                      ? Icons.arrow_downward
                                      : Icons.remove,
                              size: 16,
                              color: change > 0
                                  ? AppColors.error
                                  : change < 0
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                            ),
                          SizedBox(width: 4),
                          Text(
                            previous > 0
                                ? '${change > 0 ? '+' : ''}${change.toStringAsFixed(0)}%'
                                : 'Mới',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: change > 0
                                  ? AppColors.error
                                  : change < 0
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
          SizedBox(height: 24),

          // Insights
          if (report.improvements.isNotEmpty) ...[
            Text(
              'Cải thiện',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
            SizedBox(height: 12),
            ...report.improvements.map((item) => Card(
                  color: AppColors.success.withOpacity(0.1),
                  child: ListTile(
                    leading: Icon(Icons.check_circle, color: AppColors.success),
                    title: Text(item),
                  ),
                )),
            SizedBox(height: 16),
          ],

          if (report.concerns.isNotEmpty) ...[
            Text(
              'Cần lưu ý',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.warning,
              ),
            ),
            SizedBox(height: 12),
            ...report.concerns.map((item) => Card(
                  color: AppColors.warning.withOpacity(0.1),
                  child: ListTile(
                    leading: Icon(Icons.warning, color: AppColors.warning),
                    title: Text(item),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonChart(WeeklyReport report) {
    final apps = report.topApps.take(5).toList();
    if (apps.isEmpty) {
      return Center(child: Text('Chưa có dữ liệu'));
    }

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
                if (value.toInt() < apps.length) {
                  return Text(
                    apps[value.toInt()],
                    style: TextStyle(
                      fontSize: 10,
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
        barGroups: apps.asMap().entries.map((entry) {
          final index = entry.key;
          final app = entry.value;
          final current = report.usageByApp[app]?.toDouble() ?? 0;
          final previous =
              report.previousWeekUsageByApp[app]?.toDouble() ?? 0;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: previous,
                color: AppColors.divider,
                width: 16,
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              BarChartRodData(
                toY: current,
                color: AppColors.primary,
                width: 16,
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final app = apps[group.x];
              final label = rodIndex == 0 ? 'Tuần trước' : 'Tuần này';
              return BarTooltipItem(
                '$app\n$label: ${rod.toY.toInt()} phút',
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

  String _formatDate(String date) {
    final parts = date.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}';
    }
    return date;
  }
}

class _ReportCard extends StatelessWidget {
  final WeeklyReport report;
  final VoidCallback onTap;

  const _ReportCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPositive = report.percentChange <= 0;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_formatDate(report.weekStartDate)} - ${_formatDate(report.weekEndDate)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isPositive ? AppColors.success : AppColors.error)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive
                              ? Icons.trending_down
                              : Icons.trending_up,
                          size: 16,
                          color:
                              isPositive ? AppColors.success : AppColors.error,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${report.percentChange > 0 ? '+' : ''}${report.percentChange.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPositive
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.timer, size: 20, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    '${report.totalMinutes} phút',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    ' (${report.previousWeekMinutes} phút tuần trước)',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (report.topApps.isNotEmpty) ...[
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: report.topApps.take(3).map((app) {
                    return Chip(
                      avatar: Icon(
                        AppUtils.getAppIcon(app),
                        size: 16,
                        color: AppUtils.getAppColor(app),
                      ),
                      label: Text(app),
                      backgroundColor:
                          AppUtils.getAppColor(app).withOpacity(0.1),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String date) {
    final parts = date.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}';
    }
    return date;
  }
}

class _ReportDetailSheet extends StatelessWidget {
  final WeeklyReport report;

  const _ReportDetailSheet({required this.report});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                'Chi tiết báo cáo tuần',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '${_formatDate(report.weekStartDate)} - ${_formatDate(report.weekEndDate)}',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 24),

              // Stats
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Tổng thời gian',
                      value: '${report.totalMinutes}p',
                      icon: Icons.timer,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Thay đổi',
                      value:
                          '${report.percentChange > 0 ? '+' : ''}${report.percentChange.toStringAsFixed(0)}%',
                      icon: report.percentChange > 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: report.percentChange > 0
                          ? AppColors.error
                          : AppColors.success,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Insights
              if (report.improvements.isNotEmpty) ...[
                Text(
                  'Cải thiện',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
                SizedBox(height: 12),
                ...report.improvements.map((item) => ListTile(
                      leading:
                          Icon(Icons.check_circle, color: AppColors.success),
                      title: Text(item),
                    )),
                SizedBox(height: 16),
              ],

              if (report.concerns.isNotEmpty) ...[
                Text(
                  'Cần lưu ý',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
                SizedBox(height: 12),
                ...report.concerns.map((item) => ListTile(
                      leading: Icon(Icons.warning, color: AppColors.warning),
                      title: Text(item),
                    )),
              ],

              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Đóng'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(String date) {
    final parts = date.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return date;
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
                fontSize: 18,
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
