# CẨM NANG TỐI ƯU HÓA FIREBASE QUOTA & NGĂN NGỪA CRASH HỆ THỐNG
**Dự án:** KidGuardian - Đồng Hành Số  
**Cập nhật lần cuối:** 2026-07-11  
**Tác giả:** KidGuardian Architecture Team  

---

## 1. TỔNG QUAN VẤN ĐỀ (PROBLEM STATEMENT)

Trong kiến trúc ứng dụng giám sát thời gian thực như **KidGuardian**, hai phân hệ **Phụ huynh (Parent App)** và **Học sinh (Child App)** liên tục giao tiếp với nhau thông qua cơ chế Realtime Stream (`snapshots()`) của Cloud Firestore và Push Notification (FCM).

### Các rủi ro kỹ thuật nguy hiểm nếu không tối ưu:
1. **Lỗi `RESOURCE_EXHAUSTED (Quota exceeded)`:** Gói Firebase Spark (miễn phí) giới hạn **50,000 Reads/ngày** và **20,000 Writes/ngày**. Nếu các event giám sát ứng dụng (`onAccessibilityEvent`) hoặc vòng lặp xác thực kích hoạt ghi/đọc không kiểm soát, toàn bộ hạn ngạch sẽ cạn kiệt chỉ trong vài phút test manual.
2. **Lỗi Tràn bộ nhớ (`Out of Memory - OOM` / `SIGABRT`) trên thiết bị:** Khi một Stream nhận về hàng nghìn event mỗi giây hoặc trigger vòng lặp vô tận (Infinite Loop), Flutter Engine trên Android/iOS không kịp thu gom rác (GC), dẫn đến crash ứng dụng ngay lập tức.

---

## 2. CÁC MÔ HÌNH THIẾT KẾ AN TOÀN (OPTIMIZATION PATTERNS)

Để bảo vệ hệ thống tuyệt đối, KidGuardian áp dụng **4 Design Patterns bắt buộc** trong toàn bộ Codebase:

### 2.1. Idempotency Guard & Concurrent Lock (Chống ghi lặp & Race Condition)
**Vấn đề gặp phải:** Khi lắng nghe `authStateChanges` từ Firebase Auth, mỗi khi document user thay đổi trên Firestore hoặc token refresh, listener bị trigger lại. Nếu trong listener có gọi hàm đăng ký FCM Token (`registerToken()`) mà không có chốt chặn, ứng dụng sẽ rơi vào vòng lặp vô hạn: *Update Token -> Trigger Auth/User Stream -> Update Token...*

**Giải pháp áp dụng (`lib/data/services/notification_service.dart`):**
```dart
String? _registeredToken; // Idempotency Guard: Token đã đăng ký thành công
bool _isRegistering = false; // Concurrent Lock: Khóa chống gọi đồng thời

Future<void> registerToken(String uid) async {
  if (_isRegistering) return;
  _isRegistering = true;
  try {
    final token = await _messaging.getToken();
    if (token == null) return;

    // CHỐT CHẶN THEN CHỐT: Chỉ ghi Firestore nếu token thực sự thay đổi
    if (_registeredToken == token) {
      debugPrint('FCM token unchanged, skipping Firestore update.');
      return;
    }

    await _firestore.collection('users').doc(uid).set({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).timeout(const Duration(seconds: 10));

    _registeredToken = token;
  } finally {
    _isRegistering = false;
  }
}
```

---

### 2.2. Cooldown Pattern (Giới hạn tần suất Event nhạy cảm)
**Vấn đề gặp phải:** Trợ năng Android (`AccessibilityService`) quét màn hình với tần suất cực cao (< 50ms/lần). Nếu trẻ mở ứng dụng bị cấm (như TikTok) hoặc gõ liên tục một từ khóa nhạy cảm trong khung chat, hệ thống có thể phát ra hàng chục event vi phạm trong 1 phút. Nếu mỗi event đều ghi 1 document `Alert` lên Firestore, Quota Writes sẽ bị bùng nổ.

**Giải pháp áp dụng (`lib/presentation/blocs/smart_lock/app_monitor_bloc.dart`):**
Sử dụng Bộ nhớ đệm trong RAM (`Map<String, DateTime>`) để áp dụng thời gian chờ (Cooldown) cho từng đối tượng:
- **Khóa ứng dụng (`createAppBlockedAlert`):** Cooldown **5 phút / App**.
- **Phát hiện từ khóa (`createKeywordAlert`):** Cooldown **10 phút / Keyword**.

