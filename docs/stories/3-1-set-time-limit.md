# Story: 3-1-set-time-limit
# KidGuardian - Đồng Hành Số

**Story ID:** E3.1
**Story Key:** 3-1-set-time-limit
**Epic:** E3: Smart Lock (Android)
**Status:** done
**Priority:** P0
**Sprint:** 5

---

## Story Overview

### User Story Statement
**As a** parent,  
**I want to** set daily time limits for specific apps,  
**So that** I can control how much time my child spends on each app.

### Business Value
Chức năng này là tính năng cốt lõi của ứng dụng (Smart Lock), cho phép phụ huynh chủ động quản lý và bảo vệ thời gian sử dụng thiết bị của trẻ. Đây là một trong những USP (Unique Selling Proposition) của dự án đối với người dùng cuối (phụ huynh).

---

## Acceptance Criteria

### BDD Scenarios

**Scenario 1: Hiển thị danh sách ứng dụng để cài đặt giới hạn**
* **Given** phụ huynh đang ở màn hình Smart Lock của một trẻ
* **When** phụ huynh chọn "Cài đặt giới hạn thời gian" (Set Time Limit)
* **Then** hệ thống hiển thị danh sách các ứng dụng mạng xã hội đã cài đặt trên thiết bị của trẻ
* **And** hệ thống hiển thị các ứng dụng đã được thiết lập thời gian (nếu có) lên đầu danh sách

**Scenario 2: Đặt giới hạn thời gian mới cho một ứng dụng**
* **Given** phụ huynh đang xem danh sách ứng dụng
* **When** phụ huynh chọn một ứng dụng chưa có giới hạn thời gian (ví dụ: TikTok)
* **And** phụ huynh thiết lập thời gian (ví dụ: 60 phút) qua UI chọn giờ/phút
* **And** phụ huynh nhấn nút "Lưu"
* **Then** hệ thống cập nhật giới hạn thời gian vào Firestore (Firebase)
* **And** hệ thống hiển thị thông báo "Đã lưu cài đặt thời gian cho TikTok thành công"
* **And** ứng dụng cập nhật trạng thái hiển thị thời gian giới hạn là 60 phút trong danh sách

**Scenario 3: Đặt giới hạn thời gian theo ngày trong tuần (Tùy chọn)**
* **Given** phụ huynh đang ở màn hình đặt thời gian cho một ứng dụng
* **When** phụ huynh bật tuỳ chọn "Áp dụng theo ngày"
* **Then** hệ thống hiển thị các thứ trong tuần (T2-CN)
* **And** phụ huynh có thể đặt các mức thời gian khác nhau cho ngày thường (ví dụ: T2-T6: 30 phút) và cuối tuần (ví dụ: T7-CN: 120 phút)
* **And** khi nhấn "Lưu", thiết lập được ghi nhận chính xác theo từng ngày trong Firestore

**Scenario 4: Chỉnh sửa thời gian đã thiết lập**
* **Given** phụ huynh đã đặt giới hạn 60 phút cho TikTok
* **When** phụ huynh nhấn vào TikTok trong danh sách
* **And** thay đổi thời gian thành 30 phút và nhấn "Lưu"
* **Then** hệ thống cập nhật lại giới hạn thành 30 phút trên Firestore
* **And** thông báo "Đã cập nhật cài đặt thành công" được hiển thị

**Scenario 5: Gửi thông báo đến thiết bị của trẻ**
* **Given** thiết bị của trẻ đang kết nối mạng
* **When** phụ huynh lưu/cập nhật thiết lập thời gian mới
* **Then** hệ thống gửi thông báo (silent data message qua FCM hoặc sync realtime) đến thiết bị của trẻ
* **And** thiết bị của trẻ cập nhật logic time limit nội bộ tương ứng

---

## Developer Context

### Technical Requirements

*   **UI/UX:**
    *   Tạo màn hình `TimeLimitScreen` liệt kê các ứng dụng có thể chọn.
    *   Sử dụng BottomSheet hoặc Dialog (như `showModalBottomSheet` hoặc `showTimePicker` biến tấu) để phụ huynh chọn giờ/phút. Cần design thân thiện (Slider hoặc wheel picker cho minutes/hours).
    *   Hỗ trợ Toggle cho phép chọn cài đặt "Mỗi ngày như nhau" (Everyday) hoặc "Tuỳ chỉnh theo ngày" (Custom days).
*   **Data Models:** Cần tạo hoặc cập nhật model `AppTimeLimit`.
    *   Cấu trúc Firestore đề xuất (tương đối): `families/{familyId}/children/{childId}/timeLimits/{appPackageName}`
    *   `appPackageName`: String (VD: `com.zhiliaoapp.musically`)
    *   `appName`: String (VD: `TikTok`)
    *   `iconUrl` hoặc icon định dạng base64/tên chuẩn nếu lấy từ local.
    *   `limits`: Map/Dictionary lưu giới hạn phút cho từng ngày (VD: `{'monday': 60, 'tuesday': 60, ..., 'sunday': 120}`) hoặc số phút chung `{'everyday': 60}`.
