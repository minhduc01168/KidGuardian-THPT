# BUỔI 7: Logic Khóa Giờ (Smart Lock Mechanism)

**Thời gian:** 2 tiết (90 phút)  
**Mục tiêu:** Implement logic kiểm tra thời gian và hiển thị màn hình khóa

---

## PHẦN 1: LÝ THUYẾT (30 phút)

### 1.1 Logic Khóa Giờ

**Nguyên tắc:**
```
Nếu: thời_gian_sử_dụng >= giới_hạn
Thì: hiển_thị_màn_hình_khóa
```

**Flow:**
```
App đang chạy → Timer kiểm tra mỗi giây
                      ↓
            Kiểm tra: time_used >= quota?
                      ↓
           Có → Hiển thị Lock Screen
           Không → Tiếp tục chạy
```

### 1.2 Timer Trong Dart

**Timer** = Đối tượng thực hiện công việc sau mỗi khoảng thời gian

```dart
import 'dart:async';

// Timer gọi lại mỗi giây
Timer.periodic(Duration(seconds: 1), (timer) {
  print('Đã qua 1 giây');
});

// Hủy timer
timer.cancel();
```

### 1.3 DateTime Trong Dart

**DateTime** = Đại diện cho thời điểm

```dart
// Thời điểm hiện tại
DateTime now = DateTime.now();

// Tính khoảng cách
Duration difference = now.difference(startTime);
int minutes = difference.inMinutes;
```

---

## PHẦN 2: THỰC HÀNH (60 phút)

### 2.1 Tạo Time Tracker Service

**Tạo file `lib/services/time_tracker_service.dart`:**

```dart
import 'dart:async';

class TimeTrackerService {
  // Singleton pattern
  static final TimeTrackerService _instance = TimeTrackerService._internal();
  factory TimeTrackerService() => _instance;
  TimeTrackerService._internal();
  
  // State
  int _usedMinutes = 0;
  int _quotaMinutes = 120; // Default 2 hours
  DateTime? _startTime;
  Timer? _timer;
  
  // Stream để thông báo thay đổi
  final _timeController = StreamController<int>.broadcast();
  Stream<int> get timeStream => _timeController.stream;
  
  final _lockController = StreamController<bool>.broadcast();
  Stream<bool> get lockStream => _lockController.stream;
  
  // Getters
  int get usedMinutes => _usedMinutes;
  int get quotaMinutes => _quotaMinutes;
  int get remainingMinutes => _quotaMinutes - _usedMinutes;
  bool get isLocked => _usedMinutes >= _quotaMinutes;
  
  // Bắt đầu theo dõi
  void startTracking() {
    _startTime = DateTime.now();
    
    // Cập nhật mỗi phút
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      _updateUsedTime();
    });
    
    // Kiểm tra ngay lập tức
    _updateUsedTime();
  }
  
  // Dừng theo dõi
  void stopTracking() {
    _timer?.cancel();
    _timer = null;
  }
  
  // Cập nhật thời gian đã dùng
  void _updateUsedTime() {
    if (_startTime == null) return;
    
    Duration elapsed = DateTime.now().difference(_startTime!);
    _usedMinutes = elapsed.inMinutes;
    
    // Thông báo thay đổi
    _timeController.add(remainingMinutes);
    
    // Kiểm tra khóa
    if (isLocked) {
      _lockController.add(true);
    }
  }
  
  // Đặt giới hạn mới
  void setQuota(int minutes) {
    _quotaMinutes = minutes;
    _updateUsedTime();
  }
  
  // Thêm thời gian (khi phụ huynh đồng ý)
  void addTime(int minutes) {
    _quotaMinutes += minutes;
    _updateUsedTime();
  }
  
  // Reset (cho ngày mới)
  void reset() {
    _usedMinutes = 0;
    _startTime = DateTime.now();
    _timeController.add(remainingMinutes);
    _lockController.add(false);
  }
  
  // Giải phóng tài nguyên
  void dispose() {
    _timer?.cancel();
    _timeController.close();
    _lockController.close();
  }
}
```

### 2.2 Tạo Child Home Screen với Timer

**Cập nhật `lib/screens/child_home_screen.dart`:**

```dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/time_tracker_service.dart';

class ChildHomeScreen extends StatefulWidget {
  @override
  _ChildHomeScreenState createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  final TimeTrackerService _tracker = TimeTrackerService();
  StreamSubscription? _timeSubscription;
  StreamSubscription? _lockSubscription;
  
  int _remainingMinutes = 120;
  bool _isLocked = false;
  
  @override
  void initState() {
    super.initState();
    _startTracking();
  }
  
  void _startTracking() {
    // Bắt đầu theo dõi
    _tracker.startTracking();
    
    // Lắng nghe thay đổi thời gian
    _timeSubscription = _tracker.timeStream.listen((remaining) {
      setState(() {
        _remainingMinutes = remaining;
      });
    });
    
    // Lắng nghe sự kiện khóa
    _lockSubscription = _tracker.lockStream.listen((locked) {
      if (locked) {
        _showLockScreen();
      }
    });
  }
  
  void _showLockScreen() {
    setState(() {
      _isLocked = true;
    });
    
    // Hiển thị dialog khóa
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LockDialog(
        onRequestMoreTime: _requestMoreTime,
        onEmergencyCall: _emergencyCall,
      ),
    );
  }
  
  void _requestMoreTime() {
    // Gửi yêu cầu lên Firebase
    // Sẽ làm ở Buổi 8
    print('Gửi yêu cầu xin thêm giờ');
  }
  
  void _emergencyCall() {
    // Mở ứng dụng gọi điện
    print('Gọi khẩn cấp');
  }
  
  @override
  void dispose() {
    _timeSubscription?.cancel();
    _lockSubscription?.cancel();
    _tracker.dispose();
    super.dispose();
  }
  
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
                color: _remainingMinutes > 30 
                    ? Colors.green.shade100 
                    : Colors.red.shade100,
                border: Border.all(
                  color: _remainingMinutes > 30 
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
                    color: _remainingMinutes > 30 
                        ? Colors.green 
                        : Colors.red,
                  ),
                  SizedBox(height: 10),
                  Text(
                    '$_remainingMinutes',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _remainingMinutes > 30 
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
            
            // Thanh tiến trình
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: LinearProgressIndicator(
                value: _remainingMinutes / _tracker.quotaMinutes,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _remainingMinutes > 30 
                      ? Colors.green 
                      : Colors.red,
                ),
                minHeight: 10,
              ),
            ),
            
            SizedBox(height: 30),
            
            // Nút xin thêm giờ
            ElevatedButton.icon(
              onPressed: _requestMoreTime,
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

// Dialog khóa
class LockDialog extends StatelessWidget {
  final VoidCallback onRequestMoreTime;
  final VoidCallback onEmergencyCall;
  
  LockDialog({
    required this.onRequestMoreTime,
    required this.onEmergencyCall,
  });
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock,
              size: 80,
              color: Colors.red,
            ),
            SizedBox(height: 20),
            Text(
              'Đã hết thời gian!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Bạn đã sử dụng hết giới hạn hôm nay',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 30),
            
            // Nút xin thêm giờ
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onRequestMoreTime();
                },
                child: Text('Xin thêm 15 phút'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 10),
            
            // Nút gọi khẩn cấp
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onEmergencyCall();
                },
                icon: Icon(Icons.phone, color: Colors.red),
                label: Text(
                  'Gọi khẩn cấp',
                  style: TextStyle(color: Colors.red),
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

## PHẦN 3: BÀI TẬP VỀ NHÀ

### Bài Tập 1: Lưu Usage Log

**Yêu cầu:**
- Mỗi khi timer cập nhật, lưu log vào Firestore
- Bao gồm: thời điểm, thời lượng, app đang dùng

### Bài Tập 2: Lịch Sử Sử Dụng

**Yêu cầu:**
- Tạo màn hình xem lịch sử sử dụng
- Hiển thị danh sách logs theo ngày

### Bài Tập 3: Tìm Hiểu

**Câu hỏi:**
1. `Timer.periodic()` khác gì với `Future.delayed()`?
2. `StreamController` dùng để làm gì?
3. Tại sao cần `dispose()` Timer và Stream?

---

## TÀI LIỆU THAM KHẢO

- Dart Timer: https://api.dart.dev/stable/dart-async/Timer-class.html
- Dart Streams: https://dart.dev/tutorials/language/streams

---

## CÂU HỎI ÔN TẬP

1. Timer là gì? Cách sử dụng?
2. Stream là gì? Khác gì với Future?
3. Logic kiểm tra thời gian hoạt động thế nào?

---

**Buổi Tiếp Theo:** [Buổi 8 - Tương tác hai chiều](../buoi-08/README.md)
