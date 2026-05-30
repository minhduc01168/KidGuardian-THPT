# THỰC HÀNH: Đăng Ký & Đăng Nhập với Firebase Auth

## Mục tiêu

Xây dựng tính năng **đăng ký** và **đăng nhập** bằng Email/Password sử dụng Firebase Authentication trong Flutter.

---

## Phần 0: Kiểm tra môi trường

Trước khi bắt đầu, hãy đảm bảo máy bạn đã cài đặt Flutter. Mở Terminal (Mac/Linux) hoặc Command Prompt / PowerShell (Windows) chạy:

```bash
flutter doctor
```

Kết quả mong đợi - các mục quan trọng phải có dấu tích [✓]:

```
[✓] Flutter (Channel stable, 3.x.x)
[✓] Android toolchain - develop for Android devices
[✓] Android Studio
[✓] VS Code (nếu dùng VS Code)
```

> **Nếu có dấu [✗]:** Hãy cài đặt theo hướng dẫn tại https://docs.flutter.dev/get-started/install

### Mở emulator Android

**Cách 1: Dùng Android Studio**
1. Mở Android Studio
2. Menu: Tools → Device Manager
3. Click nút ▶ (Play) trên một emulator đã tạo
4. Nếu chưa có emulator: click "Create Device" → chọn Pixel 7 → chọn API 34 → Finish → ▶

**Cách 2: Dùng command line**
```bash
# Liệt kê emulator đã tạo
emulator -list-avds

# Chạy emulator (thay ten_emulator bằng tên thật)
emulator -avd ten_emulator
```

**Cách 3: Dùng điện thoại thật**
1. Bật Developer Options trên điện thoại (Settings → About → tap 7 lần vào Build Number)
2. Bật USB Debugging (Settings → Developer Options → USB Debugging)
3. Cắm cáp USB vào máy tính
4. Chạy `flutter devices` để kiểm tra điện thoại đã nhận

---

## Phần 1: Tạo project và copy code

### Bước 1: Tạo Flutter Project mới

```bash
# Chọn nơi bạn muốn lưu, ví dụ Desktop
flutter create auth_practice --org com.example
cd auth_practice
```

Sau lệnh này, một thư mục `auth_practice` sẽ được tạo với cấu trúc Flutter mặc định.

### Bước 2: Copy code thực hành vào project

**Trên macOS / Linux:**

```bash
# Quay lại thư mục chứa repo (nếu cần)
# Ví dụ: cd ~/Desktop nếu bạn tạo project ở Desktop

# Copy pubspec.yaml (ghi đè file mặc định)
cp docs/dao-tao/thuc-hanh-dang-nhap-dang-ky/pubspec.yaml auth_practice/pubspec.yaml

# Copy thư mục lib (ghi đè file mặc định)
rm -rf auth_practice/lib
cp -r docs/dao-tao/thuc-hanh-dang-nhap-dang-ky/lib auth_practice/lib
```

**Trên Windows (PowerShell):**

```powershell
# Copy pubspec.yaml (ghi đè file mặc định)
Copy-Item "docs\dao-tao\thuc-hanh-dang-nhap-dang-ky\pubspec.yaml" "auth_practice\pubspec.yaml" -Force

# Copy thư mục lib (ghi đè file mặc định)
Remove-Item -Recurse -Force "auth_practice\lib"
Copy-Item -Recurse "docs\dao-tao\thuc-hanh-dang-nhap-dang-ky\lib" "auth_practice\lib"
```

**Hoặc copy thủ công (Windows/Mac/Linux):**
1. Mở File Explorer (Windows) hoặc Finder (Mac)
2. Đến thư mục `thuc-hanh-dang-nhap-dang-ky`
3. Copy file `pubspec.yaml` → Dán vào thư mục `auth_practice` (ghi đè khi được hỏi)
4. Copy thư mục `lib/` → Dán vào thư mục `auth_practice` (ghi đè khi được hỏi)

### Bước 3: Kiểm tra copy thành công

