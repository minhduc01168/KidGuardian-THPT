# Hướng Dẫn Build APK Local (KidGuardian)

Tài liệu này hướng dẫn cách build file APK (`app-release.apk`) trên máy tính local (Ubuntu/Linux) để test trên thiết bị thật, đặc biệt bao gồm các cách xử lý lỗi tràn RAM (Out Of Memory) trên máy có dung lượng RAM hạn chế (ví dụ 8GB).

---

## Bước 1: Mở Terminal và trỏ vào thư mục project

Mở terminal và di chuyển vào thư mục gốc của project:
```bash
cd ~/CVS/kidguardian-thpt
```

## Bước 2: Cập nhật biến môi trường Flutter (nếu cần)

Nếu gõ lệnh `flutter` mà terminal báo `command not found`, bạn cần đưa đường dẫn Flutter vào biến môi trường:
```bash
export PATH="$PATH:$HOME/development/flutter/bin"
```
*(Lưu ý: Nếu bạn đã thêm lệnh này vào file `~/.bashrc` hoặc `~/.zshrc` thì có thể bỏ qua bước này).*

## Bước 3: Đảm bảo project đang ở code mới nhất

Luôn pull code mới nhất từ nhánh `develop` hoặc `master` trước khi build để tránh thiếu code:
```bash
git pull origin develop
```

## Bước 4: Chạy lệnh Build APK

Sử dụng cờ `--split-per-abi` để giảm dung lượng file APK (tạo ra các file APK riêng biệt cho từng loại chip điện thoại):
```bash
flutter build apk --release --split-per-abi
```

⏱ **Thời gian chờ:** Quá trình này thường kéo dài từ 3 đến 5 phút tùy cấu hình máy.

## Bước 5: Lấy file APK

Sau khi build thành công (có dòng chữ `✓ Built build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk...`), bạn có thể tìm thấy file APK tại đường dẫn sau trong project:

```text
build/app/outputs/apk/release/app-arm64-v8a-release.apk
```
*(Đây là file APK dành cho hầu hết các dòng điện thoại Android hiện nay. Bạn copy file này vào điện thoại và cài đặt).*

---

## 🛠 Xử lý lỗi thường gặp

### 1. Lỗi "Gradle build daemon disappeared unexpectedly" (Lỗi tràn RAM)

**Nguyên nhân:** Gradle mặc định yêu cầu quá nhiều RAM để build (ví dụ 8GB), trong khi máy tính của bạn chỉ có 8GB RAM tổng, dẫn đến hệ điều hành tự động "giết" tiến trình Gradle.

**Cách xử lý:**
Giới hạn bộ nhớ của Gradle xuống mức an toàn (ví dụ: 2GB) bằng cách sửa file `android/gradle.properties`:

1. Mở file `android/gradle.properties`
2. Tìm dòng `org.gradle.jvmargs=...`
3. Sửa lại thành:
   ```properties
   org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
   ```
4. Stop các tiến trình Gradle cũ bị kẹt:
   ```bash
   cd android
   ./gradlew --stop
   cd ..
   ```
5. Chạy lại lệnh build ở **Bước 4**.

### 2. Lỗi "Conflicting overloads: fun onServiceConnected()"

**Nguyên nhân:** Do quá trình merge code (đặc biệt khi xử lý Native Code Android) khiến một hàm Kotlin/Java bị khai báo 2 lần trong cùng một class.

**Cách xử lý:**
1. Đọc log lỗi trên terminal để xem hàm nào đang bị trùng (Ví dụ: báo lỗi tại file `AppMonitorService.kt:91` và `244`).
2. Mở file bị lỗi, tìm hàm bị trùng, giữ lại hàm mới nhất/đúng nhất và xóa phần khai báo bị lặp.
3. Chạy lại lệnh build.
