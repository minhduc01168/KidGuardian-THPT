# Story: 3-2-app-blocking
# KidGuardian - Đồng Hành Số

**Story ID:** E3.2
**Story Key:** 3-2-app-blocking
**Epic:** E3: Smart Lock (Android)
**Status:** done
**Priority:** P0
**Sprint:** 5

---

## Story Overview

**As a** parent,  
**I want** apps to be automatically blocked when time limit is reached,  
**So that** my child cannot continue using blocked apps.

### Business Value
Tính năng này là phần cốt lõi của tính năng khóa thông minh (Smart Lock) dành cho thiết bị Android. Tính năng này thực thi những giới hạn mà phụ huynh đã thiết lập ở Story 3.1, đảm bảo môi trường kỹ thuật số lành mạnh và ngăn chặn việc trẻ lạm dụng thời gian trên ứng dụng vượt quá mức cho phép.

---

## Acceptance Criteria

### BDD Scenarios

**Scenario 1: Theo dõi thời gian sử dụng ứng dụng trong thời gian thực (Real-time Monitoring)**
* **Given** ứng dụng KidGuardian đã được cấp quyền Accessibility Service và Usage Access trên thiết bị Android của trẻ
* **When** trẻ mở một ứng dụng (ví dụ: TikTok) thuộc danh sách đang được giám sát giới hạn thời gian
* **Then** hệ thống (AppMonitorService) bắt đầu theo dõi thời gian và tính toán số phút trẻ đang sử dụng
* **And** hệ thống liên tục kiểm tra so với mức giới hạn thời gian (Limit) đã được lấy từ Firestore

**Scenario 2: Tự động khóa ứng dụng khi hết thời gian (Automatic Blocking)**
* **Given** trẻ đang sử dụng một ứng dụng bị giới hạn
* **When** tổng thời gian sử dụng trong ngày của ứng dụng đó đạt đến mức giới hạn (ví dụ: chạm mốc 60 phút)
* **Then** hệ thống gửi tín hiệu để khóa ngay lập tức ứng dụng
* **And** thiết bị không cho phép trẻ thao tác tiếp trên ứng dụng đó

**Scenario 3: Hiển thị màn hình khóa thân thiện (Lock Screen Display)**
* **Given** một ứng dụng vừa bị hệ thống khóa do hết thời gian
* **When** quá trình chặn diễn ra
* **Then** một màn hình Overlay/Lock Screen hiển thị đè lên ứng dụng
* **And** hiển thị thông báo rõ ràng "Hết thời gian sử dụng" hoặc lý do tương ứng (Sẽ mở rộng UI kỹ hơn ở Story 3.3)

**Scenario 4: Ngăn chặn trẻ lách luật (Bypass Prevention)**
* **Given** màn hình khóa đang hiển thị
* **When** trẻ cố gắng nhấn nút Back hoặc quay lại ứng dụng vừa bị khóa từ Recent Apps
* **Then** màn hình khóa vẫn tiếp tục hiển thị hoặc tự động đẩy trẻ về màn hình Home
* **And** trẻ không thể tiếp tục dùng ứng dụng trừ khi có thời gian mở rộng (E5.1)

**Scenario 5: Ghi nhận lịch sử sử dụng vào Firestore (Usage Logging)**
* **Given** quá trình sử dụng ứng dụng diễn ra
* **When** ứng dụng bị đóng hoặc bị chặn
* **Then** hệ thống tính toán thời lượng session và ghi nhận log vào collection `usage_logs` trên Firestore (gồm `childUid`, `appPackage`, `durationMinutes`, `date` v.v...)

---

## Developer Context

### Technical Requirements

*   **Android Native Layer:**
    *   Sử dụng **AccessibilityService** (`AppMonitorService.kt`) để lắng nghe sự kiện `TYPE_WINDOW_STATE_CHANGED` nhằm phát hiện package name của ứng dụng đang mở (Foreground App).
    *   Kiểm tra `packageName` so với danh sách ứng dụng đã thiết lập `AppTimeLimitModel`.
    *   Tính toán thời lượng thực tế ứng dụng được mở trong ngày.
*   **Giao tiếp Native - Flutter:**
    *   Tạo và hoàn thiện `AccessibilityChannel` trong `lib/platform/android/accessibility_channel.dart`.
    *   Truyền sự kiện (Event Stream) từ Android Native sang Flutter qua `MethodChannel`/`EventChannel` khi một app bị block (vd: gửi `{ "type": "app_blocked", "packageName": "com.zhiliaoapp.musically" }`).
