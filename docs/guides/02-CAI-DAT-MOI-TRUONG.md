# Bài 2: Cài Đặt Môi Trường
# Hướng Dẫn Cài Đặt Công Cụ Phát Triển

---

## 1. Yêu Cầu Hệ Thống

### 1.1 Phần Cứng
- **RAM:** Tối thiểu 8GB (khuyến nghị 16GB)
- **Ổ cứng:** Tối thiểu 10GB trống
- **CPU:** Intel i5 hoặc tương đương

### 1.2 Hệ Điều Hành
- Windows 10/11 (64-bit)
- macOS 10.15 trở lên
- Linux (Ubuntu 20.04 trở lên)

---

## 2. Cài Đặt Flutter SDK

### 2.1 Tải Flutter

Truy cập: https://docs.flutter.dev/get-started/install

**Windows:**
```powershell
# Tải Flutter SDK
# Giải nén vào C:\flutter

# Thêm vào PATH
set PATH=%PATH%;C:\flutter\bin
```

**macOS/Linux:**
```bash
# Tải Flutter SDK
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable

# Thêm vào PATH
export PATH="$PATH:$HOME/development/flutter/bin"
```

### 2.2 Kiểm Tra Cài Đặt

```bash
flutter doctor
```

Kết quả mong đợi:
```
[✓] Flutter (Channel stable, 3.x.x)
[✓] Android toolchain - develop for Android devices
[✓] Android Studio
[✓] VS Code
[✓] Connected device
```

### 2.3 Cấu Hình Editor

**VS Code (Khuyến nghị):**
1. Mở VS Code
2. Install Extensions:
   - Flutter
   - Dart
3. Reload VS Code

**Android Studio:**
1. Mở Android Studio
2. Go to: Plugins
3. Search: Flutter
4. Install Flutter plugin

---

## 3. Cài Đặt Android Studio

### 3.1 Tải Android Studio

Truy cập: https://developer.android.com/studio

### 3.2 Cấu Hình Android Studio

1. Mở Android Studio
2. Go to: Settings → Appearance & Behavior → System Settings → Android SDK
3. Chọn tab: SDK Platforms
4. Chọn: Android 13 (API 33) hoặc mới hơn
5. Chọn tab: SDK Tools
6. Chọn:
   - Android SDK Build-Tools
   - Android SDK Command-line Tools
   - Android Emulator
   - Android SDK Platform-Tools
7. Click: Apply

### 3.3 Tạo Android Emulator

1. Mở Android Studio
2. Go to: Tools → Device Manager
3. Click: Create Device
4. Chọn: Pixel 6 (hoặc device bất kỳ)
5. Chọn: Android 13 (API 33)
6. Click: Finish

---

## 4. Cài Đặt Firebase CLI

### 4.1 Cài Đặt Node.js

Truy cập: https://nodejs.org/

```bash
# Kiểm tra cài đặt
node --version
npm --version
```

### 4.2 Cài Đặt Firebase CLI

```bash
npm install -g firebase-tools
```

### 4.3 Đăng Nhập Firebase

```bash
firebase login
```

### 4.4 Cài Đặt FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

---

## 5. Cài Đặt Git

### 5.1 Tải Git

Truy cập: https://git-scm.com/

### 5.2 Cấu Hình Git

```bash
git config --global user.name "Tên Của Bạn"
git config --global user.email "email@example.com"
```

### 5.3 Kiểm Tra Cài Đặt

```bash
git --version
```

---

## 6. Clone Dự Án

### 6.1 Clone Repository

```bash
git clone git@github.com:minhduc01168/KidGuardian-THPT.git
cd KidGuardian-THPT
```

### 6.2 Cài Đặt Dependencies

```bash
flutter pub get
```

### 6.3 Chạy Ứng Dụng

```bash
flutter run
```

---

## 7. Cấu Hình Firebase Cho Dự Án

### 7.1 Tạo Firebase Project

1. Truy cập: https://console.firebase.google.com/
2. Click: Add project
3. Nhập tên: KidGuardian
4. Bật Google Analytics (tùy chọn)
5. Click: Create project

### 7.2 Thêm Android App

1. Click: Add app → Android
2. Nhập Package name: `com.kidguardian.app`
3. Nhập App nickname: KidGuardian
4. Click: Register app
5. Tải file `google-services.json`
6. Copy vào: `android/app/google-services.json`

### 7.3 Cấu Hình FlutterFire

```bash
flutterfire configure
```

Chọn Firebase project và Android app.

---

## 8. Kiểm Tra Lại

### 8.1 Chạy Flutter Doctor

```bash
flutter doctor -v
```

### 8.2 Chạy Ứng Dụng

```bash
flutter run
```

### 8.3 Kiểm Tra Firebase

```bash
firebase projects:list
```

---

## 9. Xử Lý Sự Cố

### Flutter Doctor báo lỗi

**Lỗi:** Android toolchain not found
```bash
flutter config --android-sdk /path/to/android/sdk
```

**Lỗi:** Android Studio not found
```bash
flutter config --android-studio-dir /path/to/android/studio
```

### Không chạy được emulator

1. Kiểm tra: Android Studio → Device Manager
2. Khởi động emulator thủ công
3. Chạy lại: `flutter run`

### Firebase connection error

1. Kiểm tra file `google-services.json`
2. Kiểm tra package name có khớp không
3. Chạy lại: `flutterfire configure`

---

## 10. Tóm Tắt

| Bước | Công Cụ | Trạng Thái |
|------|---------|------------|
| 1 | Flutter SDK | ⬜ |
| 2 | Android Studio | ⬜ |
| 3 | Firebase CLI | ⬜ |
| 4 | Git | ⬜ |
| 5 | Clone project | ⬜ |
| 6 | Firebase setup | ⬜ |

---

**Bài Tiếp Theo:** [Flutter + Firebase](03-FLUTTER-FIREBASE.md)
