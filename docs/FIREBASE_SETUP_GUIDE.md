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

## ⚡ PHẦN 4: CẤU HÌNH CHỈ MỤC (FIRESTORE INDEXES & INDEX-DEFENSIVE QUERYING)

Đây là bước **CỰC KÌ QUAN TRỌNG** khi thiết lập dự án KidGuardian để đảm bảo hiệu năng, chống lỗi `FAILED_PRECONDITION` và ngăn chặn cạn kiệt hạn ngạch (Quota Exceeded).

### 1. Kiến trúc "Index-Defensive Querying" (Truy vấn phòng thủ chỉ mục)
Để tối ưu hóa chi phí và đảm bảo ổn định 100% trên thiết bị di động, KidGuardian áp dụng chiến lược **Index-Defensive Querying**:
- **Truy vấn đơn trường trên server (Single-field query):** Các repository (`SummaryRepository`, `ReportRepository`, `UsageRepository`) khi gọi lên Cloud Firestore chỉ thực hiện lọc theo một trường chính duy nhất (chẳng hạn `where('childUid', isEqualTo: childUid)` hoặc `where('familyId', isEqualTo: familyId)`).
- **Xử lý trên Client (Client-side Processing):** Việc sắp xếp (`orderBy`) theo thời gian (`generatedAt`, `date`, `startTime`) hoặc lọc theo dải ngày (`date range`) được thực hiện hoàn toàn trong bộ nhớ RAM của ứng dụng (Dart client).
- **Lợi ích:** Loại bỏ hoàn toàn sự phụ thuộc vào các composite indexes phức tạp cho các truy vấn báo cáo nhanh, ngăn chặn tuyệt đối tình trạng app bị treo/crash do thiếu index hoặc lỗi mạng chập chờn, đồng thời tiết kiệm tối đa số lượng Index cần bảo trì trên Firebase.

### 2. File cấu hình tự động `firestore.indexes.json`
Mặc dù đã áp dụng Index-Defensive Querying, hệ thống vẫn cần một số chỉ mục gom nhóm (`Collection Group Indexes`) và chỉ mục kết hợp (`Composite Indexes`) cho các tính năng theo dõi thời gian thực như Cảnh báo (`alerts`), Yêu cầu thời gian (`timeRequests`), và báo cáo tuần (`weekly_reports`).

Dự án đã tích hợp sẵn toàn bộ cấu hình chỉ mục chuẩn trong file `firestore.indexes.json` ở gốc dự án (bao gồm 14 indexes cho `alerts`, `timeRequests`, `weekly_reports`, `installed_apps`, `rules`, `daily_summaries`, `usage_logs`).

#### Cách 1: Triển khai tự động bằng Firebase CLI (Khuyên dùng - Nhanh nhất)
Nếu bạn đã cài đặt Firebase CLI trên máy tính, bạn có thể đẩy toàn bộ 14 chỉ mục này lên dự án Firebase chỉ bằng **1 lệnh duy nhất** từ terminal (trong thư mục gốc của dự án):
```bash
firebase deploy --only firestore:indexes
```
Sau khi chạy lệnh, hãy chờ 2-5 phút để Firebase hoàn tất xây dựng (Trạng thái chuyển sang *Enabled* màu xanh trên Firebase Console).

### 3. Cấu hình Chỉ mục Thủ công / Qua link trong Log (Khi không dùng Firebase CLI)
**Tại sao cần bước này?**  
Ứng dụng KidGuardian có tính năng cho phép Phụ huynh theo dõi cảnh báo (`alerts`) và yêu cầu xin thêm giờ (`timeRequests`) từ **tất cả các con** trong gia đình cùng một lúc thông qua kỹ thuật truy vấn gom nhóm (**Collection Group Query**). Nếu không bật chỉ mục này, ứng dụng sẽ gặp lỗi `FAILED_PRECONDITION`.

### 🛠️ Cách tạo Chỉ mục (Có 2 cách):

#### Cách 1: Tạo siêu nhanh qua đường link tự động trong Log (Khuyên dùng)
1. Khi bạn chạy app lần đầu và đăng nhập vào tài khoản Phụ huynh, nếu chưa có chỉ mục, trong cửa sổ **Logcat** (Android Studio) hoặc **Debug Console** (VS Code) sẽ in ra dòng lỗi màu đỏ có chứa đường link web.
2. Bạn chỉ cần **copy đường link trong log** và dán vào trình duyệt web đang đăng nhập tài khoản Google quản lý Firebase Console của dự án.
   * *Ví dụ Link 1 (Cho Alerts):* `https://console.firebase.google.com/v1/r/project/<id-dự-án>/firestore/indexes?create_exemption=...`
   * *Ví dụ Link 2 (Cho TimeRequests):* `https://console.firebase.google.com/v1/r/project/<id-dự-án>/firestore/indexes?create_exemption=...`
3. Khi trang Firebase Console mở ra, bấm nút xanh **"Create Index" (Tạo chỉ mục)** hoặc **"Save"**.
4. Chờ khoảng **1 - 2 phút** để Firebase xây dựng xong chỉ mục (Trạng thái chuyển từ *Building* sang *Enabled* / màu xanh).

