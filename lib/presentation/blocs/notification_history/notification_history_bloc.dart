import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kidguardian/domain/repositories/notification_repository.dart';

// Events
abstract class NotificationHistoryEvent extends Equatable {
  const NotificationHistoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationHistoryEvent {
  final String familyId;
  const LoadNotifications({required this.familyId});
  @override
  List<Object?> get props => [familyId];
}

class FilterByReadStatus extends NotificationHistoryEvent {
  final NotificationFilterStatus status;
  const FilterByReadStatus(this.status);
  @override
  List<Object?> get props => [status];
}

class FilterByType extends NotificationHistoryEvent {
  final NotificationType? type;
  const FilterByType(this.type);
  @override
  List<Object?> get props => [type];
}

class MarkAsReadEvent extends NotificationHistoryEvent {
  final String familyId;
  final String childUid;
  final String notificationId;
  const MarkAsReadEvent({
    required this.familyId,
    required this.childUid,
    required this.notificationId,
  });
  @override
  List<Object?> get props => [notificationId];
}

class MarkAllAsReadEvent extends NotificationHistoryEvent {
  final String familyId;
  final String childUid;
  const MarkAllAsReadEvent({
    required this.familyId,
    required this.childUid,
  });
  @override
  List<Object?> get props => [familyId, childUid];
}

class ClearOldNotificationsEvent extends NotificationHistoryEvent {
  final String familyId;
  final String childUid;
  final int daysOld;
  const ClearOldNotificationsEvent({
    required this.familyId,
    required this.childUid,
    this.daysOld = 30,
  });
  @override
  List<Object?> get props => [familyId, childUid, daysOld];
}

class _NotificationsUpdated extends NotificationHistoryEvent {
  final List<NotificationModel> notifications;
  const _NotificationsUpdated(this.notifications);
  @override
  List<Object?> get props => [notifications.map((n) => n.id).toList()];
}

// Enums
enum NotificationFilterStatus { all, unread, read }

// States
abstract class NotificationHistoryState extends Equatable {
  const NotificationHistoryState();
  @override
  List<Object?> get props => [];
}

class NotificationHistoryInitial extends NotificationHistoryState {}

class NotificationHistoryLoading extends NotificationHistoryState {}

class NotificationHistoryLoaded extends NotificationHistoryState {
  final List<NotificationModel> allNotifications;
  final List<NotificationModel> filteredNotifications;
  final NotificationFilterStatus filterStatus;
  final NotificationType? filterType;
  final int unreadCount;

  const NotificationHistoryLoaded({
    required this.allNotifications,
    required this.filteredNotifications,
    this.filterStatus = NotificationFilterStatus.all,
    this.filterType,
    this.unreadCount = 0,
  });

  @override
  List<Object?> get props => [
        filteredNotifications.map((n) => n.id).toList(),
        filterStatus,
        filterType,
        unreadCount,
      ];
}

class NotificationHistoryError extends NotificationHistoryState {
  final String message;
  const NotificationHistoryError(this.message);
  @override
  List<Object?> get props => [message];
}

class NotificationHistoryBloc
    extends Bloc<NotificationHistoryEvent, NotificationHistoryState> {
  final NotificationRepository notificationRepository;
  StreamSubscription? _notificationSubscription;
  List<NotificationModel> _allNotifications = [];
  NotificationFilterStatus _filterStatus = NotificationFilterStatus.all;
  NotificationType? _filterType;

  NotificationHistoryBloc({required this.notificationRepository})
      : super(NotificationHistoryInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<FilterByReadStatus>(_onFilterByReadStatus);
    on<FilterByType>(_onFilterByType);
    on<MarkAsReadEvent>(_onMarkAsRead);
    on<MarkAllAsReadEvent>(_onMarkAllAsRead);
    on<ClearOldNotificationsEvent>(_onClearOldNotifications);
    on<_NotificationsUpdated>(_onNotificationsUpdated);
  }

  void _onLoadNotifications(
      LoadNotifications event, Emitter<NotificationHistoryState> emit) {
    emit(NotificationHistoryLoading());

    _notificationSubscription?.cancel();
    _notificationSubscription = notificationRepository
        .watchAllNotifications(familyId: event.familyId)
        .listen(
      (notifications) {
        add(_NotificationsUpdated(notifications));
      },
      onError: (error) {
        debugPrint('Notification stream error: $error');
      },
    );
  }

  void _onNotificationsUpdated(
      _NotificationsUpdated event, Emitter<NotificationHistoryState> emit) {
    _allNotifications = event.notifications;
    _emitFiltered(emit);
  }

  void _onFilterByReadStatus(
      FilterByReadStatus event, Emitter<NotificationHistoryState> emit) {
    _filterStatus = event.status;
    _emitFiltered(emit);
  }

  void _onFilterByType(
      FilterByType event, Emitter<NotificationHistoryState> emit) {
    _filterType = event.type;
    _emitFiltered(emit);
  }

  Future<void> _onMarkAsRead(
      MarkAsReadEvent event, Emitter<NotificationHistoryState> emit) async {
    try {
      await notificationRepository.markAsRead(
        familyId: event.familyId,
        childUid: event.childUid,
        notificationId: event.notificationId,
      );
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      emit(NotificationHistoryError('Không thể đánh dấu đã đọc'));
    }
  }

  Future<void> _onMarkAllAsRead(
      MarkAllAsReadEvent event, Emitter<NotificationHistoryState> emit) async {
    try {
      await notificationRepository.markAllAsRead(
        familyId: event.familyId,
        childUid: event.childUid,
      );
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      emit(NotificationHistoryError('Không thể đánh dấu tất cả đã đọc'));
    }
  }

  Future<void> _onClearOldNotifications(ClearOldNotificationsEvent event,
      Emitter<NotificationHistoryState> emit) async {
    try {
      final olderThan =
          DateTime.now().subtract(Duration(days: event.daysOld));
      await notificationRepository.clearOldNotifications(
        familyId: event.familyId,
        childUid: event.childUid,
        olderThan: olderThan,
      );
    } catch (e) {
      debugPrint('Error clearing old notifications: $e');
      emit(NotificationHistoryError('Không thể xóa thông báo cũ'));
    }
  }

  void _emitFiltered(Emitter<NotificationHistoryState> emit) {
    var filtered = List<NotificationModel>.from(_allNotifications);

    // Filter by read status
    if (_filterStatus == NotificationFilterStatus.unread) {
      filtered = filtered.where((n) => !n.isRead).toList();
    } else if (_filterStatus == NotificationFilterStatus.read) {
      filtered = filtered.where((n) => n.isRead).toList();
    }

    // Filter by type
    if (_filterType != null) {
      filtered = filtered.where((n) => n.type == _filterType).toList();
    }

    final unreadCount = _allNotifications.where((n) => !n.isRead).length;

    emit(NotificationHistoryLoaded(
      allNotifications: _allNotifications,
      filteredNotifications: filtered,
      filterStatus: _filterStatus,
      filterType: _filterType,
      unreadCount: unreadCount,
    ));
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    return super.close();
  }
}
