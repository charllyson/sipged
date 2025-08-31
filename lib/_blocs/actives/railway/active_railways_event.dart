import 'package:equatable/equatable.dart';

import 'active_railway_data.dart';

abstract class ActiveRailwaysEvent extends Equatable {
  const ActiveRailwaysEvent();
  @override
  List<Object?> get props => [];
}

// ---------- Loaders ----------
class ActiveRailwaysWarmupRequested extends ActiveRailwaysEvent {
  const ActiveRailwaysWarmupRequested();
}
class ActiveRailwaysRefreshRequested extends ActiveRailwaysEvent {
  const ActiveRailwaysRefreshRequested();
}

// ---------- Seleção / Filtros ----------
class ActiveRailwaysSelectPolyline extends ActiveRailwaysEvent {
  final String? polylineId;
  const ActiveRailwaysSelectPolyline(this.polylineId);
  @override
  List<Object?> get props => [polylineId];
}

class ActiveRailwaysRegionFilterChanged extends ActiveRailwaysEvent {
  final String? region;
  const ActiveRailwaysRegionFilterChanged(this.region);
  @override
  List<Object?> get props => [region];
}

class ActiveRailwaysStatusFilterChanged extends ActiveRailwaysEvent {
  final String? statusCode;
  const ActiveRailwaysStatusFilterChanged(this.statusCode);
  @override
  List<Object?> get props => [statusCode];
}

class ActiveRailwaysPieFilterChanged extends ActiveRailwaysEvent {
  final int? pieIndex;
  const ActiveRailwaysPieFilterChanged(this.pieIndex);
  @override
  List<Object?> get props => [pieIndex];
}

// ---------- CRUD / Import ----------
class ActiveRailwaysUpsertRequested extends ActiveRailwaysEvent {
  final ActiveRailwayData data;
  const ActiveRailwaysUpsertRequested(this.data);
  @override
  List<Object?> get props => [data];
}

class ActiveRailwaysDeleteRequested extends ActiveRailwaysEvent {
  final String id;
  const ActiveRailwaysDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class ActiveRailwaysImportBatchRequested extends ActiveRailwaysEvent {
  final List<Map<String, dynamic>> linhasPrincipais;
  final List<Map<String, dynamic>> geometrias; // {geometryType, points: [...]}
  const ActiveRailwaysImportBatchRequested({
    required this.linhasPrincipais,
    required this.geometrias,
  });
  @override
  List<Object?> get props => [linhasPrincipais, geometrias];
}

// ---------- Mapa (Zoom) ----------
class ActiveRailwaysMapZoomChanged extends ActiveRailwaysEvent {
  final double zoom;
  const ActiveRailwaysMapZoomChanged(this.zoom);

  @override
  List<Object?> get props => [zoom];
}
