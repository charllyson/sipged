// lib/_utils/text/sipged_normalize.dart
class SipGedNormalize {
  const SipGedNormalize._();
  static String basic(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâãä]', caseSensitive: false), 'a')
        .replaceAll(RegExp(r'[éèêë]', caseSensitive: false), 'e')
        .replaceAll(RegExp(r'[íìîï]', caseSensitive: false), 'i')
        .replaceAll(RegExp(r'[óòôõö]', caseSensitive: false), 'o')
        .replaceAll(RegExp(r'[úùûü]', caseSensitive: false), 'u')
        .replaceAll(RegExp(r'[ç]', caseSensitive: false), 'c');
  }
}
