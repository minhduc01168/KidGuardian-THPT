# BUỔI 1: Khởi Động Dự Án & Thiết Kế UI/UX

**Thời gian:** 2 tiết (90 phút)  
**Mục tiêu:** Hiểu dự án, vẽ User Flow, thiết kế giao diện trên Figma

---

## PHẦN 1: LÝ THUYẾT (30 phút)

### 1.1 Dự Án KidGuardian Là Gì?

**Vấn đề:**
- Nhiều bạn trẻ dành quá nhiều thời gian cho mạng xã hội
- Phụ huynh muốn giám sát nhưng không muốn quá khắt khe
- Cần một giải pháp "cùng nhau quản lý" thay vì "cấm đoán"

**Giải pháp - KidGuardian:**
- Ứng dụng giúp phụ huynh và con **cùng thỏa thuận** giới hạn sử dụng
- Con có thể **xin thêm giờ** khi cần
- Phụ huynh **giám sát minh bạch**, không bí mật

### 1.2 Ai Sử Dụng Ứng Dụng?

| Người Dùng | Vai Trò | Cần Gì? |
|------------|---------|---------|
| **Phụ huynh** | Quản lý, giám sát | Dashboard, Đặt giới hạn, Phê duyệt yêu cầu |
| **Con (11-18 tuổi)** | Sử dụng, xin phép | Xem thời gian, Gửi yêu cầu, Xem quy tắc |

### 1.3 User Flow Là Gì?

**User Flow** (Luồng người dùng) là chuỗi các bước mà người dùng thực hiện để hoàn thành một mục tiêu.

**Ví dụ - Flow đăng nhập của Phụ huynh:**
```
Mở App → Nhập Email → Nhập Password → Nhấn Đăng nhập → Vào Dashboard
```

### 1.4 Vẽ User Flow Cho KidGuardian

**Flow Phụ huynh:**
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Mở App     │────▶│  Đăng nhập  │────▶│  Dashboard  │
└─────────────┘     └─────────────┘     └─────────────┘
                                               │
                                               ▼
                    ┌─────────────┐     ┌─────────────┐
                    │  Phê duyệt  │◀────│ Đặt giới hạn│
                    │   yêu cầu   │     └─────────────┘
                    └─────────────┘
```

**Flow Con:**
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Mở App     │────▶│  Đăng nhập  │────▶│  Trang chủ  │
└─────────────┘     └─────────────┘     └─────────────┘
                                               │
                           ┌───────────────────┼───────────────────┐
                           ▼                   ▼                   ▼
                    ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
                    │ Xem thời    │     │  Xin thêm   │     │  Màn hình   │
                    │ gian còn lại│     │   giờ       │     │   khóa      │
                    └─────────────┘     └─────────────┘     └─────────────┘
```

---

## PHẦN 2: THỰC HÀNH (60 phút)

### 2.1 Giới Thiệu Figma

**Figma là gì?**
- Công cụ thiết kế giao diện miễn phí
- Sử dụng trực tiếp trên trình duyệt
- Dễ chia sẻ và cộng tác

**Truy cập:** https://www.figma.com

### 2.2 Bài Tập: Thiết Kế 3 Màn Hình Chính

**Yêu cầu:** Vẽ High-fidelity (có màu sắc, font chữ, hình ảnh) cho 3 màn hình:

#### Màn hình 1: Dashboard (Phụ huynh)

**Thành phần cần có:**
- [ ] Header: Tên app, avatar phụ huynh
- [ ] Tổng thời gian con sử dụng hôm nay
- [ ] Biểu đồ tròn (Pie Chart) - tỷ lệ sử dụng theo app
- [ ] Danh sách app (TikTok, Facebook, YouTube...) với thời gian
- [ ] Nút "Đặt giới hạn"
- [ ] Bottom navigation

