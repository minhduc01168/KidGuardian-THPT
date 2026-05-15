# Bài 3: Flutter + Firebase
# Hướng Dẫn Làm Việc Với Flutter và Firebase

---

## 1. Tổng Quan

### 1.1 Flutter Là Gì?
- Framework phát triển UI của Google
- Viết 1 lần, chạy được trên Android, iOS, Web, Desktop
- Ngôn ngữ: Dart
- Hot reload: Thay đổi code → thấy ngay kết quả

### 1.2 Firebase Là Gì?
- Backend-as-a-Service (BaaS) của Google
- Không cần tự xây dựng server
- Free Tier: Đủ cho MVP

### 1.3 Tại Sao Chọn Stack Này?

| Ưu Điểm | Mô Tả |
|----------|--------|
| Nhanh | Không cần viết backend từ đầu |
| Miễn phí | Firebase Free Tier đủ cho MVP |
| Real-time | Firestore sync dữ liệu real-time |
| Bảo mật | Firebase Auth xử lý authentication |

---

## 2. Cấu Trúc Dự Án Flutter

```
lib/
├── main.dart                 # Entry point
├── core/                     # Utilities chung
│   ├── constants/           # Hằng số
│   ├── theme/               # Giao diện
│   └── utils/               # Hàm tiện ích
├── data/                     # Data layer
│   ├── models/              # Data models
│   ├── datasources/         # Firebase, local
│   └── repositories/        # Implementations
├── domain/                   # Business logic
│   ├── entities/            # Business objects
│   ├── repositories/        # Interfaces
│   └── usecases/            # Use cases
└── presentation/             # UI
    ├── screens/             # Screens
    ├── widgets/             # Reusable widgets
    └── blocs/               # State management
```

---

## 3. Làm Việc Với Flutter

### 3.1 Tạo Widget Mới

```dart
// lib/presentation/widgets/my_widget.dart
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  final String title;
  
  const MyWidget({super.key, required this.title});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
```

### 3.2 Tạo Screen Mới

```dart
// lib/presentation/screens/my_screen.dart
import 'package:flutter/material.dart';

class MyScreen extends StatelessWidget {
  const MyScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Screen'),
      ),
      body: Center(
        child: Text('Hello World'),
      ),
    );
  }
}
```

### 3.3 Navigation

```dart
// Chuyển sang screen mới
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => MyScreen()),
);

// Quay lại screen trước
Navigator.pop(context);
```

---

## 4. Làm Việc Với Firebase

### 4.1 Khởi Tạo Firebase

```dart
// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
```

### 4.2 Firebase Authentication

**Đăng ký:**
```dart
import 'package:firebase_auth/firebase_auth.dart';

Future<UserCredential> register(String email, String password) async {
  return await FirebaseAuth.instance.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );
}
```

**Đăng nhập:**
```dart
Future<UserCredential> login(String email, String password) async {
  return await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
}
```

**Đăng xuất:**
```dart
Future<void> logout() async {
  await FirebaseAuth.instance.signOut();
}
```

### 4.3 Firestore Database

**Thêm dữ liệu:**
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addUser(String uid, String name, String role) async {
  await FirebaseFirestore.instance.collection('users').doc(uid).set({
    'uid': uid,
    'name': name,
    'role': role,
    'createdAt': FieldValue.serverTimestamp(),
  });
}
```

**Đọc dữ liệu:**
```dart
Future<Map<String, dynamic>?> getUser(String uid) async {
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();
  return doc.data();
}
```

**Cập nhật dữ liệu:**
```dart
Future<void> updateUser(String uid, Map<String, dynamic> data) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .update(data);
}
```

**Xóa dữ liệu:**
```dart
Future<void> deleteUser(String uid) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .delete();
}
```

### 4.4 Real-time Listener

```dart
Stream<DocumentSnapshot> getUserStream(String uid) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots();
}

// Sử dụng trong Widget
StreamBuilder<DocumentSnapshot>(
  stream: getUserStream(uid),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final data = snapshot.data!.data() as Map<String, dynamic>;
      return Text(data['name']);
    }
    return CircularProgressIndicator();
  },
);
```

---

## 5. State Management với BLoC

### 5.1 BLoC Là Gì?
- Business Logic Component
- Tách biệt UI và Business Logic
- Dễ test, dễ maintain

### 5.2 Tạo BLoC

```dart
// lib/presentation/blocs/auth/auth_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class AuthEvent {}
class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested({required this.email, required this.password});
}

// States
abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated(this.user);
}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  
  AuthBloc({required this.loginUseCase}) : super(AuthInitial()) {
    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await loginUseCase(event.email, event.password);
        emit(AuthAuthenticated(user));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });
  }
}
```

### 5.3 Sử Dụng BLoC

```dart
// Trong main.dart
BlocProvider(
  create: (context) => AuthBloc(loginUseCase: sl<LoginUseCase>()),
  child: MyApp(),
);

// Trong Widget
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthLoading) {
      return CircularProgressIndicator();
    }
    if (state is AuthAuthenticated) {
      return DashboardScreen();
    }
    return LoginScreen();
  },
);
```

---

## 6. Dependency Injection

### 6.1 Sử Dụng get_it

```dart
// lib/core/di/injection_container.dart
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

void init() {
  // BLoCs
  sl.registerFactory(() => AuthBloc(loginUseCase: sl()));
  
  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  
  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(authSource: sl()),
  );
  
  // Data Sources
  sl.registerLazySingleton(() => FirebaseAuthSource());
}
```

### 6.2 Sử Dụng Trong App

```dart
// Khởi tạo trong main.dart
void main() async {
  init(); // Dependency injection
  runApp(MyApp());
}

// Sử dụng
final authBloc = sl<AuthBloc>();
```

---

## 7. Xử Lý Lỗi

### 7.1 Try-Catch

```dart
try {
  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
} on FirebaseAuthException catch (e) {
  if (e.code == 'user-not-found') {
    print('Không tìm thấy tài khoản');
  } else if (e.code == 'wrong-password') {
    print('Sai mật khẩu');
  }
} catch (e) {
  print('Lỗi không xác định: $e');
}
```

### 7.2 Custom Exception

```dart
// lib/core/errors/exceptions.dart
class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);
}
```

---

## 8. Best Practices

### 8.1 Code Organization
- Mỗi feature một thư mục riêng
- Tách biệt UI, Logic, Data
- Sử dụng constants cho hằng số

### 8.2 Naming Conventions
- File: `snake_case.dart`
- Class: `PascalCase`
- Variable: `camelCase`
- Constant: `kConstantName`

### 8.3 Comments
- Comment "tại sao" không phải "cái gì"
- Sử dụng Dart Doc cho public APIs
- Không comment code quá rõ ràng

---

## 9. Bài Tập Thực Hành

### Bài 1: Tạo Login Screen
- Tạo UI với Email, Password fields
- Implement Firebase Auth
- Xử lý lỗi

### Bài 2: Tạo User Profile
- Đọc dữ liệu từ Firestore
- Hiển thị thông tin user
- Cho phép chỉnh sửa

### Bài 3: Tạo Dashboard
- Hiển thị danh sách từ Firestore
- Sử dụng StreamBuilder cho real-time
- Implement pull-to-refresh

---

## 10. Tài Liệu Tham Khảo

- Flutter Documentation: https://docs.flutter.dev
- Firebase Documentation: https://firebase.google.com/docs
- BLoC Library: https://bloclibrary.dev

---

**Bài Tiếp Theo:** [Git Workflow](04-GIT-WORKFLOW.md)
