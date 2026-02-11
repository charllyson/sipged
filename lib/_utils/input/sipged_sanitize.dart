// lib/_utils/input/sipged_sanitize.dart
class SipGedSanitize {
  const SipGedSanitize._();
  static String onlyDigits(String text) => text.replaceAll(RegExp(r'[^\d]'), '');
  static String priceToDot(String text) => text.replaceAll(',', '.');
}
