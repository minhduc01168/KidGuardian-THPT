# Epics & User Stories
# KidGuardian - Đồng Hành Số

**Version:** 1.0  
**Date:** 2026-05-12  
**Status:** In Progress  
**Last Updated:** 2026-05-16  

---

## Epic Overview

| Epic | Name | Priority | Stories | Sprint |
|------|------|----------|---------|--------|
| E1 | Authentication & Profile | P0 | 8 | Sprint 1-2 | ✅ Done |
| E2 | Dashboard & Monitoring | P0 | 6 | Sprint 3-4 | 🔄 Ready |
| E3 | Smart Lock (Android) | P0 | 8 | Sprint 5-6 |
| E4 | Safety Alerts | P0 | 5 | Sprint 7 |
| E5 | Two-Way Interaction | P0 | 6 | Sprint 7 |
| E6 | Notifications | P1 | 4 | Sprint 8 |
| E7 | Settings & Profile | P2 | 3 | Sprint 8 |

**Total:** 40 User Stories

---

## Epic 1: Authentication & Profile Management

**Goal:** Enable parents and children to create accounts, link together, and manage profiles.

**Status:** ✅ Done (All 8 stories completed and code reviewed)

### User Stories

#### E1.1: Parent Registration ✅
**As a** parent,  
**I want to** register an account with email and password,  
**So that** I can start using KidGuardian to monitor my child's device.

**Acceptance Criteria:**
- [x] Parent can enter email, password, and display name
- [x] Email validation is performed
- [x] Password must be at least 8 characters
- [x] Account is created in Firebase Auth
- [x] User document is created in Firestore with role="parent"
- [x] Success message is shown
- [x] User is redirected to dashboard

**Story Points:** 3  
**Priority:** P0  
**Sprint:** 1  
**Status:** ✅ Review

---

#### E1.2: Parent Login ✅
**As a** parent,  
**I want to** login with my email and password,  
**So that** I can access my dashboard and manage settings.

**Acceptance Criteria:**
- [x] Parent can enter email and password
- [x] Firebase Auth validates credentials
- [x] Error message shown for invalid credentials
- [x] On success, user is redirected to dashboard
- [x] Session is persisted

**Story Points:** 2  
**Priority:** P0  
**Sprint:** 1  
**Status:** ✅ Review

---

#### E1.3: Create Child Account ✅
**As a** parent,  
**I want to** create an account for my child,  
**So that** my child can use the app and be monitored.

**Acceptance Criteria:**
- [x] Parent can enter child's display name and age
- [x] System generates unique linking code
- [x] Child account is created with role="child"
- [x] Child account is linked to parent's familyId
- [x] Linking code is displayed for parent to share

**Story Points:** 5  
**Priority:** P0  
**Sprint:** 1  
**Status:** ✅ Review

---

#### E1.4: Child Account Setup ✅
**As a** child,  
**I want to** setup my account using the linking code from my parent,  
**So that** I can start using the app.

**Acceptance Criteria:**
- [x] Child can enter linking code
- [x] System validates code and links to parent's family
- [x] Child profile is created
- [x] Child is redirected to their dashboard

**Story Points:** 3  
**Priority:** P0  
**Sprint:** 2  
**Status:** ✅ Review

---

#### E1.5: Child Login ✅
**As a** child,  
**I want to** login to my account,  
**So that** I can view my usage and send requests.

**Acceptance Criteria:**
- [x] Child can login with credentials
- [x] On success, child is redirected to their dashboard
- [x] Session is persisted

**Story Points:** 2  
**Priority:** P0  
**Sprint:** 2  
**Status:** ✅ Review

---

#### E1.6: Logout ✅
**As a** user (parent or child),  
**I want to** logout of my account,  
**So that** I can secure my account on shared devices.

**Acceptance Criteria:**
- [x] Logout button is available in settings
- [x] Confirmation dialog is shown
- [x] On confirmation, user is logged out
- [x] User is redirected to login screen
- [x] Local data is cleared

**Story Points:** 2  
**Priority:** P1  
**Sprint:** 2  
**Status:** ✅ Review

---

#### E1.7: Password Reset ✅
**As a** user,  
**I want to** reset my password if I forget it,  
**So that** I can regain access to my account.

**Acceptance Criteria:**
- [x] "Forgot Password" link on login screen
- [x] User can enter email
- [x] Firebase sends password reset email
- [x] Success message is shown

**Story Points:** 2  
**Priority:** P1  
**Sprint:** 2  
**Status:** ✅ Review

