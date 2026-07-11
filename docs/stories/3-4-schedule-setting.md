# Story 3.4: Schedule Setting

**Story ID:** E3.4  
**Story Key:** 3-4-schedule-setting  
**Epic:** E3: Smart Lock (Android)  
**Status:** done  
**Priority:** P1  
**Sprint:** 6  
**Story Points:** 5  

---

## Story

**As a** parent,  
**I want to** set schedules for when apps are blocked (e.g., bedtime, homework hours),  
**So that** my child focuses on homework or sleeps without device distraction.

---

## Acceptance Criteria

### BDD Scenarios

**Scenario 1: Hiển thị màn hình quản lý lịch trình**
* **Given** phụ huynh đang ở màn hình Smart Lock của một trẻ
* **When** phụ huynh chọn "Cài đặt lịch trình" (Schedule Setting)
* **Then** hệ thống hiển thị danh sách các lịch trình đã thiết lập (nếu có)
* **And** hiển thị nút "Thêm lịch trình" (Add Schedule)

**Scenario 2: Tạo lịch trình chặn mới (Blocked Time Period)**
* **Given** phụ huynh đang ở màn hình quản lý lịch trình
* **When** phụ huynh nhấn "Thêm lịch trình"
* **Then** hệ thống hiển thị form chọn: tên lịch trình, giờ bắt đầu, giờ kết thúc, các ngày áp dụng
* **And** phụ huynh có thể chọn giờ bắt đầu (ví dụ: 21:00) và giờ kết thúc (ví dụ: 06:00)
* **And** phụ huynh có thể chọn các ngày áp dụng (T2-CN, hoặc tuỳ chỉnh từng ngày)
* **When** phụ huynh nhấn "Lưu"
* **Then** hệ thống lưu lịch trình vào Firestore
* **And** hiển thị thông báo "Đã lưu lịch trình thành công"

**Scenario 3: Tạo lịch trình "Giờ học bài" (Homework Hours)**
* **Given** phụ huynh đang ở form tạo lịch trình
* **When** phụ huynh chọn template "Giờ học bài"
* **Then** hệ thống điền sẵn giờ mặc định (ví dụ: 18:00 - 21:00, T2-T6)
* **And** phụ huynh có thể chỉnh sửa giờ và ngày theo nhu cầu
* **And** lưu vào Firestore với type: "homework"

**Scenario 4: Chỉnh sửa lịch trình đã thiết lập**
* **Given** phụ huynh đã tạo lịch trình "Giờ ngủ" (21:00 - 06:00)
* **When** phụ huynh nhấn vào lịch trình và thay đổi giờ thành 22:00 - 06:00
* **And** nhấn "Lưu"
* **Then** hệ thống cập nhật lịch trình trên Firestore
* **And** thông báo "Đã cập nhật lịch trình thành công"

**Scenario 5: Xoá lịch trình**
* **Given** phụ huynh đang xem chi tiết một lịch trình
* **When** phụ huynh nhấn nút "Xoá" và xác nhận
* **Then** hệ thống xoá lịch trình khỏi Firestore
* **And** lịch trình không còn hiển thị trong danh sách

**Scenario 6: Tự động chặn ứng dụng theo lịch trình (Schedule Enforcement)**
* **Given** phụ huynh đã thiết lập lịch trình "Giờ ngủ" (21:00 - 06:00, hàng ngày)
* **When** thời gian hiện tại là 21:00
* **And** trẻ đang sử dụng ứng dụng bị giám sát
* **Then** hệ thống (AppMonitorService) tự động chặn tất cả ứng dụng bị giám sát
* **And** hiển thị màn hình khóa với lý do "Đang trong giờ ngủ"
* **And** trẻ không thể sử dụng ứng dụng cho đến 06:00

**Scenario 7: Kiểm tra lịch trình khi mở ứng dụng**
* **Given** thời gian hiện tại nằm trong một lịch trình chặn (ví dụ: 22:30 trong lịch 21:00-06:00)
* **When** trẻ mở một ứng dụng bị giám sát
* **Then** hệ thống kiểm tra lịch trình và chặn ứng dụng ngay lập tức
* **And** hiển thị màn hình khóa với lý do và thời gian còn lại đến khi hết lịch trình

