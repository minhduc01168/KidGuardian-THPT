import 'package:kidguardian/platform/android/accessibility_channel.dart';

/// BlockAppUseCase — FIX C2
///
/// Thêm startMonitoring() để khởi động ForegroundService khi bật Smart Lock.
/// Logic block/unblock không đổi — chỉ thêm hook vào service lifecycle.
class BlockAppUseCase {
  final Set<String> _blockedApps = {};

  Set<String> get blockedApps => Set.unmodifiable(_blockedApps);

  /// Khởi động MonitorForegroundService — gọi khi parent bật Smart Lock
  Future<void> startMonitoring() async {
    await AccessibilityChannel.startMonitorService();
  }

  /// Dừng MonitorForegroundService — gọi khi parent tắt Smart Lock
  Future<void> stopMonitoring() async {
    await AccessibilityChannel.stopMonitorService();
  }

  /// Thêm app vào danh sách khoá và cập nhật Native
  Future<void> execute({required String appPackageName}) async {
    _blockedApps.add(appPackageName);
    await AccessibilityChannel.updateBlockedApps(_blockedApps.toList());
  }

  /// Xoá app khỏi danh sách khoá (khi được duyệt thêm giờ)
  Future<void> unblockApp({required String appPackageName}) async {
    _blockedApps.remove(appPackageName);
    await AccessibilityChannel.updateBlockedApps(_blockedApps.toList());
  }

  /// FIX C2: Ép thiết bị về Home Screen (thay thế moveTaskToBack)
  Future<void> forceGoHome() async {
    await AccessibilityChannel.moveToHome();
  }

  /// Xoá toàn bộ app bị khoá
  Future<void> unblockAll() async {
    _blockedApps.clear();
    await AccessibilityChannel.updateBlockedApps([]);
  }

  /// Load danh sách app bị khoá từ Firestore khi khởi động
  void loadBlockedApps(List<String> apps) {
    _blockedApps.clear();
    _blockedApps.addAll(apps);
  }
}
