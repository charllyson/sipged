import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:sisged/_widgets/schedule/schedule_lane_class.dart';

// Metadados de foto
import 'package:sisged/_blocs/widgets/carousel/carousel_metadata.dart' as pm;

abstract class ScheduleEvent extends Equatable {
  const ScheduleEvent();
  @override
  List<Object?> get props => [];
}

/// Inicializa estado com contrato e serviço inicial
class ScheduleWarmupRequested extends ScheduleEvent {
  final String contractId;
  final int totalEstacas;
  final String initialServiceKey;
  const ScheduleWarmupRequested({
    required this.contractId,
    required this.totalEstacas,
    this.initialServiceKey = 'geral',
  });

  @override
  List<Object?> get props => [contractId, totalEstacas, initialServiceKey];
}

/// Recarrega tudo (serviços, faixas, execuções)
class ScheduleRefreshRequested extends ScheduleEvent {
  const ScheduleRefreshRequested();
}

/// Seleciona um serviço
class ScheduleServiceSelected extends ScheduleEvent {
  final String serviceKey;
  const ScheduleServiceSelected(this.serviceKey);

  @override
  List<Object?> get props => [serviceKey];
}

/// Salvar faixas (e recarregar)
class ScheduleLanesSaveRequested extends ScheduleEvent {
  final List<ScheduleLaneClass> lanes;
  const ScheduleLanesSaveRequested(this.lanes);

  @override
  List<Object?> get props => [lanes];
}

/// Recarrega execuções da serviceKey atual
class ScheduleExecucoesReloadRequested extends ScheduleEvent {
  const ScheduleExecucoesReloadRequested();
}

/// Upsert célula
class ScheduleSquareUpsertRequested extends ScheduleEvent {
  final int estaca;
  final int faixaIndex;
  final String tipoLabel;
  final String status; // use ScheduleStatus.key
  final String? comentario;
  final String currentUserId;
  const ScheduleSquareUpsertRequested({
    required this.estaca,
    required this.faixaIndex,
    required this.tipoLabel,
    required this.status,
    this.comentario,
    required this.currentUserId,
  });

  @override
  List<Object?> get props =>
      [estaca, faixaIndex, tipoLabel, status, comentario, currentUserId];
}

/// Upload fotos
class ScheduleSquareUploadPhotosRequested extends ScheduleEvent {
  final int estaca;
  final int faixaIndex;
  final List<Uint8List> filesBytes;
  final List<String>? fileNames;
  final String currentUserId;

  /// Metadados EXIF alinhados com filesBytes/fileNames
  final List<pm.CarouselMetadata> photoMetas;

  /// Fallback de data (campo "Data" do modal)
  final DateTime? takenAt;

  const ScheduleSquareUploadPhotosRequested({
    required this.estaca,
    required this.faixaIndex,
    required this.filesBytes,
    this.fileNames,
    required this.currentUserId,
    this.photoMetas = const [],
    this.takenAt,
  });

  @override
  List<Object?> get props =>
      [estaca, faixaIndex, filesBytes, fileNames, currentUserId, photoMetas, takenAt];
}

/// Remover foto específica
class ScheduleSquareDeletePhotoRequested extends ScheduleEvent {
  final int estaca;
  final int faixaIndex;
  final String photoUrl;
  final String currentUserId;
  const ScheduleSquareDeletePhotoRequested({
    required this.estaca,
    required this.faixaIndex,
    required this.photoUrl,
    required this.currentUserId,
  });

  @override
  List<Object?> get props => [estaca, faixaIndex, photoUrl, currentUserId];
}

/// Substituir lista de fotos
class ScheduleSquareSetPhotosRequested extends ScheduleEvent {
  final int estaca;
  final int faixaIndex;
  final List<String> photoUrls;
  final String currentUserId;
  const ScheduleSquareSetPhotosRequested({
    required this.estaca,
    required this.faixaIndex,
    required this.photoUrls,
    required this.currentUserId,
  });

  @override
  List<Object?> get props => [estaca, faixaIndex, photoUrls, currentUserId];
}
