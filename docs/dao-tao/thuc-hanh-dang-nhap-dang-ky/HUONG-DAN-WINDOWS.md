# HƯỚNG DẪN NHANH CHO HỌC SINH (WINDOWS)

> Bạn đã copy thư mục `thuc-hanh-dang-nhap-dang-ky` về máy? Làm theo các bước dưới đây.

---

## Bước 1: Kiểm tra đã cài Flutter chưa

Mở **PowerShell** hoặc **Command Prompt**, gõ:

```powershell
flutter --version
```

- **Thấy phiên bản Flutter** → Đã cài, qua Bước 2
- **Thấy lỗi** `'flutter' is not recognized` → Chưa cài, làm theo bên dưới

<details>
<summary>Cách cài Flutter trên Windows (bấm để mở rộng)</summary>

1. Tải Flutter SDK tại: **https://docs.flutter.dev/get-started/install/windows**
2. Click nút "Download Flutter SDK" (file `.zip`)
3. Giải nén vào ổ `C:\flutter` (hoặc bất kỳ đâu, nhưng KHÔNG có dấu tiếng Việt trong đường dẫn)
4. Thêm Flutter vào PATH:
   - Nhấn phím **Windows**, gõ `env`, chọn **"Edit the system environment variables"**
   - Click **Environment Variables**
   - Ở mục **User variables**, chọn **Path** → click **Edit** → **New**
   - Nhập: `C:\flutter\bin`
   - Click **OK** ở tất cả cửa sổ
5. **Đóng và mở lại** PowerShell
6. Kiểm tra: `flutter --version`

</details>

---

## Bước 2: Kiểm tra đã cài Android Studio chưa

Mở **Android Studio** (tìm trong Start Menu).

- **Mở được** → Đã cài, qua Bước 3
- **Không tìm thấy** → Chưa cài, làm theo bên dưới

<details>
<summary>Cách cài Android Studio trên Windows (bấm để mở rộng)</summary>

1. Tải tại: **https://developer.android.com/studio**
2. Chạy file `.exe` vừa tải
3. Click **Next** → **Next** → chọn đường dẫn mặc định → **Next** → **Install**
4. Đợi cài xong → click **Finish**
5. Mở Android Studio → chọn **Standard** → click **OK**
6. Đợi Android Studio tải SDK (có thể mất 5-10 phút)

</details>

---

## Bước 3: Kiểm tra đã cài emulator chưa

Mở **Android Studio** → **More Actions** → **Device Manager**

- **Thấy emulator trong danh sách** → Đã có, qua Bước 4
- **Danh sách trống** → Chưa có, làm theo bên dưới

<details>
<summary>Cách tạo emulator (bấm để mở rộng)</summary>

1. Trong Device Manager, click **Create Virtual Device**
2. Chọn **Pixel 7** → click **Next**
3. Nếu thấy **API 34** → chọn nó → **Next**
4. Nếu chưa có API 34 → click **Download** bên cạnh dòng API 34 → đợi tải xong → chọn → **Next**
5. Click **Finish**
6. Click nút **▶** (Play) để chạy emulator
7. Đợi emulator hiện ra (lần đầu có thể mất 1-2 phút)

</details>

---

## Bước 4: Tạo Flutter project

Mở **PowerShell**, chạy từng lệnh sau:

```powershell
# Đi đến Desktop (hoặc bất kỳ đâu bạn muốn)
cd $env:USERPROFILE\Desktop

# Tạo project mới
flutter create auth_practice --org com.example

# Vào thư mục project
cd auth_practice
```

---

## Bước 5: Copy code vào project

Giả sử thư mục `thuc-hanh-dang-nhap-dang-ky` nằm ở `Desktop`. Nếu bạn để chỗ khác, hãy sửa đường dẫn cho đúng.

**Mở PowerShell**, chạy:

```powershell
# Đang ở thư mục auth_practice (từ Bước 4)

# Copy pubspec.yaml
Copy-Item "$env:USERPROFILE\Desktop\thuc-hanh-dang-nhap-dang-ky\pubspec.yaml" "pubspec.yaml" -Force

# Copy thư mục lib
Remove-Item -Recurse -Force "lib"
Copy-Item -Recurse "$env:USERPROFILE\Desktop\thuc-hanh-dang-nhap-dang-ky\lib" "lib"
```