*   **Flutter Domain / Data Layer:**
    *   Triển khai `CheckAppAccessUseCase` để tính toán logic thời gian (so sánh tổng thời gian đã sử dụng với giới hạn trong `AppTimeLimitModel`).
    *   Triển khai `BlockAppUseCase` để xử lý logic gọi Native block (nếu có) hoặc gọi màn hình Lock Screen.
    *   Cập nhật `UsageRepositoryImpl` để push data lên collection `usage_logs` (theo Architecture spec).
*   **Flutter Presentation Layer:**
    *   Cập nhật `SmartLockBloc` hoặc tạo Bloc mới chuyên quản lý việc nhận tín hiệu Blocked App.
    *   Xây dựng `LockScreen` (basic) hoặc Widget overlay cho việc chặn (có thể dùng Android System Alert Window hoặc mở một Route riêng trong Flutter App chặn các background manipulation).

### Architecture Compliance

*   Dự án sử dụng **Clean Architecture** và **BLoC Pattern**.
*   **Infrastructure (Android Native):** Phần nhận diện app phải hoàn toàn nằm ở native code (`AppMonitorService.kt`). Flutter layer chỉ nhận tín hiệu và phản hồi UI hoặc gọi API Firebase.
*   **Database Schema:**
    *   Sử dụng collection `usage_logs` đã được định nghĩa trong `ARCHITECTURE.md`.
    *   Cấu trúc ghi log: `docId` (auto-generated), `childUid`, `familyId`, `appPackage`, `appName`, `startTime`, `endTime`, `durationMinutes`, `date` (YYYY-MM-DD).
*   **Security:** Chỉ lưu/đọc dữ liệu nếu user có thẩm quyền. Đảm bảo dùng offline persistence của Firebase để ứng dụng vẫn có thể chặn kể cả khi trẻ ngắt kết nối mạng. (Cache dữ liệu Limits về local).

### File Structure Expectations

Dự kiến các file cần tạo/chỉnh sửa:
*   `android/app/src/main/kotlin/com/kidguardian/accessibility/AppMonitorService.kt`
*   `lib/platform/android/accessibility_channel.dart`
*   `lib/domain/usecases/smart_lock/check_app_access_usecase.dart`
*   `lib/domain/usecases/smart_lock/block_app_usecase.dart`
*   `lib/data/repositories/usage_repository_impl.dart`
*   `lib/domain/repositories/usage_repository.dart`
*   `lib/presentation/screens/smart_lock/lock_screen.dart`
*   `lib/data/models/usage_log_model.dart`
*   `lib/domain/entities/usage_log.dart`

---

## Previous Story Intelligence (E3.1: Set Time Limit)

*   **Dev Notes từ E3.1:** Chú ý việc parse JSON linh hoạt (int, double) trong `AppTimeLimitModel`. Data time limits lưu theo dạng map ngày trong tuần (`{'everyday': 60}` hoặc tuỳ chỉnh `{'monday': 30, ...}`). Service giám sát cần load config này trước khi so sánh.
*   Dữ liệu gốc đã được đưa vào Firestore path: `families/{familyId}/children/{childId}/timeLimits/{appPackageName}`.
*   Dữ liệu Time Limit có nguy cơ `merge: true` nếu ghi đè nên luôn chú ý gọi load chính xác trước khi trigger block logic.

## Latest Tech Information

*   **Android Background Execution Restrictions (API 29+):** Kể từ Android 10, ứng dụng không thể dễ dàng start Activity từ background (trừ phi có Service foreground/accessibility hoặc Permission SYSTEM_ALERT_WINDOW). 
*   **Bypass Prevention:** Để ngăn trẻ quay lại app nhanh chóng sau khi app bị back (Lock), hãy trigger Intent đưa thiết bị về màn hình Home (Action: `Intent.ACTION_MAIN`, Category: `Intent.CATEGORY_HOME`), ĐỒNG THỜI khởi chạy Lock Screen của Flutter.
*   **Offline Data:** Cực kỳ quan trọng phải cache `AppTimeLimitModel` sử dụng Local Database hoặc chế độ Offline Cache của Firebase Firestore, nếu không trẻ có thể ngắt WiFi/4G để bypass giới hạn thời gian.

## Project Context Reference

