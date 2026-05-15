# BUỔI 5: Quản Lý Dữ Liệu (Firestore)

**Thời gian:** 2 tiết (90 phút)  
**Mục tiêu:** Hiểu Firestore, lưu và đọc dữ liệu

---

## PHẦN 1: LÝ THUYẾT (30 phút)

### 1.1 Database Là Gì?

**Database** (Cơ sở dữ liệu) = Nơi lưu trữ dữ liệu có tổ chức

**Ví dụ:**
```
Ứng dụng Facebook:
- Database lưu: Tài khoản, Bài viết, Bình luận, Bạn bè...

KidGuardian:
- Database lưu: Tài khoản, Giới hạn thời gian, Lịch sử sử dụng...
```

### 1.2 SQL vs NoSQL

| Loại | Ví Dụ | Cấu Trúc |
|------|-------|-----------|
| SQL | MySQL, PostgreSQL | Bảng (Table) - Hàng - Cột |
| NoSQL | Firestore, MongoDB | Document - Collection |

### 1.3 Firestore Là Gì?

**Firestore** = Database NoSQL của Firebase

**Cấu trúc:**
```
Collection (Tập hợp)
    └── Document (Tài liệu)
            └── Field (Trường dữ liệu)

Ví dụ:
users (Collection)
    └── user_123 (Document)
            ├── name: "Nguyễn Văn A"
            ├── email: "a@gmail.com"
            └── role: "parent"
```

### 1.4 So Sánh với SQL

| SQL | Firestore |
|-----|-----------|
| Table | Collection |
| Row | Document |
| Column | Field |
| Query | Query |

---

## PHẦN 2: THỰC HÀNH (60 phút)

### 2.1 Cài Đặt Firestore

**Thêm vào `pubspec.yaml`:**

```yaml
dependencies:
  cloud_firestore: ^4.14.0
```

**Chạy:**
```bash
flutter pub get
```

### 2.2 Thiết Kế Cấu Trúc Database Cho KidGuardian

```
users (Collection)
    └── {userId} (Document)
            ├── name: "Nguyễn Văn A"
            ├── email: "parent@gmail.com"
            ├── role: "parent"
            └── familyId: "family_123"

families (Collection)
    └── {familyId} (Document)
            ├── parentUid: "user_123"
            ├── childUid: "user_456"
            └── settings (Sub-collection)
                    ├── dailyLimit: 120 (phút)
                    ├── blockedApps: ["TikTok", "Facebook"]
                    └── keywords: ["bạo lực", "xấu"]
```

### 2.3 Tạo Service Firestore

**Tạo file `lib/services/firestore_service.dart`:**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Lấy user ID hiện tại
  String? get currentUserId => _auth.currentUser?.uid;
  
  // ===== USER OPERATIONS =====
  
  // Tạo user mới
  Future<void> createUser({
    required String name,
    required String email,
    required String role,
  }) async {
    if (currentUserId == null) return;
    
    await _firestore.collection('users').doc(currentUserId).set({
      'name': name,
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Đọc thông tin user
  Future<Map<String, dynamic>?> getUserData() async {
    if (currentUserId == null) return null;
    
    DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();
    
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    }
    return null;
  }
  
  // ===== FAMILY SETTINGS =====
  
  // Lưu giới hạn thời gian
  Future<void> saveTimeLimit({
    required String familyId,
    required int dailyLimitMinutes,
  }) async {
    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('settings')
        .doc('time_limit')
        .set({
      'dailyLimit': dailyLimitMinutes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Đọc giới hạn thời gian
  Future<int> getTimeLimit(String familyId) async {
    DocumentSnapshot doc = await _firestore
        .collection('families')
        .doc(familyId)
        .collection('settings')
        .doc('time_limit')
        .get();
    
    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return data['dailyLimit'] ?? 120;
    }
    return 120; // Default 2 hours
  }
  
  // ===== USAGE LOGS =====
  
  // Lưu log sử dụng app
  Future<void> logAppUsage({
    required String familyId,
    required String appName,
    required int durationMinutes,
  }) async {
    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('usage_logs')
        .add({
      'appName': appName,
      'duration': durationMinutes,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
  
  // Đọc logs hôm nay
  Future<List<Map<String, dynamic>>> getTodayLogs(String familyId) async {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    
    QuerySnapshot snapshot = await _firestore
        .collection('families')
        .doc(familyId)
        .collection('usage_logs')
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .orderBy('timestamp', descending: true)
        .get();
    
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }
}
```

### 2.4 Sử Dụng Trong Màn Hình

**Cập nhật `lib/screens/parent_home_screen.dart`:**

```dart
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class ParentHomeScreen extends StatefulWidget {
  @override
  _ParentHomeScreenState createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  int _dailyLimit = 120; // Default 2 hours
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    try {
      String familyId = 'family_123'; // Sẽ lấy từ user data
      int limit = await _firestoreService.getTimeLimit(familyId);
      setState(() {
        _dailyLimit = limit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveLimit(int newLimit) async {
    try {
      String familyId = 'family_123';
      await _firestoreService.saveTimeLimit(
        familyId: familyId,
        dailyLimitMinutes: newLimit,
      );
      setState(() {
        _dailyLimit = newLimit;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã lưu giới hạn: $_dailyLimit phút')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Giới hạn hàng ngày',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            
            // Slider chọn giới hạn
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _dailyLimit.toDouble(),
                    min: 30,
                    max: 240,
                    divisions: 7,
                    label: '$_dailyLimit phút',
                    onChanged: (value) {
                      setState(() {
                        _dailyLimit = value.toInt();
                      });
                    },
                  ),
                ),
                Text('$_dailyLimit phút'),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Nút lưu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _saveLimit(_dailyLimit),
                child: Text('Lưu giới hạn'),
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

## PHẦN 3: BÀI TẬP VỀ NHÀ

### Bài Tập 1: Lưu Blocked Apps

**Yêu cầu:**
- Thêm chức năng lưu danh sách app bị chặn
- Cho phép phụ huynh chọn app từ danh sách

### Bài Tập 2: Đọc và Hiển Thị Logs

**Yêu cầu:**
- Hiển thị danh sách logs sử dụng app trong ngày
- Mỗi log hiển thị: tên app, thời gian, thời lượng

### Bài Tập 3: Tìm Hiểu

**Câu hỏi:**
1. Collection và Document trong Firestore khác nhau thế nào?
2. `FieldValue.serverTimestamp()` dùng để làm gì?
3. Tại sao cần `orderBy` và `where` trong query?

---

## TÀI LIỆU THAM KHẢO

- Firestore: https://firebase.google.com/docs/firestore
- Firestore Query: https://firebase.google.com/docs/firestore/query-data/queries

---

## CÂU HỎI ÔN TẬP

1. Firestore là gì? Khác gì với SQL?
2. Collection và Document là gì?
3. Cách tạo document mới trong Firestore?
4. Cách đọc dữ liệu từ Firestore?

---

**Buổi Tiếp Theo:** [Buổi 6 - Dashboard & Biểu đồ](../buoi-06/README.md)
