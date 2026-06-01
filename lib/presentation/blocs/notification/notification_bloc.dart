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

// States
abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}
class NotificationListening extends NotificationState {
  final int pendingAlertCount;
  const NotificationListening({this.pendingAlertCount = 0});
  @override
  List<Object?> get props => [pendingAlertCount];
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
  String? _familyId;
  String? _childUid;
  Set<String> _notifiedAlertIds = {};

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
  }

  void _onStartListening(StartAlertListening event, Emitter<NotificationState> emit) {
    _familyId = event.familyId;
    _childUid = null;
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
    _childUid = null;
    _notifiedAlertIds = {};
    emit(NotificationInitial());
  }

  Future<void> _onAlertReceived(AlertReceived event, Emitter<NotificationState> emit) async {
    final alert = event.alert;
    
    await _showNotification(
      id: alert.id.hashCode,
      title: 'Cảnh báo an toàn',
      body: 'Phát hiện từ khóa "${alert.keyword}" trong ứng dụng ${alert.packageName}',
      payload: alert.id,
    );

    emit(NotificationListening(pendingAlertCount: _notifiedAlertIds.length));
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
    return super.close();
  }
}
