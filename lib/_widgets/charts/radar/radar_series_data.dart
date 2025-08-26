import 'dart:ui';

class RadarSeriesData {
  final String name;
  final List<double> values;
  final Color color;

  const RadarSeriesData({
    required this.name,
    required this.values,
    required this.color,
  });
}