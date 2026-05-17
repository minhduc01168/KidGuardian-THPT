import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kidguardian/domain/repositories/time_request_repository.dart';
import 'package:kidguardian/presentation/blocs/time_request/time_request_bloc.dart';

class TimeRequestApprovalScreen extends StatelessWidget {
  final String familyId;

  const TimeRequestApprovalScreen({super.key, required this.familyId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TimeRequestBloc(
        repository: context.read<TimeRequestRepository>(),
      )..add(LoadPendingRequests(familyId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Yêu cầu thêm thời gian'),
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
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Không có yêu cầu nào đang chờ',
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
                  return _RequestCard(
                    request: request,
                    familyId: familyId,
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

class _RequestCard extends StatelessWidget {
  final TimeRequest request;
  final String familyId;

  const _RequestCard({required this.request, required this.familyId});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('dd/MM/yyyy HH:mm').format(request.timestamp);
    final statusColor = request.status == TimeRequestStatus.pending
        ? Colors.orange
        : request.status == TimeRequestStatus.approved
            ? Colors.green
            : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      color: request.status == TimeRequestStatus.pending
          ? Colors.orange.shade50
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor,
                  child: Icon(
                    request.status == TimeRequestStatus.pending
                        ? Icons.access_time
                        : request.status == TimeRequestStatus.approved
                            ? Icons.check
                            : Icons.close,
                    color: Colors.white,
                  ),
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
                    request.status == TimeRequestStatus.pending
                        ? 'Chờ duyệt'
                        : request.status == TimeRequestStatus.approved
                            ? 'Đã duyệt'
                            : 'Đã từ chối',
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
                      'Lý do:',
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
            const SizedBox(height: 8),
            Text(
              timeStr,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
            if (request.status == TimeRequestStatus.pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showApproveDialog(context),
                      icon: const Icon(Icons.check),
                      label: const Text('Duyệt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Từ chối'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (request.parentResponse != null && request.parentResponse!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phản hồi từ phụ huynh:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(request.parentResponse!),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showApproveDialog(BuildContext context) {
    final responseController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Duyệt yêu cầu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn có muốn duyệt yêu cầu thêm ${request.requestedMinutes} phút cho ${request.appName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: responseController,
              decoration: const InputDecoration(
                labelText: 'Phản hồi (tùy chọn)',
                hintText: 'VD: Đồng ý, con hãy sử dụng hợp lý nhé',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final bloc = context.read<TimeRequestBloc>();
              bloc.add(ApproveTimeRequest(
                familyId: familyId,
                childUid: request.childUid,
                requestId: request.id,
                response: responseController.text.trim().isEmpty ? null : responseController.text.trim(),
              ));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Duyệt'),
          ),
        ],
      ),
    ).whenComplete(() => responseController.dispose());
  }

  void _showRejectDialog(BuildContext context) {
    final responseController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối yêu cầu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn có muốn từ chối yêu cầu thêm ${request.requestedMinutes} phút cho ${request.appName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: responseController,
              decoration: const InputDecoration(
                labelText: 'Lý do từ chối (tùy chọn)',
                hintText: 'VD: Con đã sử dụng đủ thời gian hôm nay',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final bloc = context.read<TimeRequestBloc>();
              bloc.add(RejectTimeRequest(
                familyId: familyId,
                childUid: request.childUid,
                requestId: request.id,
                response: responseController.text.trim().isEmpty ? null : responseController.text.trim(),
              ));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    ).whenComplete(() => responseController.dispose());
  }
}
