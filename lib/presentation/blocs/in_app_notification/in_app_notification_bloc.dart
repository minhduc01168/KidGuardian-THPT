import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';
import 'package:kidguardian/core/utils/app_utils.dart';
import 'package:kidguardian/domain/repositories/time_request_repository.dart';

// Events
abstract class InAppNotificationEvent extends Equatable {
  const InAppNotificationEvent();
  @override
  List<Object?> get props => [];
}

class LoadInAppNotifications extends InAppNotificationEvent {
  final String familyId;
  const LoadInAppNotifications({required this.familyId});
  @override
  List<Object?> get props => [familyId];
}

class MarkInAppNotificationAsRead extends InAppNotificationEvent {
  final String notificationId;
  final String type;
  const MarkInAppNotificationAsRead({required this.notificationId, required this.type});
  @override
  List<Object?> get props => [notificationId, type];
}

class MarkAllInAppNotificationsAsRead extends InAppNotificationEvent {
  const MarkAllInAppNotificationsAsRead();
}

class InAppNotificationReceived extends InAppNotificationEvent {
  final InAppNotification notification;
  const InAppNotificationReceived(this.notification);
  @override
  List<Object?> get props => [notification.id];
}

// Model
class InAppNotification extends Equatable {
  final String id;
  final String type; // 'alert' or 'time_request'
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic> data;

  const InAppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.data = const {},
  });

  InAppNotification copyWith({bool? isRead}) {
    return InAppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      data: data,
    );
  }

  @override
  List<Object?> get props => [id, type, title, body, timestamp, isRead, data];
}

// States
abstract class InAppNotificationState extends Equatable {
  const InAppNotificationState();
  @override
  List<Object?> get props => [];
}

class InAppNotificationInitial extends InAppNotificationState {}

class InAppNotificationLoading extends InAppNotificationState {}

class InAppNotificationLoaded extends InAppNotificationState {
  final List<InAppNotification> notifications;
  final int unreadCount;

