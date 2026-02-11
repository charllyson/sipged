import 'package:latlong2/latlong.dart';

/// Representa um marcador (ponto) no mapa, com dados associados como propriedades.
class TaggedChangedMarker<T> {
  /// Coordenada geográfica do marcador.
  final LatLng point;

  /// Propriedades associadas ao ponto, como dados de identificação ou metadados.
  final Map<String, dynamic> properties;

  final T data;

  /// Cria um marcador com ponto geográfico e propriedades associadas.
  const TaggedChangedMarker({
    required this.point,
    required this.properties,
    required this.data,
  });

  /// Retorna uma nova instância de [TaggedChangedMarker] com valores atualizados.
  TaggedChangedMarker copyWith({
    LatLng? point,
    Map<String, dynamic>? properties,
  }) {
    return TaggedChangedMarker(
      point: point ?? this.point,
      properties: properties ?? this.properties,
      data: data,
    );
  }
}
