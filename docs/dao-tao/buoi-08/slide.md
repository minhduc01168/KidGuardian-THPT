---
marp: true
theme: default
paginate: true
header: 'KidGuardian - Đồng Hành Số'
footer: 'BUỔI 8: Tương Tác Hai Chiều (Request & Approve)'
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
# 🚀 BUỔI 8: Tương Tác Hai Chiều (Request & Approve)

**Thời gian:** 2 tiết (90 phút)    
**Mục tiêu:** Implement tính năng xin thêm giờ và phê duyệt

---

## 🎯 Tổng quan buổi học

- **Lý thuyết:** Nắm bắt các khái niệm quan trọng
- **Thực hành:** Áp dụng kiến thức vào thực tế
- **Bài tập:** Củng cố kiến thức đã học


---
<!-- _class: lead -->
# 📚 PHẦN 1: LÝ THUYẾT (30 phút)

---
## Luồng Xin Thêm Giờ

```
[Con]                    [Firebase]              [Phụ huynh]
  │                          │                        │
  │  Gửi yêu cầu            │                        │
  │─────────────────────────▶│                        │
  │                          │  Thông báo (FCM)       │
  │                          │───────────────────────▶│
  │                          │                        │
  │                          │  Phê duyệt/Từ chối     │
  │                          │◀───────────────────────│
  │  Cập nhật quota          │                        │
  │◀─────────────────────────│                        │
```
---
## Real-time Listener

**Real-time** = Dữ liệu thay đổi → UI cập nhật ngay lập tức

```dart
// Lắng nghe thay đổi từ Firestore
FirebaseFirestore.instance
    .collection('requests')
    .snapshots()
    .listen((snapshot) {
  // Xử lý khi có thay đổi
});
```
---
## Push Notification

**Push Notification** = Thông báo đẩy từ server đến điện thoại

**Firebase Cloud Messaging (FCM):**
- Miễn phí
- Hỗ trợ Android và iOS
- Có thể gửi từ server hoặc console

---

---
<!-- _class: lead -->
# 📚 PHẦN 2: THỰC HÀNH (60 phút)

---
## Tạo Request Model

**Tạo file `lib/models/time_request.dart`:**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TimeRequest {
  final String id;
  final String childUid;
  final String childName;
  final int requestedMinutes;
  final String reason;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final DateTime? respondedAt;
  
  TimeRequest({
    required this.id,
    required this.childUid,
    required this.childName,
    required this.requestedMinutes,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });
  
  factory TimeRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TimeRequest(
      id: doc.id,
      childUid: data['childUid'] ?? '',
      childName: data['childName'] ?? '',
      requestedMinutes: data['requestedMinutes'] ?? 15,
      reason: data['reason'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null 
          ? (data['respondedAt'] as Timestamp).toDate() 
          : null,
    );
  }
}
```
---
## Tạo Request Service

**Tạo file `lib/services/request_service.dart`:**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/time_request.dart';

class RequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Gửi yêu cầu xin thêm giờ
  Future<void> sendRequest({
    required String childUid,
    required String childName,
    required int requestedMinutes,
    required String reason,
  }) async {
    await _firestore.collection('requests').add({
      'childUid': childUid,
      'childName': childName,
      'requestedMinutes': requestedMinutes,
      'reason': reason,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Lắng nghe yêu cầu (cho phụ huynh)
  Stream<List<TimeRequest>> getPendingRequests() {
    return _firestore
        .collection('requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TimeRequest.fromFirestore(doc)).toList();
    });
  }
  
  // Phê duyệt yêu cầu
  Future<void> approveRequest(String requestId, int additionalMinutes) async {
    await _firestore.collection('requests').doc(requestId).update({
      'status': 'approved',
      'respondedAt': FieldValue.serverTimestamp(),
    });
    
    // Cập nhật quota của con
    // Sẽ implement sau
  }
  
  // Từ chối yêu cầu
  Future<void> rejectRequest(String requestId, String reason) async {
    await _firestore.collection('requests').doc(requestId).update({
      'status': 'rejected',
      'rejectReason': reason,
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Lắng nghe trạng thái yêu cầu (cho con)
  Stream<TimeRequest?> getRequestStatus(String requestId) {
    return _firestore
        .collection('requests')
        .doc(requestId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return TimeRequest.fromFirestore(doc);
      }
      return null;
    });
  }
}
```
---
## Cập Nhật Child Home Screen

**Thêm nút "Xin thêm giờ" vào `lib/screens/child_home_screen.dart`:**

