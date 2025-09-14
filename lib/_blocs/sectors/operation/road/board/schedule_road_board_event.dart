// lib/_blocs/sectors/operation/road/board/schedule_road_board_event.dart
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:siged/_blocs/sectors/operation/road/board/schedule_road_board_data.dart';
import 'package:siged/_blocs/sectors/operation/road/map/schedule_road_map_data.dart';
import 'package:siged/_widgets/schedule/linear/schedule_lane_class.dart';
import 'package:siged/_blocs/widgets/carousel/carousel_metadata.dart' as pm;

abstract class ScheduleRoadBoardEvent extends Equatable {
  const ScheduleRoadBoardEvent();
  @override
  List<Object?> get props => [];
}

/// Inicializa estado com contrato e serviço inicial.
/// totalEstacas é opcional: se houver geometria, será recalculado pelos 20 m.
class ScheduleWarmupRequested extends ScheduleRoadBoardEvent {
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

/// Recarrega tudo (serviços, faixas, execuções + geometria)
class ScheduleRefreshRequested extends ScheduleRoadBoardEvent {
  const ScheduleRefreshRequested();
}

/// Seleciona um serviço
class ScheduleServiceSelected extends ScheduleRoadBoardEvent {
  final String serviceKey;
  const ScheduleServiceSelected(this.serviceKey);
  @override
  List<Object?> get props => [serviceKey];
}

/// Salvar faixas (e recarregar)
class ScheduleLanesSaveRequested extends ScheduleRoadBoardEvent {
  final List<ScheduleLaneClass> lanes;
  const ScheduleLanesSaveRequested(this.lanes);
  @override
  List<Object?> get props => [lanes];
}

/// Recarrega execuções da serviceKey atual
class ScheduleExecucoesReloadRequested extends ScheduleRoadBoardEvent {
  const ScheduleExecucoesReloadRequested();
}

/// ========================== MAPA (agora no Board) ==========================

/// Importa GeoJSON e salva geometria (na mesma infra do repositório do Board)
class ScheduleProjectImportGeoJsonRequested extends ScheduleRoadBoardEvent {
  final Map<String, dynamic> geojson;
  final String? summarySubjectContract;
  const ScheduleProjectImportGeoJsonRequested(
      this.geojson, {
        this.summarySubjectContract,
      });
  @override
  List<Object?> get props => [geojson, summarySubjectContract];
}

/// Upsert direto (caso já tenha ScheduleRoadMapData pronto)
class ScheduleProjectUpsertRequested extends ScheduleRoadBoardEvent {
  final ScheduleRoadBoardData data;
  const ScheduleProjectUpsertRequested(this.data);
  @override
  List<Object?> get props => [data];
}

/// Excluir traçado
class ScheduleProjectDeleteRequested extends ScheduleRoadBoardEvent {
  const ScheduleProjectDeleteRequested();
}

/// Seleção de polyline no mapa (tag arbitrária)
class SchedulePolylineSelected extends ScheduleRoadBoardEvent {
  final String? polylineId;
  const SchedulePolylineSelected(this.polylineId);
  @override
  List<Object?> get props => [polylineId];
}

/// Mudança de zoom (normalizado no BLoC)
class ScheduleMapZoomChanged extends ScheduleRoadBoardEvent {
  final double zoom;
  const ScheduleMapZoomChanged(this.zoom);
  @override
  List<Object?> get props => [zoom];
}

/// ---------------------------------------------------------------------------
/// AÇÃO ÚNICA: Aplicar (status/comentário/data + novos uploads + exclusões + ordenação)
/// ---------------------------------------------------------------------------
class ScheduleSquareApplyRequested extends ScheduleRoadBoardEvent {
  final int estaca;
  final int faixaIndex;

  // Metadados de célula
  final String tipoLabel;
  final String status;        // 'concluido' | 'em_andamento' | 'a_iniciar'
  final String? comentario;   // null = limpar
  final DateTime? takenAt;    // data do modal (fallback p/ novas fotos)

  // Fotos
  final List<String> finalPhotoUrls;                 // ordem final sem as novas
  final List<Uint8List> newFilesBytes;               // novas fotos (0..n)
  final List<String>? newFileNames;                  // nomes das novas (opcional)
  final List<pm.CarouselMetadata> newPhotoMetas;     // metas das novas (opcional)

  // Usuário
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
