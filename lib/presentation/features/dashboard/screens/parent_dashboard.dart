import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../domain/entities/user.dart';
import '../../../../domain/repositories/family_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/screens/create_child_screen.dart';
import '../../auth/screens/profile_screen.dart';
import '../../report/screens/weekly_report_screen.dart';
import '../../summary/screens/daily_summary_screen.dart';
import '../../../screens/smart_lock/blocked_apps_screen.dart';
import '../../usage_statistics/screens/usage_statistics_screen.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/usage_chart_widget.dart';
import '../widgets/app_usage_list_widget.dart';
import 'app_usage_detail_screen.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  void _loadDashboard() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user.familyId != null) {
      context.read<DashboardBloc>().add(
            LoadDashboard(familyId: authState.user.familyId!),
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

        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.appName),
            automaticallyImplyLeading: false,
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
          body: IndexedStack(
            index: _currentIndex,
            children: [
              _buildDashboardTab(user),
              _buildMonitoringTab(user),
              _buildSettingsTab(user),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Tổng quan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.monitor),
                label: 'Giám sát',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Cài đặt',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardTab(User user) {
    return BlocListener<DashboardBloc, DashboardState>(
      listener: (context, state) {
        // Auto-refresh every 5 minutes when dashboard is loaded
        if (state is DashboardLoaded) {
          Future.delayed(const Duration(minutes: 5), () {
            if (mounted) {
              _loadDashboard();
            }
          });
        }
      },
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (state is DashboardError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  SizedBox(height: 16),
                  Text(state.message),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadDashboard,
                    child: Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state is DashboardLoaded) {
            return _buildDashboardContent(user, state);
          }

          return _buildEmptyDashboard(user);
        },
      ),
    );
  }

  Widget _buildDashboardContent(User user, DashboardLoaded state) {
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
                  colors: [AppColors.primary, AppColors.primaryDark],
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
                    'Tổng quan sử dụng hôm nay',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Usage summary cards
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Hôm nay',
                    value: '${state.totalMinutesToday} phút',
                    icon: Icons.today,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _SummaryCard(
                    title: 'Hôm qua',
                    value: '${state.totalMinutesYesterday} phút',
                    icon: Icons.history,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Change indicator
            if (state.totalMinutesYesterday > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: state.percentChangeFromYesterday > 0
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      state.percentChangeFromYesterday > 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: state.percentChangeFromYesterday > 0
                          ? AppColors.error
                          : AppColors.success,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '${state.percentChangeFromYesterday > 0 ? "+" : ""}${state.percentChangeFromYesterday}% so với hôm qua',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: state.percentChangeFromYesterday > 0
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 24),

            // App usage list
            AppUsageListWidget(
              usageByApp: state.usageByApp,
              onAppTap: (appName, minutes) {
                if (state.childUids.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AppUsageDetailScreen(
                        childUid: state.childUids.first,
                        appName: appName,
                        totalMinutes: minutes,
                      ),
                    ),
                  );
                }
              },
            ),
            SizedBox(height: 24),

            // Usage chart widget
            UsageChartWidget(
              dailyTotals: state.dailyTotals,
              appTotals: state.usageByApp,
            ),
            SizedBox(height: 24),

            // Quick actions
            Text(
              'Chức năng nhanh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.person_add,
                    title: 'Thêm con',
                    color: AppColors.childPrimary,
                    onTap: () => _navigateToCreateChild(context, user),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.summarize,
                    title: 'Tổng kết',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DailySummaryScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.lock,
                    title: 'Khóa ứng dụng',
                    color: AppColors.warning,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tính năng đang phát triển')),
                      );
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.assessment,
                    title: 'Báo cáo tuần',
                    color: AppColors.accent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WeeklyReportScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.notifications,
                    title: 'Cảnh báo',
                    color: AppColors.error,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tính năng đang phát triển')),
                      );
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.lock,
                    title: 'Khóa ứng dụng',
                    color: AppColors.warning,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tính năng đang phát triển')),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Recent activity
            if (state.recentLogs.isNotEmpty) ...[
              Text(
                'Hoạt động gần đây',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              ...state.recentLogs.take(5).map((log) => Card(
                    child: ListTile(
                      leading: Icon(
                        AppUtils.getAppIcon(log.appName),
                        color: AppUtils.getAppColor(log.appName),
                      ),
                      title: Text(log.appName),
                      subtitle: Text('${log.durationMinutes} phút'),
                      trailing: Text(
                        '${log.startTime.hour}:${log.startTime.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
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

  Widget _buildMonitoringTab(User user) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final childUids = state is DashboardLoaded ? state.childUids : <String>[];

        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            Text(
              'Quản lý Smart Lock',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Các tính năng giám sát và quản lý ứng dụng trên thiết bị con',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: Icon(Icons.apps, color: AppColors.primary),
                title: Text('Quản lý ứng dụng giám sát'),
                subtitle: Text('Chọn ứng dụng cần giám sát'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  if (user.familyId == null || childUids.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Vui lòng thêm tài khoản con trước')),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlockedAppsScreen(
                        familyId: user.familyId!,
                        childId: childUids.first,
                      ),
                    ),
                  );
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.timer, color: AppColors.warning),
                title: Text('Giới hạn thời gian'),
                subtitle: Text('Đặt giới hạn sử dụng theo ứng dụng'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tính năng đang phát triển')),
                  );
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.lock_clock, color: AppColors.error),
                title: Text('Khóa ứng dụng'),
                subtitle: Text('Khóa ngay lập tức các ứng dụng'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tính năng đang phát triển')),
                  );
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.bar_chart, color: AppColors.accent),
                title: Text('Thống kê sử dụng'),
                subtitle: Text('Xem chi tiết thống kê sử dụng ứng dụng'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  if (user.familyId == null || childUids.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Vui lòng thêm tài khoản con trước')),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UsageStatisticsScreen(
                        childUid: childUids.first,
                        childName: 'Con',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
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
            leading: Icon(Icons.family_restroom),
            title: Text('Quản lý gia đình'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Cài đặt thông báo'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.help),
            title: Text('Trợ giúp & Hỗ trợ'),
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

  void _navigateToCreateChild(BuildContext context, User user) async {
    final familyRepo = context.read<FamilyRepository>();
    final family = await familyRepo.getFamilyByParent(user.uid);

    if (context.mounted) {
      if (family != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateChildScreen(familyId: family.familyId),
          ),
        );
      } else {
        final newFamily = await familyRepo.createFamily(user.uid);
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CreateChildScreen(familyId: newFamily.familyId),
            ),
          );
        }
      }
    }
  }

  Widget _buildEmptyDashboard(User user) {
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
                colors: [AppColors.primary, AppColors.primaryDark],
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
                  'Chào mừng bạn đến với KidGuardian',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Chức năng nhanh',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.person_add,
                  title: 'Thêm con',
                  color: AppColors.childPrimary,
                  onTap: () => _navigateToCreateChild(context, user),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.lock,
                  title: 'Khóa ứng dụng',
                  color: AppColors.warning,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tính năng đang phát triển')),
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có dữ liệu',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Thêm tài khoản con để bắt đầu giám sát',
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
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
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
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
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

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
