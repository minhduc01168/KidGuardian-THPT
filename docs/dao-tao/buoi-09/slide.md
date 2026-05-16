---
marp: true
theme: default
paginate: true
header: 'KidGuardian - Đồng Hành Số'
footer: 'BUỔI 9: Logic AI Lọc Nội Dung & Cảnh Báo An Toàn'
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
# 🚀 BUỔI 9: Logic AI Lọc Nội Dung & Cảnh Báo An Toàn

**Thời gian:** 2 tiết (90 phút)    
**Mục tiêu:** Implement tính năng lọc từ khóa và gửi cảnh báo

---

## 🎯 Tổng quan buổi học

- **Lý thuyết:** Nắm bắt các khái niệm quan trọng
- **Thực hành:** Áp dụng kiến thức vào thực tế
- **Bài tập:** Củng cố kiến thức đã học


---
<!-- _class: lead -->
# 📚 PHẦN 1: LÝ THUYẾT (30 phút)

---
## Regex Là Gì?

**Regex** (Regular Expression) = Chuỗi ký tự đặc biệt để tìm kiếm mẫu text

**Ví dụ:**
```
Tìm từ "bạo lực" trong văn bản:
- Văn bản: "Video có nội dung bạo lực"
- Regex: "bạo lực"
- Kết quả: Tìm thấy ✓
```
---
## Các Pattern Regex Cơ Bản

| Pattern | Ý Nghĩa | Ví Dụ |
|---------|---------|-------|
| `abc` | Chuỗi chính xác "abc" | "abc" |
| `a\|b` | a HOẶC b | "a" hoặc "b" |
| `[abc]` | Một trong a, b, c | "a", "b" hoặc "c" |
| `.` | Bất kỳ ký tự nào | "a", "1", "@" |
| `*` | 0 hoặc nhiều lần | "a*", "aa*" |
| `+` | 1 hoặc nhiều lần | "a+", "aa+" |
---
## Cách Hoạt Động Của Bộ Lọc

```
Input text → Quét từng từ khóa → Phát hiện? → Gửi cảnh báo
              (Blacklist)          Có
                                   ↓
                                  Không → Bỏ qua
```

---

---
<!-- _class: lead -->
# 📚 PHẦN 2: THỰC HÀNH (60 phút)

---
## Tạo Keyword Service

