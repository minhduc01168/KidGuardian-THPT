# Story 3.8: Smart Lock Settings

**Story ID:** E3.8  
**Story Key:** 3-8-smart-lock-settings  
**Epic:** E3: Smart Lock (Android)  
**Status:** done  
**Priority:** P1  
**Sprint:** 6  
**Story Points:** 3  

---

## Story

**As a** parent,  
**I want to** configure Smart Lock settings,  
**So that** I can customize how the Smart Lock feature works for my child.

---

## Acceptance Criteria

### BDD Scenarios

**Scenario 1: Hiển thị màn hình cài đặt Smart Lock**
* **Given** phụ huynh đang ở màn hình Smart Lock của một trẻ
* **When** phụ huynh chọn "Cài đặt Smart Lock" (Smart Lock Settings)
* **Then** hệ thống hiển thị màn hình cài đặt với các tuỳ chọn:
  * Bật/tắt Smart Lock (toggle switch)
  * Giới hạn thời gian mặc định (default time limit)
  * Tuỳ chọn thông báo (notification preferences)
  * Lịch sử khoá (lock history)

**Scenario 2: Bật/tắt Smart Lock**
* **Given** phụ huynh đang ở màn hình cài đặt Smart Lock
* **When** phụ huynh bật/tắt toggle "Bật Smart Lock"
* **Then** hệ thống cập nhật trạng thái `isEnabled` vào Firestore
* **And** hiển thị thông báo "Đã bật Smart Lock" hoặc "Đã tắt Smart Lock"
* **When** Smart Lock bị tắt
* **Then** tất cả giới hạn thời gian và lịch trình tạm thời không được áp dụng

**Scenario 3: Thiết lập giới hạn thời gian mặc định**
* **Given** phụ huynh đang ở màn hình cài đặt Smart Lock
* **When** phụ huynh chọn "Giới hạn thời gian mặc định"
* **Then** hệ thống hiển thị picker chọn thời gian (ví dụ: 60 phút, 90 phút, 120 phút)
* **And** phụ huynh có thể chọn thời gian từ 15 phút đến 240 phút (bước nhảy 15 phút)
* **When** phụ huynh nhấn "Lưu"
* **Then** hệ thống lưu `defaultTimeLimit` vào Firestore
* **And** hiển thị thông báo "Đã lưu giới hạn mặc định thành công"

**Scenario 4: Cấu hình tuỳ chọn thông báo**
* **Given** phụ huynh đang ở màn hình cài đặt Smart Lock
* **When** phụ huynh chọn "Tuỳ chọn thông báo"
* **Then** hệ thống hiển thị các tuỳ chọn thông báo:
  * Thông báo khi trẻ yêu cầu thêm thời gian (toggle)
  * Thông báo khi trẻ bị khoá ứng dụng (toggle)
  * Thông báo khi trẻ sử dụng hết giới hạn (toggle)
  * Thông báo vi phạm lịch trình (toggle)
* **And** phụ huynh có thể bật/tắt từng loại thông báo
* **When** phụ huynh nhấn "Lưu"
* **Then** hệ thống lưu tuỳ chọn vào Firestore

**Scenario 5: Xem lịch sử khoá**
* **Given** phụ huynh đang ở màn hình cài đặt Smart Lock
* **When** phụ huynh chọn "Lịch sử khoá"
* **Then** hệ thống hiển thị danh sách các lần khoá ứng dụng gần đây
* **And** mỗi mục hiển thị: tên ứng dụng, lý do khoá, thời gian khoá, thời gian giải khoá
* **And** danh sách được sắp xếp theo thời gian giảm dần (mới nhất trước)

**Scenario 6: Lọc lịch sử khoá theo ngày**
* **Given** phụ huynh đang ở màn hình lịch sử khoá
* **When** phụ huynh chọn bộ lọc ngày (hôm nay, 7 ngày, 30 ngày)
* **Then** hệ thống lọc danh sách theo khoảng thời gian đã chọn
* **And** hiển thị số lượng khoá trong khoảng thời gian đó

