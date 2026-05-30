# THỰC HÀNH: Đăng Ký & Đăng Nhập với Firebase Auth

## Mục tiêu

Xây dựng tính năng **đăng ký** và **đăng nhập** bằng Email/Password sử dụng Firebase Authentication trong Flutter.

---

## Hướng dẫn nhanh theo hệ điều hành

> Đã copy thư mục về máy? Chọn đúng hệ điều hành của bạn:

| Hệ điều hành | File hướng dẫn |
|---------------|---------------|
| **Windows** | [HUONG-DAN-WINDOWS.md](HUONG-DAN-WINDOWS.md) |
| **macOS** | [HUONG-DAN-MACOS.md](HUONG-DAN-MACOS.md) |
| **Ubuntu / Linux** | [HUONG-DAN-UBUNTU.md](HUONG-DAN-UBUNTU.md) |

Các file hướng dẫn nhanh trên **đơn giản hóa từng bước**, phù hợp cho người chưa từng cài Flutter.

---

## Phần 0: Cài đặt môi trường (chi tiết)

> Nếu máy bạn **đã cài Flutter rồi**, bỏ qua phần này, chạy `flutter doctor` để kiểm tra rồi qua Phần 1.

### Windows

**Bước 0.1: Cài Flutter SDK**

1. Tải Flutter SDK tại: https://docs.flutter.dev/get-started/install/windows
2. Giải nén vào thư mục, ví dụ: `C:\flutter`
3. Thêm Flutter vào PATH:
   - Mở Start → tìm "Environment Variables" → click "Edit the system environment variables"
   - Click **Environment Variables**
   - Ở mục **User variables**, chọn **Path** → click **Edit** → **New**
   - Nhập: `C:\flutter\bin`
   - Click **OK** ở tất cả cửa sổ
4. **Đóng và mở lại** Command Prompt / PowerShell
5. Kiểm tra: `flutter --version`

**Bước 0.2: Cài Android Studio**

1. Tải Android Studio tại: https://developer.android.com/studio
2. Chạy file cài đặt, để mặc định, click Next cho đến khi xong
3. Mở Android Studio → chọn **Standard** installation
4. Đợi Android Studio tải xong Android SDK

**Bước 0.3: Cấu hình Android SDK**

1. Mở Android Studio → menu **More Actions** (hoặc Tools) → **SDK Manager**
2. Tab **SDK Platforms**: tick chọn **Android 14 (API 34)**
3. Tab **SDK Tools**: tick chọn:
   - Android SDK Build-Tools
   - Android SDK Command-line Tools
   - Android Emulator
   - Android SDK Platform-Tools
4. Click **Apply** → đợi tải xong

**Bước 0.4: Tạo Android Emulator**

1. Mở Android Studio → **More Actions** → **Device Manager**
2. Click **Create Virtual Device**
3. Chọn **Pixel 7** → click **Next**
4. Chọn **API 34** (nếu chưa có, click "Download" bên cạnh) → click **Next**
5. Để mặc định → click **Finish**
6. Click nút ▶ (Play) để chạy emulator

**Bước 0.5: Kiểm tra**

Mở Command Prompt / PowerShell, chạy:

```powershell
flutter doctor
```

Kết quả mong đợi:
```
[✓] Flutter (Channel stable, 3.x.x)
[✓] Windows Version (Installed version of Windows is version 10 or higher)
[✓] Android toolchain - develop for Android devices
[✓] Android Studio
[✓] VS Code (nếu dùng)
```

> Nếu có dấu [✗], đọc dòng hướng dẫn phía dưới nó và làm theo.

---

### macOS

**Bước 0.1: Cài Homebrew** (nếu chưa có)

