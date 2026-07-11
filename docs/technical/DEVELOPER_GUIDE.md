# HƯỚNG DẪN PHÁT TRIỂN & KIẾN TRÚC PHẦN MỀM (DEVELOPER GUIDE)
**Dự án:** KidGuardian - Đồng Hành Số  
**Nền tảng:** Flutter (Dart 3.x) + Android Native (Kotlin/Java) + Firebase Cloud  

---

## 1. KIẾN TRÚC TỔNG QUÁT (CLEAN ARCHITECTURE + BLOC)

KidGuardian được xây dựng tuân thủ nghiêm ngặt theo mô hình **Clean Architecture** kết hợp với **BLoC (Business Logic Component)** để quản lý trạng thái, đảm bảo tính phân tách trách nhiệm (Separation of Concerns), dễ kiểm thử (Testable) và dễ mở rộng.

```
       +-------------------------------------------------------------+
       |               PRESENTATION LAYER (UI / BLoC)                |
       |   Screens, Widgets, BLoCs, Events, States                   |
       +-------------------------------------------------------------+
                                      |
                                      v
       +-------------------------------------------------------------+
       |                 DOMAIN LAYER (Core Business)                |
       |   Entities, Usecases, Repository Interfaces                 |
       +-------------------------------------------------------------+
                                      ^
                                      |
       +-------------------------------------------------------------+
       |                  DATA LAYER (Implementation)                |
       |   Models, Repository Implementations, Data Sources, Cache   |
       +-------------------------------------------------------------+
```

### 1.1. Cấu trúc thư mục (`lib/`)
```
lib/
├── core/                  # Các tiện ích chung, hằng số, theme, routing, error handling
│   ├── constants/         # AppColors, AppStrings
│   ├── navigation/        # AppRoutes (GoRouter/Navigator setup)
│   ├── theme/             # AppTheme (Dark/Light mode, Google Fonts setup)
│   └── utils/             # AppUtils, Validators, Formatters
├── domain/                # Lớp nghiệp vụ cốt lõi (HOÀN TOÀN KHÔNG phụ thuộc UI hay SDK bên thứ ba ngoài Dart)
│   ├── entities/          # Đối tượng nghiệp vụ thuần (User, Family, Alert, TimeRequest...)
│   ├── repositories/      # Interface định nghĩa các hành vi (AuthRepository, SmartLockRepository...)
│   └── usecases/          # Các logic tác vụ cụ thể (LinkChildUseCase, CheckAppAccessUseCase...)
├── data/                  # Lớp triển khai dữ liệu (Kết nối Firebase, SharedPreferences, Local DB)
│   ├── datasources/       # Remote (Firestore/Functions) & Local (Cache/SharedPreferences) sources
│   ├── models/            # Lớp chuyển đổi JSON/Map từ Firestore sang Domain Entity
│   ├── repositories/      # Triển khai thực tế các interface từ lớp Domain
│   └── services/          # Các dịch vụ nền (NotificationService, EmailService...)
├── presentation/          # Lớp giao diện người dùng
│   ├── blocs/             # Các BLoC/Cubit quản lý trạng thái của từng tính năng
│   ├── features/          # Các module màn hình lớn (Dashboard, Auth...)
│   ├── screens/           # Các màn hình cụ thể (LockScreen, EmergencyScreen...)
│   └── widgets/           # Các component tái sử dụng (CountdownTimer, ContactSheet...)
└── platform/              # Cầu nối giao tiếp với hệ điều hành Native (Platform Channels)
    └── android/           # Android Accessibility Channel & Method Channels
```

---

## 2. QUẢN LÝ TRẠNG THÁI (BLOC STATE MANAGEMENT)

### 2.1. Quy tắc viết BLoC
- **Event:** Bắt buộc kế thừa `Equatable`. Mọi hành động của người dùng hoặc trigger từ hệ thống đều phải thể hiện rõ qua tên Event (ví dụ: `LoadDashboardData`, `AppOpenedEvent`, `KeywordDetectedEvent`).
- **State:** Thể hiện các trạng thái của UI (ví dụ: `AppMonitorInitial`, `AppMonitorLoading`, `AppMonitorActive`, `AppBlockedState`).
- **Xử lý bất đồng bộ:** Sử dụng `async/await` an toàn. Luôn bọc trong `try/catch` và emit trạng thái lỗi (`ErrorState`) khi cần thiết.
- **Hủy Đăng ký (Dispose/Close):** BẤT KỲ `StreamSubscription` hay `Timer` nào khởi tạo trong BLoC bắt buộc phải được hủy bên trong phương thức `close()`:

