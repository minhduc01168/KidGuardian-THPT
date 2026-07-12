import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppUtils {
  static const Map<String, String> _appNameMap = {
    'com.zhiliaoapp.musically': 'TikTok',
    'com.facebook.katana': 'Facebook',
    'com.facebook.orca': 'Messenger',
    'com.google.android.youtube': 'YouTube',
    'com.instagram.android': 'Instagram',
    'com.zing.zalo': 'Zalo',
    'com.roblox.client': 'Roblox',
    'com.dts.freefireth': 'Free Fire',
    'com.garena.game.kgvn': 'Liên Quân Mobile',
    'com.ss.android.ugc.trill': 'TikTok',
    'com.android.chrome': 'Google Chrome',
    'com.google.android.gm': 'Gmail',
    'com.google.android.apps.maps': 'Google Maps',
    'org.telegram.messenger': 'Telegram',
    'com.lemon.lvoverseas': 'CapCut',
    'com.shopee.vn': 'Shopee',
    'com.mservice.momotransfer': 'MoMo',
    'TikTok': 'TikTok',
    'Facebook': 'Facebook',
    'YouTube': 'YouTube',
    'Instagram': 'Instagram',
    'Zalo': 'Zalo',
    'Roblox': 'Roblox',
    'Free Fire': 'Free Fire',
    'Messenger': 'Messenger',
    'Google Chrome': 'Google Chrome',
    'Gmail': 'Gmail',
  };

  static String getAppNameFromLog(String appPackage, String appName) {
    if (_appNameMap.containsKey(appPackage)) {
      return _appNameMap[appPackage]!;
    }
    if (appName.isNotEmpty && !appName.contains('.')) {
      return appName;
    }
    return getAppName(appPackage.isNotEmpty ? appPackage : appName);
  }

  static String getAppName(String packageOrName) {
    if (packageOrName.isEmpty) return 'Ứng dụng không xác định';
    if (_appNameMap.containsKey(packageOrName)) {
      return _appNameMap[packageOrName]!;
    }
    if (packageOrName.contains('.')) {
      final parts = packageOrName.split('.');
      String lastPart = parts.last;
      if (lastPart.toLowerCase() == 'android' || lastPart.toLowerCase() == 'client' || lastPart.toLowerCase() == 'app') {
        if (parts.length > 1) {
          lastPart = parts[parts.length - 2];
        }
      }
      if (lastPart.isNotEmpty) {
        final cleaned = lastPart.replaceAll('_', ' ').replaceAll('-', ' ');
        return cleaned.split(' ').map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join(' ').trim();
      }
    }
    return packageOrName;
  }

  static bool isSystemOrUnmonitoredApp(String packageName) {
    if (packageName.isEmpty) return true;
    final lower = packageName.toLowerCase();
    const systemExact = {
      'com.android.systemui',
      'com.google.android.googlequicksearchbox',
      'com.android.launcher',
      'com.android.launcher2',
      'com.android.launcher3',
      'com.google.android.apps.nexuslauncher',
      'com.sec.android.app.launcher',
      'com.huawei.android.launcher',
      'com.miui.home',
      'com.android.inputmethod.latin',
      'com.google.android.inputmethod.latin',
      'com.android.inputmethod.lazyswipe',
      'com.android.settings',
      'com.android.vending',
      'com.google.android.packageinstaller',
      'com.android.packageinstaller',
      'com.google.android.permissioncontroller',
      'com.android.permissioncontroller',
      'android',
    };
    if (systemExact.contains(lower)) return true;
    if (lower.startsWith('com.android.') && !lower.contains('kidguardian') && !lower.contains('chrome')) {
      return true;
    }
    if (lower.startsWith('com.google.android.inputmethod')) return true;
    if (lower.contains('permissioncontroller') || lower.contains('packageinstaller')) return true;
    return false;
  }

  static Color getAppColor(String packageOrName) {
    final name = getAppName(packageOrName);
    final colors = {
      'TikTok': Colors.black,
      'Facebook': const Color(0xFF1877F2),
      'Messenger': const Color(0xFF00B2FF),
      'Instagram': const Color(0xFFE4405F),
      'YouTube': const Color(0xFFFF0000),
      'Zalo': const Color(0xFF0068FF),
      'Roblox': const Color(0xFFE50914),
      'Free Fire': const Color(0xFFFF9900),
      'Google Chrome': const Color(0xFF4285F4),
    };
    return colors[name] ?? AppColors.primary;
  }

  static IconData getAppIcon(String packageOrName) {
    final name = getAppName(packageOrName);
    final icons = {
      'TikTok': Icons.music_note,
      'Facebook': Icons.facebook,
      'Messenger': Icons.chat_bubble,
      'Instagram': Icons.camera_alt,
      'YouTube': Icons.play_circle_filled,
      'Zalo': Icons.chat,
      'Roblox': Icons.gamepad,
      'Free Fire': Icons.sports_esports,
      'Google Chrome': Icons.public,
    };
    return icons[name] ?? Icons.apps;
  }

  static String formatMinutes(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      if (m == 0) return '${h}h';
      return '${h}h ${m}p';
    }
    return '${minutes}p';
  }
}
