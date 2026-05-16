import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kidguardian/platform/android/accessibility_channel.dart';
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
    this.blockReason,
    this.scheduleName,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _isReset = false;

  void _onReset() {
    setState(() {
      _isReset = true;
    });
  }

  void _goHome() {
    // P3 + P7: Use AccessibilityChannel with error handling
    AccessibilityChannel.moveTaskToBack().catchError((e) {
      debugPrint('LockScreen._goHome error: $e');
    });
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
      builder: (_) => const EmergencyContactSheet(),
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
                Color(0xFF9B6BCC),
              ],
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
                          // App icon
                          AppIconDisplay(
                            iconUrl: widget.iconUrl,
                            appName: widget.appName,
                            size: 80,
                          ),
                          const SizedBox(height: 16),
                          // App name
                          Text(
                            widget.appName,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          // Block reason
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  widget.blockReason == 'schedule' && widget.scheduleName != null
                                      ? 'Đang trong ${widget.scheduleName!.toLowerCase()}'
                                      : 'Bạn đã sử dụng hết thời gian cho phép hôm nay',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (widget.blockReason != 'schedule') ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Đã dùng: ${widget.usedMinutes}/${widget.limitMinutes} phút',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                    textAlign: TextAlign.center,
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
                          // Action buttons
                          if (_isReset) ...[
                            // Show close button when reset
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _goHome,
                                icon: const Icon(Icons.check_circle),
                                label: const Text(
                                  'Giới hạn đã được đặt lại - Về màn hình chính',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade400,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            // Request more time button (only for time limit blocks)
                            if (widget.blockReason != 'schedule') ...[
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _showRequestTimeDialog,
                                  icon: const Icon(Icons.access_time),
                                  label: const Text(
                                    'Xin thêm thời gian',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF6B7FE8),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            // Emergency contact button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _showEmergencyContactSheet,
                                icon: const Icon(Icons.emergency),
                                label: const Text(
                                  'Liên hệ khẩn cấp',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Colors.white70,
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Go home button
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: _goHome,
                                icon: const Icon(Icons.home),
                                label: const Text(
                                  'Quay về màn hình chính',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
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
