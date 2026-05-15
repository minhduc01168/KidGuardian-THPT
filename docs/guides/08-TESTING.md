# Bài 8: Testing
# Hướng Dẫn Viết và Chạy Test

---

## 1. Tại Sao Cần Test?

### 1.1 Lợi Ích
- **Phát hiện bug sớm:** Tìm lỗi trước khi deploy
- **Tự tin refactor:** Thay đổi code mà không sợ phá vỡ
- **Documentation:** Test là documentation sống
- **Quality:** Đảm bảo code hoạt động đúng

### 1.2 Các Loại Test

| Loại | Mô Tả | Tốc Độ | Chi Phí |
|------|-------|--------|---------|
| Unit Test | Test function, class | Nhanh | Thấp |
| Widget Test | Test UI components | Trung bình | Trung bình |
| Integration Test | Test full flow | Chậm | Cao |

---

## 2. Unit Test

### 2.1 Cấu Trúc

```
test/
├── unit/
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   ├── core/
│   └── utils/
```

### 2.2 Ví Dụ Đơn Giản

```dart
// test/unit/utils/validator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/core/utils/validators.dart';

void main() {
  group('Email Validator', () {
    test('should return true for valid email', () {
      expect(Validators.isValidEmail('test@example.com'), true);
    });
    
    test('should return false for invalid email', () {
      expect(Validators.isValidEmail('invalid-email'), false);
    });
    
    test('should return false for empty email', () {
      expect(Validators.isValidEmail(''), false);
    });
  });
}
```

### 2.3 Test Use Case

```dart
// test/unit/domain/usecases/login_usecase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/usecases/auth/login_usecase.dart';
import 'package:kidguardian/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockRepository;
  
  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUseCase(mockRepository);
  });
  
  group('LoginUseCase', () {
    test('should call repository.login with correct parameters', () async {
      // arrange
      when(() => mockRepository.login('test@email.com', 'password123'))
          .thenAnswer((_) async => testUser);
      
      // act
      await useCase('test@email.com', 'password123');
      
      // assert
      verify(() => mockRepository.login('test@email.com', 'password123')).called(1);
    });
    
    test('should throw ValidationException for empty email', () {
      // arrange & act & assert
      expect(
        () => useCase('', 'password123'),
        throwsA(isA<ValidationException>()),
      );
    });
    
    test('should throw ValidationException for empty password', () {
      expect(
        () => useCase('test@email.com', ''),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
```

### 2.4 Test BLoC

```dart
// test/unit/presentation/blocs/auth_bloc_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/presentation/blocs/auth/auth_bloc.dart';
import 'package:kidguardian/domain/usecases/auth/login_usecase.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

void main() {
  late AuthBloc authBloc;
  late MockLoginUseCase mockLoginUseCase;
  
  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    authBloc = AuthBloc(loginUseCase: mockLoginUseCase);
  });
  
  tearDown(() {
    authBloc.close();
  });
  
  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, equals(AuthInitial()));
    });
    
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Success] when login is successful',
      build: () {
        when(() => mockLoginUseCase(any(), any()))
            .thenAnswer((_) async => testUser);
        return authBloc;
      },
      act: (bloc) => bloc.add(LoginRequested(
        email: 'test@email.com',
        password: 'password123',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthSuccess>(),
      ],
    );
    
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Failure] when login fails',
      build: () {
        when(() => mockLoginUseCase(any(), any()))
            .thenThrow(Exception('Login failed'));
        return authBloc;
      },
      act: (bloc) => bloc.add(LoginRequested(
        email: 'test@email.com',
        password: 'wrong_password',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthFailure>(),
      ],
    );
  });
}
```

---

## 3. Widget Test

### 3.1 Ví Dụ

```dart
// test/widget/screens/login_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/presentation/screens/auth/login_screen.dart';
import 'package:kidguardian/presentation/blocs/auth/auth_bloc.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;
  
  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });
  
  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>(
        create: (_) => mockAuthBloc,
        child: LoginScreen(),
      ),
    );
  }
  
  group('LoginScreen', () {
    testWidgets('should display login form', (tester) async {
      // arrange
      when(() => mockAuthBloc.state).thenReturn(AuthInitial());
      when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.empty());
      
      // act
      await tester.pumpWidget(createWidgetUnderTest());
      
      // assert
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });
    
    testWidgets('should show error message when login fails', (tester) async {
      // arrange
      when(() => mockAuthBloc.state).thenReturn(AuthInitial());
      when(() => mockAuthBloc.stream).thenAnswer(
        (_) => Stream.value(AuthFailure('Login failed')),
      );
      
      // act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      
      // assert
      expect(find.text('Login failed'), findsOneWidget);
    });
    
    testWidgets('should show loading when logging in', (tester) async {
      // arrange
      when(() => mockAuthBloc.state).thenReturn(AuthLoading());
      when(() => mockAuthBloc.stream).thenAnswer(
        (_) => Stream.value(AuthLoading()),
      );
      
      // act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      
      // assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
```

### 3.2 Test Custom Widget

```dart
// test/widget/widgets/custom_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/presentation/widgets/common/custom_button.dart';

void main() {
  group('CustomButton', () {
    testWidgets('should display text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Click Me',
              onPressed: () {},
            ),
          ),
        ),
      );
      
      expect(find.text('Click Me'), findsOneWidget);
    });
    
    testWidgets('should call onPressed when tapped', (tester) async {
      bool pressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Click Me',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );
      
      await tester.tap(find.byType(CustomButton));
      expect(pressed, true);
    });
    
    testWidgets('should be disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Click Me',
              onPressed: null,
            ),
          ),
        ),
      );
      
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.enabled, false);
    });
  });
}
```

