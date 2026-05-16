# Sprint Plan
# KidGuardian - Đồng Hành Số

**Version:** 1.0  
**Date:** 2026-05-12  
**Status:** In Progress  
**Last Updated:** 2026-05-16  

---

## Project Overview

**Project:** KidGuardian - Đồng Hành Số  
**Platform:** Android (Phase 1), iOS (Phase 2)  
**Timeline:** 8 Sprints (2 months)  
**Sprint Duration:** 1 week  
**Team:** AI-assisted development  

---

## Sprint Summary

| Sprint | Dates | Focus | Stories | Points |
|--------|-------|-------|---------|--------|
| Sprint 1 | Week 1 | Project Setup & Parent Auth | E1.1, E1.2, E1.3 | 10 |
| Sprint 2 | Week 2 | Child Auth & Basic Features | E1.4, E1.5, E1.6, E1.7 | 9 |
| Sprint 3 | Week 3 | Parent Dashboard | E2.1, E2.2 | 10 |
| Sprint 4 | Week 4 | Child Dashboard & Monitoring | E2.3, E2.4, E2.5 | 9 |
| Sprint 5 | Week 5 | Smart Lock Core | E3.1, E3.2, E3.6 | 16 |
| Sprint 6 | Week 6 | Smart Lock Advanced | E3.3, E3.4, E3.5, E3.7, E3.8 | 21 |
| Sprint 7 | Week 7 | Alerts & Interaction | E4.1-E4.5, E5.1-E5.3 | 32 |
| Sprint 8 | Week 8 | Polish & Extras | E1.8, E2.6, E5.4-E5.6, E6.1-E6.4, E7.1-E7.3 | 43 |

---

## Sprint 1: Project Setup & Parent Authentication

**Duration:** Week 1  
**Goal:** Set up Flutter project, Firebase, and implement parent registration/login

### Sprint Backlog

| Story | Task | Assignee | Status |
|-------|------|----------|--------|
| | **Project Setup** | | |
| | Create Flutter project | AI | ⬜ |
| | Configure Firebase (Android) | AI | ⬜ |
| | Setup folder structure | AI | ⬜ |
| | Configure dependencies | AI | ⬜ |
| E1.1 | **Parent Registration** | | |
| | Create registration UI | AI | ⬜ |
| | Implement Firebase Auth | AI | ⬜ |
| | Create user model | AI | ⬜ |
| | Implement validation | AI | ⬜ |
| E1.2 | **Parent Login** | | |
| | Create login UI | AI | ⬜ |
| | Implement login logic | AI | ⬜ |
| | Handle errors | AI | ⬜ |
| E1.3 | **Create Child Account** | | |
| | Create child setup UI | AI | ⬜ |
| | Implement linking code generation | AI | ⬜ |
| | Create child account in Firestore | AI | ⬜ |

### Technical Tasks

- [ ] Initialize Flutter project
- [ ] Add Firebase dependencies
- [ ] Configure Firebase for Android
- [ ] Setup BLoC architecture
- [ ] Create base models
- [ ] Implement Firebase Auth service
- [ ] Create navigation structure

### Definition of Done

- [ ] Flutter project builds successfully
- [ ] Firebase connected and working
- [ ] Parent can register with email/password
- [ ] Parent can login
- [ ] Child account can be created
- [ ] Unit tests pass

### Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Firebase setup issues | Follow official documentation, use FlutterFire CLI |
| Authentication errors | Implement proper error handling |

---

## Sprint 2: Child Authentication & Basic Features

**Duration:** Week 2  
**Goal:** Implement child login, linking, and basic app structure

### Sprint Backlog

| Story | Task | Assignee | Status |
|-------|------|----------|--------|
| E1.4 | **Child Account Setup** | | |
| | Create linking code input UI | AI | ⬜ |
| | Implement code validation | AI | ⬜ |
| | Link child to family | AI | ⬜ |
| E1.5 | **Child Login** | | |
| | Implement child login flow | AI | ⬜ |
| | Create child home screen | AI | ⬜ |
| E1.6 | **Logout** | | |
| | Implement logout functionality | AI | ⬜ |
| | Clear local data on logout | AI | ⬜ |
| E1.7 | **Password Reset** | | |
| | Add forgot password flow | AI | ⬜ |
| | Implement Firebase password reset | AI | ⬜ |

