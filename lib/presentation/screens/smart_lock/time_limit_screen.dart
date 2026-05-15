import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidguardian/data/models/app_time_limit_model.dart';
import 'package:kidguardian/data/repositories/smart_lock_repository.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_bloc.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_event.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_state.dart';
import '../../widgets/smart_lock/app_limit_item.dart';
import '../../widgets/smart_lock/time_picker_bottom_sheet.dart';

class TimeLimitScreen extends StatelessWidget {
  final String familyId;
  final String childId;
  final SmartLockRepository? repository;

  const TimeLimitScreen({
    super.key,
    required this.familyId,
    required this.childId,
    this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SmartLockBloc(
        repository: repository ?? SmartLockRepository(), // In real app, inject via GetIt
      )..add(LoadAppTimeLimits(familyId, childId)),
      child: _TimeLimitView(familyId: familyId, childId: childId),
    );
  }
}

class _TimeLimitView extends StatelessWidget {
  final String familyId;
  final String childId;

  const _TimeLimitView({
    required this.familyId,
    required this.childId,
  });

  void _showTimePicker(BuildContext context, AppTimeLimitModel app) {
    final bloc = context.read<SmartLockBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return TimePickerBottomSheet(
          initialLimits: app.limits,
          onSave: (limits) {
            final updatedApp = app.copyWith(limits: limits);
            bloc.add(SaveAppTimeLimit(
              familyId,
              childId,
              updatedApp,
            ));
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt giới hạn thời gian'),
      ),
      body: BlocConsumer<SmartLockBloc, SmartLockState>(
        listener: (context, state) {
          if (state is SmartLockActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is SmartLockError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        buildWhen: (previous, current) => current is! SmartLockActionSuccess,
        builder: (context, state) {
          if (state is SmartLockLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is SmartLockLoaded) {
            if (state.apps.isEmpty) {
              return const Center(child: Text('Không có ứng dụng nào để hiển thị'));
            }
            
            return ListView.separated(
              itemCount: state.apps.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final app = state.apps[index];
                return AppLimitItem(
                  app: app,
                  onTap: () => _showTimePicker(context, app),
                );
              },
            );
          }
          
          return const Center(child: Text('Đã xảy ra lỗi'));
        },
      ),
    );
  }
}
