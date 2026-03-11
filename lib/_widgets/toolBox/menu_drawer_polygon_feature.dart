import 'dart:ui';

class MenuDrawerPolygonFeature {
  final List<Offset> points; // coordenadas no espaço da imagem (px)
  final String name;
  final Offset centroid;

  const MenuDrawerPolygonFeature({
    required this.points,
    required this.name,
    required this.centroid,
  });

  MenuDrawerPolygonFeature copyWith({
    List<Offset>? points,
    String? name,
    Offset? centroid,
  }) {
    return MenuDrawerPolygonFeature(
      points: points ?? this.points,
      name: name ?? this.name,
      centroid: centroid ?? this.centroid,
    );
  }
}
