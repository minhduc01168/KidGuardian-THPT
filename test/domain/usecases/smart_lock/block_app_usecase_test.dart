import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/domain/usecases/smart_lock/block_app_usecase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.kidguardian/accessibility');
  final List<MethodCall> methodCalls = [];

  setUp(() {
    methodCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      methodCalls.add(call);
      return true;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('BlockAppUseCase', () {
    late BlockAppUseCase useCase;

    setUp(() => useCase = BlockAppUseCase());

    test('khởi tạo với danh sách trống', () {
      expect(useCase.blockedApps, isEmpty);
    });

    test('execute() thêm app và gọi updateBlockedApps trên native', () async {
      await useCase.execute(appPackageName: 'com.zhiliaoapp.musically');
      expect(useCase.blockedApps, contains('com.zhiliaoapp.musically'));
      expect(methodCalls.first.method, 'updateBlockedApps');
    });

    test('execute() nhiều lần cùng app không tạo duplicate', () async {
      await useCase.execute(appPackageName: 'com.tiktok.app');
      await useCase.execute(appPackageName: 'com.tiktok.app');
      expect(useCase.blockedApps.length, 1);
    });

    test('unblockApp() xoá app khỏi danh sách', () async {
      await useCase.execute(appPackageName: 'com.tiktok.app');
      await useCase.unblockApp(appPackageName: 'com.tiktok.app');
      expect(useCase.blockedApps, isEmpty);
    });

    test('unblockAll() xoá toàn bộ và gọi native với list rỗng', () async {
      await useCase.execute(appPackageName: 'com.tiktok.app');
      methodCalls.clear();
      await useCase.unblockAll();

      expect(useCase.blockedApps, isEmpty);
      final apps = (methodCalls.last.arguments as Map)['apps'] as List;
      expect(apps, isEmpty);
    });

    test('loadBlockedApps() nạp danh sách mà không gọi native', () {
      useCase.loadBlockedApps(['com.tiktok.app', 'com.facebook.katana']);
      expect(useCase.blockedApps.length, 2);
      expect(methodCalls, isEmpty);
    });

    test('startMonitoring() gọi startMonitorService', () async {
      await useCase.startMonitoring();
      expect(methodCalls.any((c) => c.method == 'startMonitorService'), isTrue);
    });

    test('stopMonitoring() gọi stopMonitorService', () async {
      await useCase.stopMonitoring();
      expect(methodCalls.any((c) => c.method == 'stopMonitorService'), isTrue);
    });

    test('forceGoHome() gọi moveToHome', () async {
      await useCase.forceGoHome();
      expect(methodCalls.any((c) => c.method == 'moveToHome'), isTrue);
    });

    test('blockedApps là unmodifiable', () async {
      await useCase.execute(appPackageName: 'com.tiktok.app');
      expect(
        () => (useCase.blockedApps as dynamic).add('com.evil.app'),
        throwsUnsupportedError,
      );
    });
  });
}
