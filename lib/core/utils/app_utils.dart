import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppUtils {
  /// Danh sách package tuyệt đối KHÔNG được giám sát:
  /// bao gồm chính KidGuardian app và các monitoring tool bên thứ ba.
  static const Set<String> _selfExcludedPackages = {
    'com.kidguardian.kidguardian',
    'com.preff.kb.xm',
  };
  static const Map<String, String> _appNameMap = {
    'com.zhiliaoapp.musically': 'TikTok',
    'com.ss.android.ugc.trill': 'TikTok',
    'com.facebook.katana': 'Facebook',
    'com.instagram.android': 'Instagram',
    'com.zing.zalo': 'Zalo',
    'com.google.android.youtube': 'YouTube',
    'com.instagram.barcelona': 'Threads',
    'com.locket.Locket': 'Locket',
    'com.locket.locket': 'Locket',
    'com.discord': 'Discord',
    
    // Giữ lại các alias phòng trường hợp hiển thị log cũ
    'com.facebook.orca': 'Messenger',
    'com.android.chrome': 'Google Chrome',
    'com.google.android.gm': 'Gmail',
    'com.google.android.apps.maps': 'Google Maps',
    'TikTok': 'TikTok',
    'Facebook': 'Facebook',
    'Instagram': 'Instagram',
    'Zalo': 'Zalo',
    'YouTube': 'YouTube',
    'Threads': 'Threads',
    'Locket': 'Locket',
    'Discord': 'Discord',
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
    // BUG-5 FIX: Trả về packageOrName thay vì "không xác định" khi rỗng
    if (packageOrName.isEmpty) return packageOrName;
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

  // FIX GAP 1: Danh sách 8 ứng dụng MXH cố định được phép giám sát
  static const Set<String> _hardcodedSocialApps = {
    'com.facebook.katana', // Facebook
    'facebook',
    'com.zhiliaoapp.musically', // TikTok
    'com.ss.android.ugc.trill', // TikTok (thị trường khác)
    'tiktok',
    'com.instagram.android', // Instagram
    'instagram',
    'com.zing.zalo', // Zalo
    'zalo',
    'com.google.android.youtube', // YouTube
    'youtube',
    'com.instagram.barcelona', // Threads
    'threads',
    'com.locket.locket', // Locket
    'locket',
    'com.discord', // Discord
    'discord',
    'com.facebook.orca', // Messenger
    'messenger',
    'org.telegram.messenger', // Telegram
    'telegram',
  };

  static bool isSystemOrUnmonitoredApp(String packageName) {
    if (packageName.isEmpty) return true;
    final lower = packageName.toLowerCase();

    // 0. Self-excluded: KidGuardian app và monitoring tools không được giám sát
    if (_selfExcludedPackages.contains(lower)) return true;

    // 1. Allow-list khắt khe: CHỈ 8 ứng dụng MXH này mới trả về false (Được giám sát)
    if (_hardcodedSocialApps.contains(lower)) {
      return false;
    }

    // 2. Mọi ứng dụng khác (kể cả game, chrome, hệ thống) đều KHÔNG được hiển thị 
    // trong danh sách quản lý thời gian và báo cáo thống kê.
    return true;
  }

  static Color getAppColor(String packageOrName) {
    final name = getAppName(packageOrName);
    final colors = {
      'TikTok': Colors.black,
      'Facebook': const Color(0xFF1877F2),
      'Instagram': const Color(0xFFE4405F),
      'Zalo': const Color(0xFF0068FF),
      'YouTube': const Color(0xFFFF0000),
      'Threads': const Color(0xFF000000),
      'Locket': const Color(0xFFFFB800),
      'Discord': const Color(0xFF5865F2),
    };
    return colors[name] ?? AppColors.primary;
  }

  static IconData getAppIcon(String packageOrName) {
    final name = getAppName(packageOrName);
    final icons = {
      'TikTok': Icons.music_note,
      'Facebook': Icons.facebook,
      'Instagram': Icons.camera_alt,
      'Zalo': Icons.chat,
      'YouTube': Icons.play_circle_filled,
      'Threads': Icons.alternate_email,
      'Locket': Icons.lock,
      'Discord': Icons.discord,
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
