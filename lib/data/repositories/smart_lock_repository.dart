import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_time_limit_model.dart';
import '../models/monitored_app_model.dart';

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

  // Monitored Apps methods

  Future<List<MonitoredAppModel>> getMonitoredApps(
    String familyId,
    String childId,
  ) async {
    final snapshot = await _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId)
        .collection('monitoredApps')
        .get();

    return snapshot.docs
        .map((doc) => MonitoredAppModel.fromJson(doc.data()))
        .toList();
  }

  Future<void> toggleMonitoredApp(
    String familyId,
    String childId,
    String appPackageName,
    bool isMonitored,
  ) async {
    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId)
        .collection('monitoredApps')
        .doc(appPackageName)
        .set({'isMonitored': isMonitored}, SetOptions(merge: true));
  }

  Future<void> addCustomApp(
    String familyId,
    String childId,
    MonitoredAppModel app,
  ) async {
    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId)
        .collection('monitoredApps')
        .doc(app.appPackageName)
        .set(app.toJson());
  }

  List<MonitoredAppModel> getPopularMonitoredApps() {
    return [
      const MonitoredAppModel(
        appPackageName: 'com.zhiliaoapp.musically',
        appName: 'TikTok',
        isMonitored: true,
      ),
      const MonitoredAppModel(
        appPackageName: 'com.facebook.katana',
        appName: 'Facebook',
        isMonitored: true,
      ),
      const MonitoredAppModel(
        appPackageName: 'com.google.android.youtube',
        appName: 'YouTube',
        isMonitored: true,
      ),
      const MonitoredAppModel(
        appPackageName: 'com.instagram.android',
        appName: 'Instagram',
        isMonitored: true,
      ),
      const MonitoredAppModel(
        appPackageName: 'com.zing.zalo',
        appName: 'Zalo',
        isMonitored: true,
      ),
      const MonitoredAppModel(
        appPackageName: 'com.roblox.client',
        appName: 'Roblox',
        isMonitored: true,
      ),
      const MonitoredAppModel(
        appPackageName: 'com.dts.freefireth',
        appName: 'Free Fire',
        isMonitored: true,
      ),
    ];
  }
}