- [Source: docs/prd/PRD.md#3.3 Epic 3: Smart Lock (Android Priority)]
- [Source: docs/architecture/ARCHITECTURE.md#6.1 Android - Smart Lock Implementation]
- [Source: docs/architecture/ARCHITECTURE.md#4.1 Collections] -> Schema of `usage_logs`.

---

## Tasks / Subtasks

- [x] Task 1: Setup Models & Repositories cho Usage Tracking
  - [x] Tạo `UsageLog` entity, `UsageLogModel` theo schema `usage_logs`.
  - [x] Tạo `UsageRepository` và `UsageRepositoryImpl` để push log lên Firestore.
- [x] Task 2: Android Native - Accessibility Service (`AppMonitorService.kt`)
  - [x] Khởi tạo `AppMonitorService` extend `AccessibilityService`.
  - [x] Đăng ký service trong `AndroidManifest.xml` (cần permission `BIND_ACCESSIBILITY_SERVICE` và XML config).
  - [x] Code logic bắt event `TYPE_WINDOW_STATE_CHANGED` để tính giờ foreground app.
- [x] Task 3: Liên kết Flutter - Native (`AccessibilityChannel`)
  - [x] Khởi tạo method channel / event channel để trao đổi list app limits từ Flutter -> Native (hoặc cho Native đọc từ SharedPrefs/Local).
  - [x] Gửi tín hiệu `app_blocked` từ Native về Flutter.
- [x] Task 4: Triển khai Domain Usecases
  - [x] Xây dựng `CheckAppAccessUseCase`.
  - [x] Xây dựng `BlockAppUseCase`.
- [x] Task 5: Triển khai UI Lock Screen & BLoC Event Handler
  - [x] Code giao diện `LockScreen` cơ bản (có nút về Home).
  - [x] Setup global listener trong App (hoặc tại `main.dart` / global BLoC) để listen `onAppBlocked` stream và tự động navigate/hiển thị `LockScreen`.

## Dev Agent Record

### Agent Model Used
gemini-3.1-pro-preview

### Debug Log References
- Extracted exact requirements and schema mappings from ARCHITECTURE.md for `usage_logs` and `AppMonitorService`.
- Reused context from `3-1-set-time-limit.md` to ensure `AppTimeLimitModel` continuity.
- Evaluated Android 10+ background limitations and provided specific technical approaches (SYSTEM_ALERT_WINDOW vs Intent.CATEGORY_HOME).
- Setup AppMonitorBloc to listen to AccessibilityService events and evaluate if access is allowed.

### Completion Notes
- Ultimate context engine analysis completed - comprehensive developer guide created. Giao cho Agent Development.
- All tasks implemented according to red-green-refactor cycle.
- The `AccessibilityService` tracks app usage by forwarding `TYPE_WINDOW_STATE_CHANGED` events to Flutter Engine via `EventChannel`.
- Flutter Engine (`AppMonitorBloc`) uses `CheckAppAccessUseCase` to compare the usage against limits stored in Firestore.
- Tests written and fully pass.

### File List
- `android/app/src/main/res/xml/accessibility_service_config.xml`
- `android/app/src/main/res/values/strings.xml`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/kidguardian/kidguardian/accessibility/AppMonitorService.kt`
- `android/app/src/main/kotlin/com/kidguardian/kidguardian/MainActivity.kt`
- `lib/platform/android/accessibility_channel.dart`
- `lib/domain/usecases/smart_lock/check_app_access_usecase.dart`
- `lib/domain/usecases/smart_lock/block_app_usecase.dart`
- `lib/presentation/screens/smart_lock/lock_screen.dart`
- `lib/presentation/blocs/smart_lock/app_monitor_bloc.dart`
- `lib/main.dart`
- `lib/data/repositories/usage_repository_impl.dart`
- `test/data/models/usage_log_model_test.dart`
- `test/data/repositories/usage_repository_impl_test.dart`
- `test/domain/usecases/smart_lock/check_app_access_usecase_test.dart`
- `test/domain/usecases/smart_lock/block_app_usecase_test.dart`
- `test/presentation/blocs/smart_lock/app_monitor_bloc_test.dart`

### Change Log
- Implemented App Blocking using AccessibilityService.
- Created `AppMonitorBloc` to handle tracking and blocking apps.
- Updated `MainActivity` and `AndroidManifest` for Android.
- Added Lock Screen UI.