```dart
// Cooldown Map lưu thời điểm gửi cuối cùng
final Map<String, DateTime> _lastKeywordAlertMap = {};

Future<void> _onKeywordDetected(KeywordDetectedEvent event, Emitter<AppMonitorState> emit) async {
  final cooldownKey = '${event.keyword}_${event.packageName}';
  final lastSent = _lastKeywordAlertMap[cooldownKey];
  final now = DateTime.now();

  // Kiểm tra: Nếu chưa qua 10 phút kể từ lần gửi trước -> Bỏ qua lệnh ghi DB
  if (lastSent != null && now.difference(lastSent).inMinutes < 10) {
    debugPrint('Keyword alert cooldown active for "${event.keyword}", skipping write.');
    return;
  }
  _lastKeywordAlertMap[cooldownKey] = now;

  // Thực hiện ghi lên Firestore an toàn...
  await alertRepository.createKeywordAlert(...);
}
```

---

### 2.3. Server-Side Filtering (Lọc dữ liệu tại phía DB thay vì Client)
**Vấn đề gặp phải:** Khi sử dụng `collectionGroup()` trên Firestore (ví dụ: lấy tất cả `alerts` của các con), nếu chỉ gọi `.snapshots()` rồi dùng mã Dart `list.where((doc) => ...)` để lọc trên điện thoại, Firestore vẫn sẽ tính phí **Reads** cho toàn bộ hàng nghìn document trong database của tất cả gia đình.

**Giải pháp áp dụng (`lib/domain/repositories/alert_repository.dart`):**
Bắt buộc đẩy điều kiện lọc xuống Firestore Query bằng `.where()` và tạo **Composite Index** tương ứng trên Firebase Console:

```dart
@override
Stream<List<AlertModel>> watchAllFamilyAlerts({required String familyId}) {
  return _firestore
      .collectionGroup('alerts')
      .where('familyId', isEqualTo: familyId) // Lọc ngay tại Server
      .where('type', isEqualTo: 'keyword_detected')
      .orderBy('timestamp', descending: true)
      .limit(50) // Giới hạn số lượng tài liệu đọc
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => AlertModel.fromFirestore(doc)).toList());
}
```

---

### 2.4. Query Limit & Pagination Guard (Giới hạn quy mô Stream)
**Quy tắc bất di bất dịch:** Không một Stream `snapshots()` nào trong repositories (`TimeRequestRepository`, `NotificationRepository`, `AlertRepository`) được phép chạy mà không có `.limit()`.
- **Hạn mức chuẩn:** `.limit(50)` cho các danh sách thông báo, yêu cầu xin giờ, lịch sử vi phạm.
- **Lý do:** Giúp mỗi lần mở app hoặc có thay đổi dữ liệu, client chỉ phải trả phí tối đa 50 Reads, giữ cho bộ nhớ RAM và băng thông mạng luôn ở mức cực thấp.

---

## 3. CHECKLIST KIỂM DUYỆT TRƯỚC KHI PUSH CODE (PR CHECKLIST)

Mọi lập trình viên khi thêm tính năng mới có tương tác với Firestore phải tự kiểm tra theo Checklist sau:

- [ ] **Khả năng Offline/Timeout:** Các lệnh `.set()`, `.add()`, `.update()` đã có `.timeout(const Duration(seconds: 10))` chưa?
- [ ] **Stream Dedup / Limit:** Các truy vấn `.snapshots()` đã có `.limit(N)` và `.orderBy()` chưa?
- [ ] **High-Frequency Guard:** Nếu tính năng được trigger bởi Timer hoặc Accessibility, đã có cơ chế **Cooldown / Cache Check** trước khi gọi API Cloud chưa?
- [ ] **No Client-Side Filtering on CollectionGroup:** Không dùng Dart `.where()` sau khi tải `collectionGroup()`. Phải dùng Firestore `.where()`.
- [ ] **Subscription Cleanup:** Tất cả `StreamSubscription` trong BLoC đã được `.cancel()` bên trong hàm `close()` chưa?

---
*Tài liệu này là chuẩn mực kỹ thuật bắt buộc của dự án KidGuardian. Mọi vi phạm dẫn đến thâm hụt Quota sẽ được phát hiện trong các bước Code Review.*
