// lib/flavors.dart

import 'package:sipged/_blocs/system/setup/setup_data.dart';

class Flavor {
  static const String _definedFlavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: '',
  );

  static String get name {
    if (_definedFlavor.trim().isNotEmpty) {
      return _definedFlavor.trim();
    }

    return SetupData.flavorForArea(
      SetupData.defaultModuleLabel,
    );
  }

  static bool get isDER => name == 'der';

  static bool get isDNITRR => name == 'dnitro';
}