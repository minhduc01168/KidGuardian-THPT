import 'package:flutter/material.dart';
import '../bloc/usage_statistics_state.dart';
import '../utils/usage_statistics_helper.dart';

class MostUsedAppsList extends StatelessWidget {
  final List<AppUsageSummary> mostUsedApps;
  final Function(AppUsageSummary)? onAppTap;
  final Map<String, int>? appLimits;
  final int? dailyLimitMinutes;

  const MostUsedAppsList({
    super.key,
    required this.mostUsedApps,
    this.onAppTap,
    this.appLimits,
    this.dailyLimitMinutes,
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
        final limitMinutes = (appLimits != null && appLimits!.containsKey(app.appPackage))
            ? appLimits![app.appPackage]!
            : (dailyLimitMinutes ?? 120);
        final usedMinutes = app.totalMinutes;
        final remainingMinutes = (limitMinutes - usedMinutes).clamp(0, 99999);
        final isOverLimit = usedMinutes >= limitMinutes;
        final progress = (limitMinutes > 0) ? (usedMinutes / limitMinutes).clamp(0.0, 1.0) : 1.0;

        Color statusColor = Theme.of(context).primaryColor;
        if (isOverLimit || remainingMinutes == 0) {
          statusColor = Colors.red;
        } else if (progress > 0.8 || remainingMinutes <= 10) {
          statusColor = Colors.orange;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
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
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      '${app.sessionCount} lần mở • Trung bình ${UsageStatisticsHelper.formatDuration(app.avgMinutesPerSession)}/lần',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOverLimit
                          ? 'Đã hết giới hạn (${UsageStatisticsHelper.formatDuration(usedMinutes)} / ${UsageStatisticsHelper.formatDuration(limitMinutes)})'
                          : 'Đã dùng: ${UsageStatisticsHelper.formatDuration(usedMinutes)} | Còn lại: ${UsageStatisticsHelper.formatDuration(remainingMinutes)} (Giới hạn: ${UsageStatisticsHelper.formatDuration(limitMinutes)})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isOverLimit ? FontWeight.bold : FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ],
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
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.toDouble(),
                  minHeight: 5,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
