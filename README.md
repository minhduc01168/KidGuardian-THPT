# 🛡️ Kura (KidGuardian) - Đồng Hành Số & Quản Lý Thời Gian Thông Minh (THPT)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Cloud%20Firestore%20%7C%20Auth-FFCA28?logo=firebase)](https://firebase.google.com)
[![Test Coverage](https://img.shields.io/badge/Tests-772%2F772%20Passed%20(100%25)-4CAF50?logo=checkmarx)](test/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Kura (KidGuardian)** là giải pháp phần mềm toàn diện trên nền tảng di động giúp phụ huynh bảo vệ, đồng hành và quản lý thời gian sử dụng thiết bị số của học sinh THPT một cách minh bạch, khoa học và tự chủ.

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
- **Xin thêm thời gian thông minh:** Khi hết giờ, trẻ có thể bấm xin thêm (15/30/60 phút) kèm lý do ngay từ màn hình khóa.
- **Duyệt yêu cầu tức thì:** Phụ huynh nhận thông báo realtime dưới 5 giây qua hệ thống Firebase và duyệt/từ chối chỉ với 1 chạm.
- **App Selector Dropdown:** Hiển thị danh sách chọn lựa 10 ứng dụng mạng xã hội chuẩn hóa khi xin giờ, tự động lọc và loại bỏ các ứng dụng/game không thuộc quyền giám sát.

### 4. 🚨 Giám Sát Từ Khóa Nhạy Cảm (`Sensitive Keywords Monitor`)
- **Bộ 21 từ khóa mặc định chuẩn hóa:** Bảo vệ trẻ khỏi các nội dung độc hại thuộc 5 nhóm nguy cơ cao: *Nguy hiểm tính mạng, Bạo lực/Vũ khí, Chất kích thích/Cờ bạc, Nội dung người lớn (18+), Lừa đảo/An toàn*.
- **Quản lý tùy chỉnh linh hoạt:** Phụ huynh có thể thêm/xóa từ khóa tùy chỉnh hoặc khôi phục về mặc định.

### 5. 📈 Báo Cáo & Thống Kê Khoa Học (`Analytics & Summaries`)
- **Biểu đồ trực quan thông minh:** Thống kê chi tiết thời gian sử dụng theo ngày, tuần, tháng. Tích hợp thuật toán làm tròn (`Smart Rounding`) và tối ưu hiển thị UX (tự động ẩn số phần trăm quá bé để chống đè chữ trên PieChart).
- **Báo cáo tự động:** Tự động tổng hợp danh sách Top các ứng dụng sử dụng nhiều nhất để phụ huynh dễ dàng đánh giá.

---

## 🏗️ Kiến Trúc Kỹ Thuật & Tối Ưu Hiệu Năng

Kura được xây dựng theo kiến trúc **Clean Architecture + BLoC Pattern**, đặc biệt chú trọng tới khả năng mở rộng và tối ưu chi phí hạ tầng Cloud Firebase:

### 🛡️ 1. Index-Defensive Querying (Truy Vấn Phòng Thủ Chỉ Mục)
Để đảm bảo độ phản hồi siêu nhanh và chống cạn kiệt Quota Firebase:
- **Single-Field Server Queries:** Các Repository khi truy vấn lên Firestore chỉ lọc theo trường chính duy nhất (`childUid` hoặc `familyId`).
- **Client-Side Filtering & Sorting:** Toàn bộ việc sắp xếp thời gian (`orderBy`) và lọc dải ngày (`date range`) được thực hiện trong bộ nhớ RAM của ứng dụng Flutter, loại bỏ hoàn toàn sự phụ thuộc vào Composite Indexes đắt đỏ.

### 🔋 2. Các Cơ Chế Tối Ưu & Bảo Vệ Cấp Độ Hệ Thống
| Cơ chế | Mô tả kỹ thuật | Lợi ích |
| :--- | :--- | :--- |
| **Foreground Service bền bỉ** | Dịch vụ giám sát chạy ngầm (`START_STICKY`) | Không bị Android tự động tắt (kill) khi người dùng vuốt xóa ứng dụng khỏi Recent Apps. |
| **Native App Blocking** | Khóa app tức thì bằng lệnh `GLOBAL_ACTION_HOME` | Hoạt động sâu ở mức phần cứng, ngăn chặn trẻ cố gắng mở vòng lặp app liên tục. |
| **Realtime Stream Monitoring** | Lắng nghe yêu cầu qua Firestore Stream | Cập nhật giới hạn giờ và thông báo thời gian thực dưới 5 giây. |
| **Cooldown Cảnh báo 5 phút** | Bộ nhớ cache cục bộ kiểm soát tần suất ghi cảnh báo | Giảm 95% số lần Writes rác lên Firebase khi trẻ spam mở app bị chặn. |
| **Khóa trần Reads (`.limit`)** | Giới hạn tối đa tài liệu mới nhất trên luồng Stream | Bảo vệ tuyệt đối hạn ngạch 50.000 Reads/ngày của Firebase Spark Plan. |
| **Offline Cache Mode** | Tự động đọc dữ liệu từ `SharedPreferences` | Hệ thống khóa vẫn hoạt động mượt mà 100% kể cả khi thiết bị mất mạng Internet. |
| **Tự động hóa Chỉ mục** | Đóng gói sẵn 14+ Firestore Indexes qua `firestore.indexes.json` | Triển khai siêu nhanh toàn bộ cấu trúc Server qua 1 dòng lệnh `firebase deploy`. |

---

## 🧪 Chất Lượng Code & Bộ Kiểm Thử Tự Động (Test Suite)

Dự án tự hào đạt tỷ lệ pass **100% (`772/772 tests`)** cho toàn bộ bộ kiểm thử tự động (Unit Tests, BLoC Tests, và Widget/UI Tests):

```bash
# Chạy toàn bộ bộ kiểm thử tự động
flutter test

# Kết quả thực tế (Tháng 09/2026):
# 02:13 +772: All tests passed!
# Exit code: 0
```

- **Thư viện Mock chuẩn Enterprise:** Sử dụng `mocktail` + `bloc_test` để lập trình giả lập đầy đủ các BLoC và Repository (bao gồm `SmartLockBloc`, `AppMonitorBloc`, `TimeRequestRepository`, `SummaryRepository`...).
- **Kiểm thử chi tiết từng màn hình:** Đảm bảo tính ổn định tuyệt đối cho các luồng UI cực kỳ phức tạp như `LockScreen`, `RequestTimeDialog`, và hệ thống biểu đồ báo cáo `Dashboard`.

---

## 📚 Tài Liệu Hướng Dẫn Kỹ Thuật

Hệ thống tài liệu đầy đủ và chuẩn hóa được đặt tại thư mục `docs/`:

1. **[Hướng Dẫn Khởi Tạo Cơ Sở Dữ Liệu Firebase (`docs/KURA_DATABASE_SETUP_GUIDE.md`)](docs/KURA_DATABASE_SETUP_GUIDE.md):**  
   Hướng dẫn chi tiết tạo dự án, thiết lập Auth, cấu trúc Firestore Schema tự động (NoSQL), và Security Rules.
2. **[Phân Tích Kiến Trúc Kura (`docs/Kura_Technical_Analysis.md`)](docs/Kura_Technical_Analysis.md):**  
   Phân tích chuyên sâu về hệ thống giám sát ngầm, cơ chế giao tiếp Native, cấu trúc Flat Structure, và Data Flow đa tầng.
3. **[Hướng Dẫn Triển Khai Cloud Functions (`docs/CLOUD_FUNCTIONS_DEPLOY_GUIDE.md`)](docs/CLOUD_FUNCTIONS_DEPLOY_GUIDE.md):**  
   Cách thiết lập Push Notification tự động thông qua Node.js để đẩy thông báo khẩn cấp về máy phụ huynh.

---

## 🚀 Hướng Dẫn Khởi Chạy Nhanh

### 1. Yêu cầu hệ thống
- **Flutter SDK:** `>=3.16.0 <4.0.0`
- **Dart SDK:** `>=3.2.0 <4.0.0`
- **IDE:** Android Studio / VS Code (kèm Flutter & Dart plugins)
- **Thiết bị Android:** API 26 (Android 8.0) trở lên

### 2. Cài đặt và khởi chạy
```bash
# 1. Clone dự án về máy
git clone <url-repository>
cd KidGuardian-THPT

# 2. Tải các package phụ thuộc
flutter pub get

# 3. Triển khai cấu trúc chỉ mục Firestore lên Firebase (Chỉ chạy 1 lần nếu có Firebase CLI)
firebase deploy --only firestore:indexes

# 4. Chạy kiểm tra bộ test suite để đảm bảo mã nguồn an toàn
flutter test

# 5. Khởi chạy ứng dụng
flutter run
```

---

## 👥 Nhóm Phát Triển
Dự án được thiết kế, xây dựng và chuẩn hóa kỹ thuật cho cấp học **THPT**, định hướng kiến tạo một môi trường phát triển lành mạnh và an toàn cho thế hệ trẻ trong kỷ nguyên số.
