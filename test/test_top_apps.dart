import 'package:kidguardian/data/repositories/summary_repository_impl.dart';
import 'package:kidguardian/core/utils/app_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  final Map<String, int> usageByApp = {
    'YouTube': 120,
    'Facebook': 60,
    'Locket': 30,
  };
  
  final sortedApps = usageByApp.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final topApps = sortedApps.take(3).map((e) => e.key).toList();
  
  print('Top Apps: \$topApps');
}
