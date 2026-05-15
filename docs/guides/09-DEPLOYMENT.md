# Bài 9: Deployment
# Hướng Dẫn Build và Deploy Ứng Dụng

---

## 1. Tổng Quan

### 1.1 Các Giai Đoạn

```
Development → Testing → Staging → Production
     ↓           ↓         ↓          ↓
   Local      Firebase   Internal   Google Play
              Test Lab   Testing      Store
```

### 1.2 Các Loại Build

| Loại | Mục Đích | Command |
|------|----------|---------|
| Debug | Phát triển | `flutter run` |
| Profile | Test performance | `flutter run --profile` |
| Release | Deploy | `flutter build apk` |

---

## 2. Build Android

### 2.1 Debug Build

```bash
# Chạy trên device/emulator
flutter run

# Chạy với hot reload
flutter run --hot
```

### 2.2 Release Build

```bash
# Build APK
flutter build apk --release

# Build App Bundle (khuyến nghị cho Play Store)
flutter build appbundle --release
```

### 2.3 Build Output

```
build/app/outputs/
├── flutter-apk/
│   └── app-release.apk
└── flutter-app/
    └── app-release.aab
```

---

## 3. Cấu Hình Android

### 3.1 App Signing

```kotlin
// android/app/build.gradle
android {
    ...
    
    signingConfigs {
        release {
            storeFile file("key.jks")
            storePassword System.getenv("KEYSTORE_PASSWORD")
            keyAlias System.getenv("KEY_ALIAS")
            keyPassword System.getenv("KEY_PASSWORD")
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 3.2 Tạo Keystore

```bash
# Tạo keystore mới
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key

# Xem thông tin keystore
keytool -list -v -keystore ~/key.jks
```

### 3.3 ProGuard Rules

```proguard
# android/app/proguard-rules.pro
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
```

---

## 4. Firebase Configuration

### 4.1 Production Firebase

1. Tạo Firebase project mới cho production
2. Thêm Android app với package name chính xác
3. Tải `google-services.json`
4. Copy vào `android/app/google-services.json`

### 4.2 Environment Variables

```dart
// lib/core/config/env_config.dart
class EnvConfig {
  static const String apiKey = String.fromEnvironment('API_KEY');
  static const String authDomain = String.fromEnvironment('AUTH_DOMAIN');
  static const String projectId = String.fromEnvironment('PROJECT_ID');
}
```

### 4.3 Build với Environment

```bash
# Build với environment variables
flutter build apk --dart-define=API_KEY=your_api_key
```

---

## 5. Google Play Store

### 5.1 Tạo Tài Khoản

1. Truy cập: https://play.google.com/console
2. Đăng ký tài khoản developer ($25 một lần)
3. Điền thông tin thanh toán

### 5.2 Tạo App Mới

1. Click: Create app
2. Điền thông tin:
   - App name: KidGuardian
   - Default language: Vietnamese
   - App or game: App
   - Free or paid: Free
3. Click: Create

### 5.3 Upload App

1. Go to: Release → Production
2. Click: Create new release
3. Upload file `.aab` (App Bundle)
4. Điền release notes
5. Click: Review release

### 5.4 Store Listing

**Cần chuẩn bị:**

| Item | Yêu Cầu |
|------|---------|
| App name | Tối đa 30 ký tự |
| Short description | Tối đa 80 ký tự |
| Full description | Tối đa 4000 ký tự |
| Screenshots | Ít nhất 2 ảnh |
| Feature graphic | 1024 x 500 px |
| Icon | 512 x 512 px |

### 5.5 Content Rating

1. Go to: Policy → App content
2. Click: Start questionnaire
3. Trả lời câu hỏi về nội dung
4. Nhận rating

### 5.6 Privacy Policy

**Yêu cầu cho KidGuardian:**
- Mô tả dữ liệu thu thập
- Cách sử dụng dữ liệu
- Quyền của người dùng
- Liên hệ

**Template:**
```
Privacy Policy for KidGuardian

Last updated: [Date]

We collect the following information:
- User account information (email, name)
- App usage statistics
- Device information

We use this information to:
- Provide parental control features
- Monitor app usage
- Send notifications

Your rights:
- Access your data
- Delete your data
- Opt-out of data collection