---

## 4. Integration Test

### 4.1 Cấu Trúc

```
integration_test/
├── app_test.dart
├── auth/
│   └── login_flow_test.dart
└── dashboard/
    └── dashboard_flow_test.dart
```

### 4.2 Ví Dụ

```dart
// integration_test/auth/login_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kidguardian/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Login Flow', () {
    testWidgets('should login successfully with valid credentials', (tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();
      
      // Enter email
      await tester.enterText(
        find.byKey(Key('email_field')),
        'test@example.com',
      );
      
      // Enter password
      await tester.enterText(
        find.byKey(Key('password_field')),
        'password123',
      );
      
      // Tap login button
      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle();
      
      // Verify dashboard is shown
      expect(find.text('Dashboard'), findsOneWidget);
    });
    
    testWidgets('should show error for invalid credentials', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      await tester.enterText(
        find.byKey(Key('email_field')),
        'invalid@example.com',
      );
      
      await tester.enterText(
        find.byKey(Key('password_field')),
        'wrong_password',
      );
      
      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle();
      
      expect(find.text('Invalid credentials'), findsOneWidget);
    });
  });
}
```

---

## 5. Mocking

### 5.1 Sử Dụng mocktail

```dart
import 'package:mocktail/mocktail.dart';

// Tạo mock class
class MockAuthRepository extends Mock implements AuthRepository {}

// Setup mock
void main() {
  late MockAuthRepository mockRepository;
  
  setUp(() {
    mockRepository = MockAuthRepository();
  });
  
  test('should return user when login succeeds', () async {
    // arrange
    when(() => mockRepository.login(any(), any()))
        .thenAnswer((_) async => testUser);
    
    // act
    final result = await mockRepository.login('email', 'password');
    
    // assert
    expect(result, testUser);
    verify(() => mockRepository.login('email', 'password')).called(1);
  });
  
  test('should throw exception when login fails', () {
    // arrange
    when(() => mockRepository.login(any(), any()))
        .thenThrow(Exception('Login failed'));
    
    // act & assert
    expect(
      () => mockRepository.login('email', 'password'),
      throwsA(isA<Exception>()),
    );
  });
}
```

### 5.2 Mock Firebase

```dart
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockUserCredential mockCredential;
  
  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockCredential = MockUserCredential();
  });
  
  test('should login with Firebase Auth', () async {
    // arrange
    when(() => mockAuth.signInWithEmailAndPassword(
      email: any(named: 'email'),
      password: any(named: 'password'),
    )).thenAnswer((_) async => mockCredential);
    
    // act
    final result = await mockAuth.signInWithEmailAndPassword(
      email: 'test@email.com',
      password: 'password123',
    );
    
    // assert
    expect(result, mockCredential);
  });
}
```

---

## 6. Chạy Test

### 6.1 Command Line

```bash
# Chạy tất cả test
flutter test

# Chạy test cụ thể
flutter test test/unit/utils/validator_test.dart

# Chạy test với coverage
flutter test --coverage

# Chạy integration test
flutter test integration_test/
```

### 6.2 VS Code

1. Mở file test
2. Click vào icon play bên cạnh test
3. Hoặc nhấn F5

### 6.3 Android Studio

1. Mở file test
2. Click chuột phải vào test
3. Chọn "Run"

---

## 7. Code Coverage

### 7.1 Tạo Coverage Report

```bash
# Tạo coverage data
flutter test --coverage

# Tạo HTML report (cần lcov)
genhtml coverage/lcov.info -o coverage/html

# Mở report
open coverage/html/index.html
```

### 7.2 Coverage Targets

| Layer | Target |
|-------|--------|
| Use Cases | 90% |
| Repositories | 80% |
| BLoCs | 85% |
| Widgets | 70% |

---

## 8. Best Practices

### 8.1 Naming Convention

```dart
// ✅ Đúng
test('should return true for valid email', () {});
test('should throw exception when email is empty', () {});

// ❌ Sai
test('test email validation', () {});
test('email test', () {});
```

### 8.2 AAA Pattern

```dart
test('should calculate total correctly', () {
  // Arrange - Setup
  final calculator = Calculator();
  
  // Act - Execute
  final result = calculator.add(2, 3);
  
  // Assert - Verify
  expect(result, 5);
});
```

### 8.3 One Assert Per Test

```dart
// ✅ Đúng - Mỗi test 1 assert
test('should return true for valid email', () {
  expect(Validators.isValidEmail('test@email.com'), true);
});

test('should return false for invalid email', () {
  expect(Validators.isValidEmail('invalid'), false);
});

// ❌ Sai - Nhiều assert trong 1 test
test('should validate email', () {
  expect(Validators.isValidEmail('test@email.com'), true);
  expect(Validators.isValidEmail('invalid'), false);
  expect(Validators.isValidEmail(''), false);
});
```

---

## 9. Xử Lý Sự Cố

### 9.1 Test Chậm
- Sử dụng mock thay vì thật
- Giảm số lượng integration test
- Chạy parallel tests

### 9.2 Test Flaky
- Tránh depend vào timing
- Sử dụng mock cho async operations
- Reset state trong setUp/tearDown

### 9.3 Coverage Thấp
- Tập trung vào business logic
- Test edge cases
- Test error scenarios

---

## 10. Tóm Tắt

| Loại Test | Khi Nào | Tool |
|-----------|---------|------|
| Unit Test | Test logic, function | flutter_test |
| Widget Test | Test UI, interaction | flutter_test |
| Integration Test | Test full flow | integration_test |

---

**Bài Tiếp Theo:** [Deployment](09-DEPLOYMENT.md)
