import 'package:flutter/material.dart';

class AppColors {
  // Primary - Gradient tím xanh hiện đại
  static const Color primary = Color(0xFF6B7FE8);
  static const Color primaryDark = Color(0xFF5A6BD4);
  static const Color primaryLight = Color(0xFF8B9BF0);
  static const Color accent = Color(0xFF9B6BCC);
  
  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6B7FE8), Color(0xFF9B6BCC)],
  );
  
  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8A65), Color(0xFFFF7043)],
  );
  
  // Background colors
  static const Color background = Color(0xFFF8F9FE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F9);
  
  // Text colors
  static const Color textPrimary = Color(0xFF1A1D2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  
  // Status colors
  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF42A5F5);
  
  // Divider
  static const Color divider = Color(0xFFE5E7EB);
  
  // Shadow
  static const Color shadow = Color(0x1A000000);
  
  // Child theme colors - Cam ấm áp
  static const Color childPrimary = Color(0xFFFF8A65);
  static const Color childPrimaryDark = Color(0xFFFF7043);
  static const Color childBackground = Color(0xFFFFF8F5);
  static const Color childSurface = Color(0xFFFFF3E0);
  
  // Card colors
  static const Color cardBlue = Color(0xFFE3F2FD);
  static const Color cardGreen = Color(0xFFE8F5E9);
  static const Color cardOrange = Color(0xFFFFF3E0);
  static const Color cardPurple = Color(0xFFF3E5F5);
  static const Color cardRed = Color(0xFFFFEBEE);
  
  // Icon colors
  static const Color iconBlue = Color(0xFF42A5F5);
  static const Color iconGreen = Color(0xFF66BB6A);
  static const Color iconOrange = Color(0xFFFF9800);
  static const Color iconPurple = Color(0xFFAB47BC);
  static const Color iconRed = Color(0xFFEF5350);
}