Mở Terminal, chạy:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Sau khi cài xong:
```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

**Bước 0.2: Cài Flutter SDK**

```bash
brew install --cask flutter
```

Hoặc tải tại: https://docs.flutter.dev/get-started/install/macos

**Bước 0.3: Cài Android Studio**

```bash
brew install --cask android-studio
```

1. Mở Android Studio → chọn **Standard** installation
2. Đợi tải Android SDK xong

**Bước 0.4: Cấu hình Android SDK**

1. Mở Android Studio → menu **Android Studio** → **Settings** → **Languages & Frameworks** → **Android SDK**
2. Tab **SDK Platforms**: tick chọn **Android 14 (API 34)**
3. Tab **SDK Tools**: tick chọn:
   - Android SDK Build-Tools
   - Android SDK Command-line Tools
   - Android Emulator
   - Android SDK Platform-Tools
4. Click **Apply** → đợi tải xong

**Bước 0.5: Tạo Android Emulator**

1. Mở Android Studio → **More Actions** → **Device Manager**
2. Click **Create Virtual Device**
3. Chọn **Pixel 7** → click **Next**
4. Chọn **API 34** (nếu chưa có, click "Download" bên cạnh) → click **Next**
5. Để mặc định → click **Finish**
6. Click nút ▶ (Play) để chạy emulator

**Bước 0.6: Cài Xcode** (chỉ cần khi muốn chạy iOS)

1. Mở App Store → tìm **Xcode** → cài đặt
2. Sau khi cài, mở Terminal chạy:
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

**Bước 0.7: Kiểm tra**

```bash
flutter doctor
```

Kết quả mong đợi:
```
[✓] Flutter (Channel stable, 3.x.x)
[✓] macOS (Version xx.x)
[✓] Xcode - develop for iOS and macOS (nếu cài Xcode)
[✓] Android toolchain - develop for Android devices
[✓] Android Studio
[✓] VS Code (nếu dùng)
```

---

### Ubuntu / Linux

**Bước 0.1: Cài các gói phụ thuộc**

Mở Terminal:

```bash
sudo apt-get update
sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa
```

**Bước 0.2: Cài Flutter SDK**

```bash
# Tải Flutter
cd ~
git clone https://github.com/flutter/flutter.git -b stable

# Thêm Flutter vào PATH
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Kiểm tra:
```bash
flutter --version
```

**Bước 0.3: Cài Android Studio**

```bash
sudo snap install android-studio --classic
```

Nếu không có `snap`:
```bash
sudo apt-get install -y snapd
sudo snap install android-studio --classic
```

Hoặc tải tại: https://developer.android.com/studio (file `.tar.gz`)

1. Mở Android Studio → chọn **Standard** installation
2. Đợi tải Android SDK xong

**Bước 0.4: Cấu hình Android SDK**

1. Mở Android Studio → menu **Android Studio** → **Settings** → **Languages & Frameworks** → **Android SDK**
2. Tab **SDK Platforms**: tick chọn **Android 14 (API 34)**
3. Tab **SDK Tools**: tick chọn:
   - Android SDK Build-Tools
   - Android SDK Command-line Tools
   - Android Emulator
   - Android SDK Platform-Tools
4. Click **Apply** → đợi tải xong

**Bước 0.5: Thêm Android SDK vào PATH**

```bash
echo 'export ANDROID_HOME="$HOME/Android/Sdk"' >> ~/.bashrc
echo 'export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

**Bước 0.6: Tạo Android Emulator**

1. Mở Android Studio → **More Actions** → **Device Manager**
2. Click **Create Virtual Device**
3. Chọn **Pixel 7** → click **Next**
4. Chọn **API 34** (nếu chưa có, click "Download" bên cạnh) → click **Next**
5. Để mặc định → click **Finish**
6. Click nút ▶ (Play) để chạy emulator

> Nếu emulator báo lỗi KVM: `sudo apt-get install qemu-kvm && sudo adduser $USER kvm`
> Sau đó **đăng xuất và đăng nhập lại**.

**Bước 0.7: Kiểm tra**

```bash
flutter doctor
```

Kết quả mong đợi:
```
[✓] Flutter (Channel stable, 3.x.x)
[✓] Linux Version (Ubuntu xx.xx)
[✓] Android toolchain - develop for Android devices
[✓] Android Studio
[✓] VS Code (nếu dùng)
```

---

### Dùng điện thoại thật thay vì emulator (tất cả OS)

1. Vào **Settings** → **About phone** → tap 7 lần vào **Build Number** để bật Developer Options
2. Vào **Settings** → **Developer Options** → bật **USB Debugging**
3. Cắm cáp USB từ điện thoại vào máy tính
4. Trên điện thoại, nhấn **Allow** khi hiện thông báo "Allow USB debugging?"
5. Kiểm tra máy tính đã nhận điện thoại:

```bash
flutter devices
```

Kết quả mong đợi:
```
SM G990B (mobile) • RFXXXXXXXX • android-arm64 • Android 14 (API 34)
```

---

## Phần 1: Tạo project và copy code

### Bước 1: Tạo Flutter Project mới

Mở Terminal (macOS/Linux) hoặc Command Prompt / PowerShell (Windows):

```bash
# Ví dụ: tạo project trên Desktop
# Windows: cd %USERPROFILE%\Desktop
# macOS:   cd ~/Desktop
# Ubuntu:  cd ~/Desktop

