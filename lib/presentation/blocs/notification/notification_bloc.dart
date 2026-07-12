import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';
import 'package:kidguardian/domain/repositories/time_request_repository.dart';

// Events
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class StartAlertListening extends NotificationEvent {
  final String familyId;
  const StartAlertListening({required this.familyId});
  @override
  List<Object?> get props => [familyId];
}

class StopAlertListening extends NotificationEvent {}

class AlertReceived extends NotificationEvent {
  final AlertModel alert;
  const AlertReceived(this.alert);
  @override
  List<Object?> get props => [alert.id];
}

class MarkAlertReviewed extends NotificationEvent {
  final String familyId;
  final String childUid;
  final String alertId;
  const MarkAlertReviewed({
    required this.familyId,
    required this.childUid,
    required this.alertId,
  });
  @override
  List<Object?> get props => [alertId];
}

class QuickApproveRequest extends NotificationEvent {
  final String familyId;
  final String childUid;
  final String requestId;
  const QuickApproveRequest({
    required this.familyId,
    required this.childUid,
    required this.requestId,
  });
  @override
  List<Object?> get props => [requestId];
}

class QuickRejectRequest extends NotificationEvent {
  final String familyId;
  final String childUid;
  final String requestId;
  const QuickRejectRequest({
    required this.familyId,
    required this.childUid,
    required this.requestId,
  });
  @override
  List<Object?> get props => [requestId];
}

/// FIX C3: Bắt đầu lắng nghe time requests theo realtime (Phương án B - không cần Cloud Functions)
class StartTimeRequestListening extends NotificationEvent {
  final String familyId;
  final List<String> childUids;
  const StartTimeRequestListening({
    required this.familyId,
    required this.childUids,
  });
  @override
  List<Object?> get props => [familyId, childUids];
}

class StopTimeRequestListening extends NotificationEvent {}

/// Internal event khi phát hiện time request mới
class _TimeRequestReceived extends NotificationEvent {
  final TimeRequest request;
  final String childUid;
  const _TimeRequestReceived(this.request, this.childUid);
  @override
  List<Object?> get props => [request.id];
}

