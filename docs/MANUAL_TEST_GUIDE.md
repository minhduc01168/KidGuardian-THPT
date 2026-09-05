# HƯỚNG DẪN MANUAL TEST - KidGuardian

**Ứng dụng:** KidGuardian - Đồng Hành Số  
**Mục đích:** Quản lý và bảo vệ trẻ em trên không gian mạng, kiểm soát thời gian sử dụng ứng dụng thông minh  
**File APK:** `build/app/outputs/flutter-apk/app-debug.apk`  
**Cập nhật lần cuối:** 31/08/2026 (Đồng bộ 100% với 778/778 Automated Unit/Widget/BLoC Tests & Hoàn thiện 100% GAP Analysis Core Features)  

---

## MỤC LỤC

1. [Chuẩn bị trước khi test](#1-chuẩn-bị-trước-khi-test)
2. [Test Flow 1: Đăng ký & Đăng nhập](#2-test-flow-1-đăng-ký--đăng-nhập)
3. [Test Flow 2: Quản lý gia đình & Liên kết con (Link Code)](#3-test-flow-2-quản-lý-gia-đình--liên-kết-con-link-code)
4. [Test Flow 3: Dashboard & Giám sát tức thời](#4-test-flow-3-dashboard--giám-sát-tức-thời)
5. [Test Flow 4: Smart Lock & Lịch trình chặn](#5-test-flow-4-smart-lock--lịch-trình-chặn)
6. [Test Flow 5: Quản lý thời gian sử dụng](#6-test-flow-5-quản-lý-thời-gian-sử-dụng)
7. [Test Flow 6: Báo cáo & Thống kê sử dụng](#7-test-flow-6-báo-cáo--thống-kê-sử-dụng)
8. [Test Flow 7: Thông báo & Lịch sử](#8-test-flow-7-thông-báo--lịch-sử)
9. [Test Flow 8: Cài đặt hệ thống](#9-test-flow-8-cài-đặt-hệ-thống)
10. [Test Flow 9: Trợ giúp & FAQ](#10-test-flow-9-trợ-giúp--faq)
11. [Test Flow 10: Tương tác Parent-Child (Xin thêm giờ)](#11-test-flow-10-tương-tác-parent-child-xin-thêm-giờ)
12. [Test Flow 11: Khẩn cấp (Emergency Access)](#12-test-flow-11-khẩn-cấp-emergency-access)
13. [Test Flow 12: Foreground Service (FIX C1)](#13-test-flow-12-foreground-service-fix-c1)
14. [Test Flow 13: Native App Blocking - Accessibility (FIX C2)](#14-test-flow-13-native-app-blocking---accessibility-fix-c2)
15. [Test Flow 14: Realtime Time Request Notification (FIX C3)](#15-test-flow-14-realtime-time-request-notification-fix-c3)
16. [Test Flow 15: Cảnh Báo & Quản Lý Từ Khóa Nhạy Cảm (Epic 4 - 21 Từ Khóa)](#16-test-flow-15-cảnh-báo--quản-lý-từ-khóa-nhạy-cảm-epic-4---21-từ-khóa)
17. [Test Flow 16: Bảo vệ Hạn ngạch Firebase & Cơ chế Cooldown (FIX C4, C5, C6)](#17-test-flow-16-bảo-vệ-hạn-ngạch-firebase--cơ-chế-cooldown-fix-c4-c5-c6)
18. [Bug Report Template](#18-bug-report-template)
19. [Checklist Tổng hợp](#19-checklist-tổng-hợp)

---

## 1. Chuẩn bị trước khi test

### 1.1 Thiết bị yêu cầu
- [ ] Điện thoại Android 8.0+ (API 26+) hoặc máy ảo Android Emulator
- [ ] Kết nối Internet ổn định (WiFi hoặc 4G/LTE)
- [ ] 2 thiết bị (hoặc 1 điện thoại thật cho role Child + 1 máy ảo cho role Parent - xem Hướng dẫn 1.6)

### 1.2 Cài đặt APK
```text
1. Copy file app-debug.apk vào điện thoại
2. Vào Settings > Security > Unknown Sources → Bật
3. Mở file APK → Install
4. Cấp đầy đủ các quyền: Notification (Thông báo), Storage (Lưu trữ), Usage Access (Truy cập sử dụng)
```

### ⚠️ 1.3 Bật Accessibility Service (BẮT BUỘC cho máy Child)

> **Quan trọng:** KidGuardian sử dụng Accessibility Service để can thiệp chặn ứng dụng vi phạm ở mức phần cứng (`GLOBAL_ACTION_HOME`). Nếu không bật, tính năng khóa app sẽ KHÔNG hoạt động trên máy học sinh.

**Cách bật chung (Android Gốc/Pixel):**
1. Vào **Cài đặt (Settings)** > **Trợ năng (Accessibility)**.
2. Tìm **KidGuardian** (hoặc nằm trong mục **Ứng dụng đã tải xuống / Downloaded apps**).
3. Bật ON > Bấm **Cho phép (Allow)**.

**📱 Đối với điện thoại Samsung:**
1. Vào **Cài đặt** > **Hỗ trợ (Accessibility)** > **Ứng dụng đã cài đặt (Installed apps)**.
2. Tìm **KidGuardian** > Chuyển công tắc sang **Bật (On)** > Bấm **Cho phép**.

**📱 Đối với Xiaomi / Redmi / POCO (MIUI/HyperOS):**
> [!WARNING]
> **Khắc phục lỗi "Chế độ cài đặt bị hạn chế" (Restricted Settings) khi nút bật bị mờ:**  
> Từ Android 13/14 (MIUI 14 & HyperOS), hệ thống tự động khóa quyền Trợ năng đối với các file APK cài ngoài (sideloaded APK). Để mở khóa:
> 1. Vào **Cài đặt (Settings)** > **Ứng dụng (Apps)** > **Quản lý ứng dụng (Manage apps)**.
> 2. Tìm và chọn ứng dụng **KidGuardian** (hoặc nhấn giữ icon KidGuardian ngoài màn hình chính > Chọn **Thông tin ứng dụng / App info**).
> 3. Tại trang Thông tin ứng dụng:
>    - Cuộn xuống dưới cùng, tìm mục **"Cho phép cài đặt bị hạn chế" (Allow restricted settings)** và bật ON.
>    - *Hoặc (trên một số phiên bản MIUI/HyperOS):* Nhấn vào **biểu tượng 3 dấu chấm (⋮)** ở góc trên cùng bên phải > Chọn **"Cho phép cài đặt bị hạn chế" (Allow restricted settings)**.
> 4. Xác thực bằng vân tay/mật khẩu màn hình khóa nếu được yêu cầu.
> 5. Sau khi đã mở khóa thành công, quay trở lại **Cài đặt > Cài đặt bổ sung > Hỗ trợ tiếp cận (Accessibility) > Đã tải xuống > KidGuardian** và bật công tắc ON bình thường!

1. Vào **Cài đặt** > **Cài đặt bổ sung** > **Hỗ trợ tiếp cận (Accessibility)** > Tab **Đã tải xuống (Downloaded apps)**.
2. Chọn **KidGuardian** > Bật **Sử dụng KidGuardian**.
3. *Lưu ý:* Khi hiện cảnh báo nguy hiểm đếm ngược 10 giây, tích vào ô "Tôi nhận thức được rủi ro..." rồi bấm **OK**.

### 1.4 Tài khoản test (KHUYẾN NGHỊ)

Do cấu trúc Database trên Cloud đã được tối ưu bảo vệ Quota và chuẩn hóa các model mới, hãy tạo tài khoản mới để nghiệm thu:
- **Email Phụ huynh (Parent):** `parent_qa_2026@gmail.com`
- **Email Con (Child):** `child_qa_2026@gmail.com`
- **Mật khẩu chung:** `Test@123456`

### 1.5 Kiến trúc Hạ tầng & Bảo vệ Quota (Cập nhật 11/07/2026)
| Mã Fix | Tên cơ chế | Mô tả kỹ thuật | Section test |
| :--- | :--- | :--- | :--- |
| **FIX C1** | **Foreground Service** | Duy trì dịch vụ giám sát chạy ngầm `START_STICKY`, không bị kill khi swipe app | [Flow 12](#13-test-flow-12-foreground-service-fix-c1) |
| **FIX C2** | **Native App Blocking** | Khóa app bằng lệnh `GLOBAL_ACTION_HOME` qua Accessibility Service | [Flow 13](#14-test-flow-13-native-app-blocking---accessibility-fix-c2) |
| **FIX C3** | **Realtime Notification** | Lắng nghe yêu cầu xin giờ từ con qua Firestore Stream và thông báo tức thì | [Flow 14](#15-test-flow-14-realtime-time-request-notification-fix-c3) |
| **FIX C4** | **Cooldown 5 phút/app** | `_lastAlertSentMap` ngăn chặn spam ghi `createAppBlockedAlert` lên Firestore khi trẻ bấm liên tục vào app bị chặn | [Flow 16](#17-test-flow-16-bảo-vệ-hạn-ngạch-firebase--cơ-chế-cooldown-fix-c4-c5-c6) |
| **FIX C5** | **Khóa trần Reads (`.limit(50)`)** | Giới hạn tối đa 50 tài liệu mới nhất trên mọi luồng Stream Cảnh báo (`AlertRepository`), bảo vệ hạn ngạch 50.000 Reads/ngày | [Flow 16](#17-test-flow-16-bảo-vệ-hạn-ngạch-firebase--cơ-chế-cooldown-fix-c4-c5-c6) |
| **FIX C6** | **Offline SharedPreferences Cache** | Tự động đọc dữ liệu từ cache cục bộ (`SharedPreferences`) khi mất mạng hoặc timeout, đảm bảo app không văng/lỗi | [Flow 16](#17-test-flow-16-bảo-vệ-hạn-ngạch-firebase--cơ-chế-cooldown-fix-c4-c5-c6) |
| **FIX C7** | **Index-Defensive Architecture** | Lọc dải ngày và sắp xếp dữ liệu trên Client Dart memory (`SummaryRepository`, `ReportRepository`, `UsageRepository`) thay vì dùng composite index phức tạp trên Firestore | [Flow 16](#17-test-flow-16-bảo-vệ-hạn-ngạch-firebase--cơ-chế-cooldown-fix-c4-c5-c6) |
| **FIX C8** | **Granular App Selector** | Dropdown chọn ứng dụng cụ thể trong `RequestTimeDialog` khi trẻ xin thêm giờ từ màn hình Dashboard (`general_time`) | [Flow 10](#11-test-flow-10-tương-tác-parent-child-xin-thêm-giờ) |
| **FIX C9** | **8-App Whitelist (RAM Filter)** | Giới hạn thu thập & hiển thị thống kê nghiêm ngặt vào đúng 8 ứng dụng MXH (Facebook, TikTok, Instagram...) trên RAM Client | [Flow 6](#7-test-flow-6-báo-cáo--thống-kê-sử-dụng) |
| **FIX C10** | **Midnight Rollover** | Vòng lặp ngầm 30s của `AppMonitorService` kích hoạt khóa chặn lúc 00:00 ngay cả khi màn hình trẻ không tương tác | [Flow 4](#5-test-flow-4-smart-lock--lịch-trình-chặn) |
| **FIX C11** | **Keyword Monitor Scope** | Giới hạn tính năng quét từ khóa chỉ hoạt động trên 2 ứng dụng: Google Search và Chrome, Cooldown nâng lên 5 phút | [Flow 15](#16-test-flow-15-cảnh-báo--quản-lý-từ-khóa-nhạy-cảm-epic-4---21-từ-khóa) |
| **FIX C12** | **Two-way Analytics** | Widget `ChildAnalyticsWidget` phân tích biểu đồ dùng chung cho cả Child và Parent Dashboard | [Flow 6](#7-test-flow-6-báo-cáo--thống-kê-sử-dụng) |
| **FIX C13** | **Time Request Spam Block** | Chặn spam yêu cầu xin giờ từ trẻ: tối đa 3 lần / 1 giờ cho mỗi ứng dụng, dọn dẹp các yêu cầu lỗi hạn/qua ngày | [Flow 10](#11-test-flow-10-tương-tác-parent-child-xin-thêm-giờ) |

### 1.6 Hướng dẫn test với 1 thiết bị thật (Single Device Testing)
- **Thiết bị thật (Child Role):** Cài APK, đăng nhập role Con, bật Accessibility Service và Usage Stats. Thử nghiệm mở TikTok/Facebook để test khóa app thực tế.
- **Máy ảo Emulator trên máy tính (Parent Role):** Đăng nhập role Phụ huynh để theo dõi Dashboard, duyệt yêu cầu xin giờ, kiểm tra Lịch sử Cảnh báo realtime.

---

## 2. Test Flow 1: Đăng ký & Đăng nhập

### TC-AUTH-001: Đăng ký tài khoản Phụ huynh mới
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Mở app → Chọn "Đăng ký" | Màn hình đăng ký hiển thị | ☐ |
| 2 | Nhập Email `parent_qa_2026@gmail.com`, mật khẩu `Test@123456`, chọn vai trò **Phụ huynh** | Thông tin hợp lệ | ☐ |
| 3 | Nhấn "Đăng ký" | Chuyển sang màn hình tạo Gia đình / Thiết lập ban đầu | ☐ |

### TC-AUTH-002: Đăng nhập & Đăng xuất
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Nhập email và mật khẩu đúng → Nhấn Đăng nhập | Vào thẳng Parent Dashboard hoặc Child Dashboard tùy vai trò | ☐ |
| 2 | Nhập sai mật khẩu 1 ký tự → Nhấn Đăng nhập | Hiện thông báo lỗi rõ ràng ("Mật khẩu không chính xác") | ☐ |
| 3 | Vào Cài đặt → Nhấn Đăng xuất | Đăng xuất thành công, trở về màn hình Đăng nhập | ☐ |

---

## 3. Test Flow 2: Quản lý gia đình & Liên kết con (Link Code)

### TC-FAM-001: Phụ huynh tạo mã liên kết (Link Code)
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Trên máy Parent, vào Quản lý Gia đình → Chọn "Thêm con" | Tạo ra một mã liên kết gồm 6 chữ số (VD: `849201`), có thời hạn | ☐ |

### TC-FAM-002: Học sinh nhập mã liên kết thành công
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Trên máy Child, đăng ký/đăng nhập role Con → Mở màn hình "Liên kết gia đình" | Ô nhập mã 6 số hiển thị rõ ràng, nút "Liên kết" không bị cắt chữ | ☐ |
| 2 | Nhập mã 6 số vừa tạo từ máy Parent → Nhấn "Liên kết" | Liên kết thành công! Thiết bị Child hiển thị Dashboard giám sát | ☐ |
| 3 | Nhập mã sai hoặc mã đã hết hạn | Hiển thị lỗi "Mã liên kết không hợp lệ hoặc đã hết hạn" | ☐ |

---

## 4. Test Flow 3: Dashboard & Giám sát tức thời

### TC-DASH-001: Giám sát trạng thái thiết bị con realtime
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Mở Parent Dashboard | Hiển thị danh sách con đã liên kết, tình trạng Pin, thời gian sử dụng hôm nay | ☐ |
| 2 | Trên máy Child, mở ứng dụng bất kỳ (VD: YouTube) dùng 1 phút | Dữ liệu thời gian trên Parent Dashboard tự động tăng lên khớp thực tế | ☐ |

---

## 5. Test Flow 4: Smart Lock & Lịch trình chặn

### TC-LOCK-001: Khóa ứng dụng thủ công / Giới hạn thời gian
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Trên máy Parent, vào Smart Lock → Chọn TikTok → Đặt giới hạn `1 phút/ngày` | Lưu thiết lập thành công | ☐ |
| 2 | Trên máy Child, mở TikTok dùng quá 1 phút | TikTok lập tức bị đóng bằng cơ chế `GLOBAL_ACTION_HOME` mượt mà, văng thẳng về màn hình chính | ☐ |

### TC-LOCK-002: Vượt rào qua ngày (Midnight Rollover)
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Giả lập thời gian máy Child là `23:59`. Phụ huynh đã đặt Lịch trình giờ ngủ bắt đầu từ `00:00`. | Lịch trình thiết lập thành công | ☐ |
| 2 | Trẻ mở ứng dụng TikTok và không chạm vào màn hình trong 2 phút (chờ đồng hồ chuyển sang `00:00` hoặc `00:01`) | Dù không có tương tác (`AccessibilityEvent`), `Handler` 30s chạy ngầm vẫn phát hiện ra vi phạm giờ ngủ và tự động văng app về Home | ☐ |

---

## 6. Test Flow 5: Quản lý thời gian sử dụng

### TC-TIME-001: Thiết lập lịch trình giờ học / giờ ngủ
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Phụ huynh tạo lịch trình mới: "Giờ học tối" từ `19:00` đến `21:00`, chọn các ngày từ Thứ 2 đến Thứ 6 | Lịch trình được tạo và hiển thị trong danh sách | ☐ |
| 2 | Trong khung giờ `19:00 - 21:00`, trên máy Child mở game giải trí | Game bị khóa chặn lập tức với lý do "Đang trong lịch trình: Giờ học tối" | ☐ |

---

## 7. Test Flow 6: Báo cáo & Thống kê sử dụng

### TC-STAT-001: Xem báo cáo ngày/tuần/tháng
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Phụ huynh vào mục Báo cáo (Reports) → Chọn tab Ngày, Tuần, Tháng (30 ngày) | Biểu đồ tròn/cột hiển thị tổng thời gian sử dụng theo từng nhóm ứng dụng | ☐ |
| 2 | Kiểm tra danh sách ứng dụng trong báo cáo | Chỉ xuất hiện **đúng 8 ứng dụng mạng xã hội** (Facebook, TikTok, v.v.), không có ứng dụng hệ thống rác | ☐ |

### TC-STAT-002: Thống kê 2 chiều cho Child Dashboard (Two-way Analytics)
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Đăng nhập tài khoản Child → Mở tab **Sử dụng** trên trang chủ | `ChildAnalyticsWidget` hiển thị bảng tóm tắt: Hôm nay, 7 ngày, Trung bình | ☐ |
| 2 | Kéo xuống xem biểu đồ và lịch sử 7 ngày | Trẻ có thể tự xem biểu đồ thống kê cá nhân (chỉ hiển thị 8 app MXH), giống giao diện của Parent | ☐ |

---

## 8. Test Flow 7: Thông báo & Lịch sử

### TC-NOTIF-001: Trung tâm thông báo phụ huynh
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Vào Trung tâm thông báo (Notification Center) | Hiển thị các thông báo từ khóa, yêu cầu xin giờ, cảnh báo khóa app | ☐ |
| 2 | Nhấn nút "Đánh dấu tất cả đã đọc" | Trạng thái các thông báo chuyển sang đã đọc | ☐ |

---

## 9. Test Flow 8: Cài đặt hệ thống

### TC-SET-001: Đổi giao diện & Ngôn ngữ
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Vào Cài đặt → Chuyển đổi Theme Sáng (Light) / Tối (Dark) | Giao diện app thay đổi màu sắc ngay lập tức, mượt mà | ☐ |
| 2 | Kiểm tra hiển thị tên các ứng dụng và thông báo | Ngôn ngữ mặc định hiển thị Tiếng Việt chuẩn xác | ☐ |

---

## 10. Test Flow 9: Trợ giúp & FAQ

### TC-HELP-001: Đọc FAQ & Gửi hỗ trợ kỹ thuật
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Vào Trợ giúp & Hỗ trợ → Mở danh sách FAQ | Có thể bấm mở rộng / thu gọn (`ToggleFaqItem`) từng câu hỏi | ☐ |
| 2 | Nhập nội dung câu hỏi/phản hồi vào ô Hỗ trợ → Nhấn Gửi | Gửi thành công, hiện SnackBar thông báo xác nhận | ☐ |

---

## 11. Test Flow 10: Tương tác Parent-Child (Xin thêm giờ)

### TC-REQ-001: Trẻ xin thêm thời gian cho ứng dụng bị khóa (`app_blocked`)
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Khi app bị khóa, trên máy Child bấm **"Xin thêm thời gian"** (`RequestTimeDialog`) | Dialog hiển thị tên app (`Ứng dụng: TikTok`), các chip chọn `15 phút`, `30 phút`, `60 phút` (mặc định chọn 15 phút) và ô nhập lý do (`TextField`) | ☐ |
| 2 | Chọn `30 phút`, nhập lý do *"Con làm bài tập xong rồi ạ"* → Bấm **"Gửi yêu cầu"** | Yêu cầu được gửi lên Firestore, hiển thị thông báo đã gửi cho trẻ | ☐ |
| 3 | Máy Parent mở màn hình Yêu cầu thời gian → Bấm **"Duyệt" (+30 phút)** | Yêu cầu chuyển sang trạng thái "Đã duyệt" (`TimeRequestSubmitted`) | ☐ |
| 4 | Máy Child kiểm tra trạng thái (`TimeRequestStatusScreen`) | Trạng thái tự cập nhật realtime thành "✅ Đã được duyệt — +30 phút" và mở khóa app | ☐ |

### TC-REQ-002: Trẻ xin thêm thời gian từ Dashboard (`general_time` + App Selector Dropdown)
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Từ màn hình chính (Dashboard) trên máy Child, bấm nút **"Xin thêm thời gian"** (`general_time`) | Dialog hiển thị thêm một **Dropdown chọn ứng dụng (`AppSelector`)** liệt kê các ứng dụng đang có quy tắc giới hạn | ☐ |
| 2 | Bấm vào Dropdown và chọn `YouTube`, chọn số phút `45 phút`, nhập lý do | Hệ thống tự động kiểm tra app đó có nằm trong danh sách chặn/quy tắc hay không | ☐ |
| 3 | Bấm **"Gửi yêu cầu"** | Yêu cầu được tạo với `appPackageName` và `appName` chính xác của `YouTube` gửi tới phụ huynh duyệt | ☐ |

### TC-REQ-003: Chống Spam Yêu cầu (Tối đa 3 lần/giờ)
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Máy Child bấm xin thêm thời gian cho `TikTok` liên tục **3 lần** trong vài phút | 3 yêu cầu đầu tiên được gửi đi thành công | ☐ |
| 2 | Trẻ cố tình gửi tiếp yêu cầu xin giờ lần thứ 4 cho `TikTok` | Bị chặn lại với SnackBar báo lỗi: *"Bạn chỉ được gửi tối đa 3 yêu cầu trong vòng 1 giờ cho mỗi ứng dụng."* | ☐ |

---

## 12. Test Flow 11: Khẩn cấp (Emergency Access)

### TC-EMERG-001: Kích hoạt quyền truy cập khẩn cấp 5 phút
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Trên thiết bị Child, mở màn hình Liên hệ khẩn cấp (`EmergencyContactSheet`) → Bấm **"Kích hoạt khẩn cấp"** | Tất cả các ứng dụng bị khóa được mở khóa tạm thời trong đúng **5 phút** (`EmergencyAccessManager`) | ☐ |
| 2 | Thử kích hoạt lại khi đang trong thời gian khẩn cấp | Hệ thống báo không thể kích hoạt chồng chéo (`cannot activate when already active`) | ☐ |
| 3 | Sau khi hết 5 phút (hoặc bấm Hủy) | Khóa app được khôi phục, hệ thống thiết lập thời gian đóng băng (`cooldown`) trước khi được kích hoạt lần tiếp theo | ☐ |

---

## 13. Test Flow 12: Foreground Service (FIX C1)

> **Mục tiêu:** Xác nhận dịch vụ giám sát (`Monitoring Service`) chạy liên tục ngay cả khi app bị đưa ra background / bị swipe.

### TC-C1-001: Service notification hiển thị khi mở app
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Mở app KidGuardian (tài khoản Child) | App khởi động bình thường | ☐ |
| 2 | Kéo thanh thông báo (Notification Bar) xuống | Hiển thị thông báo **"KidGuardian đang giám sát"** (persistent notification) | ☐ |
| 3 | Thử vuốt ngang để tắt thông báo giám sát | Không thể vuốt tắt (tính năng bảo vệ dịch vụ ngầm) | ☐ |

### TC-C1-002: Service sống sót khi swipe app khỏi Recent Apps
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Mở đa nhiệm (Recent Apps) → Vuốt tắt (Swipe kill) KidGuardian | App bị đóng giao diện | ☐ |
| 2 | Kéo thanh thông báo xuống | Thông báo **"KidGuardian đang giám sát"** vẫn tồn tại và hoạt động | ☐ |
| 3 | Mở TikTok/Facebook dùng thử 1 phút → Mở lại KidGuardian | Thời gian sử dụng trong lúc tắt app vẫn được ghi nhận đầy đủ | ☐ |

### TC-C1-003: Service tự khởi động lại khi bị Force Stop bởi hệ thống
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Vào Cài đặt Android > Ứng dụng > KidGuardian > **Buộc dừng (Force Stop)** | Dịch vụ bị ngắt tạm thời | ☐ |
| 2 | Đợi khoảng 30 giây | Cơ chế `START_STICKY` tự động khởi động lại dịch vụ ngầm | ☐ |
| 3 | Kéo thanh thông báo | Thông báo giám sát xuất hiện lại tự động | ☐ |

---

## 14. Test Flow 13: Native App Blocking - Accessibility (FIX C2)

> **Mục tiêu:** Xác nhận app bị chặn ở mức phần cứng bằng lệnh `GLOBAL_ACTION_HOME` qua Accessibility Service.

### TC-C2-001: Kiểm tra trạng thái Accessibility Service
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Vào KidGuardian > Smart Lock > Cài đặt | Hiển thị trạng thái dịch vụ | ☐ |
| 2 | Kiểm tra dòng trạng thái | Hiển thị rõ: **"✅ Accessibility Service: Đã bật"** | ☐ |

### TC-C2-002: Chặn ứng dụng tức thì về màn hình Home
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Phụ huynh đặt giới hạn TikTok = `1 phút` | Lưu thành công | ☐ |
| 2 | Học sinh mở TikTok dùng hết thời gian | Màn hình **tức khắc bị văng về Home** (không rơi vào Recent Apps hay bị kẹt ở màn hình đen) | ☐ |
| 3 | Học sinh cố tình bấm mở lại TikTok từ màn hình Home | Lập tức bị đẩy về Home trong dưới 0.5 giây, hiển thị thông báo ứng dụng bị khóa | ☐ |

### TC-C2-003: Chặn ứng dụng hoạt động realtime khi phụ huynh vừa bật khóa
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Học sinh đang mở Instagram lướt bình thường | Trải nghiệm bình thường | ☐ |
| 2 | Phụ huynh mở điện thoại Parent, bấm chuyển công tắc khóa Instagram sang **Khóa** | Trong vòng 1-2 giây, màn hình máy học sinh tự động văng về Home | ☐ |
| 3 | Phụ huynh chuyển công tắc sang **Mở khóa** | Học sinh mở lại Instagram truy cập bình thường | ☐ |

---

## 15. Test Flow 14: Realtime Time Request Notification (FIX C3)

> **Mục tiêu:** Xác nhận phụ huynh nhận thông báo Realtime (không cần refresh) khi con gửi yêu cầu xin thêm thời gian qua Firestore Stream.

### TC-C3-001: Phụ huynh nhận thông báo ngay trong 5 giây
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Máy Parent đang mở ở Dashboard | — | ☐ |
| 2 | Máy Child gửi yêu cầu xin thêm 15 phút cho TikTok | Form gửi thành công | ☐ |
| 3 | Quan sát máy Parent | **Trong vòng 5 giây**, nhận thông báo đẩy: *"📱 Con xin thêm thời gian — TikTok: xin thêm 15 phút"* | ☐ |
| 4 | Bấm vào thông báo | Mở thẳng đến chi tiết yêu cầu để Duyệt/Từ chối | ☐ |

### TC-C3-002: Deduplication — Không gửi thông báo trùng lặp
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Trẻ gửi 1 yêu cầu xin giờ | Phụ huynh nhận đúng 1 thông báo, tuyệt đối không bị lặp 2-3 thông báo cùng nội dung | ☐ |

---

## 16. Test Flow 15: Cảnh Báo & Quản Lý Từ Khóa Nhạy Cảm (Epic 4 - 21 Từ Khóa)

> **Mục tiêu:** Kiểm tra khả năng giám sát bộ **21 từ khóa nhạy cảm mặc định** chuẩn hóa và tính năng gửi cảnh báo tức thì cho phụ huynh.
> 
> **Danh sách 21 từ khóa mặc định (`_defaultKeywords`):**
> 1. *Nguy hiểm tính mạng:* `tự tử`, `tự làm hại bản thân`, `nhảy lầu`
> 2. *Bạo lực & Vũ khí:* `đánh nhau`, `bạo lực`, `đánh hội đồng`, `dao`, `chém`
> 3. *Chất kích thích & Cờ bạc:* `ma túy`, `cần sa`, `thuốc lắc`, `cờ bạc`, `cá độ`, `cá cược`
> 4. *Nội dung người lớn:* `sex`, `khiêu dâm`, `phim người lớn`, `18+`
> 5. *Lừa đảo & An toàn:* `lừa đảo`, `hack`, `dâm ô`

### TC-KEYWORD-001: Kiểm tra bộ từ khóa mặc định & Quản lý tùy chỉnh (`KeywordManagementBloc`)
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Phụ huynh vào Cài đặt > Quản lý từ khóa (Keyword Management) | Khi chưa thêm từ khóa tùy chỉnh (`LoadKeywords`), hệ thống tự tải đúng **21 từ khóa mặc định** trên | ☐ |
| 2 | Nhấn "Thêm từ khóa" (`AddKeyword`) → Nhập `bắt nạt` → Nhấn Thêm | Danh sách tăng lên **22 từ khóa**, chứa từ `bắt nạt` | ☐ |
| 3 | Thử nhập lại từ khóa `tự tử` (đã có sẵn) | Hệ thống từ chối thêm trùng lặp, danh sách giữ nguyên | ☐ |
| 4 | Thử thêm khoảng trắng rỗng (`  `) | Hệ thống bỏ qua, không thêm từ khóa rỗng | ☐ |
| 5 | Nhấn nút "Khôi phục mặc định" (`ResetToDefaults`) | Danh sách tự động xóa các từ tùy chỉnh, trở về đúng **21 từ khóa chuẩn** ban đầu | ☐ |

### TC-KEYWORD-002: Phát hiện từ khóa nhạy cảm và gửi cảnh báo vi phạm
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Máy Child đang bật giám sát Accessibility, gõ văn bản hoặc tìm kiếm cụm từ `tự tử` trên trình duyệt **Chrome** hoặc **Google Search** | Hệ thống phát hiện vi phạm, tạo sự kiện `KeywordDetectedEvent` và lưu vào `AlertRepository` | ☐ |
| 2 | Trẻ gõ cụm từ tương tự trên ứng dụng Ghi chú, Zalo hoặc Tin nhắn (Không thuộc scope Chrome/Google) | Hệ thống KHÔNG quét văn bản, đảm bảo quyền riêng tư và tối ưu hóa hiệu năng | ☐ |
| 3 | Máy Parent kiểm tra thông báo/lịch sử cảnh báo (`Alert History`) | Nhận được cảnh báo realtime ghi rõ từ khóa vi phạm (chỉ từ Chrome/Google) | ☐ |

### TC-KEYWORD-003: Giới hạn Cooldown 5 phút khi gõ từ khóa
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Máy Child tìm kiếm từ `tự tử` trên Chrome | Hệ thống lập tức bắn 1 cảnh báo lên Firestore cho phụ huynh | ☐ |
| 2 | Trẻ tiếp tục gõ/tìm kiếm từ `tự tử` thêm 5 lần nữa trong vòng **3 phút** tiếp theo | Hệ thống âm thầm chặn ghi đè. Firestore KHÔNG tạo thêm cảnh báo nào mới (nhờ Cooldown 5 phút) | ☐ |

---

## 17. Test Flow 16: Bảo vệ Hạn ngạch Firebase & Cơ chế Cooldown (FIX C4, C5, C6)

> **Mục tiêu:** Kiểm chứng 3 "chốt chặn" kỹ thuật vừa được triển khai nhằm bảo vệ gói **Firebase Spark Plan (Free)** khỏi tình trạng thâm hụt hạn ngạch (`RESOURCE_EXHAUSTED`).

### TC-QUOTA-001: Kiểm chứng Cooldown 5 phút/app chống Spam Writes (`_lastAlertSentMap`)
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Phụ huynh đặt khóa ứng dụng TikTok. Trẻ mở TikTok lần 1 | TikTok bị văng về Home. Hệ thống ghi **1 tài liệu Alert** (`app_blocked`) lên Firestore | ☐ |
| 2 | Ngay sau đó (trong vòng 1-2 phút), trẻ cố chấp bấm mở TikTok thêm **10 lần liên tục** | TikTok vẫn bị chặn văng về Home 10 lần. **TUY NHIÊN:** Hệ thống `AppMonitorBloc` kiểm tra `_lastAlertSentMap` thấy chưa đủ 5 phút nên **TỪ CHỐI ghi thêm 10 Alert mới lên Firestore** | ☐ |
| 3 | Kiểm tra trên Firebase Console hoặc máy Parent | Chỉ có đúng **1 cảnh báo** được tạo ra cho ứng dụng TikTok trong khung giờ đó. Tiết kiệm 90-95% lượng Writes! | ☐ |
| 4 | Đợi đúng 5 phút sau, trẻ cố tình bấm mở lại TikTok | Lúc này hệ thống mới tiếp tục ghi thêm 1 Alert mới lên Firestore | ☐ |

### TC-QUOTA-002: Kiểm chứng giới hạn đọc `.limit(50)` trong Stream Cảnh báo (`AlertRepository`)
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Giả định gia đình có lịch sử tích tụ **500 cảnh báo cũ** trong Firestore over time | — | ☐ |
| 2 | Phụ huynh mở màn hình Lịch sử Cảnh báo (`Alert History` / `watchAllFamilyAlerts`) | Nhờ câu lệnh `.limit(50)`, ứng dụng chỉ truy vấn và tải đúng **50 tài liệu mới nhất** từ Firestore (không load toàn bộ 500 tài liệu) | ☐ |
| 3 | Kiểm tra mức tiêu thụ Reads trên trang Usage của Firebase | Lượng Reads mỗi lần load trang chỉ tốn tối đa 50 Reads, đảm bảo an toàn tuyệt đối dưới hạn mức 50.000 Reads/ngày | ☐ |

### TC-QUOTA-003: Kiểm chứng Offline Cache SharedPreferences khi mất kết nối Internet
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Trên máy Child, tắt hoàn toàn kết nối WiFi và 4G (bật Chế độ máy bay) | Thiết bị ngắt kết nối Internet | ☐ |
| 2 | Trẻ mở ứng dụng KidGuardian hoặc tiến hành kiểm tra danh sách app giám sát (`getMonitoredApps`) | Nhờ logic catch timeout & `SharedPreferences.getInstance()`, app lập tức đọc danh sách app và từ khóa từ cache cục bộ | ☐ |
| 3 | Thử mở một ứng dụng đã bị khóa trước đó (khi offline) | Tính năng chặn ứng dụng Smart Lock vẫn hoạt động trơn tru dựa trên dữ liệu cache SharedPreferences mà không bị crash hay đứng máy | ☐ |

### TC-QUOTA-004: Kiểm chứng Index-Defensive Querying trên Client memory (chống `FAILED_PRECONDITION`)
| Bước | Hành động | Kết quả mong đợi | Pass/Fail |
| :---: | :--- | :--- | :---: |
| 1 | Phụ huynh mở màn hình Báo cáo Tuần / Tổng kết (`SummaryRepository`, `ReportRepository`, `UsageRepository`) hoặc lọc theo khoảng thời gian (`getUsageByDateRange`) | Hệ thống gửi truy vấn đơn trường (chỉ lọc `childUid` hoặc `familyId`) lên Firestore mà không cần composite index `.orderBy()` phức tạp | ☐ |
| 2 | Kiểm tra trong Debug Console/Logcat | Không hề xuất hiện lỗi `FAILED_PRECONDITION: The query requires an index...` do toàn bộ logic sắp xếp và lọc dải ngày đã được thực hiện mượt mà trong RAM client (`client-side filtering`) | ☐ |
| 3 | Kiểm tra tốc độ phản hồi trên app | Dữ liệu hiển thị siêu nhanh, không bị treo retry liên tục gây cạn kiệt Quota hay crash app | ☐ |

---

## 18. Bug Report Template

Khi phát hiện lỗi trong quá trình test thực tế, vui lòng sao chép và điền theo mẫu chuẩn dưới đây:

```markdown
## BUG REPORT: [Mã lỗi ngắn gọn - VD: BR-001]

**Tiêu đề:** [Mô tả ngắn gọn hiện tượng lỗi]  
**Mức độ (Severity):** [Critical (Sập app/Hỏng logic) / High / Medium / Low]  
**Thiết bị & OS:** [VD: Samsung S23 Ultra - Android 14 / Emulator Pixel 7 - Android 13]  
**Phân hệ (Module):** [Smart Lock / Quota / Keywords / Time Request / Auth]  

**Các bước tái hiện (Steps to Reproduce):**
1. Vào màn hình...
2. Nhấn nút...
3. Thực hiện...

**Kết quả thực tế (Actual Result):** [Mô tả những gì xảy ra trên màn hình hoặc log]  
**Kết quả mong đợi (Expected Result):** [Mô tả những gì đúng thiết kế phải xảy ra]  
**Screenshot/Video / Log:** [Đính kèm hình ảnh hoặc đoạn log liên quan nếu có]  
```

---

## 19. Checklist Tổng hợp

### 🔐 Authentication & Family
- [ ] TC-AUTH-001: Đăng ký Phụ huynh mới
- [ ] TC-AUTH-002: Đăng nhập & Đăng xuất
- [ ] TC-FAM-001: Tạo mã liên kết 6 số (Parent)
- [ ] TC-FAM-002: Nhập mã liên kết thành công (Child)

### 📊 Dashboard & Time Management
- [ ] TC-DASH-001: Giám sát thời gian realtime
- [ ] TC-LOCK-001: Khóa ứng dụng & Giới hạn giờ (`1 phút/ngày`)
- [ ] TC-TIME-001: Lịch trình chặn theo giờ (`19:00 - 21:00`)
- [ ] TC-STAT-001: Báo cáo thống kê ngày/tuần/tháng & gom nhóm giờ (`groupByHour`)

### 💬 Tương tác & Khẩn cấp
- [ ] TC-REQ-001: Trẻ xin thêm giờ cho app bị khóa (`RequestTimeDialog`) & Phụ huynh duyệt
- [ ] TC-REQ-002: Trẻ xin thêm giờ từ Dashboard (`general_time` + Dropdown chọn app `RulesRepository`)
- [ ] TC-EMERG-001: Kích hoạt khẩn cấp 5 phút (`EmergencyAccessManager`) & kiểm chứng cooldown

### ⚙️ Cài đặt & Trợ giúp
- [ ] TC-NOTIF-001: Trung tâm thông báo & Đánh dấu đã đọc
- [ ] TC-SET-001: Đổi Theme Sáng/Tối & Ngôn ngữ Tiếng Việt
- [ ] TC-HELP-001: FAQ (`ToggleFaqItem`) & Gửi tin nhắn hỗ trợ

### ⭐ Kiến trúc & Bảo vệ Quota (FIX C1 -> C13)
- [ ] TC-C1-001 -> TC-C1-003: Foreground Service (`START_STICKY`) không bị kill khi swipe/Force Stop
- [ ] TC-C2-001 -> TC-C2-003: Native App Blocking (`GLOBAL_ACTION_HOME`) qua Accessibility Service
- [ ] TC-C3-001 -> TC-C3-002: Realtime Time Request Notification qua Firestore Stream dưới 5 giây
- [ ] TC-KEYWORD-001 -> TC-KEYWORD-003: Giới hạn Scope trên Chrome/Google & Cooldown 5 phút
- [ ] TC-QUOTA-001: Cooldown 5 phút/app (`_lastAlertSentMap`) chống spam Writes lên Firestore
- [ ] TC-QUOTA-002: Khóa trần `.limit(50)` cho luồng Stream Cảnh báo (`AlertRepository`)
- [ ] TC-QUOTA-003: Tự động chuyển cache cục bộ (`SharedPreferences`) khi mất kết nối Internet
- [ ] TC-QUOTA-004: Index-Defensive Querying trên Client memory (chống `FAILED_PRECONDITION`)
- [ ] TC-LOCK-002: Middleware Midnight Rollover đếm ngược 30s khóa chặn tự động lúc 00:00
- [ ] TC-STAT-001 -> TC-STAT-002: 8-App Whitelist và Two-way Analytics (Thống kê cho Child)
- [ ] TC-REQ-003: Chống Spam xin giờ (Tối đa 3 lần/1 giờ)

---
*Tài liệu được phát triển và chuẩn hóa bởi nhóm Kỹ sư Hệ thống KidGuardian — Sẵn sàng cho giai đoạn Kiểm thử Thực tế & Nghiệm thu Sản phẩm.*
