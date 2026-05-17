# Story 5.2: Parent Approval

## 1. Story Foundation

**User Story:**
**As a** parent,
**I want to** approve or reject my child's time requests,
**So that** I can maintain control while being flexible.

**Acceptance Criteria:**
- [ ] Notification received for new request
- [ ] Can view request details
- [ ] Can approve with specified time
- [ ] Can reject with optional reason
- [ ] Decision is sent to child

**Business Context & Value:**
This completes the two-way interaction loop by allowing parents to respond to their children's time requests, promoting communication and flexible parenting.

---

## 2. Developer Context & Technical Requirements

**Status:** ready-for-dev

### 2.1 Technical Constraints & Guardrails
- **UI:** Create `TimeRequestApprovalScreen` for parent to view and respond to requests
- **Data:** Use existing `TimeRequestRepository` with `approveRequest` and `rejectRequest` methods
- **Notification:** Use existing `NotificationBloc` to show notifications for new requests

### 2.2 Architecture Compliance
- **State Management:** BLoC pattern — use existing `TimeRequestBloc`
- **UI:** Material Design with request cards and action buttons

### 2.3 Previous Learnings (from E5.1)
- `TimeRequestRepository` already has `approveRequest` and `rejectRequest` methods
- `TimeRequestBloc` already has `ApproveTimeRequest` and `RejectTimeRequest` events

### 2.4 Testing Requirements
- Widget tests for TimeRequestApprovalScreen

---

## 3. Tasks & Subtasks

- [x] Create TimeRequestApprovalScreen with request list
- [x] Add approve/reject buttons with confirmation dialogs
- [x] Add optional response input for parent
- [ ] Wire navigation from parent dashboard (deferred - needs parent dashboard integration)
- [x] Run flutter test

## 4. Dev Agent Record

### Debug Log
- TimeRequestApprovalScreen shows list of pending time requests
- Approve/reject dialogs with optional response input
- Status chips for pending/approved/rejected
- Request details include app name, requested minutes, reason, timestamp

### Completion Notes
- TimeRequestApprovalScreen shows all pending requests for a family
- Approve button opens dialog with optional response
- Reject button opens dialog with optional reason
- Parent response is stored and shown to child
- 41 total tests passing

## 5. File List
- `lib/presentation/screens/interaction/time_request_approval_screen.dart` (new)

## 6. Change Log
- **2026-05-17:** Implemented E5.2 Parent Approval - approval screen with approve/reject dialogs

## 7. Status
**Status:** review
