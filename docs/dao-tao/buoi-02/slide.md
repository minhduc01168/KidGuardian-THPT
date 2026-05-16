---
marp: true
theme: default
paginate: true
header: 'KidGuardian - Đồng Hành Số'
footer: 'BUỔI 2: Thiết Lập Môi Trường & Cấu Trúc App'
style: |
  section {
    background-color: #f8f9fa;
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    padding: 40px 50px;
    font-size: 26px; /* Giảm nhẹ font chữ chung */
    overflow-y: auto; /* Cho phép cuộn toàn trang nếu text quá dài */
  }
  h1 {
    color: #2c3e50;
    font-size: 2.0em;
    text-align: center;
  }
  h2 {
    color: #34495e;
    border-bottom: 2px solid #3498db;
    padding-bottom: 10px;
    margin-bottom: 20px;
    font-size: 1.4em;
  }
  h3 {
    color: #2980b9;
    font-size: 1.2em;
  }
  .center {
    text-align: center;
  }
  code {
    background-color: #e8eaed;
    border-radius: 4px;
    padding: 2px 4px;
    color: #c0392b;
    font-size: 0.85em;
  }
  pre {
    background-color: #f1f3f5;
    border-left: 4px solid #3498db;
    max-height: 420px; /* Giới hạn chiều cao cho khối code */
    overflow-y: auto;  /* Hiển thị thanh cuộn cho code dài */
    padding: 15px;
    box-shadow: inset 0 0 10px rgba(0,0,0,0.05);
  }
  pre code {
    color: #333;
    background-color: transparent;
    font-size: 0.85em;
  }
  /* Tùy chỉnh thanh cuộn (Scrollbar) cho đẹp mắt */
  ::-webkit-scrollbar {
    width: 8px;
    height: 8px;
  }
  ::-webkit-scrollbar-track {
    background: #e1e1e1; 
    border-radius: 4px;
  }
  ::-webkit-scrollbar-thumb {
    background: #888; 
    border-radius: 4px;
  }
  ::-webkit-scrollbar-thumb:hover {
    background: #555; 
  }
---

<!-- _class: lead -->
# 🚀 BUỔI 2: Thiết Lập Môi Trường & Cấu Trúc App

**Thời gian:** 2 tiết (90 phút)    
**Mục tiêu:** Cài đặt Flutter, tạo project, hiểu cấu trúc thư mục

---

## 🎯 Tổng quan buổi học

- **Lý thuyết:** Nắm bắt các khái niệm quan trọng
- **Thực hành:** Áp dụng kiến thức vào thực tế
- **Bài tập:** Củng cố kiến thức đã học


---
<!-- _class: lead -->
# 📚 PHẦN 1: LÝ THUYẾT (30 phút)

---
## Flutter Là Gì?

**Định nghĩa:**
- Framework phát triển ứng dụng di động của Google
- Viết code **1 lần** → Chạy trên **cả Android và iOS**
- Ngôn ngữ lập trình: **Dart**

**Tại sao chọn Flutter?**

| Ưu Điểm | Giải Thích |
|----------|-----------|
| Nhanh | Hot reload - thấy thay đổi ngay lập tức |
| Đẹp | UI mượt, animation dễ làm |
| Tiết kiệm | 1 codebase cho 2 nền tảng |
| Dễ học | Syntax đơn giản, nhiều tài liệu |
---
## Cấu Trúc Project Flutter

```
my_app/
├── android/          # Code Android (không cần sửa)
├── ios/              # Code iOS (không cần sửa)
├── lib/              # ⭐ Code Dart chính (nơi viết code)
│   ├── main.dart     # Entry point - bắt đầu từ đây
│   ├── screens/      # Các màn hình
│   ├── widgets/      # Các widget tái sử dụng
│   ├── models/       # Data models
│   └── services/     # Services (Firebase, API...)
├── test/             # Unit tests
├── pubspec.yaml      # ⭐ File khai báo dependencies
└── README.md         # Tài liệu dự án
```

**Quan trọng:** 90% thời gian viết code trong thư mục `lib/`
---
## Widget Là Gì?

**Widget** = Đơn nhỏ nhất để xây dựng giao diện

**Ví dụ:**
```
Ứng dụng = Nhiều Màn hình
Màn hình = Nhiều Widget

Widget có thể là:
- Text (văn bản)
- Button (nút bấm)
- Image (hình ảnh)
- Container (hộp chứa)
- Row, Column (sắp xếp)
```

