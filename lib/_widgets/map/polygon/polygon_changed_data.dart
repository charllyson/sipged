import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Modelo imutável de polígono com estilo normal e selecionado.
class PolygonChangedData {
  final Polygon polygon;
  final String title;
  final List<dynamic>? properties;
  final Map<String, Color>? mapColors;

  // Estilo normal
  final Color normalFillColor;
  final Color normalBorderColor;
  final double normalBorderWidth;

  // Estilo selecionado
  final Color selectedFillColor;
  final Color selectedBorderColor;
  final double selectedBorderWidth;

  const PolygonChangedData({
    required this.polygon,
    required this.title,
    this.properties,
    this.mapColors,
    this.normalFillColor = const Color(0x08000000),
    this.normalBorderColor = const Color(0xFF777777),
    this.normalBorderWidth = 1.0,
    this.selectedFillColor = const Color(0x5533AAFF),
    this.selectedBorderColor = const Color(0xFF000000),
    this.selectedBorderWidth = 1.0,
  })  : assert(normalBorderWidth >= 0),
        assert(selectedBorderWidth >= 0);

  PolygonChangedData copyWith({
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
    return PolygonChangedData(
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