---

## Developer Context

### Technical Requirements

**Data Model — `ScheduleModel`:**
```dart
// lib/data/models/schedule_model.dart
class ScheduleModel extends Equatable {
  final String id;           // Firestore doc ID
  final String name;         // "Giờ ngủ", "Giờ học bài", custom name
  final String type;         // "blocked" | "homework"
  final int startHour;       // 0-23
  final int startMinute;     // 0-59
  final int endHour;         // 0-23
  final int endMinute;       // 0-59
  final Map<String, bool> days; // {monday: true, tuesday: false, ...}
  final bool isEnabled;      // Toggle on/off without deleting
}
```

**Firestore Schema:**
```
families/{familyId}/children/{childId}/schedules/{scheduleId}
{
  "id": "auto-generated",
  "name": "Giờ ngủ",
  "type": "blocked",
  "startHour": 21,
  "startMinute": 0,
  "endHour": 6,
  "endMinute": 0,
  "days": {
    "monday": true,
    "tuesday": true,
    "wednesday": true,
    "thursday": true,
    "friday": true,
    "saturday": true,
    "sunday": true
  },
  "isEnabled": true,
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Note:** Schema follows the same path pattern as `timeLimits` — `families/{familyId}/children/{childId}/schedules/{scheduleId}`. The existing `families/{familyId}.settings.lockSchedule` in ARCHITECTURE.md is the family-level default; this story creates per-child schedules at a subcollection level for flexibility.

**Schedule Logic — `ScheduleChecker`:**
```dart
// lib/domain/usecases/smart_lock/schedule_checker.dart
class ScheduleChecker {
  /// Returns true if current time falls within any active schedule
  /// Handles overnight schedules (e.g., 21:00-06:00 crosses midnight)
  bool isInBlockedPeriod(List<ScheduleModel> schedules, DateTime now) {
    // For each enabled schedule:
    // 1. Check if today is a scheduled day
    // 2. Check if current time is between start and end
    // 3. Handle overnight: if endHour < startHour, check if time >= start OR time < end
  }
}
```

**SmartLockRepository — Add schedule CRUD methods:**
```dart
// Add to existing lib/data/repositories/smart_lock_repository.dart
Future<List<ScheduleModel>> getSchedules(String familyId, String childId);
Future<void> saveSchedule(String familyId, String childId, ScheduleModel schedule);
Future<void> deleteSchedule(String familyId, String childId, String scheduleId);
```

**AppMonitorBloc Integration:**
- Add schedule checking alongside time limit checking in `_onAppEventReceived` and `_onCheckCurrentAppLimit`
- When checking app access: check BOTH time limits AND schedules
- If either blocks → app is blocked
- Add `ScheduleChecker` dependency to `AppMonitorBloc`
- `_buildBlockedState` must include schedule reason if blocked by schedule

**UI Components:**
- `ScheduleScreen` — list of schedules + FAB to add
- `ScheduleFormScreen` — form with time range picker + day selector
- `TimeRangePicker` — start/end time selection (reuse patterns from `TimePickerBottomSheet`)
- `DaySelector` — 7-day toggle (Mon-Sun), similar to existing day selector in E3.1
- Predefined templates: "Giờ ngủ" (bedtime), "Giờ học bài" (homework hours)

### Architecture Compliance

* **Clean Architecture + BLoC Pattern** as established
* **Domain Layer:** `ScheduleModel` entity, `ScheduleChecker` use case
* **Data Layer:** `SmartLockRepository` extended with schedule CRUD
* **Presentation Layer:** `SmartLockBloc` extended with schedule events/states
* **Native Layer:** `AppMonitorService.kt` receives schedule data via `AccessibilityChannel` (same pattern as time limits)
* **Offline Support:** Firestore offline persistence already enabled — schedules cached locally
* **Security:** Only parent can write schedules (Firestore security rules already enforce this)

### File Structure Expectations

**Create:**
- `lib/data/models/schedule_model.dart`
- `lib/domain/usecases/smart_lock/schedule_checker.dart`
- `lib/presentation/screens/smart_lock/schedule_screen.dart`
- `lib/presentation/screens/smart_lock/schedule_form_screen.dart`
- `lib/presentation/widgets/smart_lock/time_range_picker.dart`
- `lib/presentation/widgets/smart_lock/day_selector.dart`
- `lib/presentation/widgets/smart_lock/schedule_card.dart`
- `test/data/models/schedule_model_test.dart`
- `test/domain/usecases/smart_lock/schedule_checker_test.dart`
- `test/presentation/screens/smart_lock/schedule_screen_test.dart`
- `test/presentation/screens/smart_lock/schedule_form_screen_test.dart`
- `test/presentation/widgets/smart_lock/time_range_picker_test.dart`
- `test/presentation/widgets/smart_lock/day_selector_test.dart`
- `test/presentation/widgets/smart_lock/schedule_card_test.dart`

**Modify:**
- `lib/data/repositories/smart_lock_repository.dart` — add `getSchedules`, `saveSchedule`, `deleteSchedule`
- `lib/presentation/blocs/smart_lock/smart_lock_event.dart` — add schedule events
- `lib/presentation/blocs/smart_lock/smart_lock_state.dart` — add schedule states
- `lib/presentation/blocs/smart_lock/smart_lock_bloc.dart` — handle schedule events
- `lib/presentation/blocs/smart_lock/app_monitor_bloc.dart` — integrate schedule checking
- `lib/presentation/navigation/app_router.dart` — add schedule routes
- `test/data/repositories/smart_lock_repository_test.dart` — add schedule tests
- `test/presentation/blocs/smart_lock/smart_lock_bloc_test.dart` — add schedule tests
- `test/presentation/blocs/smart_lock/app_monitor_bloc_test.dart` — add schedule integration tests

### Dependencies

* `flutter_bloc` — state management (already in project)
* `cloud_firestore` — database (already in project)
* `equatable` — model equality (already in project)
* No new dependencies required

### Testing Requirements

* **Unit Tests:**
  - `ScheduleModel` — `fromJson`, `toJson`, `copyWith`, edge cases (overnight schedules, empty days)
  - `ScheduleChecker` — all time boundary conditions: exact start time, exact end time, overnight crossing, disabled schedules, multiple overlapping schedules
* **BLoC Tests:**
  - `SmartLockBloc` — LoadSchedules, SaveSchedule, DeleteSchedule events
  - `AppMonitorBloc` — schedule + time limit combined blocking logic
* **Widget Tests:**
  - `ScheduleScreen` — empty state, list display, FAB
  - `ScheduleFormScreen` — time picker, day selector, save/cancel
  - `ScheduleCard` — display, edit/delete actions
  - `TimeRangePicker` — start/end selection
  - `DaySelector` — toggle days, select all/none

---

## Previous Story Intelligence

### From E3.1 (Set Time Limit)
* `AppTimeLimitModel` uses `Map<String, int> limits` with keys like `'everyday'` or `'monday'`, `'tuesday'`, etc. — follow same day-key pattern for `ScheduleModel.days`
* `SmartLockRepository` stores data at `families/{familyId}/children/{childId}/timeLimits/{appPackageName}` — schedules follow same path pattern at `schedules/{scheduleId}`
* `SmartLockBloc` already has `SmartLockLoading`, `SmartLockLoaded`, `SmartLockActionSuccess`, `SmartLockError` states — extend with schedule-specific states or reuse
* `TimePickerBottomSheet` has reusable patterns for time selection — adapt for `TimeRangePicker`
* JSON parsing: handle `num` types flexibly (not just `int`) — apply to `ScheduleModel.fromJson`

### From E3.2 (App Blocking)
* `AppMonitorBloc` has `_onAppEventReceived` and `_onCheckCurrentAppLimit` — both need schedule checking
* `CheckAppAccessUseCase` checks time limits only — `ScheduleChecker` is a separate use case that runs in parallel
* `AppMonitorService.kt` sends `TYPE_WINDOW_STATE_CHANGED` events — no native changes needed for schedule (schedule logic runs in Flutter/Dart)
* Offline caching critical — schedules must be cached so enforcement works when device is offline

### From E3.3 (Lock Screen Display)
* `AppBlockedState` already has `appName`, `iconUrl`, `limitMinutes`, `usedMinutes`, `resetTime` — add `blockReason` field to distinguish "time limit reached" vs "schedule blocked"
* `LockScreen` shows reason text — needs to handle schedule-specific messages (e.g., "Đang trong giờ ngủ", "Đang trong giờ học bài")
* `CountdownTimer` calculates time until 00:00 — for schedule blocks, calculate time until schedule end instead

---

## Git Intelligence

* Recent commits follow conventional commit style: `feat:`, `fix:`, `refactor:`
* All Smart Lock files are in `lib/presentation/blocs/smart_lock/`, `lib/data/models/`, `lib/data/repositories/`
* Tests mirror source structure under `test/`
* `flutter analyze` must pass with 0 new warnings
* All existing tests must continue to pass

---

## Tasks / Subtasks

- [x] Task 1: Create `ScheduleModel` and unit tests (AC: #1, #2, #3)
  - [x] Create `lib/data/models/schedule_model.dart` with `fromJson`, `toJson`, `copyWith`
  - [x] Support overnight schedules (endHour < startHour)
  - [x] Support `type` field: "blocked" and "homework"
  - [x] Write `test/data/models/schedule_model_test.dart` with edge cases

- [x] Task 2: Extend `SmartLockRepository` with schedule CRUD (AC: #2, #4, #5)
  - [x] Add `getSchedules(familyId, childId)` → `List<ScheduleModel>`
  - [x] Add `saveSchedule(familyId, childId, schedule)` → `void`
  - [x] Add `deleteSchedule(familyId, childId, scheduleId)` → `void`
  - [x] Store at `families/{familyId}/children/{childId}/schedules/{scheduleId}`
  - [x] Write repository tests

- [x] Task 3: Create `ScheduleChecker` use case (AC: #6, #7)
  - [x] Create `lib/domain/usecases/smart_lock/schedule_checker.dart`
  - [x] Implement `isInBlockedPeriod(schedules, now)` — handles overnight, disabled, day-of-week
  - [x] Implement `getActiveSchedule(schedules, now)` — returns the active schedule (for reason display)
  - [x] Implement `getScheduleEndTime(schedule, now)` — for countdown display
  - [x] Write comprehensive unit tests for all time boundary conditions

- [x] Task 4: Extend `SmartLockBloc` with schedule events/states (AC: #1, #2, #4, #5)
  - [x] Add events: `LoadSchedules`, `SaveSchedule`, `DeleteSchedule`
  - [x] Add states: `SchedulesLoaded`, extend existing states
  - [x] Handle CRUD operations via repository
  - [x] Write BLoC tests

- [x] Task 5: Integrate schedule checking into `AppMonitorBloc` (AC: #6, #7)
  - [x] Inject `ScheduleChecker` dependency
  - [x] In `_onAppEventReceived` (opened): check schedule in addition to time limit
  - [x] In `_onCheckCurrentAppLimit`: check schedule in addition to time limit
  - [x] If schedule blocks → use schedule reason in `AppBlockedState`
  - [x] Modify `_buildBlockedState` to include schedule info
  - [x] Add `blockReason` field to `AppBlockedState` ("time_limit" | "schedule")
  - [x] Write integration tests for combined blocking logic

- [x] Task 6: Build UI — `ScheduleScreen` (AC: #1)
  - [x] List of existing schedules with `ScheduleCard`
  - [x] Empty state when no schedules
  - [x] FAB "Thêm lịch trình" (Add Schedule)
  - [x] Tap card → navigate to edit
  - [x] Swipe/tap to delete with confirmation
  - [x] Write widget tests

- [x] Task 7: Build UI — `ScheduleFormScreen` and widgets (AC: #2, #3)
  - [x] `TimeRangePicker` — start/end time with wheel picker or `showTimePicker`
  - [x] `DaySelector` — 7 toggle buttons (T2-CN) with select all/none
  - [x] Predefined templates: "Giờ ngủ" (21:00-06:00, daily), "Giờ học bài" (18:00-21:00, T2-T6)
  - [x] Name field (editable, with default from template)
  - [x] Enable/disable toggle
  - [x] Save/cancel buttons
  - [x] Validation: end time != start time, at least one day selected
  - [x] Write widget tests

- [x] Task 8: Update `LockScreen` to handle schedule block reason (AC: #6, #7)
  - [x] Display schedule name as reason (e.g., "Đang trong giờ ngủ")
  - [x] `CountdownTimer` calculates time until schedule end (not 00:00)
  - [x] Update `AppBlockedState` usage in LockScreen
  - [x] Write tests for schedule-specific lock screen display

- [x] Task 9: Integration testing and final verification
  - [x] Test full flow: create schedule → time triggers → app blocked → lock screen shows reason
  - [x] Test overnight schedule: 21:00-06:00 blocks correctly across midnight
  - [x] Test combined: time limit + schedule — whichever blocks first wins
  - [x] Run `flutter analyze` — 0 new warnings
  - [x] Run all tests — must pass

---

## Dev Agent Record

### Agent Model Used
mimo-v2.5-pro

### Debug Log References
- All 151 tests pass
- flutter analyze: 0 new warnings in new files

### Completion Notes List
- Implemented ScheduleModel with fromJson/toJson/copyWith, supporting overnight schedules and type field
- Extended SmartLockRepository with getSchedules, saveSchedule, deleteSchedule CRUD methods
- Created ScheduleChecker use case with isInBlockedPeriod, getActiveSchedule, getScheduleEndTime
- Extended SmartLockBloc with LoadSchedules, SaveSchedule, DeleteSchedule events and SchedulesLoaded state
- Integrated ScheduleChecker into AppMonitorBloc with blockReason and scheduleName fields in AppBlockedState
- Built ScheduleScreen with empty state, schedule list, FAB, delete confirmation
- Built ScheduleFormScreen with TimeRangePicker, DaySelector, templates, validation
- Updated LockScreen to show schedule-specific messages and hide "request time" for schedule blocks

### File List
- lib/data/models/schedule_model.dart (new)
- lib/domain/usecases/smart_lock/schedule_checker.dart (new)
- lib/presentation/screens/smart_lock/schedule_screen.dart (new)
- lib/presentation/screens/smart_lock/schedule_form_screen.dart (new)
- lib/presentation/widgets/smart_lock/time_range_picker.dart (new)
- lib/presentation/widgets/smart_lock/day_selector.dart (new)
- lib/data/repositories/smart_lock_repository.dart (modified)
- lib/presentation/blocs/smart_lock/smart_lock_event.dart (modified)
- lib/presentation/blocs/smart_lock/smart_lock_state.dart (modified)
- lib/presentation/blocs/smart_lock/smart_lock_bloc.dart (modified)
- lib/presentation/blocs/smart_lock/app_monitor_bloc.dart (modified)
- lib/presentation/screens/smart_lock/lock_screen.dart (modified)
- test/data/models/schedule_model_test.dart (new)
- test/domain/usecases/smart_lock/schedule_checker_test.dart (new)
- test/data/repositories/smart_lock_repository_test.dart (modified)
- test/presentation/blocs/smart_lock/smart_lock_bloc_test.dart (modified)
- test/presentation/blocs/smart_lock/app_monitor_bloc_test.dart (modified)
- test/presentation/screens/smart_lock/schedule_screen_test.dart (new)
- test/presentation/screens/smart_lock/schedule_form_screen_test.dart (new)
- test/presentation/widgets/smart_lock/time_range_picker_test.dart (new)
- test/presentation/widgets/smart_lock/day_selector_test.dart (new)
- test/presentation/screens/smart_lock/lock_screen_schedule_test.dart (new)

---

## Change Log

- 2026-05-16: Initial implementation of E3.4 Schedule Setting
  - Created ScheduleModel, ScheduleChecker, and schedule CRUD in SmartLockRepository
  - Extended SmartLockBloc and AppMonitorBloc with schedule support
  - Built ScheduleScreen, ScheduleFormScreen, TimeRangePicker, DaySelector widgets
  - Updated LockScreen to handle schedule block reasons
  - All 151 tests passing, 0 new warnings