```dart
@override
Future<void> close() {
  _alertSubscription?.cancel();
  _timeLimitCheckTimer?.cancel();
  return super.close();
}
```

### 2.2. Dependency Injection (GetIt)
Toàn bộ repository, usecase và service được đăng ký dạng `LazySingleton` hoặc `Factory` trong file thiết lập DI (`injection_container.dart` hoặc `main.dart`). UI không bao giờ khởi tạo trực tiếp Repository bằng từ khóa `new/const` mà phải truy xuất qua Service Locator hoặc `RepositoryProvider` của `flutter_bloc`.

---

## 3. CẦU NỐI TRỢ NĂNG ANDROID (ACCESSIBILITY SERVICE BRIDGE)

Phân hệ Giám sát Học sinh (Child App) dựa vào **Android Accessibility Service (Dịch vụ trợ năng)** chạy ngầm ở tầng Native (Java/Kotlin) để phát hiện gói ứng dụng đang chạy và quét nội dung văn bản tìm từ khóa nhạy cảm.

### 3.1. Cơ chế giao tiếp (`AccessibilityChannel`)
File `lib/platform/android/accessibility_channel.dart` chịu trách nhiệm lắng nghe dữ liệu đẩy lên từ Android thông qua `EventChannel`:

```
[Android Native: AccessibilityService] 
       --- (send via EventChannel) ---> [Flutter: AccessibilityChannel]
                                               |
                                               v (Stream emitted)
                                      [AppMonitorBloc]
```

- **Tên MethodChannel:** `com.kidguardian/accessibility_methods` (Dùng để kiểm tra quyền, mở trang cài đặt trợ năng, gửi lệnh khóa `performGlobalAction`).
- **Tên EventChannel:** `com.kidguardian/accessibility_events` (Dùng để phát liên tục tên gói ứng dụng (`packageName`) và văn bản (`textContext`) lên tầng Dart).

### 3.2. Quy trình xử lý sự kiện trong `AppMonitorBloc`
1. Nhận `packageName` từ tầng Native.
2. Kiểm tra bộ nhớ đệm (`SharedPreferences`) xem ứng dụng đó có thuộc danh sách bị giám sát hay không (`MonitoredAppModel`).
3. Nếu ứng dụng **BỊ KHÓA** hoặc **HẾT THỜI GIAN**:
   - Gọi MethodChannel xuống Native ra lệnh `GLOBAL_ACTION_HOME` (< 50ms).
   - Đẩy Màn hình Khóa (`LockScreen`) lên trên cùng.
   - Kiểm tra `Cooldown (5 phút)` -> Nếu đủ thời gian thì gửi `Alert` lên Firestore cho Phụ huynh.

---

## 4. QUY TRÌNH THÊM TÍNH NĂNG MỚI (NEW FEATURE WORKFLOW)

Khi cần thêm một tính năng mới (Ví dụ: **Báo cáo tuần - Weekly Report**), lập trình viên thực hiện theo thứ tự 4 bước chuẩn Clean Architecture:

### Bước 1: Lớp Domain (`lib/domain/`)
1. Tạo Entity: `lib/domain/entities/weekly_report.dart`
2. Định nghĩa Interface: `lib/domain/repositories/report_repository.dart`
3. (Tùy chọn) Tạo UseCase: `lib/domain/usecases/report/get_weekly_report_usecase.dart`

### Bước 2: Lớp Data (`lib/data/`)
1. Tạo Model (kế thừa Entity + có `fromJson/toMap`): `lib/data/models/weekly_report_model.dart`
2. Triển khai Repository: `lib/data/repositories/report_repository_impl.dart` (Sử dụng Firestore/Cache). *Lưu ý tuân thủ tuyệt đối quy tắc chống spam Quota (xem file `FIREBASE_QUOTA_OPTIMIZATION.md`).*

### Bước 3: Lớp Presentation (`lib/presentation/`)
1. Tạo BLoC (`ReportBloc`, `ReportEvent`, `ReportState`) tại `lib/presentation/blocs/report/`.
2. Viết UI Screens & Widgets tại `lib/presentation/screens/report/`.

### Bước 4: Kiểm thử & Commit
- Chạy `dart analyze` hoặc `flutter analyze` để đảm bảo 0 lỗi syntax/lint.
- Viết/chạy unit test cho BLoC và Repository.
- Commit theo chuẩn Conventional Commits: `feat: thêm chức năng báo cáo tuần cho phụ huynh`.

---
*Tài liệu này giúp đảm bảo tính nhất quán và chất lượng mã nguồn của toàn bộ dự án KidGuardian.*
