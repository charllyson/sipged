import 'dart:ui';

class PolygonFeature {
  final List<Offset> points; // coordenadas no espaço da imagem (px)
  final String name;
  final Offset centroid;

  const PolygonFeature({
    required this.points,
    required this.name,
    required this.centroid,
  });

  PolygonFeature copyWith({
    List<Offset>? points,
    String? name,
    Offset? centroid,
  }) {
    return PolygonFeature(
      points: points ?? this.points,
      name: name ?? this.name,
      centroid: centroid ?? this.centroid,
    );
  }
}
