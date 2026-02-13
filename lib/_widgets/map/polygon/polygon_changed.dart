// lib/_widgets/map/polygon/polygon_changed.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Modelo de polígono genérico com ESTILO COMPLETO:
/// - estado normal
/// - estado selecionado
///
/// O MapInteractivePage não sabe nada de SIGMINE/IBGE/etc.
/// Ele só lê essas infos e desenha.
class PolygonChanged {
  final Polygon polygon;

  /// Chave usada para seleção (ex.: processo, nome do município, etc).
  final String title;

  /// Propriedades extras (idIbge, processo, minério, etc.).
  ///
  /// chamadas existentes (IBGE, SIGMINE, etc.).
  final List<dynamic>? properties;

  /// Mapa opcional de cores para ser usado em legendas externas.
  /// (não é usado pelo MapInteractivePage; fica à disposição do chamador).
  final Map<String, Color>? mapColors;

  // ======== ESTILO NORMAL ========
  final Color normalFillColor;
  final Color normalBorderColor;
  final double normalBorderWidth;

  // ======== ESTILO SELECIONADO ========
  final Color selectedFillColor;
  final Color selectedBorderColor;
  final double selectedBorderWidth;

  const PolygonChanged({
    required this.polygon,
    required this.title,
    this.properties,
    this.mapColors,

    // Normal
    this.normalFillColor = const Color(0x08000000),
    this.normalBorderColor = const Color(0xFF777777),
    this.normalBorderWidth = 1.0,

    // Selecionado
    this.selectedFillColor = const Color(0x5533AAFF),
    this.selectedBorderColor = const Color(0xFF000000),
    this.selectedBorderWidth = 1.0,
  }) : assert(normalBorderWidth >= 0),
        assert(selectedBorderWidth >= 0);

  PolygonChanged copyWith({
    Polygon? polygon,
    String? title,
    List<dynamic>? properties,
    Map<String, Color>? mapColors,
    Color? normalFillColor,
    Color? normalBorderColor,
    double? normalBorderWidth,
    Color? selectedFillColor,
    Color? selectedBorderColor,
    double? selectedBorderWidth,
  }) {
    return PolygonChanged(
      polygon: polygon ?? this.polygon,
      title: title ?? this.title,
      properties: properties ?? this.properties,
      mapColors: mapColors ?? this.mapColors,
      normalFillColor: normalFillColor ?? this.normalFillColor,
      normalBorderColor: normalBorderColor ?? this.normalBorderColor,
      normalBorderWidth: normalBorderWidth ?? this.normalBorderWidth,
      selectedFillColor: selectedFillColor ?? this.selectedFillColor,
      selectedBorderColor: selectedBorderColor ?? this.selectedBorderColor,
      selectedBorderWidth: selectedBorderWidth ?? this.selectedBorderWidth,
    );
  }
}
