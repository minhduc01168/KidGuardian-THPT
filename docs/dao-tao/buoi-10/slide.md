---
marp: true
theme: default
paginate: true
header: 'KidGuardian - Đồng Hành Số'
footer: 'BUỔI 10: Hoàn Thiện, Build APK & Đóng Gói Dự Án'
style: |
  section {
    background-color: #f8f9fa;
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    padding: 40px 50px;
  }
  h1 {
    color: #2c3e50;
    font-size: 2.2em;
    text-align: center;
  }
  h2 {
    color: #34495e;
    border-bottom: 2px solid #3498db;
    padding-bottom: 10px;
    margin-bottom: 20px;
  }
  h3 {
    color: #2980b9;
  }
  .center {
    text-align: center;
  }
  code {
    background-color: #e8eaed;
    border-radius: 4px;
    padding: 2px 4px;
    color: #c0392b;
  }
  pre code {
    color: #333;
    background-color: transparent;
  }
  pre {
    background-color: #f1f3f5;
    border-left: 4px solid #3498db;
  }
---

<!-- _class: lead -->
# 🚀 BUỔI 10: Hoàn Thiện, Build APK & Đóng Gói Dự Án

**Thời gian:** 2 tiết (90 phút)  
**Mục tiêu:** Fix bug, build APK, đẩy code lên GitHub

---

## 🎯 Tổng quan buổi học

- **Lý thuyết:** Nắm bắt các khái niệm quan trọng
- **Thực hành:** Áp dụng kiến thức vào thực tế
- **Bài tập:** Củng cố kiến thức đã học


---
<!-- _class: lead -->
# 📚 PHẦN 1: LÝ THUYẾT (30 phút)

---
## Quy Trình Đóng Gói Ứng Dụng

```
Development → Testing → Build → Deploy
     ↓           ↓        ↓        ↓
   Viết code   Test    Tạo APK   Cài lên điện thoại
```
---
## Debug vs Release

| Loại | Đặc Điểm | Mục Đích |
|------|-----------|----------|
| Debug | Có hot reload, debug tools | Phát triển |
| Release | Tối ưu hóa, nhỏ hơn | Deploy |
---
## README Là Gì?

**README** = File tài liệu chính của dự án

**Nội dung nên có:**
- Tên dự án
- Mô tả
- Cách cài đặt
- Cách chạy
- Tác giả

---

---
<!-- _class: lead -->
# 📚 PHẦN 2: THỰC HÀNH (60 phút)

---
## Kiểm Tra Lại Code

**Checklist:**

- [ ] App chạy không crash
- [ ] Đăng nhập hoạt động
- [ ] Dashboard hiển thị đúng
- [ ] Tính năng xin giờ hoạt động
- [ ] Cảnh báo hoạt động
- [ ] Không có lỗi UI
---
## Fix Bug Thường Gặp

**Bug 1: Null safety error**
```dart
// Sai
String name = user.name; // Có thể null

// Đúng
String name = user.name ?? 'Unknown';
```

**Bug 2: Async error**
```dart
// Sai
void loadData() {
  data = await fetchData(); // Lỗi vì không có async
}

// Đúng
Future<void> loadData() async {
  data = await fetchData();
}
```

**Bug 3: Widget not found**
```dart
// Sai
TextEditingController controller;

// Đúng
TextEditingController controller = TextEditingController();
```
---
## Tạo README.md

**Tạo file `README.md` trong thư mục gốc:**

```markdown
# KidGuardian - Đồng Hành Số

---
<!-- _class: lead -->
# 📚 PHẦN 3: BÀI TẬP CUỐI KHÓA

---
## Dự Án Cá Nhân

**Yêu cầu:**
- Hoàn thiện tất cả tính năng đã học
- Tùy chỉnh giao diện theo ý thích
- Thêm ít nhất 1 tính năng mới
- Viết README đầy đủ
- Đẩy code lên GitHub

**Tính năng mới có thể thêm:**
- Dark mode
- Đa ngôn ngữ
- Thống kê chi tiết hơn
- Chia sẻ lên mạng xã hội
- ...

---

---
<!-- _class: lead -->
# 📚 PHẦN 4: TỔNG KẾT KHÓA HỌC

---
## Kiến Thức Đã Học

| Buổi | Nội Dung | Kỹ Năng |
|------|----------|---------|
| 1 | UI/UX Design | Figma, User Flow |
| 2 | Flutter Setup | Tạo project, Cấu trúc |
| 3 | State Management | setState, StatefulWidget |
| 4 | Firebase Auth | Đăng ký, Đăng nhập |
| 5 | Firestore | CRUD dữ liệu |
| 6 | Data Viz | Biểu đồ fl_chart |
| 7 | Smart Lock | Timer, Logic kiểm tra |
| 8 | Real-time | Stream, Listener |
| 9 | AI Filter | Regex, Cảnh báo |
| 10 | Deploy | Build APK, GitHub |
---
## Sản Phẩm Hoàn Chỉnh

- ✅ Ứng dụng Flutter hoàn chỉnh
- ✅ Tích hợp Firebase Auth & Firestore
- ✅ Dashboard quản lý thời gian
- ✅ Cơ chế khóa giờ và xin thêm thời gian
- ✅ Logic cảnh báo nội dung nhạy cảm
- ✅ APK chạy trên thiết bị thật
- ✅ Mã nguồn trên GitHub
---
## Hướng Phát Triển Tiếp

1. **iOS Version:** Sử dụng Flutter để build cho iOS
2. **Advanced AI:** Sử dụng Machine Learning để lọc nội dung
3. **Multi-child:** Hỗ trợ nhiều con trong 1 gia đình
4. **Analytics:** Thống kê chi tiết hơn
5. **Social Features:** Chia sẻ tiến trình

---

---
<!-- _class: lead -->
# 🎉 Cảm ơn các bạn!
### Hẹn gặp lại vào buổi sau