---

## Developer Context

### Technical Requirements

**Data Model — `SmartLockSettingsModel`:**
```dart
// lib/data/models/smart_lock_settings_model.dart
class SmartLockSettingsModel extends Equatable {
  final bool isEnabled;                    // Master toggle
  final int defaultTimeLimitMinutes;       // 15-240, step 15
  final bool notifyOnTimeRequest;          // Child requests more time
  final bool notifyOnAppBlocked;           // App gets locked
  final bool notifyOnLimitReached;         // Usage limit reached
  final bool notifyOnScheduleViolation;    // Schedule violation
  final DateTime? updatedAt;               // Last update timestamp
}
```

**Data Model — `LockHistoryEntryModel`:**
```dart
// lib/data/models/lock_history_entry_model.dart
class LockHistoryEntryModel extends Equatable {
  final String id;                  // Firestore doc ID
  final String appPackageName;      // Blocked app package
  final String appName;             // Display name
  final String reason;              // "time_limit" | "schedule" | "manual"
  final String? scheduleName;       // If blocked by schedule
  final DateTime lockedAt;          // When lock was applied
  final DateTime? unlockedAt;       // When lock was removed (nullable)
  final int? durationMinutes;       // Lock duration if applicable
}
```

**Firestore Schema:**
```
families/{familyId}/children/{childId}/settings/smartLock
{
  "isEnabled": true,
  "defaultTimeLimitMinutes": 60,
  "notifyOnTimeRequest": true,
  "notifyOnAppBlocked": true,
  "notifyOnLimitReached": true,
  "notifyOnScheduleViolation": true,
  "updatedAt": "timestamp"
}

families/{familyId}/children/{childId}/lockHistory/{entryId}
{
  "id": "auto-generated",
  "appPackageName": "com.zhiliaoapp.musically",
  "appName": "TikTok",
  "reason": "time_limit",
  "scheduleName": null,
  "lockedAt": "timestamp",
  "unlockedAt": "timestamp",
  "durationMinutes": 60
}
```

**SmartLockRepository — Add settings and history methods:**
```dart
// Add to existing lib/data/repositories/smart_lock_repository.dart
Future<SmartLockSettingsModel?> getSmartLockSettings(String familyId, String childId);
Future<void> saveSmartLockSettings(String familyId, String childId, SmartLockSettingsModel settings);
Future<List<LockHistoryEntryModel>> getLockHistory(String familyId, String childId, {int limit = 50});
Future<void> addLockHistoryEntry(String familyId, String childId, LockHistoryEntryModel entry);
```

**SmartLockBloc — Add settings events/states:**
```dart
// Events
class LoadSmartLockSettings extends SmartLockEvent { ... }
class SaveSmartLockSettings extends SmartLockEvent { ... }
class LoadLockHistory extends SmartLockEvent { ... }

// States
class SmartLockSettingsLoaded extends SmartLockState { ... }
class LockHistoryLoaded extends SmartLockState { ... }
```

**AppMonitorBloc Integration:**
- Check `SmartLockSettingsModel.isEnabled` before enforcing any blocks
- If `!isEnabled` → skip all time limit and schedule checks
- Use `defaultTimeLimitMinutes` when no specific app limit is set
- Log lock events to `lockHistory` subcollection when blocking/unblocking

**UI Components:**
- `SmartLockSettingsScreen` — main settings screen with sections
- `ToggleSwitch` — reusable toggle for enable/disable and notification options
- `TimeLimitPicker` — picker for default time limit (15-240 min, step 15)
- `NotificationPreferencesSection` — grouped toggles for notification types
- `LockHistoryScreen` — list of lock events with filter chips
- `LockHistoryCard` — individual lock event display

### Architecture Compliance

