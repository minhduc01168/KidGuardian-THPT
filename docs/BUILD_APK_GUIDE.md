# Hướng Dẫn Build APK & Tối Ưu Dung Lượng (KidGuardian)

Tài liệu này hướng dẫn cách build ứng dụng KidGuardian trên máy tính local (Linux/macOS/Windows) để cài đặt test trên thiết bị thật, các kỹ thuật **tối ưu dung lượng ứng dụng từ 72.7MB xuống ~25MB**, và xử lý các sự cố thường gặp (tràn RAM).

---

## 🚀 Hướng Dẫn Build APK Từng Bước

### Bước 1: Mở Terminal và trỏ vào thư mục project
```bash
cd ~/KidGuardian-THPT
```

### Bước 2: Cập nhật biến môi trường Flutter (nếu cần)
Nếu terminal báo `flutter: command not found`:
```bash
export PATH="$PATH:$HOME/.flutter-sdk/flutter/bin"
```

### Bước 3: Cập nhật mã nguồn mới nhất
```bash
git pull origin develop
```

### Bước 4: Dọn dẹp cache và tải dependency
```bash
flutter clean
flutter pub get
```

### Bước 5: Thực hiện Build APK Tối Ưu

> 💡 **LƯU Ý QUAN TRỌNG VỀ DUNG LƯỢNG:** 
> * **KHÔNG nên dùng lệnh mặc định `flutter build apk --release`**: Lệnh này tạo ra một file **FAT APK** chứa cùng lúc cả 3 bộ mã chip (`arm64-v8a`, `armeabi-v7a`, `x86_64`), khiến dung lượng phình to lên tới **72.7MB**.
> * **NÊN dùng cờ `--split-per-abi`**: Tách thành các file APK riêng biệt cho từng dòng chip, giúp giảm dung lượng xuống còn **~25MB** (giảm 65% dung lượng).

#### 🟢 Lựa chọn 1: Build APK tiêu chuẩn tách theo chip (Khuyên dùng khi test manual)
```bash
flutter build apk --release --split-per-abi
```

#### 🔵 Lựa chọn 2: Build APK tối ưu tối đa (Làm gọn code & Mã hóa)
```bash
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/app/outputs/symbols
```
*(Giúp giảm thêm khoảng 3MB - 5MB mã bytecode).*

#### 🔴 Lựa chọn 3: Build App Bundle (`.aab`) để phát hành lên Google Play Store
```bash
flutter build appbundle --release
```
*(Google Play Store sẽ tự động phân phối phiên bản siêu nhỏ ~19MB đến máy người dùng).*

---

## 📂 Vị Trí File APK Sau Khi Build & Hướng Dẫn Chọn File Cài Đặt

Sau khi chạy lệnh `flutter build apk --release --split-per-abi` thành công, các file APK nằm tại thư mục:
`build/app/outputs/flutter-apk/`

| Tên File APK | Dung lượng | Thiết bị tương thích |
| :--- | :---: | :--- |
| **`app-arm64-v8a-release.apk`** | **~25 MB** | **98% Smartphone Android hiện nay (Khuyên dùng để gửi cài test máy thật)** |
| `app-armeabi-v7a-release.apk` | ~22 MB | Điện thoại Android đời cũ (32-bit ARM) |
| `app-x86_64-release.apk` | ~27 MB | Máy ảo Android (Android Studio / Emulator) |
| `app-release.apk` (FAT APK) | 72.7 MB | Chứa cả 3 loại chip (Chỉ dùng khi không biết thiết bị thuộc loại chip nào) |

---

## 📊 Bảng So Sánh Chi Tiết Các Phương Pháp Build

| Lệnh Build | Dung lượng | Tỷ lệ giảm | Mục đích sử dụng |
| :--- | :---: | :---: | :--- |
| `flutter build apk --release` | **72.7 MB** | 0% | FAT APK chứa mọi chip (Quá nặng) |
| `flutter build apk --release --split-per-abi` | **~25 MB** | **📉 Giảm ~65%** | **Cài đặt trực tiếp máy thật để test nhanh** |
| `flutter build apk --release --split-per-abi --obfuscate` | **~21 MB** | **📉 Giảm ~71%** | Tối ưu tối đa mã nguồn cho file APK |
| `flutter build appbundle --release` | **~19 MB** | **📉 Giảm ~74%** | Upload phát hành chính thức lên CH Play |

---

## 🛠 Xử Lý Các Sự Cố Thường Gặp

### 1. Lỗi "Gradle build daemon disappeared unexpectedly" (Lỗi tràn RAM)
**Nguyên nhân:** Gradle mặc định đòi hỏi nhiều bộ nhớ RAM, nếu máy có 8GB RAM tổng sẽ bị OS tắt ngang tiến trình.

**Cách xử lý:**
Giới hạn RAM cho Gradle trong `android/gradle.properties`:
```properties
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
```
Sau đó dừng daemon Gradle cũ và build lại:
```bash
cd android && ./gradlew --stop && cd ..
flutter build apk --release --split-per-abi
```

### 2. Lỗi "Conflicting overloads" (Trùng lặp hàm Native Kotlin)
**Nguyên nhân:** Khi merge code bị lặp lại hàm trong file Kotlin (ví dụ `AppMonitorService.kt`).

**Cách xử lý:**
Mở file Kotlin được báo lỗi trong log, tìm và xóa bỏ đoạn hàm bị trùng lặp, sau đó build lại.
