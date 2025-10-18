// COMPLETO — Bloc com physfin_grid por ÍNDICE no Firestore e NOME na UI

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:latlong2/latlong.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_data.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_repository.dart';

import 'schedule_road_event.dart';
import 'schedule_road_state.dart';

import 'package:siged/_widgets/stakes/line_segmentation.dart'; // splitAxisByFixedStep

class ScheduleRoadBloc extends Bloc<ScheduleRoadEvent, ScheduleRoadState> {
  final ScheduleRoadRepository _repo;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  ScheduleRoadBloc({
    ScheduleRoadRepository? repository,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _repo =
      repository ?? ScheduleRoadRepository(firestore: firestore, storage: storage),
        firestore = firestore ?? FirebaseFirestore.instance,
        storage = storage ?? FirebaseStorage.instance,
        super(const ScheduleRoadState()) {
    on<ScheduleWarmupRequested>(_onWarmup);
    on<ScheduleRefreshRequested>(_onRefresh);
    on<ScheduleServiceSelected>(_onServiceSelected);
    on<ScheduleLanesSaveRequested>(_onLanesSave);
    on<ScheduleExecucoesReloadRequested>(_onExecReload);

    on<ScheduleSquareApplyRequested>(_onApply);

    on<ScheduleProjectImportGeoJsonRequested>(_onImportGeoJson);
    on<ScheduleProjectUpsertRequested>(_onUpsertProject);
    on<ScheduleProjectDeleteRequested>(_onDeleteProject);
    on<SchedulePolylineSelected>(
            (e, emit) => emit(state.copyWith(selectedPolylineId: e.polylineId)));
    on<ScheduleMapZoomChanged>((e, emit) {
      final z = double.parse(e.zoom.toStringAsFixed(2));
      if ((state.mapZoom - z).abs() >= 0.05) {
        emit(state.copyWith(mapZoom: z));
      }
    });

    on<PhysFinGridUpdateRequested>(_onPhysFinUpdateRequested);
  }

  String _slug(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

  // ====== Helpers de mapeamento NOME <-> ÍNDICE para physfin ======

  bool _isIndexKey(String k) => RegExp(r'^\d+$').hasMatch(k);
  String _idxOf(int i) => (i + 1).toString().padLeft(3, '0'); // "001", "002", ...

  /// Lista “serviços válidos” (exclui GERAL) na ordem em que aparecem
  List<ScheduleRoadData> _validServices(List<ScheduleRoadData> all) =>
      all.where((s) => s.key != 'geral').toList();

  /// NOME(slug) -> ÍNDICE("001")
  Map<String, String> _nameToIndex(List<ScheduleRoadData> services) {
    final v = _validServices(services);
    final m = <String, String>{};
    for (int i = 0; i < v.length; i++) {
      m[v[i].key] = _idxOf(i);
    }
    return m;
  }

  /// ÍNDICE("001") -> NOME(slug)
  Map<String, String> _indexToName(List<ScheduleRoadData> services) {
    final v = _validServices(services);
    final m = <String, String>{};
    for (int i = 0; i < v.length; i++) {
      m[_idxOf(i)] = v[i].key;
    }
    return m;
  }

  /// Converte GRID (Map<nome, ...>) -> (Map<idx, ...>)
  Map<String, List<double>> _gridNameToIndex(
      Map<String, List<double>> byName,
      List<ScheduleRoadData> services,
      ) {
    final m = _nameToIndex(services);
    final out = <String, List<double>>{};
    byName.forEach((k, v) {
      final idx = _isIndexKey(k) ? k : (m[k] ?? k);
      out[idx] = List<double>.from(v);
    });
    return out;
  }

  /// Converte GRID (Map<idx, ...>) -> (Map<nome, ...>)
  Map<String, List<double>> _gridIndexToName(
      Map<String, List<double>> byIndex,
      List<ScheduleRoadData> services,
      ) {
    final m = _indexToName(services);
    final out = <String, List<double>>{};
    byIndex.forEach((k, v) {
      final name = _isIndexKey(k) ? (m[k] ?? k) : k;
      out[name] = List<double>.from(v);
    });
    return out;
  }

  // ====== util ======

  ScheduleRoadData _currentMeta(ScheduleRoadState st) {
    if (st.services.isEmpty) {
      return const ScheduleRoadData(
        numero: 0, faixaIndex: 0, key: 'geral', label: 'GERAL',
        icon: Icons.clear_all, color: Colors.grey,
      );
    }
    return st.services
        .firstWhere((o) => o.key == st.currentServiceKey, orElse: () => st.services.first);
  }

  List<String> _serviceKeysForGeral(ScheduleRoadState st) =>
      st.services.where((o) => o.key != 'geral').map((o) => o.key).toList();

  Map<int, Map<int, ScheduleRoadData>> _buildExecIndex(List<ScheduleRoadData> list) {
    final map = <int, Map<int, ScheduleRoadData>>{};
    for (final e in list) {
      final inner = map.putIfAbsent(e.numero, () => <int, ScheduleRoadData>{});
      inner[e.faixaIndex] = e;
    }
    return map;
  }

  DateTime? _cellDate(ScheduleRoadData e) => e.takenAt ?? e.updatedAt ?? e.createdAt;
  DateTime? _minD(List<ScheduleRoadData> xs) {
    DateTime? d;
    for (final e in xs) {
      final c = _cellDate(e);
      if (c == null) continue;
      if (d == null || c.isBefore(d)) d = c;
    }
    return d;
  }

  DateTime? _maxD(List<ScheduleRoadData> xs) {
    DateTime? d;
    for (final e in xs) {
      final c = _cellDate(e);
      if (c == null) continue;
      if (d == null || c.isAfter(d)) d = c;
    }
    return d;
  }

  List<LatLng> _axisFrom(
      {String? geometryType, List<List<LatLng>>? multiLine, List<LatLng>? points}) {
    if (multiLine != null && multiLine.isNotEmpty) {
      return multiLine.expand((s) => s).toList(growable: false);
    }
    if (points != null && points.isNotEmpty) {
      return List<LatLng>.from(points);
    }
    return const <LatLng>[];
  }

  int _deriveTotalEstacasFromAxis(List<LatLng> axis) {
    if (axis.length < 2) return 0;
    final seg = splitAxisByFixedStep(axis: axis, stepMeters: 20.0);
    return seg.segments.length;
  }

  // ================= handlers =================

  Future<void> _onWarmup(
      ScheduleWarmupRequested e, Emitter<ScheduleRoadState> emit) async {
    emit(state.copyWith(
      contractId: e.contractId,
      summarySubjectContract: e.summarySubjectContract,
      currentServiceKey: e.initialServiceKey.toLowerCase(),
      loadingServices: true,
      loadingLanes: true,
      loadingExecucoes: true,
      savingOrImporting: true,
      error: null,
    ));

    try {
      _repo.clearContractCache(e.contractId);

      // serviços, totais, faixas e physfin em paralelo
      final servicesF = _repo.loadAvailableServicesFromBudget(e.contractId);
      final totalsF = _repo.fetchBudgetServiceTotals(e.contractId);
      final ensureLaneF = _repo.ensureDefaultLaneIfMissing(e.contractId);
      final physfinF = _repo.loadPhysFinGrid(e.contractId); // <-- índices no Firestore

      final services = await servicesF;
      await ensureLaneF;
      final lanes = await _repo.loadFaixas(e.contractId);
      final totals = await totalsF;
      final phys = await physfinF;

      final currentKey = services.any((s) => s.key == e.initialServiceKey.toLowerCase())
          ? e.initialServiceKey.toLowerCase()
          : 'geral';

      // geometria
      final ScheduleRoadData? g = await _repo.fetchProjectGeometry(e.contractId);
      final geometryType = g?.geometryType;
      final multiLine = g?.multiLine;
      final points = g?.points;

      final axis = _axisFrom(
          geometryType: geometryType, multiLine: multiLine, points: points);
      final derived = _deriveTotalEstacasFromAxis(axis);
      final totalEstacas = (derived > 0) ? derived : (e.totalEstacas ?? 0);

      // execuções do serviço atual
      final meta = _currentMeta(
          state.copyWith(services: services, currentServiceKey: currentKey));
      final execs = await _repo.fetchExecucoes(
        contractId: e.contractId,
        selectedServiceKey: currentKey,
        serviceKeysForGeral:
        services.where((s) => s.key != 'geral').map((s) => s.key).toList(),
        metaForSelected: meta,
      );

      // 🔁 Converte physfin (índice) -> (nome) para a UI
      final gridByName = _gridIndexToName(phys.grid, services);

      emit(state.copyWith(
        initialized: true,
        services: services,
        serviceTotals: totals,
        lanes: lanes,
        execucoes: execs,
        execIndex: _buildExecIndex(execs),
        minDate: _minD(execs),
        maxDate: _maxD(execs),
        loadingServices: false,
        loadingLanes: false,
        loadingExecucoes: false,
        savingOrImporting: false,
        error: null,
        currentServiceKey: currentKey,
        geometryType: geometryType,
        multiLine: multiLine,
        points: points,
        totalEstacas: totalEstacas,
        physfinPeriods: phys.periods,
        physfinGrid: gridByName, // UI vê por nome
      ));
    } catch (err, stTrace) {
      debugPrint('Warmup error: $err\n$stTrace');
      emit(state.copyWith(
        loadingServices: false,
        loadingLanes: false,
        loadingExecucoes: false,
        savingOrImporting: false,
        error: '$err',
      ));
    }
  }

  Future<void> _onRefresh(
      ScheduleRefreshRequested e, Emitter<ScheduleRoadState> emit) async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;

    emit(state.copyWith(
      loadingServices: true,
      loadingLanes: true,
      loadingExecucoes: true,
      savingOrImporting: true,
      error: null,
    ));

    try {
      _repo.clearContractCache(cid);

      final services = await _repo.loadAvailableServicesFromBudget(cid);
      final lanes = await _repo.loadFaixas(cid);
      final totals = await _repo.fetchBudgetServiceTotals(cid);
      final phys = await _repo.loadPhysFinGrid(cid); // índices

      final ScheduleRoadData? g = await _repo.fetchProjectGeometry(cid);
      final geometryType = g?.geometryType;
      final multiLine = g?.multiLine;
      final points = g?.points;

      final execs = await _repo.fetchExecucoes(
        contractId: cid,
        selectedServiceKey: state.currentServiceKey,
        serviceKeysForGeral: _serviceKeysForGeral(state.copyWith(services: services)),
        metaForSelected: _currentMeta(state.copyWith(services: services)),
      );

      final axis = _axisFrom(
          geometryType: geometryType, multiLine: multiLine, points: points);
      final maybeTotal = _deriveTotalEstacasFromAxis(axis);
      final nextTotal = maybeTotal > 0 ? maybeTotal : state.totalEstacas;

      final gridByName = _gridIndexToName(phys.grid, services);

      emit(state.copyWith(
        services: services,
        serviceTotals: totals,
        lanes: lanes,
        execucoes: execs,
        execIndex: _buildExecIndex(execs),
        minDate: _minD(execs),
        maxDate: _maxD(execs),
        loadingServices: false,
        loadingLanes: false,
        loadingExecucoes: false,
        savingOrImporting: false,
        error: null,
        geometryType: geometryType,
        multiLine: multiLine,
        points: points,
        totalEstacas: nextTotal,
        physfinPeriods: phys.periods,
        physfinGrid: gridByName, // UI por nome
      ));
    } catch (err, stTrace) {
      debugPrint('Refresh error: $err\n$stTrace');
      emit(state.copyWith(
        loadingServices: false,
        loadingLanes: false,
        loadingExecucoes: false,
        savingOrImporting: false,
        error: '$err',
      ));
    }
  }

  Future<void> _onServiceSelected(
      ScheduleServiceSelected e, Emitter<ScheduleRoadState> emit) async {
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
      emit(state.copyWith(
        execucoes: execs,
        execIndex: _buildExecIndex(execs),
        minDate: _minD(execs),
        maxDate: _maxD(execs),
        loadingExecucoes: false,
        error: null,
      ));
    } catch (err, stTrace) {
      debugPrint('ServiceSelected error: $err\n$stTrace');
      emit(state.copyWith(loadingExecucoes: false, error: '$err'));
    }
  }

  Future<void> _onLanesSave(
      ScheduleLanesSaveRequested e, Emitter<ScheduleRoadState> emit) async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;

    emit(state.copyWith(loadingLanes: true, error: null));
    try {
      await _repo.saveFaixas(cid, e.lanes);
      final lanes = await _repo.loadFaixas(cid);
      emit(state.copyWith(lanes: lanes, loadingLanes: false, error: null));
      add(const ScheduleExecucoesReloadRequested());
    } catch (err, stTrace) {
      debugPrint('LanesSave error: $err\n$stTrace');
      emit(state.copyWith(loadingLanes: false, error: '$err'));
    }
  }

