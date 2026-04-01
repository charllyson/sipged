import 'package:flutter/material.dart';
import 'package:sipged/_widgets/draw/shapes/shapes_catalog.dart';

@immutable
class ShapeData {
  final LayerShapeType value;
  final String label;

  const ShapeData({
    required this.value,
    required this.label,
  });
}