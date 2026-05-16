# KidGuardian

## PHẦN 1: MÔ TẢ DỰ ÁN

### Tên dự án
**KidGuardian - Đồng Hành Số**

### Mục tiêu
Tạo ra một ứng dụng duy nhất trên điện thoại giúp phụ huynh và trẻ em cùng quản lý thói quen sử dụng mạng xã hội thông qua sự thỏa thuận và giám sát minh bạch.

---

## Cấu trúc 1-App

### Phụ huynh
- Đăng nhập để quản lý, đặt giới hạn và nhận thông báo.

### Trẻ em
- Đăng nhập để theo dõi thời gian sử dụng và gửi yêu cầu **"xin thêm giờ"**.

---

## Công nghệ

| Thành phần | Công nghệ |
|---|---|
| Framework | Flutter (Phát triển 1 lần, chạy cả Android/iOS) |
| Backend & Cloud | Firebase (Free Tier) – Quản lý người dùng, đồng bộ dữ liệu real-time và gửi thông báo đẩy |
| Logic AI | Sử dụng thư viện lọc từ khóa nhạy cảm có sẵn (Regex hoặc local library), không tốn phí API |

---

## Tính năng cốt lõi (MVP)

### Dashboard
- Biểu đồ thời gian thực các app mạng xã hội (TikTok, Facebook...).

### Khóa giờ (Smart Lock)
- Tự động hiện màn hình chặn khi hết hạn mức thời gian đã đặt.

### Cảnh báo an toàn
- Thông báo cho phụ huynh khi trẻ truy cập từ khóa tiêu cực.

### Tương tác hai chiều
- Trẻ xin thêm giờ trực tiếp trên app.
- Phụ huynh duyệt/từ chối ngay lập tức.

---

# PHẦN 2: ĐẦU RA DỰ ÁN (OUTPUTS)

## Phần mềm
- 01 tệp cài đặt (APK) tích hợp cả hai giao diện (Cha mẹ/Con).
- Mã nguồn hoàn thiện trên GitHub kèm tài liệu hướng dẫn (`README`).

## Hệ thống
- Một Project Firebase hoạt động ổn định.
- Lưu trữ cấu hình và lịch sử sử dụng của người dùng.

## Tài liệu báo cáo
- Báo cáo khoảng 20 trang gồm:
  - Phân tích thực trạng
  - Sơ đồ luồng dữ liệu (Data Flow)
  - Báo cáo kết quả thử nghiệm thực tế

## Thiết kế (UI/UX)
- Link Figma mô tả quy trình chuyển đổi giữa hai quyền người dùng.
- Bộ nhận diện thương hiệu:
  - Logo
  - Color Palette

---

# MÔ TẢ HÌNH ẢNH TRỰC QUAN

## Hình 1 - Bảng điều khiển (Parent Home)
Hiển thị:
- Tổng thời gian con sử dụng
- Các nút thiết lập giới hạn nhanh

---

## Hình 2 - Màn hình giới hạn (Child Lock)
Màn hình hiện lên khi:
- Con dùng quá giờ

Tính năng:
- Có nút **"Xin thêm 15 phút"** để thương lượng với bố mẹ

---

## Hình 3 - Trung tâm phê duyệt (Interaction)
Phụ huynh:
- Nhận thông báo đẩy
- Có thể bấm **"Đồng ý"** cho con dùng tiếp ngay trên điện thoại của mình.