```bash
# Đảm bảo đang ở thư mục auth_practice
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
   > ⚠️ Chữ `P` trong `authpractice` phải viết HOA: `authPractice` không đúng, phải là `authpractice`
   > Hoặc kiểm tra tên thật: mở file `android/app/build.gradle.kts`, tìm `namespace`
4. **App nickname**: để trống hoặc nhập `Auth Practice`
5. Click **"Register app"**
6. Tải file **google-services.json** (click nút "Download google-services.json")
7. Copy file `google-services.json` vừa tải vào thư mục `android/app/` trong project

**Trên macOS / Linux:**
```bash
# Ví dụ file tải về nằm trong Downloads
cp ~/Downloads/google-services.json android/app/google-services.json
```

**Trên Windows (PowerShell):**
```powershell
Copy-Item "$env:USERPROFILE\Downloads\google-services.json" "android\app\google-services.json"
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

**Nếu báo lỗi "command not found":**

Bạn cần thêm Dart vào PATH. Chạy lệnh sau:

**Trên macOS / Linux:**
```bash
# Thêm vào file ~/.zshrc (macOS) hoặc ~/.bashrc (Linux)
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

Sau đó reload:
```bash
source ~/.zshrc    # macOS
source ~/.bashrc   # Linux
```

**Trên Windows (PowerShell):**
```powershell
# Thêm vào PATH (chạy 1 lần)
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$env:USERPROFILE\AppData\Local\Pub\Cache\bin", "User")
```

Sau đó **đóng và mở lại** Terminal/PowerShell, rồi chạy lại `flutterfire --version`.

### Bước 9: Cấu hình Firebase cho project

```bash
# Đảm bảo đang ở thư mục auth_practice
flutterfire configure
```

Lệnh này sẽ hỏi bạn:
1. **Select a Firebase project** → dùng mũi tên lên/xuống chọn `AuthPractice`, nhấn Enter
2. **Which platforms?** → chọn **android** (dùng Space để chọn, Enter để xác nhận)

Kết quả mong đợi:
```
✔ Firebase configuration file lib/firebase_options.dart generated successfully.
```

File `lib/firebase_options.dart` sẽ được tạo lại với đúng thông tin Firebase của bạn.

### Bước 10: Chạy ứng dụng

```bash
flutter run
```

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
| `flutter: command not found` | Flutter chưa cài hoặc chưa vào PATH | Cài lại Flutter, restart Terminal |
| `emulator: command not found` | Android Studio chưa cài hoặc chưa vào PATH | Mở Android Studio → Tools → SDK Manager |
| `firebase_options.dart not found` | Chưa chạy `flutterfire configure` | Chạy `flutterfire configure` trong thư mục project |
| `google-services.json not found` | Chưa copy file từ Firebase | Copy file vào `android/app/` |
| `API key not valid` | Sai cấu hình Firebase | Chạy lại `flutterfire configure` |
| `flutterfire: command not found` | Chưa thêm PATH | Xem Bước 8 - hướng dẫn sửa PATH |
| `user-not-found` | Email chưa đăng ký | Đăng ký tài khoản trước |
| `wrong-password` | Sai mật khẩu | Nhập lại mật khẩu đúng |
| `email-already-in-use` | Email đã được đăng ký | Dùng email khác hoặc đăng nhập |
| `weak-password` | Mật khẩu quá yếu | Dùng mật khẩu >= 6 ký tự |
| `The argument 'com.example.authPractice' isn't a valid Android package name` | Sai package name | Phải là `com.example.authpractice` (chữ p thường) |
| Build Android lỗi | Thiếu Java/Android SDK | Kiểm tra `flutter doctor` |

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

- [Cài đặt Flutter](https://docs.flutter.dev/get-started/install)
- [Flutter Documentation](https://docs.flutter.dev)
- [Firebase Auth Flutter](https://firebase.google.com/docs/auth/flutter/start)
- [Firebase Console](https://console.firebase.google.com)
