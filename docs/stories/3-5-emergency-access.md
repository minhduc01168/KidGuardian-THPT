# Story 3.5: Emergency Access

**Story ID:** E3.5
**Story Key:** 3-5-emergency-access
**Epic:** E3: Smart Lock (Android)
**Status:** ready-for-dev
**Priority:** P0
**Sprint:** 6
**Story Points:** 3

---

## Story

**As a** child,
**I want to** have emergency access to phone functions (call/text parent) even when apps are blocked,
**So that** I can contact my parents in urgent situations.

---

## Acceptance Criteria

### BDD Scenarios

**Scenario 1: Nút khẩn cấp trên màn hình khóa (Emergency Button on Lock Screen)**
* **Given** trẻ đang ở màn hình khóa (LockScreen) do ứng dụng bị chặn
* **When** trẻ nhìn thấy giao diện màn hình khóa
* **Then** hệ thống hiển thị nút "Liên hệ khẩn cấp" rõ ràng, dễ tìm
* **And** nút có icon và màu sắc nổi bật (đỏ/cam) để trẻ nhận biết đây là chức năng khẩn cấp

**Scenario 2: Gọi điện cho phụ huynh (Make Phone Call)**
* **Given** trẻ nhấn nút "Liên hệ khẩn cấp" trên màn hình khóa
* **When** hệ thống hiển thị bottom sheet với danh sách liên hệ
* **And** trẻ nhấn nút "Gọi điện" bên cạnh số phụ huynh
* **Then** hệ thống mở ứng dụng gọi điện với số phụ huynh đã điền sẵn (qua `url_launcher`)
* **And** hệ thống hiển thị đồng hồ đếm ngược 5 phút cảnh báo thời gian truy cập khẩn cấp

**Scenario 3: Nhắn tin cho phụ huynh (Send SMS)**
* **Given** trẻ nhấn nút "Liên hệ khẩn cấp" trên màn hình khóa
* **When** hệ thống hiển thị bottom sheet với danh sách liên hệ
* **And** trẻ nhấn nút "Nhắn tin" bên cạnh số phụ huynh
* **Then** hệ thống mở ứng dụng nhắn tin với số phụ huynh đã điền sẵn (qua `url_launcher`)
* **And** hệ thống hiển thị đồng hồ đếm ngược 5 phút cảnh báo thời gian truy cập khẩn cấp

**Scenario 4: Giới hạn thời gian truy cập khẩn cấp 5 phút (Emergency Access Time Limit)**
* **Given** trẻ đã kích hoạt chế độ khẩn cấp (bắt đầu gọi hoặc nhắn tin)
* **When** hệ thống bắt đầu đếm ngược 5 phút
* **And** trẻ quay lại ứng dụng KidGuardian
* **Then** hệ thống hiển thị banner/overlay cảnh báo "Truy cập khẩn cấp: còn X phút"
* **When** hết 5 phút
* **Then** hệ thống tự động thoát chế độ khẩn cấp
* **And** màn hình khóa hiển thị lại bình thường
* **And** trẻ không thể kích hoạt lại truy cập khẩn cấp trong vòng 15 phút (cooldown)

**Scenario 5: Ghi log sử dụng khẩn cấp (Emergency Usage Logging)**
* **Given** trẻ thực hiện hành động khẩn cấp (gọi hoặc nhắn tin)
* **When** hành động hoàn tất
* **Then** hệ thống ghi log vào Firestore collection `emergency_logs`
* **And** log chứa: `childUid`, `familyId`, `action` (call/sms), `phoneNumber`, `timestamp`, `duration` (thời gian truy cập khẩn cấp)
* **And** phụ huynh có thể xem log này trong dashboard (sẽ implement ở Epic khác)

**Scenario 6: Lấy số điện thoại phụ huynh từ Family Data**
* **Given** trẻ có tài khoản đã liên kết với phụ huynh
* **When** hệ thống hiển thị danh sách liên hệ khẩn cấp
* **Then** hệ thống lấy số điện thoại từ `UserModel` của phụ huynh (parent linked via `linkedTo`)
* **And** hiển thị tên và số điện thoại phụ huynh
* **If** chưa có số điện thoại → hiển thị thông báo "Chưa có số liên hệ. Vui lòng liên kết tài khoản phụ huynh."

---

## Developer Context

### Technical Requirements

