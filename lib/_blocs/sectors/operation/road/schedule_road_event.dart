// COMPLETO — acrescido dos eventos do PHYS/FIN

import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_data.dart';
import 'package:siged/_widgets/schedule/linear/schedule_lane_class.dart';
import 'package:siged/_widgets/images/carousel/carousel_metadata.dart' as pm;

abstract class ScheduleRoadEvent extends Equatable {
  const ScheduleRoadEvent();
  @override
  List<Object?> get props => [];
}

class ScheduleWarmupRequested extends ScheduleRoadEvent {
  final String contractId;
  final int? totalEstacas;
  final String initialServiceKey;
  final String? summarySubjectContract;
  const ScheduleWarmupRequested({
    required this.contractId,
    this.totalEstacas,
    this.initialServiceKey = 'geral',
    this.summarySubjectContract,
  });
  @override
  List<Object?> get props =>
      [contractId, totalEstacas, initialServiceKey, summarySubjectContract];
}

class ScheduleRefreshRequested extends ScheduleRoadEvent {
  const ScheduleRefreshRequested();
}

class ScheduleServiceSelected extends ScheduleRoadEvent {
  final String serviceKey;
  const ScheduleServiceSelected(this.serviceKey);
  @override
  List<Object?> get props => [serviceKey];
}

class ScheduleLanesSaveRequested extends ScheduleRoadEvent {
  final List<ScheduleLaneClass> lanes;
  const ScheduleLanesSaveRequested(this.lanes);
  @override
  List<Object?> get props => [lanes];
}

class ScheduleExecucoesReloadRequested extends ScheduleRoadEvent {
  const ScheduleExecucoesReloadRequested();
}

// ====== MAPA ======
class ScheduleProjectImportGeoJsonRequested extends ScheduleRoadEvent {
  final Map<String, dynamic> geojson;
  final String? summarySubjectContract;
  const ScheduleProjectImportGeoJsonRequested(this.geojson, {this.summarySubjectContract});
  @override
  List<Object?> get props => [geojson, summarySubjectContract];
}

class ScheduleProjectUpsertRequested extends ScheduleRoadEvent {
  final ScheduleRoadData data;
  const ScheduleProjectUpsertRequested(this.data);
  @override
  List<Object?> get props => [data];
}

class ScheduleProjectDeleteRequested extends ScheduleRoadEvent {
  const ScheduleProjectDeleteRequested();
}

class SchedulePolylineSelected extends ScheduleRoadEvent {
  final String? polylineId;
  const SchedulePolylineSelected(this.polylineId);
  @override
  List<Object?> get props => [polylineId];
}

class ScheduleMapZoomChanged extends ScheduleRoadEvent {
  final double zoom;
  const ScheduleMapZoomChanged(this.zoom);
  @override
  List<Object?> get props => [zoom];
}

// ====== AÇÃO ÚNICA ======
class ScheduleSquareApplyRequested extends ScheduleRoadEvent {
  final int estaca;
  final int faixaIndex;

  final String tipoLabel;
  final String status;
  final String? comentario;
  final DateTime? takenAt;

  final List<String> finalPhotoUrls;
  final List<Uint8List> newFilesBytes;
  final List<String>? newFileNames;
  final List<pm.CarouselMetadata> newPhotoMetas;

  final String currentUserId;

  const ScheduleSquareApplyRequested({
    required this.estaca,
    required this.faixaIndex,
    required this.tipoLabel,
    required this.status,
    this.comentario,
    this.takenAt,
    required this.finalPhotoUrls,
    required this.newFilesBytes,
    this.newFileNames,
    this.newPhotoMetas = const [],
    required this.currentUserId,
  });

  @override
  List<Object?> get props => [
    estaca,
    faixaIndex,
    tipoLabel,
    status,
    comentario,
    takenAt,
    finalPhotoUrls,
    newFilesBytes,
    newFileNames,
    newPhotoMetas,
    currentUserId,
  ];
}

// ====== PHYS/FIN (períodos + grade) ======

/// Dispara salvamento da grade no Firestore (usado pela tela ao alterar um percentual).
class PhysFinGridUpdateRequested extends ScheduleRoadEvent {
  final List<int> periods;
  final Map<String, List<double>> grid; // serviceKey -> [%, %, ...]
  final String? updatedBy;
  const PhysFinGridUpdateRequested({
    required this.periods,
    required this.grid,
    this.updatedBy,
  });

  @override
  List<Object?> get props => [periods, grid, updatedBy];
}
