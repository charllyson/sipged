import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/sectors/operation/schedule_data.dart';
import 'package:siged/_blocs/sectors/operation/schedule_style.dart';
import 'package:siged/_widgets/schedule/schedule_lane_class.dart';

import 'schedule_event.dart';
import 'schedule_state.dart';
import 'schedule_repository.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final ScheduleRepository _repo;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  ScheduleBloc({
    ScheduleRepository? repository,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _repo = repository ?? ScheduleRepository(firestore: firestore, storage: storage),
        firestore = firestore ?? FirebaseFirestore.instance,
        storage = storage ?? FirebaseStorage.instance,
        super(const ScheduleState()) {
    on<ScheduleWarmupRequested>(_onWarmup);
    on<ScheduleRefreshRequested>(_onRefresh);
    on<ScheduleServiceSelected>(_onServiceSelected);
    on<ScheduleLanesSaveRequested>(_onLanesSave);
    on<ScheduleExecucoesReloadRequested>(_onExecReload);

    // ação única do modal
    on<ScheduleSquareApplyRequested>(_onApply);
  }

  // ================= helpers (paths/meta) =================

  String _slug(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

  // meta do serviço atual para cor/ícone/label da UI
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

  String _canonStatus(String? raw) {
    var s = (raw ?? '').toLowerCase().trim();
    s = s
        .replaceAll('á', 'a').replaceAll('à', 'a').replaceAll('â', 'a').replaceAll('ã', 'a')
        .replaceAll('é', 'e').replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o').replaceAll('ô', 'o').replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[\s\-_]+'), ' ');
    if (s.contains('conclu')) return 'concluido';
    if (s.contains('andament') || s.contains('progress')) return 'em_andamento';
    if (s.contains('iniciar') || s.contains('todo')) return 'a_iniciar';
    return s.isEmpty ? 'a_iniciar' : 'a_iniciar';
  }

  List<String> _serviceKeysForGeral(ScheduleState st) =>
      st.services.where((o) => o.key != 'geral').map((o) => o.key).toList();

  // ================= handlers =================

  Future<void> _onWarmup(
      ScheduleWarmupRequested e,
      Emitter<ScheduleState> emit,
      ) async {
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
      final services = await _repo.loadAvailableServicesFromBudget(e.contractId);

      await _repo.ensureDefaultLaneIfMissing(e.contractId);
      final lanes = await _repo.loadFaixas(e.contractId);

      final currentKey = services.any((s) => s.key == e.initialServiceKey.toLowerCase())
          ? e.initialServiceKey.toLowerCase()
          : 'geral';

      final meta = _currentMeta(
        state.copyWith(services: services, currentServiceKey: currentKey),
      );

      final execs = await _repo.fetchExecucoes(
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
    } catch (err, stTrace) {
      debugPrint('Warmup error: $err\n$stTrace');
      emit(state.copyWith(
        loadingServices: false,
        loadingLanes: false,
        loadingExecucoes: false,
        error: '$err',
      ));
    }
  }

  Future<void> _onRefresh(
      ScheduleRefreshRequested e,
      Emitter<ScheduleState> emit,
      ) async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;

    emit(state.copyWith(
      loadingServices: true,
      loadingLanes: true,
      loadingExecucoes: true,
      error: null,
    ));

    try {
      final services = await _repo.loadAvailableServicesFromBudget(cid);
      final lanes = await _repo.loadFaixas(cid);
      final execs = await _repo.fetchExecucoes(
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
    } catch (err, stTrace) {
      debugPrint('Refresh error: $err\n$stTrace');
      emit(state.copyWith(
        loadingServices: false,
        loadingLanes: false,
        loadingExecucoes: false,
        error: '$err',
      ));
    }
  }

  Future<void> _onServiceSelected(
      ScheduleServiceSelected e,
      Emitter<ScheduleState> emit,
      ) async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;

    final newKey = e.serviceKey.toLowerCase();
    if (newKey == state.currentServiceKey) return;

    emit(state.copyWith(currentServiceKey: newKey, loadingExecucoes: true, error: null));
    try {
      final execs = await _repo.fetchExecucoes(
        contractId: cid,
        selectedServiceKey: newKey,
        serviceKeysForGeral: _serviceKeysForGeral(state),
        metaForSelected: _currentMeta(state.copyWith(currentServiceKey: newKey)),
      );
      emit(state.copyWith(execucoes: execs, loadingExecucoes: false, error: null));
    } catch (err, stTrace) {
      debugPrint('ServiceSelected error: $err\n$stTrace');
      emit(state.copyWith(loadingExecucoes: false, error: '$err'));
    }
  }

  Future<void> _onLanesSave(
      ScheduleLanesSaveRequested e,
      Emitter<ScheduleState> emit,
      ) async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;

    emit(state.copyWith(loadingLanes: true, error: null));
    try {
      await _repo.saveFaixas(cid, e.lanes);
      final lanes = await _repo.loadFaixas(cid);
      emit(state.copyWith(lanes: lanes, loadingLanes: false, error: null));
    } catch (err, stTrace) {
      debugPrint('LanesSave error: $err\n$stTrace');
      emit(state.copyWith(loadingLanes: false, error: '$err'));
    }
  }

  Future<void> _onExecReload(
      ScheduleExecucoesReloadRequested e,
      Emitter<ScheduleState> emit,
      ) async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;

    emit(state.copyWith(loadingExecucoes: true, error: null));
    try {
      final execs = await _repo.fetchExecucoes(
        contractId: cid,
        selectedServiceKey: state.currentServiceKey,
        serviceKeysForGeral: _serviceKeysForGeral(state),
        metaForSelected: _currentMeta(state),
      );
      emit(state.copyWith(execucoes: execs, loadingExecucoes: false, error: null));
    } catch (err, stTrace) {
      debugPrint('ExecReload error: $err\n$stTrace');
      emit(state.copyWith(loadingExecucoes: false, error: '$err'));
    }
  }

  Future<void> _onApply(
      ScheduleSquareApplyRequested e,
      Emitter<ScheduleState> emit,
      ) async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;
    if (state.currentServiceKey == 'geral') return;

    try {
      // 1) Aplica tudo (status/comentário/data + uploads + exclusões + ordem final)
      final uploadedUrls = await _repo.applySquareChanges(
        contractId: cid,
        serviceKey: state.currentServiceKey,
        estaca: e.estaca,
        faixaIndex: e.faixaIndex,
        tipoLabel: e.tipoLabel,
        status: e.status,
        comentario: e.comentario,
        takenAtForNew: e.takenAt,
        finalPhotoUrls: e.finalPhotoUrls,
        newFilesBytes: e.newFilesBytes,
        newFileNames: e.newFileNames,
        newPhotoMetas: e.newPhotoMetas,
        currentUserId: e.currentUserId,
      );

      // 2) Otimista no estado (inclui takenAtMs)
      final canon = _canonStatus(e.status);
      final list = [...state.execucoes];
      final idx = list.indexWhere((x) => x.numero == e.estaca && x.faixaIndex == e.faixaIndex);
      final meta = _currentMeta(state);
      final now = DateTime.now();

      if (canon == 'a_iniciar') {
        if (idx != -1) list.removeAt(idx);
      } else {
        final prev = idx != -1 ? list[idx] : null;

        // Reconstrói fotos finais em memória: final + uploads (append)
        final finalFotos = <String>[...e.finalPhotoUrls, ...uploadedUrls];

        // Metas alinhadas por URL (mantém as antigas quando existirem)
        final prevMetas = prev?.fotosMeta ?? const <Map<String, dynamic>>[];
        final byUrl = <String, Map<String, dynamic>>{
          for (final m in prevMetas)
            (m['url'] as String?) ?? '': Map<String, dynamic>.from(m),
        };
        final metasOrdered = finalFotos.map((u) {
          final m = byUrl[u];
          if (m != null) return Map<String, dynamic>.from(m);
          return {
            'url': u,
            'name': u.split('/').last,
            'uploadedAtMs': now.millisecondsSinceEpoch,
            'uploadedBy': e.currentUserId,
          };
        }).toList();

        final updated = ScheduleData(
          numero: e.estaca,
          faixaIndex: e.faixaIndex,
          tipo: e.tipoLabel,
          status: canon,
          comentario: (e.comentario?.trim().isEmpty ?? true) ? null : e.comentario!.trim(),
          createdAt: prev?.createdAt ?? now,
          createdBy: prev?.createdBy ?? e.currentUserId,
          updatedAt: now,
          updatedBy: e.currentUserId,
          key: meta.key,
          label: meta.label,
          icon: meta.icon,
          color: meta.color,
          fotos: finalFotos,
          fotosMeta: metasOrdered,
          // 👉 refletir a DATA do modal no estado otimista
          takenAtMs: (e.takenAt != null)
              ? e.takenAt!.millisecondsSinceEpoch
              : prev?.takenAtMs,
        );

        if (idx == -1) list.add(updated); else list[idx] = updated;
      }

      emit(state.copyWith(execucoes: List.unmodifiable(list), error: null));

      // 3) Recarrega do servidor para ficar 100% alinhado
      add(const ScheduleExecucoesReloadRequested());
    } catch (err, stTrace) {
      debugPrint('Apply error: $err\n$stTrace');
      emit(state.copyWith(error: '$err'));
    }
  }
}
