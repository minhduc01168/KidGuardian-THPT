import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/family_repository_impl.dart';
import 'data/repositories/report_repository_impl.dart';
import 'data/repositories/summary_repository_impl.dart';
import 'data/repositories/usage_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/family_repository.dart';
import 'domain/repositories/report_repository.dart';
import 'domain/repositories/summary_repository.dart';
import 'domain/repositories/usage_repository.dart';
import 'domain/usecases/smart_lock/check_app_access_usecase.dart';
import 'domain/usecases/smart_lock/block_app_usecase.dart';
import 'domain/usecases/smart_lock/schedule_checker.dart';
import 'presentation/features/auth/bloc/auth_bloc.dart';
import 'presentation/features/auth/bloc/auth_state.dart';
import 'presentation/features/auth/bloc/family_bloc.dart';
import 'presentation/features/auth/screens/role_selection_screen.dart';
import 'presentation/features/dashboard/bloc/dashboard_bloc.dart';
import 'presentation/features/dashboard/screens/parent_dashboard.dart';
import 'presentation/features/dashboard/screens/child_dashboard.dart';
import 'presentation/features/report/bloc/report_bloc.dart';
import 'presentation/features/summary/bloc/summary_bloc.dart';
import 'presentation/blocs/smart_lock/app_monitor_bloc.dart';
import 'presentation/screens/smart_lock/lock_screen.dart';
import 'data/repositories/smart_lock_repository.dart';
import 'domain/repositories/alert_repository.dart';
import 'domain/entities/user.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
              familyRepository: context.read<FamilyRepository>(),
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
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<AppMonitorBloc, AppMonitorState>(
              listenWhen: (previous, current) => current is AppBlockedState,
              listener: (context, state) {
                if (state is AppBlockedState) {
                  final navigator = navigatorKey.currentState;
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
          child: MaterialApp(
            navigatorKey: navigatorKey,
            title: 'KidGuardian',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            home: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthAuthenticated) {
                  return _buildHomeForRole(state.user, context);
                }
                return RoleSelectionScreen();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeForRole(User user, BuildContext context) {
    if (user.role == UserRole.parent) {
      return ParentDashboard();
    } else {
      if (user.familyId != null) {
        // Use post-frame callback to avoid dispatching event during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<AppMonitorBloc>().add(StartMonitoring(user.familyId!, user.uid));
        });
      }
      return ChildDashboard();
    }
  }
}