flutter create auth_practice --org com.example
cd auth_practice
```

Sau lệnh này, một thư mục `auth_practice` sẽ được tạo với cấu trúc Flutter mặc định.

### Bước 2: Copy code thực hành vào project

**Windows (Command Prompt):**

```cmd
:: Copy pubspec.yaml (ghi đè file mặc định)
copy /Y "..\docs\dao-tao\thuc-hanh-dang-nhap-dang-ky\pubspec.yaml" "pubspec.yaml"

:: Copy thư mục lib (ghi đè file mặc định)
rmdir /S /Q lib
xcopy /E /I /Y "..\docs\dao-tao\thuc-hanh-dang-nhap-dang-ky\lib" "lib"
```

**Windows (PowerShell):**

```powershell
Copy-Item "..\docs\dao-tao\thuc-hanh-dang-nhap-dang-ky\pubspec.yaml" "pubspec.yaml" -Force
Remove-Item -Recurse -Force "lib"
Copy-Item -Recurse "..\docs\dao-tao\thuc-hanh-dang-nhap-dang-ky\lib" "lib"
```

**macOS / Ubuntu (Terminal):**

```bash
# Copy pubspec.yaml (ghi đè file mặc định)
cp ../docs/dao-tao/thuc-hanh-dang-nhap-dang-ky/pubspec.yaml pubspec.yaml

# Copy thư mục lib (ghi đè file mặc định)
rm -rf lib
cp -r ../docs/dao-tao/thuc-hanh-dang-nhap-dang-ky/lib lib
```

**Hoặc copy thủ công (tất cả OS):**
1. Mở File Explorer (Windows) / Finder (macOS) / Nautilus (Ubuntu)
2. Đến thư mục `thuc-hanh-dang-nhap-dang-ky` trong repo
3. Copy file `pubspec.yaml` → Dán vào thư mục `auth_practice` (ghi đè khi được hỏi)
4. Copy thư mục `lib/` → Dán vào thư mục `auth_practice` (ghi đè khi được hỏi)

### Bước 3: Kiểm tra copy thành công

**Windows (Command Prompt):**

```cmd
dir lib\screens
```

**Windows (PowerShell) / macOS / Ubuntu:**

```bash
ls lib/screens/
```

Kết quả mong đợi - phải thấy 4 file:
```
login_screen.dart    register_screen.dart    home_screen.dart    forgot_password_screen.dart
```

### Bước 4: Cài dependencies

```bash
flutter pub get
```

Kết quả mong đợi:
```
Resolving dependencies...
+ firebase_auth x.x.x
+ firebase_core x.x.x
...
Changed X dependencies!
```

---

## Phần 2: Cấu hình Firebase

### Bước 5: Tạo Firebase Project

1. Mở trình duyệt, truy cập: **https://console.firebase.google.com**
2. Đăng nhập bằng tài khoản Google
3. Click nút **"Add project"** (hoặc "Tạo dự án")
4. Nhập tên project: `AuthPractice`
5. Bật/tắt Google Analytics → bỏ qua cũng được
6. Click **"Create project"** (hoặc "Tạo dự án")
7. Đợi vài giây → click **"Continue"**

### Bước 6: Bật Authentication

1. Trong Firebase Console, click project vừa tạo
2. Menu bên trái → click **Authentication** (Xác thực)
3. Click tab **Sign-in method** (Phương thức đăng nhập)
4. Click **Email/Password**
5. Bật công tắc **Enable** (Bật)
6. Click **Save** (Lưu)

### Bước 7: Thêm ứng dụng Android

1. Quay lại trang chủ Firebase Console (click logo Firebase góc trái)
2. Click biểu tượng **Android** (hình robot)
3. **Android package name**: nhập `com.example.authpractice`
   > ⚠️ Chữ `p` trong `authpractice` phải viết **thường**: `authPractice` SAI, phải là `authpractice`
   >
   > Hoặc kiểm tra tên thật: mở file `android/app/build.gradle.kts`, tìm dòng `namespace`
4. **App nickname**: để trống hoặc nhập `Auth Practice`
5. Click **"Register app"**
6. Tải file **google-services.json** (click nút "Download google-services.json")
7. Copy file `google-services.json` vừa tải vào thư mục `android/app/` trong project:

**Windows (Command Prompt):**

```cmd
copy /Y "%USERPROFILE%\Downloads\google-services.json" "android\app\google-services.json"
```

**Windows (PowerShell):**

```powershell
Copy-Item "$env:USERPROFILE\Downloads\google-services.json" "android\app\google-services.json"
```

**macOS:**

```bash
cp ~/Downloads/google-services.json android/app/google-services.json
```

**Ubuntu:**

```bash
cp ~/Downloads/google-services.json android/app/google-services.json
```

8. Click **"Next"** → **"Next"** → **"Continue to console"**

### Bước 8: Cài đặt FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

Sau khi chạy xong, kiểm tra:

```bash
flutterfire --version
```

**Nếu báo lỗi "command not found" hoặc "flutterfire is not recognized":**

Bạn cần thêm Dart vào PATH:

**Windows (Command Prompt):**

```cmd
setx PATH "%PATH%;%USERPROFILE%\AppData\Local\Pub\Cache\bin"
```

Sau đó **đóng và mở lại** Command Prompt.

**Windows (PowerShell):**

```powershell
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$env:USERPROFILE\AppData\Local\Pub\Cache\bin", "User")
```

Sau đó **đóng và mở lại** PowerShell.

**macOS:**

```bash
echo 'export PATH="$PATH":"$HOME/.pub-cache/bin"' >> ~/.zshrc
source ~/.zshrc
```

**Ubuntu:**

```bash
echo 'export PATH="$PATH":"$HOME/.pub-cache/bin"' >> ~/.bashrc
source ~/.bashrc
```

Sau khi sửa PATH, chạy lại `flutterfire --version` để kiểm tra.

### Bước 9: Cấu hình Firebase cho project

```bash
# Đảm bảo đang ở thư mục auth_practice
flutterfire configure
```

Lệnh này sẽ hỏi bạn:
1. **Select a Firebase project** → dùng mũi tên lên/xuống chọn `AuthPractice`, nhấn Enter
2. **Which platforms?** → dùng phím Space để chọn **android**, nhấn Enter

Kết quả mong đợi:
```
✔ Firebase configuration file lib/firebase_options.dart generated successfully.
```

File `lib/firebase_options.dart` sẽ được tạo lại với đúng thông tin Firebase của bạn.

### Bước 10: Chạy ứng dụng

```bash
flutter run
```

> Nếu có nhiều thiết bị, Flutter sẽ hỏi chạy trên thiết bị nào. Chọn emulator hoặc điện thoại đang kết nối.

Kết quả mong đợi:
- Ứng dụng hiện trên emulator/điện thoại
- Màn hình đăng nhập với icon khóa xanh
- Có thể đăng ký tài khoản mới, đăng nhập, và xem trang chủ

---

## Cấu trúc project sau khi hoàn thành

```
auth_practice/
├── android/
│   └── app/
│       ├── google-services.json    ← Tải từ Firebase Console (Bước 7)
│       └── ...
├── lib/
│   ├── main.dart                    ← Điểm khởi đầu
│   ├── firebase_options.dart        ← Tự động tạo bởi flutterfire configure (Bước 9)
│   └── screens/
│       ├── login_screen.dart        ← Màn hình đăng nhập
│       ├── register_screen.dart     ← Màn hình đăng ký
│       ├── home_screen.dart         ← Màn hình chính (sau đăng nhập)
│       └── forgot_password_screen.dart  ← Màn hình quên mật khẩu
├── pubspec.yaml                     ← Danh sách dependencies
└── README.md
```

---

## Giải thích code chính

### main.dart - Khởi tạo Firebase

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AuthPracticeApp());
}
```

