import 'package:kidguardian/platform/android/accessibility_channel.dart';

class BlockAppUseCase {
  final Set<String> _blockedApps = {};

  Set<String> get blockedApps => Set.unmodifiable(_blockedApps);

  Future<void> execute({required String appPackageName}) async {
    _blockedApps.add(appPackageName);
    await AccessibilityChannel.updateBlockedApps(_blockedApps.toList());
  }

  Future<void> unblockApp({required String appPackageName}) async {
    _blockedApps.remove(appPackageName);
    await AccessibilityChannel.updateBlockedApps(_blockedApps.toList());
  }

  Future<void> unblockAll() async {
    _blockedApps.clear();
    await AccessibilityChannel.updateBlockedApps([]);
  }

  void loadBlockedApps(List<String> apps) {
    _blockedApps.clear();
    _blockedApps.addAll(apps);
  }
}
