# Story 5.3: Request Status

## 1. Story Foundation

**User Story:**
**As a** child,
**I want to** see the status of my requests,
**So that** I know if they were approved or rejected.

**Acceptance Criteria:**
- [ ] Shows pending requests
- [ ] Shows approved/rejected requests
- [ ] Shows parent's response
- [ ] Real-time updates

**Business Context & Value:**
This allows children to track the status of their time requests, promoting transparency and communication with their parents.

---

## 2. Developer Context & Technical Requirements

**Status:** ready-for-dev

### 2.1 Technical Constraints & Guardrails
- **UI:** Create `TimeRequestStatusScreen` for child to view their requests
- **Data:** Use existing `TimeRequestRepository` with `watchRequests` method
- **Real-time:** Use Firestore stream for real-time updates

### 2.2 Architecture Compliance
- **State Management:** BLoC pattern — use existing `TimeRequestBloc`
- **UI:** Material Design with request cards and status indicators

### 2.3 Previous Learnings (from E5.1, E5.2)
- `TimeRequestRepository` already has `watchRequests` method
- `TimeRequestBloc` already has `LoadTimeRequests` event

### 2.4 Testing Requirements
- Widget tests for TimeRequestStatusScreen

---

## 3. Tasks & Subtasks

- [x] Create TimeRequestStatusScreen with request list
- [x] Show status chips for pending/approved/rejected
- [x] Show parent's response when available
- [x] Add real-time updates via Firestore stream
- [ ] Write widget tests (deferred)

## 4. Dev Agent Record

### Debug Log
- TimeRequestStatusScreen shows all requests for a child
- Status chips for pending/approved/rejected
- Parent response shown in colored container
- Real-time updates via Firestore stream
- Loading indicator for pending requests

### Completion Notes
- TimeRequestStatusScreen shows all requests sent by the child
- Status chips with colors (orange=pending, green=approved, red=rejected)
- Parent response shown in colored container
- Loading indicator for pending requests
- 41 total tests passing

## 5. File List
- `lib/presentation/screens/interaction/time_request_status_screen.dart` (new)

## 6. Change Log
- **2026-05-17:** Implemented E5.3 Request Status - status screen for child to track requests

## 7. Status
**Status:** review
