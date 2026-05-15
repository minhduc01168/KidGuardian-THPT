import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_utils.dart';

class AppUsageListWidget extends StatelessWidget {
  final Map<String, int> usageByApp;
  final Function(String appName, int minutes)? onAppTap;

  const AppUsageListWidget({
    super.key,
    required this.usageByApp,
    this.onAppTap,
  });

  @override
  Widget build(BuildContext context) {
    if (usageByApp.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.apps,
                size: 48,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 16),
              Text(
                'Chưa có dữ liệu sử dụng',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sortedEntries = usageByApp.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalMinutes = usageByApp.values.fold(0, (sum, val) => sum + val);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ứng dụng đã sử dụng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${sortedEntries.length} ứng dụng',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: sortedEntries.length,
            separatorBuilder: (context, index) => Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final entry = sortedEntries[index];
              final percent = totalMinutes > 0
                  ? (entry.value / totalMinutes * 100)
                  : 0;
              final hours = entry.value ~/ 60;
              final minutes = entry.value % 60;
              final timeStr = hours > 0
                  ? '$hours giờ $minutes phút'
                  : '$minutes phút';

              return _AppUsageTile(
                appName: entry.key,
                minutes: entry.value,
                timeStr: timeStr,
                percent: percent.toDouble(),
                rank: index + 1,
                onTap: onAppTap != null
                    ? () => onAppTap!(entry.key, entry.value)
                    : null,
              );
            },
          ),
          if (totalMinutes > 0)
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tổng cộng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${totalMinutes ~/ 60} giờ ${totalMinutes % 60} phút',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AppUsageTile extends StatelessWidget {
  final String appName;
  final int minutes;
  final String timeStr;
  final double percent;
  final int rank;
  final VoidCallback? onTap;

  const _AppUsageTile({
    required this.appName,
    required this.minutes,
    required this.timeStr,
    required this.percent,
    required this.rank,
    this.onTap,
  });

  Color _getRankColor() {
    switch (rank) {
      case 1:
        return Color(0xFFFFD700); // Gold
      case 2:
        return Color(0xFFC0C0C0); // Silver
      case 3:
        return Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Rank badge
            if (rank <= 3)
              Container(
                width: 24,
                height: 24,
                margin: EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: _getRankColor().withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getRankColor(),
                    ),
                  ),
                ),
              )
            else
              SizedBox(width: 36),

            // App icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppUtils.getAppColor(appName).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                AppUtils.getAppIcon(appName),
                color: AppUtils.getAppColor(appName),
                size: 24,
              ),
            ),
            SizedBox(width: 12),

            // App info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percent / 100,
                            backgroundColor: AppColors.divider.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppUtils.getAppColor(appName),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '${percent.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),

            // Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            if (onTap != null) ...[
              SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
