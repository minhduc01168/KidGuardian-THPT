import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';
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

// BLoC
class InAppNotificationBloc extends Bloc<InAppNotificationEvent, InAppNotificationState> {
  final AlertRepository alertRepository;
  final TimeRequestRepository timeRequestRepository;

  StreamSubscription? _alertSubscription;
  StreamSubscription? _requestSubscription;
  String? _familyId;
  final List<InAppNotification> _notifications = [];
  final Set<String> _readIds = {};

  InAppNotificationBloc({
    required this.alertRepository,
    required this.timeRequestRepository,
  }) : super(InAppNotificationInitial()) {
    on<LoadInAppNotifications>(_onLoad);
    on<MarkInAppNotificationAsRead>(_onMarkAsRead);
    on<MarkAllInAppNotificationsAsRead>(_onMarkAllAsRead);
    on<InAppNotificationReceived>(_onNotificationReceived);
  }

  void _onLoad(LoadInAppNotifications event, Emitter<InAppNotificationState> emit) {
    _familyId = event.familyId;
    _notifications.clear();
    _readIds.clear();

    emit(InAppNotificationLoading());

    _alertSubscription?.cancel();
    _alertSubscription = alertRepository
        .watchAllFamilyAlerts(familyId: event.familyId)
        .listen(
      (alerts) {
        for (final alert in alerts) {
          final existing = _notifications.where((n) => n.id == alert.id).firstOrNull;
          if (existing == null) {
            final notification = InAppNotification(
              id: alert.id,
              type: 'alert',
              title: 'Cảnh báo an toàn',
              body: 'Phát hiện từ khóa "${alert.keyword}" trong ${alert.packageName}',
              timestamp: alert.timestamp ?? DateTime.now(),
              isRead: _readIds.contains(alert.id),
              data: {
                'familyId': event.familyId,
                'childUid': alert.childUid,
                'alertId': alert.id,
                'keyword': alert.keyword,
                'packageName': alert.packageName,
              },
            );
            _notifications.add(notification);
            add(InAppNotificationReceived(notification));
          }
        }
        _sortAndEmit(emit);
      },
      onError: (error) {
        debugPrint('Alert stream error: $error');
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
    final index = _notifications.indexWhere((n) => n.id == event.notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
    _sortAndEmit(emit);
  }

  void _onMarkAllAsRead(
    MarkAllInAppNotificationsAsRead event,
    Emitter<InAppNotificationState> emit,
  ) {
    for (var i = 0; i < _notifications.length; i++) {
      _readIds.add(_notifications[i].id);
      _notifications[i] = _notifications[i].copyWith(isRead: true);
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
