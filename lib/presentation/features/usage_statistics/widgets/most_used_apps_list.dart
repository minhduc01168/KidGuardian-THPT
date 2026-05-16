import 'package:flutter/material.dart';
import '../bloc/usage_statistics_state.dart';
import '../utils/usage_statistics_helper.dart';

class MostUsedAppsList extends StatelessWidget {
  final List<AppUsageSummary> mostUsedApps;
  final Function(AppUsageSummary)? onAppTap;

  const MostUsedAppsList({
    super.key,
    required this.mostUsedApps,
    this.onAppTap,
  });

  @override
  Widget build(BuildContext context) {
    if (mostUsedApps.isEmpty) {
      return const Center(
        child: Text('Không có dữ liệu'),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mostUsedApps.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final app = mostUsedApps[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            app.appName,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            '${app.sessionCount} lần mở • Trung bình ${UsageStatisticsHelper.formatDuration(app.avgMinutesPerSession)}/lần',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                UsageStatisticsHelper.formatDuration(app.totalMinutes),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                '${app.percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          onTap: onAppTap != null ? () => onAppTap!(app) : null,
        );
      },
    );
  }
}
