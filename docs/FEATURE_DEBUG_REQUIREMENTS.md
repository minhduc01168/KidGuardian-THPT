# Yêu Cầu Chi Tiết Để Debug Tính Năng - KidGuardian

Tài liệu này tổng hợp các yêu cầu cốt lõi (Jobs-to-be-Done), các kịch bản ngoại lệ (Edge Cases) và tiêu chí nghiệm thu kỹ thuật (Acceptance Criteria) cho 4 tính năng chính của hệ thống KidGuardian. Tài liệu này được sử dụng làm cơ sở để rà soát code và debug hệ thống.

> **QUY TẮC CỐ ĐỊNH ỨNG DỤNG GIÁM SÁT (FIXED MONITORED APPS)**
> Để giảm độ phức tạp và dễ dàng kiểm thử, toàn bộ hệ thống (từ tính năng khóa, xin giờ, đến báo cáo thống kê) **chỉ giám sát và áp dụng quy tắc lên một danh sách cố định gồm 8 ứng dụng Mạng Xã Hội / Giải Trí:** 
> **1. Facebook**
> **2. TikTok**
> **3. Instagram**
> **4. Zalo**
> **5. YouTube**
> **6. Threads**
> **7. Locket**
> **8. Discord**
> 
> Các ứng dụng hệ thống và các ứng dụng nằm ngoài danh sách 8 app này sẽ hoàn toàn bị bỏ qua.

---

## 1. Tính năng Native Blocking (Khóa ứng dụng mức hệ thống)

### 📋 Yêu cầu chức năng cốt lõi (PM - John)
* **Mục tiêu:** Kiểm soát tức thời. Khi một ứng dụng (thuộc danh sách 8 app trên) nằm trong danh sách cấm hoặc vào khung giờ cấm, trẻ mở ứng dụng đó lên phải bị văng ra màn hình chính ngay lập tức.
* **Thời gian phản hồi:** Dưới 0.5 giây.
* **Quyền truy cập khẩn cấp:** Nếu trẻ xin truy cập khẩn cấp, hệ thống mở đúng 5 phút. Hết 5 phút tự động khóa lại. Cần có cơ chế cooldown để trẻ không thể xin khẩn cấp liên tục (chống spam).

### 📊 Kịch bản ngoại lệ / Edge Cases (BA - Mary)
* **Mất mạng (Offline):** Khi máy trẻ mất kết nối Internet, `Accessibility Service` phải tự động lấy quy tắc chặn từ bộ nhớ đệm nội bộ (SharedPreferences/Local DB) và vẫn hoạt động bình thường.
* **Xung đột trạng thái:** Trẻ đang trong 5 phút "truy cập khẩn cấp", nhưng phụ huynh đổi luật khóa app. Luật mới (khóa) cần được ưu tiên hay phải đợi hết 5 phút? (Đề xuất: Chờ hết 5 phút hoặc tự động override tùy logic, cần check code).
* **Qua ngày mới (Midnight Rollover):** Đang sử dụng ứng dụng vào cuối ngày (23:59), khi chuyển sang 00:00 (bắt đầu khung giờ cấm), ứng dụng phải tự động bị văng ra màn hình Home.

### 💻 Tiêu chí nghiệm thu kỹ thuật (Dev - Amelia)
* Phải có cờ `START_STICKY` đối với Foreground Service trên Android 14+ để ngăn hệ điều hành tự động kill Service.
* Lệnh `GLOBAL_ACTION_HOME` phải được trigger thành công trong AccessibilityService.
* Trong quá trình chặn liên tục, LogCat không được xuất hiện lỗi `ANR` (Application Not Responding) hoặc Memory Leak.
* **Unit Tests:** `SmartLockBloc` và `SmartLockRepository` phải pass 100% test case, đặc biệt là mock cho trường hợp mất mạng.

---

## 2. Tính năng Time Requests (Xin thêm giờ)

### 📋 Yêu cầu chức năng cốt lõi (PM - John)
* **Mục tiêu:** Khi trẻ hết giờ, có thể xin thêm thời gian (15, 30, 60 phút) kèm lý do. Phụ huynh nhận thông báo và duyệt ngay lập tức, sau đó ứng dụng trên máy trẻ tự động mở khóa.
* **Trải nghiệm:** Dropdown (App Selector) khi xin giờ chỉ được hiển thị các ứng dụng *thực sự đang bị khóa/giám sát* (thuộc danh sách 8 app cố định), tuyệt đối không hiện danh sách rác.

### 📊 Kịch bản ngoại lệ / Edge Cases (BA - Mary)
* **Spam Request:** Trẻ bấm liên tục nút "Xin thêm giờ". **Quy tắc:** Mỗi ứng dụng chỉ được xin thêm giờ tối đa 3 lần/giờ. Hệ thống không được tạo ra số lượng request vượt quá quy định lên Firestore.
* **Duyệt trễ (Timeout) & Reset ngày:** Khi qua ngày mới (hết ngày) mà phụ huynh chưa duyệt request, hệ thống sẽ tự động reset và xóa bỏ các yêu cầu cũ không hợp lệ này.

