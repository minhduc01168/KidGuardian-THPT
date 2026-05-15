# Hướng dẫn kết nối thiết bị Android để Debug

**Thiết bị:** Redmi Note 12  
**Cập nhật:** 2026-05-13

---

## 1. Chuẩn bị điện thoại

### Bật Developer Options
1. Vào **Settings** → **About phone**
2. Nhấn **7 lần** vào **MIUI version** cho đến khi thấy "You are now a developer"

### Bật các tùy chọn Developer
1. Vào **Settings** → **Additional settings** → **Developer options**
2. Bật các tùy chọn sau:

| Tùy chọn | Mô tả |
|----------|-------|
| **USB debugging** | Cho phép debug qua USB |
| **USB debugging (Security settings)** | **QUAN TRỌNG** cho Xiaomi/Redmi |
| **Install via USB** | Cho phép cài app qua USB |
| **USB debugging (Security settings)** | Xác nhận khi có thông báo |

---

## 2. Kết nối qua USB (Khuyến nghị)

### Bước 1: Kết nối cáp USB
```bash
# Cắm cáp USB vào điện thoại và máy tính
# Trên điện thoại: Nhấn "Allow" khi hiện thông báo "Allow USB debugging?"
```

### Bước 2: Kiểm tra kết nối
```bash
adb devices
```

Output mong đợi:
```
List of devices attached
81afa5bc0013    device
```

### Bước 3: Chạy ứng dụng
```bash
# Chạy trên thiết bị đã kết nối
flutter run -d 81afa5bc0013

# Hoặc nếu chỉ có 1 thiết bị
flutter run
```

---

## 3. Kết nối qua WiFi

### Bước 1: Bật TCP/IP qua USB
```bash
# Đảm bảo điện thoại đang kết nối USB
# Chỉ định thiết bị nếu có nhiều thiết bị
adb -s 81afa5bc0013 tcpip 5555
```

### Bước 2: Tìm IP điện thoại
1. Vào **Settings** → **About phone** → **All specs** → **IP address**
2. Hoặc: **Settings** → **Wi-Fi** → Nhấn vào mạng đang kết nối → Xem IP address

### Bước 3: Kết nối WiFi
```bash
# Tháo cáp USB
# Kết nối qua WiFi (thay IP_ADDRESS bằng IP điện thoại)
adb connect <IP_ADDRESS>:5555

# Ví dụ:
adb connect 192.168.1.179:5555
```

### Bước 4: Kiểm tra kết nối
```bash
adb devices
```

Output mong đợi:
```
List of devices attached
192.168.1.179:5555    device
```

### Bước 5: Chạy ứng dụng
```bash
flutter run -d 192.168.1.179:5555
```

---

## 4. Xử lý lỗi thường gặp

### Lỗi: "License not accepted" cho NDK

**Triệu chứng:**
```
FAILURE: Build failed with an exception.
> com.android.builder.sdk.LicenceNotAcceptedException: Failed to install the following SDK packages as some licences have not been accepted.
     ndk;28.2.13676358 NDK (Side by side) 28.2.13676358
```

**Giải pháp:**
```bash
# Chấp nhận license thủ công
sudo mkdir -p /usr/lib/android-sdk/licenses
echo -e "\n24333f8a63b6825ea9c5514f83c2829b004d1fee" | sudo tee -a /usr/lib/android-sdk/licenses/android-sdk-license
echo -e "\n84831b9409646a918e30573bab4c9c91346d8abd" | sudo tee -a /usr/lib/android-sdk/licenses/android-sdk-license
echo -e "\nd56f5187479451eabf01fb78af6dfcb131a6481e" | sudo tee -a /usr/lib/android-sdk/licenses/android-sdk-license
```

### Lỗi: "SDK directory is not writable"

**Triệu chứng:**
```
FAILURE: Build failed with an exception.
> com.android.builder.sdk.InstallFailedException: Failed to install the following SDK components:
      ndk;28.2.13676358 NDK (Side by side) 28.2.13676358
  The SDK directory is not writable (/usr/lib/android-sdk)
```

**Giải pháp:**
```bash
# Cấp quyền ghi cho thư mục SDK
sudo chmod -R 777 /usr/lib/android-sdk

# Chạy lại
flutter run -d 81afa5bc0013
```

**Hoặc chuyển SDK sang thư mục user:**
```bash
# Tạo thư mục SDK mới
mkdir -p ~/Android/sdk

# Copy SDK hiện tại
sudo cp -r /usr/lib/android-sdk/* ~/Android/sdk/

# Cấp quyền
chmod -R 755 ~/Android/sdk

# Cấu hình Flutter dùng SDK mới
flutter config --android-sdk ~/Android/sdk

# Chạy lại
flutter run -d 81afa5bc0013
```

### Lỗi: "offline" khi kết nối WiFi
```bash
# Ngắt kết nối offline
adb disconnect

# Kill ADB server
adb kill-server

# Start lại
adb start-server

# Kết nối lại
adb connect <IP_ADDRESS>:5555
```

### Lỗi: "more than one device/emulator"
```bash
# Liệt kê thiết bị
adb devices

# Chỉ định thiết cụ thể
adb -s <DEVICE_ID> <command>

# Ví dụ:
adb -s 81afa5bc0013 tcpip 5555
```

