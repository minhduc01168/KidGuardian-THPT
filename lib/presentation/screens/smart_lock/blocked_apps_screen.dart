import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidguardian/data/models/monitored_app_model.dart';
import 'package:kidguardian/data/repositories/smart_lock_repository.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_bloc.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_event.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_state.dart';

class BlockedAppsScreen extends StatelessWidget {
  final String familyId;
  final String childId;
  final SmartLockRepository? repository;

  const BlockedAppsScreen({
    super.key,
    required this.familyId,
    required this.childId,
    this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SmartLockBloc(
        repository: repository ?? SmartLockRepository(),
      )..add(LoadMonitoredApps(familyId, childId)),
      child: _BlockedAppsView(familyId: familyId, childId: childId),
    );
  }
}

class _BlockedAppsView extends StatelessWidget {
  final String familyId;
  final String childId;

  const _BlockedAppsView({
    required this.familyId,
    required this.childId,
  });

  void _showAddCustomAppDialog(BuildContext context) {
    final packageNameController = TextEditingController();
    final appNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Thêm ứng dụng tùy chỉnh'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: packageNameController,
                  decoration: const InputDecoration(
                    labelText: 'Package Name',
                    hintText: 'com.example.app',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập package name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: appNameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên ứng dụng',
                    hintText: 'My App',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên ứng dụng';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  context.read<SmartLockBloc>().add(AddCustomApp(
                    familyId,
                    childId,
                    packageNameController.text.trim(),
                    appNameController.text.trim(),
                  ));
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý ứng dụng giám sát'),
      ),
      body: BlocConsumer<SmartLockBloc, SmartLockState>(
        listener: (context, state) {
          if (state is SmartLockError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SmartLockLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MonitoredAppsLoaded) {
            if (state.apps.isEmpty) {
              return const Center(
                child: Text('Không có ứng dụng nào để hiển thị'),
              );
            }

            return ListView.separated(
              itemCount: state.apps.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final app = state.apps[index];
                return _MonitoredAppTile(
                  app: app,
                  onToggle: (value) {
                    context.read<SmartLockBloc>().add(ToggleMonitoredApp(
                      familyId,
                      childId,
                      app.appPackageName,
                      value,
                    ));
                  },
                );
              },
            );
          }

          return const Center(child: Text('Đã xảy ra lỗi'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomAppDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MonitoredAppTile extends StatelessWidget {
  final MonitoredAppModel app;
  final ValueChanged<bool> onToggle;

  const _MonitoredAppTile({
    required this.app,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(app.appName),
      subtitle: Text(
        app.isMonitored ? 'Đang giám sát' : 'Không giám sát',
        style: TextStyle(
          color: app.isMonitored ? Colors.green : Colors.grey,
        ),
      ),
      secondary: app.iconUrl != null
          ? CircleAvatar(
              backgroundImage: NetworkImage(app.iconUrl!),
            )
          : CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: Text(
                app.appName.isNotEmpty ? app.appName[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
      value: app.isMonitored,
      onChanged: onToggle,
    );
  }
}
