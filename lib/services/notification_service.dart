import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  static Future<void> initOneSignal() async {
    if (!GetPlatform.isAndroid && !GetPlatform.isIOS) return;

    final String? onesignalKey = dotenv.env["ONESIGNAL"];
    if (onesignalKey == null) return;

    // OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(onesignalKey);
    OneSignal.Notifications.requestPermission(true);
  }
}
