import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/family.dart';

class FamilyModel extends Family {
  const FamilyModel({
    required super.familyId,
    required super.parentUid,
    super.childUids = const [],
    super.linkingCode,
    required super.createdAt,
    required super.updatedAt,
  });

  factory FamilyModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FamilyModel(
      familyId: data['familyId'] ?? '',
      parentUid: data['parentUid'] ?? '',
      childUids: List<String>.from(data['childUids'] ?? []),
      linkingCode: data['linkingCode'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'parentUid': parentUid,
      'childUids': childUids,
      'linkingCode': linkingCode,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  FamilyModel copyWith({
    String? familyId,
    String? parentUid,
    List<String>? childUids,
    String? linkingCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FamilyModel(
      familyId: familyId ?? this.familyId,
      parentUid: parentUid ?? this.parentUid,
      childUids: childUids ?? this.childUids,
      linkingCode: linkingCode ?? this.linkingCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
