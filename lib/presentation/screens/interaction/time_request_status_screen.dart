import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kidguardian/domain/repositories/time_request_repository.dart';
import 'package:kidguardian/presentation/blocs/time_request/time_request_bloc.dart';

class TimeRequestStatusScreen extends StatelessWidget {
  final String familyId;
  final String childUid;

  const TimeRequestStatusScreen({
    super.key,
    required this.familyId,
    required this.childUid,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TimeRequestBloc(
        repository: context.read<TimeRequestRepository>(),
      )..add(LoadTimeRequests(familyId: familyId, childUid: childUid)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Yêu cầu của tôi'),
        ),
        body: BlocBuilder<TimeRequestBloc, TimeRequestState>(
          builder: (context, state) {
            if (state is TimeRequestLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is TimeRequestError) {
              return Center(child: Text('Lỗi: ${state.message}'));
            }
            if (state is TimeRequestsLoaded) {
              if (state.requests.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Bạn chưa gửi yêu cầu nào',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: state.requests.length,
                itemBuilder: (context, index) {
                  final request = state.requests[index];
                  return _RequestStatusCard(request: request);
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

class _RequestStatusCard extends StatelessWidget {
  final TimeRequest request;

  const _RequestStatusCard({required this.request});

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
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            if (request.reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lý do của bạn:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(request.reason),
                  ],
                ),
              ),
            ],
            if (request.parentResponse != null && request.parentResponse!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: request.status == TimeRequestStatus.approved
                      ? Colors.green.shade50
                      : request.status == TimeRequestStatus.rejected
                          ? Colors.red.shade50
                          : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: request.status == TimeRequestStatus.approved
                        ? Colors.green.shade200
                        : request.status == TimeRequestStatus.rejected
                            ? Colors.red.shade200
                            : Colors.blue.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          request.status == TimeRequestStatus.approved
                              ? Icons.check_circle
                              : request.status == TimeRequestStatus.rejected
                                  ? Icons.cancel
                                  : Icons.info,
                          size: 16,
                          color: request.status == TimeRequestStatus.approved
                              ? Colors.green
                              : request.status == TimeRequestStatus.rejected
                                  ? Colors.red
                                  : Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Phản hồi từ phụ huynh:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: request.status == TimeRequestStatus.approved
                                ? Colors.green
                                : request.status == TimeRequestStatus.rejected
                                    ? Colors.red
                                    : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.parentResponse!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              timeStr,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
            if (request.status == TimeRequestStatus.pending) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.orange.shade300,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Đang chờ phụ huynh phản hồi...',
                    style: TextStyle(
                      color: Colors.orange.shade600,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
