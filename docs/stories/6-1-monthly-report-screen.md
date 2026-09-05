# Story 6.1: Màn Hình Báo Cáo Tháng (Monthly Report Screen)
**Status:** done

## Mục Tiêu (Objective)
Lập trình màn hình tổng kết và báo cáo tháng (`MonthlyReportScreen`) cho phụ huynh, cho phép trực quan hóa dữ liệu sử dụng thiết bị dài hạn (30 ngày gần nhất) dưới dạng biểu đồ xu hướng và các số liệu phân tích chuyên sâu.

## Danh Sách Công Việc (Tasks)
- [x] **Task 1:** Tạo file `lib/presentation/features/report/screens/monthly_report_screen.dart`.
- [x] **Task 2:** Xây dựng Bloc / Cubit hoặc tái sử dụng `ReportBloc` để truy vấn dữ liệu từ Firestore (`usage_logs` collection trong 30 ngày qua).
- [x] **Task 3:** Thiết kế UI hiển thị Biểu đồ xu hướng tháng (Trend Chart) sử dụng thư viện `fl_chart`.
- [x] **Task 4:** Thêm thống kê "Top 5 ứng dụng tiêu tốn nhiều thời gian nhất trong tháng".
- [x] **Task 5:** Xử lý trường hợp không có dữ liệu (Empty Data) tương tự Daily & Weekly Report để tránh lỗi màn hình trắng.
- [x] **Task 6:** Cập nhật liên kết chuyển trang từ tab `MonthlyReport` ở `Overview` sang màn hình mới này.

## Tiêu Chí Chấp Nhận (Acceptance Criteria)
1. Hiển thị mượt mà biểu đồ cột hoặc đường biểu diễn thời gian sử dụng thiết bị trong 4 tuần / 30 ngày.
2. Có danh sách xếp hạng Top 5 ứng dụng tốn thời gian nhất kèm tổng số giờ sử dụng cụ thể.
3. Khi không có kết nối mạng hoặc lịch sử trống, màn hình hiển thị thông báo "Chưa có dữ liệu tháng" một cách thân thiện.
4. Không phát sinh cảnh báo lỗi (Lint check sạch).

### Review Findings
- [x] [Review][Patch] Tránh lặp nhãn trục X trên biểu đồ xu hướng tuần khi bước nhảy lẻ `lib/presentation/features/report/screens/monthly_report_screen.dart:345`
- [x] [Review][Defer] Tối ưu hóa truy vấn Firestore khi số lượng usage_logs lớn trong 30 ngày `lib/data/repositories/report_repository_impl.dart:215` — deferred, pre-existing
