import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../domain/entities/monthly_report.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../features/auth/bloc/auth_state.dart';
import '../../dashboard/bloc/dashboard_bloc.dart';
import '../../dashboard/bloc/dashboard_state.dart';
import '../bloc/report_bloc.dart';
import '../bloc/report_event.dart';
import '../bloc/report_state.dart';

class MonthlyReportScreen extends StatefulWidget {
  final String? childUid;

  const MonthlyReportScreen({super.key, this.childUid});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  String _getTargetChildId(BuildContext context, AuthAuthenticated authState) {
    if (widget.childUid != null && widget.childUid!.isNotEmpty) {
      return widget.childUid!;
    }
    try {
      final dashState = context.read<DashboardBloc>().state;
      if (dashState is DashboardLoaded && dashState.childUids.isNotEmpty) {
        return dashState.childUids.first;
      }
    } catch (_) {}
    return authState.user.uid;
  }

  void _loadReports() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user.familyId != null) {
      context.read<ReportBloc>().add(
            LoadMonthlyReportHistory(familyId: authState.user.familyId!),
          );
    }
  }

  void _autoGenerateIfEmpty(ReportState state) {
    if (state is MonthlyReportHistoryLoaded && state.reports.isEmpty) {
      _generateReport();
    }
  }

  void _generateReport() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user.familyId != null) {
      final targetChildUid = _getTargetChildId(context, authState);
      context.read<ReportBloc>().add(
            GenerateMonthlyReport(
              childUid: targetChildUid,
              familyId: authState.user.familyId!,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo tháng (30 ngày)'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: BlocConsumer<ReportBloc, ReportState>(
        listener: (context, state) {
          if (state is ReportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _autoGenerateIfEmpty(state);
          });

          if (state is ReportLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is ReportError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadReports,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state is MonthlyReportHistoryLoaded) {
            if (state.reports.isEmpty) return _buildEmptyState();
            return _buildReportDetail(state.reports.first);
          }

          if (state is MonthlyReportGenerated) {
            return _buildReportDetail(state.report);
          }

          return _buildEmptyState();
        },
      ),
      // FAB removed because we only have 1 screen for monthly report
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.assessment,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có báo cáo tháng',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nhấn nút để tổng hợp báo cáo 30 ngày qua',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportDetail(MonthlyReport report) {
    return RefreshIndicator(
      onRefresh: () async => _loadReports(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tổng kết 30 ngày qua',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppUtils.formatMinutes(report.totalMinutes),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        report.percentChange > 0
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: report.percentChange > 0
                            ? Colors.redAccent
                            : Colors.greenAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${report.percentChange > 0 ? "+" : ""}${report.percentChange.toStringAsFixed(1)}% so với 30 ngày trước',
                        style: TextStyle(
                          color: report.percentChange > 0
                              ? Colors.redAccent
                              : Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Weekly Breakdown Trend Chart
            const Text(
              'Xu hướng theo tuần',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildWeeklyTrendChart(report.weeklyBreakdown),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Top 5 Apps
            const Text(
              'Top 5 ứng dụng tốn thời gian nhất',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: report.topApps.take(5).map((app) {
                    final minutes = report.usageByApp[app] ?? 0;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppUtils.getAppColor(app).withOpacity(0.1),
                        child: Icon(
                          Icons.apps,
                          color: AppUtils.getAppColor(app),
                        ),
                      ),
                      title: Text(
                        app,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        AppUtils.formatMinutes(minutes),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Insights
            if (report.improvements.isNotEmpty) ...[
              const Text(
                'Điểm tích cực',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 12),
              ...report.improvements.map((item) => Card(
                    color: AppColors.success.withOpacity(0.1),
                    child: ListTile(
                      leading: const Icon(Icons.check_circle, color: AppColors.success),
                      title: Text(item),
                    ),
                  )),
              const SizedBox(height: 16),
            ],

            if (report.concerns.isNotEmpty) ...[
              const Text(
                'Cần lưu ý',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 12),
              ...report.concerns.map((item) => Card(
                    color: AppColors.warning.withOpacity(0.1),
                    child: ListTile(
                      leading: const Icon(Icons.warning, color: AppColors.warning),
                      title: Text(item),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTrendChart(Map<String, int> weeklyBreakdown) {
    final entries = weeklyBreakdown.entries.toList();
    if (entries.isEmpty) {
      return const Center(child: Text('Chưa có dữ liệu biểu đồ'));
    }

    return BarChart(
      BarChartData(
        gridData: const FlGridData(
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
                  '${(value / 60).toStringAsFixed(0)}h',
                  style: const TextStyle(
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
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value % 1 == 0 && value.toInt() >= 0 && value.toInt() < entries.length) {
                  return Text(
                    entries[value.toInt()].key,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: entries.asMap().entries.map((entry) {
          final index = entry.key;
          final val = entry.value.value.toDouble();
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: val,
                color: AppColors.primary,
                width: 20,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
