---
marp: true
theme: default
paginate: true
style: |
  section {
    background-color: #f8f9fa;
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    padding: 40px 50px;
    font-size: 26px; /* Giảm nhẹ font chữ chung */
    overflow-y: auto; /* Cho phép cuộn toàn trang nếu text quá dài */
  }
  h1 {
    color: #2c3e50;
    font-size: 2.0em;
    text-align: center;
  }
  h2 {
    color: #34495e;
    border-bottom: 2px solid #3498db;
    padding-bottom: 10px;
    margin-bottom: 20px;
    font-size: 1.4em;
  }
  h3 {
    color: #2980b9;
    font-size: 1.2em;
  }
  .center {
    text-align: center;
  }
  code {
    background-color: #e8eaed;
    border-radius: 4px;
    padding: 2px 4px;
    color: #c0392b;
    font-size: 0.85em;
  }
  pre {
    background-color: #f1f3f5;
    border-left: 4px solid #3498db;
    max-height: 480px; /* Tăng chiều cao lên một chút do đã bỏ header/footer */
    overflow-y: auto;  /* Hiển thị thanh cuộn cho code dài */
    padding: 15px;
    box-shadow: inset 0 0 10px rgba(0,0,0,0.05);
  }
  pre code {
    color: #333;
    background-color: transparent;
    font-size: 0.85em;
  }
  /* Tùy chỉnh thanh cuộn (Scrollbar) cho đẹp mắt */
  ::-webkit-scrollbar {
    width: 8px;
    height: 8px;
  }
  ::-webkit-scrollbar-track {
    background: #e1e1e1; 
    border-radius: 4px;
  }
  ::-webkit-scrollbar-thumb {
    background: #888; 
    border-radius: 4px;
  }
  ::-webkit-scrollbar-thumb:hover {
    background: #555; 
  }
---

<!-- _class: lead -->
# 🚀 BUỔI 4: Kết Nối Backend (Firebase Auth)

**Thời gian:** 2 tiết (90 phút)    
**Mục tiêu:** Tạo Firebase project, implement đăng ký/đăng nhập

---

## 🎯 Tổng quan buổi học

- **Lý thuyết:** Nắm bắt các khái niệm quan trọng
- **Thực hành:** Áp dụng kiến thức vào thực tế
- **Bài tập:** Củng cố kiến thức đã học


---
<!-- _class: lead -->
# 📚 PHẦN 1: LÝ THUYẾT (30 phút)

---
## Backend Là Gì?

**Frontend** (Giao diện) = Phần người dùng thấy và tương tác  
**Backend** (Máy chủ) = Phần xử lý dữ liệu, lưu trữ

```
[Điện thoại] ←→ [Backend Server] ←→ [Database]
   Frontend         Backend           Database
```
---
## Firebase Là Gì?

**Firebase** = Backend-as-a-Service (BaaS) của Google

**Tại sao dùng Firebase?**

| Ưu Điểm | Giải Thích |
|----------|-----------|
| Miễn phí | Free Tier đủ cho dự án nhỏ |
| Dễ dùng | Không cần tự cài server |
| Bảo mật | Google quản lý |
| Real-time | Dữ liệu đồng bộ ngay lập tức |
---
## Firebase Authentication

**Firebase Auth** = Dịch vụ xác thực người dùng

**Hỗ trợ:**
- Email/Password
- Google Sign-in
- Facebook Sign-in
- Số điện thoại
- ...
---
## Quy Trình Xác Thực

```
1. Người dùng nhập Email + Password
2. App gửi lên Firebase
3. Firebase kiểm tra:
   - Email hợp lệ?
   - Password đúng?
   - Tài khoản tồn tại?
4. Trả kết quả:
   - Thành công → Token
   - Thất bại → Error
```

---

---
<!-- _class: lead -->
# 📚 PHẦN 2: THỰC HÀNH (60 phút)

---
## Tạo Firebase Project

**Bước 1: Truy cập Firebase Console**
- Mở: https://console.firebase.google.com
- Đăng nhập bằng tài khoản Google

**Bước 2: Tạo project mới**
1. Click "Add project"
2. Nhập tên: `KidGuardian`
3. Bật/tắt Google Analytics (tùy chọn)
4. Click "Create project"

**Bước 3: Thêm Android app**
1. Click biểu tượng Android
2. Nhập Package name: `com.example.kidguardian`
3. Nhập App nickname: `KidGuardian`
4. Click "Register app"
5. Tải file `google-services.json`
6. Copy file vào `android/app/`
---
## Cài Đặt Firebase Packages

