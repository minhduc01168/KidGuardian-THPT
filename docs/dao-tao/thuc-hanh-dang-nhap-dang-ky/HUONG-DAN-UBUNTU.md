# HƯỚNG DẪN NHANH CHO HỌC SINH (UBUNTU / LINUX)

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
<summary>Cách cài Flutter trên Ubuntu (bấm để mở rộng)</summary>

```bash
# Cài các gói phụ thuộc
sudo apt-get update
sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa

# Tải Flutter
cd ~
git clone https://github.com/flutter/flutter.git -b stable

# Thêm Flutter vào PATH
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Kiểm tra
flutter --version
```

</details>

---

## Bước 2: Kiểm tra đã cài Android Studio chưa

```bash
which android-studio
```

- **Thấy đường dẫn** → Đã cài, qua Bước 3
- **Không thấy** → Chưa cài, làm theo bên dưới

<details>
<summary>Cách cài Android Studio trên Ubuntu (bấm để mở rộng)</summary>

**Cách 1: Dùng Snap (khuyến khích)**

```bash
sudo snap install android-studio --classic
```

**Cách 2: Dùng apt**

```bash
sudo apt-get install -y snapd
sudo snap install android-studio --classic
```

**Cách 3: Tải thủ công**

1. Tải tại: **https://developer.android.com/studio** (file `.tar.gz`)
2. Giải nén:
```bash
cd ~/Downloads
tar -xzf android-studio-*.tar.gz -C ~/
```
3. Chạy:
```bash
~/android-studio/bin/studio.sh
```

Sau khi cài:
1. Mở Android Studio → chọn **Standard** → **OK**
2. Đợi tải SDK (có thể mất 5-10 phút)

</details>

---

## Bước 3: Cấu hình Android SDK và PATH

Mở **Android Studio** → **Settings** → **Languages & Frameworks** → **Android SDK**

1. Tab **SDK Platforms**: tick chọn **Android 14 (API 34)**
2. Tab **SDK Tools**: tick chọn:
   - Android SDK Build-Tools
   - Android SDK Command-line Tools
   - Android Emulator
   - Android SDK Platform-Tools
3. Click **Apply** → đợi tải xong

Thêm Android SDK vào PATH:

```bash
echo 'export ANDROID_HOME="$HOME/Android/Sdk"' >> ~/.bashrc
echo 'export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

---

## Bước 4: Kiểm tra đã cài emulator chưa

```bash
emulator -list-avds
```

- **Thấy tên emulator** → Đã có, qua Bước 5
- **Danh sách trống** → Chưa có, làm theo bên dưới

<details>
<summary>Cách tạo emulator (bấm để mở rộng)</summary>

1. Mở Android Studio → **More Actions** → **Device Manager**
2. Click **Create Virtual Device**
3. Chọn **Pixel 7** → **Next**
4. Chọn **API 34** (nếu chưa có → click **Download**) → **Next**
5. Click **Finish**
6. Click nút **▶** (Play) để chạy emulator

**Nếu emulator báo lỗi KVM:**

```bash
sudo apt-get install -y qemu-kvm
sudo adduser $USER kvm
```

Sau đó **đăng xuất và đăng nhập lại** máy tính.

</details>

---

## Bước 5: Tạo Flutter project

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

## Bước 6: Copy code vào project

Giả sử thư mục `thuc-hanh-dang-nhap-dang-ky` nằm ở `Desktop`. Nếu bạn để chỗ khác, hãy sửa đường dẫn cho đúng.

```bash
# Đang ở thư mục auth_practice (từ Bước 5)

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

## Bước 7: Cài dependencies

```bash
flutter pub get
```

Thấy `Changed X dependencies!` là được.

---

## Bước 8: Tạo Firebase project

1. Mở trình duyệt, vào: **https://console.firebase.google.com**
2. Đăng nhập bằng tài khoản Google
3. Click **"Add project"**
4. Nhập tên: `AuthPractice`
5. Bật/tắt Google Analytics → bỏ qua cũng được → **Create project**
6. Đợi xong → **Continue**

---

## Bước 9: Bật Email/Password trong Firebase

1. Trong Firebase Console, click project `AuthPractice`
2. Menu trái → **Authentication**
3. Tab **Sign-in method** → click **Email/Password**
4. Bật công tắc **Enable** → **Save**

---

## Bước 10: Tải google-services.json

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

## Bước 11: Cài FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

**Nếu báo lỗi** `command not found`:

```bash
echo 'export PATH="$PATH":"$HOME/.pub-cache/bin"' >> ~/.bashrc
source ~/.bashrc

# Chạy lại:
flutterfire --version
```

---

## Bước 12: Cấu hình Firebase cho project

```bash
# Đảm bảo đang ở thư mục auth_practice
flutterfire configure
```

- Dùng mũi tên lên/xuống chọn **AuthPractice** → Enter
- Dùng Space chọn **android** → Enter

Thấy `firebase_options.dart generated successfully` là được.

---

## Bước 13: Chạy ứng dụng

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
Cấu hình SDK + PATH        ← Bước 3
Tạo emulator               ← Nếu chưa có
flutter create             ← Tạo project
Copy pubspec.yaml + lib/   ← Copy code thực hành
flutter pub get            ← Cài dependencies
Firebase Console           ← Tạo project + bật Auth + tải google-services.json
flutterfire configure      ← Cấu hình Firebase
flutter run                ← Chạy!
```

---

## Lỗi thường gặp trên Ubuntu

| Lỗi | Cách sửa |
|-----|----------|
| `command not found: flutter` | Thêm Flutter vào PATH, `source ~/.bashrc` |
| `command not found: emulator` | Xem Bước 3 - thêm Android SDK vào PATH |
| `command not found: flutterfire` | Xem Bước 11 |
| `google-services.json not found` | Copy file vào `android/app/` |
| `Unable to find a suitable Java version` | `sudo apt-get install openjdk-17-jdk` |
| Emulator báo lỗi KVM | `sudo apt-get install qemu-kvm && sudo adduser $USER kvm`, đăng xuất/đăng nhập lại |
| `INSTALL_FAILED_INVALID_APK` | Chạy `flutter clean` rồi `flutter run` lại |
| `snap: command not found` | `sudo apt-get install snapd` |
