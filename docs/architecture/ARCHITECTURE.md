# Architecture Document
# KidGuardian - Đồng Hành Số

**Version:** 1.0  
**Date:** 2026-05-12  
**Status:** Draft  

---

## 1. Tổng Quan Kiến Trúc

### 1.1 Architecture Pattern
**Clean Architecture** với **BLoC Pattern** cho state management

### 1.2 Design Principles
- **Separation of Concerns:** Tách biệt UI, Business Logic, Data
- **Dependency Inversion:** Domain layer không phụ thuộc vào outer layers
- **Testability:** Dễ test từng layer độc lập
- **Scalability:** Dễ mở rộng features mới

---

## 2. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Screens   │  │   Widgets   │  │    BLoCs    │         │
│  │   (Pages)   │  │  (Reusable) │  │   (State)   │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    APPLICATION LAYER                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Use Cases  │  │  Services   │  │  Validators │         │
│  │  (Actions)  │  │  (Logic)    │  │  (Rules)    │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      DOMAIN LAYER                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Entities   │  │ Repository  │  │  Abstracts  │         │
│  │  (Models)   │  │ Interfaces  │  │  (Contracts)│         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  INFRASTRUCTURE LAYER                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Firebase   │  │   Local     │  │  Platform   │         │
│  │  (Remote)   │  │    DB       │  │  Channels   │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                PLATFORM-SPECIFIC LAYER                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                    ANDROID                           │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌───────────┐  │   │
│  │  │ Accessibility│  │ UsageStats  │  │  Device   │  │   │
│  │  │  Service    │  │    API      │  │  Admin    │  │   │
│  │  └─────────────┘  └─────────────┘  └───────────┘  │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Folder Structure

