# Hướng Dẫn Cài Đặt Môi Trường Flutter & Kết Nối Android
# Tài liệu đào tạo cho đội ngũ KidGuardian

**Cập nhật:** 2026-05-12  
**Đã test trên:** Ubuntu 20.04 LTS, Redmi Note 12

---

## Mục Lục

1. [Tổng quan](#1-tổng-quan)
2. [Cài đặt Flutter SDK](#2-cài-đặt-flutter-sdk)
3. [Cài đặt Java 11](#3-cài-đặt-java-11)
4. [Cài đặt Android SDK & ADB](#4-cài-đặt-android-sdk--adb)
5. [Kết nối điện thoại Android](#5-kết-nối-điện-thoại-android)
6. [Cấu hình Firebase](#6-cấu-hình-firebase)
7. [Tạo Flutter Project](#7-tạo-flutter-project)
8. [Chạy ứng dụng](#8-chạy-ứng-dụng)
9. [Xử lý sự cố](#9-xử-lý-sự-cố)

---

## 1. Tổng Quan

### Phần Mềm Cần Cài

| Phần Mềm | Phiên Bản | Dung Lượng | Mục Đích |
|-----------|-----------|------------|----------|
| Flutter SDK | 3.x | ~2.5 GB | Framework phát triển app |
| Java (OpenJDK) | 11 | ~300 MB | Chạy Android tools |
| Android SDK Tools | Latest | ~500 MB | Build & deploy Android |
| ADB | Latest | ~10 MB | Kết nối điện thoại |

### Yêu Cầu Hệ Thống

- **OS:** Ubuntu 20.04+ (hoặc Linux tương đương)
- **RAM:** Tối thiểu 8GB
- **Ổ cứng:** Tối thiểu 10GB trống
- **Điện thoại:** Android 5.0+ với cáp USB

---

## 2. Cài Đặt Flutter SDK

### Bước 1: Tải Flutter

```bash
# Tạo thư mục development
mkdir -p ~/development

# Clone Flutter SDK (shallow clone để tiết kiệm dung lượng)
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable --depth 1
```

### Bước 2: Thêm vào PATH

```bash
# Thêm vào ~/.bashrc
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.bashrc

# Reload shell
source ~/.bashrc
```

### Bước 3: Kiểm tra

```bash
flutter --version
```

**Kết quả mong đợi:**
```
Flutter 3.41.9 • channel stable
Framework • revision 00b0c91f06
Engine • revision 9161402dc0
Tools • Dart 3.11.5
```

---

## 3. Cài Đặt Java 11

### Tại Sao Cần Java 11?

Android SDK tools yêu cầu Java 11 trở lên. Java 8 quá cũ sẽ gây lỗi.

### Cài Đặt

```bash
sudo apt-get update
sudo apt-get install -y openjdk-11-jdk
```

### Kiểm Tra

```bash
java -version
```

**Kết quả mong đợi:**
```
openjdk version "11.0.x"
OpenJDK Runtime Environment (build 11.0.x)
```

### Chuyển đổi Java Version (nếu cần)

```bash
# Xem danh sách Java đã cài
sudo update-alternatives --config java

# Chọn Java 11
```

---

## 4. Cài Đặt Android SDK & ADB

### Bước 1: Cài ADB

```bash
sudo apt-get install -y android-tools-adb
```

### Bước 2: Cài Android SDK Command Line Tools

```bash
# Tạo thư mục SDK
mkdir -p ~/Android/Sdk/cmdline-tools

# Tải Command Line Tools
cd ~/Android/Sdk/cmdline-tools
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdline-tools.zip

# Giải nén
unzip cmdline-tools.zip
mv cmdline-tools latest
rm cmdline-tools.zip
```

### Bước 3: Cấu hình PATH cho Android SDK

```bash
# Thêm vào ~/.bashrc
echo 'export ANDROID_HOME=$HOME/Android/Sdk' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools' >> ~/.bashrc

# Reload
source ~/.bashrc
```

### Bước 4: Cấp quyền cho Flutter

```bash
flutter config --android-sdk ~/Android/Sdk
```

---

## 5. Kết Nối Điện Thoại Android

### Bước 1: Bật Developer Options

**Trên Redmi Note 12 (Xiaomi/MIUI):**

1. Mở **Settings** (Cài đặt)
2. Vuốt xuống → **About phone** (Giới thiệu điện thoại)
3. Tìm **"MIUI version"** (Phiên bản MIUI)
4. **Tap 7 lần** liên tiếp vào "MIUI version"
5. Thấy thông báo **"You are now a developer!"** là thành công

**Trên Samsung:**
1. Settings → About phone → Software information
2. Tap 7 lần vào "Build number"

**Trên Pixel/Android gốc:**
1. Settings → About phone
2. Tap 7 lần vào "Build number"

### Bước 2: Bật USB Debugging

**Trên Redmi Note 12:**

1. Quay lại **Settings**
2. Vuốt xuống → **Additional settings** (Cài đặt bổ sung)
3. **Developer options** (Tùy chọn nhà phát triển)
4. Bật các tùy chọn sau:
   - ✅ **USB debugging** - BẬT
   - ✅ **USB debugging (Security settings)** - BẬT (nếu có)
   - ✅ **Install via USB** - BẬT

### Bước 3: Cắm Dây USB & Chọn Chế Độ

1. Cắm dây USB từ điện thoại vào máy tính
2. Kéo **thanh thông báo** xuống trên điện thoại
3. Tìm mục **"USB charging this device"** hoặc **"USB for"**
4. Tap vào → Chọn **"File Transfer (MTP)"**
5. Nếu popup **"Allow USB debugging?"** hiện → Tick **"Always allow"** → **OK**

### Bước 4: Kiểm Tra Kết Nối

```bash
# Kiểm tra ADB nhận điện thoại
adb devices
```

**Kết quả mong đợi:**
```
List of devices attached
XXXXXXXX	device
```

Nếu hiện `unauthorized` → Nhấn "Allow" trên điện thoại.

```bash
# Kiểm tra Flutter nhận điện thoại
flutter devices
```

**Kết quả mong đợi:**
```
3 connected devices:
Redmi Note 12 (mobile) • XXXXXXXX • android-arm64 • Android 13
```

---

## 6. Cấu Hình Firebase

### Bước 1: Tạo Firebase Project

1. Mở trình duyệt, truy cập: https://console.firebase.google.com
2. Đăng nhập bằng tài khoản Google
3. Click **"Create a project"**
4. Nhập tên: `KidGuardian`
5. Bật Google Analytics (miễn phí)
6. Click **"Create project"**

### Bước 2: Thêm Android App

1. Trong Firebase Console, click biểu tượng **Android**
2. Nhập thông tin:
   - **Android package name:** `com.kidguardian.kidguardian`
   - **App nickname:** `KidGuardian`
3. Click **"Register app"**

### Bước 3: Tải google-services.json

1. Click **"Download google-services.json"**
2. Lưu file vào máy

### Bước 4: Copy File Vào Project

```bash
# Giả sử file nằm trong ~/Downloads
cp ~/Downloads/google-services.json /home/minh/CVS/kidguardian-thpt/android/app/
```

### Bước 5: Hoàn Tất Firebase Setup

1. Quay lại Firebase Console
2. Click **"Next"** cho các bước tiếp theo
3. Click **"Continue to console"**

---

## 7. Tạo Flutter Project

### Cách 1: Tạo Mới

```bash
cd /home/minh/CVS/kidguardian-thpt
flutter create --org com.kidguardian --project-name kidguardian .
```

### Cách 2: Sử Dụng Project Có Sẵn

```bash
cd /home/minh/CVS/kidguardian-thpt
flutter pub get
```

---

## 8. Chạy Ứng Dụng

### Kiểm Tra Môi Trường

```bash
flutter doctor
```

**Kết quả mong đợi:**
```
[✓] Flutter (Channel stable, 3.x.x)
[✓] Android toolchain - develop for Android devices
[✓] Connected device (1 available)
```

### Chạy Ứng Dụng

```bash
flutter run
```

**Lần đầu chạy sẽ mất 2-3 phút** để build.

### Chạy Với Hot Reload

Sau khi app chạy:
- Nhấn `r` để hot reload (giữ state)
- Nhấn `R` để hot restart (reset state)
- Nhấn `q` để thoát

---

## 9. Xử Lý Sự Cố

### Sự Cố 1: Điện Thoại Không Hiện

**Nguyên nhân:** Chưa cài ADB hoặc chưa bật USB Debugging

**Giải pháp:**
```bash
# Cài ADB
sudo apt-get install -y android-tools-adb

# Kiểm tra
adb devices
```

### Sự Cố 2: "Unauthorized" Khi Chạy adb devices

**Nguyên nhân:** Chưa cho phép USB debugging

**Giải pháp:**
1. Rút dây USB ra
2. Vào Settings → Developer options → Revoke USB debugging authorizations
3. Cắm lại dây USB
4. Nhấn "Allow" trên điện thoại

### Sự Cố 3: Lỗi Java

**Nguyên nhân:** Java 8 quá cũ

**Giải pháp:**
```bash
# Cài Java 11
sudo apt-get install -y openjdk-11-jdk

# Kiểm tra
java -version
```

### Sự Cố 4: Lỗi Android SDK

**Nguyên nhân:** Chưa cài Android SDK hoặc chưa cấu hình

**Giải pháp:**
```bash
# Cấu hình SDK cho Flutter
flutter config --android-sdk ~/Android/Sdk
```

### Sự Cố 5: Lỗi "google-services.json" Không Tìm Thấy

**Nguyên nhân:** Chưa copy file vào project

**Giải pháp:**
```bash
cp ~/Downloads/google-services.json android/app/
```

### Sự Cố 6: Dây USB Chỉ Sạc, Không Truyền Dữ Liệu

**Nguyên nhân:** Dây USB kém chất lượng

**Giải pháp:**
- Thử dây USB khác
- Dùng dây theo máy hoặc dây Type-C chính hãng

---

## 10. Cheat Sheet

### Lệnh Flutter Phổ Biện

| Lệnh | Mô Tả |
|------|--------|
| `flutter doctor` | Kiểm tra môi trường |
| `flutter devices` | Liệt kê thiết bị |
| `flutter run` | Chạy ứng dụng |
| `flutter build apk` | Build APK |
| `flutter pub get` | Cài dependencies |
| `flutter clean` | Xóa build cache |
| `flutter analyze` | Kiểm tra code |

### Lệnh ADB Phổ Biện

| Lệnh | Mô Tả |
|------|--------|
| `adb devices` | Liệt kê thiết bị |
| `adb install app.apk` | Cài APK |
| `adb logcat` | Xem logs |
| `adb shell` | Mở shell trên điện thoại |

### Phím Tắt Khi Chạy App

| Phím | Mô Tả |
|------|--------|
| `r` | Hot reload |
| `R` | Hot restart |
| `q` | Thoát |
| `h` | Help |

---

## 11. Thông Tin Tham Khảo

- Flutter Docs: https://docs.flutter.dev
- Android Developer: https://developer.android.com
- Firebase Docs: https://firebase.google.com/docs
- ADB Commands: https://developer.android.com/tools/adb

---

**Tác giả:** KidGuardian Team  
**Ngày tạo:** 2026-05-12  
**Đã test trên:** Ubuntu 20.04 + Redmi Note 12
