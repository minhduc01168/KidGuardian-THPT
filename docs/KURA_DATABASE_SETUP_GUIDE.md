# Hướng dẫn chi tiết Khởi tạo Database Firebase cho ứng dụng Kura

Tài liệu này cung cấp hướng dẫn từng bước (Step-by-Step) để khởi tạo và cấu hình cơ sở dữ liệu Firebase cho ứng dụng Kura (KidGuardian) từ con số 0.

---

## Bước 1: Đăng ký tài khoản và Tạo dự án Firebase

1. **Truy cập Firebase:** Mở trình duyệt và truy cập [Firebase Console](https://console.firebase.google.com/).
2. **Đăng nhập:** Sử dụng tài khoản Google (Gmail) của bạn để đăng nhập.
3. **Tạo dự án mới:** 
   - Nhấn vào nút **Add project** (Tạo dự án).
   - Nhập tên dự án: `Kura-Database` (hoặc tên tuỳ ý).
   - Nhấn **Continue**.
   - Tại bước Google Analytics, bạn có thể tắt (Disable) để quá trình tạo diễn ra nhanh hơn.
   - Nhấn **Create project** và chờ khoảng 30 giây để Firebase cấp phát tài nguyên. Khi xong, nhấn **Continue**.

---

## Bước 2: Kích hoạt Xác thực (Authentication)

Kura yêu cầu người dùng (Phụ huynh/Trẻ em) phải có tài khoản để phân quyền và quản lý dữ liệu.

1. Tại menu bên trái, mục **Build**, chọn **Authentication**.
2. Nhấn **Get started**.
3. Chọn tab **Sign-in method**.
4. Chọn **Email/Password** trong danh sách các nhà cung cấp (Native providers).
5. Bật công tắc (Enable) ở ô đầu tiên `Email/Password`. Không cần bật `Email link`.
6. Nhấn **Save**.

---

## Bước 3: Khởi tạo Cơ sở dữ liệu (Firestore Database)

Đây là nơi lưu trữ toàn bộ dữ liệu về Gia đình, Giới hạn thời gian, Báo cáo sử dụng.

1. Tại menu bên trái, mục **Build**, chọn **Firestore Database**.
2. Nhấn **Create database**.
3. **Chọn Location (Vị trí):** Lựa chọn vị trí máy chủ gần người dùng nhất (Ví dụ: `asia-southeast1` - Singapore). Sau đó nhấn **Next**.
4. **Cấu hình ban đầu:** Chọn **Start in test mode** để có thể lập trình và kết nối dễ dàng. Nhấn **Enable**.

---

## Bước 4: Thiết lập Cấu trúc Cơ sở dữ liệu (Database Schema)

Với Firestore (NoSQL), bạn **không cần phải tự tay tạo các bảng** (Collections) trước. Khi ứng dụng Kura lần đầu tiên chạy và người dùng đăng ký tài khoản, mã nguồn của Kura sẽ tự động sinh ra cấu trúc sau:

* **`users` (Collection):**
  - Document ID: UID của người dùng.
  - Chứa thông tin: Email, Role (`parent` hoặc `child`), `familyId`.
* **`families` (Collection):**
  - Document ID: ID gia đình tự sinh.
  - Chứa mã liên kết (linkingCode) và UID của phụ huynh.
  - **Sub-collections (Bảng con) bên trong gia đình:**
    - `app_limits`: Chứa giới hạn thời gian (phút) của từng ứng dụng MXH.
    - `app_logs` / `usage_logs`: Chứa log thời gian sử dụng thực tế của trẻ.
    - `time_requests`: Chứa các yêu cầu xin thêm giờ.
    - `alerts`: Chứa các cảnh báo khẩn cấp (xóa app, tắt quyền...).
    - `daily_summaries`: Thống kê tổng hợp theo ngày.
    - `weekly_reports`: Báo cáo sử dụng theo tuần.
    - `monthly_reports`: Báo cáo sử dụng theo tháng.
    - `notifications`: Thông báo đẩy.

*Lưu ý: Mọi thứ hoàn toàn tự động, bạn không cần phải bấm nút Add Collection bằng tay.*

---

## Bước 5: Cập nhật Quy tắc bảo mật (Security Rules)

Mặc dù chọn Test Mode, nhưng để đảm bảo tính lâu dài và chuẩn xác, bạn cần cấu hình Rules.

1. Trong giao diện **Firestore Database**, chọn tab **Rules**.
2. Xóa nội dung cũ và dán đoạn mã sau vào để đảm bảo chỉ những ai có tài khoản mới được đọc/ghi dữ liệu:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      // Chỉ cho phép thao tác nếu người dùng đã đăng nhập vào Kura
      allow read, write: if request.auth != null;
    }
  }
}
```
3. Nhấn **Publish** để lưu lại.

---

## Bước 6: Cấu hình Chỉ mục (Indexes) cho Kura

Kura có hệ thống truy vấn dữ liệu phức tạp (Collection Group Query) cho các tính năng quét đa thiết bị (alerts, timeRequests, báo cáo thống kê). 

Thay vì phải tạo thủ công từng cái trên giao diện web, Kura đã đóng gói sẵn toàn bộ hơn 14 Indexes vào file `firestore.indexes.json` trong source code.

**Cách triển khai tự động cực nhanh:**
1. Mở Terminal tại thư mục gốc của dự án KidGuardian.
2. Đăng nhập Firebase CLI (nếu chưa): `firebase login`
3. Chạy lệnh deploy:
```bash
firebase deploy --only firestore:indexes
```
4. Đợi khoảng 2-5 phút để Firebase đẩy toàn bộ cấu hình chỉ mục lên Server và Build xong (Trạng thái *Enabled*).

*(Nếu không có Firebase CLI, bạn vẫn có thể tạo thủ công bằng cách bấm vào các đường link xanh đỏ hiện ra trong cửa sổ Debug Logcat mỗi khi app bị lỗi tải dữ liệu).*

---

## 🎉 Hoàn thành!

Bạn đã thiết lập thành công 100% hệ thống Database cho ứng dụng Kura. 
Bước cuối cùng là đảm bảo file `google-services.json` (Android) đã được cập nhật từ **Project settings** vào thư mục `android/app/` để ứng dụng bắt đầu giao tiếp với Server.