### Technical Tasks

- [ ] Implement child authentication flow
- [ ] Create role-based navigation
- [ ] Setup local storage (Hive)
- [ ] Implement linking code system
- [ ] Create basic UI components
- [ ] Add form validation

### Definition of Done

- [ ] Child can setup account with linking code
- [ ] Child can login
- [ ] Logout works correctly
- [ ] Password reset works
- [ ] Role-based navigation works

---

## Sprint 3: Parent Dashboard

**Duration:** Week 3  
**Goal:** Implement parent dashboard with usage charts

### Sprint Backlog

| Story | Task | Assignee | Status |
|-------|------|----------|--------|
| E2.1 | **Parent Dashboard Overview** | | |
| | Create dashboard UI | AI | ⬜ |
| | Implement usage data fetching | AI | ⬜ |
| | Create summary cards | AI | ⬜ |
| | Add real-time updates | AI | ⬜ |
| E2.2 | **Usage Chart** | | |
| | Integrate fl_chart package | AI | ⬜ |
| | Create bar chart widget | AI | ⬜ |
| | Create line chart widget | AI | ⬜ |
| | Implement date range selector | AI | ⬜ |

### Technical Tasks

- [ ] Setup Firestore queries
- [ ] Implement usage tracking service
- [ ] Create chart widgets
- [ ] Add data aggregation logic
- [ ] Implement caching strategy

### Definition of Done

- [ ] Dashboard shows usage summary
- [ ] Charts display correctly
- [ ] Data updates in real-time
- [ ] Performance is acceptable

---

## Sprint 4: Child Dashboard & Monitoring

**Duration:** Week 4  
**Goal:** Implement child dashboard and app monitoring foundation

### Sprint Backlog

| Story | Task | Assignee | Status |
|-------|------|----------|--------|
| E2.3 | **App Usage List** | | |
| | Create app list UI | AI | ⬜ |
| | Implement app info fetching | AI | ⬜ |
| | Add sorting and filtering | AI | ⬜ |
| E2.4 | **Child Dashboard** | | |
| | Create child dashboard UI | AI | ⬜ |
| | Show remaining time | AI | ⬜ |
| | Show usage breakdown | AI | ⬜ |
| E2.5 | **Daily Summary** | | |
| | Create summary generation logic | AI | ⬜ |
| | Implement notification scheduling | AI | ⬜ |

### Technical Tasks

- [ ] Implement installed apps detection
- [ ] Create usage statistics service
- [ ] Build child-specific UI
- [ ] Implement daily summary logic
- [ ] Add notification scheduling

### Definition of Done

- [ ] App list shows installed social media apps
- [ ] Child dashboard shows usage data
- [ ] Daily summary is generated
- [ ] UI is child-friendly

---

## Sprint 5: Smart Lock Core

**Duration:** Week 5  
**Goal:** Implement core Smart Lock functionality for Android

### Sprint Backlog

| Story | Task | Assignee | Status |
|-------|------|----------|--------|
| E3.1 | **Set Time Limit** ✅ | | |
| | Create time limit UI | AI | ✅ |
| | Implement time picker | AI | ✅ |
| | Save limits to Firestore | AI | ✅ |
| E3.2 | **App Blocking** ✅ | | |
| | Implement Accessibility Service | AI | ✅ |
| | Create app monitoring logic | AI | ✅ |
| | Implement blocking mechanism | AI | ✅ |
| | Add overlay window | AI | ✅ |
| E3.6 | **Blocked Apps Management** ✅ | | |
| | Create app selector UI | AI | ✅ |
| | Implement app toggling | AI | ✅ |

### Technical Tasks

- [x] Setup Android Accessibility Service
- [x] Implement UsageStats API integration
- [x] Create Flutter platform channels
- [x] Implement overlay window
- [x] Create time tracking service
- [x] Add background service

### Definition of Done

- [x] Time limits can be set
- [x] Apps are blocked when limit reached
- [x] Lock screen appears
- [x] Blocking works reliably

### Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Accessibility Service rejection | Follow Google Play policies strictly |
| Battery drain | Optimize background service |
| Bypass attempts | Multiple detection methods |

---

## Sprint 6: Smart Lock Advanced

**Duration:** Week 6  
**Goal:** Complete Smart Lock features and add schedule support

### Sprint Backlog

| Story | Task | Assignee | Status |
|-------|------|----------|--------|
| E3.3 | **Lock Screen Display** | | |
| | Design lock screen UI | AI | ⬜ |
| | Show blocking reason | AI | ⬜ |
| | Add request button | AI | ⬜ |
| | Add emergency button | AI | ⬜ |
| E3.4 | **Schedule Setting** | | |
| | Create schedule UI | AI | ⬜ |
| | Implement schedule logic | AI | ⬜ |
| | Add recurring schedules | AI | ⬜ |
| E3.5 | **Emergency Access** | | |
| | Implement emergency mode | AI | ⬜ |
| | Add call/SMS functionality | AI | ⬜ |
| | Add time limit for emergency | AI | ⬜ |
| E3.7 | **Usage Statistics** | | |
| | Create detailed stats UI | AI | ⬜ |
| | Implement data aggregation | AI | ⬜ |
| E3.8 | **Smart Lock Settings** | | |
| | Create settings UI | AI | ⬜ |
| | Implement configuration logic | AI | ⬜ |

### Technical Tasks

- [ ] Implement schedule management
- [ ] Add emergency access features
- [ ] Create detailed statistics
- [ ] Add settings management
- [ ] Optimize performance

### Definition of Done

- [ ] Lock screen displays correctly
- [ ] Schedules work as expected
- [ ] Emergency access works
- [ ] Statistics are accurate
- [ ] Settings are configurable

---

## Sprint 7: Alerts & Interaction

**Duration:** Week 7  
**Goal:** Implement safety alerts and two-way interaction

### Sprint Backlog

| Story | Task | Assignee | Status |
|-------|------|----------|--------|
| E4.1 | **Keyword Detection** | | |
| | Create keyword list | AI | ⬜ |
| | Implement text filtering | AI | ⬜ |
| | Add detection logic | AI | ⬜ |
| E4.2 | **Alert Notification** | | |
| | Implement push notifications | AI | ⬜ |
| | Create alert notification | AI | ⬜ |
| E4.3 | **Alert History** | | |
| | Create alert list UI | AI | ⬜ |
| | Implement filtering | AI | ⬜ |
| E4.4 | **Keyword Management** | | |
| | Create keyword management UI | AI | ⬜ |
| | Implement CRUD operations | AI | ⬜ |
| E4.5 | **Alert Review** | | |
| | Create review UI | AI | ⬜ |
| | Implement status updates | AI | ⬜ |
| E5.1 | **Request More Time** | | |
| | Create request UI | AI | ⬜ |
| | Implement request submission | AI | ⬜ |
| E5.2 | **Parent Approval** | | |
| | Create approval UI | AI | ⬜ |
| | Implement approval logic | AI | ⬜ |
| E5.3 | **Request Status** | | |
| | Create status tracking UI | AI | ⬜ |
| | Implement real-time updates | AI | ⬜ |

### Technical Tasks

- [ ] Implement keyword filtering algorithm
- [ ] Setup FCM notifications
- [ ] Create alert management system
- [ ] Implement request/approval flow
- [ ] Add real-time status updates

### Definition of Done

- [ ] Keywords are detected
- [ ] Alerts are sent to parents
- [ ] Alert history is viewable
- [ ] Requests can be sent and approved
- [ ] Status updates in real-time

---

## Sprint 8: Polish & Extras

**Duration:** Week 8  
**Goal:** Complete remaining features and polish the app

### Sprint Backlog

