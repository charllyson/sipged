// lib/_utils/theme/sipged_theme.dart

import 'package:flutter/material.dart';

abstract final class SipGedTheme {
  // ===========================================================================
  // CORES INSTITUCIONAIS
  // ===========================================================================

  static const Color primaryColor = Color(0xFF1B2033);
  static const Color secondaryColor = Color(0xFF091D68);

  // ===========================================================================
  // CORES BASE DO SISTEMA
  // ===========================================================================

  static const Color background = Colors.white;
  static const Color surface = Color(0xFFF7F8FA);
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceMuted = Color(0xFFEEF2F7);

  static const Color border = Color(0xFFE2E5EA);
  static const Color borderDark = Color(0xFF9CA3AF);
  static const Color borderSoft = Color(0xFFE5E7EB);

  static const Color text = Color(0xFF333333);
  static const Color textDark = Color(0xFF111827);
  static const Color textTitle = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Colors.white;
  static const Color textDisabled = Color(0xFF999999);

  static const Color transparent = Colors.transparent;

  // ===========================================================================
  // FEEDBACK
  // ===========================================================================

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color danger = Color(0xFFC62828);
  static const Color error = danger;
  static const Color info = Color(0xFF1565C0);
  static const Color disabled = Color(0xFF999999);

  // ===========================================================================
  // UPBAR
  // ===========================================================================

  static const Color upBarStart = primaryColor;
  static const Color upBarEnd = Color(0xFF1B2039);
  static const Color upBarBorder = Colors.white;

  static const List<Color> upBarGradient = <Color>[
    upBarStart,
    upBarEnd,
  ];

  // ===========================================================================
  // TAB FORM
  // ===========================================================================

  static const Color tabFormBackground = Colors.white;
  static const Color tabFormBorder = borderDark;

  static const Color tabFormHeaderBackground = surfaceLight;
  static const Color tabFormHeaderBorder = Color(0x0F000000);

  static const Color tabFormSelectedBackground = secondaryColor;
  static const Color tabFormSelectedForeground = Colors.white;

  static const Color tabFormUnselectedBackground = Colors.transparent;
  static const Color tabFormUnselectedForeground = textMuted;

  static const Color tabFormDisabledForeground = Color(0x7364748B);

  // ===========================================================================
  // CARDS / CONTAINERS
  // ===========================================================================

  static const Color cardBackground = Colors.white;
  static const Color cardBorder = borderSoft;
  static const Color cardShadow = Color(0x14000000);

  // ===========================================================================
  // GRÁFICOS
  // ===========================================================================

  static const List<Color> chartPalette = <Color>[
    Color(0xFF6E7BFF),
    Color(0xFFB66DFF),
    Color(0xFF2DD4BF),
    Color(0xFFFFB703),
    Color(0xFFFF4D6D),
    Color(0xFF60A5FA),
    Color(0xFFA3E635),
    Color(0xFFF472B6),
  ];

  static Color chartPaletteColors(int index) {
    return chartPalette[index % chartPalette.length];
  }

  static Color severityColor(String value) {
    switch (value.trim().toUpperCase()) {
      case 'GRAVE':
        return const Color(0xFFFF4D6D);

      case 'MODERADO':
        return const Color(0xFFFFB703);

      default:
        return const Color(0xFF2DD4BF);
    }
  }

  // ===========================================================================
  // HELPERS DE OPACIDADE
  // ===========================================================================

  static Color blackAlpha(double alpha) {
    return Colors.black.withValues(alpha: alpha);
  }

  static Color whiteAlpha(double alpha) {
    return Colors.white.withValues(alpha: alpha);
  }

  static Color primaryAlpha(double alpha) {
    return primaryColor.withValues(alpha: alpha);
  }

  static Color secondaryAlpha(double alpha) {
    return secondaryColor.withValues(alpha: alpha);
  }

  static Color textMutedAlpha(double alpha) {
    return textMuted.withValues(alpha: alpha);
  }

  // ===========================================================================
  // CONVERSÃO HEX
  // ===========================================================================

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
    var value = hex.trim().replaceAll('#', '');

    if (value.length == 6) {
      value = 'FF$value';
    }

    if (value.length != 8) {
      throw FormatException('Hex inválido: $hex');
    }

    return Color(int.parse(value, radix: 16));
  }
}