```dart
void _showRequestDialog() {
  final _reasonController = TextEditingController();
  int _selectedMinutes = 15;
  
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Xin thêm thời gian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn muốn xin thêm bao nhiêu phút?'),
            SizedBox(height: 20),
            
            // Chọn số phút
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [15, 30, 45].map((minutes) {
                return ChoiceChip(
                  label: Text('$minutes phút'),
                  selected: _selectedMinutes == minutes,
                  onSelected: (selected) {
                    setState(() {
                      _selectedMinutes = minutes;
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            
            // Lý do
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Lý do (tùy chọn)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _sendRequest(_selectedMinutes, _reasonController.text);
              Navigator.pop(context);
            },
            child: Text('Gửi yêu cầu'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _sendRequest(int minutes, String reason) async {
  try {
    await RequestService().sendRequest(
      childUid: 'child_uid', // Sẽ lấy từ Firebase Auth
      childName: 'Bé Linh',
      requestedMinutes: minutes,
      reason: reason,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã gửi yêu cầu!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lỗi: $e')),
    );
  }
}
```
---
## Tạo Parent Requests Screen

**Tạo file `lib/screens/parent_requests_screen.dart`:**

```dart
import 'package:flutter/material.dart';
import '../models/time_request.dart';
import '../services/request_service.dart';

class ParentRequestsScreen extends StatelessWidget {
  final RequestService _requestService = RequestService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yêu cầu từ con'),
      ),
      body: StreamBuilder<List<TimeRequest>>(
        stream: _requestService.getPendingRequests(),
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
                    'Không có yêu cầu nào',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              TimeRequest request = snapshot.data![index];
              return RequestCard(
                request: request,
                onApprove: () => _approveRequest(context, request),
                onReject: () => _rejectRequest(context, request),
              );
            },
          );
        },
      ),
    );
  }
  
  void _approveRequest(BuildContext context, TimeRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Phê duyệt yêu cầu'),
        content: Text(
          'Cho phép ${request.childName} thêm ${request.requestedMinutes} phút?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _requestService.approveRequest(
                request.id,
                request.requestedMinutes,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã phê duyệt!')),
              );
            },
            child: Text('Đồng ý'),
          ),
        ],
      ),
    );
  }
  
  void _rejectRequest(BuildContext context, TimeRequest request) {
    final _reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Từ chối yêu cầu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Từ chối yêu cầu của ${request.childName}?'),
            SizedBox(height: 20),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Lý do (tùy chọn)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _requestService.rejectRequest(
                request.id,
                _reasonController.text,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Từ chối'),
          ),
        ],
      ),
    );
  }
}

class RequestCard extends StatelessWidget {
  final TimeRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  
  RequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Icon(Icons.person),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.childName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Xin thêm ${request.requestedMinutes} phút',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (request.reason.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                'Lý do: ${request.reason}',
                style: TextStyle(color: Colors.grey),
              ),
            ],
            
            SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onReject,
                  child: Text('Từ chối'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: onApprove,
                  child: Text('Đồng ý'),
                ),
              ],
            ),
          ],
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
## Bài Tập 1: Thông Báo Real-time

**Yêu cầu:**
- Khi có yêu cầu mới, hiển thị badge trên icon
- Sử dụng `StreamBuilder` để lắng nghe thay đổi
---
## Bài Tập 2: Lịch Sử Yêu Cầu

**Yêu cầu:**
- Tạo màn hình xem lịch sử yêu cầu
- Hiển thị cả yêu cầu đã duyệt và từ chối
---
## Bài Tập 3: Tìm Hiểu

**Câu hỏi:**
1. `StreamBuilder` khác gì với `FutureBuilder`?
2. Tại sao cần `snapshots()` trong Firestore?
3. Cách gửi Push Notification với FCM?

---
---
## TÀI LIỆU THAM KHẢO

- Firestore Real-time: https://firebase.google.com/docs/firestore/query-data/listen
- FCM: https://firebase.google.com/docs/cloud-messaging

---
---
## CÂU HỎI ÔN TẬP

1. Real-time listener là gì?
2. StreamBuilder hoạt động thế nào?
3. Luồng xin thêm giờ hoạt động ra sao?

---

**Buổi Tiếp Theo:** [Buổi 9 - Lọc nội dung & Cảnh báo](../buoi-09/README.md)

---
<!-- _class: lead -->
# 🎉 Cảm ơn các bạn!
### Hẹn gặp lại vào buổi sau