**url_launcher Integration:**
* Thêm `url_launcher` vào `pubspec.yaml`
* Sử dụng `launchUrl(Uri.parse('tel:$phoneNumber'))` cho gọi điện
* Sử dụng `launchUrl(Uri.parse('sms:$phoneNumber'))` cho nhắn tin
* Android 11+ cần khai báo `<queries>` trong `AndroidManifest.xml`:
  ```xml
  <queries>
    <intent><action android:name="android.intent.action.DIAL" /></intent>
    <intent><action android:name="android.intent.action.SENDTO" /></intent>
  </queries>
  ```
* Kiểm tra `await canLaunchUrl()` trước khi launch, hiển thị lỗi nếu không khả dụng

**Emergency Access Timer (5 phút):**
* Tạo `EmergencyAccessManager` singleton hoặc class quản lý trạng thái:
  ```dart
  class EmergencyAccessManager {
    bool isActive = false;
    DateTime? activatedAt;
    DateTime? cooldownUntil;
    Timer? _timer;
    static const Duration emergencyDuration = Duration(minutes: 5);
    static const Duration cooldownDuration = Duration(minutes: 15);
  }
  ```
* Kích hoạt timer khi trẻ gọi điện hoặc nhắn tin
* Hiển thị countdown banner trên LockScreen khi `isActive == true`
* Khi hết 5 phút → set `isActive = false`, set `cooldownUntil = now + 15min`
* Trong cooldown → disable nút khẩn cấp, hiển thị "Thử lại sau X phút"
* Sử dụng `Timer.periodic(Duration(seconds: 1))` để cập nhật UI
* Cancel timer trong `dispose()`

**Emergency Logging (Firestore):**
* Collection: `emergency_logs`
* Schema:
  ```json
  {
    "childUid": "string",
    "familyId": "string",
    "action": "call | sms",
    "phoneNumber": "string",
    "timestamp": "timestamp",
    "durationSeconds": "number",
    "appPackageName": "string"
  }
  ```
* Ghi log khi: (1) bắt đầu gọi/nhắn, (2) kết thúc (cập nhật durationSeconds)

**Get Parent Phone Number:**
* Lấy từ `UserModel` của phụ huynh qua `FamilyRepository`
* Sử dụng `linkedTo` field trong child's `UserModel` để tìm parent UID
* Query `users/{parentUid}` để lấy `phoneNumber`
* Fallback: nếu không có số → hiển thị thông báo lỗi

**EmergencyContactSheet Refactor:**
* Hiện tại là placeholder (SnackBar "sẽ có trong phiên bản tiếp theo")
* Cần refactor thành StatefulWidget quản lý state
* Inject `FamilyRepository` dependency để lấy số phụ huynh
* Inject `EmergencyAccessManager` để quản lý timer
* Hiển thị countdown khi đang trong chế độ khẩn cấp
* Disable nút khi trong cooldown

### Architecture Compliance

* **Clean Architecture + BLoC Pattern** (như dự án đang sử dụng)
* **Presentation Layer:** `EmergencyContactSheet` (StatefulWidget) → gọi use case/repository
* **Domain Layer:** Có thể tạo `EmergencyAccessUseCase` hoặc logic trực tiếp trong widget (đơn giản)
* **Data Layer:** Ghi log qua `Firestore` trực tiếp (không cần repository riêng cho 1 collection đơn giản)
* **Dependency Injection:** Sử dụng `get_it` (đã có trong project) để inject `FamilyRepository`

### File Structure Expectations

**Chỉnh sửa:**
* `lib/presentation/widgets/smart_lock/emergency_contact_sheet.dart` — Refactor từ placeholder thành chức năng đầy đủ
* `lib/presentation/screens/smart_lock/lock_screen.dart` — Truyền thêm `familyId`, `childUid` vào EmergencyContactSheet, hiển thị emergency countdown banner
* `android/app/src/main/AndroidManifest.xml` — Thêm `<queries>` cho url_launcher
* `pubspec.yaml` — Thêm `url_launcher`

**Tạo mới:**
* `lib/domain/usecases/smart_lock/emergency_access_manager.dart` — Singleton quản lý timer, cooldown, state
* `lib/data/datasources/remote/emergency_log_source.dart` — Ghi log emergency vào Firestore
* `test/domain/usecases/smart_lock/emergency_access_manager_test.dart` — Unit tests cho timer logic
* `test/presentation/widgets/smart_lock/emergency_contact_sheet_test.dart` — Cập nhật widget tests

### Dependencies

* `url_launcher` — Cần thêm vào `pubspec.yaml` (chưa có)
* `cloud_firestore` — Ghi log (đã có)
* `flutter_bloc` — State management (đã có)
* `get_it` — Dependency injection (đã có)