> `WidgetsFlutterBinding.ensureInitialized()` phải gọi trước vì `Firebase.initializeApp()` sử dụng async/await, cần Flutter binding đã sẵn sàng.

### login_screen.dart - Đăng nhập

```dart
await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email,
  password: password,
);
```

### register_screen.dart - Đăng ký

```dart
final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: email,
  password: password,
);
await userCredential.user?.updateDisplayName(name);
```

### forgot_password_screen.dart - Quên mật khẩu

```dart
await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
```

### home_screen.dart - Đăng xuất

```dart
await FirebaseAuth.instance.signOut();
```

---

## Bài tập thực hành

### Bài tập 1: Chạy thành công ứng dụng (Bắt buộc)

- [ ] Kiểm tra `flutter doctor` - tất cả ✓
- [ ] Mở emulator hoặc cắm điện thoại
- [ ] Tạo Flutter project mới
- [ ] Copy code từ thư mục thực hành
- [ ] Tạo Firebase project
- [ ] Bật Email/Password authentication
- [ ] Tải `google-services.json` và copy vào `android/app/`
- [ ] Chạy `flutterfire configure`
- [ ] Chạy `flutter pub get`
- [ ] Chạy `flutter run` thành công
- [ ] Đăng ký tài khoản mới (email bất kỳ, ví dụ: `test@gmail.com`, password: `123456`)
- [ ] Đăng nhập với tài khoản đã đăng ký
- [ ] Xem thông tin trên trang Home
- [ ] Đăng xuất
- [ ] Thử quên mật khẩu