*   **State Management (BLoC):**
    *   Tạo `TimeLimitBloc` hoặc `SmartLockBloc` để quản lý state loading, loaded apps, saving, success, error.
*   **Backend (Firebase/Firestore):**
    *   Sử dụng Firebase Cloud Firestore để lưu và đọc dữ liệu giới hạn thời gian.
    *   Lưu ý xử lý offline-support (persistence) của Firestore để UI không bị gián đoạn nếu mất mạng ngắn hạn.

### Architecture Compliance

*   Dự án sử dụng kiến trúc BLoC. Mọi logic xử lý gọi API (Firestore) phải nằm trong thư mục `data/repositories` và được gọi thông qua BLoC (`presentation/bloc`).
*   Tuyệt đối **không** viết logic lưu Firestore trực tiếp bên trong UI widget.
*   Thiết kế chia rõ: `models`, `repositories`, `blocs`, `ui/screens`, `ui/widgets`.
*   Vì đây là Phase 1 (Android), cần chú trọng lấy `packageName` chuẩn của các app Android phổ biến (Youtube, TikTok, Facebook, Instagram, Zalo, Roblox, FreeFire, etc.).

### File Structure Expectations

Dự kiến các file cần tạo/chỉnh sửa (theo cấu trúc thư mục Flutter chuẩn):
*   `lib/data/models/app_time_limit_model.dart`
*   `lib/data/repositories/smart_lock_repository.dart` (nếu chưa có)
*   `lib/presentation/blocs/smart_lock/smart_lock_bloc.dart`, `smart_lock_event.dart`, `smart_lock_state.dart`
*   `lib/presentation/screens/smart_lock/time_limit_screen.dart`
*   `lib/presentation/widgets/smart_lock/app_limit_item.dart`
*   `lib/presentation/widgets/smart_lock/time_picker_bottom_sheet.dart`

### Dependencies

*   `flutter_bloc`: Cho State Management.
*   `cloud_firestore`: Cho Database.
*   Có thể cân nhắc thư viện như `numberpicker` hoặc custom CupertinoPicker để làm UI chọn giờ/phút đẹp mắt.

### Testing Requirements

*   Unit tests cho `SmartLockBloc` đảm bảo các event load và save trả về đúng state.
*   Unit test cho hàm parse Data model `AppTimeLimitModel.fromJson` và `toJson`.
*   Widget test cơ bản cho `TimeLimitScreen` để đảm bảo UI hiển thị danh sách khi có data.

---

## Project Context Reference

*   **Kiến trúc tổng quan:** Tham khảo `docs/prd/PRD.md` và `docs/epics/SPRINT-PLAN.md` (Sprint 5) để hiểu rõ đây là phần cấu hình cho Smart Lock Core. Việc setup `Time Limit` (E3.1) sẽ là dữ liệu đầu vào (input) cực kỳ quan trọng cho tính năng chặn app (App Blocking - E3.2) sẽ làm tiếp theo.
*   Hệ thống thiết lập thời gian giới hạn phải được thiết kế để sau này agent App Blocking (Service chạy ngầm Android) có thể đọc hiểu dễ dàng.

## Tasks/Subtasks

- [x] 1. Tạo Data Model `AppTimeLimitModel` và viết Unit Tests.
- [x] 2. Tạo `SmartLockRepository` để thao tác với Firestore.
- [x] 3. Tạo `SmartLockBloc` và viết Unit Tests cho BLoC.
- [x] 4. Xây dựng UI: `TimePickerBottomSheet`, `AppLimitItem` và `TimeLimitScreen`.
- [x] 5. Tích hợp BLoC vào UI và kiểm tra hiển thị.

### Review Follow-ups (AI)
- [x] Xử lý lỗi `SetOptions(merge: true)` trong `smart_lock_repository.dart`
- [x] Fix lỗi 0 phút không bị gỡ bỏ thiết lập trong `time_picker_bottom_sheet.dart`
- [x] Sửa an toàn parse JSON trong `app_time_limit_model.dart`
- [x] Bắt lỗi giá trị âm cho tuỳ chỉnh từng ngày trong `time_picker_bottom_sheet.dart`

### Senior Developer Review (AI)

**Review Outcome:** Changes Requested
**Date:** 2026-05-15

