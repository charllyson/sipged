// lib/_blocs/modules/operation/operation/civil/civil_schedule_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';

import 'civil_schedule_event.dart';
import 'civil_schedule_repository.dart';
import 'civil_schedule_state.dart';

class CivilScheduleBloc extends Bloc<CivilScheduleEvent, CivilScheduleState> {
  CivilScheduleBloc({
    required String tenantId,
    CivilScheduleRepository? repository,
  })  : repo = repository ?? CivilScheduleRepository(tenantId: tenantId),
        super(const CivilScheduleState()) {
    on<CivilWarmupRequested>(_onWarmup);
    on<CivilRefreshRequested>(_onRefresh);
    on<CivilPageSelected>(_onPage);
    on<CivilAssetUploadRequested>(_onUploadAsset);
    on<CivilPolygonUpsertRequested>(_onUpsertPolygon);
    on<CivilPolygonApplyRequested>(_onApplyPolygon);
    on<CivilPolygonDeleteRequested>(_onDeletePolygon);
  }

  final CivilScheduleRepository repo;

  String? _validContractId() {
    final cid = state.contractId?.trim();

    if (cid == null || cid.isEmpty) {
      return null;
    }

    return cid;
  }

  Future<void> _loadAll(
      String contractId,
      int page,
      Emitter<CivilScheduleState> emit,
      ) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      emit(
        state.copyWith(
          loadingMeta: false,
          loadingPolygons: false,
          error: 'Contrato inválido para carregar cronograma civil.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        loadingMeta: true,
        loadingPolygons: true,
        error: null,
      ),
    );

