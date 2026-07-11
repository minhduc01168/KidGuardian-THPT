# BỘ BIỂU ĐỒ KỸ THUẬT PHẦN MỀM - KIDGUARDIAN (ĐỒNG HÀNH SỐ)

Tài liệu này tổng hợp đầy đủ các **Biểu đồ kiến trúc & UML (Use Case, Activity, Sequence, Database ERD)** bằng cú pháp chuẩn **Mermaid**, phục vụ cho báo cáo kỹ thuật, đồ án tốt nghiệp và tài liệu thiết kế hệ thống KidGuardian.

---

## 📋 MỤC LỤC
1. [Biểu đồ Use Case Tổng quát (General Use Case Diagram)](#1-biểu-đồ-use-case-tổng-quát)
2. [Biểu đồ Use Case Phân rã (Decomposed Use Case Diagrams)](#2-biểu-đồ-use-case-phân-rã)
   - [2.1 Phân rã Phân hệ Phụ huynh (Parent Subsystem)](#21-phân-rã-phân-hệ-phụ-huynh-parent-subsystem)
   - [2.2 Phân rã Phân hệ Học sinh/Con (Child Subsystem)](#22-phân-rã-phân-hệ-học-sinhcon-child-subsystem)
3. [Biểu đồ Hoạt động (Activity Diagrams)](#3-biểu-đồ-hoạt-động-activity-diagrams)
   - [3.1 Luồng Giám sát & Chặn ứng dụng thông minh (Smart Lock Activity Flow)](#31-luồng-giám-sát--chặn-ứng-dụng-thông-minh-smart-lock-activity-flow)
   - [3.2 Luồng Xin thêm giờ & Duyệt tự động (Time Request & Auto-Approval Flow)](#32-luồng-xin-thêm-giờ--duyệt-tự-động-time-request--auto-approval-flow)
4. [Biểu đồ Tuần tự (Sequence Diagrams)](#4-biểu-đồ-tuần-tự-sequence-diagrams)
   - [4.1 Luồng Ghép nối Gia đình qua Mã 6 số (Family Linking Sequence)](#41-luồng-ghép-nối-gia-đình-qua-mã-6-số-family-linking-sequence)
   - [4.2 Luồng Chặn ứng dụng phần cứng & Bảo vệ Quota (Hardware Interception & Quota Protection)](#42-luồng-chặn-ứng-dụng-phần-cứng--bảo-vệ-quota-hardware-interception--quota-protection)
5. [Biểu đồ Cơ sở dữ liệu (Database Schema / Entity-Relationship Diagram ERD)](#5-biểu-đồ-cơ-sở-dữ-liệu-database-schema--entity-relationship-diagram-erd)

---

## 1. BIỂU ĐỒ USE CASE TỔNG QUÁT

Để tránh hiện tượng các đường nối bị đan chéo nhau khó nhìn, biểu đồ Use Case tổng quát được trình bày theo **2 bố cục tối ưu (Clean Layouts)**: Bố cục Phân cụm Chức năng (Functional Clusters) và Bố cục Đối xứng Trái-Phải (Zero-Crossing Symmetrical Layout).

### 1.1 Bố cục Phân cụm Chức năng (Functional Clusters Layout)
Mô hình hóa các Use Case thành 3 cụm nghiệp vụ cốt lõi (`1. Xác thực & Liên kết`, `2. Giám sát & Khóa thông minh`, `3. Báo cáo & Cảnh báo`), giúp đường nối trực quan, mạch lạc và không bị chồng chéo.

```mermaid
graph TB
    subgraph Actors [Các Tác Nhân Chính]
        Parent(["👤 Phụ huynh (Parent)"])
        System(["☁️ Firebase Cloud System"])
        Child(["👦 Học sinh/Con (Child)"])
    end

    subgraph KidGuardianSystem [HỆ THỐNG KIDGUARDIAN - CÁC CỤM CHỨC NĂNG]
        direction TB
        
        subgraph GroupAuth [Cụm 1: Quản lý Tài khoản & Liên kết]
            UC1("Đăng ký / Đăng nhập & Quản lý Profile")
            UC2("Ghép nối Gia đình qua Mã 6 số (Link Code)")
        end

        subgraph GroupLock [Cụm 2: Giám sát & Khóa Ứng Dụng]
            UC3("Thiết lập Giới hạn Thời gian & Lịch trình")
            UC4("Khóa Ứng dụng & Màn hình Smart Lock")
            UC5("Yêu cầu Xin giờ & Phê duyệt (Tự động/Thủ công)")
        end

        subgraph GroupReport [Cụm 3: Thống kê & Cảnh báo An toàn]
            UC6("Theo dõi Biểu đồ Sử dụng & Đồng bộ Log")
            UC7("Cảnh báo Vi phạm Khóa App & Từ khóa")
        end
    end

    Parent ===> GroupAuth
    Parent ===> GroupLock
    Parent ===> GroupReport

    GroupAuth <=== Child
    GroupLock <=== Child
    GroupReport <=== Child

    System -.- GroupAuth
    System -.- GroupLock
    System -.- GroupReport
```

### 1.2 Bố cục Đối xứng Trái - Phải (Zero-Crossing Symmetrical Layout)
Bố cục tách biệt Phụ huynh ở bên **Trái (Left)** và Học sinh ở bên **Phải (Right)**, kết nối ngang vào từng Use Case tương ứng ở giữa, đảm bảo **100% không có bất kỳ đường dây nào bị đan chéo (Zero Criss-Cross)**.

```mermaid
graph LR
    subgraph LeftActor [Tác Nhân Quản Lý]
        Parent(["👤 Phụ huynh (Parent)"])
    end

    subgraph CoreUseCases [CÁC USE CASE HỆ THỐNG]
        direction TB
        UC1("Quản lý Tài khoản & Xác thực")
        UC2("Ghép nối Gia đình (Link Code)")
        UC3("Thiết lập Giới hạn Thời gian App")
        UC4("Khóa Ứng dụng Thông minh (Smart Lock)")
        UC5("Yêu cầu & Phê duyệt Thêm giờ")
        UC6("Theo dõi Báo cáo Sử dụng & Log")
        UC7("Cảnh báo Vi phạm & Từ khóa nhạy cảm")
    end

    subgraph RightActor [Tác Nhân Giám Sát]
        Child(["👦 Học sinh/Con (Child)"])
    end

    subgraph TopSystem [Máy Chủ Nền Tảng]
        System(["☁️ Firebase Cloud"])
    end

    %% Kết nối ngang từ bên Trái (Parent)
    Parent ---> UC1
    Parent ---> UC2
    Parent ---> UC3
    Parent ---> UC5
    Parent ---> UC6
    Parent ---> UC7

    %% Kết nối ngang từ bên Phải (Child)
    UC1 <--- Child
    UC2 <--- Child
    UC4 <--- Child
    UC5 <--- Child
    UC6 <--- Child

    %% Kết nối từ trên xuống (System)
    System -.- UC2
    System -.- UC4
    System -.- UC6
    System -.- UC7
```

---

## 2. BIỂU ĐỒ USE CASE PHÂN RÃ

### 2.1 Phân rã Phân hệ Phụ huynh (Parent Subsystem)
Phụ huynh đóng vai trò quản trị viên gia đình, có đầy đủ quyền kiểm soát, cấu hình quy tắc và theo dõi báo cáo.

```mermaid
graph TD
    Parent(["👤 Phụ huynh (Parent)"])

    subgraph ParentSubsystem [Phân Hệ Quản Lý Phụ Huynh]
        P1("Tạo Mã Liên kết Gia đình 6 số")
        P2("Cấu hình Danh sách Ứng dụng Giám sát")
        P3("Thiết lập Hạn mức Thời gian hàng ngày")
        P4("Khóa/Mở khóa Ứng dụng từ xa tức thì")
        P5("Cấu hình Quy tắc Duyệt tự động (Auto-Approval)")
        P6("Phê duyệt/Từ chối Yêu cầu Xin thêm giờ")
        P7("Xem Biểu đồ & Thống kê Sử dụng (Ngày/Tuần)")
        P8("Nhận Cảnh báo Vi phạm & Từ khóa nhạy cảm")
    end

    Parent --> P1
    Parent --> P2
    Parent --> P3
    Parent --> P4
    Parent --> P5
    Parent --> P6
    Parent --> P7
    Parent --> P8

    P3 -. Include .-> P2
    P6 -. Extend .-> P5
```

### 2.2 Phân rã Phân hệ Học sinh/Con (Child Subsystem)
Học sinh/Con sử dụng thiết bị dưới sự giám sát ngầm của Trợ năng (Accessibility) và Dịch vụ nền (Foreground Service), đảm bảo an toàn số và tuân thủ quy tắc gia đình.

```mermaid
graph TD
    Child(["👦 Học sinh/Con (Child)"])

    subgraph ChildSubsystem [Phân Hệ Giám Sát Thiết Bị Con]
        C1("Nhập Mã Liên kết Gia đình")
        C2("Cấp Quyền Trợ năng & Dịch vụ nền")
        C3("Xem Thời gian Sử dụng của Bản thân")
        C4("Nhận Màn hình Khóa khi Vượt định mức")
        C5("Gửi Yêu cầu Xin thêm thời gian (Time Request)")
        C6("Nhận Phản hồi Phê duyệt từ Phụ huynh")
        C7("Đồng bộ Log Sử dụng tự động lên Cloud")
    end

    Child --> C1
    Child --> C2
    Child --> C3
    Child --> C4
    Child --> C5
    Child --> C6

    C4 -. Include .-> C5
    C2 -. Include .-> C7
```

---

## 3. BIỂU ĐỒ HOẠT ĐỘNG (ACTIVITY DIAGRAMS)

### 3.1 Luồng Giám sát & Chặn ứng dụng thông minh (Smart Lock Activity Flow)
Biểu đồ mô tả chi tiết logic xử lý tức thời ở mức phần cứng khi trẻ mở một ứng dụng mạng xã hội (TikTok, Facebook...), kết hợp cơ chế bộ nhớ đệm `SharedPreferences` và chống spam `Cooldown 5 phút`.

```mermaid
stateDiagram-v2
    [*] --> ChildOpensApp: Trẻ mở ứng dụng trên điện thoại
    ChildOpensApp --> AccessibilityDetects: Trợ năng (Accessibility Service) phát hiện gói ứng dụng (Package Name)

    state "Kiểm tra Cache cục bộ (SharedPreferences)" as CheckCache
    AccessibilityDetects --> CheckCache
    
    CheckCache --> CheckMonitoring: Đã có cấu hình trong Cache
    CheckCache --> FetchFromCloud: Cache trống/Hết hạn
    FetchFromCloud --> CheckMonitoring: Lưu vào Cache & Tiếp tục

    state "Kiểm tra danh sách theo dõi & Hạn mức" as CheckMonitoring
    CheckMonitoring --> AllowedState: Ứng dụng không bị khóa & Chưa hết giờ
    CheckMonitoring --> BlockAction: Ứng dụng bị khóa HOẶC Đã vượt hạn mức phút/ngày

    state "Cho phép sử dụng bình thường" as AllowedState
    AllowedState --> [*]: Bắt đầu tính giờ sử dụng (Usage Timer)

    state "Thực hiện Chặn tức thời ở mức phần cứng" as BlockAction
    BlockAction --> TriggerHome: Phát lệnh GLOBAL_ACTION_HOME đẩy app về màn hình chính
    TriggerHome --> ShowLockScreen: Hiển thị Màn hình Khóa (LockScreen) kèm thông tin Yêu cầu thêm giờ

    state "Kiểm tra Cooldown gửi Cảnh báo (FIX C4)" as CheckCooldown
    ShowLockScreen --> CheckCooldown
    
    CheckCooldown --> SkipAlert: Trong vòng 5 phút đã từng gửi Cảnh báo cho App này
    CheckCooldown --> SendFirestoreAlert: Đã qua 5 phút Cooldown
    
    SkipAlert --> [*]: Tiết kiệm Quota Firebase (Không gửi write)
    SendFirestoreAlert --> PushNotification: Ghi Alert lên Firestore (1 Write)
    PushNotification --> [*]: Phụ huynh nhận thông báo vi phạm
```

### 3.2 Luồng Xin thêm giờ & Duyệt tự động (Time Request & Auto-Approval Flow)
Biểu đồ mô tả quy trình xử lý thông minh khi trẻ gửi yêu cầu xin thêm giờ từ màn hình bị khóa.

```mermaid
stateDiagram-v2
    [*] --> SubmitRequest: Trẻ bấm "Xin thêm giờ" trên LockScreen & Nhập lý do
    SubmitRequest --> CheckAutoRule: Hệ thống kiểm tra Quy tắc Duyệt tự động (Auto-Approval Rule)

    state "Quy tắc tự động BẬT?" as CheckAutoRule
    CheckAutoRule --> RuleEnabled: Có bật quy tắc
    CheckAutoRule --> ManualPending: Không bật quy tắc / Tắt

    state "Kiểm tra Điều kiện Duyệt tự động" as RuleEnabled
    RuleEnabled --> AutoApprove: Số phút xin <= Hạn mức tối đa VÀ Số lần hôm nay < Giới hạn ngày
    RuleEnabled --> ManualPending: Vượt hạn mức tự động cho phép

    state "Duyệt tự động tức thời (Auto-Approved)" as AutoApprove
    AutoApprove --> UpdateLocalCache: Cộng thêm thời gian vào SharedPreferences Cache
    UpdateLocalCache --> UnlockDevice: Mở khóa ứng dụng ngay lập tức cho trẻ
    UnlockDevice --> LogAutoApproval: Ghi nhật ký tự động duyệt lên Firestore

    state "Chờ Phụ huynh Duyệt thủ công (Pending Request)" as ManualPending
    ManualPending --> NotifyParent: Gửi Push Notification / Realtime Stream tới Phụ huynh
    NotifyParent --> ParentDecision: Phụ huynh kiểm tra yêu cầu trên App

    state "Phụ huynh quyết định" as ParentDecision
    ParentDecision --> ParentApproved: Bấm Phê duyệt (Approved)
    ParentDecision --> ParentRejected: Bấm Từ chối (Rejected)

    ParentApproved --> UpdateFirestoreStatus: Cập nhật status = approved trên Firestore
    UpdateFirestoreStatus --> ChildStreamUpdates: Stream Firestore phát về máy Trẻ
    ChildStreamUpdates --> ChildSeesApproval: Trẻ thấy thông báo Đã duyệt trên màn hình khóa
    note right of ChildSeesApproval: LockScreen KHÔNG tự unlock ngay\nTrẻ phải mở lại app thủ công
    ParentRejected --> NotifyChildReject: Cập nhật status = rejected trên Firestore

    LogAutoApproval --> [*]
    ChildSeesApproval --> [*]
    NotifyChildReject --> [*]
```

---

## 4. BIỂU ĐỒ TUẦN TỰ (SEQUENCE DIAGRAMS)

### 4.1 Luồng Ghép nối Gia đình qua Mã 6 số (Family Linking Sequence)

```mermaid
sequenceDiagram
    autonumber
    actor Parent as Phụ huynh (Parent App)
    participant Auth as Firebase Auth
    participant DB as Cloud Firestore
    actor Child as Trẻ em (Child App)

    Note over Parent,DB: Giai đoạn 1: Phụ huynh tạo Mã liên kết
    Parent->>Auth: Đăng nhập tài khoản Parent
    Parent->>DB: Yêu cầu tạo mã liên kết (Generate Link Code)
    DB-->>Parent: Trả về Mã 6 số (Ví dụ: 839201, hạn 24h)
    Parent->>Child: Chia sẻ Mã 6 số trực tiếp cho Con

    Note over Child,DB: Giai đoạn 2: Trẻ nhập mã và xác nhận liên kết
    Child->>Auth: Đăng nhập tài khoản Child
    Child->>DB: Gửi yêu cầu xác nhận Mã 6 số (Verify Code)
    DB->>DB: Kiểm tra tính hợp lệ & Thời hạn mã
    
    alt Mã hợp lệ
        DB->>DB: Thêm childUid vào danh sách childUids của Family
        DB->>DB: Cập nhật trường familyId & linkedTo cho Child User
        DB-->>Child: Trả về trạng thái Thành công (Success)
        DB-->>Parent: Realtime Stream: Cập nhật danh sách con trên Dashboard
    else Mã hết hạn/Sai
        DB-->>Child: Trả về lỗi Mã không hợp lệ (Invalid Code)
    end
```

### 4.2 Luồng Chặn ứng dụng phần cứng & Bảo vệ Quota (Hardware Interception & Quota Protection)

```mermaid
sequenceDiagram
    autonumber
    actor Child as Trẻ em (Child)
    participant OS as Hệ điều hành Android
    participant Acc as Accessibility Service
    participant Bloc as AppMonitorBloc
    participant Cache as SharedPreferences
    participant DB as Cloud Firestore / FCM

    Child->>OS: Nhấn mở ứng dụng mạng xã hội (TikTok/FB)
    OS->>Acc: Bắn sự kiện onAccessibilityEvent (Package: com.zhiliaoapp.musically)
    Acc->>Bloc: Gửi thông báo gói ứng dụng đang hoạt động
    
    Bloc->>Cache: Kiểm tra trạng thái giám sát & số phút đã dùng
    Cache-->>Bloc: Trả về: Đã dùng 60/60 phút (Hết định mức)
    
    Note over Bloc,OS: Chặn phần cứng siêu tốc (< 50ms)
    Bloc->>Acc: Ra lệnh performGlobalAction(GLOBAL_ACTION_HOME)
    Acc->>OS: Đẩy ứng dụng TikTok xuống nền (Back to Home Screen)
    Bloc->>OS: Khởi chạy LockScreen (Màn hình khóa KidGuardian)
    
    Note over Bloc,DB: Kiểm tra chốt chặn Quota Firebase (FIX C4)
    Bloc->>Bloc: Kiểm tra _lastAlertSentMap[TikTok]
    alt Chưa gửi hoặc Đã qua 5 phút Cooldown
        Bloc->>Bloc: Cập nhật mốc thời gian _lastAlertSentMap = DateTime.now()
        Bloc->>DB: Ghi tài liệu Alert mới vào families/{familyId}/alerts
        DB->>DB: Trigger Cloud Function / FCM
        DB-->>Parent (App): Gửi Push Notification "Trẻ đang cố mở TikTok bị khóa"
    else Trong vòng 5 phút Cooldown
        Bloc->>Bloc: BỎ QUA ghi Firestore (Skip Write to save Quota)
    end
```

---

## 5. BIỂU ĐỒ CƠ SỞ DỮ LIỆU (DATABASE SCHEMA / ERD DIAGRAM)

Biểu đồ ERD thể hiện chi tiết cấu trúc các Thực thể (Entities) và mối quan hệ phân tầng bên trong **Cloud Firestore NoSQL Database** của KidGuardian.

```mermaid
erDiagram
    USER ||--o| FAMILY : "quản lý / thuộc về"
    FAMILY ||--|{ LINK_CODE : "sinh mã liên kết"
    FAMILY ||--|{ MONITORED_APP : "thiết lập giám sát cho con"
    FAMILY ||--|{ TIME_REQUEST : "nhận yêu cầu xin giờ"
    FAMILY ||--|{ ALERT : "lưu trữ cảnh báo vi phạm"
    FAMILY ||--|| AUTO_APPROVAL_RULE : "cấu hình quy tắc tự động duyệt"
    USER ||--|{ USAGE_LOG : "ghi nhận thời gian sử dụng"
    USER ||--|{ DAILY_SUMMARY : "tổng hợp báo cáo ngày"
    USER ||--|{ NOTIFICATION : "nhận thông báo cá nhân"

    USER {
        string uid PK "ID duy nhất từ Firebase Auth"
        string email "Email đăng nhập"
        string displayName "Tên hiển thị"
        string role "parent hoặc child"
        string familyId FK "ID của gia đình liên kết"
        string linkedTo "ID tài khoản đối tác liên kết"
        string fcmToken "Token FCM cho Push Notification"
        timestamp fcmTokenUpdatedAt "Thời gian cập nhật FCM token"
        timestamp createdAt "Thời gian tạo"
    }

    FAMILY {
        string familyId PK "ID duy nhất của gia đình"
        string parentUid FK "ID của phụ huynh chủ hộ"
        array childUids "Danh sách ID các con trong nhà"
        string linkingCode "Mã liên kết hiện tại"
        timestamp createdAt "Thời gian tạo gia đình"
        timestamp updatedAt "Thời gian cập nhật cuối"
    }

    LINK_CODE {
        string code PK "Mã 6 chữ số (Ví dụ: 839201)"
        string familyId FK "ID gia đình sinh mã"
        timestamp expiresAt "Thời điểm hết hạn (24h)"
    }

    MONITORED_APP {
        string appPackageName PK "Tên gói ứng dụng (packageName làm key)"
        string appName "Tên hiển thị ứng dụng"
        string iconUrl "URL icon ứng dụng (optional)"
        boolean isMonitored "Trạng thái bật/tắt theo dõi"
    }

    APP_TIME_LIMIT {
        string appPackageName PK "Tên gói ứng dụng (packageName làm key)"
        map limits "Hạn mức phân theo ngày (monday: 60, everyday: 90...)"
    }

    USAGE_LOG {
        string logId PK "ID nhật ký sử dụng"
        string childUid FK "ID của trẻ sử dụng"
        string packageName "Tên gói ứng dụng"
        timestamp startTime "Thời điểm bắt đầu dùng"
        int durationMinutes "Số phút sử dụng trong phiên"
    }

    DAILY_SUMMARY {
        string summaryId PK "ID báo cáo ngày (YYYY-MM-DD)"
        string childUid FK "ID của trẻ"
        string date "Ngày báo cáo"
        int totalMinutes "Tổng số phút đã dùng toàn app"
        map appUsage "Danh sách phút dùng theo từng app"
        boolean exceeded "Đã vượt hạn mức ngày hay chưa"
    }

    TIME_REQUEST {
        string requestId PK "ID yêu cầu xin giờ"
        string familyId FK "ID gia đình"
        string childUid FK "ID của trẻ xin giờ"
        string packageName "Gói ứng dụng cần xin"
        int requestedMinutes "Số phút muốn xin thêm"
        string status "pending, approved, hoặc rejected"
        string reason "Lý do xin giờ của trẻ"
        timestamp timestamp "Thời điểm gửi yêu cầu"
    }

    ALERT {
        string alertId PK "ID cảnh báo vi phạm"
        string familyId FK "ID gia đình nhận cảnh báo"
        string childUid FK "ID của trẻ vi phạm"
        string appPackageName "Ứng dụng vi phạm"
        string type "app_blocked hoặc sensitive_keyword"
        timestamp timestamp "Thời điểm vi phạm (đã lọc Cooldown 5p)"
    }

    AUTO_APPROVAL_RULE {
        string ruleId PK "ID cấu hình quy tắc"
        string familyId FK "ID gia đình"
        boolean isEnabled "Trạng thái bật/tắt tự động duyệt"
        int maxAutoApproveMinutes "Số phút tối đa cho phép tự duyệt"
        int dailyAutoApproveLimit "Số lần tối đa tự duyệt trong ngày"
        map appSpecificRules "Danh sách app được áp dụng tự duyệt"
    }

    NOTIFICATION {
        string notificationId PK "ID thông báo đẩy"
        string familyId FK "ID gia đình"
        string childUid FK "ID người nhận"
        string title "Tiêu đề thông báo"
        string body "Nội dung chi tiết"
        boolean isRead "Đã đọc hay chưa"
        timestamp timestamp "Thời điểm gửi"
    }
```

---
*Tài liệu được thiết kế đạt tiêu chuẩn chất lượng đồ án phần mềm kỹ thuật, thể hiện rõ tính nguyên bản và độ vững chắc của kiến trúc hệ thống KidGuardian.*
