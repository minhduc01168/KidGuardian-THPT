import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/emergency_log_model.dart';
import '../../../presentation/blocs/emergency_access/emergency_access_bloc.dart';
import '../../../presentation/blocs/emergency_access/emergency_access_event.dart';
import '../../../presentation/blocs/emergency_access/emergency_access_state.dart';

class EmergencyAccessHistoryScreen extends StatefulWidget {
  final String familyId;

  const EmergencyAccessHistoryScreen({
    super.key,
    required this.familyId,
  });

  @override
  State<EmergencyAccessHistoryScreen> createState() =>
      _EmergencyAccessHistoryScreenState();
}

class _EmergencyAccessHistoryScreenState
    extends State<EmergencyAccessHistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<EmergencyAccessBloc>().add(
      LoadEmergencyHistory(familyId: widget.familyId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử khẩn cấp'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<EmergencyAccessBloc, EmergencyAccessState>(
        builder: (context, state) {
          if (state is EmergencyAccessLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EmergencyAccessError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: TextStyle(fontSize: 16, color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<EmergencyAccessBloc>().add(
                        LoadEmergencyHistory(familyId: widget.familyId),
                      );
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state is EmergencyHistoryLoaded) {
            if (state.history.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có lịch sử khẩn cấp',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lịch sử sẽ được ghi lại khi bạn sử dụng tính năng khẩn cấp',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return _buildHistoryList(state.history);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHistoryList(List<EmergencyLogModel> history) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<EmergencyAccessBloc>().add(
          LoadEmergencyHistory(familyId: widget.familyId),
        );
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final log = history[index];
          return _buildHistoryItem(log, index == 0);
        },
      ),
    );
  }

  Widget _buildHistoryItem(EmergencyLogModel log, bool isFirst) {
    return Card(
      elevation: isFirst ? 3 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isFirst
              ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 2)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: log.action == 'call'
                          ? Colors.green.shade100
                          : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      log.action == 'call' ? Icons.phone : Icons.message,
                      color: log.action == 'call'
                          ? Colors.green.shade700
                          : Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.actionLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm:ss')
                              .format(log.timestamp),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(log.status),
                ],
              ),
              if (log.phoneNumber.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        log.phoneNumber,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (log.durationSeconds > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.timer, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      'Thời lượng: ${log.durationSeconds} giây',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'active':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        label = 'Đang hoạt động';
        break;
      case 'completed':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        label = 'Hoàn thành';
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
