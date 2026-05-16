import 'package:kidguardian/data/models/app_time_limit_model.dart';
import 'package:kidguardian/domain/repositories/usage_repository.dart';
import 'package:kidguardian/data/repositories/smart_lock_repository.dart';
import 'package:intl/intl.dart';

class CheckAppAccessUseCase {
  final UsageRepository usageRepository;
  final SmartLockRepository smartLockRepository;

  static const _dayKeys = [
    'monday', 'tuesday', 'wednesday', 'thursday',
    'friday', 'saturday', 'sunday',
  ];

  CheckAppAccessUseCase({
    required this.usageRepository,
    required this.smartLockRepository,
  });

  String _getDayOfWeekKey(DateTime date) {
    // DateTime.weekday: 1=Monday, 7=Sunday
    return _dayKeys[date.weekday - 1];
  }

  int _getAllowedMinutes(AppTimeLimitModel appLimit, String dayOfWeek) {
    final limits = appLimit.limits;
    if (limits.isEmpty) return -1;

    // P8: Day-specific takes priority over everyday
    if (limits.containsKey(dayOfWeek)) {
      return limits[dayOfWeek]!;
    }
    if (limits.containsKey('everyday')) {
      return limits['everyday']!;
    }
    return -1;
  }

  Future<bool> execute({
    required String familyId,
    required String childUid,
    required String appPackageName,
  }) async {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);

    final limits = await smartLockRepository.getAppTimeLimits(familyId, childUid);
    AppTimeLimitModel? appLimit;
    for (final limit in limits) {
      if (limit.appPackageName == appPackageName) {
        appLimit = limit;
        break;
      }
    }

    if (appLimit == null || appLimit.limits.isEmpty) {
      return true;
    }

    // P7: Use weekday index instead of locale-dependent DateFormat
    final dayOfWeek = _getDayOfWeekKey(now);

    final allowedMinutes = _getAllowedMinutes(appLimit, dayOfWeek);
    if (allowedMinutes < 0) {
      return true; // No limit for today
    }

    final appUsages = await usageRepository.getUsageByApp(childUid, dateStr);
    final usedMinutes = appUsages[appPackageName] ?? 0;

    return usedMinutes < allowedMinutes;
  }
}
