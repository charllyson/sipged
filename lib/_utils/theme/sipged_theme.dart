import 'package:flutter/material.dart';

abstract final class SipGedTheme {
  static Color primaryColor = const Color(0xFF1B2033);

  // Neutros úteis (exemplos)
  static const Color background = Colors.white;
  static const Color surface = Color(0xFFF7F8FA);
  static const Color border = Color(0xFFE2E5EA);

  // Feedback (exemplos)
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color danger = Color(0xFFC62828);
  static const Color info = Color(0xFF1565C0);
  static const Color disabled = Color(0xFF999999);
  static const Color text = Color(0xFF333333);

  static int _channel255(double normalized) {
    return (normalized * 255.0).round().clamp(0, 255);
  }

  static String colorToHex(Color color, {bool includeAlpha = true}) {
    final a = _channel255(color.a).toRadixString(16).padLeft(2, '0');
    final r = _channel255(color.r).toRadixString(16).padLeft(2, '0');
    final g = _channel255(color.g).toRadixString(16).padLeft(2, '0');
    final b = _channel255(color.b).toRadixString(16).padLeft(2, '0');

    final hex = includeAlpha ? '$a$r$g$b' : '$r$g$b';
    return '#${hex.toUpperCase()}';
  }

  static Color hexToColor(String hex) {
    var s = hex.replaceAll('#', '');
    if (s.length == 6) s = 'FF$s';
    if (s.length != 8) throw FormatException('Hex inválido: $hex');
    return Color(int.parse(s, radix: 16));
  }

  static Color chartPaletteColors(int i) {
    const colors = [
      Color(0xFF6E7BFF),
      Color(0xFFB66DFF),
      Color(0xFF2DD4BF),
      Color(0xFFFFB703),
      Color(0xFFFF4D6D),
      Color(0xFF60A5FA),
      Color(0xFFA3E635),
      Color(0xFFF472B6),
    ];
    return colors[i % colors.length];
  }

  static Color severityColor(String s) {
    switch (s) {
      case 'GRAVE':
        return const Color(0xFFFF4D6D);
      case 'MODERADO':
        return const Color(0xFFFFB703);
      default:
        return const Color(0xFF2DD4BF);
    }
  }
}