---

#### E1.8: Profile Management ✅
**As a** user,  
**I want to** view and edit my profile,  
**So that** I can keep my information up to date.

**Acceptance Criteria:**
- [x] User can view current profile
- [x] User can edit display name
- [x] User can view linked family members
- [x] Changes are saved to Firestore

**Story Points:** 3  
**Priority:** P2  
**Sprint:** 8  
**Status:** ✅ Review

---

## Epic 2: Dashboard & Monitoring

**Goal:** Provide parents with real-time visibility into child's app usage.

**Status:** ✅ Done (6/6 stories completed)

### User Stories

#### E2.1: Parent Dashboard Overview ✅
**As a** parent,  
**I want to** see a dashboard with my child's usage summary,  
**So that** I can quickly understand how much time they spend on social media.

**Acceptance Criteria:**
- [x] Dashboard shows total usage time today
- [x] Shows breakdown by app (TikTok, Facebook, etc.)
- [x] Shows comparison with yesterday/last week
- [x] Data refreshes automatically

**Story Points:** 5  
**Priority:** P0  
**Sprint:** 3  
**Status:** ✅ Review

---

#### E2.2: Usage Chart ✅
**As a** parent,  
**I want to** see a visual chart of app usage,  
**So that** I can easily identify patterns and trends.

**Acceptance Criteria:**
- [x] Bar chart showing usage by app
- [x] Line chart showing daily trend
- [x] Can switch between daily/weekly view
- [x] Chart is interactive (tap to see details)

**Story Points:** 5  
**Priority:** P0  
**Sprint:** 3  
**Status:** ✅ Review

---

#### E2.3: App Usage List ✅
**As a** parent,  
**I want to** see a list of all monitored apps with usage time,  
**So that** I can see which apps my child uses most.

**Acceptance Criteria:**
- [x] List shows app icon, name, and usage time
- [x] Sorted by usage time (highest first)
- [x] Shows percentage of total usage
- [x] Can tap to see detailed usage

**Story Points:** 3  
**Priority:** P0  
**Sprint:** 4  
**Status:** ✅ Review

---

#### E2.4: Child Dashboard ✅
**As a** child,  
**I want to** see my own usage dashboard,  
**So that** I can understand my usage patterns.

**Acceptance Criteria:**
- [x] Shows remaining time for today
- [x] Shows usage breakdown by app
- [x] Shows active time limits
- [x] Simple, non-intimidating design

**Story Points:** 3  
**Priority:** P0  
**Sprint:** 4  
**Status:** ✅ Review

---

#### E2.5: Daily Summary ✅
**As a** parent,  
**I want to** receive a daily summary of my child's usage,  
**So that** I can stay informed without constantly checking the app.

**Acceptance Criteria:**
- [x] Summary sent at end of day (configurable time)
- [x] Shows total usage and top apps
- [x] Highlights any alerts or violations
- [x] Can be disabled in settings

**Story Points:** 3  
**Priority:** P1  
**Sprint:** 4  
**Status:** ✅ Review

---

#### E2.6: Weekly Report ✅
**As a** parent,  
**I want to** receive a weekly report,  
**So that** I can track long-term trends.

**Acceptance Criteria:**
- [x] Report generated every Sunday
- [x] Shows week-over-week comparison
- [x] Highlights improvements or concerns
- [x] Can be viewed in-app or sent via email

**Story Points:** 5  
**Priority:** P2  
**Sprint:** 8  
**Status:** ✅ Review

---

## Epic 3: Smart Lock (Android)

**Goal:** Enable parents to set time limits and automatically block social media apps when limits are reached.

**Status:** ✅ Done (8/8 stories completed)

### User Stories

#### E3.1: Set Time Limit ✅
**As a** parent,  
**I want to** set daily time limits for specific apps,  
**So that** I can control how much time my child spends on each app.

**Acceptance Criteria:**
- [x] Parent can select app from list
- [x] Parent can set daily limit in minutes
- [x] Can set different limits for different days
- [x] Limits are saved to Firestore
- [x] Child is notified of new limits

**Story Points:** 5  
**Priority:** P0  
**Sprint:** 5  
**Status:** ✅ Done

---

#### E3.2: App Blocking ✅
**As a** parent,  
**I want** apps to be automatically blocked when time limit is reached,  
**So that** my child cannot continue using blocked apps.

**Acceptance Criteria:**
- [x] System monitors app usage in real-time
- [x] When limit reached, app is blocked
- [x] Blocked app shows lock screen
- [x] Child cannot bypass lock screen
- [x] Usage is logged to Firestore

