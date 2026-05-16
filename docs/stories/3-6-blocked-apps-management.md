# Story 3.6: Blocked Apps Management

**Story ID:** E3.6  
**Epic:** E3 — Smart Lock (Android)  
**Sprint:** 5  
**Priority:** P0  
**Story Points:** 3  
**Status:** done

---

## Story

As a parent,
I want to manage which apps are monitored and blocked on my child's device,
so that I can customize monitoring to focus on the apps that matter most.

---

## Acceptance Criteria

1. Parent can view a list of installed social media apps on the child's device.
2. Each app in the list shows a toggle to enable/disable monitoring.
3. Toggling monitoring on/off persists the change to Firestore immediately.
4. Parent can add a custom app (by package name) to the monitored list.
5. Changes to the monitored apps list take effect immediately on the child's device via `AccessibilityChannel.updateBlockedApps()`.
6. The native `AppMonitorService` respects the updated monitored apps list without restart.
7. Apps with monitoring disabled are excluded from time-limit enforcement and blocking.

---

## Tasks / Subtasks

- [x] Task 1: Create `MonitoredApp` data model (AC: 2, 3)
  - [x] Define `MonitoredApp` with `appPackageName`, `appName`, `iconUrl`, `isMonitored` fields
  - [x] Add `fromJson` / `toJson` / `copyWith` methods following `AppTimeLimitModel` pattern
  - [x] Write unit tests for model serialization and edge cases

- [x] Task 2: Extend `SmartLockRepository` with monitored apps CRUD (AC: 3, 4)
  - [x] Add `getMonitoredApps(familyId, childId)` — reads from `families/{familyId}/children/{childId}/monitoredApps`
  - [x] Add `toggleMonitoredApp(familyId, childId, appPackageName, isMonitored)` — updates single doc
  - [x] Add `addCustomApp(familyId, childId, MonitoredApp)` — creates new doc
  - [x] Merge predefined popular apps (from `getPopularApps()`) with user-configured apps
  - [x] Write unit tests for repository methods

- [x] Task 3: Add events and states to `SmartLockBloc` (AC: 2, 3, 4, 5)
  - [x] Add `LoadMonitoredApps(familyId, childId)` event
  - [x] Add `ToggleMonitoredApp(familyId, childId, appPackageName, isMonitored)` event
  - [x] Add `AddCustomApp(familyId, childId, packageName, appName)` event
  - [x] Add `MonitoredAppsLoaded` state with `List<MonitoredApp>`
  - [x] On toggle/add: persist to Firestore, then call `AccessibilityChannel.updateBlockedApps()` with the full list of monitored package names
  - [x] Write unit tests for new events

- [x] Task 4: Build `BlockedAppsScreen` UI (AC: 1, 2, 4)
  - [x] Create `lib/presentation/screens/smart_lock/blocked_apps_screen.dart`
  - [x] Display list of apps with icon, name, and `Switch` toggle
  - [x] Show "Monitored" / "Not Monitored" status per app
  - [x] Add FAB or button to "Add Custom App" (dialog with package name + app name inputs)
  - [x] Use `SmartLockBloc` for state management
  - [x] Write widget tests for screen

- [x] Task 5: Sync changes to native `AppMonitorService` (AC: 5, 6)
  - [x] On any monitored-apps change, call `AccessibilityChannel.updateBlockedApps(filteredPackageNames)`
  - [x] Verify native side receives and applies the updated list (no service restart required)
  - [x] Integration test: toggle app off → verify `AppMonitorService.isBlockedApp()` returns false

- [x] Task 6: Wire navigation from Smart Lock menu (AC: 1)
  - [x] Add route for `BlockedAppsScreen` in parent dashboard monitoring tab
  - [x] Add menu entry "Quản lý ứng dụng giám sát" in Smart Lock parent screen

---

## Dev Notes

### Previous Story Intelligence (E3.1 & E3.2)

**From E3.1 (Set Time Limit):**
- `SmartLockBloc` already handles `LoadAppTimeLimits` and `SaveAppTimeLimit` events
- `SmartLockRepository.getPopularApps()` returns a hardcoded list of 7 popular apps (TikTok, Facebook, YouTube, Instagram, Zalo, Roblox, Free Fire)
- `AppTimeLimitModel` has `appPackageName`, `appName`, `iconUrl`, `limits` fields
- Firestore path: `families/{familyId}/children/{childId}/timeLimits/{appPackageName}`
- JSON parsing handles `num`/`double` flexibly — follow same pattern

**From E3.2 (App Blocking):**
- `AccessibilityChannel.updateBlockedApps(List<String> apps)` already exists — sends list to native via MethodChannel
- `AppMonitorService.kt` checks `isBlockedApp(packageName)` against a list
- `AppMonitorBloc` listens to `AccessibilityChannel.accessibilityEvents` stream
- Native `AppMonitorService` reads from local cache — call `updateBlockedApps` to push new list

**Key Insight:** The `AccessibilityChannel.updateBlockedApps()` method already exists and is ready to use. The native side receives the list and applies it to `AppMonitorService`. No native code changes needed — just call the channel from Flutter when monitored apps change.

