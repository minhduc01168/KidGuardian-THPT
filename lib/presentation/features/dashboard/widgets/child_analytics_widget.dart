// lib/presentation/features/dashboard/widgets/child_analytics_widget.dart
//
// Widget thống kê dùng chung cho cả Parent và Child Dashboard.
// Nhận childUid làm tham số đầu vào, tự load và hiển thị dữ liệu
// từ DashboardBloc (LoadChildUsage event) mà không cần parent truyền data.
//
// Yêu cầu (FEATURE_DEBUG_REQUIREMENTS.md §4):
//   - Two-way tracking: hiển thị thống kê cho cả Parent VÀ Child
//   - Chỉ thống kê 8 app MXH cố định (AppUtils.isSystemOrUnmonitoredApp)
//   - Client-side filtering (RAM), không phụ thuộc Firestore index phức tạp
//   - Reusable Widget nhận childUid làm tham số

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_utils.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import 'usage_chart_widget.dart';

/// Widget thống kê dùng chung — hiển thị biểu đồ sử dụng cho một trẻ cụ thể.
///
/// Sử dụng:
/// ```dart
/// ChildAnalyticsWidget(
///   childUid: user.uid,
///   themeColor: AppColors.childPrimary,
/// )
/// ```
class ChildAnalyticsWidget extends StatefulWidget {
  /// UID của trẻ cần xem thống kê
  final String childUid;

  /// Màu chủ đề: childPrimary cho màn hình trẻ, primary cho parent
  final Color themeColor;

  /// Tiêu đề hiển thị trên màn hình
  final String title;

  const ChildAnalyticsWidget({
    super.key,
    required this.childUid,
    this.themeColor = AppColors.childPrimary,
    this.title = 'Thống kê sử dụng',
  });

  @override
  State<ChildAnalyticsWidget> createState() => _ChildAnalyticsWidgetState();
}

class _ChildAnalyticsWidgetState extends State<ChildAnalyticsWidget> {
  /// Số ngày lịch sử cần load — mặc định 7 ngày
  static const int _historyDays = 7;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  void _loadAnalyticsData() {
    final today = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(today);

    // LoadChildUsage sẽ kéo toàn bộ dailyTotals + usageByApp cho childUid
    // DashboardBloc đã có cơ chế RAM filtering qua AppUtils
    context.read<DashboardBloc>().add(
          LoadChildUsage(
            childUid: widget.childUid,
            date: dateStr,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading || state is DashboardInitial) {
          return _buildLoadingState();
        }

        if (state is DashboardError) {
          return _buildErrorState(state.message);
        }

        if (state is DashboardLoaded) {
          return _buildAnalyticsContent(state);
        }

        return _buildEmptyState();
      },
    );
  }

  // ─── Loading state ───────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: widget.themeColor),
          const SizedBox(height: 16),
          Text(
            'Đang tải dữ liệu...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ─── Error state ─────────────────────────────────────────────────────────

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Không thể tải dữ liệu',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadAnalyticsData,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(backgroundColor: widget.themeColor),
          ),
        ],
      ),
    );
  }

  // ─── Empty state ─────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_outlined, size: 80, color: AppColors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 20),
          Text(
            'Chưa có dữ liệu thống kê',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Dữ liệu sử dụng sẽ xuất hiện sau khi bạn sử dụng các ứng dụng được giám sát.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: _loadAnalyticsData,
            icon: Icon(Icons.refresh, color: widget.themeColor),
            label: Text('Làm mới', style: TextStyle(color: widget.themeColor)),
          ),
        ],
      ),
    );
  }

  // ─── Main content ────────────────────────────────────────────────────────

  Widget _buildAnalyticsContent(DashboardLoaded state) {
    // Client-side filter: chỉ giữ 8 app MXH được giám sát
    final filteredAppTotals = Map<String, int>.fromEntries(
      state.usageByApp.entries.where(
        (e) => !AppUtils.isSystemOrUnmonitoredApp(e.key) && e.value > 0,
      ),
    );

    // dailyTotals từ DashboardBloc đã qua RAM filtering → dùng trực tiếp
    final dailyTotals = state.dailyTotals;

    final totalToday = state.totalMinutesToday;
    final totalWeek = dailyTotals.values.fold(0, (a, b) => a + b);
    final avgPerDay = dailyTotals.isNotEmpty
        ? (totalWeek / dailyTotals.length).round()
        : 0;

    return RefreshIndicator(
      onRefresh: () async => _loadAnalyticsData(),
      color: widget.themeColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // ── Summary Cards ─────────────────────────────────────────────
            _buildSummaryRow(totalToday, totalWeek, avgPerDay),
            const SizedBox(height: 24),

            // ── UsageChartWidget (dùng chung, nhận dailyTotals + appTotals) ─
            if (filteredAppTotals.isNotEmpty || dailyTotals.isNotEmpty)
              UsageChartWidget(
                dailyTotals: dailyTotals,
                appTotals: filteredAppTotals,
              )
            else
              _buildEmptyChartCard(),

            const SizedBox(height: 24),

            // ── 7 ngày gần nhất ───────────────────────────────────────────
            if (dailyTotals.isNotEmpty) ...[
              Text(
                '${_historyDays} ngày gần nhất',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildDailyList(dailyTotals),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Summary Row (3 cards: Hôm nay / Tuần / Trung bình) ────────────────

  Widget _buildSummaryRow(int today, int week, int avg) {
    return Row(
      children: [
        Expanded(child: _buildSummaryCard('Hôm nay', '$today', 'phút', Icons.today)),
        const SizedBox(width: 8),
        Expanded(child: _buildSummaryCard('7 ngày', '$week', 'phút', Icons.date_range)),
        const SizedBox(width: 8),
        Expanded(child: _buildSummaryCard('Trung bình', '$avg', 'phút/ngày', Icons.trending_up)),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, String unit, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: widget.themeColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: widget.themeColor,
              ),
            ),
            Text(
              unit,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Empty chart placeholder ────────────────────────────────────────────

  Widget _buildEmptyChartCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.bar_chart_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'Chưa có dữ liệu biểu đồ',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Daily list ──────────────────────────────────────────────────────────

  Widget _buildDailyList(Map<String, int> dailyTotals) {
    final sorted = dailyTotals.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key)); // Mới nhất lên đầu
    final recent = sorted.take(_historyDays).toList();

    return Column(
      children: recent.map((entry) {
        final parts = entry.key.split('-');
        final dateLabel = parts.length == 3 ? '${parts[2]}/${parts[1]}' : entry.key;
        final isToday = entry.key == DateFormat('yyyy-MM-dd').format(DateTime.now());

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: widget.themeColor.withOpacity(0.1),
              child: Icon(
                isToday ? Icons.today : Icons.calendar_today,
                color: widget.themeColor,
                size: 20,
              ),
            ),
            title: Text(
              isToday ? '$dateLabel (Hôm nay)' : dateLabel,
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: Text(
              '${entry.value} phút',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.themeColor,
                fontSize: 15,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
