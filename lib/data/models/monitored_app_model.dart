import 'package:equatable/equatable.dart';

class MonitoredAppModel extends Equatable {
  final String appPackageName;
  final String appName;
  final String? iconUrl;
  final bool isMonitored;

  const MonitoredAppModel({
    required this.appPackageName,
    required this.appName,
    this.iconUrl,
    this.isMonitored = true,
  });

  factory MonitoredAppModel.fromJson(Map<String, dynamic> json) {
    return MonitoredAppModel(
      appPackageName: json['appPackageName']?.toString() ?? '',
      appName: json['appName']?.toString() ?? '',
      iconUrl: json['iconUrl']?.toString(),
      isMonitored: json['isMonitored'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appPackageName': appPackageName,
      'appName': appName,
      if (iconUrl != null) 'iconUrl': iconUrl,
      'isMonitored': isMonitored,
    };
  }

  MonitoredAppModel copyWith({
    String? appPackageName,
    String? appName,
    String? iconUrl,
    bool? isMonitored,
  }) {
    return MonitoredAppModel(
      appPackageName: appPackageName ?? this.appPackageName,
      appName: appName ?? this.appName,
      iconUrl: iconUrl ?? this.iconUrl,
      isMonitored: isMonitored ?? this.isMonitored,
    );
  }

  @override
  List<Object?> get props => [appPackageName, appName, iconUrl, isMonitored];
}
