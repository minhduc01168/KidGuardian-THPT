import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_routes.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/family_repository_impl.dart';
import 'data/repositories/report_repository_impl.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'data/repositories/summary_repository_impl.dart';
import 'data/repositories/usage_repository_impl.dart';
import 'data/services/background_message_handler.dart';
import 'data/services/notification_service.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/family_repository.dart';
import 'domain/repositories/report_repository.dart';
import 'domain/repositories/settings_repository.dart';
import 'domain/repositories/summary_repository.dart';
import 'domain/repositories/usage_repository.dart';
import 'domain/usecases/smart_lock/check_app_access_usecase.dart';
import 'domain/usecases/smart_lock/block_app_usecase.dart';
import 'domain/usecases/smart_lock/schedule_checker.dart';
import 'presentation/features/auth/bloc/auth_bloc.dart';
import 'presentation/features/auth/bloc/auth_state.dart';
import 'presentation/features/auth/bloc/family_bloc.dart';
import 'presentation/features/auth/screens/role_selection_screen.dart';
import 'presentation/features/auth/screens/splash_screen.dart';
import 'presentation/features/dashboard/bloc/dashboard_bloc.dart';
import 'presentation/features/dashboard/screens/parent_dashboard.dart';
import 'presentation/features/dashboard/screens/child_dashboard.dart';
import 'presentation/features/report/bloc/report_bloc.dart';
import 'presentation/features/settings/bloc/settings_bloc.dart';
import 'presentation/features/settings/bloc/settings_event.dart';
import 'presentation/features/settings/bloc/settings_state.dart';
import 'presentation/features/summary/bloc/summary_bloc.dart';
import 'presentation/blocs/smart_lock/app_monitor_bloc.dart';
import 'presentation/blocs/notification/notification_bloc.dart';
import 'presentation/blocs/in_app_notification/in_app_notification_bloc.dart';
import 'presentation/screens/smart_lock/lock_screen.dart';
import 'data/repositories/smart_lock_repository.dart';
import 'data/repositories/help_repository_impl.dart';
import 'domain/repositories/alert_repository.dart';
import 'domain/repositories/notification_repository.dart';
import 'domain/repositories/time_request_repository.dart';
import 'domain/repositories/help_repository.dart';
import 'domain/entities/user.dart';
import 'presentation/features/help/bloc/help_bloc.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await firebaseMessagingBackgroundHandler(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const KidGuardianApp());
}

