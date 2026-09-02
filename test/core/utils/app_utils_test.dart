import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/core/utils/app_utils.dart';

void main() {
  group('AppUtils.isSystemOrUnmonitoredApp tests', () {
    test('Should ONLY allow 10 hardcoded social apps (monitored)', () {
      expect(AppUtils.isSystemOrUnmonitoredApp('com.facebook.katana'), isFalse);
      expect(AppUtils.isSystemOrUnmonitoredApp('com.zhiliaoapp.musically'), isFalse);
      expect(AppUtils.isSystemOrUnmonitoredApp('com.ss.android.ugc.trill'), isFalse);
      expect(AppUtils.isSystemOrUnmonitoredApp('com.instagram.android'), isFalse);
      expect(AppUtils.isSystemOrUnmonitoredApp('com.zing.zalo'), isFalse);
      expect(AppUtils.isSystemOrUnmonitoredApp('com.google.android.youtube'), isFalse);
      expect(AppUtils.isSystemOrUnmonitoredApp('com.instagram.barcelona'), isFalse);
      expect(AppUtils.isSystemOrUnmonitoredApp('com.locket.Locket'), isFalse);
      expect(AppUtils.isSystemOrUnmonitoredApp('com.discord'), isFalse);
      expect(AppUtils.isSystemOrUnmonitoredApp('com.facebook.orca'), isFalse);
      expect(AppUtils.isSystemOrUnmonitoredApp('org.telegram.messenger'), isFalse);
    });

    test('Should completely exclude non-8 apps (games, browsers, google apps)', () {
      expect(AppUtils.isSystemOrUnmonitoredApp('com.garena.game.kgvn'), isTrue);
      expect(AppUtils.isSystemOrUnmonitoredApp('com.android.chrome'), isTrue);
      expect(AppUtils.isSystemOrUnmonitoredApp('com.google.android.gm'), isTrue);
      expect(AppUtils.isSystemOrUnmonitoredApp('com.google.android.apps.maps'), isTrue);
    });

    test('Should exclude self and third-party monitoring tools (KidGuardian & Xm)', () {
      expect(AppUtils.isSystemOrUnmonitoredApp('com.kidguardian.kidguardian'), isTrue);
      expect(AppUtils.isSystemOrUnmonitoredApp('com.preff.kb.xm'), isTrue);
    });

    test('Should block Android and Google system daemons', () {
      expect(AppUtils.isSystemOrUnmonitoredApp('com.android.systemui'), isTrue);
      expect(AppUtils.isSystemOrUnmonitoredApp('com.android.settings'), isTrue);
      expect(AppUtils.isSystemOrUnmonitoredApp('com.google.android.gms'), isTrue);
      expect(AppUtils.isSystemOrUnmonitoredApp('com.google.android.gsf'), isTrue);
      expect(AppUtils.isSystemOrUnmonitoredApp('com.google.android.webview'), isTrue);
      expect(AppUtils.isSystemOrUnmonitoredApp('com.google.android.packageinstaller'), isTrue);
      expect(AppUtils.isSystemOrUnmonitoredApp('android'), isTrue);
    });

    test('Should block manufacturer vendor background services', () {
      expect(AppUtils.isSystemOrUnmonitoredApp('com.sec.android.app.myfiles'), isTrue);
      expect(AppUtils.isSystemOrUnmonitoredApp('com.samsung.android.messaging'), isTrue);
      expect(AppUtils.isSystemOrUnmonitoredApp('com.miui.home'), isTrue);
      expect(AppUtils.isSystemOrUnmonitoredApp('com.xiaomi.discover'), isTrue);
      expect(AppUtils.isSystemOrUnmonitoredApp('com.oppo.market'), isTrue);
      expect(AppUtils.isSystemOrUnmonitoredApp('com.coloros.safecenter'), isTrue);
    });
  });
}
