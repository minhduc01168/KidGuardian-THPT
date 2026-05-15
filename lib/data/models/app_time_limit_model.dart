import 'package:equatable/equatable.dart';

class AppTimeLimitModel extends Equatable {
  final String appPackageName;
  final String appName;
  final String? iconUrl;
  final Map<String, int> limits;

  const AppTimeLimitModel({
    required this.appPackageName,
    required this.appName,
    this.iconUrl,
    required this.limits,
  });

  factory AppTimeLimitModel.fromJson(Map<String, dynamic> json) {
    final limitsMap = json['limits'] as Map<dynamic, dynamic>? ?? {};
    final parsedLimits = <String, int>{};
    limitsMap.forEach((key, value) {
      if (value is num) {
        parsedLimits[key.toString()] = value.toInt();
      }
    });
    
    return AppTimeLimitModel(
      appPackageName: json['appPackageName']?.toString() ?? '',
      appName: json['appName']?.toString() ?? '',
      iconUrl: json['iconUrl']?.toString(),
      limits: parsedLimits,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appPackageName': appPackageName,
      'appName': appName,
      if (iconUrl != null) 'iconUrl': iconUrl,
      'limits': limits,
    };
  }

  AppTimeLimitModel copyWith({
    String? appPackageName,
    String? appName,
    String? iconUrl,
    Map<String, int>? limits,
  }) {
    return AppTimeLimitModel(
      appPackageName: appPackageName ?? this.appPackageName,
      appName: appName ?? this.appName,
      iconUrl: iconUrl ?? this.iconUrl,
      limits: limits ?? this.limits,
    );
  }

  @override
  List<Object?> get props => [appPackageName, appName, iconUrl, limits];
}
