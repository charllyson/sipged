import 'dart:math' as math;

class GeometryCell {
  final double x, y, h, d;
  double get max => d + h * math.sqrt2;
  GeometryCell(this.x, this.y, this.h, this.d);
}
