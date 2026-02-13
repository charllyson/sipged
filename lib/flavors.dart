// lib/flavors.dart

import 'package:sipged/_blocs/system/setup/setup_data.dart';

class Flavor {
  /// 1) Tenta pegar do --dart-define=FLAVOR
  /// 2) Se não vier nada, usa o módulo padrão do SetupData
  static String name = const String.fromEnvironment(
    'FLAVOR',
    defaultValue: '',
  ).isNotEmpty
      ? const String.fromEnvironment('FLAVOR')
      : SetupData.flavorForArea(SetupData.defaultModuleLabel);

  static bool get isDER => name == 'der';
  static bool get isDNITRR => name == 'dnitro';
  static bool get isAMPRECATORIOS => name == 'amprecatorios';
}
