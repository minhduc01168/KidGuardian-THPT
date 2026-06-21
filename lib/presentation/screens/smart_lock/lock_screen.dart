import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kidguardian/platform/android/accessibility_channel.dart';
import 'package:kidguardian/domain/usecases/smart_lock/emergency_access_manager.dart';
import 'package:kidguardian/presentation/widgets/smart_lock/app_icon_display.dart';
import 'package:kidguardian/presentation/widgets/smart_lock/countdown_timer.dart';
import 'package:kidguardian/presentation/widgets/smart_lock/request_time_dialog.dart';
import 'package:kidguardian/presentation/widgets/smart_lock/emergency_contact_sheet.dart';

class LockScreen extends StatefulWidget {
  final String appPackageName;
  final String appName;
  final String? iconUrl;
  final int limitMinutes;
  final int usedMinutes;
  final DateTime resetTime;
  final String? familyId;
  final String? childUid;
  final String? parentUid;
  final String? blockReason;
  final String? scheduleName;

  const LockScreen({
    super.key,
    required this.appPackageName,
    required this.appName,
    this.iconUrl,
    required this.limitMinutes,
    required this.usedMinutes,
    required this.resetTime,
    this.familyId,
    this.childUid,
    this.parentUid,
    this.blockReason,
    this.scheduleName,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with TickerProviderStateMixin {
  bool _isReset = false;
  final _emergencyManager = EmergencyAccessManager();
  StreamSubscription<int>? _emergencySub;
  StreamSubscription<EmergencyState>? _emergencyStateSub;
  int _emergencyRemaining = 0;
  bool _emergencyActive = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _emergencySub = _emergencyManager.remainingStream.listen((remaining) {
      if (mounted) setState(() => _emergencyRemaining = remaining);
    });
    _emergencyStateSub = _emergencyManager.stateStream.listen((state) {
      if (mounted) setState(() => _emergencyActive = state == EmergencyState.active);
    });
    _emergencyActive = _emergencyManager.isActive;
    _emergencyRemaining = _emergencyManager.remainingSeconds;
    
    // Pulse animation for emergency banner
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _emergencySub?.cancel();
    _emergencyStateSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _onReset() {
    setState(() {
      _isReset = true;
    });
  }

  void _goHome() {
    AccessibilityChannel.moveTaskToBack().catchError((e) {
      debugPrint('LockScreen._goHome error: $e');
    });
  }

  String _formatEmergencyTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showRequestTimeDialog() {
    showDialog(
      context: context,
      builder: (_) => RequestTimeDialog(
        appPackageName: widget.appPackageName,
        appName: widget.appName,
        familyId: widget.familyId,
        childUid: widget.childUid,
      ),
    );
  }

  void _showEmergencyContactSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EmergencyContactSheet(
        familyId: widget.familyId,
        childUid: widget.childUid,
        parentUid: widget.parentUid,
        appPackageName: widget.appPackageName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6B7FE8),
                Color(0xFF8B5CF6),
                Color(0xFF9B6BCC),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          // App icon with glow effect
                          Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: AppIconDisplay(
                              iconUrl: widget.iconUrl,
                              appName: widget.appName,
                              size: 80,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // App name
                          Text(
                            widget.appName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          // Block reason
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.lock_outline,
                                      color: Colors.white.withOpacity(0.9),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        widget.blockReason == 'schedule' && widget.scheduleName != null
                                            ? 'Đang trong ${widget.scheduleName!.toLowerCase()}'
                                            : 'Bạn đã sử dụng hết thời gian cho phép hôm nay',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                                if (widget.blockReason != 'schedule') ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Đã dùng: ${widget.usedMinutes}/${widget.limitMinutes} phút',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Countdown timer
                          CountdownTimer(
                            resetTime: widget.resetTime,
                            onReset: _onReset,
                          ),
                          const SizedBox(height: 24),
                          // Emergency access banner
                          if (_emergencyActive) ...[
                            ScaleTransition(
                              scale: _pulseAnimation,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.orange.shade500, Colors.orange.shade700],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.4),
                                      blurRadius: 15,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.timer, color: Colors.white, size: 22),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Truy cập khẩn cấp: còn ${_formatEmergencyTime(_emergencyRemaining)}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Action buttons
                          if (_isReset) ...[
                            // Show close button when reset
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [Colors.green.shade400, Colors.green.shade600],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _goHome,
                                icon: const Icon(Icons.check_circle, size: 22),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: const Text(
                                    'Giới hạn đã được đặt lại',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _goHome,
                              icon: Icon(Icons.home, color: Colors.white70),
                              label: Text(
                                'Về màn hình chính',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ] else ...[
                            // Request more time button (only for time limit blocks)
                            if (widget.blockReason != 'schedule') ...[
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _showRequestTimeDialog,
                                  icon: const Icon(Icons.access_time, size: 22),
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: const Text(
                                      'Xin thêm thời gian',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF6B7FE8),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            // Emergency contact button
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: OutlinedButton.icon(
                                onPressed: _showEmergencyContactSheet,
                                icon: const Icon(Icons.emergency, size: 22),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: const Text(
                                    'Liên hệ khẩn cấp',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Go home button
                            TextButton.icon(
                              onPressed: _goHome,
                              icon: const Icon(Icons.home, size: 20),
                              label: const Text(
                                'Quay về màn hình chính',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white70,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              ),
                            ),
                          ],
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
