import 'package:equatable/equatable.dart';

class Family extends Equatable {
  final String familyId;
  final String parentUid;
  final List<String> childUids;
  final String? linkingCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Family({
    required this.familyId,
    required this.parentUid,
    this.childUids = const [],
    this.linkingCode,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        familyId,
        parentUid,
        childUids,
        linkingCode,
        createdAt,
        updatedAt,
      ];
}
