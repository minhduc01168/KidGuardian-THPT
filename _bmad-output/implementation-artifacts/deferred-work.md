## Deferred from: code review of 3-1-set-time-limit (2026-05-14)
- Lỗi nuốt exception (`e.toString()`) trong BLoC / Repository: Cách xử lý lỗi đang khá basic, nên thiết lập một Error Mapper chung toàn project.
- Lỗi logic sắp xếp danh sách mỏng manh trong `SmartLockBloc` phụ thuộc `.isNotEmpty`: List sorting có thể sập nếu data không như kỳ vọng. Nên viết test kỹ hơn và thêm safe null-check.