**Story Points:** 8  
**Priority:** P0  
**Sprint:** 5  
**Status:** ✅ Done  

---

#### E3.3: Lock Screen Display
**As a** child,  
**I want to** see a friendly lock screen when an app is blocked,  
**So that** I understand why I can't use the app.

**Acceptance Criteria:**
- [ ] Lock screen shows app name and icon
- [ ] Shows reason for blocking (time limit reached)
- [ ] Shows time until limit resets
- [ ] Has button to request more time
- [ ] Has emergency access button (call/text parent)

**Story Points:** 5  
**Priority:** P0  
**Sprint:** 6  

---

#### E3.4: Schedule Setting ✅
**As a** parent,  
**I want to** set schedules for when apps are blocked,  
**So that** my child focuses on homework or sleep.

**Acceptance Criteria:**
- [x] Parent can set blocked time periods (e.g., 9PM-6AM)
- [x] Can set different schedules for different days
- [x] Can set "homework hours" schedule
- [x] Schedule is enforced automatically

**Story Points:** 5  
**Priority:** P1  
**Sprint:** 6  
**Status:** ✅ Done  

---

#### E3.5: Emergency Access ✅
**As a** child,  
**I want to** have emergency access to phone functions,  
**So that** I can call or text in emergencies even when apps are blocked.

**Acceptance Criteria:**
- [x] Emergency button on lock screen
- [x] Can make phone calls
- [x] Can send SMS
- [x] Emergency access is time-limited (5 minutes)
- [x] Emergency usage is logged

**Story Points:** 3  
**Priority:** P0  
**Sprint:** 6  
**Status:** ✅ Done

---

#### E3.6: Blocked Apps Management ✅
**As a** parent,  
**I want to** manage which apps are monitored and blocked,  
**So that** I can customize monitoring for my child.

**Acceptance Criteria:**
- [x] List of installed social media apps
- [x] Can toggle monitoring for each app
- [x] Can add custom apps to monitor
- [x] Changes take effect immediately

**Story Points:** 3  
**Priority:** P0  
**Sprint:** 5  
**Status:** ✅ Done  

---

#### E3.7: Usage Statistics ✅
**As a** parent,  
**I want to** see detailed usage statistics,  
**So that** I can understand my child's app usage patterns.

**Acceptance Criteria:**
- [x] Shows usage by hour/day/week
- [x] Shows most used apps
- [x] Shows peak usage times
- [x] Can export data

**Story Points:** 5  
**Priority:** P1  
**Sprint:** 6  
**Status:** ✅ Done

---

#### E3.8: Smart Lock Settings ✅
**As a** parent,  
**I want to** configure Smart Lock settings,  
**So that** I can customize how the feature works.

**Acceptance Criteria:**
- [x] Can enable/disable Smart Lock
- [x] Can set default time limits
- [x] Can configure notification preferences
- [x] Can view lock history

**Story Points:** 3  
**Priority:** P1  
**Sprint:** 6  
**Status:** ✅ Done

---

#### E3.8: Smart Lock Settings
**As a** parent,  
**I want to** configure Smart Lock settings,  
**So that** I can customize how the feature works.

**Acceptance Criteria:**
- [x] Can enable/disable Smart Lock
- [x] Can set default time limits
- [x] Can configure notification preferences
- [x] Can view lock history

**Story Points:** 3  
**Priority:** P1  
**Sprint:** 6  
**Status:** ✅ Done  

---

## Epic 4: Safety Alerts

**Goal:** Alert parents when children encounter potentially harmful content.

### User Stories

#### E4.1: Keyword Detection
**As a** parent,  
**I want** the system to detect harmful keywords,  
**So that** I can be alerted if my child encounters inappropriate content.

**Acceptance Criteria:**
- [ ] System monitors text input (when accessible)
- [ ] Detects predefined harmful keywords
- [ ] Creates alert in Firestore
- [ ] Sends notification to parent

**Story Points:** 8  
**Priority:** P0  
**Sprint:** 7  

---

#### E4.2: Alert Notification
**As a** parent,  
**I want to** receive immediate notifications for safety alerts,  
**So that** I can respond quickly to potential issues.

**Acceptance Criteria:**
- [ ] Push notification sent immediately
- [ ] Shows keyword detected and app name
- [ ] Can tap to view alert details
- [ ] Can be configured in settings

**Story Points:** 3  
**Priority:** P0  
**Sprint:** 7  

