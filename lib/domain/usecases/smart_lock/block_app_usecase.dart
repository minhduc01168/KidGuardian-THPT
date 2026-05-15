import 'package:kidguardian/platform/android/accessibility_channel.dart';

class BlockAppUseCase {
  Future<void> execute({required String appPackageName}) async {
    // Notify native layer to block the app
    await AccessibilityChannel.updateBlockedApps([appPackageName]);
  }

  Future<void> unblockApp({required String appPackageName}) async {
    // We would need to update the list of blocked apps without this one,
    // but for now we just send an empty list assuming only one is blocked,
    // or we'd maintain the state of all blocked apps.
    // Assuming we want to clear blocks:
    await AccessibilityChannel.updateBlockedApps([]);
  }
}