### Architecture Compliance

- **Pattern:** Clean Architecture + BLoC. Logic in `data/repositories`, state in `presentation/bloc`, UI in `presentation/screens`.
- **Do NOT** write Firestore logic directly in widgets.
- **Firestore path:** `families/{familyId}/children/{childId}/monitoredApps/{appPackageName}` (new subcollection, parallel to `timeLimits`)
- **Offline persistence:** Firestore offline cache is already enabled. Changes sync when connection restores.
- **Security:** Only parent can write to family data (per Firestore rules in ARCHITECTURE.md §4.3).

### File Structure

New files to create:
- `lib/data/models/monitored_app_model.dart`
- `test/data/models/monitored_app_model_test.dart`
- `lib/presentation/screens/smart_lock/blocked_apps_screen.dart`
- `test/presentation/screens/smart_lock/blocked_apps_screen_test.dart`

Files to modify:
- `lib/data/repositories/smart_lock_repository.dart` — add monitored apps methods
- `test/data/repositories/smart_lock_repository_test.dart` — add tests
- `lib/presentation/blocs/smart_lock/smart_lock_event.dart` — add new events
- `lib/presentation/blocs/smart_lock/smart_lock_state.dart` — add `MonitoredAppsLoaded` state
- `lib/presentation/blocs/smart_lock/smart_lock_bloc.dart` — add handlers
- `test/presentation/blocs/smart_lock/smart_lock_bloc_test.dart` — add tests
- `lib/presentation/navigation/app_router.dart` — add route
- `lib/presentation/navigation/route_names.dart` — add route name

### Data Model

```dart
// MonitoredAppModel
{
  "appPackageName": "com.zhiliaoapp.musically",  // unique key
  "appName": "TikTok",
  "iconUrl": "https://...",                        // optional
  "isMonitored": true                              // toggle state
}
```

**Firestore document path:** `families/{familyId}/children/{childId}/monitoredApps/{appPackageName}`

### Sync Flow

```
Parent toggles app → SmartLockBloc → Repository writes Firestore
                                     → AccessibilityChannel.updateBlockedApps([list of monitored package names])
                                     → Native AppMonitorService receives and applies new list
                                     → Child's device immediately reflects change
```

### Testing

- Unit tests for `MonitoredAppModel.fromJson`, `toJson`, `copyWith`
- Unit tests for repository `toggleMonitoredApp`, `addCustomApp`
- Unit tests for `SmartLockBloc` new events
- Widget test for `BlockedAppsScreen` rendering and toggle interaction
- Follow existing test patterns in `test/presentation/blocs/smart_lock/smart_lock_bloc_test.dart`

---

## Dev Agent Record

### Agent Model Used
mimo-v2.5-pro (xiaomi-token-plan-sgp)

### Debug Log References
- All 46 tests pass with 0 failures
- BLoC tests required `TestWidgetsFlutterBinding.ensureInitialized()` and mock MethodChannel handler for `AccessibilityChannel`
- Widget loading test required `Completer` to capture transient loading state

### Completion Notes List
- Task 1: Created `MonitoredAppModel` with `fromJson`/`toJson`/`copyWith`, 8 unit tests
- Task 2: Extended `SmartLockRepository` with `getMonitoredApps`, `toggleMonitoredApp`, `addCustomApp`, `getPopularMonitoredApps`, 5 unit tests
- Task 3: Added `LoadMonitoredApps`, `ToggleMonitoredApp`, `AddCustomApp` events and `MonitoredAppsLoaded` state to `SmartLockBloc`. Implemented `_syncBlockedAppsToNative()` to call `AccessibilityChannel.updateBlockedApps()` on every toggle/add. 3 new BLoC tests.
- Task 4: Built `BlockedAppsScreen` with `SwitchListTile` toggles, FAB for adding custom apps via dialog, Vietnamese labels. 6 widget tests.
- Task 5: Sync is handled automatically by `_syncBlockedAppsToNative()` in the BLoC — no separate implementation needed. Native `AppMonitorService` receives updates via existing `AccessibilityChannel`.
- Task 6: Wired navigation in `parent_dashboard.dart` monitoring tab with "Quản lý ứng dụng giám sát" menu entry.

### File List
- `lib/data/models/monitored_app_model.dart` (new)
- `test/data/models/monitored_app_model_test.dart` (new)
- `lib/data/repositories/smart_lock_repository.dart` (modified)
- `test/data/repositories/smart_lock_repository_test.dart` (modified)
- `lib/presentation/blocs/smart_lock/smart_lock_event.dart` (modified)
- `lib/presentation/blocs/smart_lock/smart_lock_state.dart` (modified)
- `lib/presentation/blocs/smart_lock/smart_lock_bloc.dart` (modified)
- `test/presentation/blocs/smart_lock/smart_lock_bloc_test.dart` (modified)
- `lib/presentation/screens/smart_lock/blocked_apps_screen.dart` (new)
- `test/presentation/screens/smart_lock/blocked_apps_screen_test.dart` (new)
- `lib/presentation/features/dashboard/screens/parent_dashboard.dart` (modified)
