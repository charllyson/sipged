import 'package:flutter/material.dart';

enum GeoWorkspaceSnapEdge {
  left,
  centerX,
  right,
  top,
  centerY,
  bottom,
}

enum GeoWorkspaceResizeHandle {
  left,
  right,
  top,
  bottom,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class GeoWorkspaceGuideLines {
  final double? vertical;
  final double? horizontal;

  const GeoWorkspaceGuideLines({
    this.vertical,
    this.horizontal,
  });
}

class GeoWorkspaceResolvedRect {
  final Rect rect;
  final GeoWorkspaceGuideLines? guides;

  const GeoWorkspaceResolvedRect({
    required this.rect,
    required this.guides,
  });
}