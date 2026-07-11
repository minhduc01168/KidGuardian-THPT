import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kidguardian/data/models/auto_approval_rule_model.dart';
import 'package:kidguardian/domain/repositories/rules_repository.dart';

// Events
abstract class RulesEvent extends Equatable {
  const RulesEvent();
  @override
  List<Object?> get props => [];
}

class LoadRules extends RulesEvent {
  final String familyId;
  const LoadRules(this.familyId);
  @override
  List<Object?> get props => [familyId];
}

class UpdateMaxMinutes extends RulesEvent {
  final int minutes;
  const UpdateMaxMinutes(this.minutes);
  @override
  List<Object?> get props => [minutes];
}

class UpdateDailyLimit extends RulesEvent {
  final int limit;
  const UpdateDailyLimit(this.limit);
  @override
  List<Object?> get props => [limit];
}

class ToggleRulesEnabled extends RulesEvent {
  final bool isEnabled;
  const ToggleRulesEnabled(this.isEnabled);
  @override
  List<Object?> get props => [isEnabled];
}

class ToggleAppRule extends RulesEvent {
  final String appPackageName;
  final bool isEnabled;
  const ToggleAppRule(this.appPackageName, this.isEnabled);
  @override
  List<Object?> get props => [appPackageName, isEnabled];
}

class SaveRules extends RulesEvent {}

class _RulesUpdated extends RulesEvent {
  final AutoApprovalRule? rule;
  const _RulesUpdated(this.rule);
  @override
  List<Object?> get props => [rule];
}

// States
abstract class RulesState extends Equatable {
  const RulesState();
  @override
  List<Object?> get props => [];
}

class RulesInitial extends RulesState {}

class RulesLoading extends RulesState {}

class RulesLoaded extends RulesState {
  final AutoApprovalRule rule;
  const RulesLoaded(this.rule);
  @override
  List<Object?> get props => [rule];
}

class RulesSaving extends RulesState {}

class RulesSaved extends RulesState {
  final String message;
  const RulesSaved(this.message);
  @override
  List<Object?> get props => [message];
}

class RulesError extends RulesState {
  final String message;
  const RulesError(this.message);
  @override
  List<Object?> get props => [message];
}

class RulesBloc extends Bloc<RulesEvent, RulesState> {
  final RulesRepository repository;
  final String familyId;
  StreamSubscription? _rulesSubscription;
  AutoApprovalRule? _currentRule;

  RulesBloc({
    required this.repository,
    required this.familyId,
  }) : super(RulesInitial()) {
    on<LoadRules>(_onLoadRules);
    on<UpdateMaxMinutes>(_onUpdateMaxMinutes);
    on<UpdateDailyLimit>(_onUpdateDailyLimit);
    on<ToggleRulesEnabled>(_onToggleRulesEnabled);
    on<ToggleAppRule>(_onToggleAppRule);
    on<SaveRules>(_onSaveRules);
    on<_RulesUpdated>(_onRulesUpdated);

    add(LoadRules(familyId));
  }

  void _onLoadRules(LoadRules event, Emitter<RulesState> emit) {
    emit(RulesLoading());
    _rulesSubscription?.cancel();
    _rulesSubscription = repository.watchRules(event.familyId).listen(
      (rule) {
        add(_RulesUpdated(rule));
      },
      onError: (error) {
        debugPrint('Rules stream error: $error');
        add(_RulesUpdated(null));
      },
    );
  }

  void _onRulesUpdated(_RulesUpdated event, Emitter<RulesState> emit) {
    if (event.rule != null) {
      _currentRule = event.rule;
      emit(RulesLoaded(event.rule!));
    } else {
      _currentRule = AutoApprovalRule(id: '', familyId: familyId);
      emit(RulesLoaded(_currentRule!));
    }
  }

  void _onUpdateMaxMinutes(UpdateMaxMinutes event, Emitter<RulesState> emit) {
    if (_currentRule != null) {
      _currentRule = _currentRule!.copyWith(maxAutoApproveMinutes: event.minutes);
      emit(RulesLoaded(_currentRule!));
    }
  }

  void _onUpdateDailyLimit(UpdateDailyLimit event, Emitter<RulesState> emit) {
    if (_currentRule != null) {
      _currentRule = _currentRule!.copyWith(dailyAutoApproveLimit: event.limit);
      emit(RulesLoaded(_currentRule!));
    }
  }

  void _onToggleRulesEnabled(ToggleRulesEnabled event, Emitter<RulesState> emit) {
    if (_currentRule != null) {
      _currentRule = _currentRule!.copyWith(isEnabled: event.isEnabled);
      emit(RulesLoaded(_currentRule!));
    }
  }

  void _onToggleAppRule(ToggleAppRule event, Emitter<RulesState> emit) {
    if (_currentRule != null) {
      final updatedRules = Map<String, bool>.from(_currentRule!.appSpecificRules);
      updatedRules[event.appPackageName] = event.isEnabled;
      _currentRule = _currentRule!.copyWith(appSpecificRules: updatedRules);
      emit(RulesLoaded(_currentRule!));
    }
  }

  Future<void> _onSaveRules(SaveRules event, Emitter<RulesState> emit) async {
    if (_currentRule == null) return;

    emit(RulesSaving());
    try {
      await repository.saveRules(_currentRule!);
      emit(const RulesSaved('Đã lưu cài đặt tự động duyệt'));
    } catch (e) {
      debugPrint('Error saving rules: $e');
      emit(RulesError('Không thể lưu cài đặt: $e'));
    }
  }

  @override
  Future<void> close() {
    _rulesSubscription?.cancel();
    return super.close();
  }
}
