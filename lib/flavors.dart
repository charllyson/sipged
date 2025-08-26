class Flavor {
  static String name = const String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  static bool get isDev => name == 'dev';
  static bool get isStg => name == 'stg';
  static bool get isProd => name == 'prod';
}
