import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kidguardian/platform/android/accessibility_channel.dart';

// Events
abstract class KeywordManagementEvent extends Equatable {
  const KeywordManagementEvent();
  @override
  List<Object?> get props => [];
}

class LoadKeywords extends KeywordManagementEvent {
  final String familyId;
  const LoadKeywords(this.familyId);
  @override
  List<Object?> get props => [familyId];
}

class AddKeyword extends KeywordManagementEvent {
  final String familyId;
  final String keyword;
  const AddKeyword({required this.familyId, required this.keyword});
  @override
  List<Object?> get props => [keyword];
}

class RemoveKeyword extends KeywordManagementEvent {
  final String familyId;
  final String keyword;
  const RemoveKeyword({required this.familyId, required this.keyword});
  @override
  List<Object?> get props => [keyword];
}

class ResetToDefaults extends KeywordManagementEvent {
  final String familyId;
  const ResetToDefaults(this.familyId);
  @override
  List<Object?> get props => [familyId];
}

// States
abstract class KeywordManagementState extends Equatable {
  const KeywordManagementState();
  @override
  List<Object?> get props => [];
}

class KeywordManagementInitial extends KeywordManagementState {}
class KeywordManagementLoading extends KeywordManagementState {}
class KeywordManagementLoaded extends KeywordManagementState {
  final List<String> keywords;
  const KeywordManagementLoaded(this.keywords);
  @override
  List<Object?> get props => [keywords];
}
class KeywordManagementError extends KeywordManagementState {
  final String message;
  const KeywordManagementError(this.message);
  @override
  List<Object?> get props => [message];
}

class KeywordManagementBloc extends Bloc<KeywordManagementEvent, KeywordManagementState> {
  static const _defaultKeywords = ['tự tử', 'đánh nhau', 'cờ bạc', 'ma túy'];
  final FirebaseFirestore _firestore;

  KeywordManagementBloc({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super(KeywordManagementInitial()) {
    on<LoadKeywords>(_onLoadKeywords);
    on<AddKeyword>(_onAddKeyword);
    on<RemoveKeyword>(_onRemoveKeyword);
    on<ResetToDefaults>(_onResetToDefaults);
  }

  Future<void> _syncToNative(List<String> keywords) async {
    try {
      await AccessibilityChannel.updateKeywords(keywords);
    } catch (e) {
      debugPrint('Warning: Could not sync keywords to native: $e');
    }
  }

  Future<void> _onLoadKeywords(LoadKeywords event, Emitter<KeywordManagementState> emit) async {
    emit(KeywordManagementLoading());
    try {
      final doc = await _firestore
          .collection('families')
          .doc(event.familyId)
          .collection('settings')
          .doc('keywords')
          .get();

      List<String> keywords;
      if (doc.exists && doc.data()?['keywords'] != null) {
        keywords = List<String>.from(doc.data()!['keywords']);
      } else {
        keywords = List.from(_defaultKeywords);
      }

      await _syncToNative(keywords);
      emit(KeywordManagementLoaded(keywords));
    } catch (e) {
      debugPrint('Error loading keywords: $e');
      emit(KeywordManagementError('Failed to load keywords'));
    }
  }

  Future<void> _onAddKeyword(AddKeyword event, Emitter<KeywordManagementState> emit) async {
    if (event.keyword.trim().isEmpty) return;
    
    final currentState = state;
    if (currentState is! KeywordManagementLoaded) return;

    final updatedKeywords = List<String>.from(currentState.keywords);
    if (!updatedKeywords.contains(event.keyword.trim())) {
      updatedKeywords.add(event.keyword.trim());
      await _saveKeywords(event.familyId, updatedKeywords);
      await _syncToNative(updatedKeywords);
      emit(KeywordManagementLoaded(updatedKeywords));
    }
  }

  Future<void> _onRemoveKeyword(RemoveKeyword event, Emitter<KeywordManagementState> emit) async {
    final currentState = state;
    if (currentState is! KeywordManagementLoaded) return;

    final updatedKeywords = List<String>.from(currentState.keywords);
    updatedKeywords.remove(event.keyword);
    await _saveKeywords(event.familyId, updatedKeywords);
    await _syncToNative(updatedKeywords);
    emit(KeywordManagementLoaded(updatedKeywords));
  }

  Future<void> _onResetToDefaults(ResetToDefaults event, Emitter<KeywordManagementState> emit) async {
    final keywords = List<String>.from(_defaultKeywords);
    await _saveKeywords(event.familyId, keywords);
    await _syncToNative(keywords);
    emit(KeywordManagementLoaded(keywords));
  }

  Future<void> _saveKeywords(String familyId, List<String> keywords) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('settings')
          .doc('keywords')
          .set({'keywords': keywords}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving keywords: $e');
    }
  }
}
