import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/data/repositories/smart_lock_repository.dart';
import 'package:kidguardian/data/models/app_time_limit_model.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_bloc.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_event.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_state.dart';

class MockSmartLockRepository extends Mock implements SmartLockRepository {}

void main() {
  late SmartLockBloc bloc;
  late MockSmartLockRepository mockRepository;

  setUp(() {
    mockRepository = MockSmartLockRepository();
    bloc = SmartLockBloc(repository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('SmartLockBloc', () {
    const familyId = 'family1';
    const childId = 'child1';
    
    final popularApps = [
      const AppTimeLimitModel(appPackageName: 'com.facebook', appName: 'Facebook', limits: {}),
      const AppTimeLimitModel(appPackageName: 'com.tiktok', appName: 'TikTok', limits: {}),
    ];
    
    final configuredApps = [
      const AppTimeLimitModel(appPackageName: 'com.tiktok', appName: 'TikTok', limits: {'everyday': 60}),
    ];

    test('initial state is SmartLockInitial', () {
      expect(bloc.state, isA<SmartLockInitial>());
    });

    blocTest<SmartLockBloc, SmartLockState>(
      'emits [SmartLockLoading, SmartLockLoaded] when LoadAppTimeLimits is added',
      build: () {
        when(() => mockRepository.getPopularApps()).thenReturn(popularApps);
        when(() => mockRepository.getAppTimeLimits(familyId, childId))
            .thenAnswer((_) async => configuredApps);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadAppTimeLimits(familyId, childId)),
      expect: () => [
        isA<SmartLockLoading>(),
        isA<SmartLockLoaded>().having((state) => state.apps.length, 'apps count', 2)
            .having((state) => state.apps.first.appName, 'first app is configured one', 'TikTok'),
      ],
    );

    blocTest<SmartLockBloc, SmartLockState>(
      'emits [SmartLockActionSuccess, SmartLockLoaded] when SaveAppTimeLimit is added',
      build: () {
        when(() => mockRepository.saveAppTimeLimit(familyId, childId, configuredApps.first))
            .thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(SaveAppTimeLimit(familyId, childId, configuredApps.first)),
      expect: () => [
        isA<SmartLockActionSuccess>(),
        isA<SmartLockLoaded>(),
      ],
    );
  });
}
