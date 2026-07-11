import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kidguardian/data/models/emergency_log_model.dart';

void main() {
  group('EmergencyLogModel', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    final tTimestamp = DateTime(2026, 5, 30, 14, 30);
    final tModel = EmergencyLogModel(
      id: 'log1',
      childUid: 'child1',
      familyId: 'family1',
      action: 'call',
      phoneNumber: '0901234567',
      appPackageName: 'com.example.phone',
      timestamp: tTimestamp,
      durationSeconds: 120,
      status: 'active',
    );

    group('constructor', () {
      test('should create instance with all fields', () {
        final model = EmergencyLogModel(
          id: 'e1',
          childUid: 'c1',
          familyId: 'f1',
          action: 'call',
          phoneNumber: '0901234567',
          appPackageName: 'com.phone',
          timestamp: tTimestamp,
          durationSeconds: 60,
          status: 'completed',
        );

        expect(model.id, 'e1');
        expect(model.childUid, 'c1');
        expect(model.familyId, 'f1');
        expect(model.action, 'call');
        expect(model.phoneNumber, '0901234567');
        expect(model.appPackageName, 'com.phone');
        expect(model.timestamp, tTimestamp);
        expect(model.durationSeconds, 60);
        expect(model.status, 'completed');
      });
    });

    group('fromFirestore', () {
      test('should return valid model from Firestore document', () async {
        await fakeFirestore.collection('emergencyLogs').doc('log1').set({
          'childUid': 'child1',
          'familyId': 'family1',
          'action': 'call',
          'phoneNumber': '0901234567',
          'appPackageName': 'com.example.phone',
          'timestamp': Timestamp.fromDate(tTimestamp),
          'durationSeconds': 120,
          'status': 'active',
        });

        final doc =
            await fakeFirestore.collection('emergencyLogs').doc('log1').get();
        final result = EmergencyLogModel.fromFirestore(doc);

        expect(result.id, 'log1');
        expect(result.childUid, 'child1');
        expect(result.familyId, 'family1');
        expect(result.action, 'call');
        expect(result.phoneNumber, '0901234567');
        expect(result.appPackageName, 'com.example.phone');
        expect(result.timestamp, tTimestamp);
        expect(result.durationSeconds, 120);
        expect(result.status, 'active');
      });

      test('should use defaults when fields are missing', () async {
        await fakeFirestore.collection('emergencyLogs').doc('log2').set({});

        final doc =
            await fakeFirestore.collection('emergencyLogs').doc('log2').get();
        final result = EmergencyLogModel.fromFirestore(doc);

        expect(result.id, 'log2');
        expect(result.childUid, '');
        expect(result.familyId, '');
        expect(result.action, '');
        expect(result.phoneNumber, '');
        expect(result.appPackageName, '');
        expect(result.durationSeconds, 0);
        expect(result.status, 'unknown');
      });

      test('should fallback to DateTime.now when timestamp is null', () async {
        await fakeFirestore.collection('emergencyLogs').doc('log3').set({
          'timestamp': null,
        });

        final before = DateTime.now();
        final doc =
            await fakeFirestore.collection('emergencyLogs').doc('log3').get();
        final result = EmergencyLogModel.fromFirestore(doc);
        final after = DateTime.now();

        expect(
          result.timestamp.isAfter(before) ||
              result.timestamp.isAtSameMomentAs(before),
          true,
        );
        expect(
          result.timestamp.isBefore(after) ||
              result.timestamp.isAtSameMomentAs(after),
          true,
        );
      });
    });

    group('toJson', () {
      test('should return a valid map', () {
        final model = EmergencyLogModel(
          id: 'log1',
          childUid: 'child1',
          familyId: 'family1',
          action: 'call',
          phoneNumber: '0901234567',
          appPackageName: 'com.example.phone',
          timestamp: tTimestamp,
          durationSeconds: 120,
          status: 'active',
        );

        final result = model.toJson();

        expect(result['childUid'], 'child1');
        expect(result['familyId'], 'family1');
        expect(result['action'], 'call');
        expect(result['phoneNumber'], '0901234567');
        expect(result['appPackageName'], 'com.example.phone');
        expect(result['timestamp'], isA<Timestamp>());
        expect(result['durationSeconds'], 120);
        expect(result['status'], 'active');
      });

      test('should not include id in map', () {
        final model = EmergencyLogModel(
          id: 'log1',
          childUid: 'c1',
          familyId: 'f1',
          action: 'call',
          phoneNumber: '090',
          appPackageName: 'pkg',
          timestamp: tTimestamp,
          durationSeconds: 0,
          status: 'active',
        );

        final result = model.toJson();
        expect(result.containsKey('id'), false);
      });
    });

    group('actionLabel', () {
      test('should return Vietnamese label for call action', () {
        final model = EmergencyLogModel(
          id: '1',
          childUid: 'c',
          familyId: 'f',
          action: 'call',
          phoneNumber: '',
          appPackageName: '',
          timestamp: tTimestamp,
          durationSeconds: 0,
          status: 'active',
        );

        expect(model.actionLabel, 'Gọi điện');
      });

      test('should return Vietnamese label for sms action', () {
        final model = EmergencyLogModel(
          id: '1',
          childUid: 'c',
          familyId: 'f',
          action: 'sms',
          phoneNumber: '',
          appPackageName: '',
          timestamp: tTimestamp,
          durationSeconds: 0,
          status: 'active',
        );

        expect(model.actionLabel, 'Nhắn tin');
      });

      test('should return raw action for unknown action', () {
        final model = EmergencyLogModel(
          id: '1',
          childUid: 'c',
          familyId: 'f',
          action: 'email',
          phoneNumber: '',
          appPackageName: '',
          timestamp: tTimestamp,
          durationSeconds: 0,
          status: 'active',
        );

        expect(model.actionLabel, 'email');
      });
    });

    group('statusLabel', () {
      test('should return Vietnamese label for active status', () {
        final model = EmergencyLogModel(
          id: '1',
          childUid: 'c',
          familyId: 'f',
          action: 'call',
          phoneNumber: '',
          appPackageName: '',
          timestamp: tTimestamp,
          durationSeconds: 0,
          status: 'active',
        );

        expect(model.statusLabel, 'Đang hoạt động');
      });

      test('should return Vietnamese label for completed status', () {
        final model = EmergencyLogModel(
          id: '1',
          childUid: 'c',
          familyId: 'f',
          action: 'call',
          phoneNumber: '',
          appPackageName: '',
          timestamp: tTimestamp,
          durationSeconds: 0,
          status: 'completed',
        );

        expect(model.statusLabel, 'Đã hoàn thành');
      });

      test('should return raw status for unknown status', () {
        final model = EmergencyLogModel(
          id: '1',
          childUid: 'c',
          familyId: 'f',
          action: 'call',
          phoneNumber: '',
          appPackageName: '',
          timestamp: tTimestamp,
          durationSeconds: 0,
          status: 'pending',
        );

        expect(model.statusLabel, 'pending');
      });
    });
  });
}
