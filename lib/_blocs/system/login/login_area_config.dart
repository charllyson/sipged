import 'package:flutter/material.dart';

class AppAreaConfig {
  const AppAreaConfig._();

  static const String defaultAreaLabel = 'DER';

  static const List<String> areaNames = <String>[
    'DER',
    'DNIT-RO',
  ];

  static String? profileKeyForArea(String areaLabel) {
    switch (areaLabel.trim().toUpperCase()) {
      case 'DNIT-RO':
        return 'profileWork';

      case 'DER':
      default:
        return 'profileWork';
    }
  }

  static String flavorForArea(String areaLabel) {
    switch (areaLabel.trim().toUpperCase()) {
      case 'DNIT-RO':
        return 'dnitro';

      case 'DER':
      default:
        return 'der';
    }
  }

  static Gradient gradientForArea(String areaLabel) {
    switch (areaLabel.trim().toUpperCase()) {
      case 'DNIT-RO':
        return const LinearGradient(
          colors: [
            Color.fromARGB(255, 27, 32, 51),
            Color.fromARGB(255, 144, 202, 249),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

      case 'DER':
      default:
        return const LinearGradient(
          colors: [
            Color.fromARGB(255, 27, 32, 51),
            Color.fromARGB(255, 144, 202, 249),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}