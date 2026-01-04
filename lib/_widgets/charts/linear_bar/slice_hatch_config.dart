// lib/_widgets/charts/linear_bar/slice_hatch_config.dart
import 'package:flutter/material.dart';

/// Config de hatch para UMA fatia.
class SliceHatchStyle {
  /// Cor das linhas (hachura).
  final Color lineColor;

  /// Opacidade aplicada ao fundo (baseada na própria lineColor).
  /// Ex: 0.18 => fundo bem leve, combina com a fatia.
  final double backgroundOpacity;

  /// Espessura das linhas.
  final double strokeWidth;

  /// Espaçamento entre linhas.
  final double spacing;

  const SliceHatchStyle({
    required this.lineColor,
    this.backgroundOpacity = 0.18,
    this.strokeWidth = 2,
    this.spacing = 10.0,
  });

  Color backgroundColor() => lineColor.withOpacity(backgroundOpacity);
}

/// Resolver hatch por fatia (por índice e/ou label).
class SliceHatchConfig {
  /// Hatch por índice da fatia.
  final Map<int, SliceHatchStyle> byIndex;

  /// Hatch por label da fatia (normalizado: trim + lower).
  final Map<String, SliceHatchStyle> byLabel;

  const SliceHatchConfig({
    this.byIndex = const {},
    this.byLabel = const {},
  });

  bool get isEnabled => byIndex.isNotEmpty || byLabel.isNotEmpty;

  SliceHatchStyle? resolve({
    required int sliceIndex,
    required String? sliceLabel,
  }) {
    final byI = byIndex[sliceIndex];
    if (byI != null) return byI;

    final normalized = (sliceLabel ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return null;

    return byLabel[normalized];
  }
}