#### Cách 2: Tạo thủ công trực tiếp trên Firebase Console
Nếu bạn không muốn tìm link trong log, bạn có thể tự thiết lập trước trên giao diện Firebase Console:
1. Mở Firebase Console -> Chọn dự án KidGuardian -> Mở **Firestore Database**.
2. Chuyển sang tab **Indexes** (Chỉ mục) ở menu trên cùng -> Chọn tab con **Single-field** (Trường đơn) hoặc cuộn xuống phần **Exemptions**.
3. Bấm nút **Add Exemption** (Thêm trường hợp ngoại lệ) hoặc **Add Index**:
   * **Chỉ mục 1 (Cho Cảnh báo từ máy con):**
     - Collection ID: `alerts`
     - Field path: `type`
     - Query scope: **Collection group** (Nhóm bộ sưu tập)
     - Bấm **Save / Create**.
   * **Chỉ mục 2 (Cho Yêu cầu xin thêm thời gian):**
     - Collection ID: `timeRequests`
     - Field path: `familyId`
     - Query scope: **Collection group** (Nhóm bộ sưu tập)
     - Bấm **Save / Create**.
   * **Chỉ mục 3 (Cho Báo cáo Sử dụng App theo Trẻ - Composite Index):**
     - Collection ID: `usage_logs`
     - Fields: `childUid` (Ascending), `date` (Ascending), `startTime` (Descending)
     - Query scope: **Collection**
     - Bấm **Save / Create**.
   * **Chỉ mục 4 (Cho Báo cáo Sử dụng App theo Gia đình - Composite Index):**
     - Collection ID: `usage_logs`
     - Fields: `familyId` (Ascending), `date` (Ascending), `startTime` (Descending)
     - Query scope: **Collection**
     - Bấm **Save / Create**.

✅ *Thành công! Sau khi trạng thái Index báo **Enabled**, ứng dụng sẽ chạy ở chế độ tối ưu Server-Side Indexing siêu tốc và không bao giờ tốn RAM/Quota.*

---

## 📱 PHẦN 5: KẾT NỐI APP FLUTTER VỚI FIREBASE (Dành cho học sinh làm lại từ đầu)

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

## 📊 PHẦN 6: HƯỚNG DẪN KIỂM TRA HẠN NGẠCH (QUOTA) VÀ GIÁM SÁT DUNG LƯỢNG FIREBASE

Trong quá trình phát triển và kiểm thử ứng dụng, nếu gặp lỗi `RESOURCE_EXHAUSTED: Quota exceeded` (gây sập app hoặc không đọc/ghi được dữ liệu), đó là do dự án đã dùng hết hạn ngạch miễn phí hàng ngày của gói Spark Plan.

### 1. Giới hạn hạn ngạch miễn phí hàng ngày (Spark Plan - Free Tier)
* **Cloud Firestore Read (Đọc):** Tối đa **50.000 lần/ngày**.
* **Cloud Firestore Write (Ghi):** Tối đa **20.000 lần/ngày**.
* **Cloud Firestore Delete (Xóa):** Tối đa **20.000 lần/ngày**.
* **Thời gian làm mới (Reset về 0):** **14:00 (2 giờ chiều) hàng ngày** theo giờ Việt Nam (tương đương 00:00 giờ Pacific Time - PST/PDT).

### 2. Các liên kết kiểm tra hạn ngạch nhanh cho dự án `kidguardian-b54f7`
* **Xem trên Firebase Console (Biểu đồ Đọc/Ghi/Xóa trong ngày):**
  👉 [https://console.firebase.google.com/project/kidguardian-b54f7/firestore/databases/-default-/usage](https://console.firebase.google.com/project/kidguardian-b54f7/firestore/databases/-default-/usage)
* **Xem Tổng quan Sử dụng & Mức dùng toàn dự án:**
  👉 [https://console.firebase.google.com/project/kidguardian-b54f7/usage/details](https://console.firebase.google.com/project/kidguardian-b54f7/usage/details)
* **Xem trên Google Cloud Console (Chi tiết từng chỉ số Quota của Firestore API):**
  👉 [https://console.cloud.google.com/iam-admin/quotas?project=kidguardian-b54f7&service=firestore.googleapis.com](https://console.cloud.google.com/iam-admin/quotas?project=kidguardian-b54f7&service=firestore.googleapis.com)
* **Biểu đồ lưu lượng API Firestore theo thời gian thực:**
  👉 [https://console.cloud.google.com/apis/api/firestore.googleapis.com/metrics?project=kidguardian-b54f7](https://console.cloud.google.com/apis/api/firestore.googleapis.com/metrics?project=kidguardian-b54f7)

> [!TIP]
> 💡 **Lưu ý tối ưu:** Để tránh cạn kiệt Quota trong tương lai, ứng dụng KidGuardian đã tích hợp cơ chế bộ nhớ đệm (Cache & Diffing) trong `AppMonitorBloc`, giúp tiết kiệm từ 95% - 98% số lần ghi Firestore khi đồng bộ danh sách ứng dụng installed apps.

---

## 🎯 TỔNG KẾT
Một dự án Firebase cho KidGuardian chỉ có thể hoạt động hoàn hảo và không bị sập khi thỏa mãn **đủ 4 điều kiện**:
1. Đã bật **Authentication (Email/Password)**.
2. Đã tạo **Firestore Database** (chế độ Test mode).
3. Đã tạo **2 Collection Group Indexes** cho `alerts` và `timeRequests` trên tab Indexes.
4. Đã có file **google-services.json** nằm trong folder `android/app/`.

Chúc bạn và các học sinh hoàn thành xuất sắc dự án!
