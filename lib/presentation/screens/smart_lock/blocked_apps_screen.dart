import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidguardian/core/utils/app_utils.dart';
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Chọn ứng dụng để giám sát',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: SmartLockRepository().getInstalledApps(familyId, childId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Lỗi: ${snapshot.error}'));
                      }
                      final rawApps = snapshot.data ?? [];
                      final apps = rawApps.where((app) {
                        final pkg = app['packageName']?.toString() ?? '';
                        return pkg.isNotEmpty && !AppUtils.isSystemOrUnmonitoredApp(pkg);
                      }).toList();
                      if (apps.isEmpty) {
                        return const Center(
                          child: Text('Chưa có dữ liệu ứng dụng. Vui lòng mở ứng dụng trên máy trẻ để đồng bộ.'),
                        );
                      }
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: apps.length,
                        itemBuilder: (context, index) {
                          final app = apps[index];
                          return ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.android)),
                            title: Text(app['appName'] ?? 'Unknown'),
                            subtitle: Text(app['packageName'] ?? ''),
                            onTap: () {
                              context.read<SmartLockBloc>().add(AddCustomApp(
                                familyId,
                                childId,
                                app['packageName'],
                                app['appName'] ?? 'Unknown',
                              ));
                              Navigator.of(ctx).pop();
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
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
    // Bug 1 fix: fallback sang AppUtils.getAppName nếu appName trống
    final displayName = app.appName.isNotEmpty
        ? app.appName
        : AppUtils.getAppName(app.appPackageName);
    return SwitchListTile(
      title: Text(displayName),
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
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
      value: app.isMonitored,
      onChanged: onToggle,
    );
  }
}
