import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';

// Events
abstract class AlertReviewEvent extends Equatable {
  const AlertReviewEvent();
  @override
  List<Object?> get props => [];
}

class LoadAlertDetail extends AlertReviewEvent {
  final String familyId;
  final String childUid;
  final String alertId;
  const LoadAlertDetail({
    required this.familyId,
    required this.childUid,
    required this.alertId,
  });
  @override
  List<Object?> get props => [familyId, childUid, alertId];
}

class MarkAsReviewed extends AlertReviewEvent {
  final String familyId;
  final String childUid;
  final String alertId;
  const MarkAsReviewed({
    required this.familyId,
    required this.childUid,
    required this.alertId,
  });
  @override
  List<Object?> get props => [alertId];
}

class AddNotes extends AlertReviewEvent {
  final String familyId;
  final String childUid;
  final String alertId;
  final String notes;
  const AddNotes({
    required this.familyId,
    required this.childUid,
    required this.alertId,
    required this.notes,
  });
  @override
  List<Object?> get props => [alertId, notes];
}

class DismissAlert extends AlertReviewEvent {
  final String familyId;
  final String childUid;
  final String alertId;
  const DismissAlert({
    required this.familyId,
    required this.childUid,
    required this.alertId,
  });
  @override
  List<Object?> get props => [alertId];
}

// States
abstract class AlertReviewState extends Equatable {
  const AlertReviewState();
  @override
  List<Object?> get props => [];
}

class AlertReviewInitial extends AlertReviewState {}
class AlertReviewLoading extends AlertReviewState {}
class AlertReviewLoaded extends AlertReviewState {
  final AlertModel alert;
  const AlertReviewLoaded(this.alert);
  @override
  List<Object?> get props => [alert.id, alert.isReviewed, alert.isDismissed, alert.notes];
}
class AlertReviewSuccess extends AlertReviewState {
  final String message;
  const AlertReviewSuccess(this.message);
  @override
  List<Object?> get props => [message];
}
class AlertReviewError extends AlertReviewState {
  final String message;
  const AlertReviewError(this.message);
  @override
  List<Object?> get props => [message];
}

class AlertReviewBloc extends Bloc<AlertReviewEvent, AlertReviewState> {
  final AlertRepository alertRepository;

  AlertReviewBloc({required this.alertRepository}) : super(AlertReviewInitial()) {
    on<LoadAlertDetail>(_onLoadAlertDetail);
    on<MarkAsReviewed>(_onMarkAsReviewed);
    on<AddNotes>(_onAddNotes);
    on<DismissAlert>(_onDismissAlert);
  }

  Future<void> _onLoadAlertDetail(LoadAlertDetail event, Emitter<AlertReviewState> emit) async {
    emit(AlertReviewLoading());
    try {
      final alert = await alertRepository.getAlert(
        familyId: event.familyId,
        childUid: event.childUid,
        alertId: event.alertId,
      );
      if (alert != null) {
        emit(AlertReviewLoaded(alert));
      } else {
        emit(const AlertReviewError('Alert not found'));
      }
    } catch (e) {
      debugPrint('Error loading alert detail: $e');
      emit(AlertReviewError('Failed to load alert: $e'));
    }
  }

  Future<void> _onMarkAsReviewed(MarkAsReviewed event, Emitter<AlertReviewState> emit) async {
    try {
      await alertRepository.markAlertAsReviewed(
        familyId: event.familyId,
        childUid: event.childUid,
        alertId: event.alertId,
      );
      emit(const AlertReviewSuccess('Đã đánh dấu đã xem'));
      add(LoadAlertDetail(
        familyId: event.familyId,
        childUid: event.childUid,
        alertId: event.alertId,
      ));
    } catch (e) {
      debugPrint('Error marking as reviewed: $e');
      emit(AlertReviewError('Failed to mark as reviewed: $e'));
    }
  }

  Future<void> _onAddNotes(AddNotes event, Emitter<AlertReviewState> emit) async {
    try {
      await alertRepository.addNotesToAlert(
        familyId: event.familyId,
        childUid: event.childUid,
        alertId: event.alertId,
        notes: event.notes,
      );
      emit(const AlertReviewSuccess('Đã lưu ghi chú'));
      add(LoadAlertDetail(
        familyId: event.familyId,
        childUid: event.childUid,
        alertId: event.alertId,
      ));
    } catch (e) {
      debugPrint('Error adding notes: $e');
      emit(AlertReviewError('Failed to add notes: $e'));
    }
  }

  Future<void> _onDismissAlert(DismissAlert event, Emitter<AlertReviewState> emit) async {
    try {
      await alertRepository.dismissAlert(
        familyId: event.familyId,
        childUid: event.childUid,
        alertId: event.alertId,
      );
      emit(const AlertReviewSuccess('Đã bỏ qua cảnh báo'));
      add(LoadAlertDetail(
        familyId: event.familyId,
        childUid: event.childUid,
        alertId: event.alertId,
      ));
    } catch (e) {
      debugPrint('Error dismissing alert: $e');
      emit(AlertReviewError('Failed to dismiss alert: $e'));
    }
  }
}
