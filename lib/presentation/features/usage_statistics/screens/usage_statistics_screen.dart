import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/usage_statistics_bloc.dart';
import '../bloc/usage_statistics_event.dart';
import '../bloc/usage_statistics_state.dart';
import '../widgets/hourly_usage_chart.dart';
import '../widgets/daily_usage_chart.dart';
import '../widgets/weekly_usage_chart.dart';
import '../widgets/app_usage_pie_chart.dart';
import '../widgets/most_used_apps_list.dart';
import '../widgets/peak_usage_card.dart';
import '../widgets/date_range_selector.dart';

class UsageStatisticsScreen extends StatelessWidget {
  final String childUid;
  final String childName;

  const UsageStatisticsScreen({
    super.key,
    required this.childUid,
    required this.childName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UsageStatisticsBloc(
        usageRepository: context.read(),
      )..add(LoadUsageStats(
          childUid: childUid,
          startDate: DateTime.now().subtract(const Duration(days: 7)),
          endDate: DateTime.now(),
        )),
      child: _UsageStatisticsView(
        childUid: childUid,
        childName: childName,
      ),
    );
  }
}

class _UsageStatisticsView extends StatelessWidget {
  final String childUid;
  final String childName;

  const _UsageStatisticsView({
    required this.childUid,
    required this.childName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thống kê sử dụng - $childName'),
        actions: [
          BlocBuilder<UsageStatisticsBloc, UsageStatisticsState>(
            builder: (context, state) {
              if (state is UsageStatisticsLoaded) {
                return PopupMenuButton<ExportFormat>(
                  icon: const Icon(Icons.file_download),
                  tooltip: 'Xuất dữ liệu',
                  onSelected: (format) {
                    context.read<UsageStatisticsBloc>().add(ExportUsageData(
                          childUid: childUid,
                          startDate: state.startDate,
                          endDate: state.endDate,
                          format: format,
                        ));
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: ExportFormat.csv,
                      child: Text('Xuất file CSV'),
                    ),
                    const PopupMenuItem(
                      value: ExportFormat.pdf,
                      child: Text('Xuất file PDF'),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<UsageStatisticsBloc, UsageStatisticsState>(
        listener: (context, state) {
          if (state is UsageDataExported) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Đã xuất dữ liệu ${state.format == ExportFormat.csv ? "CSV" : "PDF"} thành công',
                ),
              ),
            );
          } else if (state is UsageStatisticsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is UsageStatisticsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is UsageStatisticsLoaded) {
            return _buildContent(context, state);
          }

          if (state is UsageStatisticsInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          return const Center(
            child: Text('Không có dữ liệu'),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, UsageStatisticsLoaded state) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DateRangeSelector(
              startDate: state.startDate,
              endDate: state.endDate,
              onDateRangeChanged: (start, end) {
                context.read<UsageStatisticsBloc>().add(SelectDateRange(
                      childUid: childUid,
                      startDate: start,
                      endDate: end,
                    ));
              },
            ),
          ),
          TabBar(
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            onTap: (index) {
              final periods = [
                TimePeriod.hour,
                TimePeriod.day,
                TimePeriod.week
              ];
              context.read<UsageStatisticsBloc>().add(ChangeTimePeriod(
                    childUid: childUid,
                    period: periods[index],
                  ));
            },
            tabs: const [
              Tab(text: 'Giờ'),
              Tab(text: 'Ngày'),
              Tab(text: 'Tuần'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildHourlyTab(context, state),
                _buildDailyTab(context, state),
                _buildWeeklyTab(context, state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyTab(BuildContext context, UsageStatisticsLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sử dụng theo giờ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          HourlyUsageChart(hourlyUsage: state.hourlyUsage),
          const SizedBox(height: 16),
          PeakUsageCard(
            peakHours: state.peakHours,
            peakDay: state.peakDay,
            totalMinutes: state.totalMinutes,
          ),
          const SizedBox(height: 16),
          const Text(
            'Ứng dụng sử dụng nhiều nhất',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          MostUsedAppsList(mostUsedApps: state.mostUsedApps),
        ],
      ),
    );
  }

  Widget _buildDailyTab(BuildContext context, UsageStatisticsLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Xu hướng theo ngày',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DailyUsageChart(dailyUsage: state.dailyUsage),
          const SizedBox(height: 16),
          const Text(
            'Phân bổ theo ứng dụng',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          AppUsagePieChart(usageByApp: state.usageByApp),
          const SizedBox(height: 16),
          PeakUsageCard(
            peakHours: state.peakHours,
            peakDay: state.peakDay,
            totalMinutes: state.totalMinutes,
          ),
          const SizedBox(height: 16),
          const Text(
            'Ứng dụng sử dụng nhiều nhất',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          MostUsedAppsList(mostUsedApps: state.mostUsedApps),
        ],
      ),
    );
  }

  Widget _buildWeeklyTab(BuildContext context, UsageStatisticsLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sử dụng theo tuần',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          WeeklyUsageChart(weeklyUsage: state.weeklyUsage),
          const SizedBox(height: 16),
          const Text(
            'Phân bổ theo ứng dụng',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          AppUsagePieChart(usageByApp: state.usageByApp),
          const SizedBox(height: 16),
          PeakUsageCard(
            peakHours: state.peakHours,
            peakDay: state.peakDay,
            totalMinutes: state.totalMinutes,
          ),
          const SizedBox(height: 16),
          const Text(
            'Ứng dụng sử dụng nhiều nhất',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          MostUsedAppsList(mostUsedApps: state.mostUsedApps),
        ],
      ),
    );
  }
}
