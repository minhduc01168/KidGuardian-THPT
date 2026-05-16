---
marp: true
theme: default
paginate: true
header: 'KidGuardian - Đồng Hành Số'
footer: 'BUỔI 3: Giao Diện Phân Quyền (Role-based UI)'
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
    max-height: 420px; /* Giới hạn chiều cao cho khối code */
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
# 🚀 BUỔI 3: Giao Diện Phân Quyền (Role-based UI)

**Thời gian:** 2 tiết (90 phút)    
**Mục tiêu:** Hiểu State Management, chuyển đổi giao diện theo vai trò

---

## 🎯 Tổng quan buổi học

- **Lý thuyết:** Nắm bắt các khái niệm quan trọng
- **Thực hành:** Áp dụng kiến thức vào thực tế
- **Bài tập:** Củng cố kiến thức đã học


---
<!-- _class: lead -->
# 📚 PHẦN 1: LÝ THUYẾT (30 phút)

---
## State Là Gì?

**State** (Trạng thái) = Dữ liệu có thể thay đổi trong ứng dụng

**Ví dụ:**
```
Người dùng chọn "Phụ huynh" → App hiển thị giao diện phụ huynh
Người dùng chọn "Con"       → App hiển thị giao diện con

State ở đây là: "vai trò hiện tại" (parent hoặc child)
```
---
## StatelessWidget vs StatefulWidget

| Loại | Đặc Điểm | Khi Nào Dùng |
|------|-----------|--------------|
| StatelessWidget | Không thay đổi | Màn hình tĩnh (About, Help) |
| StatefulWidget | Có thể thay đổi | Màn hình động (Login, Form) |

**Ví dụ:**
```dart
// StatelessWidget - Không thay đổi
class HelloWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('Hello'); // Luôn hiển thị "Hello"
  }
}

// StatefulWidget - Có thể thay đổi
class CounterWidget extends StatefulWidget {
  @override
  _CounterWidgetState createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int count = 0; // State - có thể thay đổi
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: $count'),
        ElevatedButton(
          onPressed: () {
            setState(() {
              count++; // Thay đổi state → UI cập nhật
            });
          },
          child: Text('Tăng'),
        ),
      ],
    );
  }
}
```
---
## setState Là Gì?

**`setState()`** = Hàm thông báo cho Flutter: "State đã thay đổi, hãy vẽ lại UI"

```
setState(() {
  // Thay đổi state ở đây
});
→ Flutter gọi lại build()
→ UI được cập nhật
```

---

---
<!-- _class: lead -->
# 📚 PHẦN 2: THỰC HÀNH (60 phút)

---
## Tạo Màn Hình Chọn Vai Trò

**Tạo file `lib/screens/role_selection_screen.dart`:**

```dart
import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chọn vai trò'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bạn là ai?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 40),
            
            // Nút Phụ huynh
            SizedBox(
              width: double.infinity,
              height: 120,
              child: ElevatedButton(
                onPressed: () {
                  // Chuyển sang giao diện phụ huynh
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person, size: 40),
                    SizedBox(height: 10),
                    Text(
                      'Phụ huynh',
                      style: TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Nút Con
            SizedBox(
              width: double.infinity,
              height: 120,
              child: ElevatedButton(
                onPressed: () {
                  // Chuyển sang giao diện con
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.child_care, size: 40),
                    SizedBox(height: 10),
                    Text(
                      'Con',
                      style: TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```
---
## Tạo Màn Hình Home Cho Trẻ Em

**Tạo file `lib/screens/child_home_screen.dart`:**