---

#### E4.3: Alert History
**As a** parent,  
**I want to** view history of safety alerts,  
**So that** I can track patterns and address recurring issues.

**Acceptance Criteria:**
- [ ] List of all alerts with timestamp
- [ ] Shows keyword, app, and context
- [ ] Can filter by date and status
- [ ] Can mark alerts as reviewed

**Story Points:** 3  
**Priority:** P1  
**Sprint:** 7  

---

#### E4.4: Keyword Management
**As a** parent,  
**I want to** customize the list of monitored keywords,  
**So that** I can focus on concerns specific to my child.

**Acceptance Criteria:**
- [ ] View default keyword list
- [ ] Add custom keywords
- [ ] Remove keywords
- [ ] Import/export keyword lists

**Story Points:** 3  
**Priority:** P1  
**Sprint:** 7  

---

#### E4.5: Alert Review
**As a** parent,  
**I want to** review and respond to alerts,  
**So that** I can take appropriate action.

**Acceptance Criteria:**
- [ ] View alert details
- [ ] Mark as reviewed
- [ ] Add notes
- [ ] Dismiss false positives

**Story Points:** 2  
**Priority:** P1  
**Sprint:** 7  

---

## Epic 5: Two-Way Interaction

**Goal:** Enable communication between parents and children regarding time limits and requests.

### User Stories

#### E5.1: Request More Time
**As a** child,  
**I want to** request more time for a blocked app,  
**So that** I can continue using it if I have a good reason.

**Acceptance Criteria:**
- [ ] "Request More Time" button on lock screen
- [ ] Can specify requested minutes
- [ ] Can add reason for request
- [ ] Request is sent to parent
- [ ] Shows pending status

**Story Points:** 5  
**Priority:** P0  
**Sprint:** 7  

---

#### E5.2: Parent Approval
**As a** parent,  
**I want to** approve or reject my child's time requests,  
**So that** I can maintain control while being flexible.

**Acceptance Criteria:**
- [ ] Notification received for new request
- [ ] Can view request details
- [ ] Can approve with specified time
- [ ] Can reject with optional reason
- [ ] Decision is sent to child

**Story Points:** 5  
**Priority:** P0  
**Sprint:** 7  

---

#### E5.3: Request Status
**As a** child,  
**I want to** see the status of my requests,  
**So that** I know if they were approved or rejected.

**Acceptance Criteria:**
- [ ] Shows pending requests
- [ ] Shows approved/rejected requests
- [ ] Shows parent's response
- [ ] Real-time updates

**Story Points:** 3  
**Priority:** P0  
**Sprint:** 7  

---

#### E5.4: Request History
**As a** parent,  
**I want to** view history of all requests,  
**So that** I can track patterns and make informed decisions.

**Acceptance Criteria:**
- [ ] List of all requests
- [ ] Filter by status (pending/approved/rejected)
- [ ] Shows request details and response
- [ ] Sorted by date

**Story Points:** 3  
**Priority:** P1  
**Sprint:** 8  

---

#### E5.5: Quick Approval
**As a** parent,  
**I want to** quickly approve requests from notifications,  
**So that** I don't have to open the app every time.

**Acceptance Criteria:**
- [ ] Notification shows request summary
- [ ] Action buttons in notification (Approve/Reject)
- [ ] Can approve without opening app
- [ ] Confirmation notification sent

**Story Points:** 5  
**Priority:** P1  
**Sprint:** 8  

---

#### E5.6: Auto-Approval Rules
**As a** parent,  
**I want to** set auto-approval rules,  
**So that** I don't have to manually approve every request.

**Acceptance Criteria:**
- [ ] Can set max auto-approve minutes
- [ ] Can set daily auto-approve limit
- [ ] Can enable/disable per app
- [ ] Auto-approved requests are logged

**Story Points:** 5  
**Priority:** P2  
**Sprint:** 8  

---

## Epic 6: Notifications

**Goal:** Keep users informed about important events and updates.

### User Stories

#### E6.1: Push Notifications Setup
**As a** user,  
**I want** push notifications to work reliably,  
**So that** I receive timely alerts and updates.

**Acceptance Criteria:**
- [ ] FCM token is registered on login
- [ ] Token is updated on app update
- [ ] Notifications work when app is in background
- [ ] Notifications work when app is closed

**Story Points:** 5  
**Priority:** P0  
**Sprint:** 8  

---

