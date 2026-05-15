import 'package:flutter/material.dart';
import 'package:kidguardian/data/models/app_time_limit_model.dart';

class AppLimitItem extends StatelessWidget {
  final AppTimeLimitModel app;
  final VoidCallback onTap;

  const AppLimitItem({
    super.key,
    required this.app,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasLimit = app.limits.isNotEmpty;
    String limitText = 'Chưa cài đặt';
    if (hasLimit) {
      if (app.limits.containsKey('everyday')) {
        limitText = '${app.limits['everyday']} phút / ngày';
      } else {
        limitText = 'Tùy chỉnh theo ngày';
      }
    }

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade200,
        child: const Icon(Icons.apps), // Fallback icon since we don't have real app icons loaded yet
      ),
      title: Text(app.appName, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        limitText,
        style: TextStyle(
          color: hasLimit ? Colors.green : Colors.grey,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
