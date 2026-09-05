# Hướng Dẫn Xóa Trắng Cơ Sở Dữ Liệu (Clear Firebase Database)

Tài liệu này hướng dẫn cách xóa sạch dữ liệu cũ trên hệ thống Firebase của dự án KidGuardian. Việc này giúp đưa hệ thống về trạng thái "sạch" hoàn toàn, tương đương với lúc mới khởi tạo ứng dụng.

## 1. Khi nào BẮT BUỘC phải xóa trắng Database?

Bạn chỉ nên thực hiện thao tác này ở môi trường **Kiểm thử (Testing/Development)**. Các trường hợp cần thiết bao gồm:
- **Thay đổi cấu trúc Database lớn:** Khi nâng cấp/sửa lỗi các Phase (ví dụ Phase 2, 3) có sự thay đổi về các trường dữ liệu (fields) trong Firestore. Dữ liệu cũ không tương thích có thể gây crash app.
- **Lỗi vòng lặp/trùng lặp dữ liệu không rõ nguyên nhân:** Nếu app liên tục báo lỗi do ID cũ hoặc Account cũ bị kẹt trạng thái (Ví dụ: Trẻ xin thêm giờ nhưng bị kẹt ở trạng thái pending mãi).
- **Test kịch bản E2E (End-to-End) từ đầu:** Khi bạn muốn đóng vai một Phụ huynh mới hoàn toàn: tải app -> đăng ký tài khoản -> liên kết máy con -> thiết lập từ khóa... để xem có lỗi gì không.

## 2. Hướng dẫn chi tiết từng bước

Dữ liệu của KidGuardian nằm ở 2 dịch vụ độc lập của Firebase. Bạn cần xóa ở cả 2 nơi:

### Bước 1: Xóa Người Dùng (Authentication)
Dịch vụ này lưu trữ danh sách Email và Mật khẩu đăng nhập.
1. Truy cập **[Firebase Console](https://console.firebase.google.com/)** và mở dự án **KidGuardian**.
2. Ở thanh menu dọc bên trái, mở rộng mục **Build (Xây dựng)** -> chọn **Authentication (Xác thực)**.
3. Chọn tab **Users (Người dùng)** ở thanh menu ngang phía trên.
4. Bấm vào nút có biểu tượng dấu 3 chấm `⋮` ở góc phải trên cùng của bảng danh sách người dùng -> Chọn **Delete all users (Xóa tất cả người dùng)**. (Hoặc chọn thủ công từng người rồi xóa).

### Bước 2: Xóa Dữ Liệu Ứng Dụng (Firestore Database)
Dịch vụ này lưu thông tin Gia đình, Thiết lập thời gian, Thông báo và Từ khóa cấm.
1. Trở lại thanh menu dọc bên trái, trong phần **Build (Xây dựng)**, chọn **Firestore Database**.
2. Đảm bảo bạn đang ở tab **Data (Dữ liệu)**.
3. Ở cột ngoài cùng bên trái (cột chứa các Root Collections), bạn sẽ thấy các mục như `users`, `families`...
4. Để xóa sạch dữ liệu:
   - Đưa chuột lên dòng `families`, bấm vào biểu tượng dấu 3 chấm `⋮` hiện ra bên phải.
   - Chọn **Delete collection (Xóa bộ sưu tập)**.
   - Một hộp thoại cảnh báo sẽ hiện ra. Firebase yêu cầu bạn gõ lại chính xác tên của collection (hãy gõ chữ `families` vào ô văn bản).
   - Bấm nút **Delete (Xóa)** màu đỏ.
5. Làm tương tự thao tác trên với collection `users` và các bảng khác nếu có.

*(Lưu ý: Khi bạn xóa `families`, tất cả các dữ liệu con bên trong nó như cài đặt giới hạn giờ, danh sách yêu cầu, thông báo, v.v. đều sẽ được Firebase tự động xóa sạch)*.

---
**Kết quả:** Sau khi hoàn tất 2 bước trên, bạn đã có một Backend hoàn toàn sạch. Khi cài bản APK mới nhất lên điện thoại, bạn có thể Đăng ký một tài khoản mới tinh và bắt đầu trải nghiệm ứng dụng như người dùng thật!
