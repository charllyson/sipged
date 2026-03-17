import 'package:latlong2/latlong.dart';

/// Representa um marcador tipado do mapa com:
/// - posição geográfica
/// - propriedades auxiliares
/// - dado fortemente tipado associado
///
/// Exemplo de uso:
/// - `data`: objeto completo do registro
/// - `properties`: label, id, categoria, etc.
class MarkerChangedData<T> {
  /// Coordenada geográfica do marcador.
  final LatLng point;

  /// Propriedades auxiliares associadas ao marcador.
  ///
  /// Normalmente usadas para:
  /// - label
  /// - id
  /// - categoria
  /// - metadados de exibição
  final Map<String, dynamic> properties;

  /// Objeto principal associado ao marker.
  final T data;

  const MarkerChangedData({
    required this.point,
    required this.properties,
    required this.data,
  });

  /// Retorna uma nova instância preservando imutabilidade.
  MarkerChangedData<T> copyWith({
    LatLng? point,
    Map<String, dynamic>? properties,
    T? data,
  }) {
    return MarkerChangedData<T>(
      point: point ?? this.point,
      properties: properties ?? this.properties,
      data: data ?? this.data,
    );
  }

  @override
  String toString() {
    return 'MarkerChanged<$T>('
        'point: $point, '
        'properties: $properties, '
        'data: $data'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MarkerChangedData<T> &&
        other.point.latitude == point.latitude &&
        other.point.longitude == point.longitude &&
        _mapEquals(other.properties, properties) &&
        other.data == data;
  }

  @override
  int get hashCode {
    return Object.hash(
      point.latitude,
      point.longitude,
      Object.hashAll(
        properties.entries.map((e) => Object.hash(e.key, e.value)),
      ),
      data,
    );
  }

  static bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;

    for (final entry in a.entries) {
      if (!b.containsKey(entry.key)) return false;
      if (b[entry.key] != entry.value) return false;
    }

    return true;
  }
}