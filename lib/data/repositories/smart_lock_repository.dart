import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_time_limit_model.dart';
import '../models/monitored_app_model.dart';
import '../models/schedule_model.dart';
import '../models/family_model.dart';
import '../models/smart_lock_settings_model.dart';
import '../models/lock_history_entry_model.dart';

class SmartLockRepository {
  final FirebaseFirestore _firestore;

  SmartLockRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<FamilyModel?> getFamily(String familyId) async {
    try {
      final doc = await _firestore.collection('families').doc(familyId).get();
      if (!doc.exists) return null;
      return FamilyModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  Future<List<AppTimeLimitModel>> getAppTimeLimits(
    String familyId,
    String childId, {
    bool forceServer = false, // BUG-1 FIX: force fetch từ server thay vì Firestore local cache
  }) async {
    final snapshot = await _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId)
        .collection('timeLimits')
        .get(forceServer ? const GetOptions(source: Source.server) : null);

    return snapshot.docs
        .map((doc) => AppTimeLimitModel.fromJson(doc.data()))
        .toList();
  }

  // BUG-4 FIX: Realtime stream để child device biết ngay khi phụ huynh
  // approve time request và cộng giờ vào timeLimits (không cần đợi 30s timer)
  Stream<List<AppTimeLimitModel>> watchTimeLimits(
    String familyId,
    String childId,
  ) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId)
        .collection('timeLimits')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppTimeLimitModel.fromJson(doc.data()))
            .toList());
  }

  Future<void> saveAppTimeLimit(
    String familyId,
    String childId,
    AppTimeLimitModel limit,
  ) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('children')
          .doc(childId)
          .collection('timeLimits')
          .doc(limit.appPackageName)
          .set(limit.toJson())
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => throw TimeoutException('Offline sync'),
          );
    } catch (e) {
      if (e is TimeoutException) return;
      rethrow;
    }
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
        appPackageName: 'com.instagram.barcelona',
        appName: 'Threads',
        limits: {},
      ),
      const AppTimeLimitModel(
        appPackageName: 'com.android.chrome',
        appName: 'Google Chrome',
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
    final cacheKey = 'monitored_apps_cache_$childId';
    try {
      final snapshot = await _firestore
          .collection('families')
          .doc(familyId)
          .collection('children')
          .doc(childId)
          .collection('monitoredApps')
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 5));

      final apps = snapshot.docs
          .map((doc) => MonitoredAppModel.fromJson(doc.data()))
          .toList();

      // Lưu cache vào SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String encodedData = jsonEncode(apps.map((a) => a.toJson()).toList());
      await prefs.setString(cacheKey, encodedData);

      return apps;
    } catch (e) {
      // Nếu rớt mạng hoặc timeout, fallback dùng cache local
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString(cacheKey);
      if (cachedString != null) {
        final List<dynamic> decodedList = jsonDecode(cachedString);
        return decodedList
            .map((item) => MonitoredAppModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    }
  }

  Future<void> toggleMonitoredApp(
    String familyId,
    String childId,
    String appPackageName,
    bool isMonitored,
  ) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('children')
          .doc(childId)
          .collection('monitoredApps')
          .doc(appPackageName)
          .set({'isMonitored': isMonitored}, SetOptions(merge: true))
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => throw TimeoutException('Offline sync'),
          );
    } catch (e) {
      if (e is TimeoutException) return;
      rethrow;
    }
  }

  Future<void> addCustomApp(
    String familyId,
    String childId,
    MonitoredAppModel app,
  ) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('children')
          .doc(childId)
          .collection('monitoredApps')
          .doc(app.appPackageName)
          .set(app.toJson())
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => throw TimeoutException('Offline sync'),
          );
    } catch (e) {
      if (e is TimeoutException) return;
      rethrow;
    }
  }

  // --- Installed Apps (Giai đoạn 2) ---

  Future<void> saveInstalledApps(
    String familyId,
    String childId,
    List<Map<String, dynamic>> apps,
  ) async {
    try {
      final collectionRef = _firestore
          .collection('families')
          .doc(familyId)
          .collection('children')
          .doc(childId)
          .collection('installedApps');

      // Chia nhỏ thành các batch 500 (giới hạn của Firestore)
      const int batchSize = 500;
      for (var i = 0; i < apps.length; i += batchSize) {
        final batch = _firestore.batch();
        final end = (i + batchSize < apps.length) ? i + batchSize : apps.length;
        final chunk = apps.sublist(i, end);

        for (final app in chunk) {
          batch.set(collectionRef.doc(app['packageName']), app, SetOptions(merge: true));
        }

        await batch.commit().timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw TimeoutException('Offline sync'),
            );
      }
    } catch (e) {
      if (e is TimeoutException) return;
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getInstalledApps(
    String familyId,
    String childId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('families')
          .doc(familyId)
          .collection('children')
          .doc(childId)
          .collection('installedApps')
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  }

  // Schedule CRUD methods

  Future<List<ScheduleModel>> getSchedules(
    String familyId,
    String childId,
  ) async {
    final snapshot = await _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId)
        .collection('schedules')
        .get();

    return snapshot.docs
        .map((doc) => ScheduleModel.fromJson({
              ...doc.data(),
              'id': doc.id,
            }))
        .toList();
  }

  Future<void> saveSchedule(
    String familyId,
    String childId,
    ScheduleModel schedule,
  ) async {
    final docRef = schedule.id.isEmpty
        ? _firestore
            .collection('families')
            .doc(familyId)
            .collection('children')
            .doc(childId)
            .collection('schedules')
            .doc()
        : _firestore
            .collection('families')
            .doc(familyId)
            .collection('children')
            .doc(childId)
            .collection('schedules')
            .doc(schedule.id);

    try {
      await docRef.set(schedule.toJson()).timeout(
            const Duration(seconds: 3),
            onTimeout: () => throw TimeoutException('Offline sync'),
          );
    } catch (e) {
      if (e is TimeoutException) return;
      rethrow;
    }
  }

  Future<void> deleteSchedule(
    String familyId,
    String childId,
    String scheduleId,
  ) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('children')
          .doc(childId)
          .collection('schedules')
          .doc(scheduleId)
          .delete()
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => throw TimeoutException('Offline sync'),
          );
    } catch (e) {
      if (e is TimeoutException) return;
      rethrow;
    }
  }

  // Smart Lock Settings methods

  Future<SmartLockSettingsModel?> getSmartLockSettings(
    String familyId,
    String childId,
  ) async {
    final doc = await _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId)
        .collection('settings')
        .doc('smartLock')
        .get();

    if (!doc.exists) return null;
    return SmartLockSettingsModel.fromJson(doc.data()!);
  }

  Future<void> saveSmartLockSettings(
    String familyId,
    String childId,
    SmartLockSettingsModel settings,
  ) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('children')
          .doc(childId)
          .collection('settings')
          .doc('smartLock')
          .set(settings.copyWith(updatedAt: DateTime.now()).toJson())
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => throw TimeoutException('Offline sync'),
          );
    } catch (e) {
      if (e is TimeoutException) return;
      rethrow;
    }
  }

  // Lock History methods

  Future<List<LockHistoryEntryModel>> getLockHistory(
    String familyId,
    String childId, {
    int limit = 50,
  }) async {
    final snapshot = await _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId)
        .collection('lockHistory')
        .orderBy('lockedAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => LockHistoryEntryModel.fromJson({
              ...doc.data(),
              'id': doc.id,
            }))
        .toList();
  }

  Future<void> addLockHistoryEntry(
    String familyId,
    String childId,
    LockHistoryEntryModel entry,
  ) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('children')
          .doc(childId)
          .collection('lockHistory')
          .add(entry.toJson())
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => throw TimeoutException('Offline sync'),
          );
    } catch (e) {
      if (e is TimeoutException) return;
      rethrow;
    }
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
        appPackageName: 'com.instagram.barcelona',
        appName: 'Threads',
        isMonitored: true,
      ),
      const MonitoredAppModel(
        appPackageName: 'com.android.chrome',
        appName: 'Google Chrome',
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
