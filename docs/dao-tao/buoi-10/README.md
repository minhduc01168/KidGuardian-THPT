# BUỔI 10: Hoàn Thiện, Build APK & Đóng Gói Dự Án

**Thời gian:** 2 tiết (90 phút)  
**Mục tiêu:** Fix bug, build APK, đẩy code lên GitHub

---

## PHẦN 1: LÝ THUYẾT (30 phút)

### 1.1 Quy Trình Đóng Gói Ứng Dụng

```
Development → Testing → Build → Deploy
     ↓           ↓        ↓        ↓
   Viết code   Test    Tạo APK   Cài lên điện thoại
```

### 1.2 Debug vs Release

| Loại | Đặc Điểm | Mục Đích |
|------|-----------|----------|
| Debug | Có hot reload, debug tools | Phát triển |
| Release | Tối ưu hóa, nhỏ hơn | Deploy |

### 1.3 README Là Gì?

**README** = File tài liệu chính của dự án

**Nội dung nên có:**
- Tên dự án
- Mô tả
- Cách cài đặt
- Cách chạy
- Tác giả

---

## PHẦN 2: THỰC HÀNH (60 phút)

### 2.1 Kiểm Tra Lại Code

**Checklist:**

- [ ] App chạy không crash
- [ ] Đăng nhập hoạt động
- [ ] Dashboard hiển thị đúng
- [ ] Tính năng xin giờ hoạt động
- [ ] Cảnh báo hoạt động
- [ ] Không có lỗi UI

### 2.2 Fix Bug Thường Gặp

**Bug 1: Null safety error**
```dart
// Sai
String name = user.name; // Có thể null

// Đúng
String name = user.name ?? 'Unknown';
```

**Bug 2: Async error**
```dart
// Sai
void loadData() {
  data = await fetchData(); // Lỗi vì không có async
}

// Đúng
Future<void> loadData() async {
  data = await fetchData();
}
```

**Bug 3: Widget not found**
```dart
// Sai
TextEditingController controller;

// Đúng
TextEditingController controller = TextEditingController();
```

### 2.3 Tạo README.md

**Tạo file `README.md` trong thư mục gốc:**

```markdown
# KidGuardian - Đồng Hành Số

## Mô tả
KidGuardian là ứng dụng giúp phụ huynh và trẻ em cùng quản lý thói 
quen sử dụng mạng xã hội thông qua sự thỏa thuận và giám sát minh bạch.

## Tính năng chính
- ✅ Dashboard giám sát thời gian sử dụng
- ✅ Đặt giới hạn thời gian theo ngày
- ✅ Tính năng xin thêm giờ
- ✅ Cảnh báo nội dung nhạy cảm
- ✅ Phân quyền Phụ huynh / Con

## Công nghệ sử dụng
- **Framework:** Flutter 3.x
- **Backend:** Firebase
- **Database:** Cloud Firestore
- **Authentication:** Firebase Auth

## Cài đặt

### Yêu cầu
- Flutter SDK 3.x
- Android Studio
- Firebase account

### Các bước
1. Clone repository:
   ```bash
   git clone https://github.com/minhduc01168/KidGuardian-THPT.git
   ```

2. Cài đặt dependencies:
   ```bash
   flutter pub get
   ```

3. Cấu hình Firebase:
   - Tạo Firebase project
   - Tải `google-services.json`
   - Copy vào `android/app/`

4. Chạy ứng dụng:
   ```bash
   flutter run
   ```

## Build APK
```bash
flutter build apk --release
```

File APK sẽ nằm tại: `build/app/outputs/flutter-apk/app-release.apk`

## Cấu trúc thư mục
```
lib/
├── main.dart
├── screens/          # Các màn hình
├── widgets/          # Widget tái sử dụng
├── models/           # Data models
└── services/         # Firebase services
```

## Tác giả
- **Nguyễn Minh Đức** - *Lead Developer*

## License
Dự án này dành cho mục đích học tập.
```

### 2.4 Đẩy Code Lên GitHub

**Bước 1: Khởi tạo Git (nếu chưa có)**
```bash
git init
```

