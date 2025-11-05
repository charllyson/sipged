// lib/flavors.dart
class Flavor {
  static String name = const String.fromEnvironment('FLAVOR', defaultValue: 'der');
  static bool get isDER => name == 'der';
  static bool get isDNITRO => name == 'dnitro';
  static bool get isAMPRECATORIOS => name == 'amprecatorios';

}
