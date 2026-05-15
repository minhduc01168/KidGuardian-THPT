import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_time_limit_model.dart';

class SmartLockRepository {
  final FirebaseFirestore _firestore;

  SmartLockRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<AppTimeLimitModel>> getAppTimeLimits(
    String familyId,
    String childId,
  ) async {
    final snapshot = await _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId)
        .collection('timeLimits')
        .get();

    return snapshot.docs
        .map((doc) => AppTimeLimitModel.fromJson(doc.data()))
        .toList();
  }

  Future<void> saveAppTimeLimit(
    String familyId,
    String childId,
    AppTimeLimitModel limit,
  ) async {
    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId)
        .collection('timeLimits')
        .doc(limit.appPackageName)
        .set(limit.toJson());
  }

  // Pre-defined popular apps list for MVP
  List<AppTimeLimitModel> getPopularApps() {
    return [
      const AppTimeLimitModel(
        appPackageName: 'com.zhiliaoapp.musically',
        appName: 'TikTok',
        limits: {},
      ),
      const AppTimeLimitModel(
        appPackageName: 'com.facebook.katana',
        appName: 'Facebook',
        limits: {},
      ),
      const AppTimeLimitModel(
        appPackageName: 'com.google.android.youtube',
        appName: 'YouTube',
        limits: {},
      ),
      const AppTimeLimitModel(
        appPackageName: 'com.instagram.android',
        appName: 'Instagram',
        limits: {},
      ),
      const AppTimeLimitModel(
        appPackageName: 'com.zing.zalo',
        appName: 'Zalo',
        limits: {},
      ),
      const AppTimeLimitModel(
        appPackageName: 'com.roblox.client',
        appName: 'Roblox',
        limits: {},
      ),
      const AppTimeLimitModel(
        appPackageName: 'com.dts.freefireth',
        appName: 'Free Fire',
        limits: {},
      ),
    ];
  }
}
