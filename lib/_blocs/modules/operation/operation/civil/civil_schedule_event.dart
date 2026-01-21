// lib/_blocs/modules/operation/operation/civil/civil_schedule_event.dart
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:siged/_widgets/images/carousel/carousel_metadata.dart' as pm;

abstract class CivilScheduleEvent extends Equatable {
  const CivilScheduleEvent();
  @override
  List<Object?> get props => [];
}

class CivilWarmupRequested extends CivilScheduleEvent {
  final String contractId;
  final int? initialPage; // 0-based
  const CivilWarmupRequested(this.contractId, {this.initialPage});
}

class CivilRefreshRequested extends CivilScheduleEvent {
  const CivilRefreshRequested();
}

class CivilPageSelected extends CivilScheduleEvent {
  final int page;
  const CivilPageSelected(this.page);
  @override List<Object?> get props => [page];
}

class CivilAssetUploadRequested extends CivilScheduleEvent {
  final String filename;
  final Uint8List bytes;
  final String currentUserId;
  const CivilAssetUploadRequested({
    required this.filename,
    required this.bytes,
    required this.currentUserId,
  });
}

class CivilPolygonUpsertRequested extends CivilScheduleEvent {
  final String? polygonId;
  final int page;
  final String name;
  final String? tipo;
  final String status;
  final String? comentario;
  final double? areaM2;
  final double? perimeterM;
  final List<Map<String, double>> points;
  final int? takenAtMs;
  final String currentUserId;
  const CivilPolygonUpsertRequested({
    this.polygonId,
    required this.page,
    required this.name,
    this.tipo,
    this.status = 'a_iniciar',
    this.comentario,
    this.areaM2,
    this.perimeterM,
    required this.points,
    this.takenAtMs,
    required this.currentUserId,
  });
}

class CivilPolygonApplyRequested extends CivilScheduleEvent {
  final String polygonId;
  final String status;
  final String? comentario;
  final int? takenAtMs;
  final List<String> finalPhotoUrls;
  final List<Uint8List> newFilesBytes;
  final List<String>? newFileNames;
  final List<pm.CarouselMetadata> newPhotoMetas;
  final String currentUserId;
  const CivilPolygonApplyRequested({
    required this.polygonId,
    required this.status,
    this.comentario,
    this.takenAtMs,
    required this.finalPhotoUrls,
    required this.newFilesBytes,
    this.newFileNames,
    this.newPhotoMetas = const [],
    required this.currentUserId,
  });
}

class CivilPolygonDeleteRequested extends CivilScheduleEvent {
  final String polygonId;
  const CivilPolygonDeleteRequested(this.polygonId);
}
