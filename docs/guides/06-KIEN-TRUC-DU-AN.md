# Bài 6: Kiến Trúc Dự Án
# Giải Thích Clean Architecture

---

## 1. Tại Sao Cần Kiến Trúc?

### 1.1 Vấn Đề
- Code dễ bị rối khi project lớn
- Khó test khi UI và logic trộn lẫn
- Khó maintain khi thay đổi requirement

### 1.2 Giải Pháp
- **Clean Architecture:** Tách biệt các lớp
- **BLoC Pattern:** Quản lý state
- **Dependency Injection:** Quản lý dependencies

---

## 2. Clean Architecture

### 2.1 Nguyên Tắc

```
┌─────────────────────────────────────────────┐
│           Presentation Layer                │
│         (UI, Widgets, BLoCs)                │
└─────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│           Application Layer                 │
│         (Use Cases, Services)               │
└─────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│              Domain Layer                   │
│      (Entities, Repository Interfaces)      │
└─────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│          Infrastructure Layer               │
│    (Firebase, Local DB, Platform Channels)  │
└─────────────────────────────────────────────┘
```

### 2.2 Dependency Rule
- Lớp ngoài phụ thuộc lớp trong
- Lớp trong không phụ thuộc lớp ngoài
- Domain layer không phụ thuộc bất kỳ lớp nào

---

## 3. Các Lớp Trong Dự Án

### 3.1 Presentation Layer

**Mục đích:** Hiển thị UI và xử lý user interaction

**Thành phần:**
- Screens: Các màn hình
- Widgets: Các component tái sử dụng
- BLoCs: Quản lý state

**Ví dụ:**
```dart
// lib/presentation/screens/login_screen.dart
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return CircularProgressIndicator();
          }
          return LoginForm();
        },
      ),
    );
  }
}
```

### 3.2 Application Layer

**Mục đích:** Chứa business logic và use cases

**Thành phần:**
- Use Cases: Các action cụ thể
- Services: Các service chung

**Ví dụ:**
```dart
// lib/domain/usecases/auth/login_usecase.dart
class LoginUseCase {
  final AuthRepository repository;
  
  LoginUseCase(this.repository);
  
  Future<User> call(String email, String password) async {
    // Validate input
    if (email.isEmpty || password.isEmpty) {
      throw ValidationException('Email và mật khẩu không được trống');
    }
    
    // Call repository
    return await repository.login(email, password);
  }
}
```

### 3.3 Domain Layer

**Mục đích:** Chứa business entities và repository interfaces

**Thành phần:**
- Entities: Business objects
- Repository Interfaces: Contracts cho data access

**Ví dụ:**
```dart
// lib/domain/entities/user.dart
class User {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  
  const User({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
  });
}

// lib/domain/repositories/auth_repository.dart
abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<User> register(String email, String password, String name);
  Future<void> logout();
  Future<User?> getCurrentUser();
}
```

### 3.4 Infrastructure Layer

**Mục đích:** Implement data access và platform-specific code

**Thành phần:**
- Data Sources: Firebase, Local DB
- Repository Implementations
- Platform Channels

**Ví dụ:**
```dart
// lib/data/repositories/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthSource authSource;
  final FirestoreSource firestoreSource;
  
  AuthRepositoryImpl({
    required this.authSource,
    required this.firestoreSource,
  });
  
  @override
  Future<User> login(String email, String password) async {
    final credential = await authSource.login(email, password);
    final userData = await firestoreSource.getUser(credential.user!.uid);
    return User.fromMap(userData);
  }
}
```

---

## 4. BLoC Pattern

### 4.1 BLoC Là Gì?
- Business Logic Component
- Tách biệt UI và Business Logic
- Sử dụng Stream để quản lý state

### 4.2 Cách Hoạt Động

```
Event → BLoC → State
  ↓       ↓       ↓
User   Logic    UI
```

### 4.3 Ví Dụ

```dart
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
class AuthSuccess extends AuthState {
  final User user;
  AuthSuccess(this.user);
}
class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  
  AuthBloc({required this.loginUseCase}) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
  }
  
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await loginUseCase(event.email, event.password);
      emit(AuthSuccess(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}
```

### 4.4 Sử Dụng Trong UI

```dart
BlocConsumer<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthSuccess) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
    if (state is AuthFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  builder: (context, state) {
    if (state is AuthLoading) {
      return CircularProgressIndicator();
    }
    return LoginForm();
  },
)
```

---

## 5. Dependency Injection

### 5.1 Tại Sao?
- Dễ test (mock dependencies)
- Dễ thay đổi implementation
- Quản lý lifecycle

### 5.2 Sử Dụng get_it

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
    () => AuthRepositoryImpl(authSource: sl(), firestoreSource: sl()),
  );
  
  // Data Sources
  sl.registerLazySingleton(() => FirebaseAuthSource());
  sl.registerLazySingleton(() => FirestoreSource());
}
```

### 5.3 Sử Dụng

```dart
// Trong main.dart
void main() async {
  init();
  runApp(MyApp());
}

