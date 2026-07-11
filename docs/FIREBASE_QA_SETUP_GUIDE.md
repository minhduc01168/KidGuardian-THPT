# HƯỚNG DẪN TẠO VÀ CHUYỂN ĐỔI DỰ ÁN FIREBASE DỰ PHÒNG (QA/TESTING) & TỐI ƯU HẠN NGẠCH

> **Mục đích:** Khi dự án Firebase chính (`KidGuardian-Production`) tạm thời hết hạn ngạch miễn phí 50.000 Reads/ngày trong quá trình chạy test tự động hoặc kiểm thử stress, bạn có thể tạo một dự án Firebase phụ (`KidGuardian-QA`) để tiếp tục kiểm thử thủ công (Manual Test) ngay lập tức mà không cần phải chờ đến 14:00 chiều để reset hạn ngạch.
> 
> **Đặc biệt:** Tài liệu này bao gồm hướng dẫn **Tích hợp & Cấu hình Collection, Composite Indexes và chính sách TTL** để tối ưu hóa triệt để lượt gửi/đọc dữ liệu, giúp gói Free Spark Plan chạy mượt mà không bao giờ bị thâm hụt.

---

## 📋 MỤC LỤC
1. [Bước 1: Tạo dự án mới trên Firebase Console](#bước-1-tạo-dự-án-mới-trên-firebase-console)
2. [Bước 2: Kích hoạt Authentication (Email/Password)](#bước-2-kích-hoạt-authentication-emailpassword)
3. [Bước 3: Kích hoạt Cloud Firestore & Cấu hình Luật (Security Rules)](#bước-3-kích-hoạt-cloud-firestore--cấu-hình-luật-security-rules)
4. [Bước 4: Cấu hình Composite Indexes & Tích hợp Collection tối ưu lượt gửi](#bước-4-cấu-hình-composite-indexes--tích-hợp-collection-tối-ưu-lượt-gửi)
5. [Bước 5: Đăng ký ứng dụng Android & Tải `google-services.json`](#bước-5-đăng-ký-ứng-dụng-android--tải-google-servicesjson)
6. [Bước 6: Thay thế cấu hình trong dự án Flutter & Khởi chạy](#bước-6-thay-thế-cấu-hình-trong-dự-án-flutter--khởi-chạy)
7. [Bước 7: Cách chuyển lại về dự án chính (Production) khi cần](#bước-7-cách-chuyển-lại-về-dự-án-chính-production-khi-cần)

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

## BƯỚC 4: CẤU HÌNH COMPOSITE INDEXES & TÍCH HỢP COLLECTION TỐI ƯU LƯỢT GỬI

Để ứng dụng KidGuardian tận dụng được các câu truy vấn **giới hạn số lượng `.limit(50)`** (`FIX C5`) và ngăn chặn việc quét thừa toàn bộ bảng (gây lãng phí hàng nghìn lượt Reads), bạn **bắt buộc phải cấu hình Composite Indexes (Chỉ mục kép)** cho các Collection chính ngay sau khi tạo Firestore:

### 1. Tạo Composite Index cho `alerts` (Cảnh báo & Khóa ứng dụng)
Khi phụ huynh xem Lịch sử Cảnh báo, app thực hiện truy vấn `collectionGroup('alerts').where('familyId', ...).orderBy('timestamp', descending: true).limit(50)`. Để tối ưu lượt đọc:
1. Trong Firestore Database, chuyển sang tab **Indexes** (Chỉ mục).
2. Tại mục **Composite (Chỉ mục kép)**, bấm nút **Add Index** (Thêm chỉ mục).
3. Điền thông tin chính xác:
   - **Collection ID:** `alerts`
   - **Query scope:** Chọn **Collection group**
   - **Fields indexed (Các trường được lập chỉ mục):**
     - Trường 1: Nhập `familyId` $\rightarrow$ Chọn **Ascending (Tăng dần)**
     - Trường 2: Nhập `timestamp` $\rightarrow$ Chọn **Descending (Giảm dần)**
4. Bấm **Create** (Tạo). *(Chờ 1-2 phút để trạng thái chuyển từ Building sang Enabled)*.

### 2. Tạo Composite Index cho `timeRequests` (Yêu cầu xin thêm giờ)
Để phụ huynh nhận danh sách xin giờ mới nhất mà không phải load toàn bộ lịch sử:
1. Bấm tiếp **Add Index**.
2. Điền thông tin:
   - **Collection ID:** `timeRequests`
   - **Query scope:** Chọn **Collection group**
   - **Fields indexed:**
     - Trường 1: `familyId` $\rightarrow$ **Ascending**
     - Trường 2: `timestamp` $\rightarrow$ **Descending**
3. Bấm **Create**.

### 3. Tạo Composite Index cho `notifications` (Trung tâm thông báo)
1. Bấm tiếp **Add Index**.
2. Điền thông tin:
   - **Collection ID:** `notifications`
   - **Query scope:** Chọn **Collection group**
   - **Fields indexed:**
     - Trường 1: `familyId` $\rightarrow$ **Ascending**
     - Trường 2: `timestamp` $\rightarrow$ **Descending**
3. Bấm **Create**.

### 4. Tích hợp Chính sách tự động xóa (TTL - Time-To-Live Policy) tiết kiệm Quota
Để ngăn các Collection `alerts` và `notifications` phình to lên hàng ngàn tài liệu sau nhiều ngày test (khiến mỗi lần query/sort tốn thêm tài nguyên), hãy thiết lập chính sách tự động xóa ngầm:
1. Tại tab **Indexes**, cuộn xuống hoặc chuyển sang phần **TTL Policies**.
2. Bấm **Create Policy**:
   - **Collection group:** Nhập `alerts`
   - **Timestamp field:** Nhập `timestamp`
3. Bấm **Create Policy** tiếp cho `notifications` với trường `timestamp`.
*(Firebase sẽ tự động dọn dẹp các tài liệu cũ sau thời hạn mà hoàn toàn miễn phí, không tính vào lượt Deletes/Reads hàng ngày của gói Spark Plan).*

### 5. Cấu trúc phân tầng Collection chuẩn của KidGuardian
Khi bạn chạy app lần đầu với tài khoản mới, hệ thống tự động sinh ra cấu trúc cây Collection tối ưu hóa lượt gửi như sau:
```text
databases/
 └── (default)/documents/
      ├── users/{uid}                     (Lưu role, profile của Parent/Child)
      ├── linkCodes/{code}                (Mã 6 số liên kết gia đình, có hạn sử dụng)
      └── families/{familyId}/
           ├── children/{childUid}/
           │    ├── monitoredApps/{appId} (Danh sách app + trạng thái chặn)
           │    ├── timeRequests/{reqId}  (Yêu cầu xin giờ của trẻ)
           │    ├── dailyUsage/{date}     (Log sử dụng app gom nhóm giờ - tối ưu 1 write/giờ)
           │    └── notifications/{id}    (Thông báo đẩy cho từng thiết bị)
           ├── alerts/{alertId}           (Cảnh báo vi phạm khóa app - được bảo vệ bởi Cooldown 5 phút)
           └── settings/autoApprovalRules (Quy tắc tự động duyệt thời gian)
```

---

## BƯỚC 5: ĐĂNG KÝ ỨNG DỤNG ANDROID & TẢI `google-services.json`

Để app Flutter KidGuardian kết nối được với dự án `KidGuardian-QA` vừa tạo và nhận cấu hình Index/Collection trên:

1. Tại trang chủ dự án (`Project Overview`), bấm vào **biểu tượng hình con robot Android** để thêm ứng dụng Android.
2. Tại ô **Android package name (Tên gói Android)**:  
   ⚠️ **BẮT BUỘC ĐIỀN CHÍNH XÁC:** `com.kidguardian.kidguardian`  
   *(Nếu điền sai chữ nào, ứng dụng sẽ báo lỗi Crash/MissingPlugin).*
3. Ô *App nickname* có thể điền: `KidGuardian QA App`.
4. Bấm nút **Register app** (Đăng ký ứng dụng).
5. Bấm nút xanh **Download google-services.json** để tải file cấu hình về máy tính.
6. Bấm **Next** liên tục và bấm **Continue to console** để hoàn tất.

---

## BƯỚC 6: THAY THẾ CẤU HÌNH TRONG DỰ ÁN FLUTTER & KHỞI CHẠY

Bây giờ chúng ta sẽ dán file `google-services.json` của dự án QA vào code:

### 1. Lưu lại file cũ (Dự phòng cho Production)
Trước khi thay thế, hãy đổi tên file `google-services.json` hiện tại trong thư mục `android/app/` thành `google-services.production.json` để giữ lại:
- Đường dẫn file gốc: `android/app/google-services.json`
- Đổi tên thành: `android/app/google-services.production.json`

### 2. Dán file cấu hình QA mới vào
- Copy file `google-services.json` mà bạn vừa tải về ở Bước 5.
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

🎉 **Xong!** Lúc này ứng dụng KidGuardian đã kết nối vào database `KidGuardian-QA` mới tinh với **50.000 Reads & 20.000 Writes hoàn toàn trống**, đồng thời được bảo vệ bởi hệ thống **Composite Indexes và TTL** giúp tốc độ đọc cực nhanh và không hao tốn Quota!

---

## BƯỚC 7: CÁCH CHUYỂN LẠI VỀ DỰ ÁN CHÍNH (PRODUCTION) KHI CẦN

Khi hạn ngạch của dự án chính đã được reset (sau 14:00 chiều) và bạn muốn chuyển app trở về kết nối với dự án chính (`KidGuardian-Production`):

1. Xóa file `android/app/google-services.json` hiện tại (file của QA).
2. Đổi tên file `android/app/google-services.production.json` trở lại thành `android/app/google-services.json`.
3. Chạy lại lệnh:
   ```bash
   flutter clean && flutter pub get && flutter run
   ```
   Ứng dụng sẽ lập tức kết nối trở lại với cơ sở dữ liệu chính thức!

---
*Tài liệu được chuẩn hóa bao gồm đầy đủ kiến trúc tối ưu hóa Collection và Quota Firebase cho KidGuardian.*
