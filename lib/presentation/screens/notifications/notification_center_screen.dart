import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kidguardian/presentation/blocs/in_app_notification/in_app_notification_bloc.dart';
import 'package:kidguardian/presentation/screens/alerts/alert_detail_screen.dart';

class NotificationCenterScreen extends StatelessWidget {
  final String familyId;

  const NotificationCenterScreen({
    super.key,
    required this.familyId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trung tâm thông báo'),
        actions: [
          BlocBuilder<InAppNotificationBloc, InAppNotificationState>(
            builder: (context, state) {
              if (state is InAppNotificationLoaded && state.unreadCount > 0) {
                return TextButton.icon(
                  onPressed: () {
                    context.read<InAppNotificationBloc>().add(
                      const MarkAllInAppNotificationsAsRead(),
                    );
                  },
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('Đọc tất cả'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<InAppNotificationBloc, InAppNotificationState>(
        builder: (context, state) {
          if (state is InAppNotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is InAppNotificationError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<InAppNotificationBloc>().add(
                        LoadInAppNotifications(familyId: familyId),
                      );
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }
          if (state is InAppNotificationLoaded) {
            if (state.notifications.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Chưa có thông báo nào',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Thông báo sẽ xuất hiện khi có cảnh báo mới',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                if (state.unreadCount > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.blue.shade50,
                    child: Text(
                      '${state.unreadCount} thông báo chưa đọc',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: state.notifications.length,
                    itemBuilder: (context, index) {
                      final notification = state.notifications[index];
                      return _NotificationCard(
                        notification: notification,
                        familyId: familyId,
                      );
                    },
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final InAppNotification notification;
  final String familyId;

  const _NotificationCard({
    required this.notification,
    required this.familyId,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('dd/MM/yyyy HH:mm').format(notification.timestamp);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      color: notification.isRead ? null : Colors.blue.shade50,
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            context.read<InAppNotificationBloc>().add(
              MarkInAppNotificationAsRead(
                notificationId: notification.id,
                type: notification.type,
              ),
            );
          }

          if (notification.type == 'alert') {
            final childUid = notification.data['childUid'] as String? ?? '';
            final alertId = notification.data['alertId'] as String? ?? '';
            if (childUid.isNotEmpty && alertId.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlertDetailScreen(
                    familyId: familyId,
                    childUid: childUid,
                    alertId: alertId,
                  ),
                ),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getIconColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getIcon(),
                  color: _getIconColor(),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (notification.type) {
      case 'alert':
        return Icons.warning;
      case 'time_request':
        return Icons.timer;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case 'alert':
        return Colors.red;
      case 'time_request':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}
