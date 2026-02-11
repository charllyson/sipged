
import 'package:flutter/material.dart';

/// Helper para posicionamento flexível (cantos)
class ActionsCircleButtonPosition {
  final double? left, right, top, bottom;
  final Alignment alignment;
  final CrossAxisAlignment crossAxis;

  const ActionsCircleButtonPosition({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.alignment,
    required this.crossAxis,
  });

  const ActionsCircleButtonPosition.bottomLeft({
    double this.left = 30,
    double this.bottom = 30,
  })  : right = null,
        top = null,
        alignment = Alignment.bottomLeft,
        crossAxis = CrossAxisAlignment.start;

  const ActionsCircleButtonPosition.bottomRight({
    double this.right = 30,
    double this.bottom = 30,
  })  : left = null,
        top = null,
        alignment = Alignment.bottomRight,
        crossAxis = CrossAxisAlignment.end;

  const ActionsCircleButtonPosition.topLeft({
    double this.left = 30,
    double this.top = 30,
  })  : right = null,
        bottom = null,
        alignment = Alignment.topLeft,
        crossAxis = CrossAxisAlignment.start;

  const ActionsCircleButtonPosition.topRight({
    double this.right = 30,
    double this.top = 30,
  })  : left = null,
        bottom = null,
        alignment = Alignment.topRight,
        crossAxis = CrossAxisAlignment.end;
}
