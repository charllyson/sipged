// lib/blocs/schedule/schedule_bloc.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sisged/_blocs/sectors/operation/schedule_data.dart';
import 'package:sisged/_blocs/sectors/operation/schedule_style.dart';
import 'package:sisged/_widgets/schedule/schedule_menu_buttons_names.dart'; // slugFromTitle

import 'package:sisged/_blocs/sectors/operation/schedule_repository.dart';
import 'schedule_event.dart';
import 'schedule_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final ScheduleRepository repo;

  ScheduleBloc(this.repo) : super(const ScheduleState()) {
    on<ScheduleWarmupRequested>(_onWarmup);
    on<ScheduleRefreshRequested>(_onRefresh);
    on<ScheduleServiceSelected>(_onServiceSelected);
    on<ScheduleLanesSaveRequested>(_onLanesSave);
    on<ScheduleExecucoesReloadRequested>(_onExecReload);
    on<ScheduleSquareUpsertRequested>(_onUpsert);
    on<ScheduleSquareUploadPhotosRequested>(_onUploadPhotos);
    on<ScheduleSquareDeletePhotoRequested>(_onDeletePhoto);
    on<ScheduleSquareSetPhotosRequested>(_onSetPhotos);
  }

  // -------- helpers --------

  /// Constrói a lista de serviços (meta) já normalizada.
  /// IMPORTANTE: como ScheduleData agora exige numero/faixaIndex,
  /// usamos sempre (0, 0) para os itens de meta de serviço.
  Future<List<ScheduleData>> _loadServicesNormalized(String contractId) async {
    final base = <ScheduleData>[
      ScheduleData(
        numero: 0,
        faixaIndex: 0,
        key: 'geral',
        label: 'GERAL',
        icon: Icons.clear_all,
        color: ScheduleStyle.colorForService('GERAL'),
      ),
    ];

    final loaded = await repo.loadAvailableServicesFromBudget(contractId);

    for (final s in loaded) {
      final raw = (s.label.trim().isNotEmpty) ? s.label : s.key.trim();
      if (raw.isEmpty) continue;

      final label = raw;
      final normalized = ScheduleData(
        numero: 0,
        faixaIndex: 0,
        key: slugFromTitle(label),
        label: label,
        icon: ScheduleStyle.pickIconForTitle(label),
        color: ScheduleStyle.colorForService(label),
      );

      if (!base.any((o) => o.key == normalized.key)) {
        base.add(normalized);
      }
    }

    return List.unmodifiable(base);
  }

  List<String> _serviceKeysForGeral(ScheduleState st) {
    return st.services.where((o) => o.key != 'geral').map((o) => o.key).toList();
  }

  /// Retorna o meta do serviço atual; se não houver, volta para GERAL.
  ScheduleData _currentMeta(ScheduleState st) {
    if (st.services.isEmpty) {
      return ScheduleData(
        numero: 0,
        faixaIndex: 0,
        key: 'geral',
        label: 'GERAL',
        icon: Icons.clear_all,
        color: ScheduleStyle.colorForService('GERAL'),
      );
    }
    return st.services.firstWhere(
          (o) => o.key == st.currentServiceKey,
      orElse: () => st.services.first,
    );
  }

  // -------- handlers --------

  Future<void> _onWarmup(ScheduleWarmupRequested e, Emitter<ScheduleState> emit) async {
    emit(state.copyWith(
      contractId: e.contractId,
      totalEstacas: e.totalEstacas,
      currentServiceKey: e.initialServiceKey.toLowerCase(),
      loadingServices: true,
      loadingLanes: true,
      loadingExecucoes: true,
      error: null,
    ));

    try {
      final services = await _loadServicesNormalized(e.contractId);

      // Cria 1 faixa padrão se não houver nada
      await repo.ensureDefaultLaneIfMissing(e.contractId);

      final lanes = await repo.loadFaixas(e.contractId);

      final currentKey = services.any((s) => s.key == e.initialServiceKey.toLowerCase())
          ? e.initialServiceKey.toLowerCase()
          : 'geral';

      final meta = _currentMeta(
        state.copyWith(services: services, currentServiceKey: currentKey),
      );

      final execs = await repo.fetchExecucoes(
        contractId: e.contractId,
        selectedServiceKey: currentKey,
        serviceKeysForGeral: services.where((s) => s.key != 'geral').map((s) => s.key).toList(),
        metaForSelected: meta,
      );

      emit(state.copyWith(
        services: services,
        lanes: lanes,
        execucoes: execs,
        loadingServices: false,
        loadingLanes: false,
        loadingExecucoes: false,
        initialized: true,
        error: null,
        currentServiceKey: currentKey,
      ));
    } catch (err, st) {
      debugPrint('Warmup error: $err\n$st');
      emit(state.copyWith(
        loadingServices: false,
        loadingLanes: false,
        loadingExecucoes: false,
        error: '$err',
      ));
    }
  }

  Future<void> _onRefresh(ScheduleRefreshRequested e, Emitter<ScheduleState> emit) async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;

    emit(state.copyWith(
      loadingServices: true,
      loadingLanes: true,
      loadingExecucoes: true,
      error: null,
    ));

    try {
      final services = await _loadServicesNormalized(cid);
      final lanes = await repo.loadFaixas(cid);
      final execs = await repo.fetchExecucoes(
        contractId: cid,
        selectedServiceKey: state.currentServiceKey,
        serviceKeysForGeral: _serviceKeysForGeral(state.copyWith(services: services)),
        metaForSelected: _currentMeta(state.copyWith(services: services)),
      );

      emit(state.copyWith(
        services: services,
        lanes: lanes,
        execucoes: execs,
        loadingServices: false,
        loadingLanes: false,
        loadingExecucoes: false,
        error: null,
      ));
    } catch (err, st) {
      debugPrint('Refresh error: $err\n$st');
      emit(state.copyWith(
        loadingServices: false,
        loadingLanes: false,
        loadingExecucoes: false,
        error: '$err',
      ));
    }
  }

  Future<void> _onServiceSelected(ScheduleServiceSelected e, Emitter<ScheduleState> emit) async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;

    final newKey = e.serviceKey.toLowerCase();
    if (newKey == state.currentServiceKey) return;

    emit(state.copyWith(currentServiceKey: newKey, loadingExecucoes: true, error: null));
    try {
      final execs = await repo.fetchExecucoes(
        contractId: cid,
        selectedServiceKey: newKey,
        serviceKeysForGeral: _serviceKeysForGeral(state),
        metaForSelected: _currentMeta(state.copyWith(currentServiceKey: newKey)),
      );
      emit(state.copyWith(execucoes: execs, loadingExecucoes: false, error: null));
    } catch (err, st) {
      debugPrint('ServiceSelected error: $err\n$st');
      emit(state.copyWith(loadingExecucoes: false, error: '$err'));
    }
  }

  Future<void> _onLanesSave(ScheduleLanesSaveRequested e, Emitter<ScheduleState> emit) async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;

    emit(state.copyWith(loadingLanes: true, error: null));
    try {
      await repo.saveFaixas(cid, e.lanes);
      final lanes = await repo.loadFaixas(cid); // recarrega
      emit(state.copyWith(lanes: lanes, loadingLanes: false, error: null));
    } catch (err, st) {
      debugPrint('LanesSave error: $err\n$st');
      emit(state.copyWith(loadingLanes: false, error: '$err'));
    }
  }

  Future<void> _onExecReload(ScheduleExecucoesReloadRequested e, Emitter<ScheduleState> emit) async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;

    emit(state.copyWith(loadingExecucoes: true, error: null));
    try {
      final execs = await repo.fetchExecucoes(
        contractId: cid,
        selectedServiceKey: state.currentServiceKey,
        serviceKeysForGeral: _serviceKeysForGeral(state),
        metaForSelected: _currentMeta(state),
      );
      emit(state.copyWith(execucoes: execs, loadingExecucoes: false, error: null));
    } catch (err, st) {
      debugPrint('ExecReload error: $err\n$st');
      emit(state.copyWith(loadingExecucoes: false, error: '$err'));
    }
  }

  Future<void> _onUpsert(ScheduleSquareUpsertRequested e, Emitter<ScheduleState> emit) async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;
    if (state.currentServiceKey == 'geral') return;

    try {
      await repo.upsertSquare(
        contractId: cid,
        serviceKey: state.currentServiceKey,
        estaca: e.estaca,
        faixaIndex: e.faixaIndex,
        tipoLabel: e.tipoLabel,
        status: e.status,
        comentario: e.comentario,
        currentUserId: e.currentUserId,
      );

      // Atualização local snappy
      final list = [...state.execucoes];
      final compoundKey = '${e.estaca}_${e.faixaIndex}';
      final idx = list.indexWhere((x) => '${x.numero}_${x.faixaIndex}' == compoundKey);

      if (e.status == 'a iniciar') {
        if (idx != -1) list.removeAt(idx);
      } else {
        final prev = (idx != -1) ? list[idx] : null;
        final meta = _currentMeta(state);
        final updated = ScheduleData(
          numero: e.estaca,
          faixaIndex: e.faixaIndex,
          tipo: e.tipoLabel,
          status: e.status,
          comentario: (e.comentario?.trim().isEmpty ?? true) ? null : e.comentario!.trim(),
          createdAt: prev?.createdAt ?? DateTime.now(),
          createdBy: prev?.createdBy ?? e.currentUserId,
          key: meta.key,
          label: meta.label,
          icon: meta.icon,
          color: meta.color,
        );
        if (idx == -1) {
          list.add(updated);
        } else {
          list[idx] = updated;
        }
      }

      emit(state.copyWith(execucoes: List.unmodifiable(list), error: null));
    } catch (err, st) {
      debugPrint('Upsert error: $err\n$st');
      emit(state.copyWith(error: '$err'));
    }
  }

  Future<void> _onUploadPhotos(ScheduleSquareUploadPhotosRequested e, Emitter<ScheduleState> emit) async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;
    if (state.currentServiceKey == 'geral') return;

    try {
      await repo.uploadSquarePhotos(
        contractId: state.contractId!,
        serviceKey: state.currentServiceKey,
        estaca: e.estaca,
        faixaIndex: e.faixaIndex,
        filesBytes: e.filesBytes,
        fileNames: e.fileNames,
        metasFromUi: e.photoMetas, // 👈 agora vai
        currentUserId: e.currentUserId,
        takenAt: e.takenAt,
      );

      add(const ScheduleExecucoesReloadRequested());
    } catch (err, st) {
      debugPrint('UploadPhotos error: $err\n$st');
      emit(state.copyWith(error: '$err'));
    }
  }

  Future<void> _onDeletePhoto(ScheduleSquareDeletePhotoRequested e, Emitter<ScheduleState> emit) async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;
    if (state.currentServiceKey == 'geral') return;

    try {
      await repo.deleteSquarePhoto(
        contractId: cid,
        serviceKey: state.currentServiceKey,
        estaca: e.estaca,
        faixaIndex: e.faixaIndex,
        photoUrl: e.photoUrl,
        currentUserId: e.currentUserId,
      );
      add(const ScheduleExecucoesReloadRequested());
    } catch (err, st) {
      debugPrint('DeletePhoto error: $err\n$st');
      emit(state.copyWith(error: '$err'));
    }
  }

  Future<void> _onSetPhotos(ScheduleSquareSetPhotosRequested e, Emitter<ScheduleState> emit) async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;
    if (state.currentServiceKey == 'geral') return;

    try {
      await repo.setSquarePhotos(
        contractId: cid,
        serviceKey: state.currentServiceKey,
        estaca: e.estaca,
        faixaIndex: e.faixaIndex,
        photoUrls: e.photoUrls,
        currentUserId: e.currentUserId,
      );
      add(const ScheduleExecucoesReloadRequested());
    } catch (err, st) {
      debugPrint('SetPhotos error: $err\n$st');
      emit(state.copyWith(error: '$err'));
    }
  }
}