### Lỗi: "Connection refused"
```bash
# Thử port khác
adb connect <IP_ADDRESS>:40049

# Hoặc kết nối lại qua USB và bật TCP/IP lại
adb -s 81afa5bc0013 tcpip 5555
```

### Mất kết nối WiFi
```bash
# Kết nối lại
adb connect <IP_ADDRESS>:5555

# Nếu không được, kết nối USB lại và chạy
adb -s 81afa5bc0013 tcpip 5555
```

---

## 5. Debug trong quá trình phát triển

### Hot Reload
Khi ứng dụng đang chạy, trong terminal nhấn:
- `r` → Hot Reload (tải lại code nhanh)
- `R` → Hot Restart (khởi động lại app)
- `q` → Thoát

### Xem Logs
```bash
# Flutter logs
flutter logs

# ADB logcat
adb logcat -s flutter

# Logcat với filter
adb logcat | grep "flutter"
```

### Chạy với debug mode
```bash
# Debug mode (mặc định)
flutter run

# Release mode
flutter run --release

# Profile mode
flutter run --profile
```

---

## 6. Kiểm tra thiết bị

```bash
# Liệt kê tất cả thiết bị
flutter devices

# Thông tin chi tiết thiết bị
adb -s <DEVICE_ID> shell getprop ro.product.model

# Kiểm tra Android version
adb -s <DEVICE_ID> shell getprop ro.build.version.release
```

---

## 7. Mẹo hữu ích

### Sử dụng USB thay vì WiFi
- USB ổn định hơn WiFi
- Tốc độ truyền dữ liệu nhanh hơn
- Không lo mất kết nối

### Đặt alias trong ~/.bashrc
```bash
# Thêm vào ~/.bashrc
alias adb-connect='adb connect 192.168.1.179:5555'
alias adb-devices='adb devices'
alias flutter-run='flutter run -d 81afa5bc0013'
```

### Kiểm tra kết nối nhanh
```bash
# Script kiểm tra nhanh
#!/bin/bash
echo "=== Kiểm tra thiết bị ==="
adb devices
echo ""
echo "=== Flutter devices ==="
flutter devices
```

---

## 8. Debug các tính năng

### Epic 1: Authentication & Profile

| Tính năng | Cách test |
|-----------|-----------|
| Register | Mở app → Chọn "Phụ huynh" → Đăng ký email mới |
| Login | Đăng nhập với email đã đăng ký |
| Create Child | Dashboard → "Thêm con" → Nhập tên, tuổi |
| Link Child | Tạo child khác → Nhập mã liên kết |
| Child Login | Đăng xuất → Đăng nhập tài khoản child |
| Logout | Settings → Đăng xuất |
| Reset Password | Login → "Quên mật khẩu?" |
| Profile | Nhấn icon Profile → Chỉnh sửa tên |

### Epic 2: Dashboard & Monitoring

| Tính năng | Cách test |
|-----------|-----------|
| Dashboard | Đăng nhập parent → Xem tổng quan |
| Usage Chart | Kéo xuống → Xem biểu đồ (Ngày/Tuần) |
| App List | Xem danh sách ứng dụng → Nhấn để xem chi tiết |
| Child Dashboard | Đăng nhập child → Xem thời gian còn lại |
| Daily Summary | Dashboard → "Tổng kết" |
| Weekly Report | Dashboard → "Báo cáo tuần" → Tạo báo cáo |

---

## 9. Quá trình debug thực tế (Redmi Note 12)

### Thiết bị đã test thành công
- **Model:** Redmi Note 12 (2209116AG)
- **Device ID:** 81afa5bc0013
- **Kết nối:** USB

### Các lỗi đã gặp và cách khắc phục

| Lỗi | Nguyên nhân | Giải pháp |
|-----|-------------|-----------|
| `License not accepted` | Chưa chấp nhận SDK license | Chấp nhận license thủ công (xem mục 4) |
| `SDK directory is not writable` | Không có quyền ghi vào thư mục SDK | `sudo chmod -R 777 /usr/lib/android-sdk` |
| `offline` khi kết nối WiFi | Xiaomi/Redmi cần bật Security settings | Bật "USB debugging (Security settings)" |
| `more than one device` | Có nhiều thiết bị kết nối | Chỉ định thiết bị: `adb -s <ID> <command>` |

### Log thành công
```
Launching lib/main.dart on 2209116AG in debug mode...
Checking the license for package NDK (Side by side) 28.2.13676358 in /usr/lib/android-sdk/licenses
License for package NDK (Side by side) 28.2.13676358 accepted.
Preparing "Install NDK (Side by side) 28.2.13676358 v.28.2.13676358".
"Install NDK (Side by side) 28.2.13676358 v.28.2.13676358" ready.
Installing NDK (Side by side) 28.2.13676358 in /usr/lib/android-sdk/ndk/28.2.13676358
"Install NDK (Side by side) 28.2.13676358 v.28.2.13676358" complete.
"Install NDK (Side by side) 28.2.13676358 v.28.2.13676358" finished.
```

---

**Người tạo:** Dev Team  
**Cập nhật lần cuối:** 2026-05-13