**Nếu để chỗ khác** (ví dụ ổ D:), sửa đường dẫn:

```powershell
# Ví dụ: thư mục nằm ở D:\hoc\tap\thuc-hanh-dang-nhap-dang-ky
Copy-Item "D:\hoc\tap\thuc-hanh-dang-nhap-dang-ky\pubspec.yaml" "pubspec.yaml" -Force
Remove-Item -Recurse -Force "lib"
Copy-Item -Recurse "D:\hoc\tap\thuc-hanh-dang-nhap-dang-ky\lib" "lib"
```

**Kiểm tra copy thành công:**

```powershell
dir lib\screens
```

Phải thấy 4 file:
```
login_screen.dart
register_screen.dart
home_screen.dart
forgot_password_screen.dart
```

---

## Bước 6: Cài dependencies

```powershell
flutter pub get
```

Thấy `Changed X dependencies!` là được.

---

## Bước 7: Tạo Firebase project

1. Mở trình duyệt, vào: **https://console.firebase.google.com**
2. Đăng nhập bằng tài khoản Google
3. Click **"Add project"**
4. Nhập tên: `AuthPractice`
5. Bật/tắt Google Analytics → bỏ qua cũng được → **Create project**
6. Đợi xong → **Continue**

---

## Bước 8: Bật Email/Password trong Firebase

1. Trong Firebase Console, click project `AuthPractice`
2. Menu trái → **Authentication**
3. Tab **Sign-in method** → click **Email/Password**
4. Bật công tắc **Enable** → **Save**

---

## Bước 9: Tải google-services.json

1. Trong Firebase Console, click logo Firebase góc trái (về trang chủ project)
2. Click biểu tượng **Android** (hình robot)
3. **Android package name**: gõ `com.example.authpractice`
   > ⚠️ Chữ `p` phải viết **THƯỜNG**, không phải `authPractice`
4. Click **Register app**
5. Click **Download google-services.json**
6. Copy file vừa tải vào project:

```powershell
Copy-Item "$env:USERPROFILE\Downloads\google-services.json" "android\app\google-services.json"
```

7. Click **Next** → **Next** → **Continue to console**

---

## Bước 10: Cài FlutterFire CLI

```powershell
dart pub global activate flutterfire_cli
```

**Nếu báo lỗi** `'flutterfire' is not recognized`:

```powershell
# Thêm vào PATH
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$env:USERPROFILE\AppData\Local\Pub\Cache\bin", "User")

# ĐÓNG và MỞ LẠI PowerShell, rồi chạy lại:
flutterfire --version
```

---

## Bước 11: Cấu hình Firebase cho project

```powershell
# Đảm bảo đang ở thư mục auth_practice
flutterfire configure
```

- Dùng mũi tên lên/xuống chọn **AuthPractice** → Enter
- Dùng Space chọn **android** → Enter

Thấy `firebase_options.dart generated successfully` là được.

---

## Bước 12: Chạy ứng dụng

```powershell
flutter run
```

Nếu có nhiều thiết bị, chọn emulator hoặc điện thoại.

**Thấy màn hình đăng nhập với icon khóa xanh là thành công!**

---

## Tóm tắt thứ tự

```
flutter --version          ← Kiểm tra Flutter
Android Studio             ← Kiểm tra Android Studio
Tạo emulator               ← Nếu chưa có
flutter create             ← Tạo project
Copy pubspec.yaml + lib/   ← Copy code thực hành
flutter pub get            ← Cài dependencies
Firebase Console           ← Tạo project + bật Auth + tải google-services.json
flutterfire configure      ← Cấu hình Firebase
flutter run                ← Chạy!
```

---

## Lỗi thường gặp trên Windows

| Lỗi | Cách sửa |
|-----|----------|
| `'flutter' is not recognized` | Thêm `C:\flutter\bin` vào PATH, restart PowerShell |
| `'emulator' is not recognized` | Mở Android Studio → SDK Manager → SDK Tools → tick Android Emulator |
| `'flutterfire' is not recognized` | Xem Bước 10 |
| `google-services.json not found` | Copy file vào `android\app\` |
| `Unable to find a suitable Java version` | Cài Java: trong Android Studio → Settings → Languages → JDK |
| Emulator không khởi động | Mở Android Studio → Device Manager → ▶ |
| `INSTALL_FAILED_INVALID_APK` | Chạy `flutter clean` rồi `flutter run` lại |
