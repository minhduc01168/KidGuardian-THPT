# Product Requirements Document (PRD)
# KidGuardian - Đồng Hành Số

**Version:** 1.0  
**Date:** 2026-05-12  
**Status:** Draft  

---

## 1. Tổng Quan Sản Phẩm

### 1.1 Tên Sản Phẩm
**KidGuardian - Đồng Hành Số**

### 1.2 Mục Tiêu
Tạo ra một ứng dụng di động giúp phụ huynh và trẻ em cùng quản lý thói quen sử dụng mạng xã hội thông qua sự thỏa thuận và giám sát minh bạch.

### 1.3 Tầm Nhìn
Trở thành công cụ hỗ trợ phụ huynh Việt Nam trong việc bảo vệ con em khỏi tác động tiêu cực của mạng xã hội, đồng thời tôn trọng quyền riêng tư và sự tự chủ của trẻ.

### 1.4 Đối Tượng Người Dụng
- **Primary:** Phụ huynh có con từ 11-18 tuổi
- **Secondary:** Trẻ em từ 11-18 tuổi

---

## 2. Persona & User Journey

### 2.1 Phụ Huynh (Parent Persona)

**Tên:** Anh Minh, 42 tuổi  
**Vấn đề:** Lo lắng con dành quá nhiều thời gian trên TikTok, Facebook  
**Mục tiêu:** Giám sát và giới hạn thời gian sử dụng mạng xã hội của con  

**User Journey:**
```
Onboarding → Tạo tài khoản → Tạo profile con → Thiết lập quy tắc → Dashboard giám sát → Phê duyệt yêu cầu
```

### 2.2 Trẻ Em (Child Persona)

**Tên:** Bé Linh, 14 tuổi  
**Vấn đề:** Không muốn bị giám sát quá mức, muốn được tự chủ  
**Mục tiêu:** Sử dụng mạng xã hội trong giới hạn cho phép  

**User Journey:**
```
Onboarding → Nhập mã liên kết → Xem quy tắc → Yêu cầu thêm thời gian → Xem thời gian còn lại
```

---

## 3. Chức Năng Chi Tiết (Feature Specification)

### 3.1 Epic 1: Authentication & Profile Management

| ID | Feature | Mô tả | Priority |
|----|---------|-------|----------|
| E1.1 | Parent Registration | Đăng ký bằng email/password | P0 |
| E1.2 | Child Account Creation | Phụ huynh tạo tài khoản cho con | P0 |
| E1.3 | Parent-Child Linking | Liên kết tài khoản parent-child | P0 |
| E1.4 | Role-based Login | Đăng nhập phân quyền Parent/Child | P0 |
| E1.5 | Profile Management | Quản lý thông tin profile | P1 |

### 3.2 Epic 2: Dashboard & Monitoring

| ID | Feature | Mô tả | Priority |
|----|---------|-------|----------|
| E2.1 | Usage Dashboard | Biểu đồ thời gian sử dụng theo app | P0 |
| E2.2 | App List | Danh sách app mạng xã hội đang theo dõi | P0 |
| E2.3 | Daily Summary | Tổng hợp sử dụng theo ngày | P0 |
| E2.4 | Weekly Report | Báo cáo hàng tuần cho phụ huynh | P1 |

### 3.3 Epic 3: Smart Lock (Android Priority)

| ID | Feature | Mô tả | Priority |
|----|---------|-------|----------|
| E3.1 | Time Limit Setting | Đặt giới hạn thời gian theo app | P0 |
| E3.2 | App Blocking | Khóa app khi hết thời gian (Android) | P0 |
| E3.3 | Lock Screen | Màn hình chặn hiển thị lý do | P0 |
| E3.4 | Schedule Setting | Đặt lịch khóa (giờ học, giờ ngủ) | P1 |
| E3.5 | Emergency Access | Truy cập app khẩn cấp (gọi điện, tin nhắn) | P0 |

### 3.4 Epic 4: Safety Alerts

| ID | Feature | Mô tả | Priority |
|----|---------|-------|----------|
| E4.1 | Keyword Filtering | Lọc từ khóa tiêu cực (Regex) | P0 |
| E4.2 | Alert Notification | Thông báo cho phụ huynh khi phát hiện | P0 |
| E4.3 | Alert History | Lịch sử cảnh báo | P1 |
| E4.4 | Keyword Management | Quản lý danh sách từ khóa | P1 |

### 3.5 Epic 5: Two-Way Interaction

| ID | Feature | Mô tả | Priority |
|----|---------|-------|----------|
| E5.1 | Time Request | Trẻ gửi yêu cầu xin thêm giờ | P0 |
| E5.2 | Parent Approval | Phụ huynh phê duyệt/từ chối | P0 |
| E5.3 | Request History | Lịch sử yêu cầu | P1 |
| E5.4 | Push Notification | Thông báo đẩy khi có yêu cầu | P0 |

### 3.6 Epic 6: Notifications

| ID | Feature | Mô tả | Priority |
|----|---------|-------|----------|
| E6.1 | FCM Integration | Firebase Cloud Messaging | P0 |
| E6.2 | Notification Settings | Cấu hình thông báo | P1 |
| E6.3 | Notification History | Lịch sử thông báo | P2 |

---

## 4. Non-Functional Requirements

