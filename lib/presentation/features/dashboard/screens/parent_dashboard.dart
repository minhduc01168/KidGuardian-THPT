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

import '../../auth/screens/profile_screen.dart';
import '../../report/screens/weekly_report_screen.dart';
import '../../report/screens/monthly_report_screen.dart';
import '../../settings/screens/app_settings_screen.dart';
import '../../summary/screens/daily_summary_screen.dart';
import '../../../screens/smart_lock/blocked_apps_screen.dart';
import '../../usage_statistics/screens/usage_statistics_screen.dart';
import '../../../screens/settings/auto_approval_rules_screen.dart';
import '../../../screens/notifications/notification_center_screen.dart';
import '../../../widgets/notifications/notification_badge.dart';
import '../../help/screens/help_support_screen.dart';
import '../../help/bloc/help_bloc.dart';
import '../../family/screens/family_management_screen.dart';
import '../../../screens/smart_lock/time_limit_screen.dart';
import '../../../screens/smart_lock/smart_lock_settings_screen.dart';
import '../../../blocs/smart_lock/smart_lock_bloc.dart';
import '../../../../data/repositories/smart_lock_repository.dart';
import '../../../screens/interaction/time_request_approval_screen.dart';
import '../../../screens/settings/keyword_management_screen.dart';
import '../../../blocs/in_app_notification/in_app_notification_bloc.dart';
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
      context.read<InAppNotificationBloc>().add(
            LoadInAppNotifications(familyId: authState.user.familyId!),
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
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.shield_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            automaticallyImplyLeading: false,
            actions: [
              NotificationBadge(
                onTap: () {
                  if (user.familyId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationCenterScreen(
                          familyId: user.familyId!,
                        ),
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _loadDashboard,
                tooltip: 'Làm mới',
              ),
              Container(
                margin: EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person, size: 20),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(user: user),
                      ),
                    );
                  },
                ),
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
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withOpacity(0.85), AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xin chào,\n${user.displayName}!',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sẵn sàng giám sát an toàn hôm nay?',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                    ),
                    child: const Icon(Icons.person_outline_rounded, size: 36, color: Colors.white),
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
                    minutes: state.totalMinutesToday,
                    icon: Icons.today_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryCard(
                    title: 'Hôm qua',
                    minutes: state.totalMinutesYesterday,
                    icon: Icons.history_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Change indicator
            if (state.totalMinutesYesterday > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: state.percentChangeFromYesterday > 0
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: state.percentChangeFromYesterday > 0
                            ? AppColors.error.withOpacity(0.2)
                            : AppColors.success.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        state.percentChangeFromYesterday > 0
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        color: state.percentChangeFromYesterday > 0
                            ? AppColors.error
                            : AppColors.success,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${state.percentChangeFromYesterday > 0 ? "+" : ""}${state.percentChangeFromYesterday}% so với hôm qua',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
              appTimeLimits: state.appTimeLimits,
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
                    icon: Icons.qr_code,
                    title: 'Mã liên kết',
                    color: AppColors.childPrimary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FamilyManagementScreen(user: user),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.summarize,
                    title: 'Tổng kết',
                    color: AppColors.primary,
                    onTap: () {
                      final targetId = state.childUids.isNotEmpty ? state.childUids.first : null;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DailySummaryScreen(childUid: targetId),
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
                      if (user.familyId != null) {
                        final targetId = state.childUids.isNotEmpty ? state.childUids.first : user.uid;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) => SmartLockBloc(
                                repository: SmartLockRepository(),
                              ),
                              child: SmartLockSettingsScreen(
                                familyId: user.familyId!,
                                childId: targetId,
                                childName: user.displayName,
                              ),
                            ),
                          ),
                        );
                      } else {
                        _showSetupFamilyDialog(context);
                      }
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
                      final targetId = state.childUids.isNotEmpty ? state.childUids.first : null;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WeeklyReportScreen(childUid: targetId),
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
                      if (user.familyId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NotificationCenterScreen(
                              familyId: user.familyId!,
                            ),
                          ),
                        );
                      } else {
                        _showSetupFamilyDialog(context);
                      }
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.timer,
                    title: 'Yêu cầu',
                    color: AppColors.accent,
                    onTap: () {
                      if (user.familyId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TimeRequestApprovalScreen(
                              familyId: user.familyId!,
                            ),
                          ),
                        );
                      } else {
                        _showSetupFamilyDialog(context);
                      }
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
                    icon: Icons.calendar_month,
                    title: 'Báo cáo tháng',
                    color: AppColors.primaryDark,
                    onTap: () {
                      final targetId = state.childUids.isNotEmpty ? state.childUids.first : null;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MonthlyReportScreen(childUid: targetId),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(child: SizedBox()),
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
              SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.recentLogs.length > 5 ? 5 : state.recentLogs.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 48),
                  itemBuilder: (context, index) {
                    final log = state.recentLogs[index];
                    final localStartTime = log.startTime.toLocal();
                    final timeFormatted = '${localStartTime.hour.toString().padLeft(2, '0')}:${localStartTime.minute.toString().padLeft(2, '0')}';
                    final cleanName = AppUtils.getAppName(log.appName);
                    return ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      leading: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppUtils.getAppColor(cleanName).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          AppUtils.getAppIcon(cleanName),
                          color: AppUtils.getAppColor(cleanName),
                          size: 16,
                        ),
                      ),
                      title: Text(
                        cleanName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'lúc $timeFormatted • ${AppUtils.formatMinutes(log.durationMinutes)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    );
                  },
                ),
              ),
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

  void _showSetupFamilyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.family_restroom, size: 48, color: AppColors.primary),
        title: Text('Chưa thiết lập gia đình'),
        content: Text(
          'Bạn cần liên kết tài khoản con để sử dụng tính năng này.\n\n'
          'Vào "Quản lý gia đình" để lấy mã liên kết và chia sẻ cho con.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Đã hiểu'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FamilyManagementScreen(user: authState.user),
                  ),
                );
              }
            },
            child: Text('Quản lý gia đình'),
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
                  if (user.familyId != null) {
                    final childUids = context.read<DashboardBloc>().state is DashboardLoaded
                        ? (context.read<DashboardBloc>().state as DashboardLoaded).childUids
                        : <String>[];
                    if (childUids.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TimeLimitScreen(
                            familyId: user.familyId!,
                            childId: childUids.first,
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.security, color: AppColors.error),
                title: Text('Quản lý từ khóa cấm'),
                subtitle: Text('Thêm, sửa, xóa từ khóa cần theo dõi'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  if (user.familyId == null) {
                    _showSetupFamilyDialog(context);
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => KeywordManagementScreen(
                        familyId: user.familyId!,
                      ),
                    ),
                  );
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.auto_awesome, color: Colors.green),
                title: Text('Tự động duyệt yêu cầu'),
                subtitle: Text('Cài đặt quy tắc tự động duyệt'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  if (user.familyId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Vui lòng thêm tài khoản con trước')),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AutoApprovalRulesScreen(
                        familyId: user.familyId!,
                      ),
                    ),
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
                        familyId: user.familyId,
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
            leading: Icon(Icons.tune),
            title: Text('Cài đặt ứng dụng'),
            subtitle: Text('Giao diện, ngôn ngữ, thông báo'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppSettingsScreen(),
                ),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<HelpBloc>(),
                    child: HelpSupportScreen(),
                  ),
                ),
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
                  'Chào mừng bạn đến với ${AppStrings.appName}',
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
                  icon: Icons.qr_code,
                  title: 'Mã liên kết',
                  color: AppColors.childPrimary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FamilyManagementScreen(user: user),
                      ),
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
                    if (user.familyId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider(
                            create: (_) => SmartLockBloc(
                              repository: SmartLockRepository(),
                            ),
                            child: SmartLockSettingsScreen(
                              familyId: user.familyId!,
                              childId: user.uid,
                              childName: user.displayName,
                            ),
                          ),
                        ),
                      );
                    } else {
                      _showSetupFamilyDialog(context);
                    }
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
  final int minutes;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.minutes,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: minutes),
            duration: const Duration(seconds: 1),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Text(
                '$value phút',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              );
            },
          ),
        ],
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          highlightColor: color.withOpacity(0.05),
          splashColor: color.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: color,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