// Trong Widget
final authBloc = sl<AuthBloc>();
```

---

## 6. Data Flow

### 6.1 Login Flow

```
User Input → LoginScreen → AuthBloc → LoginUseCase → AuthRepository → FirebaseAuth
    ↓           ↓            ↓           ↓              ↓              ↓
  Email    UI Update    State Change   Validation    Data Access    Authentication
    ↓           ↓            ↓           ↓              ↓              ↓
  Password  Show Loading  Emit Loading  Call Repo    Get User      Return Credential
    ↓           ↓            ↓           ↓              ↓              ↓
  Click     Hide Loading  Emit Success  Return User  Save to DB    Success
```

### 6.2 Code Example

```dart
// 1. User clicks login button
onPressed: () {
  context.read<AuthBloc>().add(
    LoginRequested(email: email, password: password),
  );
}

// 2. BLoC handles event
on<LoginRequested>((event, emit) async {
  emit(AuthLoading());
  try {
    final user = await loginUseCase(event.email, event.password);
    emit(AuthSuccess(user));
  } catch (e) {
    emit(AuthFailure(e.toString()));
  }
});

// 3. Use case validates and calls repository
Future<User> call(String email, String password) async {
  if (email.isEmpty || password.isEmpty) {
    throw ValidationException('Email và mật khẩu không được trống');
  }
  return await repository.login(email, password);
}

// 4. Repository calls data source
Future<User> login(String email, String password) async {
  final credential = await authSource.login(email, password);
  final userData = await firestoreSource.getUser(credential.user!.uid);
  return User.fromMap(userData);
}
```

---

## 7. Folder Structure Chi Tiết

```
lib/
├── main.dart
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart
│   │   └── app_constants.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── light_theme.dart
│   ├── utils/
│   │   ├── validators.dart
│   │   └── helpers.dart
│   ├── errors/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   └── di/
│       └── injection_container.dart
│
├── data/
│   ├── models/
│   │   ├── user_model.dart
│   │   └── family_model.dart
│   ├── datasources/
│   │   ├── remote/
│   │   │   ├── firebase_auth_source.dart
│   │   │   └── firestore_source.dart
│   │   └── local/
│   │       └── hive_source.dart
│   └── repositories/
│       ├── auth_repository_impl.dart
│       └── family_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── user.dart
│   │   └── family.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   └── family_repository.dart
│   └── usecases/
│       ├── auth/
│       │   ├── login_usecase.dart
│       │   └── register_usecase.dart
│       └── family/
│           └── create_family_usecase.dart
│
└── presentation/
    ├── screens/
    │   ├── auth/
    │   │   ├── login_screen.dart
    │   │   └── register_screen.dart
    │   └── dashboard/
    │       └── dashboard_screen.dart
    ├── widgets/
    │   ├── common/
    │   │   ├── custom_button.dart
    │   │   └── custom_text_field.dart
    │   └── auth/
    │       └── login_form.dart
    └── blocs/
        ├── auth/
        │   ├── auth_bloc.dart
        │   ├── auth_event.dart
        │   └── auth_state.dart
        └── dashboard/
            ├── dashboard_bloc.dart
            ├── dashboard_event.dart
            └── dashboard_state.dart
```

---

## 8. Testing

### 8.1 Unit Test

```dart
// test/unit/usecases/login_usecase_test.dart
void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockRepository;
  
  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUseCase(mockRepository);
  });
  
  test('should call repository.login with correct parameters', () async {
    // arrange
    when(() => mockRepository.login('email', 'password'))
        .thenAnswer((_) async => testUser);
    
    // act
    await useCase('email', 'password');
    
    // assert
    verify(() => mockRepository.login('email', 'password')).called(1);
  });
}
```

### 8.2 Widget Test

```dart
// test/widget/login_screen_test.dart
void main() {
  testWidgets('should show login form', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(loginUseCase: MockLoginUseCase()),
          child: LoginScreen(),
        ),
      ),
    );
    
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
```

---

## 9. Best Practices

### 9.1 Nguyên Tắc
- **Single Responsibility:** Mỗi class chỉ làm 1 việc
- **Dependency Inversion:** Phụ thuộc vào abstraction, không phụ thuộc vào implementation
- **Interface Segregation:** Interface nhỏ, cụ thể

### 9.2 Lưu Ý
- Không import infrastructure vào domain
- Không import presentation vào domain
- Sử dụng dependency injection
- Viết test cho business logic

---

## 10. Tóm Tắt

| Layer | Responsibility | Ví Dụ |
|-------|---------------|--------|
| Presentation | UI, User Interaction | Screen, Widget, BLoC |
| Application | Business Logic | Use Case, Service |
| Domain | Entities, Interfaces | User, AuthRepository |
| Infrastructure | Data Access | Firebase, Hive |

---

**Bài Tiếp Theo:** [Smart Lock Android](07-SMART-LOCK-ANDROID.md)
