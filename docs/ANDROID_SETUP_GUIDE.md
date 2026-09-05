# Hướng dẫn cài đặt Android Studio & Máy ảo Android (Emulator) cho macOS

Vì Homebrew trên máy của bạn hiện đang gặp lỗi (như tôi đã kiểm tra ở các bước trước), và hệ điều hành của bạn đang dùng chip **Apple Silicon (arm64)**, dưới đây là hướng dẫn cài đặt thủ công chuẩn xác nhất để sau này có thể Build ứng dụng lên điện thoại thật hoặc chạy máy ảo Android mượt mà.

---

## Bước 1: Tải và cài đặt Android Studio

1. Truy cập trang chủ chính thức: [https://developer.android.com/studio](https://developer.android.com/studio)
2. Nhấn vào nút **Download Android Studio**.
3. Bảng điều khoản hiện ra, kéo xuống dưới cùng, tick chọn đồng ý.
4. **ĐẶC BIẾT LƯU Ý:** Do máy Mac của bạn dùng chip M, hãy bấm chọn nút **"Mac with Apple silicon"** (Đừng chọn bản Intel vì sẽ chạy rất chậm và dễ lỗi).
5. Sau khi tải xong file `.dmg`, mở file lên và kéo thả icon Android Studio vào thư mục **Applications**.

---

## Bước 2: Khởi tạo Android SDK

1. Mở **Android Studio** từ thư mục Applications (hoặc qua Spotlight/Launchpad).
2. Khi màn hình **Android Studio Setup Wizard** hiện lên, cứ bấm **Next** liên tục (chọn chế độ Standard).
3. Android Studio sẽ tự động tải các bộ công cụ lõi cần thiết gồm:
   - *Android SDK*
   - *Android SDK Platform-Tools*
   - *Android Emulator*
4. Cài đặt thêm Command-line Tools (Bắt buộc cho Flutter):
   - Khi ở màn hình Welcome của Android Studio, bấm vào biểu tượng 3 dấu chấm (hoặc tab **More Actions**) -> Chọn **SDK Manager**.
   - Chuyển sang tab **SDK Tools** (nằm ở giữa).
   - Tick chọn ô **"Android SDK Command-line Tools (latest)"**.
   - Bấm **Apply** -> **OK** và chờ nó tải xong.
5. Sau khi quá trình tải hoàn tất (mất vài phút tùy tốc độ mạng), bấm **Finish**.

---

## Bước 3: Cài đặt biến môi trường cho Command Line

Để Terminal (hoặc tôi) có thể tự động hiểu lệnh chạy ứng dụng lên máy ảo, bạn cần cấu hình lại file môi trường.

1. Mở ứng dụng **Terminal** trên máy tính.
2. Chạy lệnh mở file cấu hình bằng cách gõ:
   ```bash
   nano ~/.zshrc
   ```
3. Copy và Paste đoạn sau vào cuối cùng của file:
   ```bash
   export ANDROID_HOME=$HOME/Library/Android/sdk
   export PATH=$PATH:$ANDROID_HOME/emulator
   export PATH=$PATH:$ANDROID_HOME/platform-tools
   export PATH=$PATH:$HOME/.flutter-sdk/flutter/bin
   ```
4. Bấm `Ctrl + O` -> `Enter` để lưu lại, sau đó bấm `Ctrl + X` để thoát nano.
5. Chạy lệnh sau để áp dụng ngay các thay đổi:
   ```bash
   source ~/.zshrc
   ```

---

## Bước 4: Tạo máy ảo (Android Virtual Device - AVD)

1. Mở **Android Studio**, ở giao diện Welcome (chưa cần mở Project nào), nhấn vào tab **More Actions** (hoặc biểu tượng 3 dấu chấm) -> Chọn **Virtual Device Manager** (hoặc AVD Manager).
2. Nhấn nút **Create Virtual Device**.
3. Chọn giao diện màn hình (Ví dụ: **Pixel 7** hoặc **Pixel 8**) -> Nhấn **Next**.
4. Ở phần chọn System Image (Hệ điều hành Android):
   - Hãy chọn các bản Android từ **API 33 (Tiramisu)** hoặc **API 34 (UpsideDownCake)**.
   - Nhấn chữ **Download** kế bên hệ điều hành (chỉ mất công tải lần đầu tiên).
   - Đảm bảo bạn tải bản có tag **arm64** hoặc **Google Play** (do chip của bạn là Apple Silicon).
5. Sau khi Download xong, chọn Image đó và bấm **Next** -> Bấm **Finish**.
6. Ở bảng danh sách máy ảo, bấm nút **Play (▶)** để khởi động máy ảo lên.

---

## Bước 5: Chấp nhận các điều khoản (Licenses) của Android

Đây là bước cực kỳ quan trọng để Flutter có thể Build ra file APK hoặc chạy lên máy thật/máy ảo mà không văng lỗi cấp quyền.

Mở lại Terminal và gõ đúng lệnh sau:
```bash
flutter doctor --android-licenses
```
Mỗi khi Terminal hiện lên dòng hỏi chọn `(y/N)`, bạn cứ việc gõ phím `y` rồi `Enter` cho đến khi tất cả các dòng đều báo accepted (khoảng 5-6 lần).

---

## Bước 6: Kiểm tra thành quả

Vẫn trên Terminal, hãy chạy lệnh cuối cùng này:
```bash
flutter doctor
```

Nếu cài đặt thành công, bạn sẽ thấy hệ thống tích xanh ở các mục như sau:
- `[✓] Android toolchain - develop for Android devices`
- `[✓] Android Studio`

Sau khi bạn hoàn thành các bước trên và máy ảo Android đã được bật sáng màn hình. Bất cứ lúc nào bạn cần tôi chạy debug trên máy ảo, hoặc nếu bạn gõ lệnh `flutter run`, ứng dụng KidGuardian-THPT sẽ chạy hoàn hảo trên nền Android!
