# MANUAL TEST PLAN - KidGuardian
## Hướng dẫn kiểm thử thủ công

**Phiên bản:** 1.0.0  
**Ngày tạo:** 23/05/2026  
**Người kiểm thử:** _______________  
**Ngày kiểm thử:** _______________

---

## MỤC LỤC

1. [Tổng quan kiểm thử](#1-tổng-quan-kiểm-thử)
2. [Chuẩn bị kiểm thử](#2-chuẩn-bị-kiểm-thử)
3. [Test Cases - Đăng ký & Đăng nhập](#3-test-cases---đăng-ký--đăng-nhập)
4. [Test Cases - Quản lý gia đình](#4-test-cases---quản-lý-gia-đình)
5. [Test Cases - Dashboard](#5-test-cases---dashboard)
6. [Test Cases - Giám sát sử dụng](#6-test-cases---giám-sát-sử-dụng)
7. [Test Cases - Smart Lock](#7-test-cases---smart-lock)
8. [Test Cases - Báo cáo & Thống kê](#8-test-cases---báo-cáo--thống-kê)
9. [Test Cases - Cài đặt](#9-test-cases---cài-đặt)
10. [Test Cases - Thông báo](#10-test-cases---thông-báo)
11. [Test Cases - Trợ giúp](#11-test-cases---trợ-giúp)
12. [Test Cases - Hiệu suất & UX](#12-test-cases---hiệu-suất--ux)
13. [Bug Report Template](#13-bug-report-template)
14. [Test Summary](#14-test-summary)

---

## 1. Tổng quan kiểm thử

### 1.1 Mục đích
Tài liệu này cung cấp hướng dẫn kiểm thử thủ công chi tiết cho ứng dụng KidGuardian, đảm bảo tất cả các tính năng hoạt động đúng theo yêu cầu.

### 1.2 Phạm vi kiểm thử
- Đăng ký/Đăng nhập
- Quản lý gia đình (Liên kết tài khoản)
- Dashboard (Phụ huynh & Trẻ em)
- Giám sát sử dụng ứng dụng
- Smart Lock (Khóa thông minh)
- Báo cáo & Thống kê
- Cài đặt ứng dụng
- Hệ thống thông báo
- Trợ giúp & Hỗ trợ

### 1.3 Priority Levels
| Priority | Mô tả |
|----------|-------|
| **P0 - Critical** | Bug nghiêm trọng, crash app |
| **P1 - High** | Tính năng chính không hoạt động |
| **P2 - Medium** | Tính năng phụ không hoạt động |
| **P3 - Low** | UI/UX issues, minor bugs |

---

## 2. Chuẩn bị kiểm thử

### 2.1 Thiết bị kiểm thử
| Thiết bị | OS | Version | Status |
|----------|------|---------|--------|
| Android Phone 1 | Android | 10+ | ☐ |
| Android Phone 2 | Android | 12+ | ☐ |
| iPhone 1 | iOS | 14+ | ☐ |
| iPhone 2 | iOS | 16+ | ☐ |

### 2.2 Tài khoản test
| Vai trò | Email | Password | Ghi chú |
|---------|-------|----------|---------|
| Phụ huynh | parent1@test.com | Test1234 | Tài khoản chính |
| Phụ huynh 2 | parent2@test.com | Test1234 | Test multi-parent |
| Trẻ em 1 | child1@test.com | Test1234 | Đã liên kết |
| Trẻ em 2 | child2@test.com | Test1234 | Chưa liên kết |

### 2.3 Test Environment
- **Network:** WiFi & 4G
- **Firebase:** Production environment
- **Notifications:** Enabled

---

## 3. Test Cases - Đăng ký & Đăng nhập

### TC-001: Chọn vai trò
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-001 |
| **Mô tả** | Kiểm tra màn hình chọn vai trò |
| **Priority** | P0 |
| **Precondition** | App mới cài đặt, chưa đăng nhập |

**Steps:**
1. Mở ứng dụng KidGuardian
2. Quan sát màn hình chọn vai trò

**Expected Result:**
- [ ] Hiển thị 2 lựa chọn: "Phụ huynh" và "Trẻ em"
- [ ] Có logo và tên ứng dụng
- [ ] UI hiển thị đẹp, không lỗi font

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-002: Đăng ký tài khoản Phụ huynh
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-002 |
| **Mô tả** | Kiểm tra đăng ký tài khoản mới |
| **Priority** | P0 |
| **Precondition** | Đã chọn vai trò "Phụ huynh" |

**Steps:**
1. Chọn vai trò "Phụ huynh"
2. Nhấn "Đăng ký" 
3. Nhập Họ tên: "Test Parent"
4. Nhập Email: "newparent@test.com"
5. Nhập Password: "Test1234"
6. Nhập Confirm Password: "Test1234"
7. Nhấn "Đăng ký"

**Expected Result:**
- [ ] Form validation hoạt động đúng
- [ ] Hiển thị loading khi đang đăng ký
- [ ] Đăng ký thành công → Chuyển đến Dashboard (Thời gian xử lý < 2 giây)
- [ ] Thông báo đăng ký thành công
- [ ] *Lưu ý Firebase:* Trên Firestore Console, chỉ bảng `users` được tạo ra ban đầu. Các bảng khác (như `families`, `app_usage`) sẽ xuất hiện khi có dữ liệu đầu tiên được insert. Đây là hành vi chuẩn (NoSQL dynamic schema), không phải lỗi thiếu bảng.

**Test Data:**
| Field | Valid | Invalid |
|-------|-------|---------|
| Email | test@email.com | test.com, test@, @email.com |
| Password | Test1234 | 123, abcdefgh, TESTTEST |
| Confirm Password | Match | Không match |

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-003: Đăng ký tài khoản Trẻ em
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-003 |
| **Mô tả** | Kiểm tra đăng ký tài khoản trẻ em |
| **Priority** | P0 |
| **Precondition** | Đã chọn vai trò "Trẻ em" |

**Steps:**
1. Chọn vai trò "Trẻ em"
2. Nhập Họ tên: "Test Child"
3. Nhập Email: "newchild@test.com"
4. Nhập Password: "Test1234"
5. Nhấn "Đăng ký"

**Expected Result:**
- [ ] Đăng ký thành công
- [ ] Chuyển đến Child Dashboard
- [ ] Hiển thị thông báo "Chưa liên kết tài khoản"

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-004: Đăng nhập thành công
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-004 |
| **Mô tả** | Kiểm tra đăng nhập với tài khoản hợp lệ |
| **Priority** | P0 |
| **Precondition** | Đã có tài khoản |

**Steps:**
1. Mở ứng dụng
2. Chọn vai trò "Phụ huynh"
3. Nhập Email: "parent1@test.com"
4. Nhập Password: "Test1234"
5. Nhấn "Đăng nhập"

**Expected Result:**
- [ ] Hiển thị loading indicator
- [ ] Đăng nhập thành công trong vòng 3 giây
- [ ] Chuyển đến Parent Dashboard
- [ ] Hiển thị tên người dùng trên AppBar

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-005: Đăng nhập thất bại
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-005 |
| **Mô tả** | Kiểm tra đăng nhập với thông tin sai |
| **Priority** | P0 |
| **Precondition** | Ở màn hình đăng nhập |

**Steps:**
1. Nhập Email: "wrong@email.com"
2. Nhập Password: "wrongpassword"
3. Nhấn "Đăng nhập"

**Expected Result:**
- [ ] Hiển thị thông báo lỗi "Email hoặc mật khẩu không đúng"
- [ ] Không crash app
- [ ] Có thể thử lại

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-006: Quên mật khẩu
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-006 |
| **Mô tả** | Kiểm tra chức năng quên mật khẩu |
| **Priority** | P1 |
| **Precondition** | Ở màn hình đăng nhập |

**Steps:**
1. Nhập Email: "parent1@test.com"
2. Nhấn "Quên mật khẩu?"
3. Kiểm tra email

**Expected Result:**
- [ ] Hiển thị thông báo "Đã gửi email đặt lại mật khẩu"
- [ ] Nhận được email từ Firebase
- [ ] Link trong email hoạt động

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-007: Validation form đăng nhập
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-007 |
| **Mô tả** | Kiểm tra validation các trường nhập liệu |
| **Priority** | P1 |
| **Precondition** | Ở màn hình đăng nhập |

**Steps:**
1. Để trống Email, nhấn "Đăng nhập"
2. Nhập Email không hợp lệ (không có @), nhấn "Đăng nhập"
3. Để trống Password, nhấn "Đăng nhập"
4. Nhập Password < 8 ký tự, nhấn "Đăng nhập"

**Expected Result:**
- [ ] Hiển thị "Vui lòng nhập email"
- [ ] Hiển thị "Email không hợp lệ"
- [ ] Hiển thị "Vui lòng nhập mật khẩu"
- [ ] Hiển thị "Mật khẩu phải ít nhất 8 ký tự"

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-008: Hiển thị/Ẩn mật khẩu
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-008 |
| **Mô tả** | Kiểm tra toggle hiển thị mật khẩu |
| **Priority** | P3 |
| **Precondition** | Ở màn hình đăng nhập |

**Steps:**
1. Nhập mật khẩu
2. Nhấn icon mắt để hiện mật khẩu
3. Nhấn icon mắt để ẩn mật khẩu

**Expected Result:**
- [ ] Mật khẩu hiển thị dưới dạng chấm (••••••)
- [ ] Nhấn icon → Hiển thị mật khẩu dạng text
- [ ] Nhấn lại → Ẩn mật khẩu

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-009: Đăng xuất
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-009 |
| **Mô tả** | Kiểm tra chức năng đăng xuất |
| **Priority** | P1 |
| **Precondition** | Đã đăng nhập |

**Steps:**
1. Vào Profile (icon người dùng)
2. Nhấn "Đăng xuất"
3. Xác nhận đăng xuất

**Expected Result:**
- [ ] Hiển thị dialog xác nhận
- [ ] Đăng xuất thành công
- [ ] Chuyển về màn hình chọn vai trò
- [ ] Không thể quay lại Dashboard bằng nút Back

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

## 4. Test Cases - Quản lý gia đình

### TC-010: Khởi tạo gia đình và thêm con
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-010 |
| **Mô tả** | Kiểm tra tính năng tạo gia đình ngầm và thêm con (cho phụ huynh mới) |
| **Priority** | P0 |
| **Precondition** | Đăng nhập tài khoản phụ huynh, chưa có gia đình |

**Steps:**
1. Đăng nhập tài khoản phụ huynh mới
2. Tại màn hình chính nhấn "Thêm con" hoặc vào Cài đặt > Quản lý gia đình > "Thêm tài khoản con"
3. Nhập tên con: "Bé An"
4. Nhập tuổi: 10
5. Nhấn "Tạo tài khoản"

**Expected Result:**
- [ ] Hệ thống tự động khởi tạo gia đình (nếu phụ huynh chưa có)
- [ ] Tạo tài khoản con thành công
- [ ] Hiển thị mã liên kết (linking code) 6 ký tự
- [ ] Tài khoản con xuất hiện trong danh sách quản lý gia đình

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-011: Quản lý mã liên kết và thêm thành viên khác
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-011 |
| **Mô tả** | Kiểm tra sao chép mã liên kết và tiếp tục tạo tài khoản con |
| **Priority** | P1 |
| **Precondition** | Đã tạo thành công tài khoản con ở TC-010 |

**Steps:**
1. Ở màn hình tạo thành công, nhấn "Sao chép mã"
2. Nhấn "Tạo tài khoản khác"
3. Nhập tên con và tuổi mới, nhấn "Tạo tài khoản"

**Expected Result:**
- [ ] Hiển thị thông báo "Đã sao chép mã liên kết"
- [ ] Form được làm trống để nhập thành viên mới
- [ ] Tạo thành công và hiển thị mã liên kết mới cho bé thứ 2

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-012: Liên kết tài khoản con (bằng mã)
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-012 |
| **Mô tả** | Kiểm tra liên kết tài khoản con bằng mã liên kết |
| **Priority** | P0 |
| **Precondition** | Tài khoản con chưa liên kết |

**Steps:**
1. Đăng nhập tài khoản trẻ em
2. Nhấn "Liên kết với phụ huynh"
3. Nhập mã liên kết từ phụ huynh
4. Nhấn "Liên kết"

**Expected Result:**
- [ ] Liên kết thành công
- [ ] Hiển thị thông báo thành công
- [ ] Dashboard cập nhật thông tin gia đình

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-013: Xem danh sách thành viên
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-013 |
| **Mô tả** | Kiểm tra hiển thị danh sách thành viên gia đình |
| **Priority** | P1 |
| **Precondition** | Gia đình có ít nhất 1 con |

**Steps:**
1. Vào "Quản lý gia đình"
2. Xem danh sách thành viên

**Expected Result:**
- [ ] Hiển thị tên phụ huynh
- [ ] Hiển thị danh sách con
- [ ] Hiển thị trạng thái liên kết
- [ ] Có thể xem chi tiết từng thành viên

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-014: Xóa thành viên khỏi gia đình
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-014 |
| **Mô tả** | Kiểm tra xóa con khỏi gia đình |
| **Priority** | P2 |
| **Precondition** | Gia đình có ít nhất 1 con |

**Steps:**
1. Vào "Quản lý gia đình"
2. Chọn con cần xóa
3. Nhấn "Xóa khỏi gia đình"
4. Xác nhận

**Expected Result:**
- [ ] Hiển thị dialog xác nhận
- [ ] Xóa thành công
- [ ] Con không còn trong danh sách
- [ ] Tài khoản con chuyển sang trạng thái "Chưa liên kết"

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

## 5. Test Cases - Dashboard

### TC-015: Parent Dashboard - Hiển thị tổng quan
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-015 |
| **Mô tả** | Kiểm tra hiển thị Parent Dashboard |
| **Priority** | P0 |
| **Precondition** | Đăng nhập tài khoản phụ huynh có gia đình |

**Steps:**
1. Đăng nhập tài khoản phụ huynh
2. Quan sát Dashboard

**Expected Result:**
- [ ] Hiển thị tên ứng dụng "KidGuardian"
- [ ] Hiển thị icon thông báo
- [ ] Hiển thị tab: Dashboard, Giám sát, Cài đặt
- [ ] Hiển thị tổng quan sử dụng của con
- [ ] Hiển thị biểu đồ sử dụng

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-016: Parent Dashboard - Xem chi tiết sử dụng
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-016 |
| **Mô tả** | Kiểm tra xem chi tiết sử dụng của con |
| **Priority** | P1 |
| **Precondition** | Ở Parent Dashboard |

**Steps:**
1. Nhấn vào con trong danh sách
2. Xem chi tiết sử dụng

**Expected Result:**
- [ ] Hiển thị tên con
- [ ] Hiển thị tổng thời gian sử dụng
- [ ] Hiển thị danh sách ứng dụng đã sử dụng
- [ ] Hiển thị thời gian cho từng ứng dụng
- [ ] Có nút "Làm mới"

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-017: Child Dashboard - Hiển thị
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-017 |
| **Mô tả** | Kiểm tra hiển thị Child Dashboard |
| **Priority** | P0 |
| **Precondition** | Đăng nhập tài khoản trẻ em đã liên kết |

**Steps:**
1. Đăng nhập tài khoản trẻ em
2. Quan sát Dashboard

**Expected Result:**
- [ ] Hiển thị thanh tiến trình sử dụng
- [ ] Hiển thị thời gian còn lại
- [ ] Hiển thị tab: Trang chủ, Sử dụng, Cài đặt
- [ ] Có nút "Truy cập khẩn cấp" (FAB)
- [ ] Màu sắc theme trẻ em (khác phụ huynh)

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-018: Child Dashboard - Chưa liên kết
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-018 |
| **Mô tả** | Kiểm tra Child Dashboard khi chưa liên kết |
| **Priority** | P1 |
| **Precondition** | Đăng nhập tài khoản trẻ em chưa liên kết |

**Steps:**
1. Đăng nhập tài khoản trẻ em mới
2. Quan sát Dashboard

**Expected Result:**
- [ ] Hiển thị thông báo "Chưa liên kết với phụ huynh"
- [ ] Có nút "Liên kết ngay"
- [ ] Không hiển thị tab Giám sát
- [ ] Không có nút Truy cập khẩn cấp

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-019: Dashboard - Làm mới dữ liệu
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-019 |
| **Mô tả** | Kiểm tra chức năng làm mới |
| **Priority** | P2 |
| **Precondition** | Ở Dashboard |

**Steps:**
1. Nhấn nút "Làm mới" (icon refresh)
2. Kéo xuống để làm mới (pull-to-refresh)

**Expected Result:**
- [ ] Hiển thị loading indicator
- [ ] Dữ liệu được cập nhật
- [ ] Không crash khi mất mạng

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

## 6. Test Cases - Giám sát sử dụng

### TC-020: Xem danh sách ứng dụng giám sát
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-020 |
| **Mô tả** | Kiểm tra hiển thị danh sách ứng dụng được giám sát |
| **Priority** | P0 |
| **Precondition** | Đăng nhập phụ huynh, đã có con |

**Steps:**
1. Vào tab "Giám sát"
2. Xem danh sách ứng dụng

**Expected Result:**
- [ ] Hiển thị danh sách ứng dụng (Facebook, TikTok, YouTube, etc.)
- [ ] Hiển thị thời gian giới hạn cho mỗi app
- [ ] Hiển thị thời gian đã sử dụng
- [ ] Hiển thị trạng thái (Bình thường/Cảnh báo/Vượt quá)

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-021: Thiết lập giới hạn thời gian
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-021 |
| **Mô tả** | Kiểm tra thiết lập giới hạn thời gian cho ứng dụng |
| **Priority** | P0 |
| **Precondition** | Ở màn hình giám sát |

**Steps:**
1. Chọn ứng dụng (VD: TikTok)
2. Nhấn "Thiết lập giới hạn"
3. Chọn thời gian: 60 phút
4. Nhấn "Lưu"

**Expected Result:**
- [ ] Hiển thị picker thời gian
- [ ] Lưu thành công
- [ ] Hiển thị giới hạn mới
- [ ] Áp dụng ngay lập tức

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-022: Thêm ứng dụng vào danh sách giám sát
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-022 |
| **Mô tả** | Kiểm tra thêm ứng dụng mới vào giám sát |
| **Priority** | P1 |
| **Precondition** | Ở màn hình giám sát |

**Steps:**
1. Nhấn "Thêm ứng dụng"
2. Chọn ứng dụng từ danh sách
3. Thiết lập giới hạn thời gian
4. Nhấn "Thêm"

**Expected Result:**
- [ ] Hiển thị danh sách ứng dụng cài đặt trên thiết bị
- [ ] Thêm thành công
- [ ] Ứng dụng xuất hiện trong danh sách giám sát

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-023: Xóa ứng dụng khỏi giám sát
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-023 |
| **Mô tả** | Kiểm tra xóa ứng dụng khỏi danh sách giám sát |
| **Priority** | P2 |
| **Precondition** | Danh sách có ít nhất 1 ứng dụng |

**Steps:**
1. Chọn ứng dụng
2. Nhấn icon xóa hoặc swipe để xóa
3. Xác nhận xóa

**Expected Result:**
- [ ] Hiển thị dialog xác nhận
- [ ] Xóa thành công
- [ ] Ứng dụng không còn trong danh sách

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

## 7. Test Cases - Smart Lock

### TC-024: Khóa ứng dụng khi vượt giới hạn
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-024 |
| **Mô tả** | Kiểm tra khóa ứng dụng khi sử dụng vượt giới hạn |
| **Priority** | P0 |
| **Precondition** | Thiết bị con đã cài app, giới hạn 30 phút |

**Steps:**
1. Mở ứng dụng được giám sát (VD: TikTok)
2. Sử dụng trong 30 phút
3. Quan sát khi hết thời gian

**Expected Result:**
- [ ] Hiển thị cảnh báo khi còn 5 phút
- [ ] Hiển thị cảnh báo khi còn 1 phút
- [ ] Hiển thị màn hình khóa khi hết thời gian
- [ ] Không thể thoát khỏi màn hình khóa bằng nút Back

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-025: Màn hình khóa - Hiển thị thông tin
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-025 |
| **Mô tả** | Kiểm tra hiển thị màn hình khóa |
| **Priority** | P0 |
| **Precondition** | Ứng dụng bị khóa |

**Steps:**
1. Đợi ứng dụng bị khóa
2. Quan sát màn hình khóa

**Expected Result:**
- [ ] Hiển thị icon khóa
- [ ] Hiển thị tên ứng dụng bị khóa
- [ ] Hiển thị thời gian đã sử dụng / giới hạn
- [ ] Hiển thị thời gian reset
- [ ] Có nút "Yêu cầu thêm thời gian"
- [ ] Màu đỏ/cảnh báo

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-026: Yêu cầu thêm thời gian
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-026 |
| **Mô tả** | Kiểm tra trẻ yêu cầu thêm thời gian |
| **Priority** | P1 |
| **Precondition** | Ở màn hình khóa |

**Steps:**
1. Nhấn "Yêu cầu thêm thời gian"
2. Chọn số phút muốn thêm: 30 phút
3. Nhập lý do: "Con cần thêm thời gian"
4. Nhấn "Gửi yêu cầu"

**Expected Result:**
- [ ] Hiển thị form yêu cầu
- [ ] Gửi thành công
- [ ] Hiển thị thông báo "Đã gửi yêu cầu"
- [ ] Phụ huynh nhận được thông báo

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-027: Phụ huynh duyệt yêu cầu thêm thời gian
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-027 |
| **Mô tả** | Kiểm tra phụ huynh duyệt yêu cầu |
| **Priority** | P1 |
| **Precondition** | Có yêu cầu từ con |

**Steps:**
1. Đăng nhập tài khoản phụ huynh
2. Vào thông báo
3. Xem yêu cầu từ con
4. Nhấn "Duyệt" và chọn số phút
5. Xác nhận

**Expected Result:**
- [ ] Hiển thị danh sách yêu cầu
- [ ] Hiển thị thông tin chi tiết
- [ ] Duyệt thành công
- [ ] Con nhận được thông báo
- [ ] Thời gian sử dụng được cộng thêm

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-028: Phụ huynh từ chối yêu cầu
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-028 |
| **Mô tả** | Kiểm tra phụ huynh từ chối yêu cầu |
| **Priority** | P2 |
| **Precondition** | Có yêu cầu từ con |

**Steps:**
1. Đăng nhập tài khoản phụ huynh
2. Vào thông báo
3. Xem yêu cầu từ con
4. Nhấn "Từ chối"
5. Nhập lý do (optional)
6. Xác nhận

**Expected Result:**
- [ ] Từ chối thành công
- [ ] Con nhận được thông báo từ chối
- [ ] Yêu cầu chuyển trạng thái "Từ chối"

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-029: Emergency Access
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-029 |
| **Mô tả** | Kiểm tra truy cập khẩn cấp |
| **Priority** | P1 |
| **Precondition** | Ứng dụng bị khóa |

**Steps:**
1. Ở màn hình khóa
2. Nhấn nút "Truy cập khẩn cấp" (FAB)
3. Nhập lý do khẩn cấp
4. Gửi yêu cầu

**Expected Result:**
- [ ] Hiển thị form nhập lý do
- [ ] Gửi yêu cầu thành công
- [ ] Phụ huynh nhận được thông báo khẩn cấp
- [ ] Yêu cầu được ưu tiên xử lý

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-030: Schedule Checker - Lịch sử dụng
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-030 |
| **Mô tả** | Kiểm tra tính năng lịch sử dụng |
| **Priority** | P2 |
| **Precondition** | Đã thiết lập lịch |

**Steps:**
1. Vào Smart Lock Settings
2. Thiết lập lịch: Thứ 2-6, 18:00-20:00
3. Thử sử dụng ngoài giờ

**Expected Result:**
- [ ] Lưu lịch thành công
- [ ] Chặn sử dụng ngoài giờ cho phép
- [ ] Hiển thị thông báo "Ngoài giờ sử dụng"

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

## 8. Test Cases - Báo cáo & Thống kê

### TC-031: Xem báo cáo hàng ngày
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-031 |
| **Mô tả** | Kiểm tra xem báo cáo sử dụng hàng ngày |
| **Priority** | P1 |
| **Precondition** | Có dữ liệu sử dụng |

**Steps:**
1. Vào "Tổng hợp" hoặc "Báo cáo"
2. Xem báo cáo hôm nay

**Expected Result:**
- [ ] Hiển thị tổng thời gian sử dụng
- [ ] Hiển thị chi tiết theo từng ứng dụng
- [ ] Hiển thị biểu đồ
- [ ] So sánh với giới hạn

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-032: Xem báo cáo tuần
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-032 |
| **Mô tả** | Kiểm tra xem báo cáo tuần |
| **Priority** | P1 |
| **Precondition** | Có dữ liệu sử dụng |

**Steps:**
1. Vào "Báo cáo tuần"
2. Chọn tuần cần xem
3. Xem chi tiết

**Expected Result:**
- [ ] Hiển thị tổng thời gian tuần
- [ ] Biểu đồ cột theo ngày
- [ ] Top 5 ứng dụng sử dụng nhiều nhất
- [ ] Trung bình mỗi ngày

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-033: Xuất báo cáo PDF
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-033 |
| **Mô tả** | Kiểm tra xuất báo cáo dạng PDF |
| **Priority** | P2 |
| **Precondition** | Ở màn hình báo cáo |

**Steps:**
1. Nhấn "Xuất báo cáo"
2. Chọn định dạng PDF
3. Chọn thời gian
4. Nhấn "Xuất"

**Expected Result:**
- [ ] Tạo file PDF thành công
- [ ] File PDF có đầy đủ thông tin
- [ ] Có thể mở file
- [ ] Có thể chia sẻ file

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-034: Xuất báo cáo CSV
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-034 |
| **Mô tả** | Kiểm tra xuất báo cáo dạng CSV |
| **Priority** | P2 |
| **Precondition** | Ở màn hình báo cáo |

**Steps:**
1. Nhấn "Xuất báo cáo"
2. Chọn định dạng CSV
3. Nhấn "Xuất"

**Expected Result:**
- [ ] Tạo file CSV thành công
- [ ] File CSV có đúng định dạng
- [ ] Có thể mở bằng Excel/Google Sheets

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-035: Usage Statistics - Biểu đồ
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-035 |
| **Mô tả** | Kiểm tra hiển thị biểu đồ thống kê |
| **Priority** | P2 |
| **Precondition** | Có dữ liệu sử dụng |

**Steps:**
1. Vào "Thống kê sử dụng"
2. Xem các loại biểu đồ

**Expected Result:**
- [ ] Biểu đồ cột (Bar chart)
- [ ] Biểu đồ tròn (Pie chart)
- [ ] Biểu đồ đường (Line chart)
- [ ] Có thể tương tác (tap để xem chi tiết)

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

## 9. Test Cases - Cài đặt

### TC-036: Thay đổi theme
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-036 |
| **Mô tả** | Kiểm tra thay đổi giao diện sáng/tối |
| **Priority** | P2 |
| **Precondition** | Ở màn hình Cài đặt |

**Steps:**
1. Vào "Cài đặt ứng dụng"
2. Chọn "Giao diện"
3. Chọn "Tối"
4. Quan sát thay đổi

**Expected Result:**
- [ ] Chuyển sang dark mode
- [ ] Tất cả screens đều dark mode
- [ ] Text vẫn đọc được
- [ ] Icons hiển thị đúng

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-037: Thay đổi ngôn ngữ
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-037 |
| **Mô tả** | Kiểm tra thay đổi ngôn ngữ |
| **Priority** | P2 |
| **Precondition** | Ở màn hình Cài đặt |

**Steps:**
1. Vào "Cài đặt ứng dụng"
2. Chọn "Ngôn ngữ"
3. Chọn "English"
4. Quan sát thay đổi

**Expected Result:**
- [ ] Chuyển sang tiếng Anh
- [ ] Tất cả text đều tiếng Anh
- [ ] Có thể chuyển lại tiếng Việt

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-038: Cài đặt thông báo
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-038 |
| **Mô tả** | Kiểm tra cài đặt thông báo |
| **Priority** | P2 |
| **Precondition** | Ở màn hình Cài đặt |

**Steps:**
1. Vào "Cài đặt ứng dụng"
2. Chọn "Thông báo"
3. Bật/tắt các loại thông báo

**Expected Result:**
- [ ] Toggle thông báo hoạt động
- [ ] Lưu cài đặt thành công
- [ ] Áp dụng ngay lập tức

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-039: Thay đổi mật khẩu
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-039 |
| **Mô tả** | Kiểm tra thay đổi mật khẩu |
| **Priority** | P1 |
| **Precondition** | Ở Profile |

**Steps:**
1. Vào Profile
2. Nhấn "Đổi mật khẩu"
3. Nhập mật khẩu hiện tại
4. Nhập mật khẩu mới
5. Xác nhận mật khẩu mới
6. Nhấn "Lưu"

**Expected Result:**
- [ ] Validation hoạt động đúng
- [ ] Đổi mật khẩu thành công
- [ ] Có thể đăng nhập bằng mật khẩu mới
- [ ] Thông báo thành công

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

## 10. Test Cases - Thông báo

### TC-040: Push Notification - Nhận thông báo
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-040 |
| **Mô tả** | Kiểm tra nhận push notification |
| **Priority** | P1 |
| **Precondition** | Đã bật thông báo |

**Steps:**
1. Đợi sự kiện触发 thông báo (VD: con yêu cầu thêm thời gian)
2. Kiểm tra notification

**Expected Result:**
- [ ] Nhận được push notification
- [ ] Hiển thị đúng nội dung
- [ ] Nhấn vào notification → Mở app đúng screen

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-041: In-App Notification
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-041 |
| **Mô tả** | Kiểm tra thông báo trong ứng dụng |
| **Priority** | P1 |
| **Precondition** | Đang sử dụng app |

**Steps:**
1. Đợi sự kiện触发 thông báo
2. Kiểm tra trong app

**Expected Result:**
- [ ] Hiển thị banner thông báo trong app
- [ ] Badge count trên icon thông báo
- [ ] Vào Notification Center xem chi tiết

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-042: Notification Center
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-042 |
| **Mô tả** | Kiểm tra trung tâm thông báo |
| **Priority** | P1 |
| **Precondition** | Có thông báo |

**Steps:**
1. Nhấn icon thông báo
2. Xem danh sách thông báo
3. Nhấn vào thông báo để xem chi tiết

**Expected Result:**
- [ ] Hiển thị danh sách thông báo
- [ ] Sắp xếp theo thời gian
- [ ] Đánh dấu đã đọc
- [ ] Nhấn vào → Navigate đúng screen

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-043: Alert History
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-043 |
| **Mô tả** | Kiểm tra lịch sử cảnh báo |
| **Priority** | P2 |
| **Precondition** | Có cảnh báo |

**Steps:**
1. Vào "Lịch sử cảnh báo"
2. Xem danh sách

**Expected Result:**
- [ ] Hiển thị danh sách cảnh báo
- [ ] Hiển thị thời gian, loại cảnh báo
- [ ] Có thể lọc theo loại

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

## 11. Test Cases - Trợ giúp

### TC-044: FAQ - Câu hỏi thường gặp
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-044 |
| **Mô tả** | Kiểm tra trang FAQ |
| **Priority** | P3 |
| **Precondition** | Ở màn hình Trợ giúp |

**Steps:**
1. Vào "Trợ giúp & Hỗ trợ"
2. Nhấn "Câu hỏi thường gặp"
3. Xem danh sách câu hỏi

**Expected Result:**
- [ ] Hiển thị danh sách FAQ
- [ ] Có thể expand/collapse
- [ ] Nội dung hữu ích

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-045: Liên hệ hỗ trợ
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-045 |
| **Mô tả** | Kiểm tra tính năng liên hệ hỗ trợ |
| **Priority** | P3 |
| **Precondition** | Ở màn hình Trợ giúp |

**Steps:**
1. Vào "Trợ giúp & Hỗ trợ"
2. Nhấn "Liên hệ hỗ trợ"
3. Nhập nội dung
4. Gửi

**Expected Result:**
- [ ] Hiển thị form liên hệ
- [ ] Gửi thành công
- [ ] Thông báo đã gửi

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-046: Thông tin ứng dụng
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-046 |
| **Mô tả** | Kiểm tra trang thông tin ứng dụng |
| **Priority** | P3 |
| **Precondition** | Ở màn hình Trợ giúp |

**Steps:**
1. Vào "Trợ giúp & Hỗ trợ"
2. Nhấn "Thông tin ứng dụng"

**Expected Result:**
- [ ] Hiển thị phiên bản ứng dụng
- [ ] Hiển thị thông tin liên hệ
- [ ] Link đến điều khoản sử dụng
- [ ] Link đến chính sách bảo mật

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

## 12. Test Cases - Hiệu suất & UX

### TC-047: App khởi động
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-047 |
| **Mô tả** | Kiểm tra thời gian khởi động app |
| **Priority** | P1 |
| **Precondition** | App chưa chạy |

**Steps:**
1. Đóng app hoàn toàn
2. Mở app
3. Đo thời gian

**Expected Result:**
- [ ] Khởi động trong < 3 giây
- [ ] Hiển thị splash screen
- [ ] Không crash

**Actual Result:** _______________  
**Thời gian:** _______ giây  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-048: Navigation mượt
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-048 |
| **Mô tả** | Kiểm tra độ mượt khi chuyển screen |
| **Priority** | P2 |
| **Precondition** | Đang sử dụng app |

**Steps:**
1. Chuyển qua lại giữa các tab
2. Navigate đến các screen khác nhau
3. Quan sát animation

**Expected Result:**
- [ ] Transition mượt, không giật
- [ ] Animation 60fps
- [ ] Không delay

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-049: Scroll performance
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-049 |
| **Mô tả** | Kiểm tra hiệu suất cuộn danh sách |
| **Priority** | P2 |
| **Precondition** | Có danh sách dài |

**Steps:**
1. Vào screen có danh sách dài
2. Cuộn lên xuống nhanh
3. Quan sát

**Expected Result:**
- [ ] Cuộn mượt
- [ ] Không lag
- [ ] Lazy loading hoạt động

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

### TC-050: Offline behavior
| Thông tin | Chi tiết |
|-----------|----------|
| **ID** | TC-050 |
| **Mô tả** | Kiểm tra hoạt động khi mất mạng |
| **Priority** | P2 |
| **Precondition** | Đang sử dụng app |

**Steps:**
1. Tắt WiFi/4G
2. Thử sử dụng app
3. Bật lại mạng

**Expected Result:**
- [ ] Hiển thị thông báo mất mạng
- [ ] Dữ liệu đã cache vẫn hiển thị
- [ ] Tự động sync khi có mạng

**Actual Result:** _______________  
**Status:** ☐ Pass ☐ Fail  
**Bug ID:** _______________

---

## 13. Bug Report Template

### Bug Report

**Bug ID:** BUG-XXX  
**Title:** _______________  
**Priority:** ☐ P0 ☐ P1 ☐ P2 ☐ P3  
**Status:** ☐ New ☐ Open ☐ In Progress ☐ Fixed ☐ Closed  

**Environment:**
- Device: _______________
- OS: _______________
- App Version: _______________
- Network: _______________

**Steps to Reproduce:**
1. _______________
2. _______________
3. _______________

**Expected Result:**
_______________

**Actual Result:**
_______________

**Screenshots/Videos:**
_______________

**Additional Notes:**
_______________

---

## 14. Test Summary

### Tổng kết kiểm thử

| Category | Total | Pass | Fail | Blocked | N/A |
|----------|-------|------|------|---------|-----|
| Đăng ký/Đăng nhập | 9 | | | | |
| Quản lý gia đình | 5 | | | | |
| Dashboard | 5 | | | | |
| Giám sát sử dụng | 4 | | | | |
| Smart Lock | 7 | | | | |
| Báo cáo/Thống kê | 5 | | | | |
| Cài đặt | 4 | | | | |
| Thông báo | 4 | | | | |
| Trợ giúp | 3 | | | | |
| Hiệu suất/UX | 4 | | | | |
| **TOTAL** | **50** | | | | |

### Test Completion

- **Total Test Cases:** 50
- **Executed:** _____
- **Passed:** _____
- **Failed:** _____
- **Pass Rate:** _____%

### Sign-off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| QA Lead | | | |
| Developer | | | |
| PM | | | |

---

**Tài liệu này được tạo cho dự án KidGuardian**  
**Cập nhật lần cuối: 23/05/2026**
