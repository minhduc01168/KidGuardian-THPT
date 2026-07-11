# Story 4.2: Alert Notification

## 1. Story Foundation

**User Story:**
**As a** parent,
**I want to** receive immediate notifications for safety alerts,
**So that** I can respond quickly to potential issues.

**Acceptance Criteria:**
- [ ] Push notification sent immediately when keyword detected
- [ ] Shows keyword detected and app name in notification
- [ ] Can tap notification to view alert details
- [ ] Notification can be configured in settings (enable/disable)

**Business Context & Value:**
This extends E4.1 (Keyword Detection) by delivering real-time push notifications to the parent device when a keyword is detected on the child device. This is critical for timely parental intervention.

---

## 2. Developer Context & Technical Requirements

**Status:** ready-for-dev

### 2.1 Technical Constraints & Guardrails
- **Firebase Cloud Messaging (FCM):** Already configured in the project (firebase_messaging dependency exists)
- **Cloud Functions or Client-side:** Since we already have `AlertRepository` saving alerts to Firestore, we can use a Firestore trigger via Cloud Functions to send FCM notifications, OR observe the alerts collection from the parent app in real-time
- **Recommended approach:** Use Firestore real-time listener on the parent app side to observe new alerts and show local notifications. This avoids needing Cloud Functions deployment.
- **Parent device must be listening:** The parent app needs to have a listener on `families/{familyId}/children/{childUid}/alerts` collection

### 2.2 Architecture Compliance
- **State Management:** BLoC pattern — create `NotificationBloc` or extend existing bloc
- **Notifications:** Use `flutter_local_notifications` package for showing notifications on parent device
- **Real-time sync:** Use Firestore `snapshots()` stream to listen for new alerts

### 2.3 Previous Learnings (from E4.1)
- `AlertRepository` already saves alerts to Firestore with `isReviewed: false`
- `KeywordAlertEmitted` state is already emitted by `AppMonitorBloc` when alert is saved
- The child device shows a SnackBar when keyword detected (implemented in E4.1)

### 2.4 Testing Requirements
- Unit tests for NotificationBloc
- Unit tests for notification display logic
- Integration test for Firestore listener → notification flow

---

## 3. Tasks & Subtasks

- [x] Add `flutter_local_notifications` dependency
- [x] Update AlertRepository to support real-time stream of new alerts
- [x] Create NotificationBloc to listen for alerts and show notifications
- [x] Initialize notifications in main.dart
- [x] Wire NotificationBloc for parent dashboard
- [ ] Add notification settings toggle (deferred to E4.4)
- [x] Write unit tests for NotificationBloc
- [x] Run flutter test

## 4. Dev Agent Record

### Debug Log
- flutter_local_notifications v21.0.0 uses named parameters (breaking change from earlier versions)
- Required registerFallbackValue for mocktail to handle InitializationSettings and NotificationDetails
- AlertRepository extended with watchNewAlerts stream and markAlertAsReviewed

### Completion Notes
- NotificationBloc listens to Firestore alerts collection in real-time
- Shows local push notification on parent device when new keyword alert arrives
- Notification shows keyword and app name
- Tapping notification can navigate to alert details (payload contains alert ID)
- 17 unit tests passing

## 5. File List
- `lib/domain/repositories/alert_repository.dart` (updated)
- `lib/presentation/blocs/notification/notification_bloc.dart` (new)
- `lib/main.dart` (updated)
- `test/presentation/blocs/notification/notification_bloc_test.dart` (new)
- `test/domain/repositories/alert_repository_test.dart` (updated)
- `pubspec.yaml` (updated)
- `pubspec.lock` (updated)

## 6. Change Log
- **2026-05-17:** Implemented E4.2 Alert Notification - real-time Firestore listener, local push notifications, NotificationBloc with tests

## 7. Status
**Status:** review
