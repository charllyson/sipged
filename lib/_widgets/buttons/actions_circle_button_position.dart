
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
    double left = 30,
    double bottom = 30,
  })  : left = left,
        right = null,
        top = null,
        bottom = bottom,
        alignment = Alignment.bottomLeft,
        crossAxis = CrossAxisAlignment.start;

  const ActionsCircleButtonPosition.bottomRight({
    double right = 30,
    double bottom = 30,
  })  : left = null,
        right = right,
        top = null,
        bottom = bottom,
        alignment = Alignment.bottomRight,
        crossAxis = CrossAxisAlignment.end;

  const ActionsCircleButtonPosition.topLeft({
    double left = 30,
    double top = 30,
  })  : left = left,
        right = null,
        top = top,
        bottom = null,
        alignment = Alignment.topLeft,
        crossAxis = CrossAxisAlignment.start;

  const ActionsCircleButtonPosition.topRight({
    double right = 30,
    double top = 30,
  })  : left = null,
        right = right,
        top = top,
        bottom = null,
        alignment = Alignment.topRight,
        crossAxis = CrossAxisAlignment.end;
}
