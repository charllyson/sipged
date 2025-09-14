// lib/_blocs/sectors/operation/road/board/schedule_road_board_bloc.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:latlong2/latlong.dart';
import 'package:siged/_blocs/sectors/operation/road/board/schedule_road_board_data.dart';

import 'schedule_road_board_event.dart';
import 'schedule_road_board_state.dart';
import 'schedule_road_board_repository.dart' show ScheduleRoadBoardRepository, ProjectGeometryData;

import 'package:siged/_services/geoJson/line_segmentation.dart'; // splitAxisByFixedStep

class ScheduleRoadBoardBloc extends Bloc<ScheduleRoadBoardEvent, ScheduleRoadBoardState> {
  final ScheduleRoadBoardRepository _repo;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  ScheduleRoadBoardBloc({
    ScheduleRoadBoardRepository? repository,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _repo = repository ?? ScheduleRoadBoardRepository(firestore: firestore, storage: storage),
        firestore = firestore ?? FirebaseFirestore.instance,
        storage = storage ?? FirebaseStorage.instance,
        super(const ScheduleRoadBoardState()) {
    on<ScheduleWarmupRequested>(_onWarmup);
    on<ScheduleRefreshRequested>(_onRefresh);
    on<ScheduleServiceSelected>(_onServiceSelected);
    on<ScheduleLanesSaveRequested>(_onLanesSave);
    on<ScheduleExecucoesReloadRequested>(_onExecReload);

    // ação única do modal
    on<ScheduleSquareApplyRequested>(_onApply);

    // ===== MAPA (unificado) =====
    on<ScheduleProjectImportGeoJsonRequested>(_onImportGeoJson);
    on<ScheduleProjectUpsertRequested>(_onUpsertProject);
    on<ScheduleProjectDeleteRequested>(_onDeleteProject);
    on<SchedulePolylineSelected>((e, emit) => emit(state.copyWith(selectedPolylineId: e.polylineId)));
    on<ScheduleMapZoomChanged>((e, emit) {
      final z = double.parse(e.zoom.toStringAsFixed(2));
      if ((state.mapZoom - z).abs() >= 0.05) emit(state.copyWith(mapZoom: z));
    });
  }

  // ------ helpers ------
  String _slug(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

  ScheduleRoadBoardData _currentMeta(ScheduleRoadBoardState st) {
    if (st.services.isEmpty) {
      return const ScheduleRoadBoardData(
        numero: 0, faixaIndex: 0, key: 'geral', label: 'GERAL',
        icon: Icons.clear_all, color: Colors.grey,
      );
    }
    return st.services.firstWhere((o) => o.key == st.currentServiceKey, orElse: () => st.services.first);
  }

  List<String> _serviceKeysForGeral(ScheduleRoadBoardState st) =>
      st.services.where((o) => o.key != 'geral').map((o) => o.key).toList();

  Map<int, Map<int, ScheduleRoadBoardData>> _buildExecIndex(List<ScheduleRoadBoardData> list) {
    final map = <int, Map<int, ScheduleRoadBoardData>>{};
    for (final e in list) {
      final inner = map.putIfAbsent(e.numero, () => <int, ScheduleRoadBoardData>{});
      inner[e.faixaIndex] = e;
    }
    return map;
  }

  DateTime? _cellDate(ScheduleRoadBoardData e) => e.takenAt ?? e.updatedAt ?? e.createdAt;
  DateTime? _minD(List<ScheduleRoadBoardData> xs) {
    DateTime? d; for (final e in xs){final c=_cellDate(e); if(c==null) continue; if(d==null||c.isBefore(d)) d=c;} return d;
  }
  DateTime? _maxD(List<ScheduleRoadBoardData> xs) {
    DateTime? d; for (final e in xs){final c=_cellDate(e); if(c==null) continue; if(d==null||c.isAfter(d)) d=c;} return d;
  }

  // Deriva o eixo (flatten) a partir da geometria crua
  List<LatLng> _axisFrom({
    String? geometryType,
    List<List<LatLng>>? multiLine,
    List<LatLng>? points,
  }) {
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
    return seg.segments.length; // 1 segmento = 20 m = 1 estaca
  }

  // ================= handlers =================

  Future<void> _onWarmup(ScheduleWarmupRequested e, Emitter<ScheduleRoadBoardState> emit) async {
    emit(state.copyWith(
      contractId: e.contractId,
      summarySubjectContract: e.summarySubjectContract,
      currentServiceKey: e.initialServiceKey.toLowerCase(),
      loadingServices: true,
      loadingLanes: true,
      loadingExecucoes: true,
      savingOrImporting: true, // carregando geometria também
      error: null,
    ));

    try {
      // serviços + faixas
      final services = await _repo.loadAvailableServicesFromBudget(e.contractId);
      await _repo.ensureDefaultLaneIfMissing(e.contractId);
      final lanes = await _repo.loadFaixas(e.contractId);

      final currentKey = services.any((s) => s.key == e.initialServiceKey.toLowerCase())
          ? e.initialServiceKey.toLowerCase()
          : 'geral';

      // geometria (agora direto no state: geometryType/multiLine/points)
      final ScheduleRoadBoardData? g = await _repo.fetchProjectGeometry(e.contractId);
      final geometryType = g?.geometryType;
      final multiLine    = g?.multiLine;
      final points       = g?.points;

      // totalEstacas a partir da geometria (ou usa o fornecido)
      final axis = _axisFrom(geometryType: geometryType, multiLine: multiLine, points: points);
      final derived = _deriveTotalEstacasFromAxis(axis);
      final totalEstacas = (derived > 0) ? derived : (e.totalEstacas ?? 0);

      // execuções do serviço atual
      final meta = _currentMeta(state.copyWith(services: services, currentServiceKey: currentKey));
      final execs = await _repo.fetchExecucoes(
        contractId: e.contractId,
        selectedServiceKey: currentKey,
        serviceKeysForGeral: services.where((s) => s.key != 'geral').map((s) => s.key).toList(),
        metaForSelected: meta,
      );

      emit(state.copyWith(
        initialized: true,
        services: services,
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
        // geometria no state:
        geometryType: geometryType,
        multiLine: multiLine,
        points: points,
        totalEstacas: totalEstacas,
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

  Future<void> _onRefresh(ScheduleRefreshRequested e, Emitter<ScheduleRoadBoardState> emit) async {
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
      final services = await _repo.loadAvailableServicesFromBudget(cid);
      final lanes = await _repo.loadFaixas(cid);

      // geometria
      final ScheduleRoadBoardData? g = await _repo.fetchProjectGeometry(cid);
      final geometryType = g?.geometryType;
      final multiLine    = g?.multiLine;
      final points       = g?.points;

      final execs = await _repo.fetchExecucoes(
        contractId: cid,
        selectedServiceKey: state.currentServiceKey,
        serviceKeysForGeral: _serviceKeysForGeral(state.copyWith(services: services)),
        metaForSelected: _currentMeta(state.copyWith(services: services)),
      );

      // recalcula totalEstacas se conseguirmos derivar
      final axis = _axisFrom(geometryType: geometryType, multiLine: multiLine, points: points);
      final maybeTotal = _deriveTotalEstacasFromAxis(axis);
      final nextTotal = maybeTotal > 0 ? maybeTotal : state.totalEstacas;

      emit(state.copyWith(
        services: services,
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

  Future<void> _onServiceSelected(ScheduleServiceSelected e, Emitter<ScheduleRoadBoardState> emit) async {
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

  Future<void> _onLanesSave(ScheduleLanesSaveRequested e, Emitter<ScheduleRoadBoardState> emit) async {
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

  Future<void> _onExecReload(ScheduleExecucoesReloadRequested e, Emitter<ScheduleRoadBoardState> emit) async {
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

  Future<void> _onApply(ScheduleSquareApplyRequested e, Emitter<ScheduleRoadBoardState> emit) async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;
    if (state.currentServiceKey == 'geral') return;

    try {
      // 1) aplica alterações (repo mantém comportamento)
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

      // 2) atualização otimista
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
          for (final m in prevMetas) (m['url'] as String?) ?? '': Map<String, dynamic>.from(m),
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

        final updated = ScheduleRoadBoardData(
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
          takenAtMs: (e.takenAt != null) ? e.takenAt!.millisecondsSinceEpoch : prev?.takenAtMs,
        );

        if (idx == -1) list.add(updated); else list[idx] = updated;
      }

      final newIndex = _buildExecIndex(list);
      final newMin = _minD(list);
      final newMax = _maxD(list);

      emit(state.copyWith(
        execucoes: List.unmodifiable(list),
        execIndex: newIndex,
        minDate: newMin,
        maxDate: newMax,
        error: null,
      ));

      // 3) reload para alinhar com servidor
      add(const ScheduleExecucoesReloadRequested());
    } catch (err, stTrace) {
      debugPrint('Apply error: $err\n$stTrace');
      emit(state.copyWith(error: '$err'));
    }
  }

  // ===================== MAPA (unificado) =====================

  Future<void> _onImportGeoJson(ScheduleProjectImportGeoJsonRequested e, Emitter<ScheduleRoadBoardState> emit) async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;
    emit(state.copyWith(savingOrImporting: true, error: null));
    try {
      final ScheduleRoadBoardData saved = await _repo.importGeoJson(
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
          _axisFrom(
            geometryType: saved.geometryType,
            multiLine: saved.multiLine,
            points: saved.points,
          ),
        ),
      ));
    } catch (err) {
      emit(state.copyWith(savingOrImporting: false, error: err.toString()));
    }
  }

  Future<void> _onUpsertProject(ScheduleProjectUpsertRequested e, Emitter<ScheduleRoadBoardState> emit) async {
    emit(state.copyWith(savingOrImporting: true, error: null));
    try {
      final ScheduleRoadBoardData saved = await _repo.upsertProjectGeometry(e.data);
      emit(state.copyWith(
        savingOrImporting: false,
        geometryType: saved.geometryType,
        multiLine: saved.multiLine,
        points: saved.points,
        totalEstacas: _deriveTotalEstacasFromAxis(
          _axisFrom(
            geometryType: saved.geometryType,
            multiLine: saved.multiLine,
            points: saved.points,
          ),
        ),
      ));
    } catch (err) {
      emit(state.copyWith(savingOrImporting: false, error: err.toString()));
    }
  }

  Future<void> _onDeleteProject(ScheduleProjectDeleteRequested e, Emitter<ScheduleRoadBoardState> emit) async {
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
}
