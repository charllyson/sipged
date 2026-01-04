import 'package:equatable/equatable.dart';
import 'package:siged/_widgets/map/polylines/tappable_changed_polyline.dart';

import 'osm_road_data.dart';

class OSMRoadsState extends Equatable {
  final bool isLoading;
  final String? error;

  /// Dados brutos recebidos (não simplificados)
  final List<RoadGeometry> rawRoads;

  /// Polylines já convertidas para o mapa
  final List<TappableChangedPolyline> polylines;

  /// UF atualmente carregada (ex.: "AL")
  final String? uf;

  /// Filtro de tipo de rodovia
  final RodoviaTipo filtro;

  const OSMRoadsState({
    required this.isLoading,
    required this.error,
    required this.rawRoads,
    required this.polylines,
    required this.uf,
    required this.filtro,
  });

  // ---------------------------------------------------------------------------
  // ESTADO INICIAL
  // ---------------------------------------------------------------------------
  factory OSMRoadsState.initial() => const OSMRoadsState(
    isLoading: false,
    error: null,
    rawRoads: [],
    polylines: [],
    uf: null,
    filtro: RodoviaTipo.todas,
  );

  // ---------------------------------------------------------------------------
  // COPY WITH
  // ---------------------------------------------------------------------------
  OSMRoadsState copyWith({
    bool? isLoading,
    String? error,
    List<RoadGeometry>? rawRoads,
    List<TappableChangedPolyline>? polylines,
    String? uf,
    RodoviaTipo? filtro,
    bool clearError = false,
  }) {
    return OSMRoadsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      rawRoads: rawRoads ?? this.rawRoads,
      polylines: polylines ?? this.polylines,
      uf: uf ?? this.uf,
      filtro: filtro ?? this.filtro,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    error,
    rawRoads,
    polylines,
    uf,
    filtro,
  ];
}
