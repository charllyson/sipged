import 'package:flutter/material.dart';

@immutable
class LayerActionVisual {
  final bool hasData;
  final IconData icon;
  final String tooltip;

  const LayerActionVisual({
    required this.hasData,
    required this.icon,
    required this.tooltip,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LayerActionVisual &&
            other.hasData == hasData &&
            other.icon == icon &&
            other.tooltip == tooltip);
  }

  @override
  int get hashCode => Object.hash(hasData, icon, tooltip);
}