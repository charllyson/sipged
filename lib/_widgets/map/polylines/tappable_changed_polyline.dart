import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class TappableChangedPolyline {
  final List<LatLng> points;
  final dynamic tag;
  final bool isDotted;
  final Color color;
  final Color? defaultColor;
  final double strokeWidth;

  /// 🔹 Se `false`, essa polyline não participa do hit-test (não “clica”)
  final bool hitTestable;

  TappableChangedPolyline({
    required this.points,
    required this.tag,
    required this.color,
    this.defaultColor,
    required this.strokeWidth,
    this.isDotted = false,
    this.hitTestable = true, // default: clicável
  });

  TappableChangedPolyline copyWith({
    List<LatLng>? points,
    dynamic tag,
    bool? isDotted,
    Color? color,
    double? strokeWidth,
    Color? defaultColor,
    bool? hitTestable,
  }) {
    return TappableChangedPolyline(
      points: points ?? this.points,
      tag: tag ?? this.tag,
      isDotted: isDotted ?? this.isDotted,
      color: color ?? this.color,
      defaultColor: defaultColor ?? this.defaultColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      hitTestable: hitTestable ?? this.hitTestable,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TappableChangedPolyline &&
        other.tag == tag &&
        other.isDotted == isDotted &&
        other.color == color &&
        other.defaultColor == defaultColor &&
        other.strokeWidth == strokeWidth &&
        other.hitTestable == hitTestable &&
        _listEquals(other.points, points);
  }

  @override
  int get hashCode => Object.hash(
    tag,
    isDotted,
    color,
    defaultColor,
    strokeWidth,
    hitTestable,
    Object.hashAll(points.map((p) => Object.hash(p.latitude, p.longitude))),
  );

  bool _listEquals(List<LatLng> a, List<LatLng> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].latitude != b[i].latitude || a[i].longitude != b[i].longitude) {
        return false;
      }
    }
    return true;
  }
}
