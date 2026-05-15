import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/daily_summary.dart';
import '../../domain/repositories/summary_repository.dart';
import '../../domain/repositories/usage_repository.dart';
import '../models/daily_summary_model.dart';

class SummaryRepositoryImpl implements SummaryRepository {
  final FirebaseFirestore _firestore;
  final UsageRepository _usageRepository;

  SummaryRepositoryImpl({
    FirebaseFirestore? firestore,
    required UsageRepository usageRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _usageRepository = usageRepository;

  @override
  Future<DailySummary> generateDailySummary(
    String childUid,
    String familyId,
    String date,
  ) async {
    // Check if summary already exists
    final exists = await hasSummaryForDate(childUid, date);
    if (exists) {
      final existing = await getSummariesByChild(childUid, limit: 1);
      if (existing.isNotEmpty) {
        return existing.first;
      }
    }

    // Get usage data
    final totalMinutes = await _usageRepository.getTotalUsageMinutes(
      childUid,
      date,
    );

    final usageByApp = await _usageRepository.getUsageByApp(childUid, date);

    // Sort by usage and get top 3
    final sortedApps = usageByApp.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topApps = sortedApps.take(3).map((e) => e.key).toList();

    // Create summary
    final summary = DailySummaryModel(
      summaryId: '',
      childUid: childUid,
      familyId: familyId,
      date: date,
      totalMinutes: totalMinutes,
      usageByApp: usageByApp,
      topApps: topApps,
      alertCount: 0, // TODO: integrate with alerts
      violationCount: 0, // TODO: integrate with violations
      sent: false,
    );

    // Save to Firestore
    final docRef = await _firestore
        .collection('daily_summaries')
        .add(summary.toMap());

    return DailySummaryModel(
      summaryId: docRef.id,
      childUid: childUid,
      familyId: familyId,
      date: date,
      totalMinutes: totalMinutes,
      usageByApp: usageByApp,
      topApps: topApps,
    );
  }

  @override
  Future<List<DailySummary>> getSummariesByFamily(
    String familyId, {
    int limit = 7,
  }) async {
    try {
      final query = await _firestore
          .collection('daily_summaries')
          .where('familyId', isEqualTo: familyId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => DailySummaryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<DailySummary>> getSummariesByChild(
    String childUid, {
    int limit = 7,
  }) async {
    try {
      final query = await _firestore
          .collection('daily_summaries')
          .where('childUid', isEqualTo: childUid)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => DailySummaryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> markAsSent(String summaryId) async {
    await _firestore.collection('daily_summaries').doc(summaryId).update({
      'sent': true,
      'sentAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<bool> hasSummaryForDate(String childUid, String date) async {
    final query = await _firestore
        .collection('daily_summaries')
        .where('childUid', isEqualTo: childUid)
        .where('date', isEqualTo: date)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }
}
