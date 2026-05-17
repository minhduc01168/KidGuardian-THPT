import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';
import 'package:kidguardian/presentation/blocs/alert_review/alert_review_bloc.dart';

class AlertDetailScreen extends StatelessWidget {
  final String familyId;
  final String childUid;
  final String alertId;

  const AlertDetailScreen({
    super.key,
    required this.familyId,
    required this.childUid,
    required this.alertId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AlertReviewBloc(
        alertRepository: context.read<AlertRepository>(),
      )..add(LoadAlertDetail(familyId: familyId, childUid: childUid, alertId: alertId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết cảnh báo'),
        ),
        body: BlocConsumer<AlertReviewBloc, AlertReviewState>(
          listener: (context, state) {
            if (state is AlertReviewSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
            }
            if (state is AlertReviewError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is AlertReviewLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AlertReviewError && state.message.contains('not found')) {
              return const Center(child: Text('Không tìm thấy cảnh báo'));
            }
            if (state is AlertReviewLoaded) {
              return _AlertDetailContent(
                alert: state.alert,
                familyId: familyId,
                childUid: childUid,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _AlertDetailContent extends StatefulWidget {
  final AlertModel alert;
  final String familyId;
  final String childUid;

  const _AlertDetailContent({
    required this.alert,
    required this.familyId,
    required this.childUid,
  });

  @override
  State<_AlertDetailContent> createState() => _AlertDetailContentState();
}

class _AlertDetailContentState extends State<_AlertDetailContent> {
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.alert.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final timeStr = alert.timestamp != null
        ? DateFormat('dd/MM/yyyy HH:mm:ss').format(alert.timestamp!)
        : 'N/A';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: alert.isDismissed
                ? Colors.grey.shade100
                : alert.isReviewed
                    ? Colors.green.shade50
                    : Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        alert.isDismissed
                            ? Icons.remove_circle
                            : alert.isReviewed
                                ? Icons.check_circle
                                : Icons.warning,
                        color: alert.isDismissed
                            ? Colors.grey
                            : alert.isReviewed
                                ? Colors.green
                                : Colors.red,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          alert.isDismissed
                              ? 'Đã bỏ qua'
                              : alert.isReviewed
                                  ? 'Đã xem'
                                  : 'Chưa xem',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: alert.isDismissed
                                ? Colors.grey
                                : alert.isReviewed
                                    ? Colors.green
                                    : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _InfoRow(label: 'Từ khóa', value: '"${alert.keyword}"'),
                  _InfoRow(label: 'Ứng dụng', value: alert.packageName),
                  _InfoRow(label: 'Thời gian', value: timeStr),
                  _InfoRow(label: 'Loại', value: alert.type),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ngữ cảnh:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                alert.textContext.isNotEmpty ? alert.textContext : 'Không có ngữ cảnh',
                style: TextStyle(
                  color: alert.textContext.isNotEmpty ? null : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ghi chú:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Thêm ghi chú cho cảnh báo này...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<AlertReviewBloc>().add(AddNotes(
                      familyId: widget.familyId,
                      childUid: widget.childUid,
                      alertId: alert.id,
                      notes: _notesController.text,
                    ));
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Lưu ghi chú'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!alert.isReviewed) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<AlertReviewBloc>().add(MarkAsReviewed(
                    familyId: widget.familyId,
                    childUid: widget.childUid,
                    alertId: alert.id,
                  ));
                },
                icon: const Icon(Icons.check),
                label: const Text('Đánh dấu đã xem'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (!alert.isDismissed) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Bỏ qua cảnh báo'),
                      content: const Text('Bạn có chắc muốn bỏ qua cảnh báo này? Đây là cảnh báo sai (false positive)?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () {
                            context.read<AlertReviewBloc>().add(DismissAlert(
                              familyId: widget.familyId,
                              childUid: widget.childUid,
                              alertId: alert.id,
                            ));
                            Navigator.pop(ctx);
                          },
                          child: const Text('Bỏ qua', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.remove_circle_outline),
                label: const Text('Bỏ qua (False Positive)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
