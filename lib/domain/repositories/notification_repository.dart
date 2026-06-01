import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { alert, timeRequest, system }

class NotificationModel {
  final String id;
  final String familyId;
  final String childUid;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String? relatedId;

  NotificationModel({
    required this.id,
    required this.familyId,
    required this.childUid,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.relatedId,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NotificationModel(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      childUid: data['childUid'] ?? '',
      type: NotificationType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => NotificationType.system,
      ),
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      relatedId: data['relatedId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'childUid': childUid,
      'type': type.name,
      'title': title,
      'body': body,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
      'relatedId': relatedId,
    };
  }
}

abstract class NotificationRepository {
  Stream<List<NotificationModel>> watchAllNotifications({
    required String familyId,
  });

  Future<void> markAsRead({
    required String familyId,
    required String childUid,
    required String notificationId,
  });

  Future<void> markAllAsRead({
    required String familyId,
    required String childUid,
  });

  Future<void> deleteNotification({
    required String familyId,
    required String childUid,
    required String notificationId,
  });

  Future<void> clearOldNotifications({
    required String familyId,
    required String childUid,
    required DateTime olderThan,
  });

  Future<void> addNotification(NotificationModel notification);
}

class NotificationRepositoryImpl implements NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<NotificationModel>> watchAllNotifications({
    required String familyId,
  }) {
    // Note: This query requires a composite index in Firestore:
    // Collection Group: notifications
    // Fields: familyId ASC, timestamp DESC
    // Create this index in Firebase Console or firestore.indexes.json
    return _firestore
        .collectionGroup('notifications')
        .where('familyId', isEqualTo: familyId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<void> markAsRead({
    required String familyId,
    required String childUid,
    required String notificationId,
  }) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('children')
          .doc(childUid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<void> markAllAsRead({
    required String familyId,
    required String childUid,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('families')
          .doc(familyId)
          .collection('children')
          .doc(childUid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  @override
  Future<void> deleteNotification({
    required String familyId,
    required String childUid,
    required String notificationId,
  }) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('children')
          .doc(childUid)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  @override
  Future<void> clearOldNotifications({
    required String familyId,
    required String childUid,
    required DateTime olderThan,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('families')
          .doc(familyId)
          .collection('children')
          .doc(childUid)
          .collection('notifications')
          .where('timestamp', isLessThan: Timestamp.fromDate(olderThan))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear old notifications: $e');
    }
  }

  @override
  Future<void> addNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection('families')
          .doc(notification.familyId)
          .collection('children')
          .doc(notification.childUid)
          .collection('notifications')
          .add(notification.toMap());
    } catch (e) {
      throw Exception('Failed to add notification: $e');
    }
  }
}