```
kidguardian/
├── android/                          # Android native code
│   └── app/src/main/kotlin/
│       └── com/kidguardian/
│           ├── accessibility/        # Accessibility Service
│           ├── deviceadmin/          # Device Admin
│           └── usagestats/           # UsageStats API
│
├── ios/                              # iOS native code (Phase 2)
│   └── Runner/
│       └── ScreenTimeBridge.swift
│
├── lib/                              # Flutter/Dart code
│   ├── main.dart                     # App entry point
│   │
│   ├── core/                         # Core utilities
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_strings.dart
│   │   │   ├── app_enums.dart
│   │   │   └── app_constants.dart
│   │   │
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   ├── light_theme.dart
│   │   │   └── dark_theme.dart
│   │   │
│   │   ├── utils/
│   │   │   ├── validators.dart
│   │   │   ├── formatters.dart
│   │   │   ├── helpers.dart
│   │   │   └── extensions.dart
│   │   │
│   │   ├── errors/
│   │   │   ├── exceptions.dart
│   │   │   └── failures.dart
│   │   │
│   │   └── di/
│   │       └── injection_container.dart
│   │
│   ├── data/                         # Data layer
│   │   ├── models/
│   │   │   ├── user_model.dart
│   │   │   ├── family_model.dart
│   │   │   ├── usage_log_model.dart
│   │   │   ├── alert_model.dart
│   │   │   └── request_model.dart
│   │   │
│   │   ├── datasources/
│   │   │   ├── remote/
│   │   │   │   ├── firebase_auth_source.dart
│   │   │   │   ├── firestore_source.dart
│   │   │   │   └── fcm_source.dart
│   │   │   │
│   │   │   └── local/
│   │   │       ├── hive_source.dart
│   │   │       └── shared_prefs_source.dart
│   │   │
│   │   └── repositories/
│   │       ├── auth_repository_impl.dart
│   │       ├── family_repository_impl.dart
│   │       ├── usage_repository_impl.dart
│   │       ├── alert_repository_impl.dart
│   │       └── request_repository_impl.dart
│   │
│   ├── domain/                       # Domain layer
│   │   ├── entities/
│   │   │   ├── user.dart
│   │   │   ├── family.dart
│   │   │   ├── usage_log.dart
│   │   │   ├── alert.dart
│   │   │   └── request.dart
│   │   │
│   │   ├── repositories/
│   │   │   ├── auth_repository.dart
│   │   │   ├── family_repository.dart
│   │   │   ├── usage_repository.dart
│   │   │   ├── alert_repository.dart
│   │   │   └── request_repository.dart
│   │   │
│   │   └── usecases/
│   │       ├── auth/
│   │       │   ├── login_usecase.dart
│   │       │   ├── register_usecase.dart
│   │       │   └── link_child_usecase.dart
│   │       │
│   │       ├── monitoring/
│   │       │   ├── get_usage_stats_usecase.dart
│   │       │   └── track_app_usage_usecase.dart
│   │       │
│   │       ├── smart_lock/
│   │       │   ├── set_time_limit_usecase.dart
│   │       │   ├── check_app_access_usecase.dart
│   │       │   └── block_app_usecase.dart
│   │       │
│   │       └── interaction/
│   │           ├── send_request_usecase.dart
│   │           └── approve_request_usecase.dart
│   │
│   ├── presentation/                 # Presentation layer
│   │   ├── navigation/
│   │   │   ├── app_router.dart
│   │   │   └── route_names.dart
│   │   │
│   │   ├── common/
│   │   │   ├── widgets/
│   │   │   │   ├── custom_button.dart
│   │   │   │   ├── custom_card.dart
│   │   │   │   ├── custom_text_field.dart
│   │   │   │   ├── loading_indicator.dart
│   │   │   │   └── error_widget.dart
│   │   │   │
│   │   │   └── dialogs/
│   │   │       ├── confirm_dialog.dart
│   │   │       └── alert_dialog.dart
│   │   │
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── login_screen.dart
│   │   │   │   │   ├── register_screen.dart
│   │   │   │   │   └── link_child_screen.dart
│   │   │   │   │
│   │   │   │   ├── widgets/
│   │   │   │   │   ├── login_form.dart
│   │   │   │   │   └── register_form.dart
│   │   │   │   │
│   │   │   │   └── bloc/
│   │   │   │       ├── auth_bloc.dart
│   │   │   │       ├── auth_event.dart
│   │   │   │       └── auth_state.dart
│   │   │   │
│   │   │   ├── dashboard/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── parent_dashboard.dart
│   │   │   │   │   └── child_dashboard.dart
│   │   │   │   │
│   │   │   │   ├── widgets/
│   │   │   │   │   ├── usage_chart.dart
│   │   │   │   │   ├── app_usage_card.dart
│   │   │   │   │   └── summary_card.dart
│   │   │   │   │
│   │   │   │   └── bloc/
│   │   │   │       ├── dashboard_bloc.dart
│   │   │   │       ├── dashboard_event.dart
│   │   │   │       └── dashboard_state.dart
│   │   │   │
│   │   │   ├── smart_lock/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── time_limit_screen.dart
│   │   │   │   │   ├── lock_screen.dart
│   │   │   │   │   └── schedule_screen.dart
│   │   │   │   │
│   │   │   │   ├── widgets/
│   │   │   │   │   ├── time_picker.dart
│   │   │   │   │   ├── app_selector.dart
│   │   │   │   │   └── blocked_screen.dart
│   │   │   │   │
│   │   │   │   └── bloc/
│   │   │   │       ├── smart_lock_bloc.dart
│   │   │   │       ├── smart_lock_event.dart
│   │   │   │       └── smart_lock_state.dart
│   │   │   │
│   │   │   ├── alerts/
│   │   │   │   ├── screens/
│   │   │   │   │   └── alerts_screen.dart
│   │   │   │   │
│   │   │   │   ├── widgets/
│   │   │   │   │   ├── alert_card.dart
│   │   │   │   │   └── keyword_chip.dart
│   │   │   │   │
│   │   │   │   └── bloc/
│   │   │   │       ├── alerts_bloc.dart
│   │   │   │       ├── alerts_event.dart
│   │   │   │       └── alerts_state.dart
│   │   │   │
│   │   │   └── interaction/
│   │   │       ├── screens/
│   │   │       │   ├── requests_screen.dart
│   │   │       │   └── request_detail_screen.dart
│   │   │       │
│   │   │       ├── widgets/
│   │   │       │   ├── request_card.dart
│   │   │       │   └── approval_buttons.dart
│   │   │       │
│   │   │       └── bloc/
│   │   │           ├── interaction_bloc.dart
│   │   │           ├── interaction_event.dart
│   │   │           └── interaction_state.dart
│   │   │
│   │   └── blocs/
│   │       └── global/
│   │           ├── theme_bloc.dart
│   │           └── connectivity_bloc.dart
│   │
│   └── platform/                     # Platform channels
│       ├── android/
│       │   ├── accessibility_channel.dart
│       │   ├── usage_stats_channel.dart
│       │   └── device_admin_channel.dart
│       │
│       └── ios/
│           └── screen_time_channel.dart
│
├── test/                             # Unit & Widget tests
│   ├── unit/
│   │   ├── usecases/
│   │   ├── repositories/
│   │   └── blocs/
│   │
│   ├── widget/
│   │   ├── screens/
│   │   └── widgets/
│   │
│   └── integration/
│       └── flows/
│
├── docs/                             # Documentation
├── assets/                           # Images, fonts, etc.
│   ├── images/
│   ├── icons/
│   └── fonts/
│
└── pubspec.yaml                      # Dependencies
```