**Thêm vào `pubspec.yaml`:**

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
```

**Chạy lệnh:**
```bash
flutter pub get
```
---
## Khởi Tạo Firebase

**Cập nhật `lib/main.dart`:**

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // Đảm bảo Flutter đã khởi tạo
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(KidGuardianApp());
}

class KidGuardianApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KidGuardian',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: LoginScreen(),
    );
  }
}
```

**Chạy lệnh cấu hình Firebase:**
```bash
flutterfire configure
```
---
## Tạo Login Screen

**Tạo file `lib/screens/login_screen.dart`:**

```dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // State
  bool _isLoading = false;
  String? _errorMessage;
  
  // Firebase Auth instance
  final _auth = FirebaseAuth.instance;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  // Hàm đăng nhập
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      // Đăng nhập thành công
      // Chuyển sang màn hình chính
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _errorMessage = 'Không tìm thấy tài khoản';
        } else if (e.code == 'wrong-password') {
          _errorMessage = 'Sai mật khẩu';
        } else {
          _errorMessage = 'Lỗi: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi không xác định';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng nhập'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Icon(
              Icons.shield,
              size: 80,
              color: Colors.blue,
            ),
            SizedBox(height: 30),
            
            // Email field
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 15),
            
            // Password field
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              obscureText: true,
            ),
            SizedBox(height: 10),
            
            // Error message
            if (_errorMessage != null)
              Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            
            // Login button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Đăng nhập', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            SizedBox(height: 15),
            
            // Register link
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegisterScreen(),
                  ),
                );
              },
              child: Text('Chưa có tài khoản? Đăng ký'),
            ),
          ],
        ),
      ),
    );
  }
}
```
---
## Tạo Register Screen

**Tạo file `lib/screens/register_screen.dart`:**

```dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  final _auth = FirebaseAuth.instance;
  
  Future<void> _register() async {
    // Kiểm tra mật khẩu khớp
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Mật khẩu không khớp';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Tạo tài khoản
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      // Cập nhật tên hiển thị
      await userCredential.user?.updateDisplayName(
        _nameController.text.trim(),
      );
      
      // Đăng ký thành công
      Navigator.pop(context); // Quay lại trang đăng nhập
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng ký thành công!')),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'weak-password') {
          _errorMessage = 'Mật khẩu quá yếu';
        } else if (e.code == 'email-already-in-use') {
          _errorMessage = 'Email đã được sử dụng';
        } else {
          _errorMessage = 'Lỗi: ${e.message}';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng ký'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 15),
              
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 15),
              
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 15),
              
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 10),
              
              if (_errorMessage != null)
                Text(_errorMessage!, style: TextStyle(color: Colors.red)),
              
              SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : Text('Đăng ký'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

---
<!-- _class: lead -->
# 📚 PHẦN 3: BÀI TẬP VỀ NHÀ

---
## Bài Tập 1: Hoàn Thiện Login Screen

**Yêu cầu:**
- Thêm nút "Quên mật khẩu"
- Sử dụng `sendPasswordResetEmail()` của Firebase
---
## Bài Tập 2: Thêm Loading Animation

**Yêu cầu:**
- Khi đang đăng nhập, hiển thị animation loading
- Sau khi đăng nhập thành công, hiển thị thông báo
---
## Bài Tập 3: Tìm Hiểu

**Câu hỏi:**
1. `FirebaseAuthException` là gì?
2. Các mã lỗi phổ biến khi đăng nhập?
3. Tại sao cần `dispose()` Controllers?

---
---
## TÀI LIỆU THAM KHẢO

- Firebase Auth: https://firebase.google.com/docs/auth/flutter/start
- Firebase Console: https://console.firebase.google.com

---
---
## CÂU HỎI ÔN TẬP

1. Firebase là gì?
2. Firebase Auth hỗ trợ những phương thức đăng nhập nào?
3. `signInWithEmailAndPassword()` làm gì?
4. Cách xử lý lỗi trong Firebase Auth?

---

**Buổi Tiếp Theo:** [Buổi 5 - Quản lý dữ liệu (Firestore)](../buoi-05/README.md)

---
<!-- _class: lead -->
# 🎉 Cảm ơn các bạn!
### Hẹn gặp lại vào buổi sau
