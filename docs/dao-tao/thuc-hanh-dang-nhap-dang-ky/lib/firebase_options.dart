// =============================================================
// FILE NÀY SẼ ĐƯỢC TỰ ĐỘNG TẠO BỞI LỆNH: flutterfire configure
// KHÔNG CHỈNH SỬA THỦ CÔNG - hãy chạy lệnh trên để tạo lại
// =============================================================

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions chưa được cấu hình cho platform này.',
        );
    }
  }

  // TODO: Thay thế bằng giá trị thật từ Firebase Console
  // Sau khi chạy `flutterfire configure`, file này sẽ được tạo lại tự động
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    iosBundleId: 'com.example.authpractice',
  );
}