#### E6.2: Notification Preferences
**As a** user,  
**I want to** configure which notifications I receive,  
**So that** I'm not overwhelmed with unnecessary alerts.

**Acceptance Criteria:**
- [ ] Can toggle notifications by type
- [ ] Can set quiet hours
- [ ] Can choose notification sound
- [ ] Settings are synced to Firestore

**Story Points:** 3  
**Priority:** P1  
**Sprint:** 8  

---

#### E6.3: Notification History
**As a** user,  
**I want to** view history of notifications,  
**So that** I can review past alerts.

**Acceptance Criteria:**
- [ ] List of all notifications
- [ ] Sorted by date
- [ ] Can mark as read
- [ ] Can clear old notifications

**Story Points:** 3  
**Priority:** P2  
**Sprint:** 8  

---

#### E6.4: In-App Notifications
**As a** user,  
**I want to** see notifications within the app,  
**So that** I don't miss important updates.

**Acceptance Criteria:**
- [ ] Notification badge on app icon
- [ ] Notification center in app
- [ ] Unread count displayed
- [ ] Can tap to view details

**Story Points:** 3  
**Priority:** P2  
**Sprint:** 8  

---

## Epic 7: Settings & Profile

**Goal:** Allow users to customize app behavior and manage their profiles.

### User Stories

#### E7.1: App Settings
**As a** user,  
**I want to** configure app settings,  
**So that** I can customize the app to my preferences.

**Acceptance Criteria:**
- [ ] Can toggle dark/light mode
- [ ] Can set language (Vietnamese/English)
- [ ] Can configure notification settings
- [ ] Settings are persisted locally

**Story Points:** 3  
**Priority:** P2  
**Sprint:** 8  

---

#### E7.2: Family Management
**As a** parent,  
**I want to** manage my family members,  
**So that** I can add or remove children from my account.

**Acceptance Criteria:**
- [ ] View list of linked children
- [ ] Add new child account
- [ ] Remove child account
- [ ] View child's linking status

**Story Points:** 3  
**Priority:** P1  
**Sprint:** 8  

---

#### E7.3: Help & Support
**As a** user,  
**I want to** access help and support,  
**So that** I can get assistance when needed.

**Acceptance Criteria:**
- [ ] FAQ section
- [ ] Contact support form
- [ ] App version info
- [ ] Terms of service and privacy policy

**Story Points:** 2  
**Priority:** P2  
**Sprint:** 8  

---

## Story Points Summary

| Epic | Stories | Total Points |
|------|---------|--------------|
| E1: Authentication | 8 | 22 |
| E2: Dashboard | 6 | 24 |
| E3: Smart Lock | 8 | 37 |
| E4: Safety Alerts | 5 | 19 |
| E5: Interaction | 6 | 26 |
| E6: Notifications | 4 | 14 |
| E7: Settings | 3 | 8 |
| **Total** | **40** | **150** |

---

## Sprint Allocation

| Sprint | Stories | Points | Focus |
|--------|---------|--------|-------|
| Sprint 1 | E1.1, E1.2, E1.3 | 10 | Parent auth & child creation |
| Sprint 2 | E1.4, E1.5, E1.6, E1.7 | 9 | Child auth & basic features |
| Sprint 3 | E2.1, E2.2 | 10 | Parent dashboard |
| Sprint 4 | E2.3, E2.4, E2.5 | 9 | Child dashboard & monitoring |
| Sprint 5 | E3.1, E3.2, E3.6 | 16 | Smart Lock core |
| Sprint 6 | E3.3, E3.4, E3.5, E3.7, E3.8 | 21 | Smart Lock advanced |
| Sprint 7 | E4.1, E4.2, E4.3, E4.4, E4.5, E5.1, E5.2, E5.3 | 32 | Alerts & interaction |
| Sprint 8 | E1.8, E2.6, E5.4, E5.5, E5.6, E6.1, E6.2, E6.3, E6.4, E7.1, E7.2, E7.3 | 43 | Polish & extras |

**Total Sprints:** 8  
**Average Points per Sprint:** ~19  

---

**Document Owner:** Product Team  
**Last Updated:** 2026-05-13  
**Next Review:** 2026-05-19

---

## Change Log

| Date | Change | Author |
|------|--------|--------|
| 2026-05-12 | Initial document created | Product Team |
| 2026-05-13 | Epic 1 completed - all 8 stories implemented and moved to review status | Dev Team |
| 2026-05-16 | Epic 3: E3.1 Set Time Limit and E3.2 App Blocking completed with code review fixes | Dev Team |
