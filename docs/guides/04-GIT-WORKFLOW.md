# Bài 4: Git Workflow
# Quy Trình Làm Việc Với Git

---

## 1. Tại Sao Dùng Git?

### 1.1 Git Là Gì?
- Hệ thống quản lý phiên bản phân tán (Distributed Version Control)
- Theo dõi thay đổi code
- Nhiều người làm việc cùng lúc
- Dễ dàng quay lại phiên bản trước

### 1.2 Tại Sao Quan Trọng?
- **Backup:** Code được lưu trữ an toàn
- **Collaboration:** Nhiều người cùng code
- **History:** Xem lại lịch sử thay đổi
- **Branching:** Làm việc trên nhiều tính năng cùng lúc

---

## 2. Cấu Trúc Repository

```
KidGuardian-THPT/
├── .git/                    # Git metadata
├── lib/                     # Source code
├── docs/                    # Documentation
├── test/                    # Tests
├── android/                 # Android native
├── ios/                     # iOS native
├── pubspec.yaml             # Dependencies
├── .gitignore               # Files to ignore
└── README.md                # Project readme
```

---

## 3. Branch Strategy

### 3.1 Main Branches

| Branch | Mục Đích | Quy Tắc |
|--------|----------|---------|
| `master` | Production code | Luôn stable, chỉ merge từ develop |
| `develop` | Development code | Chứa code mới nhất, merge từ feature |

### 3.2 Feature Branches

| Branch Pattern | Mục Đích | Ví Dụ |
|----------------|----------|-------|
| `feature/*` | Tính năng mới | `feature/auth-login` |
| `bugfix/*` | Sửa lỗi | `bugfix/login-error` |
| `hotfix/*` | Sửa lỗi khẩn cấp | `hotfix/crash-fix` |

### 3.3 Branch Flow

```
feature/auth-login → develop → master
         ↓                ↓
    Development      Staging/Test
```

---

## 4. Quy Trình Làm Việc

### 4.1 Bắt Đầu Làm Việc

```bash
# 1. Pull code mới nhất
git checkout develop
git pull origin develop

# 2. Tạo feature branch mới
git checkout -b feature/auth-login

# 3. Làm việc trên feature branch
# ... code code code ...
```

### 4.2 Lưu Code

```bash
# 1. Kiểm tra status
git status

# 2. Thêm files vào staging
git add .                    # Thêm tất cả
git add lib/auth/            # Thêm thư mục cụ thể
git add lib/auth/login.dart  # Thêm file cụ thể

# 3. Commit với message rõ ràng
git commit -m "feat: implement login with Firebase Auth"
```

### 4.3 Push Code Lên Remote

```bash
# Push lần đầu
git push -u origin feature/auth-login

# Các lần push tiếp theo
git push
```

### 4.4 Tạo Pull Request

1. Truy cập GitHub
2. Click: Compare & pull request
3. Điền title và description
4. Chọn reviewers
5. Click: Create pull request

### 4.5 Merge Code

```bash
# Sau khi PR được approve
git checkout develop
git pull origin develop
git merge feature/auth-login
git push origin develop

# Xóa feature branch
git branch -d feature/auth-login
git push origin --delete feature/auth-login
```

---

## 5. Commit Message Convention

### 5.1 Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### 5.2 Types

| Type | Mô Tả | Ví Dụ |
|------|--------|-------|
| `feat` | Tính năng mới | feat: add login screen |
| `fix` | Sửa lỗi | fix: resolve login crash |
| `docs` | Tài liệu | docs: update README |
| `style` | Format code | style: format auth files |
| `refactor` | Refactor code | refactor: extract auth logic |
| `test` | Tests | test: add login unit tests |
| `chore` | Công việc khác | chore: update dependencies |

### 5.3 Ví Dụ

```bash
# Tốt
git commit -m "feat(auth): implement email login with Firebase"

# Tốt
git commit -m "fix(dashboard): resolve chart rendering issue"

# Kém
git commit -m "update code"

# Kém
git commit -m "fix bug"
```

---

## 6. Các Lệnh Git Phổ Biến

### 6.1 Xem Trạng Thái

```bash
git status              # Xem files thay đổi
git log                 # Xem lịch sử commit
git log --oneline       # Xem lịch sử rút gọn
git diff                # Xem thay đổi chi tiết
```

### 6.2 Làm Việc Với Branch

```bash
git branch                    # Xem danh sách branch
git branch feature-login      # Tạo branch mới
git checkout feature-login    # Chuyển branch
git checkout -b feature-login # Tạo và chuyển branch
git branch -d feature-login   # Xóa branch
```

