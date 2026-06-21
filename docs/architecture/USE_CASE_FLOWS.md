# Sơ Đồ Luồng Hoạt Động Cốt Lõi (Core Use Case Flows)
*Tài liệu chuẩn hóa kiến trúc luồng xử lý của KidGuardian*

## 1. Luồng Xác Thực & Khởi Tạo (Authentication Flow)
Sử dụng mô hình State Machine để quản lý trạng thái đồng bộ giữa Firebase Auth và Firestore thông qua Splash Screen.

```mermaid
stateDiagram-v2
    direction TB
    [*] --> Splash: User mở ứng dụng
    
    state Splash {
        direction LR
        [*] --> CheckFirebase
        CheckFirebase --> CheckFirestore: Có tín hiệu Firebase Auth
        CheckFirebase --> Unauthenticated: User = Null
        CheckFirestore --> Authenticated: Tải xong User Data (Firestore)
        CheckFirestore --> Loading: Đang fetch Data
    }
    
    Splash --> RoleSelection: Unauthenticated
    RoleSelection --> Register: Chọn Role & Đăng ký
    RoleSelection --> Login: Đã có tài khoản
    
    Register --> Splash: Đăng ký thành công\n(Lợi dụng Auto-login của Firebase)
    Login --> Splash: Đăng nhập thành công
    
    Authenticated --> ParentDashboard: Role == Parent
    Authenticated --> ChildDashboard: Role == Child
```

## 2. Luồng Liên Kết Tài Khoản (Parent-Child Linking)
Tự động hóa luồng khởi tạo Family, giảm thiểu thao tác dư thừa cho phụ huynh.

```mermaid
sequenceDiagram
    autonumber
    actor Parent as Phụ Huynh
    participant App as KidGuardian App
    participant DB as Firestore
    actor Child as Trẻ Em
    
    Parent->>App: Đăng nhập lần đầu
    activate App
    App->>DB: Kiểm tra `familyId`
    activate DB
    DB-->>App: Trả về null
    App->>DB: Tự động khởi tạo Family & Sinh mã liên kết (VD: ABC123)
    DB-->>App: Khởi tạo thành công
    deactivate DB
    App-->>Parent: Hiển thị mã liên kết trên màn hình
    deactivate App
    
    Parent->>Child: Cung cấp mã liên kết cho con
    
    Child->>App: Đăng nhập (Role Child)
    activate App
    App->>DB: Nhập mã liên kết (ABC123)
    activate DB
    DB->>DB: Validate tính hợp lệ của mã
    DB->>DB: Cập nhật `familyId` vào tài khoản Child
    DB-->>App: Liên kết thành công
    deactivate DB
    App-->>Child: Chuyển vào Child Dashboard
    App-)Parent: Push Notification: "Trẻ đã liên kết thiết bị"
    deactivate App
```

## 3. Luồng Giám Sát & Khóa Ứng Dụng (Smart Lock Flow)
Cơ chế khóa theo chỉ định (Whitelist/Blacklist), không can thiệp vào các ứng dụng hệ thống cơ bản.
Phụ huynh cấu hình danh sách app cần khoá → Firestore → Máy trẻ real-time sync → Accessibility Service phát hiện vi phạm → LockScreen.

