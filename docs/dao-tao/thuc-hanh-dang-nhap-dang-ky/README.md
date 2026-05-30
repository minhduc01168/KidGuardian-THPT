# THỰC HÀNH: Đăng Ký & Đăng Nhập với Firebase Auth

## Mục tiêu

Xây dựng tính năng **đăng ký** và **đăng nhập** bằng Email/Password sử dụng Firebase Authentication trong Flutter.

## Yêu cầu trước khi bắt đầu

| Yêu cầu | Chi tiết |
|---------|----------|
| Flutter SDK | Đã cài đặt (phiên bản 3.x trở lên) |
| Android Studio / VS Code | Đã cài đặt |
| Tài khoản Google | Để tạo Firebase project |
| Thiết bị hoặc emulator | Android hoặc iOS |

---

## Hướng dẫn từng bước

### Bước 1: Tạo Flutter Project mới

Mở Terminal / Command Prompt và chạy:

```bash
# Tạo project mới (chọn nơi bạn muốn lưu, ví dụ Desktop)
flutter create auth_practice --org com.example
cd auth_practice
```

### Bước 2: Copy code thực hành vào project

Copy các file từ thư mục thực hành vào project vừa tạo:

```bash
# Đường dẫn đến thư mục thực hành (điều chỉnh cho đúng)
THUC_HANH="docs/dao-tao/thuc-hanh-dang-nhap-dang-ky"

# Copy pubspec.yaml (ghi đè file mặc định)
cp "$THUC_HANH/pubspec.yaml" pubspec.yaml

# Copy thư mục lib (ghi đè file mặc định)
rm -rf lib
cp -r "$THUC_HANH/lib" lib
```

**Hoặc copy thủ công:**
1. Mở thư mục `thuc-hanh-dang-nhap-dang-ky` trong File Explorer / Finder
2. Copy file `pubspec.yaml` → Dán vào project `auth_practice` (ghi đè)
3. Copy thư mục `lib/` → Dán vào project `auth_practice` (ghi đè)

### Bước 3: Tạo Firebase Project

1. Mở **Firebase Console**: https://console.firebase.google.com
2. Đăng nhập bằng tài khoản Google
3. Click **"Add project"**
4. Nhập tên project (ví dụ: `AuthPractice`)
5. Bật hoặc tắt Google Analytics (tùy chọn)
6. Click **"Create project"**

### Bước 4: Bật Authentication

1. Trong Firebase Console, chọn project vừa tạo
2. Chọn menu **Authentication** (bên trái)
3. Tab **Sign-in method**
4. Bật phương thức **Email/Password**
5. Click **Save**

### Bước 5: Thêm ứng dụng Android

1. Trong Firebase Console, click biểu tượng **Android**
2. Nhập **Android package name**: `com.example.authPractice`
   > Lưu ý: package name phải khớp với tên project bạn tạo ở Bước 1
3. Click **"Register app"**
4. Tải file **google-services.json**
5. Copy file vào thư mục `android/app/` trong project

### Bước 6: Thêm ứng dụng iOS (nếu dùng iOS)

1. Trong Firebase Console, click biểu tượng **iOS**
2. Nhập **iOS bundle ID**: `com.example.authPractice`
3. Click **"Register app"**
4. Tải file **GoogleService-Info.plist**
5. Copy file vào thư mục `Runner/` trong Xcode

### Bước 7: Cài đặt FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### Bước 8: Cấu hình Firebase cho project

```bash
# Đảm bảo đang ở thư mục project auth_practice
flutterfire configure
```

Lệnh này sẽ:
- Tự động tạo lại file `lib/firebase_options.dart` với đúng cấu hình Firebase của bạn
- Cập nhật file Android/iOS với thông tin Firebase

### Bước 9: Cài đặt dependencies

```bash
flutter pub get
```

### Bước 10: Chạy ứng dụng

```bash
flutter run
```

---

## Cấu trúc project sau khi hoàn thành

```
auth_practice/
├── android/
│   └── app/
│       ├── google-services.json    # Firebase config (tải từ Firebase Console)
│       └── ...
├── ios/
│   └── Runner/
│       ├── GoogleService-Info.plist # Firebase config (tải từ Firebase Console)
│       └── ...
├── lib/
│   ├── main.dart                    # Điểm khởi đầu, khởi tạo Firebase
│   ├── firebase_options.dart        # Cấu hình Firebase (tự động tạo)
│   └── screens/
│       ├── login_screen.dart        # Màn hình đăng nhập
│       ├── register_screen.dart     # Màn hình đăng ký
│       ├── home_screen.dart         # Màn hình chính (sau đăng nhập)
│       └── forgot_password_screen.dart  # Màn hình quên mật khẩu
├── pubspec.yaml                     # Danh sách dependencies
└── README.md                        # File hướng dẫn này
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

- [ ] Tạo Flutter project mới
- [ ] Copy code từ thư mục thực hành
- [ ] Tạo Firebase project
- [ ] Bật Email/Password authentication
- [ ] Cấu hình `flutterfire configure`
- [ ] Chạy `flutter run` thành công
- [ ] Đăng ký tài khoản mới
- [ ] Đăng nhập với tài khoản đã đăng ký
- [ ] Xem thông tin trên trang Home
- [ ] Đăng xuất

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
| `firebase_options.dart not found` | Chưa chạy `flutterfire configure` | Chạy lệnh `flutterfire configure` |
| `google-services.json not found` | Chưa copy file từ Firebase | Copy file vào `android/app/` |
| `API key not valid` | Sai cấu hình Firebase | Kiểm tra lại `firebase_options.dart` |
| `user-not-found` | Email chưa đăng ký | Đăng ký tài khoản trước |
| `wrong-password` | Sai mật khẩu | Nhập lại mật khẩu đúng |
| `email-already-in-use` | Email đã được đăng ký | Dùng email khác hoặc đăng nhập |
| `weak-password` | Mật khẩu quá yếu | Dùng mật khẩu >= 6 ký tự |
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

### Đăng xuất nhanh (trong code)

```dart
await FirebaseAuth.instance.signOut();
```

---

## Tài liệu tham khảo

- [Firebase Auth Flutter](https://firebase.google.com/docs/auth/flutter/start)
- [Firebase Console](https://console.firebase.google.com)
- [Flutter Documentation](https://docs.flutter.dev)
- [Cài đặt Flutter](https://docs.flutter.dev/get-started/install)