**Gợi ý thiết kế:**
```
┌─────────────────────────────────────┐
│ KidGuardian              [Avatar]   │
├─────────────────────────────────────┤
│                                     │
│   Thời gian sử dụng hôm nay        │
│        2h 30p / 3h                  │
│      [============----] 83%         │
│                                     │
├─────────────────────────────────────┤
│   [Pie Chart]     TikTok: 1h 20p   │
│                   Facebook: 45p     │
│                   YouTube: 25p      │
├─────────────────────────────────────┤
│                                     │
│   [Đặt giới hạn]  [Xem chi tiết]   │
│                                     │
├─────────────────────────────────────┤
│  [Home]  [Alerts]  [Requests] [Me]  │
└─────────────────────────────────────┘
```

#### Màn hình 2: Màn hình khóa (Child Lock Screen)

**Thành phần cần có:**
- [ ] Icon khóa lớn
- [ ] Thông báo "Bạn đã hết thời gian sử dụng"
- [ ] Tên app bị khóa
- [ ] Nút "Xin thêm 15 phút"
- [ ] Nút "Gọi khẩn cấp"
- [ ] Nút "Về trang chủ"

**Gợi ý thiết kế:**
```
┌─────────────────────────────────────┐
│                                     │
│              [🔒]                   │
│                                     │
│      Ứng dụng đã bị khóa           │
│                                     │
│    Bạn đã dùng TikTok 1h 30p      │
│    Đã hết giới hạn hôm nay         │
│                                     │
│   ┌─────────────────────────────┐   │
│   │     Xin thêm 15 phút        │   │
│   └─────────────────────────────┘   │
│                                     │
│   ┌─────────────────────────────┐   │
│   │     Gọi khẩn cấp 📞        │   │
│   └─────────────────────────────┘   │
│                                     │
│        Về trang chủ                │
└─────────────────────────────────────┘
```

#### Màn hình 3: Trung tâm thông báo (Parent Notifications)

**Thành phần cần có:**
- [ ] Header: "Thông báo"
- [ ] Danh sách thông báo
- [ ] Mỗi thông báo: icon, nội dung, thời gian
- [ ] Nút "Đồng ý" / "Từ chối" (cho yêu cầu xin giờ)
- [ ] Badge số thông báo chưa đọc

**Gợi ý thiết kế:**
```
┌─────────────────────────────────────┐
│ Thông báo                    [3] 🔔 │
├─────────────────────────────────────┤
│                                     │
│ 🕐 Bé Linh xin thêm 15 phút       │
│    Cho ứng dụng TikTok             │
│    2 phút trước                     │
│    [Đồng ý]  [Từ chối]            │
│                                     │
├─────────────────────────────────────┤
│ ⚠️ Cảnh báo: Phát hiện từ khóa    │
│    "bạo lực" trong tìm kiếm        │
│    15 phút trước                    │
│                                     │
├─────────────────────────────────────┤
│ ✅ Bạn đã cho phép thêm 15 phút   │
│    Cho YouTube                      │
│    1 giờ trước                      │
│                                     │
└─────────────────────────────────────┘
```

---

## PHẦN 3: BÀI TẬP VỀ NHÀ

### Bài Tập 1: Hoàn thiện thiết kế trên Figma

**Yêu cầu:**
- Hoàn thiện 3 màn hình đã vẽ trên lớp
- Thêm 2 màn hình nữa:
  - Màn hình Đăng nhập
  - Màn hình Chọn vai trò (Phụ huynh / Con)

### Bài Tập 2: Vẽ User Flow chi tiết

**Yêu cầu:**
- Vẽ User Flow cho luồng "Con xin thêm giờ → Phụ huynh phê duyệt"
- Bao gồm cả trường hợp "Phụ huynh từ chối"

---

## TÀI LIỆU THAM KHẢO

- Figma Tutorial: https://www.figma.com/resources/learn-design/
- Material Design 3: https://m3.material.io/
- Color Palette Generator: https://coolors.co/

---

## CÂU HỎI ÔN TẬP

1. KidGuardian giải quyết vấn đề gì?
2. User Flow là gì? Tại sao cần vẽ User Flow?
3. Dashboard của phụ huynh cần hiển thị những thông tin gì?
4. Màn hình khóa cần có những thành phần nào?

---

**Buổi Tiếp Theo:** [Buổi 2 - Thiết lập môi trường & Cấu trúc App](../buoi-02/README.md)
