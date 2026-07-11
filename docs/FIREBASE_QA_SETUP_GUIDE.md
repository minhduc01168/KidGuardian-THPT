# HƯỚNG DẪN TẠO VÀ CHUYỂN ĐỔI DỰ ÁN FIREBASE DỰ PHÒNG (QA/TESTING)

> **Mục đích:** Khi dự án Firebase chính (`KidGuardian-Production`) tạm thời hết hạn ngạch miễn phí 50.000 Reads/ngày trong quá trình chạy test tự động hoặc kiểm thử stress, bạn có thể tạo một dự án Firebase phụ (`KidGuardian-QA`) để tiếp tục kiểm thử thủ công (Manual Test) ngay lập tức mà không cần phải chờ đến 14:00 chiều để reset hạn ngạch.

---

## 📋 MỤC LỤC
1. [Bước 1: Tạo dự án mới trên Firebase Console](#bước-1-tạo-dự-án-mới-trên-firebase-console)
2. [Bước 2: Kích hoạt Authentication (Email/Password)](#bước-2-kích-hoạt-authentication-emailpassword)
3. [Bước 3: Kích hoạt Cloud Firestore & Cấu hình Luật (Security Rules)](#bước-3-kích-hoạt-cloud-firestore--cấu-hình-luật-security-rules)
4. [Bước 4: Đăng ký ứng dụng Android & Tải `google-services.json`](#bước-4-đăng-ký-ứng-dụng-android--tải-google-servicesjson)
5. [Bước 5: Thay thế cấu hình trong dự án Flutter & Khởi chạy](#bước-5-thay-thế-cấu-hình-trong-dự-án-flutter--khởi-chạy)
6. [Bước 6: Cách chuyển lại về dự án chính (Production) khi cần](#bước-6-cách-chuyển-lại-về-dự-án-chính-production-khi-cần)

---

## BƯỚC 1: TẠO DỰ ÁN MỚI TRÊN FIREBASE CONSOLE

1. Truy cập vào [Firebase Console](https://console.firebase.google.com/) và đăng nhập tài khoản Google của bạn.
2. Tại giao diện chính, bấm vào nút **Add project** (Thêm dự án).
3. Nhập tên dự án dự phòng, ví dụ: `KidGuardian-QA` hoặc `KidGuardian-Test`.
4. Bấm **Continue** (Tiếp tục).
5. Khi hệ thống hỏi về **Google Analytics**, gạt công tắc tắt đi (Disable Google Analytics for this project) để tạo cho nhanh $\rightarrow$ Bấm **Create project** (Tạo dự án).
6. Chờ khoảng 10-15 giây khi màn hình hiển thị *"Your new project is ready"* $\rightarrow$ Bấm **Continue** để vào trang quản trị của dự án mới.

---

## BƯỚC 2: KÍCH HOẠT AUTHENTICATION (EMAIL/PASSWORD)

Ứng dụng KidGuardian cần dịch vụ Authentication để đăng ký và đăng nhập tài khoản Phụ huynh/Con.

1. Tại cột menu dọc bên trái, mở mục **Build** (Xây dựng) $\rightarrow$ Chọn **Authentication**.
2. Bấm nút **Get started** (Bắt đầu).
3. Hệ thống chuyển sang tab **Sign-in method** (Phương thức đăng nhập) $\rightarrow$ Trong danh sách *Native providers*, bấm chọn **Email/Password**.
4. Gạt công tắc đầu tiên (**Enable**) sang màu xanh $\rightarrow$ Bấm **Save** (Lưu). *(Lưu ý: Không cần bật ô "Email link")*.

---

## BƯỚC 3: KÍCH HOẠT CLOUD FIRESTORE & CẤU HÌNH LUẬT (SECURITY RULES)

1. Ở menu dọc bên trái, trong phần **Build**, chọn **Firestore Database**.
2. Bấm nút **Create database** (Tạo cơ sở dữ liệu).
3. Tại bước chọn phiên bản (*Database edition*): Chọn **Standard edition** (miễn phí) $\rightarrow$ Bấm **Next**.
4. Tại bước chọn vị trí máy chủ (*Cloud Firestore location*): Chọn **`nam5 (us-central)`** hoặc **`asia-southeast1 (Singapore)`** $\rightarrow$ Bấm **Next**.
5. Tại bước chọn chế độ (*Security rules*): Chọn **Start in test mode** (Bắt đầu ở chế độ thử nghiệm) $\rightarrow$ Bấm **Create** (Tạo).
6. **Cập nhật Security Rules chuẩn cho KidGuardian:**
   - Sau khi tạo xong, bạn chuyển sang tab **Rules** (Quy tắc) bên trên bảng dữ liệu Firestore.
   - Xóa hết đoạn code cũ và dán toàn bộ đoạn quy tắc chuẩn dưới đây vào:
   ```js
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         // Cho phép mọi tài khoản đã đăng nhập (hoặc đang test) được đọc/ghi
         allow read, write: if request.auth != null || true;
       }
     }
   }
   ```
   - Bấm nút **Publish** (Xuất bản) màu xanh ở góc trên.

---

## BƯỚC 4: ĐĂNG KÝ ỨNG DỤNG ANDROID & TẢI `google-services.json`

Để app Flutter KidGuardian kết nối được với dự án `KidGuardian-QA` vừa tạo:

1. Tại trang chủ dự án (`Project Overview`), bấm vào **biểu tượng hình con robot Android** để thêm ứng dụng Android.
2. Tại ô **Android package name (Tên gói Android)**:  
   ⚠️ **BẮT BUỘC ĐIỀN CHÍNH XÁC:** `com.kidguardian.kidguardian`  
   *(Nếu điền sai chữ nào, ứng dụng sẽ báo lỗi Crash/MissingPlugin).*
3. Ô *App nickname* có thể điền: `KidGuardian QA App`.
4. Bấm nút **Register app** (Đăng ký ứng dụng).
5. Bấm nút xanh **Download google-services.json** để tải file cấu hình về máy tính.
6. Bấm **Next** liên tục và bấm **Continue to console** để hoàn tất.

---

## BƯỚC 5: THAY THẾ CẤU HÌNH TRONG DỰ ÁN FLUTTER & KHỞI CHẠY

Bây giờ chúng ta sẽ dán file `google-services.json` của dự án QA vào code:

### 1. Lưu lại file cũ (Dự phòng cho Production)
Trước khi thay thế, hãy đổi tên file `google-services.json` hiện tại trong thư mục `android/app/` thành `google-services.production.json` để giữ lại:
- Đường dẫn file gốc: `android/app/google-services.json`
- Đổi tên thành: `android/app/google-services.production.json`

### 2. Dán file cấu hình QA mới vào
- Copy file `google-services.json` mà bạn vừa tải về ở Bước 4.
- Dán vào đúng thư mục: `android/app/google-services.json`.

### 3. Xóa bộ nhớ đệm và build lại app (Clean Build)
Mở Terminal trong thư mục dự án KidGuardian và chạy lần lượt 3 lệnh sau để ứng dụng nhận kết nối mới:

```bash
# 1. Xóa bộ nhớ đệm cũ của Flutter
flutter clean

# 2. Tải lại các thư viện
flutter pub get

# 3. Chạy ứng dụng trên máy ảo/máy thật (hoặc bấm nút Run trên Android Studio/VS Code)
flutter run
```

🎉 **Xong!** Lúc này ứng dụng KidGuardian trên máy ảo/thiết bị của bạn đã được kết nối với dự án `KidGuardian-QA` mới tinh với hạn ngạch **50.000 Reads & 20.000 Writes hoàn toàn trống**. Bạn có thể đăng ký tài khoản mới và kiểm thử thủ công thoải mái!

---

## BƯỚC 6: CÁCH CHUYỂN LẠI VỀ DỰ ÁN CHÍNH (PRODUCTION) KHI CẦN

Khi hạn ngạch của dự án chính đã được reset (sau 14:00 chiều) và bạn muốn chuyển app trở về kết nối với dự án chính (`KidGuardian-Production`):

1. Xóa file `android/app/google-services.json` hiện tại (file của QA).
2. Đổi tên file `android/app/google-services.production.json` trở lại thành `android/app/google-services.json`.
3. Chạy lại lệnh:
   ```bash
   flutter clean && flutter pub get && flutter run
   ```
   Ứng dụng sẽ lập tức kết nối trở lại với cơ sở dữ liệu chính thức!

---
*Tài liệu được thiết kế tối ưu giúp chuyển đổi môi trường kiểm thử linh hoạt, đảm bảo không bao giờ bị gián đoạn tiến độ nghiệm thu dự án.*
