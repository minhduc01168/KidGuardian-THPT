import 'package:flutter/material.dart';

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String roleSelection = '/role-selection';
  static const String parentDashboard = '/parent-dashboard';
  static const String childDashboard = '/child-dashboard';
  static const String profile = '/profile';
  static const String changePassword = '/change-password';
  static const String createChild = '/create-child';
  static const String linkChild = '/link-child';
  static const String familyManagement = '/family-management';
  static const String appSettings = '/app-settings';
  static const String helpSupport = '/help-support';
  static const String faq = '/faq';
  static const String contactSupport = '/contact-support';
  static const String appInfo = '/app-info';
  static const String legalDocuments = '/legal-documents';
  static const String usageStatistics = '/usage-statistics';
  static const String weeklyReport = '/weekly-report';
  static const String dailySummary = '/daily-summary';
  static const String notificationCenter = '/notification-center';
  static const String notificationHistory = '/notification-history';
  static const String smartLockSettings = '/smart-lock-settings';
  static const String timeLimit = '/time-limit';
  static const String schedule = '/schedule';
  static const String scheduleForm = '/schedule-form';
  static const String blockedApps = '/blocked-apps';
  static const String lockHistory = '/lock-history';
  static const String lockScreen = '/lock-screen';
  static const String alertHistory = '/alert-history';
  static const String alertDetail = '/alert-detail';
  static const String keywordManagement = '/keyword-management';
  static const String timeRequestApproval = '/time-request-approval';
  static const String timeRequestStatus = '/time-request-status';
  static const String requestHistory = '/request-history';
  static const String autoApprovalRules = '/auto-approval-rules';
  static const String emergencyAccess = '/emergency-access';
  static const String emergencyHistory = '/emergency-history';
  static const String appUsageDetail = '/app-usage-detail';
}

class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<T?> push<T>(Widget screen, {String? routeName}) {
    return navigatorKey.currentState!.push<T>(
      MaterialPageRoute(
        builder: (_) => screen,
        settings: RouteSettings(name: routeName),
      ),
    );
  }

  static Future<T?> pushReplacement<T>(Widget screen, {String? routeName}) {
    return navigatorKey.currentState!.pushReplacement<T, void>(
      MaterialPageRoute(
        builder: (_) => screen,
        settings: RouteSettings(name: routeName),
      ),
    );
  }

  static Future<T?> pushAndRemoveAll<T>(Widget screen, {String? routeName}) {
    return navigatorKey.currentState!.pushAndRemoveUntil<T>(
      MaterialPageRoute(
        builder: (_) => screen,
        settings: RouteSettings(name: routeName),
      ),
      (route) => false,
    );
  }

  static void pop<T>([T? result]) {
    navigatorKey.currentState!.pop<T>(result);
  }

  static void popUntil(String routeName) {
    navigatorKey.currentState!.popUntil(
      (route) => route.settings.name == routeName,
    );
  }

  static bool canPop() {
    return navigatorKey.currentState!.canPop();
  }
}
