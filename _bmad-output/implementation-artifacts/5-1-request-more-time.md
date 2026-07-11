# Story 5.1: Request More Time

## 1. Story Foundation

**User Story:**
**As a** child,
**I want to** request more time for a blocked app,
**So that** I can continue using it if I have a good reason.

**Acceptance Criteria:**
- [ ] "Request More Time" button on lock screen
- [ ] Can specify requested minutes
- [ ] Can add reason for request
- [ ] Request is sent to parent
- [ ] Shows pending status

**Business Context & Value:**
This enables two-way interaction between parent and child, allowing children to request additional time when they have valid reasons, promoting communication and trust.

---

## 2. Developer Context & Technical Requirements

**Status:** ready-for-dev

### 2.1 Technical Constraints & Guardrails
- **UI:** Add "Request More Time" button to existing LockScreen
- **Data:** Create `TimeRequest` model and store in Firestore at `families/{familyId}/children/{childUid}/timeRequests`
- **Communication:** Request appears in parent dashboard as pending

### 2.2 Architecture Compliance
- **State Management:** BLoC pattern — create `TimeRequestBloc`
- **UI:** Bottom sheet for request form on lock screen

### 2.3 Previous Learnings (from Sprint 6)
- LockScreen already exists with emergency access button
- AppBlockedState contains familyId, childUid, parentUid

### 2.4 Testing Requirements
- Unit tests for TimeRequestBloc

---

## 3. Tasks & Subtasks

- [x] Create TimeRequest model with minutes, reason, status, timestamp
- [x] Create TimeRequestRepository with submitRequest, getRequests methods
- [x] Create TimeRequestBloc with SubmitRequest, LoadRequests events
- [x] Add "Request More Time" button to LockScreen (already existed)
- [x] Create request form bottom sheet with minutes picker and reason input (updated to use new bloc)
- [x] Show pending status after submission
- [x] Write unit tests for TimeRequestBloc

## 4. Dev Agent Record

### Debug Log
- LockScreen already had "Xin thêm thời gian" button and RequestTimeDialog
- Updated RequestTimeDialog to use new TimeRequestRepository and TimeRequestBloc
- TimeRequest model stores in families/{familyId}/children/{childUid}/timeRequests
- Added approve/reject methods for parent side

### Completion Notes
- TimeRequestBloc handles SubmitTimeRequest, LoadTimeRequests, LoadPendingRequests, ApproveTimeRequest, RejectTimeRequest
- RequestTimeDialog updated to use BlocProvider and BlocConsumer
- Minutes picker with 15/30/60 options
- Reason input field
- Success/error feedback via SnackBar
- 41 total tests passing

## 5. File List
- `lib/domain/repositories/time_request_repository.dart` (new)
- `lib/presentation/blocs/time_request/time_request_bloc.dart` (new)
- `lib/presentation/widgets/smart_lock/request_time_dialog.dart` (updated)
- `test/presentation/blocs/time_request/time_request_bloc_test.dart` (new)

## 6. Change Log
- **2026-05-17:** Implemented E5.1 Request More Time - model, repository, bloc, updated dialog, tests

## 7. Status
**Status:** review
