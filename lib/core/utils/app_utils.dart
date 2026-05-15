import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppUtils {
  static Color getAppColor(String appName) {
    final colors = {
      'TikTok': Colors.black,
      'Facebook': const Color(0xFF1877F2),
      'Instagram': const Color(0xFFE4405F),
      'YouTube': const Color(0xFFFF0000),
      'Zalo': const Color(0xFF0068FF),
    };
    return colors[appName] ?? AppColors.primary;
  }

  static IconData getAppIcon(String appName) {
    final icons = {
      'TikTok': Icons.music_note,
      'Facebook': Icons.facebook,
      'Instagram': Icons.camera_alt,
      'YouTube': Icons.play_circle_filled,
      'Zalo': Icons.chat,
    };
    return icons[appName] ?? Icons.apps;
  }
}
