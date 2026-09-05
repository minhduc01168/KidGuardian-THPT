# Kế Hoạch Triển Khai Kiểm Tra & Hoàn Thiện 5 Luồng Nghiệp Vụ

Tài liệu này lưu trữ lại kế hoạch thực thi cho 5 luồng nghiệp vụ còn lại của KidGuardian, đối chiếu theo kiến trúc mới nhất tại `USE_CASE_FLOWS.md`.

## Nguyên Tắc (Principles)
- **FCM**: Tạm thời giả lập các hành động push notification / trigger ở phía Client do chưa hoàn thiện hạ tầng server.
- **E2E Testing**: Các luồng UI thuần (Flutter) sẽ được test qua `integration_test`. Các tính năng Native (như Accessibility Lock) sẽ được đảm bảo bằng Review Code kỹ lưỡng và PM sẽ test thủ công (Manual Test) trên máy thật.

---

## Phase 1: Luồng Liên Kết Tài Khoản (Family Linking Flow)
- **Mục tiêu:** Củng cố sự kiện liên kết giữa ứng dụng của phụ huynh và ứng dụng của trẻ em, không cần mã rườm rà. Phụ huynh sinh mã tự động, Trẻ em điền mã.
- **Thực thi:** 
  1. Kiểm tra lại `ChildDashboard` để đảm bảo khi chưa liên kết sẽ hiện form đòi mã.
  2. Kiểm tra `LinkChildToFamily` event trong `AuthBloc`.
  3. Viết `integration_test/family_linking_test.dart` giả lập Child login và điền mã liên kết.

---

## Phase 2: Luồng Giám Sát & Khóa Ứng Dụng (Smart Lock Flow)
- **Mục tiêu:** Kiểm tra và hoàn thiện service chạy ngầm chặn app trên Android.
- **Thực thi:** 
  1. Kiểm tra Android Native (`AppMonitorService.kt` và `MonitorForegroundService.kt`).
  2. Đảm bảo việc khóa app chỉ áp dụng trên Whitelist/Blacklist.
  3. Màn hình overlay khóa (Lock Screen) phải hiển thị nút "Xin Thêm Giờ".
  4. Đảm bảo Platform Channel gửi danh sách bị chặn sang Native chính xác.

---

## Phase 3: Luồng Xin Thêm Giờ (Time Request Flow)
- **Mục tiêu:** Trẻ bấm xin thêm giờ, cha mẹ chấp thuận.
- **Thực thi:** 
  1. Rà soát `InteractionRepository` xử lý trạng thái Approved/Rejected.
  2. Khi Approved, tự động cộng thêm thời gian (Time Limit) dưới Firestore.
  3. Ra lệnh gỡ khóa màn hình bên thiết bị của trẻ.

---

## Phase 4: Luồng Cảnh Báo An Toàn (Safety Alerts & Keyword Filtering)
- **Mục tiêu:** Kiểm tra văn bản (text) trẻ em nhập trên mạng để phát hiện từ khóa tiêu cực.
- **Thực thi:** 
  1. Tối ưu `onAccessibilityEvent` để chỉ quét text nhập liệu ở các ứng dụng quan trọng (như trình duyệt). Tránh làm hao pin và vi phạm quyền riêng tư.
  2. Cảnh báo và lưu log xuống Firestore (collection `alerts`) qua MethodChannel.

---

## Phase 5: Luồng Thống Kê & Báo Cáo (Dashboard & Reporting)
- **Mục tiêu:** Trực quan hóa dữ liệu sử dụng trên biểu đồ của Phụ huynh và Trẻ em.
- **Thực thi:** 
  1. Rà soát lại code của Tab thống kê trên `ParentDashboard` và `ChildDashboard`.
  2. Fix các lỗi biểu đồ (Fl_chart) bị trắng tinh hoặc không đồng bộ số liệu nếu có.

---
*(Được tự động tạo ra và thực thi bởi AI để bảo lưu tiến trình)*