---

## 4. Database Schema (Firestore)

### 4.1 Collections

#### users/{uid}
```json
{
  "uid": "string",
  "email": "string",
  "displayName": "string",
  "role": "parent | child",
  "familyId": "string",
  "linkedTo": "string (uid)",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "settings": {
    "notifications": true,
    "theme": "light"
  }
}
```

#### families/{familyId}
```json
{
  "familyId": "string",
  "parentUid": "string",
  "childUids": ["string"],
  "settings": {
    "dailyLimitMinutes": 120,
    "lockSchedule": [
      {
        "dayOfWeek": "monday",
        "startTime": "22:00",
        "endTime": "06:00"
      }
    ],
    "blockedApps": ["com.zhiliaoapp.musically", "com.facebook.katana"],
    "keywords": ["bạo lực", "xấu", "nguy hiểm"]
  },
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

#### usage_logs/{docId}
```json
{
  "docId": "string (auto-generated)",
  "childUid": "string",
  "familyId": "string",
  "appPackage": "string",
  "appName": "string",
  "startTime": "timestamp",
  "endTime": "timestamp",
  "durationMinutes": "number",
  "date": "string (YYYY-MM-DD)"
}
```

#### alerts/{docId}
```json
{
  "docId": "string (auto-generated)",
  "childUid": "string",
  "familyId": "string",
  "keyword": "string",
  "appPackage": "string",
  "context": "string",
  "timestamp": "timestamp",
  "status": "pending | reviewed | dismissed",
  "parentNote": "string"
}
```

#### requests/{docId}
```json
{
  "docId": "string (auto-generated)",
  "childUid": "string",
  "familyId": "string",
  "type": "extra_time | unlock",
  "appPackage": "string",
  "requestedMinutes": "number",
  "reason": "string",
  "status": "pending | approved | rejected",
  "parentResponse": "string",
  "createdAt": "timestamp",
  "respondedAt": "timestamp"
}
```

### 4.2 Indexes

| Collection | Fields | Order |
|------------|--------|-------|
| usage_logs | childUid, date | startTime desc |
| alerts | familyId, status | timestamp desc |
| requests | familyId, status | createdAt desc |

### 4.3 Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Family members can read family data
    match /families/{familyId} {
      allow read: if request.auth.uid in resource.data.parentUid || 
                     request.auth.uid in resource.data.childUids;
      allow write: if request.auth.uid == resource.data.parentUid;
    }
    
    // Usage logs - children write, parents read
    match /usage_logs/{logId} {
      allow create: if request.auth.uid == resource.data.childUid;
      allow read: if request.auth.uid in get(/databases/$(database)/documents/families/$(resource.data.familyId)).data.parentUid;
    }
  }
}
```

---

## 5. State Management (BLoC Pattern)

### 5.1 BLoC Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    Event    │────▶│    BLoC     │────▶│    State    │
│  (Input)    │     │  (Logic)    │     │  (Output)   │
└─────────────┘     └─────────────┘     └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Use Cases  │
                    │  (Actions)  │
                    └─────────────┘
```

### 5.2 Example BLoC Structure

```dart
// auth_bloc.dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  
  AuthBloc({required this.loginUseCase, required this.registerUseCase}) 
    : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }
  
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await loginUseCase(LoginParams(
      email: event.email,
      password: event.password,
    ));
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }
}
```

---

## 6. Platform Integration

### 6.1 Android - Smart Lock Implementation

#### Accessibility Service
```kotlin
// AppMonitorService.kt
class AppMonitorService : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString()
            if (packageName != null && isBlockedApp(packageName)) {
                checkAppAccess(packageName)
            }
        }
    }
    
    private fun isBlockedApp(packageName: String): Boolean {
        // Check against blocked apps list from Firebase
        return blockedApps.contains(packageName)
    }
    
    private fun checkAppAccess(packageName: String) {
        // Check time limits and show lock screen if needed
        CoroutineScope(Dispatchers.IO).launch {
            val canAccess = usageRepository.canAccessApp(packageName)
            if (!canAccess) {
                showLockScreen(packageName)
            }
        }
    }
}
```

#### Method Channel Bridge
```dart
// platform/android/accessibility_channel.dart
class AccessibilityChannel {
  static const MethodChannel _channel = 
    MethodChannel('com.kidguardian/accessibility');
  
