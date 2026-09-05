import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kidguardian/domain/repositories/time_request_repository.dart';
import 'package:kidguardian/domain/repositories/rules_repository.dart';
import 'package:kidguardian/domain/repositories/alert_repository.dart';

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

class LoadAllRequests extends TimeRequestEvent {
  final String familyId;
  const LoadAllRequests(this.familyId);
  @override
  List<Object?> get props => [familyId];
}

class FilterRequestsByStatus extends TimeRequestEvent {
  final TimeRequestFilterStatus status;
  const FilterRequestsByStatus(this.status);
  @override
  List<Object?> get props => [status];
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

// Enums
enum TimeRequestFilterStatus { all, pending, approved, rejected }

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

class TimeRequestHistoryLoaded extends TimeRequestState {
  final List<TimeRequest> allRequests;
  final List<TimeRequest> filteredRequests;
  final TimeRequestFilterStatus filterStatus;

  const TimeRequestHistoryLoaded({
    required this.allRequests,
    required this.filteredRequests,
    this.filterStatus = TimeRequestFilterStatus.all,
  });

  @override
  List<Object?> get props => [filteredRequests.map((r) => r.id).toList(), filterStatus];
}

class TimeRequestBloc extends Bloc<TimeRequestEvent, TimeRequestState> {
  final TimeRequestRepository repository;
  final RulesRepository? rulesRepository;
  final AlertRepository? alertRepository;
  StreamSubscription? _requestSubscription;
  List<TimeRequest> _allRequests = [];
  TimeRequestFilterStatus _filterStatus = TimeRequestFilterStatus.all;

  TimeRequestBloc({
    required this.repository, 
    this.rulesRepository,
    this.alertRepository,
  }) : super(TimeRequestInitial()) {
    on<SubmitTimeRequest>(_onSubmitRequest);
    on<LoadTimeRequests>(_onLoadRequests);
    on<LoadPendingRequests>(_onLoadPendingRequests);
    on<LoadAllRequests>(_onLoadAllRequests);
    on<FilterRequestsByStatus>(_onFilterByStatus);
    on<ApproveTimeRequest>(_onApproveRequest);
    on<RejectTimeRequest>(_onRejectRequest);
    on<_RequestsUpdated>(_onRequestsUpdated);
  }

  Future<void> _onSubmitRequest(SubmitTimeRequest event, Emitter<TimeRequestState> emit) async {
    emit(TimeRequestSubmitting());
    try {
      // RATE LIMIT: Tối đa 3 lần / giờ / ứng dụng
      final recentCount = await repository.countRecentRequests(
        familyId: event.familyId,
        childUid: event.childUid,
        appPackageName: event.appPackageName,
        window: const Duration(hours: 1),
      );

      if (recentCount >= 3) {
        emit(const TimeRequestError(
            'Bạn chỉ được xin thêm giờ tối đa 3 lần/giờ cho ứng dụng này. Vui lòng thử lại sau.'));
        return;
      }

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

      bool autoApproved = false;
      if (rulesRepository != null) {
        final shouldAutoApprove = await rulesRepository!.shouldAutoApprove(
          familyId: event.familyId,
          appPackageName: event.appPackageName,
          requestedMinutes: event.requestedMinutes,
        );

        if (shouldAutoApprove) {
          final requestId = await repository.submitRequest(request);
          if (requestId.isNotEmpty) {
            await repository.approveRequest(
              familyId: event.familyId,
              childUid: event.childUid,
              requestId: requestId,
              response: 'Tự động duyệt',
            );
            await rulesRepository!.logAutoApprovedRequest(
              TimeRequest(
                id: requestId,
                familyId: request.familyId,
                childUid: request.childUid,
                appPackageName: request.appPackageName,
                appName: request.appName,
                requestedMinutes: request.requestedMinutes,
                reason: request.reason,
                status: TimeRequestStatus.approved,
                timestamp: request.timestamp,
              )
            );
            autoApproved = true;
          }
        }
      }

      if (!autoApproved) {
        await repository.submitRequest(request);
        
        // Ghi log alert
        if (alertRepository != null) {
          try {
            await alertRepository!.createTimeRequestAlert(
              familyId: event.familyId,
              childUid: event.childUid,
              packageName: event.appPackageName,
              requestedMinutes: event.requestedMinutes,
            );
          } catch (e) {
            debugPrint('Error creating time request alert: $e');
          }
        }
      }

      emit(TimeRequestSubmitted(
        autoApproved
            ? 'Yêu cầu đã được tự động duyệt'
            : 'Yêu cầu đã được gửi đến phụ huynh',
      ));
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
    _allRequests = event.requests;
    if (_filterStatus != TimeRequestFilterStatus.all ||
        state is TimeRequestHistoryLoaded) {
      _emitFilteredHistory(emit);
    } else {
      emit(TimeRequestsLoaded(event.requests));
    }
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

  void _onLoadAllRequests(LoadAllRequests event, Emitter<TimeRequestState> emit) {
    _requestSubscription?.cancel();
    _filterStatus = TimeRequestFilterStatus.all;
    _requestSubscription = repository
        .watchAllRequests(familyId: event.familyId)
        .listen(
      (requests) {
        add(_RequestsUpdated(requests));
      },
      onError: (error) {
        debugPrint('All requests stream error: $error');
      },
    );
  }

  void _onFilterByStatus(FilterRequestsByStatus event, Emitter<TimeRequestState> emit) {
    _filterStatus = event.status;
    _emitFilteredHistory(emit);
  }

  void _emitFilteredHistory(Emitter<TimeRequestState> emit) {
    var filtered = List<TimeRequest>.from(_allRequests);

    if (_filterStatus == TimeRequestFilterStatus.pending) {
      filtered = filtered.where((r) => r.status == TimeRequestStatus.pending).toList();
    } else if (_filterStatus == TimeRequestFilterStatus.approved) {
      filtered = filtered.where((r) => r.status == TimeRequestStatus.approved).toList();
    } else if (_filterStatus == TimeRequestFilterStatus.rejected) {
      filtered = filtered.where((r) => r.status == TimeRequestStatus.rejected).toList();
    }

    emit(TimeRequestHistoryLoaded(
      allRequests: _allRequests,
      filteredRequests: filtered,
      filterStatus: _filterStatus,
    ));
  }

  @override
  Future<void> close() {
    _requestSubscription?.cancel();
    return super.close();
  }
}
