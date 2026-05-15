import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/domain/usecases/smart_lock/check_app_access_usecase.dart';
import 'package:kidguardian/domain/repositories/usage_repository.dart';
import 'package:kidguardian/data/repositories/smart_lock_repository.dart';
import 'package:kidguardian/data/models/app_time_limit_model.dart';

class MockUsageRepository extends Mock implements UsageRepository {}
class MockSmartLockRepository extends Mock implements SmartLockRepository {}

void main() {
  late CheckAppAccessUseCase useCase;
  late MockUsageRepository mockUsageRepository;
  late MockSmartLockRepository mockSmartLockRepository;

  setUp(() {
    mockUsageRepository = MockUsageRepository();
    mockSmartLockRepository = MockSmartLockRepository();
    useCase = CheckAppAccessUseCase(
      usageRepository: mockUsageRepository,
      smartLockRepository: mockSmartLockRepository,
    );
  });

  group('CheckAppAccessUseCase', () {
    const familyId = 'f1';
    const childUid = 'c1';
    const appPackage = 'com.tiktok.app';

    test('should return true if no limits exist', () async {
      when(() => mockSmartLockRepository.getAppTimeLimits(familyId, childUid))
          .thenAnswer((_) async => []);
      
      final result = await useCase.execute(
        familyId: familyId,
        childUid: childUid,
        appPackageName: appPackage,
      );

      expect(result, isTrue);
    });

    test('should return true if usage is under limit', () async {
      when(() => mockSmartLockRepository.getAppTimeLimits(familyId, childUid))
          .thenAnswer((_) async => [
                AppTimeLimitModel(
                  appPackageName: appPackage,
                  appName: 'TikTok',
                  limits: const {'everyday': 60},
                )
              ]);
      when(() => mockUsageRepository.getUsageByApp(childUid, any()))
          .thenAnswer((_) async => {appPackage: 30});
      
      final result = await useCase.execute(
        familyId: familyId,
        childUid: childUid,
        appPackageName: appPackage,
      );

      expect(result, isTrue);
    });

    test('should return false if usage equals or exceeds limit', () async {
      when(() => mockSmartLockRepository.getAppTimeLimits(familyId, childUid))
          .thenAnswer((_) async => [
                AppTimeLimitModel(
                  appPackageName: appPackage,
                  appName: 'TikTok',
                  limits: const {'everyday': 60},
                )
              ]);
      when(() => mockUsageRepository.getUsageByApp(childUid, any()))
          .thenAnswer((_) async => {appPackage: 60});
      
      final result = await useCase.execute(
        familyId: familyId,
        childUid: childUid,
        appPackageName: appPackage,
      );

      expect(result, isFalse);
    });
  });
}
