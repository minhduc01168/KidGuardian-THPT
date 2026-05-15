import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/family.dart';
import '../../domain/repositories/family_repository.dart';
import '../models/family_model.dart';

class FamilyRepositoryImpl implements FamilyRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  FamilyRepositoryImpl({
    FirebaseFirestore? firestore,
    Uuid? uuid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = uuid ?? const Uuid();

  @override
  Future<Family> createFamily(String parentUid) async {
    final familyId = _uuid.v4();
    final linkingCode = _generateLinkingCode();

    final family = FamilyModel(
      familyId: familyId,
      parentUid: parentUid,
      childUids: [],
      linkingCode: linkingCode,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection('families')
        .doc(familyId)
        .set(family.toMap());

    await _firestore.collection('users').doc(parentUid).update({
      'familyId': familyId,
    });

    return family;
  }

  @override
  Future<Family?> getFamily(String familyId) async {
    try {
      final doc = await _firestore.collection('families').doc(familyId).get();
      if (!doc.exists) return null;
      return FamilyModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Family?> getFamilyByParent(String parentUid) async {
    try {
      final query = await _firestore
          .collection('families')
          .where('parentUid', isEqualTo: parentUid)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return FamilyModel.fromFirestore(query.docs.first);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String> generateLinkingCode(String familyId) async {
    String linkingCode;
    bool isUnique = false;
    
    // Generate unique linking code
    do {
      linkingCode = _generateLinkingCode();
      final existing = await getFamilyByLinkingCode(linkingCode);
      isUnique = existing == null;
    } while (!isUnique);

    await _firestore.collection('families').doc(familyId).update({
      'linkingCode': linkingCode,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return linkingCode;
  }

  @override
  Future<Family> addChildToFamily(String familyId, String childUid) async {
    final familyRef = _firestore.collection('families').doc(familyId);

    await familyRef.update({
      'childUids': FieldValue.arrayUnion([childUid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('users').doc(childUid).update({
      'familyId': familyId,
    });

    final doc = await familyRef.get();
    return FamilyModel.fromFirestore(doc);
  }

  @override
  Future<Family?> getFamilyByLinkingCode(String linkingCode) async {
    try {
      final query = await _firestore
          .collection('families')
          .where('linkingCode', isEqualTo: linkingCode)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return FamilyModel.fromFirestore(query.docs.first);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> removeChildFromFamily(String familyId, String childUid) async {
    await _firestore.collection('families').doc(familyId).update({
      'childUids': FieldValue.arrayRemove([childUid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('users').doc(childUid).update({
      'familyId': FieldValue.delete(),
      'linkedTo': FieldValue.delete(),
    });
  }

  String _generateLinkingCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
