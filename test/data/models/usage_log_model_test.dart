import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kidguardian/data/models/usage_log_model.dart';
import 'package:kidguardian/domain/entities/usage_log.dart';

void main() {
  group('UsageLogModel', () {
    final startTime = DateTime(2026, 5, 16, 10, 0);
    final endTime = DateTime(2026, 5, 16, 10, 30);
    final model = UsageLogModel(
      docId: 'doc1',
      childUid: 'child1',
      familyId: 'family1',
      appPackage: 'com.example.app',
      appName: 'Example App',
      startTime: startTime,
      endTime: endTime,
      durationMinutes: 30,
      date: '2026-05-16',
    );

    test('should be a subclass of UsageLog entity', () {
      expect(model, isA<UsageLog>());
    });

    test('toMap should return a valid map', () {
      final result = model.toMap();
      expect(result, {
        'childUid': 'child1',
        'familyId': 'family1',
        'appPackage': 'com.example.app',
        'appName': 'Example App',
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'durationMinutes': 30,
        'date': '2026-05-16',
      });
    });
  });
}