### 💻 Tiêu chí nghiệm thu kỹ thuật (Dev - Amelia)
* **Firestore Quota Protection:** Các truy vấn (Query) trên `TimeRequestRepository` phải là *Single-Field Query* (vd: chỉ lọc theo `childUid`). Toàn bộ việc sắp xếp thời gian (`orderBy`) hoặc lọc (`where`) phức tạp phải xử lý tại Client-side (RAM) để tránh lỗi `FAILED_PRECONDITION` (Index).
* Giao diện tạo dropdown phải lấy danh sách ứng dụng đã qua bộ lọc của `RulesRepository` trước khi hiển thị.
* Implement cơ chế block logic phía client: đếm số lần xin thêm giờ theo ID ứng dụng (<= 3 lần trong vòng 1 giờ).

---

## 3. Tính năng Keyword Monitor (Giám sát từ khóa nhạy cảm)

### 📋 Yêu cầu chức năng cốt lõi (PM - John)
* **Mục tiêu:** Tự động giám sát text gõ trên màn hình và cảnh báo nếu phát hiện 21 từ khóa mặc định thuộc 5 nhóm rủi ro cao. 
* **Phạm vi theo dõi giới hạn:** **CHỈ** theo dõi việc gõ text trên 2 ứng dụng: **Google Search** và **Google Chrome**. Không giám sát bừa bãi ở các app khác.
* **Trải nghiệm:** Phụ huynh có thể thêm, xóa từ khóa, hoặc khôi phục về danh sách 21 từ mặc định dễ dàng.

### 📊 Kịch bản ngoại lệ / Edge Cases (BA - Mary)
* **Đồng bộ Offline/Online:** Nếu phụ huynh thêm/xóa từ khóa khi máy trẻ không có mạng, máy trẻ **phải tự động cập nhật danh sách mới nhất ngay khi có mạng trở lại**.
* **Case-insensitive & Dấu câu:** Nếu chặn từ "Súng", các chữ như "súng", "SÚNG" phải bị nhận diện. Cần test kỹ với tiếng Việt có dấu.

### 💻 Tiêu chí nghiệm thu kỹ thuật (Dev - Amelia)
* Thuật toán tìm kiếm chuỗi (String matching) phải bỏ qua viết hoa/viết thường và có thể xử lý dấu tiếng Việt.
* Chỉ trigger logic dò từ khóa khi `packageName` hiện tại thuộc về `com.google.android.googlequicksearchbox` hoặc `com.android.chrome`.
* **Cơ chế Cooldown 5 phút:** Lưu cache cục bộ (`_lastAlertSentMap`) các từ khóa đã cảnh báo để tránh cạn kiệt Writes Quota.
* **Giới hạn số lượng truy vấn:** Stream nghe cảnh báo trên máy phụ huynh phải có `.limit(50)` để tiết kiệm Reads Quota.

---

## 4. Tính năng Báo Cáo & Thống Kê (Analytics & Summaries)

### 📋 Yêu cầu chức năng cốt lõi (PM - John)
* **Mục tiêu:** Giúp phụ huynh nắm bắt trực quan thói quen sử dụng điện thoại của trẻ. 
* **Theo dõi hai chiều (Two-way tracking):** Tính năng Báo cáo & Thống kê **PHẢI có mặt ở cả màn hình Phụ huynh (Parent) VÀ màn hình của Trẻ (Child)**. Trẻ em có thể tự xem biểu đồ thống kê để tự theo dõi, rèn luyện tính kỷ luật cá nhân.
* **Biểu đồ thời gian:** Thống kê chi tiết thời gian sử dụng (của 8 app mạng xã hội cố định) theo ngày, tuần, tháng và được phân loại theo khung giờ (groupByHour).
* **Báo cáo tuần:** Tự động tổng hợp dữ liệu để phát hành báo cáo sử dụng thiết bị hằng tuần cho phụ huynh và trẻ em.

### 📊 Kịch bản ngoại lệ / Edge Cases (BA - Mary)
* **Lọc ứng dụng được giám sát:** Chỉ thống kê và báo cáo danh sách 8 ứng dụng đã chỉ định. Bỏ qua hoàn toàn thời gian sử dụng các app khác.
* **Đồng bộ dữ liệu Offline:** Nếu trẻ dùng điện thoại khi không có kết nối internet, thời gian sử dụng mạng xã hội phải được cộng dồn nội bộ và đẩy bù (sync) lên Firestore qua Batch Write khi mạng được khôi phục.

### 💻 Tiêu chí nghiệm thu kỹ thuật (Dev - Amelia)
* **Client-side Filtering & Sorting:** Toàn bộ việc filter thời gian (date range) để vẽ biểu đồ phải được xử lý tại bộ nhớ RAM (Dart layer) thay vì dựa vào Index phức tạp trên Firestore.
* **Đồng bộ luồng UI:** Do giao diện thống kê áp dụng cho cả Parent và Child, cần thiết kế Widget dùng chung (Reusable Widget) nhận vào `uid` của trẻ làm tham số để đảm bảo tính nhất quán trên UI.
