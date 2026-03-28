import 'package:wakelock_plus/wakelock_plus.dart';

/// FLAG_SECURE يتفعّل globally من main.dart — هنا بسن نتحكم في Wakelock فقط.
class ContentProtection {
  /// يتفعّل الشاشة تفضل شغالة خلال تشغيل الفيديو.
  static Future<void> enable() async {
    await WakelockPlus.enable();
  }

  /// يوقف الـ wakelock لمّا يغلق البلاير.
  static Future<void> disable() async {
    await WakelockPlus.disable();
  }
}
