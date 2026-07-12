import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../domain/entities/user.dart';
import '../../../../domain/repositories/family_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/screens/profile_screen.dart';
import '../../auth/screens/link_child_screen.dart';
import '../../settings/screens/app_settings_screen.dart';
import '../../help/screens/help_support_screen.dart';
import '../../help/bloc/help_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../../../blocs/emergency_access/emergency_access_screen.dart';
import 'dart:math' as math;
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_bloc.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_event.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_state.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/app_monitor_bloc.dart';
import 'package:kidguardian/presentation/widgets/smart_lock/request_time_dialog.dart';
import 'package:kidguardian/data/models/app_time_limit_model.dart';

class ChildDashboard extends StatefulWidget {
  const ChildDashboard({super.key});

  @override
  State<ChildDashboard> createState() => _ChildDashboardState();
}

class _ChildDashboardState extends State<ChildDashboard> {
  int _currentIndex = 0;
  int _dailyLimitMinutes = 120; // Default 2 hours, will be updated from settings
  List<AppTimeLimitModel> _appLimits = [];

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

      if (authState.user.familyId != null) {
        context.read<SmartLockBloc>().add(
              LoadSmartLockSettings(
                authState.user.familyId!,
                authState.user.uid,
              ),
            );
        context.read<SmartLockBloc>().add(
              LoadAppTimeLimits(
                authState.user.familyId!,
                authState.user.uid,
              ),
            );
      }
    }
  }

  String _getAppName(String packageNameOrName) {
    const map = {
      'com.zhiliaoapp.musically': 'TikTok',
      'com.facebook.katana': 'Facebook',
      'com.google.android.youtube': 'YouTube',
      'com.instagram.android': 'Instagram',
      'com.zing.zalo': 'Zalo',
      'com.roblox.client': 'Roblox',
      'com.dts.freefireth': 'Free Fire',
    };
    return map[packageNameOrName] ?? packageNameOrName;
  }

  int _getAppLimitMinutes(String packageName) {
    AppTimeLimitModel? appLimit;
    for (final limit in _appLimits) {
      if (limit.appPackageName == packageName) {
        appLimit = limit;
        break;
      }
    }
    if (appLimit != null && appLimit.limits.isNotEmpty) {
      const dayKeys = [
        'monday', 'tuesday', 'wednesday', 'thursday',
        'friday', 'saturday', 'sunday',
      ];
      final dayOfWeek = dayKeys[DateTime.now().weekday - 1];
      if (appLimit.limits.containsKey(dayOfWeek)) {
        return appLimit.limits[dayOfWeek]!;
      }
      if (appLimit.limits.containsKey('everyday')) {
        return appLimit.limits['everyday']!;
      }
    }
    return _dailyLimitMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SmartLockBloc, SmartLockState>(
          listener: (context, state) {
            if (state is SmartLockSettingsLoaded && mounted) {
              setState(() {
                _dailyLimitMinutes = state.settings.defaultTimeLimitMinutes;
              });
            } else if (state is SmartLockLoaded && mounted) {
              setState(() {
                _appLimits = state.apps;
              });
            }
          },
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return Scaffold(
              appBar: AppBar(
                title: const Text(AppStrings.appName),
                automaticallyImplyLeading: false,
                backgroundColor: AppColors.childPrimary,
              ),
              body: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.childPrimary,
                ),
              ),
            );
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
          floatingActionButton: isLinked
              ? FloatingActionButton(
                  onPressed: () async {
                    if (user.familyId != null) {
                      final familyRepo = context.read<FamilyRepository>();
                      final family = await familyRepo.getFamily(user.familyId!);
                      if (family != null && mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EmergencyAccessScreen(
                              familyId: user.familyId!,
                              childUid: user.uid,
                              parentUid: family.parentUid,
                            ),
                          ),
                        );
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Không tìm thấy thông tin gia đình'),
                          ),
                        );
                      }
                    }
                  },
                  backgroundColor: Colors.red.shade600,
                  tooltip: 'Truy cập khẩn cấp',
                  child: const Icon(Icons.emergency, color: Colors.white),
                )
              : null,
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
    ),
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
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Nhập mã liên kết',
                    style: TextStyle(fontSize: 18),
                  ),
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
      builder: (context, dashboardState) {
        if (dashboardState is DashboardLoading || dashboardState is DashboardInitial) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.childPrimary,
            ),
          );
        }

        return BlocBuilder<AppMonitorBloc, AppMonitorState>(
          builder: (context, monitorState) {
            int totalToday = 0;
            Map<String, int> usageByApp = {};

            if (dashboardState is DashboardLoaded) {
              totalToday = dashboardState.totalMinutesToday;
              usageByApp = Map<String, int>.from(dashboardState.usageByApp);
            }

            // Đồng bộ dữ liệu thực tế đang đếm nếu có từ AppMonitorBloc
            if (monitorState is AppBlockedState) {
              final appPkg = monitorState.appPackageName;
              if (appPkg.isNotEmpty && monitorState.usedMinutes > (usageByApp[appPkg] ?? 0)) {
                final diff = monitorState.usedMinutes - (usageByApp[appPkg] ?? 0);
                usageByApp[appPkg] = monitorState.usedMinutes;
                totalToday += diff;
              }
            }

            if (dashboardState is DashboardLoaded || monitorState is AppBlockedState || monitorState is AppMonitorRunning) {
              return _buildHomeContent(user, totalToday, usageByApp);
            }

            return _buildHomeEmpty(user);
          },
        );
      },
    );
  }

  Widget _buildHomeContent(User user, int totalMinutesToday, Map<String, int> usageByApp) {
    final remainingMinutes = _dailyLimitMinutes - totalMinutesToday;
    final isOverLimit = remainingMinutes <= 0;
    final progress = _dailyLimitMinutes > 0 ? (totalMinutesToday / _dailyLimitMinutes) : 0.0;

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
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (user.familyId != null) {
                            showDialog(
                              context: context,
                              builder: (_) => RequestTimeDialog(
                                familyId: user.familyId!,
                                childUid: user.uid,
                                appPackageName: 'general_time',
                                appName: 'Thời gian sử dụng chung',
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.more_time, color: Colors.white),
                        label: const Text(
                          'Yêu cầu thêm thời gian',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.childPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Usage by app
            if (usageByApp.isNotEmpty) ...[
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
                        child: _buildPieChart(usageByApp),
                      ),
                      SizedBox(height: 16),
                      ...usageByApp.entries.take(5).map((entry) {
                        final appDisplayName = _getAppName(entry.key);
                        final usedMinutes = entry.value;
                        final limitMinutes = _getAppLimitMinutes(entry.key);
                        final remainingMinutes = math.max(0, limitMinutes - usedMinutes);
                        final isOverAppLimit = usedMinutes >= limitMinutes;
                        final progress = (limitMinutes > 0) ? (usedMinutes / limitMinutes).clamp(0.0, 1.0) : 1.0;

                        Color statusColor = AppColors.childPrimary;
                        if (isOverAppLimit || remainingMinutes == 0) {
                          statusColor = AppColors.error;
                        } else if (progress > 0.8 || remainingMinutes <= 10) {
                          statusColor = AppColors.warning;
                        }

                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    AppUtils.getAppIcon(appDisplayName),
                                    size: 26,
                                    color: AppUtils.getAppColor(appDisplayName),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          appDisplayName,
                                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          isOverAppLimit
                                              ? 'Đã hết giờ ($usedMinutes / $limitMinutes phút)'
                                              : 'Đã dùng: ${usedMinutes}p | Còn lại: ${remainingMinutes}p (Giới hạn: ${limitMinutes}p)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isOverAppLimit ? FontWeight.bold : FontWeight.normal,
                                            color: statusColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.add_circle_outline,
                                      color: AppColors.childPrimary,
                                      size: 24,
                                    ),
                                    tooltip: 'Xin thêm giờ cho app này',
                                    onPressed: () {
                                      if (user.familyId != null) {
                                        showDialog(
                                          context: context,
                                          builder: (_) => RequestTimeDialog(
                                            familyId: user.familyId!,
                                            childUid: user.uid,
                                            appPackageName: entry.key,
                                            appName: appDisplayName,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress.toDouble(),
                                  minHeight: 6,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ] else ...[
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
                        'Chưa có dữ liệu ứng dụng',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Hôm nay bạn chưa sử dụng ứng dụng nào. Hãy tiếp tục duy trì thói quen sử dụng điện thoại lành mạnh nhé! 🌟',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
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
                    'Hôm nay bạn chưa sử dụng ứng dụng nào. Bắt đầu sử dụng điện thoại để xem thống kê hoặc gửi yêu cầu thêm thời gian.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (user.familyId != null) {
                        showDialog(
                          context: context,
                          builder: (_) => RequestTimeDialog(
                            familyId: user.familyId!,
                            childUid: user.uid,
                            appPackageName: 'general_time',
                            appName: 'Thời gian sử dụng chung',
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.more_time, color: Colors.white),
                    label: const Text(
                      'Yêu cầu thêm thời gian',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.childPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        return _buildUsageEmpty(user);
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

  Widget _buildUsageEmpty(User user) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 40),
            Icon(
              Icons.bar_chart_rounded,
              size: 96,
              color: AppColors.childPrimary.withOpacity(0.5),
            ),
            SizedBox(height: 24),
            Text(
              'Thống kê sử dụng hôm nay',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Hôm nay bạn chưa sử dụng ứng dụng nào hoặc dữ liệu đang được đồng bộ từ thiết bị.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                if (user.familyId != null) {
                  showDialog(
                    context: context,
                    builder: (_) => RequestTimeDialog(
                      familyId: user.familyId!,
                      childUid: user.uid,
                      appPackageName: 'general_time',
                      appName: 'Thời gian sử dụng chung',
                    ),
                  );
                }
              },
              icon: const Icon(Icons.more_time, color: Colors.white),
              label: const Text(
                'Yêu cầu thêm thời gian',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.childPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
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
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                AppStrings.logout,
                style: TextStyle(color: AppColors.error),
              ),
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
