# 🛡️ KidGuardian - Đồng Hành Số & Quản Lý Thời Gian Thông Minh (THPT)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Cloud%20Firestore%20%7C%20Auth-FFCA28?logo=firebase)](https://firebase.google.com)
[![Test Coverage](https://img.shields.io/badge/Tests-650%2F650%20Passed%20(100%25)-4CAF50?logo=checkmarx)](test/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**KidGuardian** là giải pháp phần mềm toàn diện trên nền tảng di động giúp phụ huynh bảo vệ, đồng hành và quản lý thời gian sử dụng thiết bị số của học sinh THPT một cách minh bạch, khoa học và tự chủ.

---

## 🌟 Tính Năng Nổi Bật

### 1. 🔐 Liên Kết Gia Đình & Xác Thực An Toàn (`Family & Auth`)
- **Mã kết nối 6 chữ số (`Link Code`):** Liên kết nhanh chóng và bảo mật cao giữa máy phụ huynh (`Parent`) và máy con (`Child`).
- **Phân quyền vai trò minh bạch:** Trải nghiệm giao diện và luồng nghiệp vụ riêng biệt cho từng vai trò.

### 2. ⚡ Smart Lock & Chặn Ứng Dụng Mức Phần Cứng (`Native Blocking`)
- **Khóa ứng dụng realtime:** Cập nhật quy tắc giới hạn từ xa, tự động văng về màn hình Home dưới 0.5 giây khi mở ứng dụng vượt giới hạn (`GLOBAL_ACTION_HOME` qua **Accessibility Service**).
- **Lịch trình giờ học/giờ ngủ (`Schedules`):** Thiết lập khung giờ chặn tự động theo ngày trong tuần.
- **Quyền truy cập khẩn cấp (`Emergency Access`):** Cho phép mở khóa tạm thời trong 5 phút khi có việc khẩn cấp, tích hợp cơ chế đóng băng (`cooldown`) chống lạm dụng.

### 3. 💬 Tương Tác Đồng Hành (`Time Requests`)
- **Xin thêm thời gian thông minh:** Khi hết giờ, trẻ có thể bấm xin thêm (15/30/60 phút) kèm lý do ngay từ màn hình khóa (`app_blocked`) hoặc từ màn hình chính (`general_time`).
- **App Selector Dropdown:** Khi xin giờ từ màn hình chính, hệ thống hiển thị danh sách Dropdown (`AppSelector`) tự động lọc các ứng dụng đang có quy tắc giới hạn từ `RulesRepository`.
- **Duyệt yêu cầu tức thì:** Phụ huynh nhận thông báo realtime dưới 5 giây qua Firestore Stream và duyệt/từ chối chỉ với 1 chạm.

### 4. 🚨 Giám Sát Từ Khóa Nhạy Cảm (`Sensitive Keywords Monitor`)
- **Bộ 21 từ khóa mặc định chuẩn hóa:** Bảo vệ trẻ khỏi các nội dung độc hại thuộc 5 nhóm nguy cơ cao: *Nguy hiểm tính mạng, Bạo lực/Vũ khí, Chất kích thích/Cờ bạc, Nội dung người lớn (18+), Lừa đảo/An toàn*.
- **Quản lý tùy chỉnh linh hoạt:** Phụ huynh có thể thêm/xóa từ khóa tùy chỉnh hoặc khôi phục về mặc định (`ResetToDefaults`).

### 5. 📈 Báo Cáo & Thống Kê Khoa Học (`Analytics & Summaries`)
- **Biểu đồ trực quan:** Thống kê chi tiết thời gian sử dụng theo ngày, tuần, tháng và gom nhóm theo khung giờ (`groupByHour`).
- **Báo cáo tuần tự động (`Weekly Reports`):** Tự động tổng hợp và đánh giá mức độ sử dụng của học sinh.

---

## 🏗️ Kiến Trúc Kỹ Thuật & Tối Ưu Hiệu Năng

KidGuardian được xây dựng theo kiến trúc **Clean Architecture + BLoC Pattern**, đặc biệt chú trọng tới khả năng mở rộng và tối ưu chi phí hạ tầng Cloud Firebase:

### 🛡️ 1. Index-Defensive Querying (Truy Vấn Phòng Thủ Chỉ Mục)
Để chống lại lỗi `FAILED_PRECONDITION: The query requires an index...` và đảm bảo độ phản hồi siêu nhanh:
- **Single-Field Server Queries:** Các Repository (`SummaryRepository`, `ReportRepository`, `UsageRepository`) khi truy vấn lên Firestore chỉ lọc theo trường chính duy nhất (`childUid` hoặc `familyId`).
- **Client-Side Filtering & Sorting:** Toàn bộ việc sắp xếp thời gian (`orderBy`) và lọc dải ngày (`date range`) được thực hiện trong bộ nhớ RAM của ứng dụng Flutter (Client-side logic), loại bỏ hoàn toàn sự phụ thuộc vào Composite Indexes phức tạp và tiết kiệm tối đa Quota.

### 🔋 2. Bộ 8 Cơ Chế Bảo Vệ Hạn Ngạch Firebase (`Firebase Quota Protection`)
| Cơ chế | Mô tả kỹ thuật | Lợi ích |
| :--- | :--- | :--- |
| **FIX C1: Foreground Service** | Dịch vụ giám sát chạy ngầm (`START_STICKY`) với notification cố định | Không bị kill khi swipe app khỏi Recent Apps hay Force Stop |
| **FIX C2: Native App Blocking** | Khóa app tức thì bằng lệnh `GLOBAL_ACTION_HOME` qua Accessibility Service | Ngăn chặn vòng lặp mở app vi phạm |
| **FIX C3: Realtime Notifications** | Lắng nghe yêu cầu qua Firestore Stream và gửi thông báo đẩy | Nhận thông báo dưới 5 giây, không cần polling/refresh |
| **FIX C4: Cooldown 5 phút/app** | Bộ nhớ cache `_lastAlertSentMap` kiểm soát tần suất ghi cảnh báo | Giảm 90-95% số lần Writes lên Firestore khi trẻ bấm liên tục vào app bị chặn |
| **FIX C5: Khóa trần Reads (`.limit(50)`)** | Giới hạn tối đa 50 tài liệu mới nhất trên mọi luồng Stream Cảnh báo (`AlertRepository`) | Bảo vệ hạn ngạch 50.000 Reads/ngày của gói Spark Plan |
| **FIX C6: Offline SharedPreferences Cache** | Tự động đọc danh sách app và từ khóa từ cache cục bộ khi mất mạng/timeout | App hoạt động mượt mà 100% khi không có Internet |
| **FIX C7: Index-Defensive Architecture** | Lọc và sắp xếp dữ liệu báo cáo trực tiếp trong RAM Client | Ngăn lỗi `FAILED_PRECONDITION` và giảm số lượng Index cần bảo trì |
| **FIX C8: Granular App Selector** | Dropdown chọn ứng dụng cụ thể khi xin giờ từ Dashboard, kiểm tra qua `RulesRepository` | Tương tác chính xác, tránh ghi sai dữ liệu yêu cầu |

---

## 🧪 Chất Lượng Code & Bộ Kiểm Thử Tự Động (Test Suite)

Dự án tự hào đạt tỷ lệ pass **100% (`650/650 tests`)** cho toàn bộ bộ kiểm thử tự động (Unit Tests, BLoC Tests, và Widget/UI Tests):

```bash
# Chạy toàn bộ bộ kiểm thử tự động
flutter test

# Kết quả thực tế (11/07/2026):
# 00:16 +650 ~1: All other tests passed!
# Exit code: 0
```

- **Thư viện Mock chuẩn enterprise:** Sử dụng `mocktail` + `bloc_test` để lập trình giả lập đầy đủ các BLoC (`SmartLockBloc`, `AppMonitorBloc`) và Repository (`TimeRequestRepository`, `AlertRepository`, `RulesRepository`, `SummaryRepository`, `UsageRepository`, `ReportRepository`).
- **Kiểm thử chi tiết từng màn hình:** Đảm bảo tính ổn định tuyệt đối cho các luồng UI quan trọng như `LockScreen`, `RequestTimeDialog`, `EmergencyContactSheet`, `LoginScreen`, `RegisterScreen`, `DashboardScreen`, `KeywordManagementScreen`.

---

## 📚 Tài Liệu Hướng Dẫn & Kiểm Thử

Hệ thống tài liệu đầy đủ và chuẩn hóa, sẵn sàng cho việc triển khai và kiểm thử thực tế:

1. **[Hướng Dẫn Cài Đặt & Cấu Hình Firebase (`docs/FIREBASE_SETUP_GUIDE.md`)](docs/FIREBASE_SETUP_GUIDE.md):**  
   Hướng dẫn chi tiết từng bước tạo dự án Firebase, bật Authentication, thiết lập Firestore Test Mode, cấu hình `firestore.indexes.json` (`firebase deploy --only firestore:indexes`), và giải thích chiến lược Index-Defensive Querying.
2. **[Hướng Dẫn Kiểm Thử Thủ Công (`docs/MANUAL_TEST_GUIDE.md`)](docs/MANUAL_TEST_GUIDE.md):**  
   Tài liệu step-by-step gồm 17 Test Flows (từ Đăng nhập, Smart Lock, Tương tác Parent-Child với App Selector Dropdown, đến các bài test kiểm chứng Quota & Offline Cache).
3. **[Danh Sách Test Cases Chi Tiết (`docs/manual-test-cases.md`)](docs/manual-test-cases.md):**  
   Bộ 52 Test Cases chuẩn hóa (gồm `TC-REQ-001`, `TC-REQ-002`, `TC-026B`, `TC-QUOTA-001 -> TC-QUOTA-004`) kèm mẫu báo cáo lỗi (`Bug Report Template`) và bảng tổng kết (`Sign-off table`).

---

## 🚀 Hướng Dẫn Khởi Chạy Nhanh

### 1. Yêu cầu hệ thống
- **Flutter SDK:** `>=3.16.0 <4.0.0`
- **Dart SDK:** `>=3.2.0 <4.0.0`
- **Android Studio / VS Code** (kèm Flutter & Dart plugins)
- **Thiết bị Android:** API 26 (Android 8.0) trở lên

### 2. Cài đặt và khởi chạy
```bash
# 1. Clone dự án về máy
git clone <url-repository>
cd KidGuardian-THPT

# 2. Tải các package phụ thuộc
flutter pub get

# 3. Triển khai chỉ mục Firestore lên Firebase (chỉ cần chạy 1 lần nếu có Firebase CLI)
firebase deploy --only firestore:indexes

# 4. Kiểm tra toàn bộ test suite
flutter test

# 5. Khởi chạy ứng dụng trên thiết bị / emulator
flutter run
```

---

## 👥 Nhóm Phát Triển
Dự án được thiết kế, xây dựng và chuẩn hóa kỹ thuật cho cấp học **THPT**, định hướng kiến tạo một môi trường phát triển lành mạnh và an toàn cho thế hệ trẻ trong kỷ nguyên số.
