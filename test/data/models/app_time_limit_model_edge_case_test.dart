import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/data/models/app_time_limit_model.dart';

void main() {
  test('AppTimeLimitModel handles missing JSON keys gracefully', () {
    final Map<String, dynamic> emptyJson = {};
    final result = AppTimeLimitModel.fromJson(emptyJson);
    
    expect(result.appPackageName, '');
    expect(result.appName, '');
    expect(result.iconUrl, null);
    expect(result.limits, {});
  });
}
