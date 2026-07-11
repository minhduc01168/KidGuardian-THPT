import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kidguardian/domain/usecases/smart_lock/emergency_access_manager.dart';
import 'package:kidguardian/data/datasources/remote/emergency_log_source.dart';

class EmergencyContactSheet extends StatefulWidget {
  final String? familyId;
  final String? childUid;
  final String? parentUid;
  final String? appPackageName;
  final EmergencyAccessManager? emergencyManager;
  final EmergencyLogSource? logSource;

  const EmergencyContactSheet({
    super.key,
    this.familyId,
    this.childUid,
    this.parentUid,
    this.appPackageName,
    this.emergencyManager,
    this.logSource,
  });

  @override
  State<EmergencyContactSheet> createState() => _EmergencyContactSheetState();
}

class _EmergencyContactSheetState extends State<EmergencyContactSheet> {
  late final EmergencyAccessManager _emergencyManager;
  late final EmergencyLogSource _logSource;

  String? _parentName;
  String? _parentPhone;
  bool _isLoading = true;
  String? _errorMessage;

  StreamSubscription<int>? _remainingSub;
  StreamSubscription<EmergencyState>? _stateSub;
  int _remainingSeconds = 0;
  EmergencyState _state = EmergencyState.inactive;

  @override
  void initState() {
    super.initState();
    _emergencyManager = widget.emergencyManager ?? EmergencyAccessManager();
    _logSource = widget.logSource ?? EmergencyLogSource();
    _loadParentInfo();
    _listenEmergencyState();
  }

  void _listenEmergencyState() {
    _remainingSub = _emergencyManager.remainingStream.listen((remaining) {
      if (mounted) setState(() => _remainingSeconds = remaining);
    });
    _stateSub = _emergencyManager.stateStream.listen((state) {
      if (mounted) setState(() => _state = state);
    });
    _remainingSeconds = _emergencyManager.remainingSeconds;
    _state = _emergencyManager.isActive
        ? EmergencyState.active
        : _emergencyManager.cooldownUntil != null
            ? EmergencyState.cooldown
            : EmergencyState.inactive;
  }

  Future<void> _loadParentInfo() async {
    if (widget.parentUid == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Chưa liên kết tài khoản phụ huynh';
      });
      return;
    }

    try {
      final name = await _logSource.getParentName(widget.parentUid!);
      final phone = await _logSource.getParentPhoneNumber(widget.parentUid!);

      if (mounted) {
        setState(() {
          _parentName = name ?? 'Phụ huynh';
          _parentPhone = phone;
          _isLoading = false;
          if (phone == null || phone.isEmpty) {
            _errorMessage = 'Chưa có số điện thoại. Phụ huynh cần cập nhật số trong cài đặt.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không thể tải thông tin liên hệ';
        });
      }
    }
  }

  Future<void> _makeCall() async {
    if (_parentPhone == null) return;
    await _launchEmergencyAction('call', 'tel:$_parentPhone');
  }

  Future<void> _sendSms() async {
    if (_parentPhone == null) return;
    await _launchEmergencyAction('sms', 'sms:$_parentPhone');
  }

  Future<void> _launchEmergencyAction(String action, String url) async {
    final uri = Uri.parse(url);

    if (!await canLaunchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở ứng dụng. Vui lòng kiểm tra cài đặt thiết bị.')),
        );
      }
      return;
    }

    if (!_emergencyManager.isActive) {
      _emergencyManager.activate();
      await _logSource.logEmergencyStart(
        childUid: widget.childUid ?? '',
        familyId: widget.familyId ?? '',
        action: action,
        phoneNumber: _parentPhone!,
        appPackageName: widget.appPackageName ?? '',
      );
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _remainingSub?.cancel();
    _stateSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandleBar(),
          const SizedBox(height: 16),
          _buildTitle(),
          const SizedBox(height: 8),
          _buildSubtitle(),
          const SizedBox(height: 20),
          if (_state == EmergencyState.active) _buildActiveBanner(),
          if (_state == EmergencyState.cooldown) _buildCooldownBanner(),
          if (_state == EmergencyState.inactive) ...[
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else if (_errorMessage != null)
              _buildErrorState()
            else
              _buildContactCard(),
          ],
          const SizedBox(height: 20),
          if (!_isLoading && _errorMessage == null && _state == EmergencyState.inactive)
            _buildActionButtons(),
          const SizedBox(height: 12),
          _buildCloseButton(),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildHandleBar() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Icon(Icons.emergency, color: Colors.red.shade400, size: 28),
        const SizedBox(width: 10),
        const Text(
          'Liên hệ khẩn cấp',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Liên hệ trực tiếp với phụ huynh',
      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
    );
  }

  Widget _buildActiveBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Truy cập khẩn cấp: còn ${_formatTime(_remainingSeconds)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn có thể gọi hoặc nhắn tin cho phụ huynh trong thời gian này.',
            style: TextStyle(fontSize: 13, color: Colors.orange.shade700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCooldownBanner() {
    final cooldownSec = _emergencyManager.cooldownRemainingSeconds;
    final cooldownMin = (cooldownSec / 60).ceil();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(Icons.hourglass_disabled, color: Colors.grey.shade500, size: 32),
          const SizedBox(height: 8),
          Text(
            'Đã hết thời gian khẩn cấp',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Thử lại sau khoảng $cooldownMin phút',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF6B7FE8).withValues(alpha: 0.1),
            child: const Icon(Icons.person, color: Color(0xFF6B7FE8), size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _parentName ?? 'Phụ huynh',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  _parentPhone ?? '',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.warning_amber, color: Colors.red.shade400, size: 32),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(fontSize: 14, color: Colors.red.shade700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _makeCall,
            icon: const Icon(Icons.phone),
            label: const Text('Gọi điện'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green.shade600,
              side: BorderSide(color: Colors.green.shade300),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _sendSms,
            icon: const Icon(Icons.message),
            label: const Text('Nhắn tin'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6B7FE8),
              side: const BorderSide(color: Color(0xFF6B7FE8)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCloseButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Đóng'),
      ),
    );
  }
}
