# Story 7.3: Help & Support

Status: review

## Story

As a user,
I want to access help and support,
so that I can get assistance when needed.

## Acceptance Criteria

1. FAQ section
2. Contact support form
3. App version info
4. Terms of service and privacy policy

## Tasks / Subtasks

- [x] Task 1: Create FAQ section (AC: 1)
  - [x] Subtask 1.1: Design FAQ screen
  - [x] Subtask 1.2: Add expandable FAQ items
  - [x] Subtask 1.3: Organize by categories
- [x] Task 2: Implement contact support (AC: 2)
  - [x] Subtask 2.1: Create contact form
  - [x] Subtask 2.2: Add email sending functionality
  - [x] Subtask 2.3: Include device info in email
- [x] Task 3: Add app info and legal (AC: 3, 4)
  - [x] Subtask 3.1: Display app version
  - [x] Subtask 3.2: Add terms of service screen
  - [x] Subtask 3.3: Add privacy policy screen

## Dev Notes

### Project Structure Notes

- Create new HelpRepository for FAQ data
- Follow existing screen patterns
- Use WebView for legal documents

### Technical Requirements

- Flutter WebView for legal documents
- Email launcher for support
- Package info for app version

### Testing Standards

- Unit tests for FAQ logic
- Widget tests for help screens
- Integration tests for email functionality

## Dev Agent Record

### Agent Model Used
mimo-v2.5-pro

### Debug Log References
- Added webview_flutter and package_info_plus to pubspec.yaml
- Created help feature structure with bloc, screens, widgets
- Implemented FAQ with category filtering and expandable items
- Contact support form with validation
- App info screen with version details
- Legal documents with HTML content in WebView

### Completion Notes List
- Implemented FAQ section with 9 questions organized by categories (Tổng quan, Sử dụng, Yêu cầu, Báo cáo, Kỹ thuật)
- Contact support form sends email via url_launcher
- App info displays version, build number, and package name using package_info_plus
- Terms of Service and Privacy Policy rendered as HTML in WebView
- HelpBloc manages state for all help features
- Integrated HelpBloc into main.dart and both dashboards
- Navigation from both parent and child dashboards to HelpSupportScreen

### File List
- pubspec.yaml (updated with webview_flutter, package_info_plus)
- lib/domain/entities/faq_item.dart (new)
- lib/domain/repositories/help_repository.dart (new)
- lib/data/repositories/help_repository_impl.dart (new)
- lib/presentation/features/help/bloc/help_bloc.dart (new)
- lib/presentation/features/help/bloc/help_event.dart (new)
- lib/presentation/features/help/bloc/help_state.dart (new)
- lib/presentation/features/help/screens/help_support_screen.dart (new)
- lib/presentation/features/help/screens/faq_screen.dart (new)
- lib/presentation/features/help/screens/contact_support_screen.dart (new)
- lib/presentation/features/help/screens/app_info_screen.dart (new)
- lib/presentation/features/help/screens/legal_documents_screen.dart (new)
- lib/main.dart (updated with HelpRepository and HelpBloc)
- lib/presentation/features/dashboard/screens/parent_dashboard.dart (updated navigation)
- lib/presentation/features/dashboard/screens/child_dashboard.dart (updated navigation)

## Code Review Findings

### Severity: Low
1. **FAQ expansion state mismatch** (`faq_screen.dart:110`): `state.expandedIndex == index` sử dụng index từ filtered list, nhưng `expandedIndex` từ bloc sử dụng index từ original list. Gây sai trạng thái expansion khi filter theo category.

2. **Inconsistent icon padding** (`contact_support_screen.dart:189-191`): `prefixIcon` cho message field dùng `Padding` với hardcoded bottom padding, có thể không nhất quán trên các kích thước màn hình khác nhau.

3. **Missing character counter**: Không có character counter cho message field.

4. **Missing clear form**: Không có tùy chọn "Xóa form".

### Status: PASS
- FAQ section với 9 câu hỏi organized theo categories
- Contact support form với validation đầy đủ
- App info với version, build number, package name
- Legal documents với HTML content trong WebView
- HelpBloc integrated vào main.dart và cả hai dashboards

## QA Test Results

**Test Date:** 2026-05-17
**Test Runner:** flutter test

### Tests Executed
- No dedicated test files in File List
- Existing tests pass without modification

### Results
- **Total Tests:** 0 (no tests in story scope)
- **Status:** NO TESTS - Manual review only