### 6.3 Undo Changes

```bash
# Undo file chưa staged
git checkout -- lib/auth/login.dart

# Undo file đã staged
git reset HEAD lib/auth/login.dart

# Undo commit (giữ changes)
git reset --soft HEAD~1

# Undo commit (xóa changes)
git reset --hard HEAD~1
```

### 6.4 Stash Changes

```bash
# Stash changes hiện tại
git stash

# Xem danh sách stash
git stash list

# Áp dụng stash gần nhất
git stash pop

# Áp dụng stash nhưng giữ trong list
git stash apply
```

---

## 7. Xử Lý Conflict

### 7.1 Conflict Là Gì?
- Hai người sửa cùng 1 file
- Git không biết merge thế nào
- Cần resolve thủ công

### 7.2 Cách Resolve

```bash
# 1. Pull code mới nhất
git pull origin develop

# 2. Mở file conflict
# Conflict sẽ trông như thế này:
<<<<<<< HEAD
// Code của bạn
=======
// Code của người khác
>>>>>>> develop

# 3. Chọn code đúng và xóa markers

# 4. Add và commit
git add .
git commit -m "resolve: merge conflict in auth/login.dart"
```

---

## 8. .gitignore

### 8.1 Flutter .gitignore

```gitignore
# Dart/Pub
.packages
.pub/
build/

# Flutter
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies

# IDE
.idea/
.vscode/
*.iml

# Android
android/.gradle
android/captures/
android/gradlew
android/gradlew.bat
android/local.properties
android/**/GeneratedPluginRegistrant.java
android/key.properties

# iOS
ios/**/*.mode1v3
ios/**/*.mode2v3
ios/**/*.moved-aside
ios/**/*.pbxuser
ios/**/*.perspectivev3
ios/Pods/
ios/.symlinks/
ios/Flutter/Flutter.framework
ios/Flutter/Flutter.podspec
ios/Flutter/Generated.xcconfig
ios/Flutter/app.flx
ios/Flutter/app.zip
ios/Flutter/flutter_assets/
ios/ServiceDefinitions.json

# Firebase
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
firebase_options.dart

# macOS
**/Flutter/GeneratedPluginRegistrant.swift
**/Flutter/ephemeral/
**/Pods/
**/macos/Flutter/GeneratedPluginRegistrant.swift
**/macos/Flutter/ephemeral/

# IDE
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Environment
.env
.env.local
```

---

## 9. Best Practices

### 9.1 Commit Nhỏ
- Mỗi commit nên là 1 thay đổi logic
- Dễ review, dễ revert
- Không commit "update all files"

### 9.2 Message Rõ Ràng
- Mô tả ngắn gọn nhưng đầy đủ
- Sử dụng convention
- Viết bằng tiếng Anh

### 9.3 Pull Before Push
- Luôn pull trước khi push
- Resolve conflict sớm
- Giữ branch up-to-date

### 9.4 Review Code
- Review code trước khi merge
- Sử dụng Pull Request
- Đọc code của người khác

---

## 10. Bài Tập Thực Hành

### Bài 1: Tạo Feature Branch
```bash
git checkout develop
git checkout -b feature/my-feature
# Tạo 1 file mới
git add .
git commit -m "feat: add my feature"
git push -u origin feature/my-feature
```

### Bài 2: Resolve Conflict
1. Tạo 2 branch từ develop
2. Sửa cùng 1 file ở cả 2 branch
3. Merge branch 1 vào develop
4. Merge branch 2 vào develop (sẽ conflict)
5. Resolve conflict

### Bài 3: Sử Dụng Stash
```bash
# Đang làm việc dở
git stash
# Chuyển sang fix bug khác
git checkout -b bugfix/other-bug
# Fix xong
git checkout feature/my-feature
git stash pop
```

---

## 11. Cheat Sheet

| Lệnh | Mô Tả |
|------|--------|
| `git status` | Xem trạng thái |
| `git add .` | Thêm tất cả vào staging |
| `git commit -m "msg"` | Commit với message |
| `git push` | Push lên remote |
| `git pull` | Pull từ remote |
| `git checkout -b branch` | Tạo branch mới |
| `git merge branch` | Merge branch |
| `git stash` | Stash changes |
| `git log --oneline` | Xem lịch sử |

---

**Bài Tiếp Theo:** [Code Conventions](05-CODE-CONVENTIONS.md)
