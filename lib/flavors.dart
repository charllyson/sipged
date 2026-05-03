import 'package:sipged/_blocs/system/login/login_area_config.dart';

class Flavor {
  static const String _definedFlavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: '',
  );

  static String get name {
    final cleanFlavor = _definedFlavor.trim();

    if (cleanFlavor.isNotEmpty) {
      return cleanFlavor;
    }

    return AppAreaConfig.flavorForArea(
      AppAreaConfig.defaultAreaLabel,
    );
  }

  static bool get isDER {
    return name.toLowerCase() == 'der';
  }

  static bool get isDNITRO {
    return name.toLowerCase() == 'dnitro';
  }

  /// Mantido apenas se em algum lugar antigo ainda estiver chamando `isDNITRR`.
  static bool get isDNITRR {
    return isDNITRO;
  }
}