class KidGuardianApp extends StatelessWidget {
  const KidGuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (_) => AuthRepositoryImpl(),
        ),
        RepositoryProvider<FamilyRepository>(
          create: (_) => FamilyRepositoryImpl(),
        ),
        RepositoryProvider<UsageRepository>(
          create: (_) => UsageRepositoryImpl(),
        ),
        RepositoryProvider<SummaryRepository>(
          create: (context) => SummaryRepositoryImpl(
            usageRepository: context.read<UsageRepository>(),
          ),
        ),
        RepositoryProvider<ReportRepository>(
          create: (context) => ReportRepositoryImpl(
            usageRepository: context.read<UsageRepository>(),
          ),
        ),
        RepositoryProvider<SmartLockRepository>(
          create: (_) => SmartLockRepository(),
        ),
        RepositoryProvider<AlertRepository>(
          create: (_) => AlertRepositoryImpl(),
        ),
        RepositoryProvider<NotificationRepository>(
          create: (_) => NotificationRepositoryImpl(),
        ),
        RepositoryProvider<TimeRequestRepository>(
          create: (_) => TimeRequestRepositoryImpl(),
        ),
        RepositoryProvider<NotificationService>(
          create: (context) => NotificationService(
            timeRequestRepository: context.read<TimeRequestRepository>(),
          )..initialize(),
        ),
        RepositoryProvider<SettingsRepository>(
          create: (_) => SettingsRepositoryImpl(),
        ),
        RepositoryProvider<HelpRepository>(
          create: (_) => HelpRepositoryImpl(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
              familyRepository: context.read<FamilyRepository>(),
              notificationService: context.read<NotificationService>(),
            ),
          ),
          BlocProvider<FamilyBloc>(
            create: (context) => FamilyBloc(
              familyRepository: context.read<FamilyRepository>(),
              authRepository: context.read<AuthRepository>(),
            ),
          ),
          BlocProvider<DashboardBloc>(
            create: (context) => DashboardBloc(
              usageRepository: context.read<UsageRepository>(),
              familyRepository: context.read<FamilyRepository>(),
            ),
          ),
          BlocProvider<SummaryBloc>(
            create: (context) => SummaryBloc(
              summaryRepository: context.read<SummaryRepository>(),
            ),
          ),
          BlocProvider<ReportBloc>(
            create: (context) => ReportBloc(
              reportRepository: context.read<ReportRepository>(),
            ),
          ),
          BlocProvider<AppMonitorBloc>(
            create: (context) => AppMonitorBloc(
              checkAppAccessUseCase: CheckAppAccessUseCase(
                usageRepository: context.read<UsageRepository>(),
                smartLockRepository: context.read<SmartLockRepository>(),
              ),
              blockAppUseCase: BlockAppUseCase(),
              usageRepository: context.read<UsageRepository>(),
              smartLockRepository: context.read<SmartLockRepository>(),
              scheduleChecker: ScheduleChecker(),
              alertRepository: context.read<AlertRepository>(),
            ),
          ),
          BlocProvider<NotificationBloc>(
            create: (context) => NotificationBloc(
              alertRepository: context.read<AlertRepository>(),
              timeRequestRepository: context.read<TimeRequestRepository>(),
            )..initializeNotifications(),
          ),
          BlocProvider<InAppNotificationBloc>(
            create: (context) => InAppNotificationBloc(
              alertRepository: context.read<AlertRepository>(),
              timeRequestRepository: context.read<TimeRequestRepository>(),
            ),
          ),
          BlocProvider<SettingsBloc>(
            create: (context) => SettingsBloc(
              settingsRepository: context.read<SettingsRepository>(),
            )..add(LoadSettings()),
          ),
          BlocProvider<HelpBloc>(
            create: (context) => HelpBloc(
              helpRepository: context.read<HelpRepository>(),
            ),
          ),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<AuthBloc, AuthState>(
              // Bắt mọi transition về AuthUnauthenticated (kể cả từ AuthLoading sau đăng xuất)
              listenWhen: (previous, current) =>
                  current is AuthUnauthenticated && previous is! AuthUnauthenticated,
              listener: (context, state) {
                // pushAndRemoveUntil xoá toàn bộ stack — tránh ChildDashboard còn nằm dưới stack
                AppNavigator.navigatorKey.currentState?.pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const RoleSelectionScreen(),
                  ),
                  (route) => false,
                );
              },
            ),
            BlocListener<AppMonitorBloc, AppMonitorState>(
              listenWhen: (previous, current) => current is AppBlockedState,
              listener: (context, state) {
                if (state is AppBlockedState) {
                  final navigator = AppNavigator.navigatorKey.currentState;
                  if (navigator != null) {
                    navigator.popUntil((route) {
                      return route.settings.name != 'lock_screen';
                    });
                    navigator.push(
                      MaterialPageRoute(
                        settings: const RouteSettings(name: 'lock_screen'),
                        builder: (_) => LockScreen(
                          appPackageName: state.appPackageName,
                          appName: state.appName,
                          iconUrl: state.iconUrl,
                          limitMinutes: state.limitMinutes,
                          usedMinutes: state.usedMinutes,
                          resetTime: state.resetTime,
                          familyId: state.familyId,
                          childUid: state.childUid,
                          parentUid: state.parentUid,
                        ),
                      ),
                    );
                  }
                }
              },
            ),
            BlocListener<AppMonitorBloc, AppMonitorState>(
              listenWhen: (previous, current) => current is KeywordAlertEmitted,
              listener: (context, state) {
                if (state is KeywordAlertEmitted) {
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Phát hiện từ khóa: "${state.keyword}" trong ứng dụng'),
                      backgroundColor: Colors.red.shade700,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
          ],
          child: BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, settingsState) {
              return MaterialApp(
                navigatorKey: AppNavigator.navigatorKey,
                title: 'KidGuardian',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: settingsState.themeMode,
                locale: settingsState.locale,
                supportedLocales: const [
                  Locale('vi'),
                  Locale('en'),
                ],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                debugShowCheckedModeBanner: false,
                home: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is AuthInitial || state is AuthLoading) {
                      return const SplashScreen();
                    } else if (state is AuthAuthenticated) {
                      return _buildHomeForRole(state.user, context);
                    }
                    return const RoleSelectionScreen();
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHomeForRole(User user, BuildContext context) {
    if (user.role == UserRole.parent) {
      if (user.familyId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<NotificationBloc>().add(
            StartAlertListening(familyId: user.familyId!),
          );
          context.read<NotificationBloc>().add(
            StartTimeRequestListening(familyId: user.familyId!, childUids: const []),
          );
        });
      }
      return ParentDashboard();
    } else {
      if (user.familyId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<AppMonitorBloc>().add(StartMonitoring(user.familyId!, user.uid));
        });
      }
      return ChildDashboard();
    }
  }
}
