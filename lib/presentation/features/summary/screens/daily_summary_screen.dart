import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../domain/entities/daily_summary.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../features/auth/bloc/auth_state.dart';
import '../bloc/summary_bloc.dart';
import '../bloc/summary_event.dart';
import '../bloc/summary_state.dart';

class DailySummaryScreen extends StatefulWidget {
  const DailySummaryScreen({super.key});

  @override
  State<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  void _loadSummary() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user.familyId != null) {
      context.read<SummaryBloc>().add(
            LoadSummaryHistory(familyId: authState.user.familyId!),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tổng kết hàng ngày'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<SummaryBloc, SummaryState>(
        builder: (context, state) {
          if (state is SummaryLoading) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is SummaryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  SizedBox(height: 16),
                  Text(state.message),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadSummary,
                    child: Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state is SummaryHistoryLoaded) {
            return _buildSummaryList(state.summaries);
          }

          return Center(
            child: Text('Chưa có dữ liệu tổng kết'),
          );
        },
      ),
    );
  }

  Widget _buildSummaryList(List<DailySummary> summaries) {
    if (summaries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.summarize,
              size: 80,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'Chưa có tổng kết',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tổng kết sẽ được tạo vào cuối mỗi ngày',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadSummary(),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: summaries.length,
        itemBuilder: (context, index) {
          final summary = summaries[index];
          return _SummaryCard(summary: summary);
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final DailySummary summary;

  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final hours = summary.totalMinutes ~/ 60;
    final minutes = summary.totalMinutes % 60;
    final hasAlerts = summary.alertCount > 0 || summary.violationCount > 0;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showSummaryDetail(context, summary),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        _formatDate(summary.date),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (hasAlerts)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning,
                            size: 16,
                            color: AppColors.error,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${summary.alertCount + summary.violationCount} cảnh báo',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16),

              // Total usage
              Row(
                children: [
                  Icon(
                    Icons.timer,
                    size: 24,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    hours > 0
                        ? '$hours giờ $minutes phút'
                        : '$minutes phút',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    ' sử dụng',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Top apps
              if (summary.topApps.isNotEmpty) ...[
                Text(
                  'Ứng dụng nhiều nhất:',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: summary.topApps.map((app) {
                    final minutes = summary.usageByApp[app] ?? 0;
                    return Chip(
                      avatar: Icon(
                        AppUtils.getAppIcon(app),
                        size: 18,
                        color: AppUtils.getAppColor(app),
                      ),
                      label: Text('$app ($minutes phút)'),
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
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return date;
  }

  void _showSummaryDetail(BuildContext context, DailySummary summary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SummaryDetailSheet(summary: summary),
    );
  }
}

class _SummaryDetailSheet extends StatelessWidget {
  final DailySummary summary;

  const _SummaryDetailSheet({required this.summary});

  @override
  Widget build(BuildContext context) {
    final hours = summary.totalMinutes ~/ 60;
    final minutes = summary.totalMinutes % 60;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
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

              // Title
              Text(
                'Chi tiết tổng kết',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _formatDate(summary.date),
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 24),

              // Total usage card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
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
                      Icons.timer,
                      size: 48,
                      color: Colors.white,
                    ),
                    SizedBox(height: 12),
                    Text(
                      hours > 0
                          ? '$hours giờ $minutes phút'
                          : '$minutes phút',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Tổng thời gian sử dụng',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Alerts section
              if (summary.alertCount > 0 || summary.violationCount > 0) ...[
                Text(
                  'Cảnh báo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                if (summary.alertCount > 0)
                  ListTile(
                    leading: Icon(Icons.warning, color: AppColors.warning),
                    title: Text('${summary.alertCount} cảnh báo an toàn'),
                  ),
                if (summary.violationCount > 0)
                  ListTile(
                    leading: Icon(Icons.error, color: AppColors.error),
                    title:
                        Text('${summary.violationCount} vi phạm giới hạn'),
                  ),
                SizedBox(height: 24),
              ],

              // App breakdown
              Text(
                'Chi tiết theo ứng dụng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              ...summary.usageByApp.entries.map((entry) {
                final appHours = entry.value ~/ 60;
                final appMinutes = entry.value % 60;
                final timeStr = appHours > 0
                    ? '$appHours giờ $appMinutes phút'
                    : '$appMinutes phút';

                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          AppUtils.getAppColor(entry.key).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      AppUtils.getAppIcon(entry.key),
                      color: AppUtils.getAppColor(entry.key),
                    ),
                  ),
                  title: Text(entry.key),
                  trailing: Text(
                    timeStr,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                );
              }),

              SizedBox(height: 24),

              // Close button
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
      return 'Ngày ${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return date;
  }
}
