import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class AutoApprovalRule extends Equatable {
  final String id;
  final String familyId;
  final int maxAutoApproveMinutes;
  final int dailyAutoApproveLimit;
  final bool isEnabled;
  final Map<String, bool> appSpecificRules;
  final DateTime? updatedAt;

  const AutoApprovalRule({
    required this.id,
    required this.familyId,
    this.maxAutoApproveMinutes = 30,
    this.dailyAutoApproveLimit = 3,
    this.isEnabled = false,
    this.appSpecificRules = const {},
    this.updatedAt,
  });

  factory AutoApprovalRule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final appRules = data['appSpecificRules'] as Map<dynamic, dynamic>? ?? {};
    final parsedAppRules = <String, bool>{};
    appRules.forEach((key, value) {
      parsedAppRules[key.toString()] = value == true;
    });

    return AutoApprovalRule(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      maxAutoApproveMinutes: data['maxAutoApproveMinutes'] ?? 30,
      dailyAutoApproveLimit: data['dailyAutoApproveLimit'] ?? 3,
      isEnabled: data['isEnabled'] ?? false,
      appSpecificRules: parsedAppRules,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'maxAutoApproveMinutes': maxAutoApproveMinutes,
      'dailyAutoApproveLimit': dailyAutoApproveLimit,
      'isEnabled': isEnabled,
      'appSpecificRules': appSpecificRules,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AutoApprovalRule copyWith({
    String? id,
    String? familyId,
    int? maxAutoApproveMinutes,
    int? dailyAutoApproveLimit,
    bool? isEnabled,
    Map<String, bool>? appSpecificRules,
    DateTime? updatedAt,
  }) {
    return AutoApprovalRule(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      maxAutoApproveMinutes: maxAutoApproveMinutes ?? this.maxAutoApproveMinutes,
      dailyAutoApproveLimit: dailyAutoApproveLimit ?? this.dailyAutoApproveLimit,
      isEnabled: isEnabled ?? this.isEnabled,
      appSpecificRules: appSpecificRules ?? this.appSpecificRules,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, familyId, maxAutoApproveMinutes, dailyAutoApproveLimit, isEnabled, appSpecificRules, updatedAt];
}