**Tạo file `lib/services/keyword_service.dart`:**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class KeywordService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Danh sách từ khóa mặc định
  final List<String> _defaultKeywords = [
    'bạo lực',
    'xấu',
    'nguy hiểm',
    'ma túy',
    'cờ bạc',
    'đánh nhau',
    'tự tử',
    'tự hại',
  ];
  
  // Kiểm tra text có chứa từ khóa không
  Map<String, dynamic>? checkForKeywords(String text) {
    String normalizedText = text.toLowerCase().trim();
    
    for (String keyword in _defaultKeywords) {
      if (normalizedText.contains(keyword.toLowerCase())) {
        return {
          'keyword': keyword,
          'context': _extractContext(normalizedText, keyword),
          'timestamp': DateTime.now(),
        };
      }
    }
    
    return null;
  }
  
  // Trích xuất context xung quanh từ khóa
  String _extractContext(String text, String keyword) {
    int index = text.indexOf(keyword.toLowerCase());
    if (index == -1) return '';
    
    int start = (index - 20).clamp(0, text.length);
    int end = (index + keyword.length + 20).clamp(0, text.length);
    
    String context = text.substring(start, end);
    if (start > 0) context = '...$context';
    if (end < text.length) context = '$context...';
    
    return context;
  }
  
  // Lưu cảnh báo vào Firestore
  Future<void> saveAlert({
    required String childUid,
    required String childName,
    required String keyword,
    required String context,
    required String appName,
  }) async {
    await _firestore.collection('alerts').add({
      'childUid': childUid,
      'childName': childName,
      'keyword': keyword,
      'context': context,
      'appName': appName,
      'status': 'unread',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
  
  // Lấy danh sách cảnh báo
  Stream<List<Map<String, dynamic>>> getAlerts() {
    return _firestore
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
  
  // Đánh dấu đã đọc
  Future<void> markAsRead(String alertId) async {
    await _firestore.collection('alerts').doc(alertId).update({
      'status': 'read',
    });
  }
  
  // Thêm từ khóa mới
  Future<void> addKeyword(String keyword) async {
    await _firestore.collection('settings').doc('keywords').update({
      'keywords': FieldValue.arrayUnion([keyword]),
    });
  }
  
  // Lấy danh sách từ khóa tùy chỉnh
  Future<List<String>> getCustomKeywords() async {
    DocumentSnapshot doc = await _firestore
        .collection('settings')
        .doc('keywords')
        .get();
    
    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return List<String>.from(data['keywords'] ?? []);
    }
    
    return [];
  }
}
```
---
## Tạo Alert Model

**Tạo file `lib/models/alert.dart`:**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Alert {
  final String id;
  final String childUid;
  final String childName;
  final String keyword;
  final String context;
  final String appName;
  final String status;
  final DateTime timestamp;
  
  Alert({
    required this.id,
    required this.childUid,
    required this.childName,
    required this.keyword,
    required this.context,
    required this.appName,
    required this.status,
    required this.timestamp,
  });
  
  factory Alert.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Alert(
      id: doc.id,
      childUid: data['childUid'] ?? '',
      childName: data['childName'] ?? '',
      keyword: data['keyword'] ?? '',
      context: data['context'] ?? '',
      appName: data['appName'] ?? '',
      status: data['status'] ?? 'unread',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
```
---
## Tạo Alerts Screen Cho Phụ Huynh

**Tạo file `lib/screens/parent_alerts_screen.dart`:**

```dart
import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../services/keyword_service.dart';

class ParentAlertsScreen extends StatelessWidget {
  final KeywordService _keywordService = KeywordService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cảnh báo an toàn'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _keywordService.getAlerts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 80, color: Colors.green),
                  SizedBox(height: 20),
                  Text(
                    'Không có cảnh báo nào',
                    style: TextStyle(fontSize: 18),
                  ),
                  Text(
                    'Con bạn đang an toàn!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> alertData = snapshot.data![index];
              return AlertCard(alertData: alertData);
            },
          );
        },
      ),
    );
  }
}

class AlertCard extends StatelessWidget {
  final Map<String, dynamic> alertData;
  
  AlertCard({required this.alertData});
  
  @override
  Widget build(BuildContext context) {
    bool isUnread = alertData['status'] == 'unread';
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isUnread ? Colors.red.shade50 : null,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: isUnread ? Colors.red : Colors.grey,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phát hiện từ khóa nhạy cảm',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isUnread ? Colors.red : Colors.grey,
                        ),
                      ),
                      Text(
                        '${alertData['childName']} - ${alertData['appName']}',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (isUnread)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Mới',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Hiển thị từ khóa
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.vpn_key, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    'Từ khóa: ${alertData['keyword']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 8),
            
            // Hiển thị context
            if (alertData['context'] != null && alertData['context'].isNotEmpty)
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${alertData['context']}"',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            
            SizedBox(height: 12),
            
            // Thời gian
            Text(
              _formatTime(alertData['timestamp']),
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return '';
    
    Duration difference = DateTime.now().difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else {
      return '${difference.inDays} ngày trước';
    }
  }
}
```
---
## Tạo Keyword Management Screen

**Tạo file `lib/screens/keyword_management_screen.dart`:**

```dart
import 'package:flutter/material.dart';
import '../services/keyword_service.dart';

class KeywordManagementScreen extends StatefulWidget {
  @override
  _KeywordManagementScreenState createState() => _KeywordManagementScreenState();
}

class _KeywordManagementScreenState extends State<KeywordManagementScreen> {
  final KeywordService _keywordService = KeywordService();
  final TextEditingController _keywordController = TextEditingController();
  
  List<String> _keywords = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadKeywords();
  }
  
  Future<void> _loadKeywords() async {
    List<String> keywords = await _keywordService.getCustomKeywords();
    setState(() {
      _keywords = keywords;
      _isLoading = false;
    });
  }
  
  Future<void> _addKeyword() async {
    String keyword = _keywordController.text.trim();
    if (keyword.isEmpty) return;
    
    await _keywordService.addKeyword(keyword);
    _keywordController.clear();
    await _loadKeywords();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã thêm từ khóa: $keyword')),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý từ khóa'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Thêm từ khóa mới
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _keywordController,
                          decoration: InputDecoration(
                            labelText: 'Thêm từ khóa mới',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _addKeyword,
                        child: Text('Thêm'),
                      ),
                    ],
                  ),
                ),
                
                // Danh sách từ khóa
                Expanded(
                  child: _keywords.isEmpty
                      ? Center(
                          child: Text('Chưa có từ khóa tùy chỉnh'),
                        )
                      : ListView.builder(
                          itemCount: _keywords.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: Icon(Icons.vpn_key),
                              title: Text(_keywords[index]),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  // Xóa từ khóa
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
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
## Bài Tập 1: Cải Thiện Regex

**Yêu cầu:**
- Hỗ trợ tìm kiếm không phân biệt hoa/thường
- Hỗ trợ tìm kiếm gần đúng (fuzzy search)
---
## Bài Tập 2: Thêm Push Notification

**Yêu cầu:**
- Khi phát hiện từ khóa, gửi Push Notification đến phụ huynh
- Sử dụng Firebase Cloud Messaging
---
## Bài Tập 3: Tìm Hiểu

**Câu hỏi:**
1. Regex là gì? Tại sao dùng cho lọc nội dung?
2. `toLowerCase()` dùng để làm gì?
3. Cách gửi Push Notification với FCM?

---
---
## TÀI LIỆU THAM KHẢO

- Dart Regex: https://api.dart.dev/stable/dart-core/RegExp-class.html
- FCM: https://firebase.google.com/docs/cloud-messaging

---
---
## CÂU HỎI ÔN TẬP

1. Regex là gì?
2. Cách kiểm tra text chứa từ khóa?
3. Cách lưu cảnh báo vào Firestore?

---

**Buổi Tiếp Theo:** [Buổi 10 - Hoàn thiện & Build APK](../buoi-10/README.md)

---
<!-- _class: lead -->
# 🎉 Cảm ơn các bạn!
### Hẹn gặp lại vào buổi sau
