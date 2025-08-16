import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class TappableChangedPolyline {
  final List<LatLng> points;
  final dynamic tag;
  final bool isDotted;
  final Color color;
  final Color? defaultColor; // novo campo
  final double strokeWidth;

  TappableChangedPolyline({
    required this.points,
    required this.tag,
    required this.color,
    this.defaultColor,
    required this.strokeWidth,
    this.isDotted = false,
  });

  TappableChangedPolyline copyWith({
    List<LatLng>? points,
    dynamic tag,
    bool? isDotted,
    Color? color,
    double? strokeWidth,
    Color? defaultColor,
  }) {
    return TappableChangedPolyline(
      points: points ?? this.points,
      tag: tag ?? this.tag,
      isDotted: isDotted ?? this.isDotted,
      color: color ?? this.color,
      defaultColor: defaultColor ?? this.defaultColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }


  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TappableChangedPolyline &&
        other.tag == tag &&
        _listEquals(other.points, points);
  }

  @override
  int get hashCode => Object.hash(
    tag,
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
