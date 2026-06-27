# Deferred Work

## Deferred from: code review of 6-1-monthly-report-screen.md (2026-06-27)
- [ ] Tối ưu hóa truy vấn Firestore khi số lượng usage_logs lớn trong 30 ngày `lib/data/repositories/report_repository_impl.dart:215` — Lý do: Hiện tại lượng log mỗi tháng của một trẻ ở mức vừa phải (~500-1000 logs), truy vấn trực tiếp vẫn phản hồi dưới 500ms. Sẽ tối ưu bằng aggregation cursor khi mở rộng quy mô.
