import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidguardian/data/models/app_time_limit_model.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_bloc.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_event.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_state.dart';
import 'package:kidguardian/presentation/screens/smart_lock/time_limit_screen.dart';
import 'package:kidguardian/data/repositories/smart_lock_repository.dart';

class MockSmartLockRepository extends Mock implements SmartLockRepository {}

void main() {
  late MockSmartLockRepository mockRepository;

  setUp(() {
    mockRepository = MockSmartLockRepository();
  });

  Widget buildScreen() {
    return MaterialApp(
      home: TimeLimitScreen(
        familyId: '1',
        childId: '1',
        repository: mockRepository,
      ),
    );
  }

  testWidgets('TimeLimitScreen displays empty list when no apps', (WidgetTester tester) async {
    when(() => mockRepository.getAppTimeLimits(any(), any())).thenAnswer((_) async => []);
    when(() => mockRepository.getPopularApps()).thenReturn([]);
    
    await tester.pumpWidget(buildScreen());
    
    // Wait for the mock future to resolve
    await tester.pumpAndSettle();
    
    expect(find.text('Không có ứng dụng nào để hiển thị'), findsOneWidget);
  });
}