**Bước 2: Thêm tất cả file**
```bash
git add .
```

**Bước 3: Commit**
```bash
git commit -m "feat: hoàn thiện KidGuardian MVP"
```

**Bước 4: Đẩy lên GitHub**
```bash
git remote add origin https://github.com/minhduc01168/KidGuardian-THPT.git
git push -u origin master
```

### 2.5 Build APK

**Bước 1: Clean project**
```bash
flutter clean
flutter pub get
```

**Bước 2: Build release APK**
```bash
flutter build apk --release
```

**Bước 3: Tìm file APK**
```
build/app/outputs/flutter-apk/app-release.apk
```

**Bước 4: Cài lên điện thoại**
- Copy file APK vào điện thoại
- Mở file và cài đặt
- Hoặc sử dụng: `flutter install`

### 2.6 Tạo Báo Cáo Dự Án

**Cấu trúc báo cáo:**

```
1. Giới thiệu dự án
   - Mục tiêu
   - Đối tượng sử dụng

2. Phân tích yêu cầu
   - Yêu cầu chức năng
   - Yêu cầu phi chức năng

3. Thiết kế
   - Kiến trúc hệ thống
   - Cơ sở dữ liệu
   - Giao diện

4. Triển khai
   - Công nghệ sử dụng
   - Quá trình phát triển

5. Kết quả
   - Demo ứng dụng
   - Đánh giá

6. Kết luận
   - Ưu điểm
   - Nhược điểm
   - Hướng phát triển
```

---

## PHẦN 3: BÀI TẬP CUỐI KHÓA

### Dự Án Cá Nhân

**Yêu cầu:**
- Hoàn thiện tất cả tính năng đã học
- Tùy chỉnh giao diện theo ý thích
- Thêm ít nhất 1 tính năng mới
- Viết README đầy đủ
- Đẩy code lên GitHub

**Tính năng mới có thể thêm:**
- Dark mode
- Đa ngôn ngữ
- Thống kê chi tiết hơn
- Chia sẻ lên mạng xã hội
- ...

---

## PHẦN 4: TỔNG KẾT KHÓA HỌC

### Kiến Thức Đã Học

| Buổi | Nội Dung | Kỹ Năng |
|------|----------|---------|
| 1 | UI/UX Design | Figma, User Flow |
| 2 | Flutter Setup | Tạo project, Cấu trúc |
| 3 | State Management | setState, StatefulWidget |
| 4 | Firebase Auth | Đăng ký, Đăng nhập |
| 5 | Firestore | CRUD dữ liệu |
| 6 | Data Viz | Biểu đồ fl_chart |
| 7 | Smart Lock | Timer, Logic kiểm tra |
| 8 | Real-time | Stream, Listener |
| 9 | AI Filter | Regex, Cảnh báo |
| 10 | Deploy | Build APK, GitHub |

### Sản Phẩm Hoàn Chỉnh

- ✅ Ứng dụng Flutter hoàn chỉnh
- ✅ Tích hợp Firebase Auth & Firestore
- ✅ Dashboard quản lý thời gian
- ✅ Cơ chế khóa giờ và xin thêm thời gian
- ✅ Logic cảnh báo nội dung nhạy cảm
- ✅ APK chạy trên thiết bị thật
- ✅ Mã nguồn trên GitHub

### Hướng Phát Triển Tiếp

1. **iOS Version:** Sử dụng Flutter để build cho iOS
2. **Advanced AI:** Sử dụng Machine Learning để lọc nội dung
3. **Multi-child:** Hỗ trợ nhiều con trong 1 gia đình
4. **Analytics:** Thống kê chi tiết hơn
5. **Social Features:** Chia sẻ tiến trình

---

## CHỨC MỪNG BẠN ĐÃ HOÀN THÀNH KHÓA HỌC! 🎉

Bạn đã có đủ kiến thức để:
- Xây dựng ứng dụng di động với Flutter
- Sử dụng Firebase làm backend
- Triển khai ứng dụng lên thiết bị thật
- Tiếp tục phát triển dự án KidGuardian

**Chúc bạn thành công!** 🚀
