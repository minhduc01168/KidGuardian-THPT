# Hướng Dẫn Deploy và Quản Lý Firebase Cloud Functions (Push Notification)

Tài liệu này hướng dẫn chi tiết cách cấu hình, triển khai (deploy) và vận hành hệ thống Push Notification tự động (dành cho yêu cầu xin thêm giờ và cảnh báo từ khóa) cho KidGuardian thông qua Firebase Cloud Functions.

---

## 1. Tổng Quan Kiến Trúc

Hệ thống Push Notification hoạt động dựa trên Cloud Functions v2 (Event-driven triggers từ Firestore):

1. **Xin thêm giờ (`onTimeRequestCreated`)**:
   - Trigger: Khi trẻ tạo yêu cầu xin thêm giờ (`timeRequests/{requestId}`) trên máy con.
   - Hành động: Lấy `fcmToken` của phụ huynh từ `users/{parentUid}` → gửi FCM High Priority Push Notification đến máy phụ huynh.

2. **Cảnh báo từ khóa (`onKeywordAlertCreated`)**:
   - Trigger: Khi phát hiện từ khóa cấm (`alerts/{alertId}` có `type == "keyword_detected"`).
   - Hành động: Lấy `fcmToken` phụ huynh → gửi FCM Push Notification tức thì với nội dung cảnh báo.

---

## 2. Cấu Trúc Thư Mục & Codebase

- Thư mục backend: `/functions`
- File trigger chính: `/functions/index.js`
- Cấu hình Firebase: `/firebase.json` và `/.firebaserc`
- Runtime Node.js: `Node.js 20`

---

## 3. Các Bước Deploy Cloud Functions

### Bước 1: Chuẩn bị tài khoản & Gói Firebase
- Đảm bảo dự án Firebase (`kidguardian-b54f7`) đã được nâng cấp lên **gói Blaze** (Pay-as-you-go).
  - *Lưu ý*: Với số lượng người dùng nhỏ (< 1.000 gia đình), toàn bộ lưu lượng sử dụng nằm hoàn toàn trong hạn mức miễn phí (Free Tier: 2,000,000 lượt gọi/tháng), hoàn toàn không phát sinh chi phí.

### Bước 2: Đăng nhập Firebase CLI (Nếu chưa đăng nhập)
```bash
firebase login
```
*(Hoặc dùng `firebase login --no-localhost` nếu thao tác trên môi trường terminal không có trình duyệt).*

### Bước 3: Triển khai (Deploy) lên Firebase
Chạy lệnh sau tại thư mục gốc của dự án:
```bash
cd /home/minhduc168/KidGuardian-THPT
firebase deploy --only functions
```

### Bước 4: Kiểm tra trạng thái sau khi Deploy
- Xóa bớt container image cũ tự động (Cleanup policy): Nhập số ngày (ví dụ `7`) nếu CLI hỏi.
- Kiểm tra danh sách Functions đã hoạt động trên Firebase Console:
  `https://console.firebase.google.com/project/kidguardian-b54f7/functions`

---

## 4. Xem Logs Realtime & Troubleshooting

Xem log hoạt động trực tiếp của Cloud Functions:
```bash
firebase functions:log --only onTimeRequestCreated,onKeywordAlertCreated
```

---

## 5. Lưu Ý Quan Trọng Về Data Structure
Để Cloud Functions gửi Push Notification đúng đến phụ huynh:
- Cấu trúc document `families/{familyId}` trong Firestore **bắt buộc** phải chứa trường `parentUid`:
  ```json
  {
    "parentUid": "string_uid_phu_huynh"
  }
  ```
- Tài khoản phụ huynh trong document `users/{parentUid}` phải chứa trường `fcmToken`:
  ```json
  {
    "fcmToken": "string_fcm_token"
  }
  ```
*(Trường `fcmToken` đã được Flutter app tự động lưu khi phụ huynh đăng nhập vào ứng dụng).*