  static Future<bool> isServiceEnabled() async {
    return await _channel.invokeMethod('isServiceEnabled');
  }
  
  static Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod('openSettings');
  }
  
  static Stream<String> get onAppBlocked {
    return _channel.receiveBroadcastStream()
      .where((event) => event['type'] == 'app_blocked')
      .map((event) => event['packageName'] as String);
  }
}
```

### 6.2 iOS - Screen Time Integration (Phase 2)

```swift
// ScreenTimeBridge.swift
import ManagedSettings
import FamilyControls

class ScreenTimeBridge: NSObject {
    private let center = AuthorizationCenter.shared
    
    func requestAuthorization() async throws {
        try await center.requestAuthorization(for: .individual)
    }
    
    func setAppLimit(appTokens: Set<ApplicationToken>, minutes: Int) {
        let store = ManagedSettingsStore()
        store.shield.applications = appTokens
    }
}
```

---

## 7. Firebase Configuration

### 7.1 Firebase Services Used

| Service | Purpose | Free Tier Limits |
|---------|---------|------------------|
| Authentication | User login/register | 10K users/month |
| Cloud Firestore | Database | 1GB storage, 50K reads/day |
| Cloud Messaging | Push notifications | Unlimited |
| Crashlytics | Error tracking | Unlimited |

### 7.2 Optimization Strategies

**Firestore Caching:**
```dart
// Enable offline persistence
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

**Query Optimization:**
```dart
// Use composite indexes
// Limit query results
// Implement pagination
```

---

## 8. Testing Strategy

### 8.1 Test Pyramid

```
        ┌─────────────┐
        │  E2E Tests  │  (Few)
        ├─────────────┤
        │ Integration │  (Some)
        │    Tests    │
        ├─────────────┤
        │  Unit Tests │  (Many)
        └─────────────┘
```

### 8.2 Test Coverage Targets

| Layer | Target |
|-------|--------|
| Use Cases | 90% |
| Repositories | 80% |
| BLoCs | 85% |
| Widgets | 70% |

### 8.3 Key Test Scenarios

1. **Authentication Flow:** Login → Link Child → Dashboard
2. **Smart Lock Flow:** Set Limit → Time Expired → Lock Screen
3. **Request Flow:** Child Request → Parent Notification → Approval
4. **Alert Flow:** Keyword Detected → Alert Created → Parent Notified

---

## 9. Security Considerations

### 9.1 Data Protection
- Firebase Authentication for secure user management
- Firestore Security Rules for data access control
- Local encryption for sensitive data (Hive)
- HTTPS for all network communication

### 9.2 Privacy Compliance
- Minimal data collection (only what's necessary)
- Parental consent mechanism
- Data retention policy (30 days for usage logs)
- Right to deletion

---

## 10. Performance Optimization

### 10.1 App Performance
- Lazy loading for screens
- Image caching
- Debounce for real-time listeners
- Pagination for lists

### 10.2 Battery Optimization
- Batch Firestore writes
- Efficient background service management
- Smart polling intervals

---

## 11. Deployment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Google Play Store                        │
│                    (Android App - Phase 1)                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Firebase Project                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │    Auth     │  │  Firestore  │  │     FCM     │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Flutter App (Android)                     │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Presentation → Application → Domain → Infrastructure│   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 12. Appendix

### 12.1 Technology Stack Summary

| Category | Technology | Version |
|----------|------------|---------|
| Framework | Flutter | 3.x |
| Language | Dart | 3.x |
| State Management | flutter_bloc | 8.x |
| Backend | Firebase | Latest |
| Local Storage | Hive | 2.x |
| Charts | fl_chart | Latest |
| Notifications | flutter_local_notifications | 15.x |

### 12.2 Useful Commands

```bash
# Run app
flutter run

# Run tests
flutter test

# Build APK
flutter build apk --release

# Analyze code
flutter analyze
```

---

**Document Owner:** Architecture Team  
**Last Updated:** 2026-05-12  
**Next Review:** 2026-05-19
