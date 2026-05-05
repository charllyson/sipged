// lib/_blocs/modules/operation/operation/civil/civil_schedule_state.dart
import 'package:equatable/equatable.dart';

class CivilScheduleState extends Equatable {
  final bool initialized;
  final String? contractId;

  final int currentPage;
  final Map<String, dynamic> boardMeta; // page_count, dxf_bounds, ...
  final Map<String, dynamic> assets;    // pdf_url, dxf_url

  final bool loadingMeta;
  final bool loadingPolygons;
  final bool uploadingAsset;
  final bool applyingPolygon;

  final List<Map<String, dynamic>> polygons; // [{id, name, page, status, points, ...}]
  final String? error;

  const CivilScheduleState({
    this.initialized = false,
    this.contractId,
    this.currentPage = 0,
    this.boardMeta = const {},
    this.assets = const {},
    this.loadingMeta = false,
    this.loadingPolygons = false,
    this.uploadingAsset = false,
    this.applyingPolygon = false,
    this.polygons = const [],
    this.error,
  });

  CivilScheduleState copyWith({
    bool? initialized,
    String? contractId,
    int? currentPage,
    Map<String, dynamic>? boardMeta,
    Map<String, dynamic>? assets,
    bool? loadingMeta,
    bool? loadingPolygons,
    bool? uploadingAsset,
    bool? applyingPolygon,
    List<Map<String, dynamic>>? polygons,
    String? error,
  }) {
    return CivilScheduleState(
      initialized: initialized ?? this.initialized,
      contractId: contractId ?? this.contractId,
      currentPage: currentPage ?? this.currentPage,
      boardMeta: boardMeta ?? this.boardMeta,
      assets: assets ?? this.assets,
      loadingMeta: loadingMeta ?? this.loadingMeta,
      loadingPolygons: loadingPolygons ?? this.loadingPolygons,
      uploadingAsset: uploadingAsset ?? this.uploadingAsset,
      applyingPolygon: applyingPolygon ?? this.applyingPolygon,
      polygons: polygons ?? this.polygons,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    initialized, contractId, currentPage, boardMeta, assets,
    loadingMeta, loadingPolygons, uploadingAsset, applyingPolygon,
    polygons, error,
  ];
}
