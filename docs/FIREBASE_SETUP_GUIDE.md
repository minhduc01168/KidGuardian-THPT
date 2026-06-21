# Hướng Dẫn Thiết Lập Firebase Cho Dự Án KidGuardian

Tài liệu này được soạn thảo chi tiết từng bước (Step-by-step) dành cho người chưa từng sử dụng Firebase. Bạn có thể sử dụng tài liệu này để cấu hình dự án hoặc dùng làm giáo trình hướng dẫn cho học sinh.

---

## 📌 Tổng Quan
**Firebase** là một nền tảng của Google giúp cung cấp "backend" (máy chủ) có sẵn cho các ứng dụng di động mà không cần phải tự lập trình server từ số không. 

Đối với dự án **KidGuardian**, chúng ta bắt buộc phải sử dụng 2 dịch vụ chính của Firebase:
1. **Authentication (Xác thực):** Để quản lý tài khoản người dùng (Đăng ký, Đăng nhập, Quên mật khẩu).
2. **Cloud Firestore (Cơ sở dữ liệu):** Để lưu trữ thông tin Gia đình, Mã liên kết, Thời gian sử dụng, và Danh sách app bị khóa.

---

## 🛠️ PHẦN 1: TẠO DỰ ÁN TRÊN FIREBASE

1. Mở trình duyệt web và truy cập vào [Firebase Console](https://console.firebase.google.com/).
2. Đăng nhập bằng tài khoản Google của bạn (Gmail).
3. Tại giao diện chính, bấm vào nút trắng to **Add project** (Thêm dự án).
4. Nhập tên dự án (Ví dụ: `KidGuardian`) và bấm **Continue**.
5. Màn hình Google Analytics hiện ra, bạn có thể tắt đi (với dự án môn học thì chưa cần thiết) -> Bấm **Create project** (Tạo dự án).
6. Đợi 10-15 giây để quá trình hoàn tất, sau đó bấm **Continue**. Lúc này bạn đã vào được trang tổng quan (Dashboard) của dự án.

---

## 🔐 PHẦN 2: KÍCH HOẠT AUTHENTICATION (QUẢN LÝ TÀI KHOẢN)

KidGuardian sử dụng phương thức đăng nhập bằng **Email và Mật khẩu**. Nếu bạn không bật tính năng này, ứng dụng sẽ báo lỗi khi cố gắng Đăng ký tài khoản.

1. Tại màn hình chính của Firebase Console, nhìn sang **cột menu dọc bên trái**, mở phần **Build** (Xây dựng).
2. Bấm vào chữ **Authentication**.
3. Một màn hình giới thiệu hiện ra, bấm vào nút **Get started** (Bắt đầu).
4. Hệ thống sẽ chuyển sang tab **Sign-in method** (Phương thức đăng nhập).
5. Trong danh sách "Native providers", bấm chọn **Email/Password**.
6. Gạt công tắc đầu tiên (`Enable` ở mục Email/Password) sang màu xanh để bật. *(Lưu ý: Không cần bật "Email link")*.
7. Bấm **Save** (Lưu).

✅ *Thành công! Dự án của bạn đã sẵn sàng cho phép người dùng đăng ký.*

---

## 🗄️ PHẦN 3: KÍCH HOẠT CLOUD FIRESTORE (CƠ SỞ DỮ LIỆU)

Đây là bước cực kỳ quan trọng. Nếu không bật Database, ứng dụng sẽ không thể lưu trữ bất cứ thứ gì (không có mã liên kết, không có gia đình, không thể khóa máy).

1. Quay lại **cột menu dọc bên trái**, trong phần **Build**, chọn **Firestore Database**.
2. Bấm vào nút **Create database** (Tạo cơ sở dữ liệu).
3. Firebase sẽ hiển thị giao diện thiết lập mới. Hãy làm theo các bước sau:
   - **Database edition:** Chọn **Standard edition** (Phiên bản tiêu chuẩn - miễn phí và đầy đủ tính năng). Bấm **Next**.
   - **ID, Location, & API type:** Ở mục Location (Vị trí), chọn khu vực (Ví dụ: `asia-southeast1` hoặc giữ nguyên mặc định của Firebase). Các mục khác để nguyên. Bấm **Configure** (Thiết lập) hoặc **Create** (Tạo).
   - *(Lưu ý: Nếu màn hình có bước hỏi về Security rules (Quy tắc bảo mật), hãy chọn **Start in test mode**).*
4. Đợi vài giây để Firebase khởi tạo cơ sở dữ liệu.
5. **CẤU HÌNH BẢO MẬT (Rất Quan Trọng):** 
   - Sau khi tạo xong, trên màn hình Firestore, hãy chuyển sang tab **Rules** (Quy tắc) ở ngay thanh menu phía trên.
   - Tìm dòng có chữ `allow read, write: if false;` (nếu có).
   - Đổi chữ `false` thành `true` (thành: `allow read, write: if true;`). Thao tác này (Test mode) cho phép ứng dụng đọc/ghi dữ liệu thoải mái trong quá trình bạn hoặc học sinh đang lập trình.
   - Bấm nút **Publish** (Xuất bản) để lưu quy tắc mới.
6. Xong! Bạn quay lại tab **Data** (Dữ liệu), lúc này Database đã sẵn sàng hoạt động (màn hình sẽ có dòng chữ **Start collection**).

✅ *Thành công! Database của bạn đã sẵn sàng để lưu trữ mọi thứ từ KidGuardian.*

---

## 📱 PHẦN 4: KẾT NỐI APP FLUTTER VỚI FIREBASE (Dành cho học sinh làm lại từ đầu)

*(Lưu ý: Với dự án hiện tại trên máy tính của bạn, phần này ĐÃ ĐƯỢC LÀM SẴN. Nhưng nếu học sinh tải source code mới về máy khác, các em phải làm bước này).*

Để ứng dụng (app) có quyền nói chuyện với cái Firebase vừa tạo ở trên, bạn phải lấy một "chứng minh thư" từ Firebase bỏ vào thư mục code của app. File chứng minh thư này gọi là `google-services.json`.

1. Ở trang chủ Firebase Console, bấm vào nút có **biểu tượng Android** (nằm ở giữa màn hình, hoặc dưới chữ "Get started by adding Firebase to your app").
2. Đăng ký App:
   - **Android package name:** Điền chính xác `com.kidguardian.kidguardian` (hoặc tên package của app học sinh).
   - Bấm **Register app**.
3. Tải file cấu hình:
   - Bấm nút xanh **Download google-services.json** để tải file về máy tính.
   - Bấm **Next** cho đến khi hoàn thành (Skip các bước hướng dẫn code vì trong app Flutter đã cài thư viện sẵn rồi).
4. Đưa file vào dự án:
   - Copy file `google-services.json` vừa tải.
   - Dán đè vào thư mục `android/app/` trong thư mục code dự án KidGuardian.

---

## 🎯 TỔNG KẾT
Một dự án Firebase cho KidGuardian chỉ có thể hoạt động khi thỏa mãn **đủ 3 điều kiện**:
1. Đã bật **Authentication (Email/Password)**.
2. Đã tạo **Firestore Database** (chế độ Test mode).
3. Đã có file **google-services.json** nằm trong folder `android/app/`.

Chúc bạn và các học sinh hoàn thành xuất sắc dự án!