* **Clean Architecture + BLoC Pattern** as established
* **Domain Layer:** `SmartLockSettingsModel`, `LockHistoryEntryModel` entities
* **Data Layer:** `SmartLockRepository` extended with settings and history CRUD
* **Presentation Layer:** `SmartLockBloc` extended with settings events/states
* **Firestore path:** `families/{familyId}/children/{childId}/settings/smartLock` (single document)
* **History path:** `families/{familyId}/children/{childId}/lockHistory/{entryId}` (subcollection)
* **Offline Support:** Firestore offline persistence already enabled
* **Security:** Only parent can write settings (Firestore security rules already enforce this)

### File Structure Expectations

**Create:**
- `lib/data/models/smart_lock_settings_model.dart`
- `lib/data/models/lock_history_entry_model.dart`
- `lib/presentation/screens/smart_lock/smart_lock_settings_screen.dart`
- `lib/presentation/screens/smart_lock/lock_history_screen.dart`
- `lib/presentation/widgets/smart_lock/notification_preferences_section.dart`
- `lib/presentation/widgets/smart_lock/lock_history_card.dart`
- `test/data/models/smart_lock_settings_model_test.dart`
- `test/data/models/lock_history_entry_model_test.dart`
- `test/presentation/screens/smart_lock/smart_lock_settings_screen_test.dart`
- `test/presentation/screens/smart_lock/lock_history_screen_test.dart`
- `test/presentation/widgets/smart_lock/notification_preferences_section_test.dart`
- `test/presentation/widgets/smart_lock/lock_history_card_test.dart`

**Modify:**
- `lib/data/repositories/smart_lock_repository.dart` — add settings and history methods
- `lib/presentation/blocs/smart_lock/smart_lock_event.dart` — add settings events
- `lib/presentation/blocs/smart_lock/smart_lock_state.dart` — add settings states
- `lib/presentation/blocs/smart_lock/smart_lock_bloc.dart` — handle settings events
- `lib/presentation/blocs/smart_lock/app_monitor_bloc.dart` — check isEnabled before blocking
- `lib/presentation/navigation/app_router.dart` — add settings routes
- `test/data/repositories/smart_lock_repository_test.dart` — add settings tests
- `test/presentation/blocs/smart_lock/smart_lock_bloc_test.dart` — add settings tests
- `test/presentation/blocs/smart_lock/app_monitor_bloc_test.dart` — add isEnabled check tests

### Dependencies

* `flutter_bloc` — state management (already in project)
* `cloud_firestore` — database (already in project)
* `equatable` — model equality (already in project)
* `intl` — date formatting for lock history (already in project)
* No new dependencies required

### Testing Requirements

* **Unit Tests:**
  - `SmartLockSettingsModel` — `fromJson`, `toJson`, `copyWith`, default values
  - `LockHistoryEntryModel` — `fromJson`, `toJson`, `copyWith`, nullable fields
* **BLoC Tests:**
  - `SmartLockBloc` — LoadSmartLockSettings, SaveSmartLockSettings, LoadLockHistory events
  - `AppMonitorBloc` — verify isEnabled=false skips blocking
* **Widget Tests:**
  - `SmartLockSettingsScreen` — renders all sections, toggle interaction
  - `LockHistoryScreen` — empty state, list display, filter chips
  - `LockHistoryCard` — displays lock event details correctly
  - `NotificationPreferencesSection` — toggle each notification type

---

## Previous Story Intelligence

### From E3.1 (Set Time Limit)
* `SmartLockRepository` stores data at `families/{familyId}/children/{childId}/` — settings follow same path pattern
* `SmartLockBloc` already has `SmartLockLoading`, `SmartLockLoaded`, `SmartLockActionSuccess`, `SmartLockError` states — extend with settings-specific states
* JSON parsing: handle `num` types flexibly (not just `int`) — apply to `SmartLockSettingsModel.fromJson`

### From E3.4 (Schedule Setting)
* `ScheduleModel` has `isEnabled` field — `SmartLockSettingsModel.isEnabled` is a master toggle that overrides all schedules
* `AppMonitorBloc` checks schedules in `_onAppEventReceived` — add `isEnabled` check before schedule checking
* Schedule blocking uses `blockReason` field — lock history should capture this