### 4.1 Performance
- App khởi động trong < 3 giây
- Dashboard load trong < 2 giây
- Push notification delivery < 5 giây

### 4.2 Security
- Firebase Authentication
- Data encryption at rest và in transit
- Secure storage cho sensitive data

### 4.3 Scalability
- Hỗ trợ 10,000 users (Firebase Free Tier)
- Database design tối ưu cho read-heavy workload

### 4.4 Accessibility
- Font size tối thiểu 14sp
- Touch target tối thiểu 48dp
- Hỗ trợ screen reader
- Color contrast đạt WCAG AA

### 4.5 Platform Support
- **Android:** API level 21+ (Android 5.0+)
- **iOS:** Phase 2 (sau 3-4 tháng)

---

## 5. MVP Scope

### 5.1 Trong MVP (Phase 1 - Android)

| Feature | Status |
|---------|--------|
| Parent/Child Authentication | ✅ |
| Parent-Child Linking | ✅ |
| Usage Dashboard | ✅ |
| Smart Lock (Android) | ✅ |
| Safety Alerts (Keyword Filter) | ✅ |
| Time Request/Approval | ✅ |
| Push Notifications | ✅ |

### 5.2 Ngoài MVP

| Feature | Phase |
|---------|-------|
| iOS App | Phase 2 |
| Screen Time Integration (iOS) | Phase 2 |
| Advanced Analytics | Phase 3 |
| AI Content Analysis | Phase 3 |
| Multi-language Support | Phase 3 |

---

## 6. Success Metrics

### 6.1 Định Lượng

| Metric | Target |
|--------|--------|
| User Activation Rate | > 60% sau 7 ngày |
| Daily Active Users | > 40% sau 30 ngày |
| Time Request Usage | > 2 requests/ngày/child |
| Social Media Time Reduction | 20-30% |

### 6.2 Định Tính

| Metric | Target |
|--------|--------|
| Parent Satisfaction | Cảm thấy yên tâm hơn |
| Child Experience | Không cảm thấy bị giám sát quá mức |
| App Store Rating | > 4.0 stars |

---

## 7. Ràng Buộc Kỹ Thuật

### 7.1 Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter 3.x |
| State Management | BLoC/Cubit |
| Backend | Firebase (Free Tier) |
| Database | Cloud Firestore |
| Authentication | Firebase Auth |
| Push Notifications | Firebase Cloud Messaging |
| Local Storage | Hive |

### 7.2 Platform-Specific Requirements

**Android:**
- Accessibility Service cho app monitoring
- UsageStats API cho usage tracking
- Device Admin API cho advanced features

---

## 8. Compliance Requirements

### 8.1 Legal Requirements

| Luật | Yêu cầu |
|------|---------|
| COPPA | Parental consent cho trẻ < 13 tuổi |
| GDPR-K | Data minimization, right to erasure |
| Luật An toàn thông tin mạng VN | Xác minh độ tuổi, parental consent |
| Luật Bảo vệ dữ liệu cá nhân VN | Data storage trong nước |

### 8.2 App Store Requirements

**Google Play Store:**
- Families Policy compliance
- Data safety section rõ ràng
- No targeted ads cho trẻ em

---

## 9. Timeline & Milestones

### 9.1 Phase 1: Android MVP (Tháng 1-2)

| Milestone | Timeline | Deliverable |
|-----------|----------|-------------|
| M1: Project Setup | Tuần 1 | Flutter project, Firebase setup |
| M2: Authentication | Tuần 2 | Login, registration, linking |
| M3: Dashboard | Tuần 3-4 | Usage monitoring, charts |
| M4: Smart Lock | Tuần 5-6 | App blocking, time limits |
| M5: Alerts & Interaction | Tuần 7 | Keyword filter, request flow |
| M6: Polish & Test | Tuần 8 | Bug fixes, beta testing |

### 9.2 Phase 2: iOS + Enhancement (Tháng 3-4)

| Milestone | Timeline | Deliverable |
|-----------|----------|-------------|
| M7: iOS App | Tuần 9-12 | iOS version with Screen Time |
| M8: Enhanced Features | Tuần 13-16 | Advanced analytics, improvements |

---

## 10. Risk Assessment

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| iOS Smart Lock limitation | High | High | Use Screen Time API + education |
| Android Accessibility rejection | High | Medium | Follow Google Play policies |
| Firebase Free Tier limits | Medium | Medium | Implement caching, optimize queries |
| Compliance issues | High | Low | Legal review, privacy by design |
| 2-month timeline tight | Medium | High | Strict scope control, MVP focus |

---

## 11. Appendix

### 11.1 Glossary

| Term | Definition |
|------|------------|
| Smart Lock | Tính năng khóa ứng dụng khi hết thời gian cho phép |
| Parent-Child Linking | Cơ chế liên kết tài khoản phụ huynh và trẻ em |
| Safety Alerts | Cảnh báo khi phát hiện từ khóa tiêu cực |

### 11.2 References

- Firebase Documentation: https://firebase.google.com/docs
- Flutter Documentation: https://docs.flutter.dev
- Google Play Families Policy: https://play.google.com/about/families/
- COPPA Compliance: https://www.ftc.gov/legal-library/browse/rules/childrens-online-privacy-protection-rule-coppa

---

**Document Owner:** Product Team  
**Last Updated:** 2026-05-12  
**Next Review:** 2026-05-19
