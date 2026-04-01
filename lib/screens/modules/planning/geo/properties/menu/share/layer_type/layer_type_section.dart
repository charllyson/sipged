import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';

enum LayerTypeUsageContext {
  symbology,
  labels,
}

class LayerTypeOption {
  final String label;
  final LayerSimpleSymbolType type;

  const LayerTypeOption({
    required this.label,
    required this.type,
  });
}

class LayerTypeSection {
  LayerTypeSection._();

  static const LayerTypeOption _textOption = LayerTypeOption(
    label: 'Camada de Texto',
    type: LayerSimpleSymbolType.textLayer,
  );

  static const LayerTypeOption _svgOption = LayerTypeOption(
    label: 'Camada de Ícone',
    type: LayerSimpleSymbolType.svgMarker,
  );

  static const LayerTypeOption _shapeOption = LayerTypeOption(
    label: 'Camada de Geometria',
    type: LayerSimpleSymbolType.simpleMarker,
  );

  static List<String> itemsForGeometry(
      LayerGeometryKind geometryKind, {
        LayerTypeUsageContext context = LayerTypeUsageContext.symbology,
      }) {
    return optionsForGeometry(
      geometryKind,
      context: context,
    ).map((e) => e.label).toList(growable: false);
  }

  static List<LayerTypeOption> optionsForGeometry(
      LayerGeometryKind geometryKind, {
        LayerTypeUsageContext context = LayerTypeUsageContext.symbology,
      }) {
    if (context == LayerTypeUsageContext.labels) {
      return const [
        _textOption,
        _svgOption,
        _shapeOption,
      ];
    }

    switch (geometryKind) {
      case LayerGeometryKind.point:
      case LayerGeometryKind.mixed:
      case LayerGeometryKind.unknown:
        return const [
          _textOption,
          _svgOption,
          _shapeOption,
        ];

      case LayerGeometryKind.line:
      case LayerGeometryKind.polygon:
        return const [
          _shapeOption,
        ];
    }
  }

  static String labelFromType(LayerSimpleSymbolType type) {
    switch (type) {
      case LayerSimpleSymbolType.textLayer:
        return _textOption.label;
      case LayerSimpleSymbolType.svgMarker:
        return _svgOption.label;
      case LayerSimpleSymbolType.simpleMarker:
        return _shapeOption.label;
    }
  }

  static LayerSimpleSymbolType typeFromLabel(String? label) {
    final normalized = (label ?? '').trim().toLowerCase();

    if (normalized == _textOption.label.toLowerCase()) {
      return LayerSimpleSymbolType.textLayer;
    }

    if (normalized == _svgOption.label.toLowerCase()) {
      return LayerSimpleSymbolType.svgMarker;
    }

    return LayerSimpleSymbolType.simpleMarker;
  }

  static bool supportsSvg(
      LayerGeometryKind geometryKind, {
        LayerTypeUsageContext context = LayerTypeUsageContext.symbology,
      }) {
    return optionsForGeometry(
      geometryKind,
      context: context,
    ).any((e) => e.type == LayerSimpleSymbolType.svgMarker);
  }

  static bool supportsText(
      LayerGeometryKind geometryKind, {
        LayerTypeUsageContext context = LayerTypeUsageContext.symbology,
      }) {
    return optionsForGeometry(
      geometryKind,
      context: context,
    ).any((e) => e.type == LayerSimpleSymbolType.textLayer);
  }

  static bool supportsSimpleMarker(
      LayerGeometryKind geometryKind, {
        LayerTypeUsageContext context = LayerTypeUsageContext.symbology,
      }) {
    return optionsForGeometry(
      geometryKind,
      context: context,
    ).any((e) => e.type == LayerSimpleSymbolType.simpleMarker);
  }

  static IconData iconForType(LayerSimpleSymbolType type) {
    switch (type) {
      case LayerSimpleSymbolType.textLayer:
        return Icons.text_fields;
      case LayerSimpleSymbolType.svgMarker:
        return Icons.place_outlined;
      case LayerSimpleSymbolType.simpleMarker:
        return Icons.category_outlined;
    }
  }
}