### Bài tập 2: Hiểu code (Trả lời câu hỏi)

1. `Firebase.initializeApp()` làm gì? Tại sao cần gọi trước `runApp()`?
2. `FirebaseAuthException` là gì? Các mã lỗi phổ biến khi đăng nhập?
3. Tại sao cần gọi `dispose()` cho các TextEditingController?
4. `Navigator.pushReplacement` khác gì `Navigator.push`?
5. Tại sao cần `try-catch` khi gọi Firebase Auth?

### Bài tập 3: Mở rộng (Nâng cao)

Thêm các tính năng sau vào ứng dụng:

1. **Validate email** - Kiểm tra email hợp lệ trước khi submit (dùng RegExp)
2. **Hiển thị tên người dùng** - Trên AppBar thay vì chỉ trong Card
3. **Ảnh đại diện** - Cho phép chọn avatar từ danh sách có sẵn
4. **Xác nhận email** - Gửi email xác nhận sau khi đăng ký
   ```dart
   await userCredential.user?.sendEmailVerification();
   ```
5. **Đổi mật khẩu** - Thêm màn hình đổi mật khẩu cho người dùng đã đăng nhập

---

## Xử lý lỗi thường gặp

| Lỗi | Nguyên nhân | Cách khắc phục |
|-----|-------------|----------------|
| `flutter doctor` có dấu ✗ | Thiếu cài đặt | Làm theo hướng dẫn của `flutter doctor` |
| `flutter: command not found` / `'flutter' is not recognized` | Flutter chưa cài hoặc chưa vào PATH | Cài lại Flutter, sửa PATH, restart Terminal |
| `emulator: command not found` | Android SDK chưa vào PATH | Xem lại Bước 0.5 (Ubuntu) / Bước 0.3 (Windows) |
| `flutterfire: command not found` / `'flutterfire' is not recognized` | Chưa thêm PATH | Xem Bước 8 - hướng dẫn sửa PATH theo OS |
| `firebase_options.dart not found` | Chưa chạy `flutterfire configure` | Chạy `flutterfire configure` trong thư mục project |
| `google-services.json not found` | Chưa copy file từ Firebase | Copy file vào `android/app/` |
| `API key not valid` | Sai cấu hình Firebase | Chạy lại `flutterfire configure` |
| `user-not-found` | Email chưa đăng ký | Đăng ký tài khoản trước |
| `wrong-password` | Sai mật khẩu | Nhập lại mật khẩu đúng |
| `email-already-in-use` | Email đã được đăng ký | Dùng email khác hoặc đăng nhập |
| `weak-password` | Mật khẩu quá yếu | Dùng mật khẩu >= 6 ký tự |
| Package name không hợp lệ | Sai package name | Phải là `com.example.authpractice` (chữ p thường) |
| Build Android lỗi | Thiếu Java/Android SDK | Kiểm tra `flutter doctor` |
| Emulator không khởi động (Ubuntu) | Thiếu KVM | `sudo apt-get install qemu-kvm && sudo adduser $USER kvm`, đăng xuất rồi đăng nhập lại |

---

## Mẹo Debug

### Xem log Firebase Auth

```dart
// Thêm vào trước khi gọi Firebase Auth
print('Đang thử đăng nhập với email: $email');
```

### Kiểm tra user hiện tại

```dart
final user = FirebaseAuth.instance.currentUser;
print('User hiện tại: ${user?.email ?? "Chưa đăng nhập"}');
```

### Hot reload vs Hot restart

- **Hot Reload** (r): Tải lại giao diện, giữ nguyên state. Dùng khi sửa UI.
- **Hot Restart** (R): Khởi động lại app từ đầu. Dùng khi sửa logic Firebase.
- **Thoát** (q): Thoát khỏi `flutter run`.

> ⚠️ Khi sửa `firebase_options.dart` hoặc `main.dart`, phải dùng **Hot Restart (R)** hoặc chạy lại `flutter run`.

---

## Tài liệu tham khảo

- [Cài đặt Flutter - Windows](https://docs.flutter.dev/get-started/install/windows)
- [Cài đặt Flutter - macOS](https://docs.flutter.dev/get-started/install/macos)
- [Cài đặt Flutter - Linux](https://docs.flutter.dev/get-started/install/linux)
- [Flutter Documentation](https://docs.flutter.dev)
- [Firebase Auth Flutter](https://firebase.google.com/docs/auth/flutter/start)
- [Firebase Console](https://console.firebase.google.com)
