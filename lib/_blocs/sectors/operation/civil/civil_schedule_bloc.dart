// lib/_blocs/sectors/operation/civil/civil_schedule_bloc.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'civil_schedule_event.dart';
import 'civil_schedule_state.dart';
import 'civil_schedule_repository.dart';

class CivilScheduleBloc extends Bloc<CivilScheduleEvent, CivilScheduleState> {
  final CivilScheduleRepository repo;

  CivilScheduleBloc({CivilScheduleRepository? repository})
      : repo = repository ?? CivilScheduleRepository(),
        super(const CivilScheduleState()) {
    on<CivilWarmupRequested>(_onWarmup);
    on<CivilRefreshRequested>(_onRefresh);
    on<CivilPageSelected>(_onPage);
    on<CivilAssetUploadRequested>(_onUploadAsset);
    on<CivilPolygonUpsertRequested>(_onUpsertPolygon);
    on<CivilPolygonApplyRequested>(_onApplyPolygon);
    on<CivilPolygonDeleteRequested>(_onDeletePolygon);
  }

  Future<void> _loadAll(String cid, int page, Emitter<CivilScheduleState> emit) async {
    emit(state.copyWith(loadingMeta: true, loadingPolygons: true, error: null));
    try {
      final meta = await repo.loadBoardMeta(cid);
      final assets = await repo.loadAssets(cid);
      final polys = await repo.fetchPolygons(contractId: cid, page: page);
      emit(state.copyWith(
        boardMeta: meta,
        assets: assets,
        polygons: polys,
        loadingMeta: false,
        loadingPolygons: false,
        error: null,
      ));
    } catch (err, st) {
      emit(state.copyWith(loadingMeta: false, loadingPolygons: false, error: '$err'));
    }
  }

  Future<void> _onWarmup(CivilWarmupRequested e, Emitter<CivilScheduleState> emit) async {
    emit(state.copyWith(
      initialized: true,
      contractId: e.contractId,
      currentPage: e.initialPage ?? 0,
      error: null,
    ));
    await _loadAll(e.contractId, e.initialPage ?? 0, emit);
  }

  Future<void> _onRefresh(CivilRefreshRequested e, Emitter<CivilScheduleState> emit) async {
    final cid = state.contractId;
    if (cid == null) return;
    await _loadAll(cid, state.currentPage, emit);
  }

  Future<void> _onPage(CivilPageSelected e, Emitter<CivilScheduleState> emit) async {
    final cid = state.contractId;
    if (cid == null) return;
    emit(state.copyWith(currentPage: e.page, loadingPolygons: true, error: null));
    try {
      final polys = await repo.fetchPolygons(contractId: cid, page: e.page);
      emit(state.copyWith(polygons: polys, loadingPolygons: false));
    } catch (err, st) {
      emit(state.copyWith(loadingPolygons: false, error: '$err'));
    }
  }

  Future<void> _onUploadAsset(CivilAssetUploadRequested e, Emitter<CivilScheduleState> emit) async {
    final cid = state.contractId;
    if (cid == null) return;
    emit(state.copyWith(uploadingAsset: true, error: null));
    try {
      await repo.uploadAsset(
        contractId: cid,
        bytes: e.bytes,
        filename: e.filename,
        currentUserId: e.currentUserId,
      );
      final assets = await repo.loadAssets(cid);
      emit(state.copyWith(assets: assets, uploadingAsset: false));
    } catch (err, st) {
      emit(state.copyWith(uploadingAsset: false, error: '$err'));
    }
  }

  Future<void> _onUpsertPolygon(CivilPolygonUpsertRequested e, Emitter<CivilScheduleState> emit) async {
    final cid = state.contractId;
    if (cid == null) return;
    emit(state.copyWith(applyingPolygon: true, error: null));
    try {
      await repo.upsertPolygon(
        contractId: cid,
        polygonId: e.polygonId,
        page: e.page,
        name: e.name,
        tipo: e.tipo,
        status: e.status,
        comentario: e.comentario,
        areaM2: e.areaM2,
        perimeterM: e.perimeterM,
        points: e.points,
        takenAtMs: e.takenAtMs,
        currentUserId: e.currentUserId,
      );
      final polys = await repo.fetchPolygons(contractId: cid, page: state.currentPage);
      emit(state.copyWith(polygons: polys, applyingPolygon: false));
    } catch (err, st) {
      emit(state.copyWith(applyingPolygon: false, error: '$err'));
    }
  }

  Future<void> _onApplyPolygon(CivilPolygonApplyRequested e, Emitter<CivilScheduleState> emit) async {
    final cid = state.contractId;
    if (cid == null) return;
    emit(state.copyWith(applyingPolygon: true, error: null));
    try {
      await repo.applyPolygonChanges(
        contractId: cid,
        polygonId: e.polygonId,
        status: e.status,
        comentario: e.comentario,
        takenAtMs: e.takenAtMs,
        finalPhotoUrls: e.finalPhotoUrls,
        newFilesBytes: e.newFilesBytes,
        newFileNames: e.newFileNames,
        newPhotoMetas: e.newPhotoMetas,
        currentUserId: e.currentUserId,
      );
      final polys = await repo.fetchPolygons(contractId: cid, page: state.currentPage);
      emit(state.copyWith(polygons: polys, applyingPolygon: false));
    } catch (err, st) {
      emit(state.copyWith(applyingPolygon: false, error: '$err'));
    }
  }

  Future<void> _onDeletePolygon(CivilPolygonDeleteRequested e, Emitter<CivilScheduleState> emit) async {
    final cid = state.contractId;
    if (cid == null) return;
    emit(state.copyWith(applyingPolygon: true, error: null));
    try {
      await repo.deletePolygon(contractId: cid, polygonId: e.polygonId);
      final polys = await repo.fetchPolygons(contractId: cid, page: state.currentPage);
      emit(state.copyWith(polygons: polys, applyingPolygon: false));
    } catch (err, st) {
      emit(state.copyWith(applyingPolygon: false, error: '$err'));
    }
  }
}
