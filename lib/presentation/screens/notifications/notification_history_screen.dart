import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kidguardian/domain/repositories/notification_repository.dart';
import 'package:kidguardian/presentation/blocs/notification_history/notification_history_bloc.dart';

class NotificationHistoryScreen extends StatelessWidget {
  final String familyId;
  final String childUid;

  const NotificationHistoryScreen({
    super.key,
    required this.familyId,
    required this.childUid,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationHistoryBloc(
        notificationRepository: context.read<NotificationRepository>(),
      )..add(LoadNotifications(familyId: familyId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lịch sử thông báo'),
          actions: [
            BlocBuilder<NotificationHistoryBloc, NotificationHistoryState>(
              builder: (context, state) {
                if (state is NotificationHistoryLoaded) {
                  return Row(
                    children: [
                      if (state.unreadCount > 0)
                        TextButton.icon(
                          onPressed: () {
                            context.read<NotificationHistoryBloc>().add(
                                  MarkAllAsReadEvent(
                                    familyId: familyId,
                                    childUid: childUid,
                                  ),
                                );
                          },
                          icon: const Icon(Icons.done_all, size: 18),
                          label: const Text('Đọc tất cả'),
                        ),
                      PopupMenuButton<dynamic>(
                        icon: const Icon(Icons.more_vert),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'filter_all',
                            child: Row(
                              children: [
                                Icon(Icons.all_inclusive),
                                SizedBox(width: 8),
                                Text('Tất cả'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'filter_unread',
                            child: Row(
                              children: [
                                Icon(Icons.mark_email_unread),
                                SizedBox(width: 8),
                                Text('Chưa đọc'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'filter_read',
                            child: Row(
                              children: [
                                Icon(Icons.mark_email_read),
                                SizedBox(width: 8),
                                Text('Đã đọc'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'clear_30',
                            child: Row(
                              children: [
                                Icon(Icons.delete_sweep, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Xóa thông báo cũ (30 ngày)',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'clear_7',
                            child: Row(
                              children: [
                                Icon(Icons.delete_sweep, color: Colors.orange),
                                SizedBox(width: 8),
                                Text('Xóa thông báo cũ (7 ngày)',
                                    style: TextStyle(color: Colors.orange)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          final bloc =
                              context.read<NotificationHistoryBloc>();
                          switch (value) {
                            case 'filter_all':
                              bloc.add(const FilterByReadStatus(
                                  NotificationFilterStatus.all));
                              break;
                            case 'filter_unread':
                              bloc.add(const FilterByReadStatus(
                                  NotificationFilterStatus.unread));
                              break;
                            case 'filter_read':
                              bloc.add(const FilterByReadStatus(
                                  NotificationFilterStatus.read));
                              break;
                            case 'clear_30':
                              _confirmClear(context, bloc, 30);
                              break;
                            case 'clear_7':
                              _confirmClear(context, bloc, 7);
                              break;
                          }
                        },
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocBuilder<NotificationHistoryBloc, NotificationHistoryState>(
          builder: (context, state) {
            if (state is NotificationHistoryLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is NotificationHistoryError) {
              return Center(child: Text('Lỗi: ${state.message}'));
            }
            if (state is NotificationHistoryLoaded) {
              if (state.filteredNotifications.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Không có thông báo nào',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  if (state.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: Colors.blue.shade50,
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            '${state.unreadCount} thông báo chưa đọc',
                            style: TextStyle(color: Colors.blue.shade700),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: state.filteredNotifications.length,
                      itemBuilder: (context, index) {
                        final notification =
                            state.filteredNotifications[index];
                        return _NotificationCard(
                          notification: notification,
                          familyId: familyId,
                          childUid: childUid,
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
      ),
    );
  }

  void _confirmClear(
      BuildContext context, NotificationHistoryBloc bloc, int daysOld) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa thông báo cũ'),
        content: Text(
            'Bạn có chắc muốn xóa tất cả thông báo cũ hơn $daysOld ngày?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              bloc.add(ClearOldNotificationsEvent(
                familyId: familyId,
                childUid: childUid,
                daysOld: daysOld,
              ));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final String familyId;
  final String childUid;

  const _NotificationCard({
    required this.notification,
    required this.familyId,
    required this.childUid,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr =
        DateFormat('dd/MM/yyyy HH:mm').format(notification.timestamp);

    return Dismissible(
      key: Key(notification.id),
      direction:
          notification.isRead ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.green,
        child: const Icon(Icons.check, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        context.read<NotificationHistoryBloc>().add(MarkAsReadEvent(
              familyId: familyId,
              childUid: childUid,
              notificationId: notification.id,
            ));
        return false;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        color: notification.isRead ? null : Colors.blue.shade50,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _getTypeColor(notification.type),
            child: Icon(
              _getTypeIcon(notification.type),
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                timeStr,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
          trailing: notification.isRead
              ? const Icon(Icons.check_circle, color: Colors.green, size: 16)
              : const Icon(Icons.circle, color: Colors.blue, size: 12),
        ),
      ),
    );
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.alert:
        return Colors.red;
      case NotificationType.timeRequest:
        return Colors.orange;
      case NotificationType.system:
        return Colors.blue;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.alert:
        return Icons.warning;
      case NotificationType.timeRequest:
        return Icons.timer;
      case NotificationType.system:
        return Icons.info;
    }
  }
}