### Testing Requirements

* **Unit Tests:**
  - `EmergencyAccessManager`: timer activation, 5-min expiry, 15-min cooldown, can/cannot activate
  - Emergency log Firestore write
* **Widget Tests:**
  - `EmergencyContactSheet`: hiển thị số phụhuynh, gọi điện, nhắn tin, countdown banner, cooldown state
  - `LockScreen`: emergency banner hiển thị khi emergency active
* **Integration Tests:**
  - Flow: lock screen → emergency button → call parent → 5-min timer → auto-expire → cooldown

---

## Previous Story Intelligence (E3.4: Schedule Setting)

* **Dev Notes từ E3.4:** `SmartLockRepository` đã có pattern CRUD với Firestore — follow same pattern nếu cần thêm emergency log repository
* `AppBlockedState` đã có `familyId`, `childUid` — truyền trực tiếp vào `EmergencyContactSheet`
* `LockScreen` đã nhận `familyId`, `childUid` từ `AppBlockedState` — sẵn sàng truyền data
* `CountdownTimer` widget đã có từ E3.3 — có thể tái sử dụng pattern timer (nhưng emergency timer khác logic)
* `EmergencyContactSheet` hiện tại là placeholder tạo ở E3.3 — cần refactor hoàn toàn
* All text trong UI phải bằng tiếng Việt (convention từ E3.3)

## Previous Story Intelligence (E3.3: Lock Screen Display)

* `EmergencyContactSheet` đã được tạo với UI layout cơ bản (handle bar, title, contact info, call/message buttons)
* Buttons hiện tại hiển thị SnackBar "sẽ có trong phiên bản tiếp theo" — cần thay bằng `url_launcher` thật
* `LockScreen` đã có nút "Liên hệ khẩn cấp" gọi `_showEmergencyContactSheet()`
* `PopScope(canPop: false)` giữ nguyên — emergency sheet mở qua `showModalBottomSheet`
* Pattern `SingleChildScrollView` trong sheet đã được test — giữ nguyên để tránh overflow

---

## Git Intelligence

* Recent commits follow conventional commit style: `feat:`, `fix:`, `refactor:`
* All Smart Lock files are in `lib/presentation/blocs/smart_lock/`, `lib/presentation/widgets/smart_lock/`
* Tests mirror source structure under `test/`
* `flutter analyze` must pass with 0 new warnings
* All existing tests must continue to pass

---

## Tasks / Subtasks

