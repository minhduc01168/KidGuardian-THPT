import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyLogModel {
  final String id;
  final String childUid;
  final String familyId;
  final String action;
  final String phoneNumber;
  final String appPackageName;
  final DateTime timestamp;
  final int durationSeconds;
  final String status;

  const EmergencyLogModel({
    required this.id,
    required this.childUid,
    required this.familyId,
    required this.action,
    required this.phoneNumber,
    required this.appPackageName,
    required this.timestamp,
    required this.durationSeconds,
    required this.status,
  });

  factory EmergencyLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EmergencyLogModel(
      id: doc.id,
      childUid: data['childUid'] ?? '',
      familyId: data['familyId'] ?? '',
      action: data['action'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      appPackageName: data['appPackageName'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationSeconds: data['durationSeconds'] ?? 0,
      status: data['status'] ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'childUid': childUid,
      'familyId': familyId,
      'action': action,
      'phoneNumber': phoneNumber,
      'appPackageName': appPackageName,
      'timestamp': Timestamp.fromDate(timestamp),
      'durationSeconds': durationSeconds,
      'status': status,
    };
  }

  String get actionLabel {
    switch (action) {
      case 'call':
        return 'Gọi điện';
      case 'sms':
        return 'Nhắn tin';
      default:
        return action;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Đang hoạt động';
      case 'completed':
        return 'Đã hoàn thành';
      default:
        return status;
    }
  }
}
