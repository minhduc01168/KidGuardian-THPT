# HƯỚNG DẪN NHANH CHO HỌC SINH (macOS)

> Bạn đã copy thư mục `thuc-hanh-dang-nhap-dang-ky` về máy? Làm theo các bước dưới đây.

---

## Bước 1: Kiểm tra đã cài Flutter chưa

Mở **Terminal**, gõ:

```bash
flutter --version
```

- **Thấy phiên bản Flutter** → Đã cài, qua Bước 2
- **Thấy lỗi** `command not found` → Chưa cài, làm theo bên dưới

<details>
<summary>Cách cài Flutter trên macOS (bấm để mở rộng)</summary>

**Cách 1: Dùng Homebrew (khuyến khích)**

```bash
# Cài Homebrew (nếu chưa có)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Cài Flutter
brew install --cask flutter
```

**Cách 2: Tải thủ công**

1. Tải Flutter SDK tại: **https://docs.flutter.dev/get-started/install/macos**
2. Giải nén vào thư mục, ví dụ: `~/flutter`
3. Thêm vào PATH:
```bash
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```
4. Kiểm tra: `flutter --version`

</details>

---

## Bước 2: Kiểm tra đã cài Android Studio chưa

Mở **Finder** → Applications → tìm **Android Studio**

- **Tìm thấy** → Đã cài, qua Bước 3
- **Không tìm thấy** → Chưa cài, làm theo bên dưới

<details>
<summary>Cách cài Android Studio trên macOS (bấm để mở rộng)</summary>

```bash
brew install --cask android-studio
```

Hoặc tải tại: **https://developer.android.com/studio**

1. Mở file `.dmg` vừa tải
2. Kéo **Android Studio** vào thư mục **Applications**
3. Mở Android Studio → chọn **Standard** → **OK**
4. Đợi tải SDK (có thể mất 5-10 phút)

</details>

---

## Bước 3: Kiểm tra đã cài emulator chưa

Mở **Android Studio** → **More Actions** → **Device Manager**

- **Thấy emulator** → Đã có, qua Bước 4
- **Danh sách trống** → Chưa có, làm theo bên dưới

<details>
<summary>Cách tạo emulator (bấm để mở rộng)</summary>

1. Trong Device Manager, click **Create Virtual Device**
2. Chọn **Pixel 7** → **Next**
3. Chọn **API 34** (nếu chưa có → click **Download**) → **Next**
4. Click **Finish**
5. Click nút **▶** (Play) để chạy emulator

</details>

---

## Bước 4: Tạo Flutter project

Mở **Terminal**, chạy:

```bash
# Đi đến Desktop
cd ~/Desktop

# Tạo project mới
flutter create auth_practice --org com.example

# Vào thư mục project
cd auth_practice
```

---

## Bước 5: Copy code vào project

Giả sử thư mục `thuc-hanh-dang-nhap-dang-ky` nằm ở `Desktop`. Nếu bạn để chỗ khác, hãy sửa đường dẫn cho đúng.

```bash
# Đang ở thư mục auth_practice (từ Bước 4)

# Copy pubspec.yaml
cp ~/Desktop/thuc-hanh-dang-nhap-dang-ky/pubspec.yaml pubspec.yaml

# Copy thư mục lib
rm -rf lib
cp -r ~/Desktop/thuc-hanh-dang-nhap-dang-ky/lib lib
```

**Nếu để chỗ khác** (ví dụ Documents):

```bash
# Ví dụ: thư mục nằm ở ~/Documents/thuc-hanh-dang-nhap-dang-ky
cp ~/Documents/thuc-hanh-dang-nhap-dang-ky/pubspec.yaml pubspec.yaml
rm -rf lib
cp -r ~/Documents/thuc-hanh-dang-nhap-dang-ky/lib lib
```

**Kiểm tra copy thành công:**

```bash
ls lib/screens/
```

Phải thấy 4 file:
```
login_screen.dart    register_screen.dart    home_screen.dart    forgot_password_screen.dart
```

---

## Bước 6: Cài dependencies

```bash
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

```bash
cp ~/Downloads/google-services.json android/app/google-services.json
```

7. Click **Next** → **Next** → **Continue to console**

---

## Bước 10: Cài FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

**Nếu báo lỗi** `command not found`:

```bash
echo 'export PATH="$PATH":"$HOME/.pub-cache/bin"' >> ~/.zshrc
source ~/.zshrc

# Chạy lại:
flutterfire --version
```

---

## Bước 11: Cấu hình Firebase cho project

```bash
# Đảm bảo đang ở thư mục auth_practice
flutterfire configure
```

- Dùng mũi tên lên/xuống chọn **AuthPractice** → Enter
- Dùng Space chọn **android** → Enter

Thấy `firebase_options.dart generated successfully` là được.

---

## Bước 12: Chạy ứng dụng

```bash
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

## Lỗi thường gặp trên macOS

| Lỗi | Cách sửa |
|-----|----------|
| `command not found: flutter` | Thêm Flutter vào PATH, restart Terminal |
| `command not found: emulator` | Mở Android Studio → SDK Manager → SDK Tools → tick Android Emulator |
| `command not found: flutterfire` | Xem Bước 10 |
| `google-services.json not found` | Copy file vào `android/app/` |
| `Unable to find a suitable Java version` | Cài Java: `brew install --cask temurin` |
| Emulator không khởi động | Mở Android Studio → Device Manager → ▶ |
| `INSTALL_FAILED_INVALID_APK` | Chạy `flutter clean` rồi `flutter run` lại |
