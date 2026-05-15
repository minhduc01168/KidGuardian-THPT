# Bài 1: Tổng Quan Dự Án
# KidGuardian - Đồng Hành Số

---

## 1. KidGuardian là gì?

KidGuardian là ứng dụng di động giúp **phụ huynh** và **trẻ em** cùng quản lý thói quen sử dụng mạng xã hội.

### Mục Tiêu
- Giám sát thời gian sử dụng mạng xã hội của con
- Khóa ứng dụng khi hết thời gian cho phép
- Cảnh báo khi con truy cập nội dung không phù hợp
- Cho phép con xin thêm giờ và phụ huynh phê duyệt

### Đối Tượng Sử Dụng
- **Phụ huynh:** Có con từ 11-18 tuổi
- **Trẻ em:** Từ 11-18 tuổi

---

## 2. Tính Năng Cốt Lõi

### 2.1 Dashboard (Bảng Điều Khiển)
- Biểu đồ thời gian sử dụng theo từng ứng dụng
- Tổng quan sử dụng trong ngày/tuần
- So sánh với ngày trước

### 2.2 Smart Lock (Khóa Thông Minh)
- Đặt giới hạn thời gian cho từng ứng dụng
- Tự động khóa khi hết thời gian
- Màn hình khóa thân thiện
- Lịch khóa (giờ học, giờ ngủ)

### 2.3 Safety Alerts (Cảnh Báo An Toàn)
- Phát hiện từ khóa không phù hợp
- Thông báo cho phụ huynh ngay lập tức
- Lịch sử cảnh báo

### 2.4 Two-Way Interaction (Tương Tác Hai Chiều)
- Trẻ gửi yêu cầu xin thêm giờ
- Phụ huynh phê duyệt/từ chối
- Thông báo real-time

---

## 3. Công Nghệ Sử Dụng

| Thành Phần | Công Nghệ | Lý Do Chọn |
|------------|-----------|------------|
| Framework | Flutter | Phát triển 1 lần, chạy cả Android/iOS |
| Backend | Firebase | Miễn phí, dễ sử dụng, real-time |
| State Management | BLoC | Dễ test, dễ maintain |
| Database | Firestore | Real-time sync, offline support |
| Auth | Firebase Auth | Bảo mật, hỗ trợ nhiều phương thức |

---

## 4. Quy Trình Phát Triển

```
Phase 1 (Tháng 1-2): Android MVP
    ↓
Phase 2 (Tháng 3-4): iOS + Enhancement
    ↓
Phase 3 (Tháng 5-6): Advanced Features
```

### Phase 1: Android MVP
- Đăng ký/đăng nhập
- Dashboard giám sát
- Smart Lock (Android)
- Cảnh báo an toàn
- Tương tác hai chiều

---

## 5. Tại Sao Lại Làm Dự Án Này?

### Vấn Đề
- Trẻ em dành quá nhiều thời gian trên mạng xã hội
- Phụ huynh khó kiểm soát
- Thiếu công cụ giám sát minh bạch

### Giải pháp
- KidGuardian giúp phụ huynh giám sát **minh bạch**
- Trẻ em hiểu rõ giới hạn và được **thương lượng**
- Không phải "giám sát bí mật" mà là "đồng hành cùng con"

---

## 6. Lưu Ý Quan Trọng

### Về Quyền Riêng Tư
- Đây là ứng dụng giám sát **có sự đồng ý**
- Phụ huynh và con cùng thống nhất quy tắc
- Không thu thập dữ liệu không cần thiết

### Về Compliance
- Tuân thủ COPPA (trẻ em dưới 13 tuổi)
- Tuân thủ GDPR-K (nếu có user châu Âu)
- Tuân thủ Luật An toàn thông tin mạng Việt Nam

---

## 7. Câu Hỏi Thường Gặp

**H:** Ứng dụng có miễn phí không?  
**C:** Có, sử dụng Firebase Free Tier. Có thể giới hạn số lượng user.

**H:** iOS có khóa app được không?  
**C:** Không, iOS hạn chế nghiêm ngặt. Phase 2 sẽ dùng Screen Time API.

**H:** Trẻ có thể gỡ cài đặt app không?  
**C:** Có, nhưng phụ huynh sẽ nhận thông báo. Cần thỏa thuận với con.

---

## 8. Tài Liệu Tham Khảo

- [PRD chi tiết](../prd/PRD.md)
- [Kiến trúc hệ thống](../architecture/ARCHITECTURE.md)
- [Epics & Stories](../epics/EPICS.md)

---

**Bài Tiếp Theo:** [Cài Đặt Môi Trường](02-CAI-DAT-MOI-TRUONG.md)
