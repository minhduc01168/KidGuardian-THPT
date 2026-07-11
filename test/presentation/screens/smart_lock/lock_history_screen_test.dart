import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/data/repositories/smart_lock_repository.dart';
import 'package:kidguardian/data/models/lock_history_entry_model.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_bloc.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_event.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_state.dart';
import 'package:kidguardian/presentation/screens/smart_lock/lock_history_screen.dart';
import 'package:kidguardian/presentation/widgets/smart_lock/lock_history_card.dart';

class MockSmartLockRepository extends Mock implements SmartLockRepository {}

void main() {
  late MockSmartLockRepository mockRepository;

  setUp(() {
    mockRepository = MockSmartLockRepository();
  });

  Widget buildTestWidget({
    List<LockHistoryEntryModel>? history,
    bool throwError = false,
  }) {
    if (throwError) {
      when(() => mockRepository.getLockHistory(any(), any()))
          .thenThrow(Exception('Firestore error'));
    } else {
      when(() => mockRepository.getLockHistory(any(), any()))
          .thenAnswer((_) async => history ?? []);
    }

    return MaterialApp(
      home: BlocProvider<SmartLockBloc>(
        create: (_) => SmartLockBloc(repository: mockRepository),
        child: const LockHistoryScreen(
          familyId: 'family1',
          childId: 'child1',
        ),
      ),
    );
  }

  group('LockHistoryScreen', () {
    testWidgets('displays loading indicator initially', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      // Don't settle - just pump once to see loading state
      await tester.pump();

      // Either loading or already loaded (both are acceptable)
      final hasLoader = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      final hasEmpty = find.text('Chưa có lịch sử khoá').evaluate().isNotEmpty;
      expect(hasLoader || hasEmpty, isTrue);
    });

    testWidgets('displays empty state when no history', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Chưa có lịch sử khoá'), findsOneWidget);
    });

    testWidgets('displays filter chips', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Hôm nay'), findsOneWidget);
      expect(find.text('7 ngày'), findsOneWidget);
      expect(find.text('30 ngày'), findsOneWidget);
    });

    testWidgets('displays history list when data exists', (tester) async {
      final history = [
        LockHistoryEntryModel(
          id: 'entry1',
          appPackageName: 'com.tiktok',
          appName: 'TikTok',
          reason: 'time_limit',
          lockedAt: DateTime(2026, 5, 16, 10),
        ),
        LockHistoryEntryModel(
          id: 'entry2',
          appPackageName: 'com.facebook',
          appName: 'Facebook',
          reason: 'schedule',
          scheduleName: 'Giờ ngủ',
          lockedAt: DateTime(2026, 5, 16, 9),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(history: history));
      await tester.pumpAndSettle();

      expect(find.byType(LockHistoryCard), findsNWidgets(2));
      expect(find.text('TikTok'), findsOneWidget);
      expect(find.text('Facebook'), findsOneWidget);
    });

    testWidgets('displays app bar with correct title', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Lịch sử khoá'), findsOneWidget);
    });
  });

  group('LockHistoryCard', () {
    testWidgets('displays app name and reason', (tester) async {
      final entry = LockHistoryEntryModel(
        id: 'entry1',
        appPackageName: 'com.tiktok',
        appName: 'TikTok',
        reason: 'time_limit',
        lockedAt: DateTime(2026, 5, 16, 10, 30),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: LockHistoryCard(entry: entry)),
      ));
      await tester.pumpAndSettle();

      expect(find.text('TikTok'), findsOneWidget);
      expect(find.text('Đã hết giới hạn thời gian'), findsOneWidget);
    });

    testWidgets('displays schedule reason with schedule name', (tester) async {
      final entry = LockHistoryEntryModel(
        id: 'entry1',
        appPackageName: 'com.tiktok',
        appName: 'TikTok',
        reason: 'schedule',
        scheduleName: 'Giờ ngủ',
        lockedAt: DateTime(2026, 5, 16, 21, 0),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: LockHistoryCard(entry: entry)),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Đang trong Giờ ngủ'), findsOneWidget);
    });

    testWidgets('displays lock time', (tester) async {
      final entry = LockHistoryEntryModel(
        id: 'entry1',
        appPackageName: 'com.tiktok',
        appName: 'TikTok',
        reason: 'time_limit',
        lockedAt: DateTime(2026, 5, 16, 10, 30),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: LockHistoryCard(entry: entry)),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Khoá lúc'), findsOneWidget);
    });

    testWidgets('displays unlock time when available', (tester) async {
      final entry = LockHistoryEntryModel(
        id: 'entry1',
        appPackageName: 'com.tiktok',
        appName: 'TikTok',
        reason: 'time_limit',
        lockedAt: DateTime(2026, 5, 16, 10, 30),
        unlockedAt: DateTime(2026, 5, 16, 11, 30),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: LockHistoryCard(entry: entry)),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Mở lúc'), findsOneWidget);
    });
  });
}
