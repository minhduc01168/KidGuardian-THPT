# Bài 5: Code Conventions
# Quy Ước Viết Code

---

## 1. Tại Sao Cần Code Conventions?

### 1.1 Lợi Ích
- **Đọc dễ hiểu:** Code thống nhất, dễ đọc
- **Maintain dễ:** Ai cũng hiểu code của nhau
- **Review nhanh:** Ít thảo luận về style
- **Professional:** Code trông chuyên nghiệp

### 1.2 Nguyên Tắc
- Tuân thủ theo Dart/Flutter style guide
- Nhất quán trong toàn bộ project
- Sử dụng linter để kiểm tra tự động

---

## 2. Dart Style Guide

### 2.1 Naming Conventions

| Loại | Style | Ví Dụ |
|------|-------|-------|
| File | `snake_case.dart` | `login_screen.dart` |
| Class | `PascalCase` | `LoginScreen` |
| Variable | `camelCase` | `userName` |
| Constant | `kConstantName` | `kDefaultPadding` |
| Enum | `PascalCase` | `AuthStatus` |
| Enum value | `camelCase` | `AuthStatus.authenticated` |

### 2.2 Ví Dụ

```dart
// ✅ Đúng
class LoginScreen extends StatelessWidget {
  static const String routeName = '/login';
  
  final String userName;
  final int userAge;
  
  const LoginScreen({
    super.key,
    required this.userName,
    required this.userAge,
  });
}

// ❌ Sai
class login_screen extends StatelessWidget {
  static const String RouteName = '/login';
  
  final String UserName;
  final int user_age;
}
```

---

## 3. Flutter Style Guide

### 3.1 Widget Structure

```dart
class MyWidget extends StatelessWidget {
  // 1. Constants
  static const double _padding = 16.0;
  
  // 2. Fields
  final String title;
  final VoidCallback? onTap;
  
  // 3. Constructor
  const MyWidget({
    super.key,
    required this.title,
    this.onTap,
  });
  
  // 4. Build method
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(_padding),
        child: Text(title),
      ),
    );
  }
}
```

### 3.2 Widget Tree

```dart
// ✅ Đúng - Rõ ràng, dễ đọc
return Scaffold(
  appBar: AppBar(
    title: Text('Login'),
  ),
  body: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        TextField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: 'Email',
          ),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: _handleLogin,
          child: Text('Login'),
        ),
      ],
    ),
  ),
);

// ❌ Sai - Khó đọc
return Scaffold(appBar: AppBar(title: Text('Login')), body: Padding(padding: EdgeInsets.all(16), child: Column(children: [TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')), SizedBox(height: 16), ElevatedButton(onPressed: _handleLogin, child: Text('Login'))])));
```

---

## 4. Folder Structure

### 4.1 Feature-Based Structure

```
lib/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── blocs/
│   │       ├── screens/
│   │       └── widgets/
│   ├── dashboard/
│   └── smart_lock/
```

### 4.2 File Naming

| Loại | Pattern | Ví Dụ |
|------|---------|-------|
| Screen | `*_screen.dart` | `login_screen.dart` |
| Widget | `*_widget.dart` | `custom_button.dart` |
| BLoC | `*_bloc.dart` | `auth_bloc.dart` |
| Event | `*_event.dart` | `auth_event.dart` |
| State | `*_state.dart` | `auth_state.dart` |
| Model | `*_model.dart` | `user_model.dart` |
| Entity | `*.dart` | `user.dart` |
| Repository | `*_repository.dart` | `auth_repository.dart` |
| Use Case | `*_usecase.dart` | `login_usecase.dart` |

---

## 5. Import Conventions

### 5.1 Import Order

```dart
// 1. Dart imports
import 'dart:async';
import 'dart:convert';

// 2. Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// 3. Third-party imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 4. Project imports
import 'package:kidguardian/core/constants/app_colors.dart';
import 'package:kidguardian/features/auth/domain/entities/user.dart';
```

### 5.2 Relative vs Absolute

```dart
// ✅ Đúng - Sử dụng package imports
import 'package:kidguardian/features/auth/presentation/screens/login_screen.dart';

// ❌ Sai - Sử dụng relative imports
import '../../../auth/presentation/screens/login_screen.dart';
```

---

## 6. Comments

### 6.1 Khi Nào Comment

```dart
// ✅ Comment "tại sao"
// We use a 5-second delay because Firebase needs time to sync
await Future.delayed(Duration(seconds: 5));

// ❌ Comment "cái gì" (code đã rõ)
// Increment counter by 1
counter++;
```

### 6.2 Dart Doc

```dart
/// Authenticates user with email and password.
///
/// Returns [UserCredential] on success.
/// Throws [FirebaseAuthException] on failure.
///
/// Example:
/// ```dart
/// final credential = await login('user@email.com', 'password');
/// ```
Future<UserCredential> login(String email, String password) async {
  // implementation
}
```

---

## 7. Error Handling

### 7.1 Try-Catch

```dart
try {
  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
} on FirebaseAuthException catch (e) {
  // Handle specific Firebase errors
  if (e.code == 'user-not-found') {
    throw AuthException('Không tìm thấy tài khoản');
  } else if (e.code == 'wrong-password') {
    throw AuthException('Sai mật khẩu');
  }
  throw AuthException('Lỗi đăng nhập: ${e.message}');
} catch (e) {
  // Handle other errors
  throw AuthException('Lỗi không xác định');
}
```

### 7.2 Custom Exceptions

```dart
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}
```

---

## 8. State Management (BLoC)

### 8.1 BLoC Structure

```dart
// Events
abstract class AuthEvent {}
class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  const LoginRequested({required this.email, required this.password});
}

// States
abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState {
  final User user;
  const AuthSuccess(this.user);
}
class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
  }
  
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // implementation
      emit(AuthSuccess(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}
```

---

## 9. Testing Conventions

### 9.1 Test File Structure

```
test/
├── unit/
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
```

### 9.2 Test Naming

```dart
// ✅ Đúng
void main() {
  group('AuthBloc', () {
    group('LoginRequested', () {
      test('should emit [Loading, Success] when login is successful', () {
        // test
      });
      
      test('should emit [Loading, Failure] when login fails', () {
        // test
      });
    });
  });
}
```

---

## 10. Linting

### 10.1 analysis_options.yaml

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_declare_return_types
    - annotate_overrides
    - avoid_empty_else
    - avoid_print
    - avoid_unnecessary_containers
    - camel_case_types
    - constant_identifier_names
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_fields
    - prefer_final_locals
    - sort_constructors_first
    - sort_unnamed_constructors_first
    - unnecessary_const
    - unnecessary_new
    - unnecessary_this
    - use_key_in_widget_constructors
```

### 10.2 Chạy Linter

```bash
flutter analyze
```

---

## 11. Tóm Tắt

| Quy Tắc | Mô Tả |
|----------|-------|
| Naming | snake_case cho file, PascalCase cho class |
| Imports | Dart → Flutter → Third-party → Project |
| Comments | Comment "tại sao", không comment "cái gì" |
| Structure | Feature-based, tách biệt layers |
| Error | Try-catch với custom exceptions |
| State | BLoC pattern |
| Testing | Unit test cho logic, Widget test cho UI |

---

**Bài Tiếp Theo:** [Kiến Trúc Dự Án](06-KIEN-TRUC-DU-AN.md)
