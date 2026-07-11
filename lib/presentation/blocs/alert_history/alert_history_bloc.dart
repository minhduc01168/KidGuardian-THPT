import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';

// Events
abstract class AlertHistoryEvent extends Equatable {
  const AlertHistoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadAlerts extends AlertHistoryEvent {
  final String familyId;
  final String childUid;
  const LoadAlerts({required this.familyId, required this.childUid});
  @override
  List<Object?> get props => [familyId, childUid];
}

class FilterByStatus extends AlertHistoryEvent {
  final AlertFilterStatus status;
  const FilterByStatus(this.status);
  @override
  List<Object?> get props => [status];
}

class FilterByDateRange extends AlertHistoryEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  const FilterByDateRange({this.startDate, this.endDate});
  @override
  List<Object?> get props => [startDate, endDate];
}

class MarkAlertReviewedEvent extends AlertHistoryEvent {
  final String familyId;
  final String childUid;
  final String alertId;
  const MarkAlertReviewedEvent({
    required this.familyId,
    required this.childUid,
    required this.alertId,
  });
  @override
  List<Object?> get props => [alertId];
}

class _AlertsUpdated extends AlertHistoryEvent {
  final List<AlertModel> alerts;
  const _AlertsUpdated(this.alerts);
  @override
  List<Object?> get props => [alerts.map((a) => a.id).toList()];
}

// Enums
enum AlertFilterStatus { all, unreviewed, reviewed }

// States
abstract class AlertHistoryState extends Equatable {
  const AlertHistoryState();
  @override
  List<Object?> get props => [];
}

class AlertHistoryInitial extends AlertHistoryState {}
class AlertHistoryLoading extends AlertHistoryState {}
class AlertHistoryLoaded extends AlertHistoryState {
  final List<AlertModel> allAlerts;
  final List<AlertModel> filteredAlerts;
  final AlertFilterStatus filterStatus;
  final DateTime? startDate;
  final DateTime? endDate;

  const AlertHistoryLoaded({
    required this.allAlerts,
    required this.filteredAlerts,
    this.filterStatus = AlertFilterStatus.all,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [filteredAlerts.map((a) => a.id).toList(), filterStatus, startDate, endDate];
}
class AlertHistoryError extends AlertHistoryState {
  final String message;
  const AlertHistoryError(this.message);
  @override
  List<Object?> get props => [message];
}

class AlertHistoryBloc extends Bloc<AlertHistoryEvent, AlertHistoryState> {
  final AlertRepository alertRepository;
  StreamSubscription? _alertSubscription;
  String? _familyId;
  String? _childUid;
  List<AlertModel> _allAlerts = [];
  AlertFilterStatus _filterStatus = AlertFilterStatus.all;
  DateTime? _startDate;
  DateTime? _endDate;

  AlertHistoryBloc({required this.alertRepository}) : super(AlertHistoryInitial()) {
    on<LoadAlerts>(_onLoadAlerts);
    on<FilterByStatus>(_onFilterByStatus);
    on<FilterByDateRange>(_onFilterByDateRange);
    on<MarkAlertReviewedEvent>(_onMarkReviewed);
    on<_AlertsUpdated>(_onAlertsUpdated);
  }

  void _onLoadAlerts(LoadAlerts event, Emitter<AlertHistoryState> emit) {
    _familyId = event.familyId;
    _childUid = event.childUid;
    emit(AlertHistoryLoading());

    _alertSubscription?.cancel();
    _alertSubscription = alertRepository
        .watchAllAlerts(familyId: event.familyId, childUid: event.childUid)
        .listen(
      (alerts) {
        add(_AlertsUpdated(alerts));
      },
      onError: (error) {
        debugPrint('Alert stream error: $error');
      },
    );
  }

  void _onAlertsUpdated(_AlertsUpdated event, Emitter<AlertHistoryState> emit) {
    _allAlerts = event.alerts;
    _emitFiltered(emit);
  }

  void _onFilterByStatus(FilterByStatus event, Emitter<AlertHistoryState> emit) {
    _filterStatus = event.status;
    _emitFiltered(emit);
  }

  void _onFilterByDateRange(FilterByDateRange event, Emitter<AlertHistoryState> emit) {
    _startDate = event.startDate;
    _endDate = event.endDate;
    _emitFiltered(emit);
  }

  Future<void> _onMarkReviewed(MarkAlertReviewedEvent event, Emitter<AlertHistoryState> emit) async {
    try {
      await alertRepository.markAlertAsReviewed(
        familyId: event.familyId,
        childUid: event.childUid,
        alertId: event.alertId,
      );
    } catch (e) {
      debugPrint('Error marking alert as reviewed: $e');
      emit(AlertHistoryError('Failed to mark alert as reviewed'));
    }
  }

  void _emitFiltered(Emitter<AlertHistoryState> emit) {
    var filtered = List<AlertModel>.from(_allAlerts);

    // Filter by status
    if (_filterStatus == AlertFilterStatus.unreviewed) {
      filtered = filtered.where((a) => !a.isReviewed).toList();
    } else if (_filterStatus == AlertFilterStatus.reviewed) {
      filtered = filtered.where((a) => a.isReviewed).toList();
    }

    // Filter by date range
    if (_startDate != null) {
      filtered = filtered.where((a) {
        if (a.timestamp == null) return false;
        return !a.timestamp!.isBefore(_startDate!);
      }).toList();
    }
    if (_endDate != null) {
      filtered = filtered.where((a) {
        if (a.timestamp == null) return false;
        return a.timestamp!.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    emit(AlertHistoryLoaded(
      allAlerts: _allAlerts,
      filteredAlerts: filtered,
      filterStatus: _filterStatus,
      startDate: _startDate,
      endDate: _endDate,
    ));
  }

  @override
  Future<void> close() {
    _alertSubscription?.cancel();
    return super.close();
  }
}
