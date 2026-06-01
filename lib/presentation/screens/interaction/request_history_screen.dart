import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kidguardian/domain/repositories/time_request_repository.dart';
import 'package:kidguardian/presentation/blocs/time_request/time_request_bloc.dart';

class RequestHistoryScreen extends StatelessWidget {
  final String familyId;

  const RequestHistoryScreen({super.key, required this.familyId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TimeRequestBloc(
        repository: context.read<TimeRequestRepository>(),
      )..add(LoadAllRequests(familyId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lịch sử yêu cầu'),
          actions: [
            BlocBuilder<TimeRequestBloc, TimeRequestState>(
              builder: (context, state) {
                if (state is TimeRequestHistoryLoaded) {
                  return PopupMenuButton<TimeRequestFilterStatus>(
                    icon: const Icon(Icons.filter_list),
                    onSelected: (status) {
                      context
                          .read<TimeRequestBloc>()
                          .add(FilterRequestsByStatus(status));
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: TimeRequestFilterStatus.all,
                        child: Row(
                          children: [
                            Icon(
                              Icons.all_inclusive,
                              color:
                                  state.filterStatus ==
                                          TimeRequestFilterStatus.all
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                            ),
                            const SizedBox(width: 8),
                            const Text('Tất cả'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: TimeRequestFilterStatus.pending,
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color:
                                  state.filterStatus ==
                                          TimeRequestFilterStatus.pending
                                      ? Colors.orange
                                      : null,
                            ),
                            const SizedBox(width: 8),
                            const Text('Đang chờ'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: TimeRequestFilterStatus.approved,
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color:
                                  state.filterStatus ==
                                          TimeRequestFilterStatus.approved
                                      ? Colors.green
                                      : null,
                            ),
                            const SizedBox(width: 8),
                            const Text('Đã duyệt'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: TimeRequestFilterStatus.rejected,
                        child: Row(
                          children: [
                            Icon(
                              Icons.cancel,
                              color:
                                  state.filterStatus ==
                                          TimeRequestFilterStatus.rejected
                                      ? Colors.red
                                      : null,
                            ),
                            const SizedBox(width: 8),
                            const Text('Đã từ chối'),
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
        body: BlocBuilder<TimeRequestBloc, TimeRequestState>(
          builder: (context, state) {
            if (state is TimeRequestLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is TimeRequestError) {
              return Center(child: Text('Lỗi: ${state.message}'));
            }
            if (state is TimeRequestHistoryLoaded) {
              if (state.filteredRequests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.filterStatus == TimeRequestFilterStatus.all
                            ? 'Chưa có yêu cầu nào'
                            : 'Không có yêu cầu nào phù hợp',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: state.filteredRequests.length,
                itemBuilder: (context, index) {
                  final request = state.filteredRequests[index];
                  return _RequestHistoryCard(request: request);
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

class _RequestHistoryCard extends StatelessWidget {
  final TimeRequest request;

  const _RequestHistoryCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('dd/MM/yyyy HH:mm').format(request.timestamp);
    final statusColor = request.status == TimeRequestStatus.pending
        ? Colors.orange
        : request.status == TimeRequestStatus.approved
            ? Colors.green
            : Colors.red;
    final statusIcon = request.status == TimeRequestStatus.pending
        ? Icons.access_time
        : request.status == TimeRequestStatus.approved
            ? Icons.check_circle
            : Icons.cancel;
    final statusText = request.status == TimeRequestStatus.pending
        ? 'Đang chờ duyệt'
        : request.status == TimeRequestStatus.approved
            ? 'Đã được duyệt'
            : 'Đã bị từ chối';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetailSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor,
                    child: Icon(statusIcon, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.appName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Xin thêm ${request.requestedMinutes} phút',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                timeStr,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context) {
    final timeStr = DateFormat('dd/MM/yyyy HH:mm').format(request.timestamp);
    final statusColor = request.status == TimeRequestStatus.pending
        ? Colors.orange
        : request.status == TimeRequestStatus.approved
            ? Colors.green
            : Colors.red;
    final statusText = request.status == TimeRequestStatus.pending
        ? 'Đang chờ duyệt'
        : request.status == TimeRequestStatus.approved
            ? 'Đã được duyệt'
            : 'Đã bị từ chối';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: statusColor,
                    child: Icon(
                      request.status == TimeRequestStatus.pending
                          ? Icons.access_time
                          : request.status == TimeRequestStatus.approved
                              ? Icons.check_circle
                              : Icons.cancel,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.appName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _DetailRow(
                label: 'Thời gian yêu cầu',
                value: '${request.requestedMinutes} phút',
                icon: Icons.timer,
              ),
              const SizedBox(height: 16),
              _DetailRow(
                label: 'Thời gian gửi',
                value: timeStr,
                icon: Icons.calendar_today,
              ),
              if (request.reason.isNotEmpty) ...[
                const SizedBox(height: 16),
                _DetailSection(
                  label: 'Lý do của con',
                  value: request.reason,
                  icon: Icons.info_outline,
                  backgroundColor: Colors.grey.shade100,
                ),
              ],
              if (request.parentResponse != null &&
                  request.parentResponse!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _DetailSection(
                  label: 'Phản hồi từ phụ huynh',
                  value: request.parentResponse!,
                  icon: request.status == TimeRequestStatus.approved
                      ? Icons.check_circle
                      : request.status == TimeRequestStatus.rejected
                          ? Icons.cancel
                          : Icons.info,
                  backgroundColor: request.status == TimeRequestStatus.approved
                      ? Colors.green.shade50
                      : request.status == TimeRequestStatus.rejected
                          ? Colors.red.shade50
                          : Colors.blue.shade50,
                  borderColor: request.status == TimeRequestStatus.approved
                      ? Colors.green.shade200
                      : request.status == TimeRequestStatus.rejected
                          ? Colors.red.shade200
                          : Colors.blue.shade200,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? backgroundColor;
  final Color? borderColor;

  const _DetailSection({
    required this.label,
    required this.value,
    required this.icon,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
