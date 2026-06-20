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

```mermaid
stateDiagram-v2
    direction TB
    [*] --> MonitorService: Background Service chạy ngầm
    
    state MonitorService {
        [*] --> CheckUsage
        CheckUsage --> Blocked: Hết giờ / Nằm trong khung giờ cấm
        CheckUsage --> Tracking: Còn thời gian sử dụng
    }
    
    Blocked --> LockScreen: Hiển thị Overlay đè lên App MXH
    
    state LockScreen {
        [*] --> ShowWarning
        ShowWarning --> ExitApp: Trẻ bấm phím Home/Back
        ShowWarning --> RequestTime: Trẻ chọn "Xin thêm giờ"
    }
    
    ExitApp --> [*]: Thoát về màn hình chính hệ điều hành
```

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
