import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/data/models/app_time_limit_model.dart';

void main() {
  group('AppTimeLimitModel', () {
    const tAppTimeLimitModel = AppTimeLimitModel(
      appPackageName: 'com.zhiliaoapp.musically',
      appName: 'TikTok',
      iconUrl: 'https://example.com/tiktok.png',
      limits: {'everyday': 60},
    );

    test('should return a valid model from JSON', () {
      // arrange
      final Map<String, dynamic> jsonMap = {
        'appPackageName': 'com.zhiliaoapp.musically',
        'appName': 'TikTok',
        'iconUrl': 'https://example.com/tiktok.png',
        'limits': {'everyday': 60},
      };
      
      // act
      final result = AppTimeLimitModel.fromJson(jsonMap);
      
      // assert
      expect(result, tAppTimeLimitModel);
    });

    test('should return a JSON map containing proper data', () {
      // act
      final result = tAppTimeLimitModel.toJson();
      
      // assert
      final expectedMap = {
        'appPackageName': 'com.zhiliaoapp.musically',
        'appName': 'TikTok',
        'iconUrl': 'https://example.com/tiktok.png',
        'limits': {'everyday': 60},
      };
      expect(result, expectedMap);
    });

    test('copyWith should return a new object with updated values', () {
      // act
      final result = tAppTimeLimitModel.copyWith(
        appName: 'TikTok Updated',
        limits: {'monday': 30, 'tuesday': 30},
      );
      
      // assert
      expect(result.appName, 'TikTok Updated');
      expect(result.limits, {'monday': 30, 'tuesday': 30});
      expect(result.appPackageName, tAppTimeLimitModel.appPackageName);
    });
  });
}