---

---
<!-- _class: lead -->
# 📚 PHẦN 2: THỰC HÀNH (60 phút)

---
## Cài Đặt Môi Trường

**Bước 1: Cài Flutter SDK**

1. Truy cập: https://docs.flutter.dev/get-started/install
2. Chọn hệ điều hành (Windows/Mac/Linux)
3. Tải và giải nén
4. Thêm vào PATH

**Kiểm tra:**
```bash
flutter doctor
```

**Bước 2: Cài Android Studio**

1. Tải: https://developer.android.com/studio
2. Cài đặt
3. Mở Android Studio → SDK Manager
4. Chọn Android 13 (API 33)

**Bước 3: Cài VS Code**

1. Tải: https://code.visualstudio.com
2. Cài Extensions:
   - Flutter
   - Dart
---
## Tạo Project Mới

**Bước 1: Tạo project**

```bash
flutter create kidguardian
cd kidguardian
```

**Bước 2: Chạy thử**

```bash
flutter run
```

**Bước 3: Mở trong VS Code**

```bash
code .
```
---
## Cấu Trúc Lại Thư Mục

**Tạo cấu trúc chuyên nghiệp:**

```bash
# Trong thư mục lib/
mkdir -p screens
mkdir -p widgets
mkdir -p models
mkdir -p services
```

**Kết quả:**
```
lib/
├── main.dart
├── screens/
├── widgets/
├── models/
└── services/
```
---
## Code Màn Hình Home Cơ Bản

**Xóa nội dung mặc định trong `main.dart` và viết lại:**

```dart
// lib/main.dart
import 'package:flutter/material.dart';

void main() {
  runApp(KidGuardianApp());
}

class KidGuardianApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KidGuardian',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('KidGuardian'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield,
              size: 100,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Text(
              'Chào mừng đến với KidGuardian!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Đồng hành số cho gia đình bạn',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // Sẽ làm ở buổi sau
              },
              child: Text('Bắt đầu'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```
---
## Giải Thích Code

**`MaterialApp`:**
- Widget gốc của ứng dụng
- Cấu hình theme, title, home screen

**`Scaffold`:**
- Cấu trúc cơ bản của 1 màn hình
- Có AppBar (thanh trên), Body (nội dung)

**`Column`:**
- Sắp xếp các widget theo chiều dọc

**`Center`:**
- Căn giữa widget

**`ElevatedButton`:**
- Nút bấm có hiệu ứng nổi

---

---
<!-- _class: lead -->
# 📚 PHẦN 3: BÀI TẬP VỀ NHÀ

---
## Bài Tập 1: Tạo Màn Hình Mới

**Yêu cầu:**
- Tạo file `lib/screens/login_screen.dart`
- Code màn hình đăng nhập với:
  - TextField nhập Email
  - TextField nhập Password
  - Nút "Đăng nhập"
  - Text "Chưa có tài khoản? Đăng ký"
---
## Bài Tập 2: Tạo Widget Tái Sử Dụng

**Yêu cầu:**
- Tạo file `lib/widgets/custom_button.dart`
- Tạo widget `CustomButton` với:
  - Parameter: `text`, `onPressed`
  - Style đẹp, có thể tái sử dụng
---
## Bài Tập 3: Tìm Hiểu

**Câu hỏi:**
1. Sự khác biệt giữa `StatelessWidget` và `StatefulWidget` là gì?
2. `pubspec.yaml` dùng để làm gì?
3. Tại sao cần tách code thành nhiều thư mục?

---
---
## TÀI LIỆU THAM KHẢO

- Flutter Docs: https://docs.flutter.dev
- Dart Language Tour: https://dart.dev/guides/language/language-tour
- Flutter Widget Catalog: https://docs.flutter.dev/ui/widgets

---
---
## CÂU HỎI ÔN TẬP

1. Flutter dùng ngôn ngữ gì?
2. `lib/main.dart` là file gì?
3. `Widget` là gì? Cho 3 ví dụ.
4. Command để tạo project mới là gì?
5. Tại sao cần tách code thành `screens/`, `widgets/`, `models/`?

---

**Buổi Tiếp Theo:** [Buổi 3 - Giao diện Phân quyền](../buoi-03/README.md)

---
<!-- _class: lead -->
# 🎉 Cảm ơn các bạn!
### Hẹn gặp lại vào buổi sau
