import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/data/models/monitored_app_model.dart';

void main() {
  group('MonitoredAppModel', () {
    const tMonitoredAppModel = MonitoredAppModel(
      appPackageName: 'com.zhiliaoapp.musically',
      appName: 'TikTok',
      iconUrl: 'https://example.com/tiktok.png',
      isMonitored: true,
    );

    test('should return a valid model from JSON', () {
      final Map<String, dynamic> jsonMap = {
        'appPackageName': 'com.zhiliaoapp.musically',
        'appName': 'TikTok',
        'iconUrl': 'https://example.com/tiktok.png',
        'isMonitored': true,
      };

      final result = MonitoredAppModel.fromJson(jsonMap);

      expect(result, tMonitoredAppModel);
    });

    test('should handle missing optional iconUrl in JSON', () {
      final Map<String, dynamic> jsonMap = {
        'appPackageName': 'com.zhiliaoapp.musically',
        'appName': 'TikTok',
        'isMonitored': false,
      };

      final result = MonitoredAppModel.fromJson(jsonMap);

      expect(result.appPackageName, 'com.zhiliaoapp.musically');
      expect(result.appName, 'TikTok');
      expect(result.iconUrl, isNull);
      expect(result.isMonitored, false);
    });

    test('should default isMonitored to true when missing in JSON', () {
      final Map<String, dynamic> jsonMap = {
        'appPackageName': 'com.zhiliaoapp.musically',
        'appName': 'TikTok',
      };

      final result = MonitoredAppModel.fromJson(jsonMap);

      expect(result.isMonitored, true);
    });

    test('should return a JSON map containing proper data', () {
      final result = tMonitoredAppModel.toJson();

      final expectedMap = {
        'appPackageName': 'com.zhiliaoapp.musically',
        'appName': 'TikTok',
        'iconUrl': 'https://example.com/tiktok.png',
        'isMonitored': true,
      };
      expect(result, expectedMap);
    });

    test('should omit iconUrl from JSON when null', () {
      const model = MonitoredAppModel(
        appPackageName: 'com.test',
        appName: 'Test',
        isMonitored: true,
      );

      final result = model.toJson();

      expect(result.containsKey('iconUrl'), false);
    });

    test('copyWith should return a new object with updated values', () {
      final result = tMonitoredAppModel.copyWith(
        appName: 'TikTok Updated',
        isMonitored: false,
      );

      expect(result.appName, 'TikTok Updated');
      expect(result.isMonitored, false);
      expect(result.appPackageName, tMonitoredAppModel.appPackageName);
      expect(result.iconUrl, tMonitoredAppModel.iconUrl);
    });

    test('copyWith should preserve values when no arguments provided', () {
      final result = tMonitoredAppModel.copyWith();

      expect(result, tMonitoredAppModel);
    });

    test('should handle empty string values gracefully', () {
      final Map<String, dynamic> jsonMap = {
        'appPackageName': '',
        'appName': '',
        'isMonitored': true,
      };

      final result = MonitoredAppModel.fromJson(jsonMap);

      expect(result.appPackageName, '');
      expect(result.appName, '');
    });
  });
}
