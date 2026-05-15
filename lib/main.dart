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
import 'presentation/features/auth/bloc/auth_bloc.dart';
import 'presentation/features/auth/bloc/auth_state.dart';
import 'presentation/features/auth/bloc/family_bloc.dart';
import 'presentation/features/auth/screens/role_selection_screen.dart';
import 'presentation/features/dashboard/bloc/dashboard_bloc.dart';
import 'presentation/features/dashboard/screens/parent_dashboard.dart';
import 'presentation/features/dashboard/screens/child_dashboard.dart';
import 'presentation/features/report/bloc/report_bloc.dart';
import 'presentation/features/summary/bloc/summary_bloc.dart';
import 'domain/entities/user.dart';

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
        ],
        child: MaterialApp(
          title: 'KidGuardian',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return _buildHomeForRole(state.user);
              }
              return RoleSelectionScreen();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHomeForRole(User user) {
    if (user.role == UserRole.parent) {
      return ParentDashboard();
    } else {
      return ChildDashboard();
    }
  }
}