```dart
import 'package:flutter/material.dart';

class ChildHomeScreen extends StatefulWidget {
  @override
  _ChildHomeScreenState createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  // State
  int remainingMinutes = 90; // Thời gian còn lại
  String currentApp = 'TikTok'; // App đang sử dụng
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('KidGuardian'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Đồng hồ đếm ngược
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: remainingMinutes > 30 
                    ? Colors.green.shade100 
                    : Colors.red.shade100,
                border: Border.all(
                  color: remainingMinutes > 30 
                      ? Colors.green 
                      : Colors.red,
                  width: 4,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer,
                    size: 40,
                    color: remainingMinutes > 30 
                        ? Colors.green 
                        : Colors.red,
                  ),
                  SizedBox(height: 10),
                  Text(
                    '$remainingMinutes',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: remainingMinutes > 30 
                          ? Colors.green 
                          : Colors.red,
                    ),
                  ),
                  Text(
                    'phút còn lại',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 30),
            
            // Thông tin app hiện tại
            Card(
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Row(
                  children: [
                    Icon(Icons.apps, size: 30),
                    SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đang sử dụng',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          currentApp,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 30),
            
            // Nút xin thêm giờ
            ElevatedButton.icon(
              onPressed: () {
                // Sẽ làm ở buổi sau
              },
              icon: Icon(Icons.access_time),
              label: Text('Xin thêm 15 phút'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```
---
## Kết Nối Các Màn Hình

**Cập nhật `lib/main.dart`:**

```dart
import 'package:flutter/material.dart';
import 'screens/role_selection_screen.dart';
import 'screens/child_home_screen.dart';

void main() {
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
      home: RoleSelectionScreen(),
    );
  }
}
```
---
## Thêm Navigation

**Cập nhật RoleSelectionScreen để chuyển màn hình:**

```dart
// Trong RoleSelectionScreen
ElevatedButton(
  onPressed: () {
    // Chuyển sang giao diện con
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChildHomeScreen(),
      ),
    );
  },
  // ...
),
```

---

---
<!-- _class: lead -->
# 📚 PHẦN 3: BÀI TẬP VỀ NHÀ

---
## Bài Tập 1: Tạo Màn Hình Home Cho Phụ Huynh

**Yêu cầu:**
- Tạo file `lib/screens/parent_home_screen.dart`
- Hiển thị:
  - Tên con
  - Tổng thời gian sử dụng
  - Nút "Đặt giới hạn"
  - Nút "Xem thông báo"
---
## Bài Tập 2: Thêm Bộ Đếm Ngược

**Yêu cầu:**
- Trong `ChildHomeScreen`, thêm Timer đếm ngược
- Mỗi phút giảm 1 đơn vị
- Khi hết thời gian → Hiển thị thông báo

**Gợi ý:**
```dart
import 'dart:async';

// Trong _ChildHomeScreenState
Timer? _timer;

void startTimer() {
  _timer = Timer.periodic(Duration(minutes: 1), (timer) {
    setState(() {
      if (remainingMinutes > 0) {
        remainingMinutes--;
      } else {
        timer.cancel();
        // Hiển thị màn hình khóa
      }
    });
  });
}

@override
void initState() {
  super.initState();
  startTimer();
}

@override
void dispose() {
  _timer?.cancel();
  super.dispose();
}
```
---
## Bài Tập 3: Tìm Hiểu

**Câu hỏi:**
1. `setState()` dùng để làm gì?
2. Sự khác biệt giữa `Navigator.push` và `Navigator.pushReplacement` là gì?
3. Tại sao cần `dispose()` Timer?

---
---
## TÀI LIỆU THAM KHẢO

- Flutter State Management: https://docs.flutter.dev/data-and-backend/state-mgmt/intro
- Navigator: https://docs.flutter.dev/ui/navigation
- Timer: https://api.dart.dev/stable/dart-async/Timer-class.html

---
---
## CÂU HỎI ÔN TẬP

1. State là gì?
2. Khi nào dùng `StatelessWidget`, khi nào dùng `StatefulWidget`?
3. `setState()` hoạt động như thế nào?
4. Cách chuyển màn hình trong Flutter?

---

**Buổi Tiếp Theo:** [Buổi 4 - Kết nối Backend (Firebase Auth)](../buoi-04/README.md)

---
<!-- _class: lead -->
# 🎉 Cảm ơn các bạn!
### Hẹn gặp lại vào buổi sau