- [x] Task 1: Thêm `url_launcher` dependency (AC: #2, #3)
  - [x] Thêm `url_launcher` vào `pubspec.yaml`
  - [x] Thêm `<queries>` vào `AndroidManifest.xml` cho Android 11+
  - [x] Chạy `flutter pub get`
  - [x] Verify không có lỗi build

- [x] Task 2: Tạo `EmergencyAccessManager` (AC: #4)
  - [x] Tạo `lib/domain/usecases/smart_lock/emergency_access_manager.dart`
  - [x] Implement timer 5 phút với `Timer.periodic`
  - [x] Implement cooldown 15 phút sau khi hết timer
  - [x] Implement `canActivate`, `activate()`, `deactivate()`
  - [x] Expose stream cho UI cập nhật
  - [x] Viết unit tests

- [x] Task 3: Tạo Emergency Log Source (AC: #5)
  - [x] Tạo `lib/data/datasources/remote/emergency_log_source.dart`
  - [x] Implement `logEmergencyStart(childUid, familyId, action, phoneNumber, appPackageName)`
  - [x] Implement `logEmergencyEnd(childUid, timestamp, durationSeconds)`
  - [x] Implement `getParentPhoneNumber`, `getParentName`
  - [x] Collection: `emergency_logs`

- [x] Task 4: Refactor `EmergencyContactSheet` (AC: #1, #2, #3, #6)
  - [x] Chuyển từ StatelessWidget → StatefulWidget
  - [x] Inject `EmergencyLogSource` để lấy số phụ huynh
  - [x] Hiển thị tên và số phụhuynh từ Firestore
  - [x] Thay SnackBar bằng `launchUrl(Uri.parse('tel:...'))` cho gọi điện
  - [x] Thay SnackBar bằng `launchUrl(Uri.parse('sms:...'))` cho nhắn tin
  - [x] Gọi `EmergencyAccessManager.activate()` khi gọi/nhắn
  - [x] Hiển thị countdown 5 phút khi đang trong chế độ khẩn cấp
  - [x] Disable nút khi trong cooldown
  - [x] Hiển thị lỗi nếu không có số phụ huynh
  - [x] Ghi log vào Firestore khi gọi/nhắn
  - [x] Cập nhật widget tests

- [x] Task 5: Cập nhật `LockScreen` hiển thị emergency banner (AC: #4)
  - [x] Listen `EmergencyAccessManager` state changes
  - [x] Hiển thị banner "Truy cập khẩn cấp: còn X phút" khi emergency active
  - [x] Banner có nền cam, text trắng, countdown timer
  - [x] Pass `parentUid` từ AppBlockedState → LockScreen → EmergencyContactSheet

- [x] Task 6: Integration testing và verify
  - [x] Test EmergencyAccessManager: activate, deactivate, cooldown, canActivate
  - [x] Test EmergencyContactSheet: title, subtitle, parent info, buttons, error state
  - [x] Chạy `flutter analyze` — 0 new warnings
  - [x] Chạy tất cả tests — 156 pass, 1 skip

---

## Dev Agent Record

### Agent Model Used
mimo-v2.5-pro (bmad-dev-story skill)

### Debug Log References
- Task 1: Added url_launcher ^6.3.1 to pubspec.yaml, added DIAL and SENDTO queries to AndroidManifest.xml
- Task 2: EmergencyAccessManager singleton with Timer.periodic(1s), 5-min emergency + 15-min cooldown, Stream-based state
- Task 3: EmergencyLogSource with lazy FirebaseFirestore, logs to `emergency_logs` collection
- Task 4: EmergencyContactSheet refactored to StatefulWidget, injectable EmergencyLogSource for testing, FakeEmergencyLogSource in tests
- Task 5: LockScreen listens to EmergencyAccessManager streams, orange banner with countdown, parentUid passed from AppBlockedState via FamilyModel
- Task 6: 156 tests pass (1 skip pre-existing), 0 new analyze warnings

### Completion Notes List
- ✅ url_launcher added with Android 11+ queries support
- ✅ EmergencyAccessManager: singleton, 5-min timer, 15-min cooldown, Stream-based remaining/state updates
- ✅ EmergencyLogSource: lazy Firestore init, logEmergencyStart/End, getParentPhoneNumber/getName
- ✅ EmergencyContactSheet: StatefulWidget, loads parent info from Firestore, real call/SMS via url_launcher, countdown banner, cooldown state, error handling
- ✅ LockScreen: parentUid parameter, emergency banner with countdown, stream subscriptions cleaned up in dispose()
- ✅ AppBlockedState: added parentUid field, populated via SmartLockRepository.getFamily()
- ✅ All text in Vietnamese, 156 tests pass, 0 new warnings

### File List
- pubspec.yaml (modified — added url_launcher)
- android/app/src/main/AndroidManifest.xml (modified — added DIAL/SENDTO queries)
- lib/domain/usecases/smart_lock/emergency_access_manager.dart (new)
- lib/data/datasources/remote/emergency_log_source.dart (new)
- lib/presentation/widgets/smart_lock/emergency_contact_sheet.dart (modified — refactored from placeholder to full implementation)
- lib/presentation/screens/smart_lock/lock_screen.dart (modified — added parentUid, emergency banner, stream subscriptions)
- lib/presentation/blocs/smart_lock/app_monitor_bloc.dart (modified — added parentUid to AppBlockedState, _getParentUid())
- lib/data/repositories/smart_lock_repository.dart (modified — added getFamily() method)
- lib/main.dart (modified — pass parentUid to LockScreen)
- test/presentation/widgets/smart_lock/emergency_contact_sheet_test.dart (modified — rewritten with FakeEmergencyLogSource)
- test/presentation/blocs/smart_lock/app_monitor_bloc_test.dart (modified — updated props count)

---

## Change Log

| Date | Change | Author |
|------|--------|--------|
| 2026-05-16 | Story created from E3.5 epic specification | Story Context Engine |
| 2026-05-16 | Implemented E3.5: url_launcher, EmergencyAccessManager, EmergencyLogSource, EmergencyContactSheet refactor, LockScreen emergency banner | Dev Agent (mimo-v2.5-pro) |

---

## Status Updates
*   [x] Context Analyzed
*   [x] Architecture Requirements Verified
*   [x] Implementation Guide Created
*   [x] Dev Agent Assigned
*   [x] Code Complete
*   [ ] Code Reviewed
