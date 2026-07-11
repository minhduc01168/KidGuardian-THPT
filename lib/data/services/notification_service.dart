import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kidguardian/domain/repositories/time_request_repository.dart';

class NotificationService {
  final FirebaseMessaging _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final TimeRequestRepository _timeRequestRepository;
  final FirebaseFirestore _firestore;

  static const String _channelId = 'kidguardian_requests';
  static const String _channelName = 'Time Requests';
  static const String _channelDescription = 'Notifications for time extension requests';

  static const String _approveAction = 'APPROVE_REQUEST';
  static const String _rejectAction = 'REJECT_REQUEST';

  String? _currentUid;

  NotificationService({
    FirebaseMessaging? fcm,
    FlutterLocalNotificationsPlugin? localNotifications,
    FirebaseFirestore? firestore,
    required TimeRequestRepository timeRequestRepository,
  })  : _fcm = fcm ?? FirebaseMessaging.instance,
        _localNotifications = localNotifications ?? FlutterLocalNotificationsPlugin(),
        _firestore = firestore ?? FirebaseFirestore.instance,
        _timeRequestRepository = timeRequestRepository;

  Future<void> initialize() async {
    await _requestPermissions();
    await _createNotificationChannel();
    await _configureFCM();
    _listenTokenRefresh();
  }

  Future<void> registerToken(String uid) async {
    try {
      _currentUid = uid;
      final token = await _fcm.getToken();
      if (token == null) {
        debugPrint('FCM token is null');
        return;
      }

      await _firestore.collection('users').doc(uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('FCM token registered for user: $uid');
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }

  void _listenTokenRefresh() {
    _fcm.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM token refreshed: $newToken');
      final uid = _currentUid;
      if (uid != null && uid.isNotEmpty) {
        try {
          await _firestore.collection('users').doc(uid).set({
            'fcmToken': newToken,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          debugPrint('Refreshed FCM token updated for user: $uid');
        } catch (e) {
          debugPrint('Error updating refreshed token: $e');
        }
      } else {
        debugPrint('Token refresh skipped - no user logged in');
      }
    });
  }

  Future<void> _requestPermissions() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: false,
    );
    debugPrint('FCM permission status: ${settings.authorizationStatus}');
  }

  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> _configureFCM() async {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.data}');
    if (message.data['type'] == 'time_request') {
      _showTimeRequestNotification(message.data);
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.data}');
  }

  Future<void> _showTimeRequestNotification(Map<String, dynamic> data) async {
    final requestId = data['requestId'] as String? ?? '';
    final familyId = data['familyId'] as String? ?? '';
    final childUid = data['childUid'] as String? ?? '';
    final appName = data['appName'] as String? ?? 'Unknown App';
    final requestedMinutes = int.tryParse(data['requestedMinutes']?.toString() ?? '0') ?? 0;
    final reason = data['reason'] as String? ?? '';

    final body = reason.isNotEmpty
        ? 'Xin thêm $requestedMinutes phút cho $appName\nLý do: $reason'
        : 'Xin thêm $requestedMinutes phút cho $appName';

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      autoCancel: true,
      actions: [
        AndroidNotificationAction(
          _approveAction,
          'Duyệt',
          showsUserInterface: false,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          _rejectAction,
          'Từ chối',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'TIME_REQUEST_CATEGORY',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload = jsonEncode({
      'requestId': requestId,
      'familyId': familyId,
      'childUid': childUid,
      'appName': appName,
      'requestedMinutes': requestedMinutes,
    });

    await _localNotifications.show(
      id: requestId.hashCode.abs(),
      title: 'Yêu cầu thêm thời gian',
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<void> handleNotificationAction(
    String action,
    Map<String, dynamic> data,
  ) async {
    final requestId = data['requestId'] as String? ?? '';
    final familyId = data['familyId'] as String? ?? '';
    final childUid = data['childUid'] as String? ?? '';
    final appName = data['appName'] as String? ?? 'Unknown App';
    final requestedMinutes = data['requestedMinutes'] as int? ?? 0;

    try {
      if (action == _approveAction) {
        await _timeRequestRepository.approveRequest(
          familyId: familyId,
          childUid: childUid,
          requestId: requestId,
          response: 'Đã duyệt nhanh từ thông báo',
        );
        await _sendConfirmationNotification(
          title: 'Đã duyệt yêu cầu',
          body: 'Đã duyệt thêm $requestedMinutes phút cho $appName',
          isApproved: true,
        );
      } else if (action == _rejectAction) {
        await _timeRequestRepository.rejectRequest(
          familyId: familyId,
          childUid: childUid,
          requestId: requestId,
          response: 'Đã từ chối nhanh từ thông báo',
        );
        await _sendConfirmationNotification(
          title: 'Đã từ chối yêu cầu',
          body: 'Đã từ chối yêu cầu thêm $requestedMinutes phút cho $appName',
          isApproved: false,
        );
      }
    } catch (e) {
      debugPrint('Error handling notification action: $e');
      await _sendConfirmationNotification(
        title: 'Lỗi xử lý',
        body: 'Không thể xử lý yêu cầu. Vui lòng thử lại trong ứng dụng.',
        isApproved: false,
      );
    }
  }

  Future<void> _sendConfirmationNotification({
    required String title,
    required String body,
    required bool isApproved,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      autoCancel: true,
      color: isApproved ? Color(0xFF4CAF50) : Color(0xFFF44336),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}