  const InAppNotificationLoaded({
    required this.notifications,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [notifications, unreadCount];
}

class InAppNotificationError extends InAppNotificationState {
  final String message;
  const InAppNotificationError(this.message);
  @override
  List<Object?> get props => [message];
}

class _NotificationsUpdated extends InAppNotificationEvent {
  const _NotificationsUpdated();
}

// BLoC
class InAppNotificationBloc extends Bloc<InAppNotificationEvent, InAppNotificationState> {
  final AlertRepository alertRepository;
  final TimeRequestRepository timeRequestRepository;

  StreamSubscription? _alertSubscription;
  StreamSubscription? _requestSubscription;
  String? _familyId;
  final List<InAppNotification> _notifications = [];
  final Set<String> _readIds = {};
  // BUG-3 FIX: SharedPreferences key để persist trạng thái đã đọc
  static const String _readIdsPrefKey = 'notif_read_ids';

  InAppNotificationBloc({
    required this.alertRepository,
    required this.timeRequestRepository,
  }) : super(InAppNotificationInitial()) {
    on<LoadInAppNotifications>(_onLoad);
    on<MarkInAppNotificationAsRead>(_onMarkAsRead);
    on<MarkAllInAppNotificationsAsRead>(_onMarkAllAsRead);
    on<InAppNotificationReceived>(_onNotificationReceived);
    on<_NotificationsUpdated>((event, emit) => _sortAndEmit(emit));
  }

  // BUG-3 FIX: Load _readIds từ SharedPreferences khi khởi động
  Future<void> _loadPersistedReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_readIdsPrefKey) ?? [];
      _readIds.addAll(saved);
    } catch (e) {
      debugPrint('InAppNotificationBloc: Failed to load persisted readIds: $e');
    }
  }

  // BUG-3 FIX: Persist _readIds sau khi mark as read
  Future<void> _persistReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_readIdsPrefKey, _readIds.toList());
    } catch (e) {
      debugPrint('InAppNotificationBloc: Failed to persist readIds: $e');
    }
  }

  void _onLoad(LoadInAppNotifications event, Emitter<InAppNotificationState> emit) {
    _familyId = event.familyId;
    _notifications.clear();
    // BUG-3 FIX: Không clear _readIds trước — load từ prefs trước
    _loadPersistedReadIds();

    emit(InAppNotificationLoading());

    _alertSubscription?.cancel();
    _alertSubscription = alertRepository
        .watchAllFamilyAlerts(familyId: event.familyId)
        .listen(
      (alerts) {
        for (final alert in alerts) {
          final isRead = alert.isReviewed || _readIds.contains(alert.id);
          final existingIndex = _notifications.indexWhere((n) => n.id == alert.id);

          // BUG-E FIX: Tạo title/body phù hợp theo từng loại alert
          String title;
          String body;
          String notifType;
          switch (alert.type) {
            case 'keyword_detected':
              title = '⚠️ Cảnh báo từ khóa';
              body = 'Phát hiện từ khóa "${alert.keyword}" trong ${AppUtils.getAppName(alert.packageName)}';
              notifType = 'alert';
              break;
            case 'app_blocked':
              title = '🔒 Ứng dụng bị chặn';
              body = '${AppUtils.getAppName(alert.packageName)} đã bị chặn do vượt giới hạn thời gian';
              notifType = 'alert';
              break;
            case 'time_request':
              // Bỏ qua time_request type từ alerts — đã được xử lý qua timeRequestRepository stream
              continue;
            default:
              title = 'Thông báo';
              body = alert.textContext.isNotEmpty ? alert.textContext : 'Có sự kiện mới';
              notifType = 'alert';
          }

          final notification = InAppNotification(
            id: alert.id,
            type: notifType,
            title: title,
            body: body,
            timestamp: (alert.timestamp ?? DateTime.now()).toLocal(),
            isRead: isRead,
            data: {
              'familyId': event.familyId,
              'childUid': alert.childUid,
              'alertId': alert.id,
              'keyword': alert.keyword,
              'packageName': alert.packageName,
              'alertType': alert.type,
            },
          );

          if (existingIndex != -1) {
            _notifications[existingIndex] = notification;
          } else {
            _notifications.add(notification);
          }
        }
        add(const _NotificationsUpdated());
      },
      onError: (error) {
        debugPrint('Alert stream error: $error');
      },
    );

    _requestSubscription?.cancel();
    _requestSubscription = timeRequestRepository
        .watchPendingRequests(familyId: event.familyId)
        .listen(
      (requests) {
        // BUG-3 FIX: REPLACE toàn bộ time_request entries thay vì append
        // Khi request approved → stream dừng emit nó → phải xóa khỏi list
        _notifications.removeWhere((n) => n.type == 'time_request');
        for (final req in requests) {
          _notifications.add(InAppNotification(
            id: req.id,
            type: 'time_request',
            title: 'Yêu cầu thêm thời gian',
            body: 'Yêu cầu ${req.requestedMinutes} phút cho ${AppUtils.getAppNameFromLog(req.appPackageName, req.appName)}',
            timestamp: req.timestamp.toLocal(),
            isRead: _readIds.contains(req.id),
            data: {
              'familyId': event.familyId,
              'childUid': req.childUid,
              'requestId': req.id,
              'packageName': req.appPackageName,
              'requestedMinutes': req.requestedMinutes,
            },
          ));
        }
        add(const _NotificationsUpdated());
      },
      onError: (error) {
        debugPrint('TimeRequest stream error: $error');
      },
    );

    _sortAndEmit(emit);
  }

  void _onNotificationReceived(
    InAppNotificationReceived event,
    Emitter<InAppNotificationState> emit,
  ) {
    _sortAndEmit(emit);
  }

  void _onMarkAsRead(
    MarkInAppNotificationAsRead event,
    Emitter<InAppNotificationState> emit,
  ) {
    _readIds.add(event.notificationId);
    // BUG-3 FIX: Persist ngay sau khi mark as read
    _persistReadIds();
    final index = _notifications.indexWhere((n) => n.id == event.notificationId);
    if (index != -1) {
      final notif = _notifications[index];
      _notifications[index] = notif.copyWith(isRead: true);

      // Nếu là alert, đồng bộ markAlertAsReviewed lên Firestore
      if (notif.type == 'alert') {
        final familyId = notif.data['familyId'] as String? ?? _familyId;
        final childUid = notif.data['childUid'] as String?;
        final alertId = notif.data['alertId'] as String? ?? notif.id;

        if (familyId != null && childUid != null) {
          alertRepository.markAlertAsReviewed(
            familyId: familyId,
            childUid: childUid,
            alertId: alertId,
          ).catchError((e) {
            debugPrint('Failed to mark alert as reviewed on Firestore: $e');
          });
        }
      }
    }
    _sortAndEmit(emit);
  }

  void _onMarkAllAsRead(
    MarkAllInAppNotificationsAsRead event,
    Emitter<InAppNotificationState> emit,
  ) {
    for (var i = 0; i < _notifications.length; i++) {
      final notif = _notifications[i];
      _readIds.add(notif.id);
      _notifications[i] = notif.copyWith(isRead: true);

      if (notif.type == 'alert') {
        final familyId = notif.data['familyId'] as String? ?? _familyId;
        final childUid = notif.data['childUid'] as String?;
        final alertId = notif.data['alertId'] as String? ?? notif.id;

        if (familyId != null && childUid != null) {
          alertRepository.markAlertAsReviewed(
            familyId: familyId,
            childUid: childUid,
            alertId: alertId,
          ).catchError((e) {
            debugPrint('Failed to mark alert as reviewed on Firestore: $e');
          });
        }
      }
    }
    _sortAndEmit(emit);
  }

  void _sortAndEmit(Emitter<InAppNotificationState> emit) {
    _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    emit(InAppNotificationLoaded(
      notifications: List.unmodifiable(_notifications),
      unreadCount: unreadCount,
    ));
  }

  @override
  Future<void> close() {
    _alertSubscription?.cancel();
    _requestSubscription?.cancel();
    return super.close();
  }
}
