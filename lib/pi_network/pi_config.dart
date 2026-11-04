class PiConfig {
  PiConfig._();

  // نبدأ بالاختبار فقط، وليس Mainnet.
  static const bool isTestnet = true;

  // سنحدد عنوان التطبيق بعد تجهيز استضافة HTTPS.
  static const String developmentUrl = '';

  // إصدار Pi SDK للويب.
  static const String sdkVersion = '2.0';
}