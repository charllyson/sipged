import 'package:flutter/material.dart';

abstract final class SipGedTheme {
  // ===========================================================================
  // CORES INSTITUCIONAIS
  // ===========================================================================

  static const Color primaryColor = Color(0xFF1B2033);
  static const Color secondaryColor = Color(0xFF091D68);

  // ===========================================================================
  // CORES BASE
  // ===========================================================================

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

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
  // LIGHT THEME COLORS
  // ===========================================================================

  static const Color lightPrimary = Color(0xFF0F172A);
  static const Color lightSecondary = Color(0xFF1D4ED8);

  static const Color lightScaffoldBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCanvas = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF8FAFC);
  static const Color lightDivider = Color(0xFFE5E7EB);

  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);

  // ===========================================================================
  // DARK THEME COLORS
  // ===========================================================================

  static const Color darkPrimary = Color(0xFF60A5FA);
  static const Color darkSecondary = Color(0xFF3B82F6);

  static const Color darkScaffoldBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCanvas = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1F2937);
  static const Color darkDivider = Color(0xFF374151);

  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  // ===========================================================================
  // CORES DOS MÓDULOS / DRAWER / HOME
  // ===========================================================================

  static const Color drawerSectionLabelColor = Colors.white;
  static const Color drawerModuleLabelColor = Colors.white70;

  static const Color contractsColor = Color(0xFF0EA5E9);
  static const Color operationColor = Color(0xFF059669);
  static const Color planningColor = Color(0xFF1E40AF);
  static const Color trafficColor = Color(0xFFEA580C);
  static const Color activeColor = Color(0xFF334155);

  // ===========================================================================
  // FEEDBACK
  // ===========================================================================

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFC62828);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);
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
  // THEME DATA - LIGHT
  // ===========================================================================

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: lightPrimary,
      onPrimary: Colors.white,
      secondary: lightSecondary,
      onSecondary: Colors.white,
      error: error,
      onError: Colors.white,
      surface: lightSurface,
      onSurface: lightTextPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      primaryColor: lightPrimary,
      scaffoldBackgroundColor: lightScaffoldBackground,
      canvasColor: lightCanvas,
      cardColor: lightCard,
      dividerColor: lightDivider,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: lightPrimary.withValues(alpha: 0.04),

      appBarTheme: const AppBarTheme(
        backgroundColor: lightPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: lightPrimary,
        contentTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
      ),

      dividerTheme: const DividerThemeData(
        color: lightDivider,
        thickness: 1,
      ),

      cardTheme: const CardThemeData(
        color: lightCard,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: lightTextPrimary),
        bodyMedium: TextStyle(color: lightTextPrimary),
        bodySmall: TextStyle(color: lightTextSecondary),
        titleLarge: TextStyle(
          color: lightTextPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: lightTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: lightTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        labelLarge: TextStyle(
          color: lightTextPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: lightDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: lightDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: lightSecondary,
            width: 1.4,
          ),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: lightSecondary,
      ),
    );
  }

  // ===========================================================================
  // THEME DATA - DARK
  // ===========================================================================

  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: darkPrimary,
      onPrimary: Colors.white,
      secondary: darkSecondary,
      onSecondary: Colors.white,
      error: error,
      onError: Colors.white,
      surface: darkSurface,
      onSurface: darkTextPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      primaryColor: darkPrimary,
      scaffoldBackgroundColor: darkScaffoldBackground,
      canvasColor: darkCanvas,
      cardColor: darkCard,
      dividerColor: darkDivider,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: darkPrimary.withValues(alpha: 0.08),

      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: darkSurface,
        contentTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
      ),

      dividerTheme: const DividerThemeData(
        color: darkDivider,
        thickness: 1,
      ),

      cardTheme: const CardThemeData(
        color: darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: darkTextPrimary),
        bodyMedium: TextStyle(color: darkTextPrimary),
        bodySmall: TextStyle(color: darkTextSecondary),
        titleLarge: TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        labelLarge: TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: darkSecondary,
            width: 1.4,
          ),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: darkSecondary,
      ),
    );
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