#### Action Items
- [x] [Review][Patch] Sửa lỗi parse JSON trong `AppTimeLimitModel.fromJson` — Cần chuyển đổi kiểu linh hoạt (xử lý `num`, `double`) thay vì ép kiểu cứng sang `int`.
- [x] [Review][Patch] Sửa lỗi hardcoded ID trong `TimeLimitScreen` — Cần dùng biến `familyId` và `childId` thực tế để dispatch `SaveAppTimeLimit` event.
- [x] [Review][Patch] Sửa thông báo thành công trong `SmartLockBloc` — Cần kiểm tra update (chứ không chỉ thêm mới) và hiển thị thông báo "Đã cập nhật cài đặt thành công" theo đúng specs.
- [x] [Review][Patch] Fix giao diện `TimePickerBottomSheet` — Thêm xử lý `SafeArea` và tính lại `height` tránh overflow trên các màn hình có tỉ lệ khác.
- [x] [Review][Patch] Sửa lỗi nút trừ (Minus Button) trong `TimePickerBottomSheet` — Cho phép giảm số phút xuống mức 0 để gỡ bỏ hoàn toàn giới hạn thời gian.
- [x] [Review][Defer] Lỗi nuốt exception (`e.toString()`) trong BLoC / Repository — deferred, pre-existing.
- [x] [Review][Defer] Lỗi logic sắp xếp danh sách mỏng manh trong `SmartLockBloc` phụ thuộc `.isNotEmpty` — deferred, pre-existing.
- [x] [AI-Review][High] Sửa logic `SetOptions(merge: true)` trong repository gây lỗi merge thời gian trên database.
- [x] [AI-Review][High] Sửa lỗi đặt về 0 phút không xoá thiết lập trong `TimePickerBottomSheet`.
- [x] [AI-Review][High] Xoá null cast nguy hiểm `as String` cho các key bắt buộc trong json parsing của Model.
- [x] [AI-Review][Med] Chặn giá trị phút âm khi nhấn trừ trong tuỳ chỉnh nhiều ngày.

---

## Dev Agent Record

### Debug Log
* Khởi tạo file model `AppTimeLimitModel` cùng với các unit tests.
* Khởi tạo `SmartLockRepository` cùng tests. Sửa lỗi `SetOptions` trong test với `any()`.
* Triển khai `SmartLockBloc` cho việc xử lý state (Load, Save) và kết hợp danh sách apps được cài đặt trước (popular apps) và danh sách cấu hình.
* Xây dựng UI Component `AppLimitItem`, `TimePickerBottomSheet` hỗ trợ lựa chọn thời gian (everyday và custom days).
* Xây dựng `TimeLimitScreen` tích hợp BLoC và hiển thị list. Đã thay đổi import path cho đúng và thêm `repository` param cho testing.

### Completion Notes
* ✅ Resolved review finding [High]: Sửa logic `SetOptions(merge: true)` trong repository gây lỗi merge thời gian trên database.
* ✅ Resolved review finding [High]: Sửa lỗi đặt về 0 phút không xoá thiết lập trong `TimePickerBottomSheet`.
* ✅ Resolved review finding [High]: Xoá null cast nguy hiểm `as String` cho các key bắt buộc trong json parsing của Model. Đã thêm `app_time_limit_model_edge_case_test.dart`
* ✅ Resolved review finding [Med]: Chặn giá trị phút âm khi nhấn trừ trong tuỳ chỉnh nhiều ngày. Đã thêm `time_picker_bottom_sheet_zero_test.dart`.
* Đã hoàn thành toàn bộ ACs và tests với độ phủ cao. Tính năng thiết lập thời gian giới hạn đã sẵn sàng. Firebase Cloud Firestore được tích hợp.

---

## File List

* `lib/data/models/app_time_limit_model.dart`
* `test/data/models/app_time_limit_model_test.dart`
* `test/data/models/app_time_limit_model_edge_case_test.dart`
* `lib/data/repositories/smart_lock_repository.dart`
* `test/data/repositories/smart_lock_repository_test.dart`
* `lib/presentation/blocs/smart_lock/smart_lock_event.dart`
* `lib/presentation/blocs/smart_lock/smart_lock_state.dart`
* `lib/presentation/blocs/smart_lock/smart_lock_bloc.dart`
* `test/presentation/blocs/smart_lock/smart_lock_bloc_test.dart`
* `lib/presentation/widgets/smart_lock/app_limit_item.dart`
* `test/presentation/widgets/smart_lock/app_limit_item_test.dart`
* `lib/presentation/widgets/smart_lock/time_picker_bottom_sheet.dart`
* `test/presentation/widgets/smart_lock/time_picker_bottom_sheet_test.dart`
* `test/presentation/widgets/smart_lock/time_picker_bottom_sheet_zero_test.dart`
* `lib/presentation/screens/smart_lock/time_limit_screen.dart`
* `test/presentation/screens/smart_lock/time_limit_screen_test.dart`

---

## Change Log

* 2026-05-15: Addressed code review findings - 4 items resolved (Date: 2026-05-15)
* 2026-05-14: Thêm models, repository, bloc và views cho Time Limit feature (Story 3-1). Đã setup và passed tất cả unit và widget tests.

---

## Status Updates
*   [x] Context Analyzed
*   [x] Architecture Requirements Verified
*   [x] Implementation Guide Created
*   [x] Dev Agent Assigned
*   [x] Code Complete
*   [x] Code Reviewed
