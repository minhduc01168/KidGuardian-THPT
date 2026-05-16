# Hướng Dẫn Cài Đặt Máy Ảo Waydroid Trên Ubuntu 20.04 (Cho Máy Yếu)

Tài liệu này hướng dẫn cách cài đặt **Waydroid** để chạy máy ảo Android giả lập trên Ubuntu 20.04. Đây là giải pháp thay thế tối ưu cho Android Virtual Device (AVD) của Android Studio, đặc biệt phù hợp cho các máy tính có cấu hình thấp (RAM <= 8GB, ổ cứng trống ít).

Waydroid sử dụng chung nhân (kernel) với Ubuntu nên chạy cực kỳ mượt mà, tốn rất ít RAM và chỉ chiếm khoảng 1.5GB - 2GB dung lượng ổ cứng.

---

## 1. Yêu cầu hệ thống

*   Hệ điều hành: Ubuntu 20.04 LTS (Hoặc các bản phân phối dựa trên Debian/Ubuntu).
*   RAM: Tối thiểu 4GB (Khuyến nghị 8GB).
*   Ổ cứng trống: Tối thiểu 3GB.

---

## 2. Cài đặt Weston (Môi trường Wayland giả lập)

Vì Ubuntu 20.04 mặc định sử dụng môi trường hiển thị **X11**, trong khi Waydroid bắt buộc phải chạy trên môi trường **Wayland**, chúng ta cần cài đặt một "cầu nối" rất nhẹ có tên là **Weston**.

Mở Terminal (`Ctrl` + `Alt` + `T`) và chạy lệnh sau:

```bash
sudo apt update
sudo apt install weston -y
```

*(Lưu ý: Nếu bạn thấy các cảnh báo dạng `/sbin/ldconfig.real: ... is not a symbolic link` liên quan đến OpenCV hoặc thư viện khác ở cuối quá trình cài đặt, hãy bỏ qua chúng. Quá trình cài đặt Weston vẫn thành công).*

---

## 3. Cài đặt Waydroid

Tiếp tục chạy lần lượt các lệnh sau để cài đặt các công cụ cần thiết, thêm kho lưu trữ (repository) của Waydroid và tiến hành cài đặt:

```bash
# Cài đặt các gói phụ thuộc
sudo apt install curl ca-certificates -y

# Thêm kho lưu trữ của Waydroid
curl -s https://repo.waydro.id | sudo bash

# Cài đặt ứng dụng Waydroid
sudo apt install waydroid -y
```

---

## 4. Khởi tạo Android (Tải Image)

Bước này sẽ tải hệ điều hành Android về máy tính. Để tiết kiệm dung lượng ổ cứng và RAM, hãy cài đặt bản **VANILLA** (Phiên bản Android thuần túy, KHÔNG chứa Google Play Services).

Chạy lệnh sau trong Terminal:

```bash
sudo waydroid init -s VANILLA
```

*Lưu ý: Quá trình này cần tải về khoảng 1.5GB dữ liệu hình ảnh (system image) của Android. Vui lòng kiên nhẫn chờ đợi cho đến khi tiến trình hoàn tất.*

---

## 5. Hướng dẫn khởi chạy và sử dụng Waydroid (Rất Quan Trọng)

Trên Ubuntu 20.04 (X11), bạn **không thể** mở Waydroid trực tiếp từ Menu ứng dụng thông thường. Bạn phải khởi chạy thông qua cửa sổ Weston. 

Mỗi khi muốn bắt đầu code và cần mở máy ảo, hãy thực hiện đúng 3 bước sau:

**Bước 5.1:** Mở **Terminal 1** và khởi chạy Weston:
```bash
weston
```
*(Một cửa sổ màn hình trống sẽ hiện lên. Đây chính là không gian Wayland. Hãy giữ nguyên cửa sổ này và đừng tắt).*

**Bước 5.2:** Mở **Terminal 2** (Mở thêm một tab terminal mới) và khởi động dịch vụ ngầm của Waydroid:
```bash
waydroid session start
```

**Bước 5.3:** Mở **Terminal 3** (Mở thêm tab thứ ba) và hiển thị giao diện Android lên cửa sổ Weston:
```bash
waydroid show-full-ui
```
Lúc này, giao diện Android sẽ xuất hiện bên trong cửa sổ Weston.

---

## 6. Kết nối Flutter/VS Code với Waydroid để Debug

Sau khi máy ảo Waydroid đã chạy, bạn cần kết nối nó với công cụ lập trình thông qua ADB (Android Debug Bridge).

**Bước 6.1:** Lấy địa chỉ IP của máy ảo Waydroid. Gõ lệnh sau vào Terminal:
```bash
waydroid status
```
*Tìm dòng có ghi `IP: 192.168.xxx.xxx` (Ví dụ: `192.168.240.112`).*

**Bước 6.2:** Kết nối ADB với địa chỉ IP vừa lấy được:
```bash
adb connect 192.168.xxx.xxx:5555
```
*(Thay thế bằng IP thực tế của bạn, luôn kèm theo port `:5555`).*

**Bước 6.3:** Mở VS Code. Ở góc dưới bên phải màn hình (Khu vực chọn Device), bạn sẽ thấy một thiết bị mới xuất hiện có tên là **waydroid_x86_64**. Chọn thiết bị này.

**Bước 6.4:** Chạy ứng dụng KidGuardian của bạn như bình thường:
```bash
flutter run
```

---

## 7. Cách tắt Waydroid đúng cách để giải phóng RAM

Sau khi hoàn thành công việc lập trình, bạn nên tắt hoàn toàn Waydroid để giải phóng RAM cho máy tính.

Chạy lần lượt 2 lệnh sau:

```bash
# Dừng phiên làm việc hiện tại
waydroid session stop

# Dừng toàn bộ container của Waydroid ngầm
sudo waydroid container stop
```

Sau khi chạy xong, bạn có thể tắt cửa sổ Weston.

---
**Cập nhật lần cuối:** 2026-05-16
