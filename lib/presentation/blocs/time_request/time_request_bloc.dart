import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kidguardian/domain/repositories/time_request_repository.dart';

// Events
abstract class TimeRequestEvent extends Equatable {
  const TimeRequestEvent();
  @override
  List<Object?> get props => [];
}

class SubmitTimeRequest extends TimeRequestEvent {
  final String familyId;
  final String childUid;
  final String appPackageName;
  final String appName;
  final int requestedMinutes;
  final String reason;
  const SubmitTimeRequest({
    required this.familyId,
    required this.childUid,
    required this.appPackageName,
    required this.appName,
    required this.requestedMinutes,
    required this.reason,
  });
  @override
  List<Object?> get props => [familyId, childUid, appPackageName, requestedMinutes, reason];
}

class LoadTimeRequests extends TimeRequestEvent {
  final String familyId;
  final String childUid;
  const LoadTimeRequests({required this.familyId, required this.childUid});
  @override
  List<Object?> get props => [familyId, childUid];
}

class LoadPendingRequests extends TimeRequestEvent {
  final String familyId;
  const LoadPendingRequests(this.familyId);
  @override
  List<Object?> get props => [familyId];
}

class ApproveTimeRequest extends TimeRequestEvent {
  final String familyId;
  final String childUid;
  final String requestId;
  final String? response;
  const ApproveTimeRequest({
    required this.familyId,
    required this.childUid,
    required this.requestId,
    this.response,
  });
  @override
  List<Object?> get props => [requestId];
}

class RejectTimeRequest extends TimeRequestEvent {
  final String familyId;
  final String childUid;
  final String requestId;
  final String? response;
  const RejectTimeRequest({
    required this.familyId,
    required this.childUid,
    required this.requestId,
    this.response,
  });
  @override
  List<Object?> get props => [requestId];
}

class _RequestsUpdated extends TimeRequestEvent {
  final List<TimeRequest> requests;
  const _RequestsUpdated(this.requests);
  @override
  List<Object?> get props => [requests.map((r) => r.id).toList()];
}

// States
abstract class TimeRequestState extends Equatable {
  const TimeRequestState();
  @override
  List<Object?> get props => [];
}

class TimeRequestInitial extends TimeRequestState {}
class TimeRequestLoading extends TimeRequestState {}
class TimeRequestSubmitting extends TimeRequestState {}
class TimeRequestSubmitted extends TimeRequestState {
  final String message;
  const TimeRequestSubmitted(this.message);
  @override
  List<Object?> get props => [message];
}
class TimeRequestsLoaded extends TimeRequestState {
  final List<TimeRequest> requests;
  const TimeRequestsLoaded(this.requests);
  @override
  List<Object?> get props => [requests.map((r) => r.id).toList()];
}
class TimeRequestError extends TimeRequestState {
  final String message;
  const TimeRequestError(this.message);
  @override
  List<Object?> get props => [message];
}

class TimeRequestBloc extends Bloc<TimeRequestEvent, TimeRequestState> {
  final TimeRequestRepository repository;
  StreamSubscription? _requestSubscription;

  TimeRequestBloc({required this.repository}) : super(TimeRequestInitial()) {
    on<SubmitTimeRequest>(_onSubmitRequest);
    on<LoadTimeRequests>(_onLoadRequests);
    on<LoadPendingRequests>(_onLoadPendingRequests);
    on<ApproveTimeRequest>(_onApproveRequest);
    on<RejectTimeRequest>(_onRejectRequest);
    on<_RequestsUpdated>(_onRequestsUpdated);
  }

  Future<void> _onSubmitRequest(SubmitTimeRequest event, Emitter<TimeRequestState> emit) async {
    emit(TimeRequestSubmitting());
    try {
      final request = TimeRequest(
        id: '',
        familyId: event.familyId,
        childUid: event.childUid,
        appPackageName: event.appPackageName,
        appName: event.appName,
        requestedMinutes: event.requestedMinutes,
        reason: event.reason,
        status: TimeRequestStatus.pending,
        timestamp: DateTime.now(),
      );
      await repository.submitRequest(request);
      emit(const TimeRequestSubmitted('Yêu cầu đã được gửi đến phụ huynh'));
    } catch (e) {
      debugPrint('Error submitting time request: $e');
      emit(TimeRequestError('Failed to submit request: $e'));
    }
  }

  void _onLoadRequests(LoadTimeRequests event, Emitter<TimeRequestState> emit) {
    _requestSubscription?.cancel();
    _requestSubscription = repository
        .watchRequests(familyId: event.familyId, childUid: event.childUid)
        .listen(
      (requests) {
        add(_RequestsUpdated(requests));
      },
      onError: (error) {
        debugPrint('Time requests stream error: $error');
      },
    );
  }

  void _onLoadPendingRequests(LoadPendingRequests event, Emitter<TimeRequestState> emit) {
    _requestSubscription?.cancel();
    _requestSubscription = repository
        .watchPendingRequests(familyId: event.familyId)
        .listen(
      (requests) {
        add(_RequestsUpdated(requests));
      },
      onError: (error) {
        debugPrint('Pending requests stream error: $error');
      },
    );
  }

  void _onRequestsUpdated(_RequestsUpdated event, Emitter<TimeRequestState> emit) {
    emit(TimeRequestsLoaded(event.requests));
  }

  Future<void> _onApproveRequest(ApproveTimeRequest event, Emitter<TimeRequestState> emit) async {
    try {
      await repository.approveRequest(
        familyId: event.familyId,
        childUid: event.childUid,
        requestId: event.requestId,
        response: event.response,
      );
    } catch (e) {
      debugPrint('Error approving request: $e');
      emit(TimeRequestError('Failed to approve request: $e'));
    }
  }

  Future<void> _onRejectRequest(RejectTimeRequest event, Emitter<TimeRequestState> emit) async {
    try {
      await repository.rejectRequest(
        familyId: event.familyId,
        childUid: event.childUid,
        requestId: event.requestId,
        response: event.response,
      );
    } catch (e) {
      debugPrint('Error rejecting request: $e');
      emit(TimeRequestError('Failed to reject request: $e'));
    }
  }

  @override
  Future<void> close() {
    _requestSubscription?.cancel();
    return super.close();
  }
}