  Future<void> _onExecReload(
      ScheduleExecucoesReloadRequested e, Emitter<ScheduleRoadState> emit) async {
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
      emit(state.copyWith(
        execucoes: execs,
        execIndex: _buildExecIndex(execs),
        minDate: _minD(execs),
        maxDate: _maxD(execs),
        loadingExecucoes: false,
        error: null,
      ));
    } catch (err, stTrace) {
      debugPrint('ExecReload error: $err\n$stTrace');
      emit(state.copyWith(loadingExecucoes: false, error: '$err'));
    }
  }

  Future<void> _onApply(
      ScheduleSquareApplyRequested e, Emitter<ScheduleRoadState> emit) async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;
    if (state.currentServiceKey == 'geral') return;

    try {
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

      final list = [...state.execucoes];
      final idx = list.indexWhere((x) => x.numero == e.estaca && x.faixaIndex == e.faixaIndex);
      final meta = _currentMeta(state);
      final now = DateTime.now();

      String _canon(String? s) {
        s = (s ?? '').toLowerCase();
        if (s.contains('conclu')) return 'concluido';
        if (s.contains('andament') || s.contains('progress')) return 'em_andamento';
        return 'a_iniciar';
      }
      final canon = _canon(e.status);

      if (canon == 'a_iniciar') {
        if (idx != -1) list.removeAt(idx);
      } else {
        final prev = idx != -1 ? list[idx] : null;
        final finalFotos = <String>[...e.finalPhotoUrls, ...uploadedUrls];

        final prevMetas = prev?.fotosMeta ?? const <Map<String, dynamic>>[];
        final byUrl = <String, Map<String, dynamic>>{
          for (final m in prevMetas) (m['url'] as String?) ?? '':
          Map<String, dynamic>.from(m),
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

        final updated = ScheduleRoadData(
          numero: e.estaca,
          faixaIndex: e.faixaIndex,
          tipo: e.tipoLabel,
          status: canon,
          comentario:
          (e.comentario?.trim().isEmpty ?? true) ? null : e.comentario!.trim(),
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
          takenAtMs:
          (e.takenAt != null) ? e.takenAt!.millisecondsSinceEpoch : prev?.takenAtMs,
        );

        if (idx == -1) {
          list.add(updated);
        } else {
          list[idx] = updated;
        }
      }

      emit(state.copyWith(
        execucoes: List.unmodifiable(list),
        execIndex: _buildExecIndex(list),
        minDate: _minD(list),
        maxDate: _maxD(list),
        error: null,
      ));

      add(const ScheduleExecucoesReloadRequested());
    } catch (err, stTrace) {
      debugPrint('Apply error: $err\n$stTrace');
      emit(state.copyWith(error: '$err'));
    }
  }

  // ===================== MAPA =====================

  Future<void> _onImportGeoJson(
      ScheduleProjectImportGeoJsonRequested e, Emitter<ScheduleRoadState> emit) async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;
    emit(state.copyWith(savingOrImporting: true, error: null));
    try {
      final ScheduleRoadData saved = await _repo.importGeoJson(
        contractId: cid,
        geojson: e.geojson,
        summarySubjectContract: e.summarySubjectContract ?? state.summarySubjectContract,
      );
      emit(state.copyWith(
        savingOrImporting: false,
        geometryType: saved.geometryType,
        multiLine: saved.multiLine,
        points: saved.points,
        totalEstacas: _deriveTotalEstacasFromAxis(
          _axisFrom(geometryType: saved.geometryType, multiLine: saved.multiLine, points: saved.points),
        ),
      ));
    } catch (err) {
      emit(state.copyWith(savingOrImporting: false, error: err.toString()));
    }
  }

  Future<void> _onUpsertProject(
      ScheduleProjectUpsertRequested e, Emitter<ScheduleRoadState> emit) async {
    emit(state.copyWith(savingOrImporting: true, error: null));
    try {
      final ScheduleRoadData saved = await _repo.upsertProjectGeometry(e.data);
      emit(state.copyWith(
        savingOrImporting: false,
        geometryType: saved.geometryType,
        multiLine: saved.multiLine,
        points: saved.points,
        totalEstacas: _deriveTotalEstacasFromAxis(
          _axisFrom(geometryType: saved.geometryType, multiLine: saved.multiLine, points: saved.points),
        ),
      ));
    } catch (err) {
      emit(state.copyWith(savingOrImporting: false, error: err.toString()));
    }
  }

  Future<void> _onDeleteProject(
      ScheduleProjectDeleteRequested e, Emitter<ScheduleRoadState> emit) async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;
    emit(state.copyWith(savingOrImporting: true, error: null));
    try {
      await _repo.deleteProjectGeometry(cid);
      emit(state.copyWith(
        savingOrImporting: false,
        geometryType: null,
        multiLine: null,
        points: null,
        totalEstacas: 0,
      ));
    } catch (err) {
      emit(state.copyWith(savingOrImporting: false, error: err.toString()));
    }
  }

  // ===================== PHYS/FIN =====================

  Future<void> _onPhysFinUpdateRequested(
      PhysFinGridUpdateRequested e, Emitter<ScheduleRoadState> emit) async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;

    // Converte NOME -> ÍNDICE para gravar
    final gridIdx = _gridNameToIndex(e.grid, state.services);

    // Atualiza estado imediatamente (UI continua por nome)
    emit(state.copyWith(
      physfinPeriods: e.periods,
      physfinGrid: e.grid,
    ));

    try {
      await _repo.savePhysFinGrid(
        contractId: cid,
        periods: e.periods,
        grid: gridIdx, // grava por índice
        updatedBy: e.updatedBy,
      );
    } catch (err) {
      debugPrint('savePhysFinGrid error: $err');
    }
  }
}
