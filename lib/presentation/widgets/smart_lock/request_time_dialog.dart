import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidguardian/domain/repositories/time_request_repository.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';
import 'package:kidguardian/domain/repositories/rules_repository.dart';
import 'package:kidguardian/presentation/blocs/time_request/time_request_bloc.dart';

class AppOption {
  final String packageName;
  final String appName;
  const AppOption(this.packageName, this.appName);
}

class RequestTimeDialog extends StatefulWidget {
  final String appPackageName;
  final String appName;
  final String? familyId;
  final String? childUid;

  const RequestTimeDialog({
    super.key,
    required this.appPackageName,
    required this.appName,
    this.familyId,
    this.childUid,
  });

  @override
  State<RequestTimeDialog> createState() => _RequestTimeDialogState();
}

class _RequestTimeDialogState extends State<RequestTimeDialog> {
  int _selectedMinutes = 15;
  final _reasonController = TextEditingController();

  late String _selectedPackageName;
  late String _selectedAppName;

  static const _minuteOptions = [15, 30, 60];

  static const List<AppOption> _commonMonitoredApps = [
    AppOption('com.zhiliaoapp.musically', 'TikTok'),
    AppOption('com.facebook.katana', 'Facebook'),
    AppOption('com.instagram.android', 'Instagram'),
    AppOption('com.zing.zalo', 'Zalo'),
    AppOption('com.google.android.youtube', 'YouTube'),
    AppOption('com.instagram.barcelona', 'Threads'),
    AppOption('com.locket.locket', 'Locket'),
    AppOption('com.discord', 'Discord'),
    AppOption('com.facebook.orca', 'Messenger'),
    AppOption('org.telegram.messenger', 'Telegram'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.appPackageName == 'general_time' || widget.appPackageName.isEmpty) {
      _selectedPackageName = _commonMonitoredApps.first.packageName;
      _selectedAppName = _commonMonitoredApps.first.appName;
    } else {
      _selectedPackageName = widget.appPackageName;
      _selectedAppName = widget.appName;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TimeRequestBloc(
        repository: context.read<TimeRequestRepository>(),
        alertRepository: context.read<AlertRepository>(),
        rulesRepository: context.read<RulesRepository>(),
      ),
      child: BlocConsumer<TimeRequestBloc, TimeRequestState>(
        listener: (context, state) {
          if (state is TimeRequestSubmitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          }
          if (state is TimeRequestError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TimeRequestSubmitted) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Đã gửi yêu cầu đến phụ huynh',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vui lòng chờ phản hồi từ phụ huynh.\nBạn đã xin thêm $_selectedMinutes phút cho $_selectedAppName.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B7FE8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Đóng'),
                    ),
                  ),
                ],
              ),
            );
          }

          final isGeneralRequest = widget.appPackageName == 'general_time' || widget.appPackageName.isEmpty;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.access_time, color: const Color(0xFF6B7FE8)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Xin thêm thời gian',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isGeneralRequest) ...[
                    const Text(
                      'Chọn ứng dụng muốn chơi thêm:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPackageName,
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: _commonMonitoredApps.map((app) {
                        return DropdownMenuItem<String>(
                          value: app.packageName,
                          child: Text(
                            app.appName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                      onChanged: state is TimeRequestSubmitting
                          ? null
                          : (val) {
                              if (val != null) {
                                final selected = _commonMonitoredApps.firstWhere((a) => a.packageName == val);
                                setState(() {
                                  _selectedPackageName = selected.packageName;
                                  _selectedAppName = selected.appName;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Text(
                      'Ứng dụng: ${widget.appName}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'Chọn số phút muốn xin thêm:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _minuteOptions.map((minutes) {
                      final isSelected = _selectedMinutes == minutes;
                      return ChoiceChip(
                        label: Text('$minutes phút'),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedMinutes = minutes),
                        selectedColor: const Color(0xFF6B7FE8),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      labelText: 'Lý do (tùy chọn)',
                      hintText: 'VD: Con cần thêm thời gian để giải trí...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    maxLines: 2,
                    maxLength: 500,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: state is TimeRequestSubmitting ? null : () => Navigator.of(context).pop(),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: state is TimeRequestSubmitting
                    ? null
                    : () {
                        if (widget.familyId != null && widget.childUid != null) {
                          context.read<TimeRequestBloc>().add(SubmitTimeRequest(
                            familyId: widget.familyId!,
                            childUid: widget.childUid!,
                            appPackageName: _selectedPackageName,
                            appName: _selectedAppName,
                            requestedMinutes: _selectedMinutes,
                            reason: _reasonController.text.trim(),
                          ));
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B7FE8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: state is TimeRequestSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Gửi yêu cầu'),
              ),
            ],
          );
        },
      ),
    );
  }
}
