import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kidguardian/domain/repositories/time_request_repository.dart';

class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  group('TimeRequest.fromFirestore Edge Cases & Null Safety Verification', () {
    late MockDocumentSnapshot mockDoc;

    setUp(() {
      mockDoc = MockDocumentSnapshot();
      when(() => mockDoc.id).thenReturn('req_123');
    });

    test('Parses complete valid Firestore document correctly', () {
      when(() => mockDoc.data()).thenReturn({
        'familyId': 'fam_abc',
        'childUid': 'child_xyz',
        'appPackageName': 'com.zhiliaoapp.musically',
        'appName': 'TikTok',
        'requestedMinutes': 30,
        'reason': 'Học xong bài rồi ạ',
        'status': 'APPROVED',
        'timestamp': Timestamp.fromDate(DateTime(2026, 8, 19, 14, 30)),
        'parentResponse': 'Cho con 30p nhé',
      });

      final req = TimeRequest.fromFirestore(mockDoc);

      expect(req.id, equals('req_123'));
      expect(req.familyId, equals('fam_abc'));
      expect(req.childUid, equals('child_xyz'));
      expect(req.appPackageName, equals('com.zhiliaoapp.musically'));
      expect(req.appName, equals('TikTok'));
      expect(req.requestedMinutes, equals(30));
      expect(req.reason, equals('Học xong bài rồi ạ'));
      expect(req.status, equals(TimeRequestStatus.approved));
      expect(req.parentResponse, equals('Cho con 30p nhé'));
    });

    test('Handles missing / null fields with safe fallbacks (BUG-5 & BUG-4 stability)', () {
      // Simulate corrupted/empty Firestore doc
      when(() => mockDoc.data()).thenReturn({});

      final req = TimeRequest.fromFirestore(mockDoc);

      expect(req.id, equals('req_123'));
      expect(req.familyId, equals(''));
      expect(req.childUid, equals(''));
      expect(req.appPackageName, equals(''));
      expect(req.appName, equals(''));
      expect(req.requestedMinutes, equals(0));
      expect(req.reason, equals(''));
      expect(req.status, equals(TimeRequestStatus.pending)); // Fallback
      expect(req.parentResponse, isNull);
    });

    test('Handles unknown status string safely defaulting to pending', () {
      when(() => mockDoc.data()).thenReturn({
        'status': 'UNKNOWN_INVALID_STATUS',
      });

      final req = TimeRequest.fromFirestore(mockDoc);
      expect(req.status, equals(TimeRequestStatus.pending));
    });

    test('Handles lowercase / uppercase / mixed-case status values', () {
      for (final testCase in [
        {'status': 'pending', 'expected': TimeRequestStatus.pending},
        {'status': 'APPROVED', 'expected': TimeRequestStatus.approved},
        {'status': 'Rejected', 'expected': TimeRequestStatus.rejected},
      ]) {
        when(() => mockDoc.data()).thenReturn({'status': testCase['status']});
        final req = TimeRequest.fromFirestore(mockDoc);
        expect(req.status, equals(testCase['expected']));
      }
    });

    test('toMap converts model back to Firestore map properly', () {
      final req = TimeRequest(
        id: 'req_1',
        familyId: 'fam_1',
        childUid: 'child_1',
        appPackageName: 'com.instagram.android',
        appName: 'Instagram',
        requestedMinutes: 15,
        reason: 'xem tin tức',
        status: TimeRequestStatus.pending,
        timestamp: DateTime(2026, 8, 19),
        parentResponse: null,
      );

      final map = req.toMap();
      expect(map['familyId'], equals('fam_1'));
      expect(map['childUid'], equals('child_1'));
      expect(map['appPackageName'], equals('com.instagram.android'));
      expect(map['appName'], equals('Instagram'));
      expect(map['requestedMinutes'], equals(15));
      expect(map['status'], equals('pending'));
    });
  });
}
