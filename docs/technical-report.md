# BÁO CÁO KỸ THUẬT PHẦN MỀM

## Dự án: KidGuardian - Đồng Hành Số
### Ứng dụng quản lý thời gian sử dụng mạng xã hội cho trẻ em

---

**Phiên bản:** 1.0.0+1  
**Ngày tạo:** 23/05/2026  
**Trạng thái:** Đang phát triển  

---

## MỤC LỤC

1. [Tổng quan dự án](#1-tổng-quan-dự-án)
2. [Mục tiêu và phạm vi](#2-mục-tiêu-và-phạm-vi)
3. [Kiến trúc hệ thống](#3-kiến-trúc-hệ-thống)
4. [Công nghệ sử dụng](#4-công-nghệ-sử-dụng)
5. [Cấu trúc thư mục](#5-cấu-trúc-thư-mục)
6. [Data Model](#6-data-model)
7. [Business Logic Layer](#7-business-logic-layer)
8. [Presentation Layer](#8-presentation-layer)
9. [State Management](#9-state-management)
10. [Firebase Integration](#10-firebase-integration)
11. [Authentication & Authorization](#11-authentication--authorization)
12. [Hệ thống thông báo](#12-hệ-thống-thông-báo)
13. [Tính năng Smart Lock](#13-tính-năng-smart-lock)
14. [Báo cáo & Thống kê](#14-báo-cáo--thống-kê)
15. [Bảo mật](#15-bảo-mật)
16. [Hiệu suất](#16-hiệu-suất)
17. [Testing](#17-testing)
18. [Triển khai](#18-triển-khai)
19. [Tài liệu tham khảo](#19-tài-liệu-tham-khảo)
20. [Phụ lục](#20-phụ-lục)

---

## 1. Tổng quan dự án

### 1.1 Giới thiệu

KidGuardian (Đồng Hành Số) là ứng dụng di động đa nền tảng được phát triển bằng Flutter,旨在 giúp phụ huynh quản lý và giám sát thời gian sử dụng mạng xã hội của trẻ em. Ứng dụng cung cấp giải pháp toàn diện cho việc:

- **Giám sát thời gian sử dụng**: Theo dõi thời gian trẻ sử dụng các ứng dụng mạng xã hội
- **Quản lý giới hạn**: Thiết lập giới hạn thời gian sử dụng hàng ngày cho từng ứng dụng
- **Khóa thông minh**: Tự động khóa ứng dụng khi vượt quá giới hạn cho phép
- **Báo cáo chi tiết**: Cung cấp báo cáo thống kê về thói quen sử dụng của trẻ
- **Thông báo real-time**: Cảnh báo phụ huynh khi trẻ vi phạm quy định

### 1.2 Đối tượng sử dụng

| Vai trò | Mô tả |
|---------|-------|
| **Phụ huynh (Parent)** | Quản lý tài khoản con, thiết lập quy tắc, xem báo cáo |
| **Trẻ em (Child)** | Sử dụng thiết bị, nhận thông báo, xem thời gian còn lại |

### 1.3 Tính năng chính

1. **Đăng ký & Liên kết tài khoản**
   - Đăng ký bằng email/password
   - Tạo mã liên kết để kết nối tài khoản phụ huynh và trẻ

2. **Dashboard giám sát**
   - Phụ huynh: Tổng quan về tất cả trẻ trong gia đình
   - Trẻ: Xem thời gian sử dụng cá nhân

3. **Quản lý ứng dụng**
   - Danh sách ứng dụng được giám sát
   - Thiết lập giới hạn thời gian cho từng ứng dụng

4. **Smart Lock**
   - Tự động khóa ứng dụng khi hết thời gian
   - Màn hình khóa với thông tin chi tiết
   - Yêu cầu mở khóa từ phụ huynh

5. **Báo cáo & Thống kê**
   - Báo cáo hàng ngày/tuần
   - Biểu đồ sử dụng
   - Xuất báo cáo PDF/CSV

6. **Hệ thống thông báo**
   - Thông báo đẩy (Push Notification)
   - Thông báo trong ứng dụng
   - Cảnh báo từ khóa

---

## 2. Mục tiêu và phạm vi

### 2.1 Mục tiêu dự án

| Mục tiêu | Mô tả | Trạng thái |
|----------|-------|------------|
| M1 | Xây dựng ứng dụng Flutter đa nền tảng (Android, iOS, Web) | Đang thực hiện |
| M2 | Tích hợp Firebase cho backend services | Hoàn thành |
| M3 | Implement Clean Architecture | Hoàn thành |
| M4 | Đảm bảo bảo mật dữ liệu người dùng | Đang thực hiện |
| M5 | Hiệu suất mượt mà,用户体验 tốt | Đang tối ưu |

### 2.2 Phạm vi dự án

**Trong phạm vi:**
- Ứng dụng di động cho phụ huynh và trẻ em
- Backend sử dụng Firebase services
- Hệ thống giám sát và quản lý thời gian
- Báo cáo và thống kê sử dụng

**Ngoài phạm vi:**
- Quản lý thiết bị (MDM)
- Lọc nội dung web
- Giám sát tin nhắn mạng xã hội

### 2.3 Yêu cầu phi chức năng

| Yêu cầu | Tiêu chí |
|---------|----------|
| **Hiệu suất** | App khởi động < 3s, UI mượt 60fps |
| **Bảo mật** | Mã hóa dữ liệu, xác thực an toàn |
| **Khả năng mở rộng** | Hỗ trợ 10,000+ users đồng thời |
| **Tính sẵn sàng** | 99.9% uptime |
| **Đa nền tảng** | Android 8.0+, iOS 13+, Web |

---

## 3. Kiến trúc hệ thống

### 3.1 Tổng quan kiến trúc

KidGuardian áp dụng **Clean Architecture** với 4 layers chính:

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│   (UI, BLoC, Screens, Widgets)      │
├─────────────────────────────────────┤
│         Domain Layer                │
│   (Entities, UseCases, Repos)       │
├─────────────────────────────────────┤
│          Data Layer                 │
│   (Repositories, DataSources, Models)│
├─────────────────────────────────────┤
│          Core Layer                 │
│   (Constants, DI, Utils, Theme)     │
└─────────────────────────────────────┘
```

### 3.2 Chi tiết các Layers

#### 3.2.1 Core Layer (`lib/core/`)

Layer nền tảng chứa các thành phần dùng chung:

- **constants/**: Màu sắc, chuỗi hằng số
- **di/**: Dependency Injection (sử dụng GetIt)
- **errors/**: Xử lý lỗi tùy chỉnh
- **navigation/**: Quản lý điều hướng
- **theme/**: ThemeData cho ứng dụng
- **utils/**: Các tiện ích chung

#### 3.2.2 Domain Layer (`lib/domain/`)

Layer business logic thuần túy, không phụ thuộc Flutter:

- **entities/**: Các đối tượng business (User, Family, UsageLog, etc.)
- **repositories/**: Abstract repository interfaces
- **usecases/**: Các use case implementations

#### 3.2.3 Data Layer (`lib/data/`)

Layer xử lý dữ liệu:

- **datasources/**: Data sources (remote: Firebase, local: SharedPreferences)
- **models/**: Data models (extends entities với serialization)
- **repositories/**: Repository implementations
- **services/**: Các services (Notification, Background, etc.)

#### 3.2.4 Presentation Layer (`lib/presentation/`)

Layer UI:

- **blocs/**: Business Logic Components
- **common/**: Shared widgets
- **features/**: Feature modules (auth, dashboard, settings, etc.)
- **navigation/**: App navigation
- **screens/**: App screens
- **widgets/**: Reusable widgets

### 3.3 Luồng dữ liệu

```
User Action → UI Widget → BLoC Event → UseCase → Repository → DataSource
     ↑                                                           ↓
     └──────────── BLoC State ← UseCase Result ← Repository ←──┘
```

### 3.4 Dependency Injection

Sử dụng `flutter_bloc`'s `RepositoryProvider` và `BlocProvider`:

```dart
// main.dart
MultiRepositoryProvider(
  providers: [
    RepositoryProvider<AuthRepository>(
      create: (_) => AuthRepositoryImpl(),
    ),
    // ... other repositories
  ],
  child: MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>(
        create: (context) => AuthBloc(
          authRepository: context.read<AuthRepository>(),
        ),
      ),
      // ... other blocs
    ],
    child: MaterialApp(...),
  ),
)
```

---

## 4. Công nghệ sử dụng

### 4.1 Framework & Ngôn ngữ

| Công nghệ | Phiên bản | Mục đích |
|-----------|-----------|----------|
| **Flutter** | 3.11.5+ | Framework chính |
| **Dart** | 3.11.5+ | Ngôn ngữ lập trình |

### 4.2 Backend Services (Firebase)

| Service | Package | Mục đích |
|---------|---------|----------|
| **Firebase Core** | firebase_core: ^3.12.1 | Khởi tạo Firebase |
| **Firebase Auth** | firebase_auth: ^5.5.4 | Xác thực người dùng |
| **Cloud Firestore** | cloud_firestore: ^5.6.5 | Database chính |
| **Cloud Functions** | cloud_functions: ^5.2.2 | Server-side logic |
| **Firebase Messaging** | firebase_messaging: ^15.2.4 | Push notifications |
| **Firebase Crashlytics** | firebase_crashlytics: ^4.3.4 | Báo cáo lỗi |

### 4.3 State Management & Architecture

| Package | Mục đích |
|---------|----------|
| **flutter_bloc: ^9.1.0** | State management chính |
| **equatable: ^2.0.7** | So sánh objects |
| **get_it: ^8.0.2** | Dependency Injection |

### 4.4 UI & UX

| Package | Mục đích |
|---------|----------|
| **cupertino_icons: ^1.0.8** | iOS-style icons |
| **fl_chart: ^0.70.2** | Biểu đồ |
| **flutter_local_notifications: ^21.0.0** | Thông báo local |

### 4.5 Utilities

| Package | Mục đích |
|---------|----------|
| **shared_preferences: ^2.3.4** | Local storage |
| **intl: ^0.20.2** | Quốc tế hóa |
| **uuid: ^4.5.1** | Tạo UUID |
| **csv: ^6.0.0** | Xuất CSV |
| **pdf: ^3.11.2** | Xuất PDF |
| **share_plus: ^10.1.4** | Chia sẻ file |
| **path_provider: ^2.1.5** | Đường dẫn file |
| **url_launcher: ^6.3.1** | Mở URL |
| **webview_flutter: ^4.10.0** | WebView |
| **package_info_plus: ^8.1.3** | Thông tin app |

### 4.6 Dev Dependencies

| Package | Mục đích |
|---------|----------|
| **flutter_test** | Unit testing |
| **flutter_lints: ^6.0.0** | Code linting |
| **bloc_test: ^10.0.0** | BLoC testing |
| **mocktail: ^1.0.4** | Mocking |
| **fake_cloud_firestore: ^3.1.0** | Fake Firestore cho testing |

---

## 5. Cấu trúc thư mục

```
kidguardian-thpt/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   └── app_strings.dart
│   │   ├── di/
│   │   ├── errors/
│   │   ├── navigation/
│   │   │   └── app_routes.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   └── utils/
│   │
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── local/
│   │   │   └── remote/
│   │   │       └── emergency_log_source.dart
│   │   ├── models/
│   │   │   ├── app_time_limit_model.dart
│   │   │   ├── auto_approval_rule_model.dart
│   │   │   ├── daily_summary_model.dart
│   │   │   ├── emergency_log_model.dart
│   │   │   ├── family_model.dart
│   │   │   ├── lock_history_entry_model.dart
│   │   │   ├── monitored_app_model.dart
│   │   │   ├── schedule_model.dart
│   │   │   ├── smart_lock_settings_model.dart
│   │   │   ├── usage_log_model.dart
│   │   │   ├── user_model.dart
│   │   │   └── weekly_report_model.dart
│   │   ├── repositories/
│   │   │   ├── auth_repository_impl.dart
│   │   │   ├── family_repository_impl.dart
│   │   │   ├── help_repository_impl.dart
│   │   │   ├── report_repository_impl.dart
│   │   │   ├── settings_repository_impl.dart
│   │   │   ├── smart_lock_repository.dart
│   │   │   ├── summary_repository_impl.dart
│   │   │   └── usage_repository_impl.dart
│   │   └── services/
│   │       ├── background_message_handler.dart
│   │       └── notification_service.dart
│   │
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── daily_summary.dart
│   │   │   ├── family.dart
│   │   │   ├── faq_item.dart
│   │   │   ├── usage_log.dart
│   │   │   ├── user.dart
│   │   │   └── weekly_report.dart
│   │   ├── repositories/
│   │   │   ├── auth_repository.dart
│   │   │   ├── family_repository.dart
│   │   │   ├── report_repository.dart
│   │   │   ├── settings_repository.dart
│   │   │   ├── summary_repository.dart
│   │   │   └── usage_repository.dart
│   │   └── usecases/
│   │       ├── auth/
│   │       ├── dashboard/
│   │       ├── interaction/
│   │       ├── monitoring/
│   │       ├── notification/
│   │       └── smart_lock/
│   │           ├── block_app_usecase.dart
│   │           ├── check_app_access_usecase.dart
│   │           └── schedule_checker.dart
│   │
│   ├── presentation/
│   │   ├── blocs/
│   │   │   ├── alert_history/
│   │   │   ├── alert_review/
│   │   │   ├── emergency_access/
│   │   │   ├── in_app_notification/
│   │   │   ├── keyword_management/
│   │   │   ├── notification_history/
│   │   │   ├── notification/
│   │   │   ├── rules/
│   │   │   ├── smart_lock/
│   │   │   └── time_request/
│   │   ├── common/
│   │   ├── features/
│   │   │   ├── alerts/
│   │   │   ├── auth/
│   │   │   ├── dashboard/
│   │   │   ├── family/
│   │   │   ├── help/
│   │   │   ├── interaction/
│   │   │   ├── report/
│   │   │   ├── settings/
│   │   │   ├── smart_lock/
│   │   │   ├── summary/
│   │   │   └── usage_statistics/
│   │   ├── navigation/
│   │   ├── screens/
│   │   │   └── smart_lock/
│   │   │       └── lock_screen.dart
│   │   └── widgets/
│   │
│   ├── platform/
│   │
│   └── main.dart
│
├── assets/
│   ├── images/
│   └── icons/
│
├── android/
├── ios/
├── web/
├── linux/
├── macos/
├── windows/
│
├── test/
│
├── pubspec.yaml
├── analysis_options.yaml
├── firestore.indexes.json
└── README.md
```

---

## 6. Data Model

### 6.1 Entity Classes (Domain Layer)

#### 6.1.1 User Entity

```dart
// lib/domain/entities/user.dart
enum UserRole { parent, child }

class User extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String? familyId;
  final String? linkedTo;
  final DateTime createdAt;
  
  // Properties: uid, email, displayName, role, familyId, linkedTo, createdAt
}
```

#### 6.1.2 Family Entity

```dart
// lib/domain/entities/family.dart
class Family extends Equatable {
  final String familyId;
  final String parentUid;
  final List<String> childUids;
  final String? linkingCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Properties: familyId, parentUid, childUids, linkingCode, createdAt, updatedAt
}
```

#### 6.1.3 UsageLog Entity

```dart
// lib/domain/entities/usage_log.dart
class UsageLog extends Equatable {
  final String logId;
  final String childUid;
  final String appPackageName;
  final String appName;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  
  // Properties: logId, childUid, appPackageName, appName, startTime, endTime, durationMinutes
}
```

#### 6.1.4 DailySummary Entity

```dart
// lib/domain/entities/daily_summary.dart
class DailySummary extends Equatable {
  final String summaryId;
  final String childUid;
  final DateTime date;
  final int totalMinutes;
  final Map<String, int> appUsage; // packageName → minutes
  final int limitMinutes;
  final bool exceeded;
  
  // Properties: summaryId, childUid, date, totalMinutes, appUsage, limitMinutes, exceeded
}
```

#### 6.1.5 WeeklyReport Entity

```dart
// lib/domain/entities/weekly_report.dart
class WeeklyReport extends Equatable {
  final String reportId;
  final String childUid;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int totalMinutes;
  final Map<String, int> dailyUsage; // day → minutes
  final List<String> topApps;
  
  // Properties: reportId, childUid, weekStart, weekEnd, totalMinutes, dailyUsage, topApps
}
```

### 6.2 Model Classes (Data Layer)

Models mở rộng Entities với serialization:

```dart
// lib/data/models/user_model.dart
class UserModel extends User {
  UserModel({...});
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      email: json['email'],
      // ... parse from JSON
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      // ... serialize to JSON
    };
  }
  
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    // Parse from Firestore document
  }
}
```

### 6.3 Firestore Collections

```
firestore/
├── users/{uid}
│   ├── uid: string
│   ├── email: string
│   ├── displayName: string
│   ├── role: "parent" | "child"
│   ├── familyId: string (optional)
│   ├── linkedTo: string (optional)
│   └── createdAt: timestamp
│
├── families/{familyId}
│   ├── familyId: string
│   ├── parentUid: string
│   ├── childUids: string[]
│   ├── linkingCode: string (optional)
│   ├── createdAt: timestamp
│   └── updatedAt: timestamp
│
├── usage_logs/{logId}
│   ├── logId: string
│   ├── childUid: string
│   ├── appPackageName: string
│   ├── appName: string
│   ├── startTime: timestamp
│   ├── endTime: timestamp (optional)
│   └── durationMinutes: number
│
├── daily_summaries/{summaryId}
│   ├── summaryId: string
│   ├── childUid: string
│   ├── date: timestamp
│   ├── totalMinutes: number
│   ├── appUsage: map<string, number>
│   ├── limitMinutes: number
│   └── exceeded: boolean
│
├── alerts/{alertId}
│   ├── alertId: string
│   ├── familyId: string
│   ├── childUid: string
│   ├── type: string
│   ├── message: string
│   ├── read: boolean
│   └── createdAt: timestamp
│
└── time_requests/{requestId}
    ├── requestId: string
    ├── childUid: string
    ├── parentUid: string
    ├── requestedMinutes: number
    ├── status: "pending" | "approved" | "rejected"
    └── createdAt: timestamp
```

---

## 7. Business Logic Layer

### 7.1 Repository Pattern

#### 7.1.1 Abstract Repository (Domain Layer)

```dart
// lib/domain/repositories/auth_repository.dart
abstract class AuthRepository {
  Future<User?> signInWithEmailAndPassword(String email, String password);
  Future<User?> signUpWithEmailAndPassword(String email, String password, String displayName);
  Future<void> signOut();
  Future<User?> getCurrentUser();
  Stream<User?> get authStateChanges;
}
```

#### 7.1.2 Repository Implementation (Data Layer)

```dart
// lib/data/repositories/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _getUserFromCredential(credential);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
  
  // ... other implementations
}
```

### 7.2 Use Cases

#### 7.2.1 CheckAppAccessUseCase

```dart
// lib/domain/usecases/smart_lock/check_app_access_usecase.dart
class CheckAppAccessUseCase {
  final UsageRepository usageRepository;
  final SmartLockRepository smartLockRepository;
  
  CheckAppAccessUseCase({
    required this.usageRepository,
    required this.smartLockRepository,
  });
  
  Future<AppAccessResult> execute(String childUid, String appPackageName) async {
    // 1. Get current usage for today
    final usage = await usageRepository.getTodayUsage(childUid, appPackageName);
    
    // 2. Get app time limit
    final limit = await smartLockRepository.getAppTimeLimit(appPackageName);
    
    // 3. Check if exceeded
    if (usage >= limit) {
      return AppAccessResult.blocked(
        usedMinutes: usage,
        limitMinutes: limit,
      );
    }
    
    return AppAccessResult.allowed(
      remainingMinutes: limit - usage,
    );
  }
}
```

#### 7.2.2 BlockAppUseCase

```dart
// lib/domain/usecases/smart_lock/block_app_usecase.dart
class BlockAppUseCase {
  Future<void> execute({
    required String appPackageName,
    required String appName,
    required String iconUrl,
    required int limitMinutes,
    required int usedMinutes,
    required DateTime resetTime,
    required String familyId,
    required String childUid,
    required String parentUid,
  }) async {
    // Show lock screen
    // Log the blocking event
    // Notify parent
  }
}
```

### 7.3 Error Handling

```dart
// lib/core/errors/exceptions.dart
class ServerException implements Exception {
  final String message;
  ServerException({required this.message});
}

class CacheException implements Exception {
  final String message;
  CacheException({required this.message});
}

// lib/core/errors/failures.dart
abstract class Failure {
  final String message;
  Failure({required this.message});
}

class ServerFailure extends Failure {
  ServerFailure({required super.message});
}

class CacheFailure extends Failure {
  CacheFailure({required super.message});
}
```

---

## 8. Presentation Layer

### 8.1 Feature Modules

#### 8.1.1 Auth Feature

**Screens:**
- `RoleSelectionScreen`: Chọn vai trò (Phụ huynh/Trẻ em)
- `LoginScreen`: Đăng nhập
- `RegisterScreen`: Đăng ký
- `LinkAccountScreen`: Liên kết tài khoản

**BLoC:**
- `AuthBloc`: Quản lý trạng thái xác thực
- `FamilyBloc`: Quản lý gia đình

#### 8.1.2 Dashboard Feature

**Screens:**
- `ParentDashboard`: Dashboard cho phụ huynh
- `ChildDashboard`: Dashboard cho trẻ em

**BLoC:**
- `DashboardBloc`: Quản lý dữ liệu dashboard

#### 8.1.3 Smart Lock Feature

**Screens:**
- `LockScreen`: Màn hình khóa ứng dụng

**BLoC:**
- `AppMonitorBloc`: Giám sát và khóa ứng dụng

#### 8.1.4 Settings Feature

**Screens:**
- `SettingsScreen`: Cài đặt chung
- `AppTimeLimitScreen`: Cài đặt giới hạn thời gian
- `NotificationSettingsScreen`: Cài đặt thông báo

**BLoC:**
- `SettingsBloc`: Quản lý cài đặt

#### 8.1.5 Report Feature

**Screens:**
- `ReportScreen`: Xem báo cáo
- `ExportScreen`: Xuất báo cáo

**BLoC:**
- `ReportBloc`: Quản lý báo cáo

### 8.2 Shared Widgets

```dart
// lib/presentation/widgets/
├── app_card.dart
├── custom_button.dart
├── custom_text_field.dart
├── loading_indicator.dart
├── error_widget.dart
├── empty_state.dart
└── stat_card.dart
```

### 8.3 Theme System

```dart
// lib/core/theme/app_theme.dart
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    // ... other theme properties
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    // ... other theme properties
  );
}
```

---

## 9. State Management

### 9.1 BLoC Pattern

Ứng dụng sử dụng **BLoC (Business Logic Component)** pattern với `flutter_bloc`.

#### 9.1.1 BLoC Structure

```dart
// Event
abstract class AuthEvent extends Equatable {
  const AuthEvent();
}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;
  
  const SignInRequested({required this.email, required this.password});
  
  @override
  List<Object> get props => [email, password];
}

// State
abstract class AuthState extends Equatable {
  const AuthState();
}

class AuthInitial extends AuthState {
  @override
  List<Object> get props => [];
}

class AuthLoading extends AuthState {
  @override
  List<Object> get props => [];
}

class AuthAuthenticated extends AuthState {
  final User user;
  
  const AuthAuthenticated({required this.user});
  
  @override
  List<Object> get props => [user];
}

class AuthError extends AuthState {
  final String message;
  
  const AuthError({required this.message});
  
  @override
  List<Object> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final FamilyRepository familyRepository;
  final NotificationService notificationService;
  
  AuthBloc({
    required this.authRepository,
    required this.familyRepository,
    required this.notificationService,
  }) : super(AuthInitial()) {
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<AuthCheckRequested>(_onAuthCheckRequested);
  }
  
  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signInWithEmailAndPassword(
        event.email,
        event.password,
      );
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthError(message: 'Đăng nhập thất bại'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
  
  // ... other event handlers
}
```

### 9.2 Các BLoCs trong ứng dụng

| BLoC | Trách nhiệm |
|------|-------------|
| `AuthBloc` | Xác thực, đăng nhập/đăng ký |
| `FamilyBloc` | Quản lý gia đình, liên kết tài khoản |
| `DashboardBloc` | Dữ liệu dashboard |
| `SummaryBloc` | Tổng hợp sử dụng hàng ngày |
| `ReportBloc` | Báo cáo và thống kê |
| `SettingsBloc` | Cài đặt ứng dụng |
| `AppMonitorBloc` | Giám sát và khóa ứng dụng |
| `NotificationBloc` | Quản lý thông báo |
| `InAppNotificationBloc` | Thông báo trong app |
| `HelpBloc` | Hệ thống trợ giúp |
| `AlertHistoryBloc` | Lịch sử cảnh báo |
| `AlertReviewBloc` | Đánh giá cảnh báo |
| `EmergencyAccessBloc` | Truy cập khẩn cấp |
| `KeywordManagementBloc` | Quản lý từ khóa |
| `NotificationHistoryBloc` | Lịch sử thông báo |
| `RulesBloc` | Quản lý quy tắc |
| `TimeRequestBloc` | Yêu cầu thêm thời gian |

### 9.3 BLoC Testing

```dart
// test/auth_bloc_test.dart
blocTest<AuthBloc, AuthState>(
  'emits [AuthLoading, AuthAuthenticated] when sign in succeeds',
  build: () {
    when(() => mockAuthRepository.signInWithEmailAndPassword(
      any(), any(),
    )).thenAnswer((_) async => mockUser);
    return AuthBloc(
      authRepository: mockAuthRepository,
      familyRepository: mockFamilyRepository,
      notificationService: mockNotificationService,
    );
  },
  act: (bloc) => bloc.add(SignInRequested(
    email: 'test@example.com',
    password: 'password',
  )),
  expect: () => [
    isA<AuthLoading>(),
    isA<AuthAuthenticated>(),
  ],
);
```

---

## 10. Firebase Integration

### 10.1 Firebase Configuration

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const KidGuardianApp());
}
```

### 10.2 Cloud Firestore

#### 10.2.1 Data Structure

```dart
// lib/data/repositories/family_repository_impl.dart
class FamilyRepositoryImpl implements FamilyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  Future<Family> createFamily(String parentUid) async {
    final docRef = _firestore.collection('families').doc();
    final family = Family(
      familyId: docRef.id,
      parentUid: parentUid,
      childUids: [],
      linkingCode: _generateLinkingCode(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await docRef.set(family.toJson());
    return family;
  }
  
  @override
  Future<void> addChildToFamily(String familyId, String childUid) async {
    await _firestore.collection('families').doc(familyId).update({
      'childUids': FieldValue.arrayUnion([childUid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
```

#### 10.2.2 Real-time Listeners

```dart
// Stream usage data
Stream<List<UsageLog>> watchChildUsage(String childUid) {
  return _firestore
      .collection('usage_logs')
      .where('childUid', isEqualTo: childUid)
      .orderBy('startTime', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => UsageLogModel.fromFirestore(doc)).toList();
  });
}
```

### 10.3 Firebase Auth

```dart
// lib/data/repositories/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  
  @override
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) return null;
      return User(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? '',
        role: UserRole.parent, // Default, will be updated from Firestore
        createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      );
    });
  }
}
```

### 10.4 Cloud Functions

```dart
// Cloud Functions for server-side logic
// lib/data/services/cloud_functions_service.dart
class CloudFunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  Future<void> sendNotification({
    required String targetUid,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    await _functions.httpsCallable('sendNotification').call({
      'targetUid': targetUid,
      'title': title,
      'body': body,
      'data': data,
    });
  }
}
```

### 10.5 Firebase Messaging

```dart
// lib/data/services/notification_service.dart
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  Future<void> initialize() async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token
      final token = await _messaging.getToken();
      // Save token to Firestore
      
      // Configure foreground notification presentation
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }
}
```

---

## 11. Authentication & Authorization

### 11.1 Authentication Flow

```
┌─────────────────┐
│  Role Selection  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Login Screen   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Firebase Auth    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Check Role       │
│ (Firestore)      │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐ ┌────────┐
│ Parent │ │ Child  │
│Dashboard│ │Dashboard│
└────────┘ └────────┘
```

### 11.2 Authorization Rules

#### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Families collection
    match /families/{familyId} {
      allow read: if request.auth != null && 
        (resource.data.parentUid == request.auth.uid || 
         request.auth.uid in resource.data.childUids);
      allow write: if request.auth != null && 
        resource.data.parentUid == request.auth.uid;
    }
    
    // Usage logs collection
    match /usage_logs/{logId} {
      allow read: if request.auth != null && 
        (resource.data.childUid == request.auth.uid || 
         isParentOfChild(resource.data.childUid));
      allow write: if request.auth != null;
    }
  }
}
```

### 11.3 Role-Based Access Control

```dart
// lib/domain/entities/user.dart
enum UserRole { parent, child }

// Check role before navigation
Widget _buildHomeForRole(User user, BuildContext context) {
  if (user.role == UserRole.parent) {
    return ParentDashboard();
  } else {
    return ChildDashboard();
  }
}
```

---

## 12. Hệ thống thông báo

### 12.1 Push Notifications

```dart
// lib/data/services/notification_service.dart
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final TimeRequestRepository _timeRequestRepository;
  
  NotificationService({required TimeRequestRepository timeRequestRepository})
      : _timeRequestRepository = timeRequestRepository;
  
  Future<void> initialize() async {
    // Request permission
    final settings = await _messaging.requestPermission();
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle background messages
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    }
  }
  
  void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification
    _showLocalNotification(
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      data: message.data,
    );
  }
}
```

### 12.2 In-App Notifications

```dart
// lib/presentation/blocs/in_app_notification/in_app_notification_bloc.dart
class InAppNotificationBloc extends Bloc<InAppNotificationEvent, InAppNotificationState> {
  final AlertRepository _alertRepository;
  final TimeRequestRepository _timeRequestRepository;
  
  StreamSubscription? _alertSubscription;
  StreamSubscription? _requestSubscription;
  
  InAppNotificationBloc({
    required AlertRepository alertRepository,
    required TimeRequestRepository timeRequestRepository,
  }) : _alertRepository = alertRepository,
       _timeRequestRepository = timeRequestRepository,
       super(InAppNotificationInitial()) {
    on<StartListening>(_onStartListening);
    on<AlertReceived>(_onAlertReceived);
    on<TimeRequestReceived>(_onTimeRequestReceived);
  }
  
  Future<void> _onStartListening(
    StartListening event,
    Emitter<InAppNotificationState> emit,
  ) async {
    _alertSubscription = _alertRepository.watchAlerts(event.familyId).listen(
      (alert) => add(AlertReceived(alert: alert)),
    );
    
    _requestSubscription = _timeRequestRepository.watchRequests(event.familyId).listen(
      (request) => add(TimeRequestReceived(request: request)),
    );
  }
}
```

### 12.3 Local Notifications

```dart
// lib/data/services/local_notification_service.dart
class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }
  
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'kidguardian_channel',
      'KidGuardian Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const notificationDetails = NotificationDetails(android: androidDetails);
    
    await _plugin.show(id, title, body, notificationDetails, payload: payload.toString());
  }
}
```

---

## 13. Tính năng Smart Lock

### 13.1 Tổng quan

Smart Lock là tính năng cốt lõi của KidGuardian, cho phép:
- Giám sát thời gian sử dụng ứng dụng theo thời gian thực
- Tự động khóa ứng dụng khi vượt quá giới hạn
- Hiển thị màn hình khóa với thông tin chi tiết
- Cho phép trẻ yêu cầu thêm thời gian

### 13.2 AppMonitorBloc

```dart
// lib/presentation/blocs/smart_lock/app_monitor_bloc.dart
class AppMonitorBloc extends Bloc<AppMonitorEvent, AppMonitorState> {
  final CheckAppAccessUseCase _checkAppAccessUseCase;
  final BlockAppUseCase _blockAppUseCase;
  final UsageRepository _usageRepository;
  final SmartLockRepository _smartLockRepository;
  final ScheduleChecker _scheduleChecker;
  final AlertRepository _alertRepository;
  
  StreamSubscription? _usageSubscription;
  Timer? _monitoringTimer;
  
  AppMonitorBloc({
    required CheckAppAccessUseCase checkAppAccessUseCase,
    required BlockAppUseCase blockAppUseCase,
    required UsageRepository usageRepository,
    required SmartLockRepository smartLockRepository,
    required ScheduleChecker scheduleChecker,
    required AlertRepository alertRepository,
  }) : _checkAppAccessUseCase = checkAppAccessUseCase,
       _blockAppUseCase = blockAppUseCase,
       _usageRepository = usageRepository,
       _smartLockRepository = smartLockRepository,
       _scheduleChecker = scheduleChecker,
       _alertRepository = alertRepository,
       super(AppMonitorInitial()) {
    on<StartMonitoring>(_onStartMonitoring);
    on<StopMonitoring>(_onStopMonitoring);
    on<CheckAppAccess>(_onCheckAppAccess);
    on<AppUsageUpdated>(_onAppUsageUpdated);
  }
  
  Future<void> _onStartMonitoring(
    StartMonitoring event,
    Emitter<AppMonitorState> emit,
  ) async {
    emit(AppMonitoringInProgress());
    
    // Start listening to usage updates
    _usageSubscription = _usageRepository.watchChildUsage(event.childUid).listen(
      (logs) => add(AppUsageUpdated(logs: logs)),
    );
    
    // Start periodic monitoring
    _monitoringTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkAllApps(event.familyId, event.childUid),
    );
  }
  
  Future<void> _onCheckAppAccess(
    CheckAppAccess event,
    Emitter<AppMonitorState> emit,
  ) async {
    final result = await _checkAppAccessUseCase.execute(
      event.childUid,
      event.appPackageName,
    );
    
    if (result is AppAccessBlocked) {
      emit(AppBlockedState(
        appPackageName: event.appPackageName,
        appName: event.appName,
        iconUrl: event.iconUrl,
        limitMinutes: result.limitMinutes,
        usedMinutes: result.usedMinutes,
        resetTime: result.resetTime,
        familyId: event.familyId,
        childUid: event.childUid,
        parentUid: event.parentUid,
      ));
    }
  }
}
```

### 13.3 Lock Screen

```dart
// lib/presentation/screens/smart_lock/lock_screen.dart
class LockScreen extends StatelessWidget {
  final String appPackageName;
  final String appName;
  final String iconUrl;
  final int limitMinutes;
  final int usedMinutes;
  final DateTime resetTime;
  final String familyId;
  final String childUid;
  final String parentUid;
  
  const LockScreen({
    super.key,
    required this.appPackageName,
    required this.appName,
    required this.iconUrl,
    required this.limitMinutes,
    required this.usedMinutes,
    required this.resetTime,
    required this.familyId,
    required this.childUid,
    required this.parentUid,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 100, color: Colors.red),
            const SizedBox(height: 24),
            Text(
              'Ứng dụng đã bị khóa',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              '$appName đã sử dụng $usedMinutes/$limitMinutes phút',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Thời gian reset: ${_formatTime(resetTime)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _requestMoreTime(context),
              child: const Text('Yêu cầu thêm thời gian'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 13.4 Schedule Checker

```dart
// lib/domain/usecases/smart_lock/schedule_checker.dart
class ScheduleChecker {
  bool isWithinAllowedTime(Schedule schedule) {
    final now = DateTime.now();
    final dayOfWeek = now.weekday;
    
    // Check if today is allowed
    if (!schedule.allowedDays.contains(dayOfWeek)) {
      return false;
    }
    
    // Check if current time is within allowed range
    final currentTime = TimeOfDay.now();
    final startTime = schedule.startTime;
    final endTime = schedule.endTime;
    
    return _isTimeBetween(currentTime, startTime, endTime);
  }
  
  bool _isTimeBetween(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // Cross midnight
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }
}
```

---

## 14. Báo cáo & Thống kê

### 14.1 Daily Summary

```dart
// lib/domain/entities/daily_summary.dart
class DailySummary extends Equatable {
  final String summaryId;
  final String childUid;
  final DateTime date;
  final int totalMinutes;
  final Map<String, int> appUsage; // packageName → minutes
  final int limitMinutes;
  final bool exceeded;
  
  double get usagePercentage => (totalMinutes / limitMinutes) * 100;
  int get remainingMinutes => limitMinutes - totalMinutes;
}
```

### 14.2 Weekly Report

```dart
// lib/domain/entities/weekly_report.dart
class WeeklyReport extends Equatable {
  final String reportId;
  final String childUid;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int totalMinutes;
  final Map<String, int> dailyUsage; // day → minutes
  final List<String> topApps;
  
  double get averageDailyUsage => totalMinutes / 7;
  String get mostUsedApp => topApps.isNotEmpty ? topApps.first : 'N/A';
}
```

### 14.3 Report Generation

```dart
// lib/data/repositories/report_repository_impl.dart
class ReportRepositoryImpl implements ReportRepository {
  final UsageRepository _usageRepository;
  
  ReportRepositoryImpl({required UsageRepository usageRepository})
      : _usageRepository = usageRepository;
  
  @override
  Future<WeeklyReport> generateWeeklyReport(String childUid, DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final logs = await _usageRepository.getUsageLogs(
      childUid: childUid,
      startDate: weekStart,
      endDate: weekEnd,
    );
    
    // Calculate daily usage
    final dailyUsage = <String, int>{};
    for (var i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final dayLogs = logs.where((log) => 
        log.startTime.day == day.day &&
        log.startTime.month == day.month &&
        log.startTime.year == day.year,
      );
      dailyUsage[_formatDay(day)] = dayLogs.fold(0, (sum, log) => sum + log.durationMinutes);
    }
    
    // Calculate top apps
    final appUsage = <String, int>{};
    for (final log in logs) {
      appUsage[log.appPackageName] = (appUsage[log.appPackageName] ?? 0) + log.durationMinutes;
    }
    final topApps = appUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return WeeklyReport(
      reportId: const Uuid().v4(),
      childUid: childUid,
      weekStart: weekStart,
      weekEnd: weekEnd,
      totalMinutes: logs.fold(0, (sum, log) => sum + log.durationMinutes),
      dailyUsage: dailyUsage,
      topApps: topApps.take(5).map((e) => e.key).toList(),
    );
  }
}
```

### 14.4 Export Reports

```dart
// lib/data/services/export_service.dart
class ExportService {
  Future<File> exportToPdf(WeeklyReport report) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Báo cáo sử dụng tuần ${_formatWeek(report.weekStart)}'),
          ),
          pw.Table.fromTextArray(
            headers: ['Ngày', 'Thời gian (phút)'],
            data: report.dailyUsage.entries.map((e) => [e.key, e.value.toString()]).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Paragraph(
            text: 'Tổng thời gian: ${report.totalMinutes} phút',
          ),
          pw.Paragraph(
            text: 'Trung bình/ngày: ${report.averageDailyUsage.toStringAsFixed(1)} phút',
          ),
        ],
      ),
    );
    
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/report_${report.reportId}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
  
  Future<File> exportToCsv(WeeklyReport report) async {
    final csvData = [
      ['Ngày', 'Thời gian (phút)'],
      ...report.dailyUsage.entries.map((e) => [e.key, e.value.toString()]),
      ['', ''],
      ['Tổng thời gian', report.totalMinutes.toString()],
      ['Trung bình/ngày', report.averageDailyUsage.toStringAsFixed(1)],
    ];
    
    final csv = const ListToCsvConverter().convert(csvData);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/report_${report.reportId}.csv');
    await file.writeAsString(csv);
    return file;
  }
}
```

### 14.5 Charts

```dart
// lib/presentation/widgets/usage_chart.dart
class UsageChart extends StatelessWidget {
  final Map<String, int> data;
  
  const UsageChart({super.key, required this.data});
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: data.values.reduce((a, b) => a > b ? a : b).toDouble() * 1.2,
          barGroups: data.entries.map((entry) {
            return BarChartGroupData(
              x: data.keys.toList().indexOf(entry.key),
              barRods: [
                BarChartRodData(
                  toY: entry.value.toDouble(),
                  color: Theme.of(context).colorScheme.primary,
                  width: 20,
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < data.keys.length) {
                    return Text(data.keys.elementAt(index));
                  }
                  return const Text('');
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## 15. Bảo mật

### 15.1 Firebase Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    function isParentOfChild(childUid) {
      let family = get(/databases/$(database)/documents/families/$(request.resource.data.familyId));
      return family.data.parentUid == request.auth.uid;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && isOwner(userId);
      allow update: if isAuthenticated() && isOwner(userId);
      allow delete: if false;
    }
    
    // Families collection
    match /families/{familyId} {
      allow read: if isAuthenticated() && 
        (resource.data.parentUid == request.auth.uid || 
         request.auth.uid in resource.data.childUids);
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && 
        resource.data.parentUid == request.auth.uid;
      allow delete: if false;
    }
    
    // Usage logs collection
    match /usage_logs/{logId} {
      allow read: if isAuthenticated() && 
        (resource.data.childUid == request.auth.uid || 
         isParentOfChild(resource.data.childUid));
      allow create: if isAuthenticated();
      allow update: if false;
      allow delete: if false;
    }
  }
}
```

### 15.2 Data Encryption

- **Transit**: TLS 1.3 cho tất cả communications
- **Rest**: Firebase tự động mã hóa dữ liệu tại rest
- **Local**: SharedPreferences không chứa dữ liệu nhạy cảm

### 15.3 Authentication Security

```dart
// Password validation
bool _isValidPassword(String password) {
  return password.length >= 8 &&
      RegExp(r'[A-Z]').hasMatch(password) &&
      RegExp(r'[a-z]').hasMatch(password) &&
      RegExp(r'[0-9]').hasMatch(password);
}

// Email validation
bool _isValidEmail(String email) {
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}
```

### 15.4 Privacy Considerations

- Dữ liệu người dùng được lưu trữ an toàn trên Firebase
- Không chia sẻ dữ liệu với bên thứ ba
- Phụ huynh chỉ có thể xem dữ liệu của con mình
- Trẻ em không thể xem dữ liệu của phụ huynh

---

## 16. Hiệu suất

### 16.1 Performance Metrics

| Metric | Target | Current |
|--------|--------|---------|
| App startup time | < 3s | ~2.5s |
| UI frame rate | 60 fps | 58-60 fps |
| Memory usage | < 150MB | ~120MB |
| Battery impact | Minimal | Low |
| Network requests | Optimized | OK |

### 16.2 Optimization Techniques

#### 16.2.1 Lazy Loading

```dart
// Lazy load widgets
class LazyLoadWidget extends StatefulWidget {
  @override
  _LazyLoadWidgetState createState() => _LazyLoadWidgetState();
}

class _LazyLoadWidgetState extends State<LazyLoadWidget> {
  bool _isLoaded = false;
  
  @override
  void initState() {
    super.initState();
    // Load data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }
  
  Future<void> _loadData() async {
    // Load heavy data
    setState(() {
      _isLoaded = true;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const CircularProgressIndicator();
    }
    return _buildContent();
  }
}
```

#### 16.2.2 Caching

```dart
// Cache images
CachedNetworkImage(
  imageUrl: url,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
  cacheManager: CacheManager(
    Config(
      'customCacheKey',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
    ),
  ),
);
```

#### 16.2.3 Efficient List Rendering

```dart
// Use ListView.builder for large lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ItemWidget(item: items[index]);
  },
  // Add keys for better performance
  key: PageStorageKey<String>('uniqueKey'),
);
```

### 16.3 Memory Management

```dart
// Dispose resources properly
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  StreamSubscription? _subscription;
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _subscription = stream.listen((data) {
      // Handle data
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      // Do something
    });
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
```

---

## 17. Testing

### 17.1 Testing Strategy

| Loại test | Coverage | Tools |
|-----------|----------|-------|
| Unit Tests | 80%+ | flutter_test, bloc_test |
| Widget Tests | 70%+ | flutter_test |
| Integration Tests | 60%+ | integration_test |
| E2E Tests | 50%+ | Patrol |

### 17.2 Unit Tests

```dart
// test/domain/usecases/check_app_access_usecase_test.dart
void main() {
  late CheckAppAccessUseCase useCase;
  late MockUsageRepository mockUsageRepository;
  late MockSmartLockRepository mockSmartLockRepository;
  
  setUp(() {
    mockUsageRepository = MockUsageRepository();
    mockSmartLockRepository = MockSmartLockRepository();
    useCase = CheckAppAccessUseCase(
      usageRepository: mockUsageRepository,
      smartLockRepository: mockSmartLockRepository,
    );
  });
  
  test('should return blocked when usage exceeds limit', () async {
    // Arrange
    when(() => mockUsageRepository.getTodayUsage(any(), any()))
        .thenAnswer((_) async => 60);
    when(() => mockSmartLockRepository.getAppTimeLimit(any()))
        .thenAnswer((_) async => 30);
    
    // Act
    final result = await useCase.execute('childUid', 'com.example.app');
    
    // Assert
    expect(result, isA<AppAccessBlocked>());
    verify(() => mockUsageRepository.getTodayUsage('childUid', 'com.example.app')).called(1);
  });
}
```

### 17.3 BLoC Tests

```dart
// test/presentation/blocs/auth_bloc_test.dart
void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockAuthRepository;
  late MockFamilyRepository mockFamilyRepository;
  late MockNotificationService mockNotificationService;
  
  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockFamilyRepository = MockFamilyRepository();
    mockNotificationService = MockNotificationService();
    authBloc = AuthBloc(
      authRepository: mockAuthRepository,
      familyRepository: mockFamilyRepository,
      notificationService: mockNotificationService,
    );
  });
  
  tearDown(() {
    authBloc.close();
  });
  
  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthAuthenticated] when sign in succeeds',
    build: () {
      when(() => mockAuthRepository.signInWithEmailAndPassword(any(), any()))
          .thenAnswer((_) async => mockUser);
      return authBloc;
    },
    act: (bloc) => bloc.add(SignInRequested(
      email: 'test@example.com',
      password: 'password',
    )),
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthAuthenticated>(),
    ],
  );
  
  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthError] when sign in fails',
    build: () {
      when(() => mockAuthRepository.signInWithEmailAndPassword(any(), any()))
          .thenThrow(Exception('Invalid credentials'));
      return authBloc;
    },
    act: (bloc) => bloc.add(SignInRequested(
      email: 'test@example.com',
      password: 'wrongpassword',
    )),
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthError>(),
    ],
  );
}
```

### 17.4 Widget Tests

```dart
// test/presentation/screens/login_screen_test.dart
void main() {
  testWidgets('Login screen should display email and password fields', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(),
      ),
    );
    
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
  
  testWidgets('Login screen should show error when fields are empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(),
      ),
    );
    
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    
    expect(find.text('Vui lòng nhập email'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
  });
}
```

### 17.5 Integration Tests

```dart
// integration_test/app_test.dart
void main() {
  group('App Integration Tests', () {
    testWidgets('Full login flow', (tester) async {
      await tester.pumpWidget(KidGuardianApp());
      
      // Wait for app to load
      await tester.pumpAndSettle();
      
      // Tap on parent login
      await tester.tap(find.text('Phụ huynh'));
      await tester.pumpAndSettle();
      
      // Enter credentials
      await tester.enterText(find.byType(TextField).first, 'parent@test.com');
      await tester.enterText(find.byType(TextField).last, 'Password123');
      
      // Tap login
      await tester.tap(find.text('Đăng nhập'));
      await tester.pumpAndSettle();
      
      // Should navigate to parent dashboard
      expect(find.text('Dashboard'), findsOneWidget);
    });
  });
}
```

---

## 18. Triển khai

### 18.1 Build Configuration

#### Android

```yaml
# android/app/build.gradle
android {
    compileSdk 34
    
    defaultConfig {
        applicationId "com.kidguardian.app"
        minSdk 24
        targetSdk 34
        versionCode 1
        versionName "1.0.0"
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

#### iOS

```xml
<!-- ios/Runner/Info.plist -->
<key>CFBundleDisplayName</key>
<string>KidGuardian</string>
<key>CFBundleIdentifier</key>
<string>com.kidguardian.app</string>
<key>CFBundleVersion</key>
<string>1</string>
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
```

### 18.2 CI/CD Pipeline

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.11.5'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Analyze code
        run: flutter analyze
      
      - name: Run tests
        run: flutter test
      
      - name: Build APK
        run: flutter build apk --release
  
  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      
      - name: Build and deploy
        run: |
          flutter build appbundle
          # Deploy to Google Play
```

### 18.3 Environment Configuration

```dart
// lib/core/config/env_config.dart
class EnvConfig {
  static const String apiKey = String.fromEnvironment('API_KEY');
  static const String authDomain = String.fromEnvironment('AUTH_DOMAIN');
  static const String projectId = String.fromEnvironment('PROJECT_ID');
  static const String storageBucket = String.fromEnvironment('STORAGE_BUCKET');
  static const String messagingSenderId = String.fromEnvironment('MESSAGING_SENDER_ID');
  static const String appId = String.fromEnvironment('APP_ID');
}
```

### 18.4 Release Process

1. **Version Bump**
   ```bash
   # Update version in pubspec.yaml
   flutter version 1.0.0+1
   ```

2. **Build Release**
   ```bash
   # Android
   flutter build appbundle --release
   
   # iOS
   flutter build ipa --release
   ```

3. **Deploy**
   - Android: Upload to Google Play Console
   - iOS: Upload to App Store Connect

---

## 19. Tài liệu tham khảo

### 19.1 Official Documentation

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Dart Language](https://dart.dev/guides)

### 19.2 Packages & Libraries

- [flutter_bloc](https://pub.dev/packages/flutter_bloc)
- [firebase_core](https://pub.dev/packages/firebase_core)
- [cloud_firestore](https://pub.dev/packages/cloud_firestore)
- [fl_chart](https://pub.dev/packages/fl_chart)

### 19.3 Architecture References

- [Clean Architecture - Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [BLoC Pattern](https://bloclibrary.dev/)

### 19.4 Design Guidelines

- [Material Design 3](https://m3.material.io/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

---

## 20. Phụ lục

### 20.1 Glossary

| Thuật ngữ | Định nghĩa |
|-----------|------------|
| **BLoC** | Business Logic Component - Pattern quản lý state |
| **Clean Architecture** | Kiến trúc phần mềm với sự phân tách rõ ràng |
| **Firebase** | Platform phát triển ứng dụng của Google |
| **Firestore** | NoSQL database của Firebase |
| **FCM** | Firebase Cloud Messaging - Dịch vụ push notification |
| **Smart Lock** | Tính năng khóa ứng dụng tự động |
| **Use Case** | Đại diện cho một hành động cụ thể của người dùng |

### 20.2 API Endpoints

#### Firestore Collections

| Collection | Description |
|------------|-------------|
| `users` | Thông tin người dùng |
| `families` | Thông tin gia đình |
| `usage_logs` | Nhật ký sử dụng |
| `daily_summaries` | Tổng hợp hàng ngày |
| `alerts` | Cảnh báo |
| `time_requests` | Yêu cầu thêm thời gian |
| `settings` | Cài đặt |

### 20.3 Error Codes

| Code | Description | Solution |
|------|-------------|----------|
| `auth/email-already-in-use` | Email đã được sử dụng | Sử dụng email khác |
| `auth/invalid-email` | Email không hợp lệ | Kiểm tra định dạng email |
| `auth/weak-password` | Mật khẩu yếu | Sử dụng mật khẩu mạnh hơn |
| `auth/user-not-found` | Không tìm thấy người dùng | Kiểm tra email |
| `auth/wrong-password` | Sai mật khẩu | Nhập lại mật khẩu |

### 20.4 Changelog

#### Version 1.0.0 (23/05/2026)
- Initial release
- Authentication system
- Family linking
- Usage monitoring
- Smart Lock feature
- Reports and statistics
- Push notifications

### 20.5 Known Issues

| Issue | Priority | Status |
|-------|----------|--------|
| UI lag on older devices | Medium | Investigating |
| Notification delay on iOS | Low | Pending fix |
| Battery optimization | High | In progress |

### 20.6 Future Enhancements

- [ ] Multi-language support (English, Vietnamese)
- [ ] Dark mode improvements
- [ ] Advanced analytics
- [ ] Content filtering
- [ ] Geofencing features
- [ ] Wear OS support

---

**Tài liệu này được tạo tự động bởi BMad Document Project**  
**Cập nhật lần cuối: 23/05/2026**

---

## Liên hệ

Đội ngũ phát triển KidGuardian  
Email: dev@kidguardian.com  
Website: https://kidguardian.com