Contact: [email]
```

---

## 6. App Review

### 6.1 Google Play Review

**Thời gian:** 1-3 ngày

**Có thể bị reject nếu:**
- Vi phạm chính sách
- Thiếu privacy policy
- App crash
- Nội dung không phù hợp

### 6.2 Chuẩn Bị Cho Review

- [ ] App không crash
- [ ] Có privacy policy
- [ ] Tuân thủ Families Policy
- [ ] Không có content inappropriate
- [ ] Permissions giải thích rõ ràng

---

## 7. CI/CD

### 7.1 GitHub Actions

```yaml
# .github/workflows/build.yml
name: Build and Test

on:
  push:
    branches: [ master, develop ]
  pull_request:
    branches: [ master ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: flutter pub get
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v3
        with:
          name: release-apk
          path: build/app/outputs/flutter-apk/app-release.apk
```

### 7.2 Fastlane

```ruby
# android/fastlane/Fastfile
default_platform(:android)

platform :android do
  desc "Deploy to Google Play"
  lane :deploy do
    gradle(task: "clean assembleRelease")
    upload_to_play_store(
      track: "internal",
      aab: "build/app/outputs/bundle/release/app-release.aab"
    )
  end
end
```

---

## 8. Monitoring

### 8.1 Firebase Crashlytics

```dart
// lib/main.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Set up Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  
  runApp(MyApp());
}
```

### 8.2 Firebase Analytics

```dart
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  static Future<void> logEvent(String name, Map<String, dynamic>? params) async {
    await _analytics.logEvent(name: name, parameters: params);
  }
  
  static Future<void> logLogin() async {
    await _analytics.logLogin(loginMethod: 'email');
  }
}
```

---

## 9. Version Management

### 9.1 Semantic Versioning

```
Major.Minor.Patch
  1.   0.   0

Major: Breaking changes
Minor: New features
Patch: Bug fixes
```

### 9.2 Cập Nhật Version

```yaml
# pubspec.yaml
version: 1.0.0+1
```

```bash
# Tăng version
flutter pub run cider bump major
flutter pub run cider bump minor
flutter pub run cider bump patch
```

### 9.3 Changelog

```markdown
# CHANGELOG.md

## 1.0.0
- Initial release
- Login/Register
- Dashboard
- Smart Lock

## 1.1.0
- Added Safety Alerts
- Improved UI

## 1.1.1
- Fixed login crash
- Performance improvements
```

---

## 10. Checklist Trước Khi Deploy

### 10.1 Code Quality

- [ ] Flutter analyze không có lỗi
- [ ] Test coverage > 70%
- [ ] Không có TODO/FIXME
- [ ] Code review completed

### 10.2 Testing

- [ ] Unit tests pass
- [ ] Widget tests pass
- [ ] Integration tests pass
- [ ] Manual testing trên device thật

### 10.3 Configuration

- [ ] Firebase production config
- [ ] App signing configured
- [ ] Version number updated
- [ ] Changelog updated

### 10.4 Documentation

- [ ] README updated
- [ ] API documentation
- [ ] User guide
- [ ] Privacy policy

### 10.5 Performance

- [ ] App size < 50MB
- [ ] Startup time < 3s
- [ ] No memory leaks
- [ ] Battery optimization

---

## 11. Post-Deploy

### 11.1 Monitoring

- [ ] Check Crashlytics
- [ ] Check Analytics
- [ ] Monitor user reviews
- [ ] Track key metrics

### 11.2 Response Plan

**Nếu có crash:**
1. Check Crashlytics
2. Fix bug
3. Deploy hotfix

**Nếu có bad review:**
1. Respond professionally
2. Fix issue
3. Update app

---

## 12. Tóm Tắt

| Bước | Command | Output |
|------|---------|--------|
| Debug | `flutter run` | Debug app |
| Build APK | `flutter build apk` | app-release.apk |
| Build AAB | `flutter build appbundle` | app-release.aab |
| Deploy | Upload to Play Store | Live app |

---

## 13. Tài Liệu Tham Khảo

- Flutter Build: https://docs.flutter.dev/deployment/android
- Google Play Console: https://play.google.com/console
- Firebase: https://firebase.google.com/docs

---

**Hoàn Thành!** 🎉

Bạn đã hoàn thành tất cả các bài hướng dẫn. Bây giờ bạn có thể:
1. Bắt đầu phát triển KidGuardian
2. Deploy lên Google Play Store
3. Monitoring và maintain ứng dụng
