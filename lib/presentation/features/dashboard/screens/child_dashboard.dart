import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../domain/entities/user.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/screens/profile_screen.dart';
import '../../auth/screens/link_child_screen.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

class ChildDashboard extends StatefulWidget {
  const ChildDashboard({super.key});

  @override
  State<ChildDashboard> createState() => _ChildDashboardState();
}

class _ChildDashboardState extends State<ChildDashboard> {
  int _currentIndex = 0;
  final int _dailyLimitMinutes = 120; // Default 2 hours, will be updated from settings

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  void _loadDashboard() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      context.read<DashboardBloc>().add(
            LoadChildUsage(
              childUid: authState.user.uid,
              date: dateStr,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return SizedBox.shrink();
        }

        final user = state.user;
        final isLinked = user.familyId != null;

        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.appName),
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.childPrimary,
            actions: [
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _loadDashboard,
              ),
              IconButton(
                icon: Icon(Icons.person),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(user: user),
                    ),
                  );
                },
              ),
            ],
          ),
          body: isLinked
              ? IndexedStack(
                  index: _currentIndex,
                  children: [
                    _buildHomeTab(user),
                    _buildUsageTab(user),
                    _buildSettingsTab(user),
                  ],
                )
              : _buildLinkAccountPrompt(),
          bottomNavigationBar: isLinked
              ? BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  selectedItemColor: AppColors.childPrimary,
                  items: [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Trang chủ',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.bar_chart),
                      label: 'Sử dụng',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings),
                      label: 'Cài đặt',
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }

  Widget _buildLinkAccountPrompt() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.link_off,
              size: 80,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 24),
            Text(
              'Chưa liên kết tài khoản',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Bạn cần nhập mã liên kết từ phụ huynh để sử dụng ứng dụng',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LinkChildScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.link),
                label: Text(
                  'Nhập mã liên kết',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.childPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab(User user) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.childPrimary,
            ),
          );
        }

        if (state is DashboardLoaded) {
          return _buildHomeContent(user, state);
        }

        return _buildHomeEmpty(user);
      },
    );
  }

  Widget _buildHomeContent(User user, DashboardLoaded state) {
    final remainingMinutes = _dailyLimitMinutes - state.totalMinutesToday;
    final isOverLimit = remainingMinutes <= 0;
    final progress = state.totalMinutesToday / _dailyLimitMinutes;

    return RefreshIndicator(
      onRefresh: () async => _loadDashboard(),
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.childPrimary, Color(0xFF388E3C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xin chào, ${user.displayName}!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    isOverLimit
                        ? 'Bạn đã hết thời gian sử dụng hôm nay'
                        : 'Hôm nay bạn còn $remainingMinutes phút',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Time remaining card
            Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Thời gian còn lại',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: CircularProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              strokeWidth: 12,
                              backgroundColor: AppColors.divider.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isOverLimit
                                    ? AppColors.error
                                    : progress > 0.8
                                        ? AppColors.warning
                                        : AppColors.childPrimary,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isOverLimit ? '0' : '$remainingMinutes',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: isOverLimit
                                      ? AppColors.error
                                      : AppColors.childPrimary,
                                ),
                              ),
                              Text(
                                'phút',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Giới hạn: $_dailyLimitMinutes phút/ngày',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Usage by app
            if (state.usageByApp.isNotEmpty) ...[
              Text(
                'Ứng dụng đã sử dụng',
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
                    children: [
                      SizedBox(
                        height: 150,
                        child: _buildPieChart(state.usageByApp),
                      ),
                      SizedBox(height: 16),
                      ...state.usageByApp.entries.take(5).map((entry) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                AppUtils.getAppIcon(entry.key),
                                size: 20,
                                color: AppUtils.getAppColor(entry.key),
                              ),
                              SizedBox(width: 8),
                              Expanded(child: Text(entry.key)),
                              Text(
                                '${entry.value}p',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<String, int> usageByApp) {
    final colors = [
      AppColors.childPrimary,
      AppColors.primary,
      AppColors.warning,
      AppColors.error,
      AppColors.accent,
    ];

    final total = usageByApp.values.fold(0, (sum, val) => sum + val);
    if (total == 0) return SizedBox.shrink();

    return PieChart(
      PieChartData(
        sections: usageByApp.entries.toList().asMap().entries.map((entry) {
          final index = entry.key;
          final appEntry = entry.value;
          final percent = total > 0 ? (appEntry.value / total * 100) : 0;
          return PieChartSectionData(
            value: appEntry.value.toDouble() > 0
                ? appEntry.value.toDouble()
                : 0.1,
            title: '${percent.toStringAsFixed(0)}%',
            color: colors[index % colors.length],
            radius: 50,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 30,
      ),
    );
  }

  Widget _buildHomeEmpty(User user) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.childPrimary, Color(0xFF388E3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào, ${user.displayName}!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Hôm nay bạn khỏe không?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.timer,
                    size: 64,
                    color: AppColors.childPrimary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có dữ liệu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Bắt đầu sử dụng điện thoại để xem thống kê',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageTab(User user) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoaded && state.dailyTotals.isNotEmpty) {
          return _buildUsageContent(state);
        }
        return _buildUsageEmpty();
      },
    );
  }

  Widget _buildUsageContent(DashboardLoaded state) {
    final sortedEntries = state.dailyTotals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                child: _buildWeeklyChart(sortedEntries),
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Chi tiết theo ngày',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          ...sortedEntries.reversed.take(7).map((entry) {
            final dateParts = entry.key.split('-');
            final dateLabel = '${dateParts[2]}/${dateParts[1]}';
            final isOverLimit = entry.value > _dailyLimitMinutes;

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isOverLimit
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.childPrimary.withOpacity(0.1),
                  child: Icon(
                    isOverLimit ? Icons.warning : Icons.check,
                    color: isOverLimit
                        ? AppColors.error
                        : AppColors.childPrimary,
                  ),
                ),
                title: Text(dateLabel),
                trailing: Text(
                  '${entry.value} phút',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isOverLimit ? AppColors.error : AppColors.childPrimary,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(List<MapEntry<String, int>> entries) {
    if (entries.isEmpty) {
      return Center(
        child: Text(
          'Chưa có dữ liệu',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final spots = entries.asMap().entries.map((entry) {
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
                if (value.toInt() < entries.length) {
                  final date = entries[value.toInt()].key;
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
          final isOverLimit = entry.value.y > _dailyLimitMinutes;
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.y,
                color: isOverLimit ? AppColors.error : AppColors.childPrimary,
                width: 24,
                borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final entry = entries[group.x];
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

  Widget _buildUsageEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 80,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'Thống kê sử dụng',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Chưa có dữ liệu',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(User user) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: Icon(Icons.person),
            title: Text('Thông tin cá nhân'),
            subtitle: Text(user.email),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(user: user),
                ),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.link),
            title: Text('Liên kết tài khoản'),
            subtitle:
                Text(user.familyId != null ? 'Đã liên kết' : 'Chưa liên kết'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              if (user.familyId == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LinkChildScreen(),
                  ),
                );
              }
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.help),
            title: Text('Trợ giúp'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              _showLogoutDialog(context);
            },
            icon: Icon(Icons.logout, color: AppColors.error),
            label: Text(
              AppStrings.logout,
              style: TextStyle(color: AppColors.error),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Đăng xuất'),
        content: Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            child: Text(
              'Đăng xuất',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