```mermaid
flowchart TD
    subgraph PARENT["📱 Máy Phụ Huynh"]
        P1(["Phụ huynh mở\nDashboard"])
        P2["Ấn 'Khoá ứng dụng'"]
        P3{"Đã có\nfamilyId?"}
        P3A["Hiện hộp thoại\n'Hãy thêm tài khoản con'"]
        P4["Mở SmartLockSettingsScreen\n+ BlocProvider&lt;SmartLockBloc&gt;"]
        P5{"Bật/Tắt\nSmart Lock\ntoàn bộ?"}
        P6["Chọn App cần khoá\nTừ danh sách mặc định:\n• TikTok • Facebook • YouTube\n• Instagram • Zalo • Roblox\n• Free Fire + thêm thủ công"]
        P7["Thiết lập giới hạn giờ\ncho từng App theo ngày\n(Mon–Sun, HH:mm–HH:mm)"]
        P8["Tạo Lịch khoá (Schedule)\nTheo khung giờ cố định\nVD: 22:00–06:00 hàng ngày"]
        P9["Lưu cấu hình"]
        P10["✅ Toast: Lưu thành công"]
    end

    subgraph FIRESTORE["☁️ Firebase Firestore"]
        FS1[("families/{id}/children/{childId}\n/settings/smartLock\n{isEnabled, defaultTimeLimitMinutes}")]
        FS2[("families/{id}/children/{childId}\n/monitoredApps\n{packageName, isMonitored}")]
        FS3[("families/{id}/children/{childId}\n/schedules\n{startTime, endTime, days[]}")]
        FS4[("families/{id}/alerts\n{type, appName, timestamp}")]
    end

    subgraph CHILD["📱 Máy Trẻ Em (Android)"]
        C1(["AppMonitorBloc\nchạy nền liên tục"])
        C2["AccessibilityService\nPoll foreground app\nmỗi 1 giây"]
        C3{"App hiện tại\ncó trong\ndanh sách khoá?"}
        C4{"Smart Lock\nđang BẬT\n(isEnabled)?"}
        C5{"Có Schedule\nđang active\nở thời điểm này?"}
        C6{"Đã hết\nTime Limit\nhôm nay?"}
        C7["🔒 Hiển thị LockScreen\n(Overlay toàn màn hình)"]
        C8["🟢 Cho phép\ndùng app\nbình thường"]
        C9["Ghi Alert vào\nFirestore\n{type: 'blocked'}"]
        C10["Gửi Push Notification\ncho phụ huynh\n'Con đang cố mở app bị khoá'"]
        C11["Trẻ chọn\n'Xin thêm giờ'"]
        C12["→ Time Request Flow"]
    end

    P1 --> P2 --> P3
    P3 -->|"Chưa có familyId"| P3A
    P3 -->|"Có familyId"| P4
    P4 --> P5
    P5 -->|"Tắt Smart Lock"| P9
    P5 -->|"Bật Smart Lock"| P6
    P6 --> P7 --> P8 --> P9
    P9 -->|"Lưu trạng thái bật/tắt"| FS1
    P9 -->|"Lưu danh sách app khoá"| FS2
    P9 -->|"Lưu lịch khoá"| FS3
    P9 --> P10

    FS1 & FS2 & FS3 -->|"Firestore Real-time\nListener sync về máy trẻ\n(offline cache enabled)"| C1
    C1 --> C2 --> C3
    C3 -->|"Không có trong danh sách"| C8
    C3 -->|"Có trong danh sách"| C4
    C4 -->|"Smart Lock TẮT"| C8
    C4 -->|"Smart Lock BẬT"| C5
    C5 -->|"Không có Schedule\nnào active"| C6
    C5 -->|"Có Schedule active\n(đang trong giờ cấm)"| C7
    C6 -->|"Còn trong giới hạn"| C8
    C6 -->|"Đã hết giới hạn giờ"| C7
    C7 --> C9 --> FS4
    C9 --> C10
    C7 --> C11 --> C12

    style PARENT fill:#e3f2fd,stroke:#1565c0,color:#000
    style FIRESTORE fill:#fff8e1,stroke:#f57f17,color:#000
    style CHILD fill:#e8f5e9,stroke:#2e7d32,color:#000
    style C7 fill:#ffcdd2,stroke:#c62828,color:#000
    style C8 fill:#c8e6c9,stroke:#2e7d32,color:#000
    style P3A fill:#fff3e0,stroke:#e65100,color:#000
```

### Bảng Tham Chiếu Kỹ Thuật

