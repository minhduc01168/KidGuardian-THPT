import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/remote/emergency_log_source.dart';
import '../../../domain/usecases/smart_lock/emergency_access_manager.dart';
import '../../../presentation/blocs/emergency_access/emergency_access_bloc.dart';
import '../../../presentation/blocs/emergency_access/emergency_access_event.dart';
import '../../../presentation/blocs/emergency_access/emergency_access_state.dart';
import '../../../presentation/blocs/emergency_access/emergency_access_history_screen.dart';

class EmergencyAccessScreen extends StatefulWidget {
  final String familyId;
  final String childUid;
  final String parentUid;
  final String? appPackageName;

  const EmergencyAccessScreen({
    super.key,
    required this.familyId,
    required this.childUid,
    required this.parentUid,
    this.appPackageName,
  });

  @override
  State<EmergencyAccessScreen> createState() => _EmergencyAccessScreenState();
}

class _EmergencyAccessScreenState extends State<EmergencyAccessScreen> {
  late final EmergencyAccessBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = EmergencyAccessBloc(
      logSource: EmergencyLogSource(),
    );
    _bloc.add(LoadEmergencyContacts(parentUid: widget.parentUid));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _sendSms(String phone) async {
    final uri = Uri.parse('sms:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Truy cập khẩn cấp'),
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Lịch sử khẩn cấp',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: _bloc,
                      child: EmergencyAccessHistoryScreen(
                        familyId: widget.familyId,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<EmergencyAccessBloc, EmergencyAccessState>(
          listener: (context, state) {
            if (state is EmergencyAccessSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
            }
            if (state is EmergencyAccessError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            if (state is EmergencyActivated) {
              _makeCall(state.phoneNumber);
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildEmergencyHeader(),
                  const SizedBox(height: 24),
                  if (state is EmergencyAccessLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (state is EmergencyContactLoaded)
                    _buildContactSection(state)
                  else if (state is EmergencyActive)
                    _buildActiveSection(state)
                  else if (state is EmergencyCooldown)
                    _buildCooldownSection(state)
                  else if (state is EmergencyHistoryLoaded)
                    _buildHistoryPreview(state),
                  const SizedBox(height: 24),
                  _buildEmergencyGuide(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmergencyHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade700, Colors.red.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emergency,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'Truy cập khẩn cấp',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Liên hệ ngay với phụ huynh khi cần thiết',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(EmergencyContactLoaded state) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Liên hệ phụ huynh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (state.parentPhone != null && state.parentPhone!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.parentName ?? 'Phụ huynh',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.parentPhone!,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _activateAndCall(state.parentPhone!),
                      icon: const Icon(Icons.phone, color: Colors.white),
                      label: const Text('Gọi điện'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _activateAndSms(state.parentPhone!),
                      icon: const Icon(Icons.message, color: Colors.white),
                      label: const Text('Nhắn tin'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      size: 48,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Chưa có số điện thoại phụ huynh',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Phụ huynh cần cập nhật số điện thoại trong phần cài đặt để sử dụng tính năng này.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSection(EmergencyActive state) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Column(
          children: [
            Icon(
              Icons.timer,
              size: 48,
              color: Colors.orange.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              'Truy cập khẩn cấp đang hoạt động',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _formatTime(state.remainingSeconds),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn có thể gọi hoặc nhắn tin cho phụ huynh',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _bloc.add(DeactivateEmergency(childUid: widget.childUid));
                },
                icon: const Icon(Icons.stop),
                label: const Text('Dừng truy cập'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCooldownSection(EmergencyCooldown state) {
    final minutes = (state.cooldownSeconds / 60).ceil();
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.hourglass_disabled,
              size: 48,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 16),
            Text(
              'Đã hết thời gian khẩn cấp',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử lại sau khoảng $minutes phút',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryPreview(EmergencyHistoryLoaded state) {
    if (state.history.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lịch sử gần đây',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: _bloc,
                          child: EmergencyAccessHistoryScreen(
                            familyId: widget.familyId,
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...state.history.take(3).map((log) => ListTile(
              leading: CircleAvatar(
                backgroundColor: log.action == 'call'
                    ? Colors.green.shade100
                    : Colors.blue.shade100,
                child: Icon(
                  log.action == 'call' ? Icons.phone : Icons.message,
                  color: log.action == 'call' ? Colors.green : Colors.blue,
                ),
              ),
              title: Text(log.actionLabel),
              subtitle: Text(
                DateFormat('dd/MM/yyyy HH:mm').format(log.timestamp),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: log.status == 'completed'
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log.statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: log.status == 'completed'
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyGuide() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hướng dẫn sử dụng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildGuideItem(
              Icons.info_outline,
              'Truy cập khẩn cấp cho phép bạn liên hệ trực tiếp với phụ huynh.',
            ),
            _buildGuideItem(
              Icons.timer,
              'Thời gian truy cập kéo dài 5 phút.',
            ),
            _buildGuideItem(
              Icons.lock_clock,
              'Sau khi sử dụng, cần đợi 15 phút trước khi sử dụng lại.',
            ),
            _buildGuideItem(
              Icons.history,
              'Mọi lần sử dụng đều được ghi lại trong lịch sử.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _activateAndCall(String phone) {
    _bloc.add(ActivateEmergency(
      childUid: widget.childUid,
      familyId: widget.familyId,
      action: 'call',
      phoneNumber: phone,
      appPackageName: widget.appPackageName ?? '',
    ));
  }

  void _activateAndSms(String phone) {
    _bloc.add(ActivateEmergency(
      childUid: widget.childUid,
      familyId: widget.familyId,
      action: 'sms',
      phoneNumber: phone,
      appPackageName: widget.appPackageName ?? '',
    ));
  }
}
