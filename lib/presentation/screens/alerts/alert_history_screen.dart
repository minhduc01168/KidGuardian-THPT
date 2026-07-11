import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';
import 'package:kidguardian/presentation/blocs/alert_history/alert_history_bloc.dart';

class AlertHistoryScreen extends StatelessWidget {
  final String familyId;
  final String childUid;

  const AlertHistoryScreen({
    super.key,
    required this.familyId,
    required this.childUid,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AlertHistoryBloc(
        alertRepository: context.read<AlertRepository>(),
      )..add(LoadAlerts(familyId: familyId, childUid: childUid)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lịch sử cảnh báo'),
          actions: [
            BlocBuilder<AlertHistoryBloc, AlertHistoryState>(
              builder: (context, state) {
                if (state is AlertHistoryLoaded) {
                  return PopupMenuButton<AlertFilterStatus>(
                    icon: const Icon(Icons.filter_list),
                    onSelected: (status) {
                      context.read<AlertHistoryBloc>().add(FilterByStatus(status));
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: AlertFilterStatus.all,
                        child: Row(
                          children: [
                            Icon(Icons.all_inclusive,
                              color: state.filterStatus == AlertFilterStatus.all
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            const Text('Tất cả'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: AlertFilterStatus.unreviewed,
                        child: Row(
                          children: [
                            Icon(Icons.new_releases,
                              color: state.filterStatus == AlertFilterStatus.unreviewed
                                  ? Colors.orange
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            const Text('Chưa xem'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: AlertFilterStatus.reviewed,
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                              color: state.filterStatus == AlertFilterStatus.reviewed
                                  ? Colors.green
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            const Text('Đã xem'),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocBuilder<AlertHistoryBloc, AlertHistoryState>(
          builder: (context, state) {
            if (state is AlertHistoryLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AlertHistoryError) {
              return Center(child: Text('Lỗi: ${state.message}'));
            }
            if (state is AlertHistoryLoaded) {
              if (state.filteredAlerts.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Không có cảnh báo nào', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: state.filteredAlerts.length,
                itemBuilder: (context, index) {
                  final alert = state.filteredAlerts[index];
                  return _AlertCard(
                    alert: alert,
                    familyId: familyId,
                    childUid: childUid,
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  final String familyId;
  final String childUid;

  const _AlertCard({
    required this.alert,
    required this.familyId,
    required this.childUid,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = alert.timestamp != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(alert.timestamp!)
        : 'N/A';

    return Dismissible(
      key: Key(alert.id),
      direction: alert.isReviewed ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.green,
        child: const Icon(Icons.check, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        context.read<AlertHistoryBloc>().add(MarkAlertReviewedEvent(
          familyId: familyId,
          childUid: childUid,
          alertId: alert.id,
        ));
        return false;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        color: alert.isReviewed ? null : Colors.orange.shade50,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: alert.isReviewed ? Colors.grey : Colors.red,
            child: Icon(
              alert.isReviewed ? Icons.check : Icons.warning,
              color: Colors.white,
            ),
          ),
          title: Text(
            'Từ khóa: "${alert.keyword}"',
            style: TextStyle(
              fontWeight: alert.isReviewed ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text('Ứng dụng: ${alert.packageName}'),
              if (alert.textContext.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Ngữ cảnh: ${alert.textContext}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                timeStr,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
          trailing: alert.isReviewed
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.circle, color: Colors.orange, size: 12),
        ),
      ),
    );
  }
}