| Thành phần | Mô tả chi tiết |
|---|---|
| **Trigger phát hiện** | `AccessibilityService` Android poll foreground app mỗi 1 giây qua `MethodChannel` |
| **Danh sách mặc định** | 7 app hardcode (TikTok, Facebook, YouTube, Instagram, Zalo, Roblox, Free Fire) |
| **Thêm app tuỳ chỉnh** | Nhập thủ công Package Name — **(UX cần cải thiện ở Sprint 2)** |
| **Offline safety** | Hiện chưa cache offline — nếu máy trẻ offline, danh sách khoá không áp dụng được **(fix ở Sprint 2)** |
| **Timeout Firestore** | Mọi lệnh ghi Firestore có `.timeout(3s)` → không bao giờ treo UI |
| **Lỗi đã fix** | `BlocProvider<SmartLockBloc>` đã được bổ sung tại 3 điểm navigate trong `parent_dashboard.dart` |



## 4. Luồng Xin Thêm Giờ (Time Request Flow)
Cơ chế tương tác 2 chiều (Two-way Interaction) thời gian thực thông qua FCM.

```mermaid
sequenceDiagram
    autonumber
    actor Child as Trẻ Em
    participant App as KidGuardian App
    participant DB as Firestore
    participant FCM as Firebase Cloud Messaging
    actor Parent as Phụ Huynh
    
    Child->>App: Tạo Request xin thêm thời gian (vd: 30p)
    activate App
    App->>DB: Lưu Request vào Firestore
    activate DB
    DB-)FCM: Trigger Push Notification
    deactivate DB
    deactivate App
    
    FCM-)Parent: Nhận thông báo: "Con xin thêm thời gian"
    
    Parent->>App: Mở app xem chi tiết yêu cầu
    activate App
    alt Phụ Huynh Đồng Ý
        App->>DB: Cập nhật status = "Approved"
        activate DB
        DB->>DB: Cộng thêm 30 phút vào Time Limit
        DB-)FCM: Trigger Push Notification
        deactivate DB
        FCM-)Child: Nhận thông báo: "Yêu cầu đã được phê duyệt"
        App-->>Child: Gỡ màn hình khóa, tiếp tục sử dụng app MXH
    else Phụ Huynh Từ Chối
        App->>DB: Cập nhật status = "Rejected"
        activate DB
        DB-)FCM: Trigger Push Notification
        deactivate DB
        FCM-)Child: Nhận thông báo: "Yêu cầu bị từ chối"
    end
    deactivate App
```

## 5. Luồng Cảnh Báo An Toàn (Safety Alerts & Keyword Filtering)
Giới hạn quyền Accessibility Service để tối ưu pin và bảo vệ quyền riêng tư.

```mermaid
sequenceDiagram
    autonumber
    participant Monitor as Accessibility Service
    participant Regex as Keyword Filter
    participant DB as Firestore
    actor Parent as Phụ Huynh
    
    Monitor->>Monitor: Lắng nghe sự kiện AccessibilityEvent
    opt Bộ Lọc Sự Kiện (Event Filter)
        Monitor->>Monitor: Chỉ quét các text nhập liệu từ Trình duyệt / Search bar
    end
    Monitor->>Regex: Kiểm tra text với danh sách từ khóa tiêu cực
    
    alt Phát hiện từ khóa nguy hiểm (vd: tự tử, bạo lực)
        Regex->>DB: Ghi log Cảnh báo khẩn cấp
        activate DB
        DB-)Parent: Push Notification: Báo động đỏ
        deactivate DB
        Parent->>DB: Phụ huynh truy cập xem chi tiết bối cảnh
    end
```

## 6. Luồng Thống Kê & Báo Cáo (Dashboard & Reporting)

```mermaid
stateDiagram-v2
    direction LR
    [*] --> ParentDashboard
    
    state ParentDashboard {
        [*] --> Overview
        Overview --> DailySummary: Xem sử dụng trong ngày
        Overview --> WeeklyReport: Xem báo cáo tuần
        Overview --> MonthlyReport: Xem báo cáo tháng
        
        DailySummary --> AppList: Xem chi tiết từng app
        WeeklyReport --> TrendChart: Xem biểu đồ xu hướng tuần
        MonthlyReport --> TrendChart: Xem biểu đồ xu hướng tháng
    }
```