// States
abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}
class NotificationListening extends NotificationState {
  final int pendingAlertCount;
  final int pendingTimeRequestCount;
  const NotificationListening({
    this.pendingAlertCount = 0,
    this.pendingTimeRequestCount = 0,
  });
  @override
  List<Object?> get props => [pendingAlertCount, pendingTimeRequestCount];
}
class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message);
  @override
  List<Object?> get props => [message];
}

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final AlertRepository alertRepository;
  final TimeRequestRepository timeRequestRepository;
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  
  StreamSubscription? _alertSubscription;
  StreamSubscription? _timeRequestSubscription; // FIX C3
  String? _familyId;
  Set<String> _notifiedAlertIds = {};
  Set<String> _notifiedRequestIds = {}; // FIX C3: track để tránh notify trùng lặp

  NotificationBloc({
    required this.alertRepository,
    required this.timeRequestRepository,
    FlutterLocalNotificationsPlugin? notificationsPlugin,
  })  : _notificationsPlugin = notificationsPlugin ?? FlutterLocalNotificationsPlugin(),
        super(NotificationInitial()) {
    on<StartAlertListening>(_onStartListening);
    on<StopAlertListening>(_onStopListening);
    on<AlertReceived>(_onAlertReceived);
    on<MarkAlertReviewed>(_onMarkReviewed);
    on<QuickApproveRequest>(_onQuickApprove);
    on<QuickRejectRequest>(_onQuickReject);
    // FIX C3
    on<StartTimeRequestListening>(_onStartTimeRequestListening);
    on<StopTimeRequestListening>(_onStopTimeRequestListening);
    on<_TimeRequestReceived>(_onTimeRequestReceived);
  }

  Future<void> initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );
    // FIX #3: Tạo các notification channel cần thiết ngay từ khi khởi động
    // Android sẽ silently drop notification nếu channel chưa được tạo trước
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    // Channel cho cảnh báo từ khoá động và keyword alerts (HIGH priority)
    await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
      'kidguardian_alerts',
      'Cảnh báo an toàn',
      description: 'Thông báo cảnh báo từ khoá nguy hiểm và bạo lực',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ));

    // Channel cho yêu cầu xin thêm thời gian (HIGH priority)
    await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
      'kidguardian_requests',
      'Yêu cầu thời gian',
      description: 'Thông báo khi con xin thêm thời gian sử dụng app',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ));

    debugPrint('NotificationBloc: Notification channels created successfully');
  }

  void _onStartListening(StartAlertListening event, Emitter<NotificationState> emit) {
    if (_alertSubscription != null && _familyId == event.familyId) return;
    _familyId = event.familyId;
    _notifiedAlertIds = {};

    _alertSubscription?.cancel();
    _alertSubscription = alertRepository
        .watchAllFamilyAlerts(familyId: event.familyId)
        .listen(
      (alerts) {
        final currentIds = alerts.map((a) => a.id).toSet();
        _notifiedAlertIds.removeWhere((id) => !currentIds.contains(id));
        for (final alert in alerts) {
          if (!_notifiedAlertIds.contains(alert.id)) {
            _notifiedAlertIds.add(alert.id);
            add(AlertReceived(alert));
          }
        }
      },
      onError: (error) {
        debugPrint('Alert stream error: $error');
      },
    );

    emit(const NotificationListening());
  }

  void _onStopListening(StopAlertListening event, Emitter<NotificationState> emit) {
    _alertSubscription?.cancel();
    _alertSubscription = null;
    _familyId = null;
    _notifiedAlertIds = {};
    emit(NotificationInitial());
  }

  // ─── FIX C3: Firestore realtime stream cho Time Requests ─────────────────

  void _onStartTimeRequestListening(
    StartTimeRequestListening event,
    Emitter<NotificationState> emit,
  ) {
    // FIX #2: Guard bug — phải cập nhật _familyId trước khi check
    if (_timeRequestSubscription != null && _familyId == event.familyId) return;
    _familyId = event.familyId; // Cập nhật trước khi restart listener
    _timeRequestSubscription?.cancel();
    _notifiedRequestIds = {};

    // watchPendingRequests dùng collectionGroup — tự filter theo familyId
    _timeRequestSubscription = timeRequestRepository
        .watchPendingRequests(familyId: event.familyId)
        .listen(
      (requests) {
        for (final req in requests) {
          if (!_notifiedRequestIds.contains(req.id)) {
            _notifiedRequestIds.add(req.id);
            add(_TimeRequestReceived(req, req.childUid));
          }
        }
      },
      onError: (error) => debugPrint('TimeRequest stream error: $error'),
    );

    emit(const NotificationListening()); // Emit initial listening state
  }

  void _onStopTimeRequestListening(
    StopTimeRequestListening event,
    Emitter<NotificationState> emit,
  ) {
    _timeRequestSubscription?.cancel();
    _timeRequestSubscription = null;
    _notifiedRequestIds = {};
  }

  Future<void> _onTimeRequestReceived(
    _TimeRequestReceived event,
    Emitter<NotificationState> emit,
  ) async {
    final req = event.request;
    // FIX #2: Bỏ qua request quá cũ (> 5 phút) khi phụ huynh mở app lần đầu
    // Tránh spam notification cho các pending requests đã tồn tại trước khi app khởi động
    final ageMinutes = DateTime.now().difference(req.timestamp).inMinutes;
    if (ageMinutes > 5) {
      _notifiedRequestIds.add(req.id); // Ghi nhớ để không notify lần sau
      debugPrint('TimeRequest ${req.id} is ${ageMinutes}min old, skipping notification');
      emit(NotificationListening(
        pendingAlertCount: _notifiedAlertIds.length,
        pendingTimeRequestCount: _notifiedRequestIds.length,
      ));
      return;
    }
    await _showTimeRequestNotification(
      id: req.id.hashCode,
      appName: req.appName,
      requestedMinutes: req.requestedMinutes,
      reason: req.reason,
      payload: 'time_request:${req.id}:${event.childUid}',
    );
    emit(NotificationListening(
      pendingAlertCount: _notifiedAlertIds.length,
      pendingTimeRequestCount: _notifiedRequestIds.length,
    ));
  }

  Future<void> _onAlertReceived(AlertReceived event, Emitter<NotificationState> emit) async {
    final alert = event.alert;
    // FIX #3: Chỉ hiển notification cho keyword_detected, bỏ qua app_blocked (spam)
    if (alert.type != 'keyword_detected') {
      emit(NotificationListening(
        pendingAlertCount: _notifiedAlertIds.length,
        pendingTimeRequestCount: _notifiedRequestIds.length,
      ));
      return;
    }
    await _showNotification(
      id: alert.id.hashCode,
      title: '⚠️ Cảnh báo từ khoá nguy hiểm',
      body: 'Phát hiện "${alert.keyword}" trong ${alert.packageName}. Nhấn để xem chi tiết.',
      payload: alert.id,
    );

    emit(NotificationListening(
      pendingAlertCount: _notifiedAlertIds.length,
      pendingTimeRequestCount: _notifiedRequestIds.length,
    ));
  }

  Future<void> _onMarkReviewed(MarkAlertReviewed event, Emitter<NotificationState> emit) async {
    try {
      await alertRepository.markAlertAsReviewed(
        familyId: event.familyId,
        childUid: event.childUid,
        alertId: event.alertId,
      );
      _notifiedAlertIds.remove(event.alertId);
      emit(NotificationListening(pendingAlertCount: _notifiedAlertIds.length));
    } catch (e) {
      debugPrint('Error marking alert as reviewed: $e');
      emit(NotificationError('Failed to mark alert as reviewed'));
    }
  }

  Future<void> _onQuickApprove(QuickApproveRequest event, Emitter<NotificationState> emit) async {
    try {
      await timeRequestRepository.approveRequest(
        familyId: event.familyId,
        childUid: event.childUid,
        requestId: event.requestId,
        response: 'Đã duyệt nhanh từ thông báo',
      );
      await _showConfirmationNotification(
        title: 'Đã duyệt yêu cầu',
        body: 'Bạn đã duyệt yêu cầu thêm thời gian',
        isApproved: true,
      );
      emit(NotificationListening(pendingAlertCount: _notifiedAlertIds.length));
    } catch (e) {
      debugPrint('Error quick approving request: $e');
      emit(NotificationError('Failed to approve request'));
    }
  }

  Future<void> _onQuickReject(QuickRejectRequest event, Emitter<NotificationState> emit) async {
    try {
      await timeRequestRepository.rejectRequest(
        familyId: event.familyId,
        childUid: event.childUid,
        requestId: event.requestId,
        response: 'Đã từ chối nhanh từ thông báo',
      );
      await _showConfirmationNotification(
        title: 'Đã từ chối yêu cầu',
        body: 'Bạn đã từ chối yêu cầu thêm thời gian',
        isApproved: false,
      );
      emit(NotificationListening(pendingAlertCount: _notifiedAlertIds.length));
    } catch (e) {
      debugPrint('Error quick rejecting request: $e');
      emit(NotificationError('Failed to reject request'));
    }
  }

  Future<void> _showConfirmationNotification({
    required String title,
    required String body,
    required bool isApproved,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'kidguardian_alerts',
      'Safety Alerts',
      channelDescription: 'Notifications for safety keyword alerts',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      autoCancel: true,
      color: isApproved ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _notificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> _showTimeRequestNotification({
    required int id,
    required String appName,
    required int requestedMinutes,
    required String reason,
    String? payload,
  }) async {
    // FIX #2: Dùng đúng channel 'kidguardian_requests' cho time requests
    const androidDetails = AndroidNotificationDetails(
      'kidguardian_requests',
      'Yêu cầu thời gian',
      channelDescription: 'Thông báo khi con xin thêm thời gian sử dụng app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _notificationsPlugin.show(
      id: id,
      title: '📱 Con xin thêm thời gian',
      body: '$appName: xin thêm $requestedMinutes phút. Lý do: ${reason.isNotEmpty ? reason : "Không có"}',
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'kidguardian_alerts',
      'Safety Alerts',
      channelDescription: 'Notifications for safety keyword alerts',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  @override
  Future<void> close() {
    _alertSubscription?.cancel();
    _timeRequestSubscription?.cancel(); // FIX C3
    return super.close();
  }
}