| Story | Task | Assignee | Status |
|-------|------|----------|--------|
| E1.8 | **Profile Management** | | |
| | Create profile UI | AI | ⬜ |
| | Implement edit functionality | AI | ⬜ |
| E2.6 | **Weekly Report** | | |
| | Create report generation | AI | ⬜ |
| | Implement report UI | AI | ⬜ |
| E5.4 | **Request History** | | |
| | Create history UI | AI | ⬜ |
| | Implement filtering | AI | ⬜ |
| E5.5 | **Quick Approval** | | |
| | Implement notification actions | AI | ⬜ |
| | Add quick approve/reject | AI | ⬜ |
| E5.6 | **Auto-Approval Rules** | | |
| | Create rules UI | AI | ⬜ |
| | Implement auto-approval logic | AI | ⬜ |
| E6.1 | **Push Notifications Setup** | | |
| | Finalize FCM integration | AI | ⬜ |
| | Test notification delivery | AI | ⬜ |
| E6.2 | **Notification Preferences** | | |
| | Create preferences UI | AI | ⬜ |
| | Implement settings logic | AI | ⬜ |
| E6.3 | **Notification History** | | |
| | Create history UI | AI | ⬜ |
| | Implement storage | AI | ⬜ |
| E6.4 | **In-App Notifications** | | |
| | Create notification center | AI | ⬜ |
| | Add badge count | AI | ⬜ |
| E7.1 | **App Settings** | | |
| | Create settings UI | AI | ⬜ |
| | Implement theme switching | AI | ⬜ |
| E7.2 | **Family Management** | | |
| | Create family management UI | AI | ⬜ |
| | Implement add/remove child | AI | ⬜ |
| E7.3 | **Help & Support** | | |
| | Create FAQ section | AI | ⬜ |
| | Add support contact | AI | ⬜ |

### Technical Tasks

- [ ] Polish UI/UX
- [ ] Optimize performance
- [ ] Fix bugs
- [ ] Add error handling
- [ ] Write documentation
- [ ] Prepare for release

### Definition of Done

- [ ] All features implemented
- [ ] No critical bugs
- [ ] Performance acceptable
- [ ] UI polished
- [ ] Ready for beta testing

---

## Risk Management

### Technical Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Accessibility Service issues | High | Medium | Follow Google Play policies, test thoroughly |
| Firebase Free Tier limits | Medium | Medium | Implement caching, optimize queries |
| Performance issues | Medium | Low | Profile and optimize critical paths |
| App Store rejection | High | Low | Follow guidelines, test on multiple devices |

### Schedule Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Feature creep | High | Medium | Strict scope control, MVP focus |
| Technical debt | Medium | Medium | Regular refactoring, code reviews |
| Integration issues | Medium | Low | Early integration testing |

---

## Dependencies

### External Dependencies

| Dependency | Impact | Mitigation |
|------------|--------|------------|
| Firebase | High | Have backup plan for critical features |
| Flutter packages | Medium | Use well-maintained packages |
| Android APIs | High | Test on multiple Android versions |

### Internal Dependencies

| Dependency | Dependent On | Impact |
|------------|--------------|--------|
| Authentication | Firebase Auth | High |
| Smart Lock | Accessibility Service | High |
| Push Notifications | FCM | Medium |

---

## Communication Plan

### Daily Standup
- **Time:** Start of each work session
- **Format:** Brief status update
- **Focus:** Blockers and progress

### Sprint Review
- **Time:** End of each sprint
- **Format:** Demo and feedback
- **Focus:** Completed features and next sprint planning

### Sprint Retrospective
- **Time:** After sprint review
- **Format:** What went well, what to improve
- **Focus:** Process improvements

---

## Tools & Resources

### Development Tools

| Tool | Purpose |
|------|---------|
| Flutter SDK | App development |
| Android Studio | Android development |
| Firebase Console | Backend management |
| Git | Version control |

### Testing Tools

| Tool | Purpose |
|------|---------|
| flutter_test | Unit testing |
| integration_test | Integration testing |
| Firebase Test Lab | Device testing |

### Documentation Tools

| Tool | Purpose |
|------|---------|
| Markdown | Documentation |
| Figma | UI/UX design |

---

## Success Criteria

### Sprint Success

- [ ] All planned stories completed
- [ ] No critical bugs
- [ ] Tests passing
- [ ] Code reviewed

### Project Success

- [ ] MVP features complete
- [ ] App stable and performant
- [ ] Ready for beta testing
- [ ] Documentation complete

---

**Document Owner:** Scrum Master  
**Last Updated:** 2026-05-16  
**Next Review:** End of Sprint 5