### From E3.6 (Blocked Apps Management)
* `MonitoredAppModel` has `isMonitored` per-app — `SmartLockSettingsModel.isEnabled` is global master toggle
* `AccessibilityChannel.updateBlockedApps()` — when SmartLock disabled, should send empty list or skip update

---

## Git Intelligence

* Recent commits follow conventional commit style: `feat:`, `fix:`, `refactor:`
* All Smart Lock files are in `lib/presentation/blocs/smart_lock/`, `lib/data/models/`, `lib/data/repositories/`
* Tests mirror source structure under `test/`
* `flutter analyze` must pass with 0 new warnings
* All existing tests must continue to pass

---

## Tasks / Subtasks

- [x] Task 1: Create `SmartLockSettingsModel` and unit tests (AC: #2, #3, #4)
  - [x] Create `lib/data/models/smart_lock_settings_model.dart` with `fromJson`, `toJson`, `copyWith`
  - [x] Support default values: `isEnabled: true`, `defaultTimeLimitMinutes: 60`, all notify: `true`
  - [x] Write `test/data/models/smart_lock_settings_model_test.dart` with edge cases

- [x] Task 2: Create `LockHistoryEntryModel` and unit tests (AC: #5, #6)
  - [x] Create `lib/data/models/lock_history_entry_model.dart` with `fromJson`, `toJson`, `copyWith`
  - [x] Support nullable `unlockedAt` and `scheduleName` fields
  - [x] Write `test/data/models/lock_history_entry_model_test.dart` with edge cases

- [x] Task 3: Extend `SmartLockRepository` with settings and history CRUD (AC: #2, #3, #4, #5)
  - [x] Add `getSmartLockSettings(familyId, childId)` → `SmartLockSettingsModel?`
  - [x] Add `saveSmartLockSettings(familyId, childId, settings)` → `void`
  - [x] Add `getLockHistory(familyId, childId, {limit})` → `List<LockHistoryEntryModel>`
  - [x] Add `addLockHistoryEntry(familyId, childId, entry)` → `void`
  - [x] Store settings at `families/{familyId}/children/{childId}/settings/smartLock`
  - [x] Store history at `families/{familyId}/children/{childId}/lockHistory/{entryId}`
  - [x] Write repository tests

- [x] Task 4: Extend `SmartLockBloc` with settings events/states (AC: #2, #3, #4, #5)
  - [x] Add events: `LoadSmartLockSettings`, `SaveSmartLockSettings`, `LoadLockHistory`
  - [x] Add states: `SmartLockSettingsLoaded`, `LockHistoryLoaded`
  - [x] Handle CRUD operations via repository
  - [x] Write BLoC tests

- [x] Task 5: Integrate `isEnabled` check into `AppMonitorBloc` (AC: #2)
  - [x] Load `SmartLockSettingsModel` on init
  - [x] Before enforcing blocks, check `isEnabled`
  - [x] If `!isEnabled` → skip all time limit and schedule checks
  - [x] Use `defaultTimeLimitMinutes` when no specific app limit set
  - [x] Log lock events to `lockHistory` when blocking/unblocking
  - [x] Write integration tests

- [x] Task 6: Build UI — `SmartLockSettingsScreen` (AC: #1, #2, #3, #4)
  - [x] Main settings screen with sections: Enable/Disable, Default Time Limit, Notifications, Lock History
  - [x] Toggle switch for `isEnabled` with confirmation dialog when disabling
  - [x] Time limit picker (15-240 min, step 15) with wheel picker or slider
  - [x] Navigate to `NotificationPreferencesSection` and `LockHistoryScreen`
  - [x] Write widget tests

- [x] Task 7: Build UI — `NotificationPreferencesSection` (AC: #4)
  - [x] Grouped toggles for each notification type
  - [x] Description text for each toggle
  - [x] Save button that dispatches `SaveSmartLockSettings`
  - [x] Write widget tests

- [x] Task 8: Build UI — `LockHistoryScreen` and `LockHistoryCard` (AC: #5, #6)
  - [x] List of lock events with `LockHistoryCard`
  - [x] Filter chips: Hôm nay, 7 ngày, 30 ngày
  - [x] Empty state when no history
  - [x] Each card shows: app icon/name, reason, locked/unlocked time
  - [x] Write widget tests

- [x] Task 9: Integration testing and final verification
  - [x] Test full flow: disable Smart Lock → verify apps not blocked
  - [x] Test: set default time limit → verify applied to apps without specific limit
  - [x] Test: lock event → verify logged to history
  - [x] Run `flutter analyze` — 0 new warnings
  - [x] Run all tests — must pass

---

## Dev Agent Record

### Agent Model Used
mimo-v2.5-pro (xiaomi-token-plan-sgp)

### Debug Log References
- All 212 tests pass (1 skipped was pre-existing)
- 51 new tests added for E3.8
- flutter analyze: 0 new warnings

### Completion Notes List
- Created SmartLockSettingsModel with fromJson/toJson/copyWith, supporting all notification preferences and default time limit
- Created LockHistoryEntryModel with fromJson/toJson/copyWith, supporting nullable unlockedAt and scheduleName fields
- Extended SmartLockRepository with getSmartLockSettings, saveSmartLockSettings, getLockHistory, addLockHistoryEntry CRUD methods
- Extended SmartLockBloc with LoadSmartLockSettings, SaveSmartLockSettings, LoadLockHistory events and SmartLockSettingsLoaded, LockHistoryLoaded states
- Integrated isEnabled check into AppMonitorBloc - skips all time limit and schedule checks when SmartLock is disabled
- Built SmartLockSettingsScreen with enable/disable toggle (with confirmation dialog), default time limit picker (15-240 min, step 15), notification preferences, and lock history navigation
- Built NotificationPreferencesSection with toggles for 4 notification types: time request, app blocked, limit reached, schedule violation
- Built LockHistoryScreen with filter chips (Tất cả, Hôm nay, 7 ngày, 30 ngày) and empty state
- Built LockHistoryCard with app icon, reason text, lock/unlock time display
- All text in Vietnamese as required
- Settings stored at families/{familyId}/children/{childId}/settings/smartLock
- History stored at families/{familyId}/children/{childId}/lockHistory/{entryId}

### File List
- lib/data/models/smart_lock_settings_model.dart (new)
- lib/data/models/lock_history_entry_model.dart (new)
- lib/data/repositories/smart_lock_repository.dart (modified)
- lib/presentation/blocs/smart_lock/smart_lock_event.dart (modified)
- lib/presentation/blocs/smart_lock/smart_lock_state.dart (modified)
- lib/presentation/blocs/smart_lock/smart_lock_bloc.dart (modified)
- lib/presentation/blocs/smart_lock/app_monitor_bloc.dart (modified)
- lib/presentation/screens/smart_lock/smart_lock_settings_screen.dart (new)
- lib/presentation/screens/smart_lock/lock_history_screen.dart (new)
- lib/presentation/widgets/smart_lock/notification_preferences_section.dart (new)
- lib/presentation/widgets/smart_lock/lock_history_card.dart (new)
- test/data/models/smart_lock_settings_model_test.dart (new)
- test/data/models/lock_history_entry_model_test.dart (new)
- test/presentation/blocs/smart_lock/smart_lock_bloc_test.dart (modified)
- test/presentation/screens/smart_lock/smart_lock_settings_screen_test.dart (new)
- test/presentation/screens/smart_lock/lock_history_screen_test.dart (new)
- test/presentation/widgets/smart_lock/notification_preferences_section_test.dart (new)

---

## Change Log

- 2026-05-16: Initial story spec created for E3.8 Smart Lock Settings