    try {
      final results = await Future.wait<Object>([
        repo.loadBoardMeta(cleanContractId),
        repo.loadAssets(cleanContractId),
        repo.fetchPolygons(
          contractId: cleanContractId,
          page: page,
        ),
      ]);

      final meta = results[0] as Map<String, dynamic>;
      final assets = results[1] as Map<String, dynamic>;
      final polygons = results[2] as List<Map<String, dynamic>>;

      emit(
        state.copyWith(
          boardMeta: meta,
          assets: assets,
          polygons: polygons,
          loadingMeta: false,
          loadingPolygons: false,
          error: null,
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          loadingMeta: false,
          loadingPolygons: false,
          error: 'Erro ao carregar cronograma civil: $err',
        ),
      );
    }
  }

  Future<void> _reloadPolygons(
      String contractId,
      Emitter<CivilScheduleState> emit,
      ) async {
    final polygons = await repo.fetchPolygons(
      contractId: contractId,
      page: state.currentPage,
    );

    emit(
      state.copyWith(
        polygons: polygons,
        loadingPolygons: false,
        applyingPolygon: false,
        error: null,
      ),
    );
  }

  Future<void> _onWarmup(
      CivilWarmupRequested event,
      Emitter<CivilScheduleState> emit,
      ) async {
    final cleanContractId = event.contractId.trim();
    final initialPage = event.initialPage ?? 0;

    if (cleanContractId.isEmpty) {
      emit(
        state.copyWith(
          initialized: true,
          loadingMeta: false,
          loadingPolygons: false,
          error: 'Contrato inválido para iniciar cronograma civil.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        initialized: true,
        contractId: cleanContractId,
        currentPage: initialPage,
        error: null,
      ),
    );

    await _loadAll(
      cleanContractId,
      initialPage,
      emit,
    );
  }

  Future<void> _onRefresh(
      CivilRefreshRequested event,
      Emitter<CivilScheduleState> emit,
      ) async {
    final contractId = _validContractId();

    if (contractId == null) {
      emit(
        state.copyWith(
          error: 'Contrato inválido para atualizar cronograma civil.',
        ),
      );
      return;
    }

    await _loadAll(
      contractId,
      state.currentPage,
      emit,
    );
  }

  Future<void> _onPage(
      CivilPageSelected event,
      Emitter<CivilScheduleState> emit,
      ) async {
    final contractId = _validContractId();

    if (contractId == null) {
      emit(
        state.copyWith(
          error: 'Contrato inválido para trocar página do cronograma civil.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        currentPage: event.page,
        loadingPolygons: true,
        error: null,
      ),
    );

    try {
      final polygons = await repo.fetchPolygons(
        contractId: contractId,
        page: event.page,
      );

      emit(
        state.copyWith(
          polygons: polygons,
          loadingPolygons: false,
          error: null,
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          loadingPolygons: false,
          error: 'Erro ao carregar polígonos da página: $err',
        ),
      );
    }
  }

  Future<void> _onUploadAsset(
      CivilAssetUploadRequested event,
      Emitter<CivilScheduleState> emit,
      ) async {
    final contractId = _validContractId();

    if (contractId == null) {
      emit(
        state.copyWith(
          error: 'Contrato inválido para enviar arquivo do cronograma civil.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        uploadingAsset: true,
        error: null,
      ),
    );

    try {
      await repo.uploadAsset(
        contractId: contractId,
        bytes: event.bytes,
        filename: event.filename,
        currentUserId: event.currentUserId,
      );

      final assets = await repo.loadAssets(contractId);

      emit(
        state.copyWith(
          assets: assets,
          uploadingAsset: false,
          error: null,
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          uploadingAsset: false,
          error: 'Erro ao enviar arquivo: $err',
        ),
      );
    }
  }

  Future<void> _onUpsertPolygon(
      CivilPolygonUpsertRequested event,
      Emitter<CivilScheduleState> emit,
      ) async {
    final contractId = _validContractId();

    if (contractId == null) {
      emit(
        state.copyWith(
          error: 'Contrato inválido para salvar polígono.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        applyingPolygon: true,
        error: null,
      ),
    );

    try {
      await repo.upsertPolygon(
        contractId: contractId,
        polygonId: event.polygonId,
        page: event.page,
        name: event.name,
        tipo: event.tipo,
        status: event.status,
        comentario: event.comentario,
        areaM2: event.areaM2,
        perimeterM: event.perimeterM,
        points: event.points,
        takenAtMs: event.takenAtMs,
        currentUserId: event.currentUserId,
      );

      await _reloadPolygons(
        contractId,
        emit,
      );
    } catch (err) {
      emit(
        state.copyWith(
          applyingPolygon: false,
          error: 'Erro ao salvar polígono: $err',
        ),
      );
    }
  }

  Future<void> _onApplyPolygon(
      CivilPolygonApplyRequested event,
      Emitter<CivilScheduleState> emit,
      ) async {
    final contractId = _validContractId();

    if (contractId == null) {
      emit(
        state.copyWith(
          error: 'Contrato inválido para aplicar alteração no polígono.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        applyingPolygon: true,
        error: null,
      ),
    );

    try {
      await repo.applyPolygonChanges(
        contractId: contractId,
        polygonId: event.polygonId,
        status: event.status,
        comentario: event.comentario,
        takenAtMs: event.takenAtMs,
        finalPhotoUrls: event.finalPhotoUrls,
        newPhotos: event.newPhotos,
        currentUserId: event.currentUserId,
      );

      await _reloadPolygons(
        contractId,
        emit,
      );
    } catch (err) {
      emit(
        state.copyWith(
          applyingPolygon: false,
          error: 'Erro ao aplicar alteração no polígono: $err',
        ),
      );
    }
  }

  Future<void> _onDeletePolygon(
      CivilPolygonDeleteRequested event,
      Emitter<CivilScheduleState> emit,
      ) async {
    final contractId = _validContractId();

    if (contractId == null) {
      emit(
        state.copyWith(
          error: 'Contrato inválido para excluir polígono.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        applyingPolygon: true,
        error: null,
      ),
    );

    try {
      await repo.deletePolygon(
        contractId: contractId,
        polygonId: event.polygonId,
      );

      await _reloadPolygons(
        contractId,
        emit,
      );
    } catch (err) {
      emit(
        state.copyWith(
          applyingPolygon: false,
          error: 'Erro ao excluir polígono: $err',
        ),
      );
    }
  }
}