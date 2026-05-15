import 'package:kidguardian/data/models/app_time_limit_model.dart';
import 'package:kidguardian/domain/repositories/usage_repository.dart';
import 'package:kidguardian/data/repositories/smart_lock_repository.dart';
import 'package:intl/intl.dart';

class CheckAppAccessUseCase {
  final UsageRepository usageRepository;
  final SmartLockRepository smartLockRepository;

  CheckAppAccessUseCase({
    required this.usageRepository,
    required this.smartLockRepository,
  });

  Future<bool> execute({
    required String familyId,
    required String childUid,
    required String appPackageName,
  }) async {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    
    // Get time limits
    final limits = await smartLockRepository.getAppTimeLimits(familyId, childUid);
    AppTimeLimitModel? appLimit;
    for (final limit in limits) {
      if (limit.appPackageName == appPackageName) {
        appLimit = limit;
        break;
      }
    }

    if (appLimit == null || appLimit.limits.isEmpty) {
      return true; // No limits set for this app
    }

    // Get today's day of week (monday, tuesday, etc.) or check everyday
    final dayOfWeek = DateFormat('EEEE').format(now).toLowerCase();
    
    int allowedMinutes = 0;
    if (appLimit.limits.containsKey('everyday')) {
      allowedMinutes = appLimit.limits['everyday']!;
    } else if (appLimit.limits.containsKey(dayOfWeek)) {
      allowedMinutes = appLimit.limits[dayOfWeek]!;
    } else {
      return true; // No limit for today
    }

    // Get current usage
    final appUsages = await usageRepository.getUsageByApp(childUid, dateStr);
    final usedMinutes = appUsages[appPackageName] ?? 0; // The map key is appName, we might need to change it to appPackageName in repository.
    
    return usedMinutes < allowedMinutes;
  }
}
