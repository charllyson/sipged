import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'package:siged/_blocs/modules/operation/operation/road/schedule_road_data.dart';
import 'package:siged/_blocs/modules/operation/operation/road/schedule_road_repository.dart';
import 'package:siged/_blocs/modules/operation/operation/road/schedule_road_state.dart';
import 'package:siged/_widgets/schedule/linear/schedule_lane_class.dart';
import 'package:siged/_widgets/schedule/stakes/line_segmentation.dart'; // splitAxisByFixedStep
import 'package:siged/_widgets/images/carousel/carousel_metadata.dart' as pm;

/// Cubit principal do Schedule de rodovia.
///
/// Padrão: Cubit + State + Repository + Data.
/// Nenhum `Event` e nenhum `ChangeNotifier`.
class ScheduleRoadCubit extends Cubit<ScheduleRoadState> {
  final ScheduleRoadRepository _repo;

  ScheduleRoadCubit({
    ScheduleRoadRepository? repository,
  })  : _repo = repository ?? ScheduleRoadRepository(),
        super(const ScheduleRoadState());

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
        numero: 0,
        faixaIndex: 0,
        key: 'geral',
        label: 'GERAL',
        icon: Icons.clear_all,
        color: Colors.grey,
      );
    }
    return st.services.firstWhere(
          (o) => o.key == st.currentServiceKey,
      orElse: () => st.services.first,
    );
  }

  List<String> _serviceKeysForGeral(ScheduleRoadState st) =>
      st.services.where((o) => o.key != 'geral').map((o) => o.key).toList();

  Map<int, Map<int, ScheduleRoadData>> _buildExecIndex(
      List<ScheduleRoadData> list,
      ) {
    final map = <int, Map<int, ScheduleRoadData>>{};
    for (final e in list) {
      final inner = map.putIfAbsent(e.numero, () => <int, ScheduleRoadData>{});
      inner[e.faixaIndex] = e;
    }
    return map;
  }

  DateTime? _cellDate(ScheduleRoadData e) =>
      e.takenAt ?? e.updatedAt ?? e.createdAt;

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
    return seg.segments.length;
  }

  // ================= PUBLIC API =================

  /// Inicialização completa do Schedule de uma obra.
  Future<void> warmup({
    required String contractId,
    int? totalEstacas,
    String initialServiceKey = 'geral',
    String? summarySubjectContract,
  }) async {
    emit(
      state.copyWith(
        contractId: contractId,
        summarySubjectContract: summarySubjectContract,
        currentServiceKey: initialServiceKey.toLowerCase(),
        loadingServices: true,
        loadingLanes: true,
        loadingExecucoes: true,
        savingOrImporting: true,
        error: null,
      ),
    );

    try {
      _repo.clearContractCache(contractId);

      // serviços, totais, faixas e physfin em paralelo
      final servicesF = _repo.loadAvailableServicesFromBudget(contractId);
      final totalsF = _repo.fetchBudgetServiceTotals(contractId);
      final ensureLaneF = _repo.ensureDefaultLaneIfMissing(contractId);
      final physfinF = _repo.loadPhysFinGrid(contractId); // índices no Firestore

      final services = await servicesF;
      await ensureLaneF;
      final lanes = await _repo.loadFaixas(contractId);
      final totals = await totalsF;
      final phys = await physfinF;

      final currentKey =
      services.any((s) => s.key == initialServiceKey.toLowerCase())
          ? initialServiceKey.toLowerCase()
          : 'geral';

      // geometria
      final ScheduleRoadData? g =
      await _repo.fetchProjectGeometry(contractId);
      final geometryType = g?.geometryType;
      final multiLine = g?.multiLine;
      final points = g?.points;

      final axis = _axisFrom(
        geometryType: geometryType,
        multiLine: multiLine,
        points: points,
      );
      final derived = _deriveTotalEstacasFromAxis(axis);
      final effectiveTotalEstacas =
      (derived > 0) ? derived : (totalEstacas ?? 0);

      // execuções do serviço atual
      final meta = _currentMeta(
        state.copyWith(services: services, currentServiceKey: currentKey),
      );
      final execs = await _repo.fetchExecucoes(
        contractId: contractId,
        selectedServiceKey: currentKey,
        serviceKeysForGeral:
        services.where((s) => s.key != 'geral').map((s) => s.key).toList(),
        metaForSelected: meta,
      );

      // Converte physfin (índice) -> (nome) para a UI
      final gridByName = _gridIndexToName(phys.grid, services);

      emit(
        state.copyWith(
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
          totalEstacas: effectiveTotalEstacas,
          physfinPeriods: phys.periods,
          physfinGrid: gridByName, // UI vê por nome
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          loadingServices: false,
          loadingLanes: false,
          loadingExecucoes: false,
          savingOrImporting: false,
          error: '$err',
        ),
      );
    }
  }

  /// Recarrega serviços, faixas, execuções, physfin e geometria para o contrato atual.
  Future<void> refresh() async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;

    emit(
      state.copyWith(
        loadingServices: true,
        loadingLanes: true,
        loadingExecucoes: true,
        savingOrImporting: true,
        error: null,
      ),
    );

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
        serviceKeysForGeral: _serviceKeysForGeral(
          state.copyWith(services: services),
        ),
        metaForSelected: _currentMeta(
          state.copyWith(services: services),
        ),
      );

      final axis = _axisFrom(
        geometryType: geometryType,
        multiLine: multiLine,
        points: points,
      );
      final maybeTotal = _deriveTotalEstacasFromAxis(axis);
      final nextTotal = maybeTotal > 0 ? maybeTotal : state.totalEstacas;

      final gridByName = _gridIndexToName(phys.grid, services);

      emit(
        state.copyWith(
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
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          loadingServices: false,
          loadingLanes: false,
          loadingExecucoes: false,
          savingOrImporting: false,
          error: '$err',
        ),
      );
    }
  }

  /// Troca o serviço atual (ASFALTO, BASE, GERAL, etc.).
  Future<void> selectService(String serviceKey) async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;

    final newKey = serviceKey.toLowerCase();
    if (newKey == state.currentServiceKey) return;

    emit(
      state.copyWith(
        currentServiceKey: newKey,
        loadingExecucoes: true,
        error: null,
      ),
    );

    try {
      final execs = await _repo.fetchExecucoes(
        contractId: cid,
        selectedServiceKey: newKey,
        serviceKeysForGeral: _serviceKeysForGeral(state),
        metaForSelected: _currentMeta(
          state.copyWith(currentServiceKey: newKey),
        ),
      );

      emit(
        state.copyWith(
          execucoes: execs,
          execIndex: _buildExecIndex(execs),
          minDate: _minD(execs),
          maxDate: _maxD(execs),
          loadingExecucoes: false,
          error: null,
        ),
      );
    } catch (err) {
      emit(state.copyWith(loadingExecucoes: false, error: '$err'));
    }
  }

  /// Salva faixas (lanes) e recarrega execuções.
  Future<void> saveLanes(List<ScheduleLaneClass> lanes) async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;

    emit(state.copyWith(loadingLanes: true, error: null));
    try {
      await _repo.saveFaixas(cid, lanes);
      final newLanes = await _repo.loadFaixas(cid);
      emit(state.copyWith(lanes: newLanes, loadingLanes: false, error: null));
      await reloadExecucoes();
    } catch (err) {
      emit(state.copyWith(loadingLanes: false, error: '$err'));
    }
  }

  /// Recarrega apenas execuções do serviço atual.
  Future<void> reloadExecucoes() async {
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
      emit(
        state.copyWith(
          execucoes: execs,
          execIndex: _buildExecIndex(execs),
          minDate: _minD(execs),
          maxDate: _maxD(execs),
          loadingExecucoes: false,
          error: null,
        ),
      );
    } catch (err) {
      emit(state.copyWith(loadingExecucoes: false, error: '$err'));
    }
  }

  /// Aplica alteração em uma única célula (estaca/faixa).
  ///
  /// Regras importantes:
  /// - Se status for "a iniciar", mas tiver comentário ou foto, sobe pra "em_andamento".
  /// - Se status final for "a_iniciar" E não tiver conteúdo, a célula é limpa.
  Future<void> applySquareToCell({
    required int estaca,
    required int faixaIndex,
    required String tipoLabel,
    required String status,
    String? comentario,
    DateTime? takenAt,
    required List<String> finalPhotoUrls,
    required List<Uint8List> newFilesBytes,
    List<String>? newFileNames,
    List<pm.CarouselMetadata> newPhotoMetas = const [],
    required String currentUserId,
    bool reloadAfter = true,
  }) async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;
    if (state.currentServiceKey == 'geral') return;

    try {
      // Conteúdo relevante: comentário + fotos (existentes + novas)
      final hasComment = (comentario?.trim().isNotEmpty ?? false);
      final hasPhotos =
          finalPhotoUrls.isNotEmpty || newFilesBytes.isNotEmpty;

      String canon0(String? s) {
        s = (s ?? '').toLowerCase();
        if (s.contains('conclu')) return 'concluido';
        if (s.contains('andament') || s.contains('progress')) {
          return 'em_andamento';
        }
        return 'a_iniciar';
      }

      // Normaliza status vindo do UI
      var canon = canon0(status);

      // 🔴 Regra: se o usuário não mexeu no status (a_iniciar),
      // mas adicionou comentário ou foto, considera pelo menos em_andamento.
      if (canon == 'a_iniciar' && (hasComment || hasPhotos)) {
        canon = 'em_andamento';
      }

      final uploadedUrls = await _repo.applySquareChanges(
        contractId: cid,
        serviceKey: state.currentServiceKey,
        estaca: estaca,
        faixaIndex: faixaIndex,
        tipoLabel: tipoLabel,
        status: canon, // 👈 já envia status "corrigido"
        comentario: comentario,
        takenAtForNew: takenAt,
        finalPhotoUrls: finalPhotoUrls,
        newFilesBytes: newFilesBytes,
        newFileNames: newFileNames,
        newPhotoMetas: newPhotoMetas,
        currentUserId: currentUserId,
      );

      final list = [...state.execucoes];
      final idx =
      list.indexWhere((x) => x.numero == estaca && x.faixaIndex == faixaIndex);
      final meta = _currentMeta(state);
      final now = DateTime.now();

      // Se status final for realmente "a_iniciar", limpa a célula
      if (canon == 'a_iniciar') {
        if (idx != -1) list.removeAt(idx);

        emit(
          state.copyWith(
            execucoes: List.unmodifiable(list),
            execIndex: _buildExecIndex(list),
            minDate: _minD(list),
            maxDate: _maxD(list),
            error: null,
          ),
        );

        if (reloadAfter) {
          await reloadExecucoes();
        }
        return;
      }

      // A partir daqui é concluído / em andamento
      final prev = idx != -1 ? list[idx] : null;
      final finalFotos = <String>[...finalPhotoUrls, ...uploadedUrls];

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
          'uploadedBy': currentUserId,
        };
      }).toList();

      final updated = ScheduleRoadData(
        numero: estaca,
        faixaIndex: faixaIndex,
        tipo: tipoLabel,
        status: canon,
        comentario:
        (comentario?.trim().isEmpty ?? true) ? null : comentario!.trim(),
        createdAt: prev?.createdAt ?? now,
        createdBy: prev?.createdBy ?? currentUserId,
        updatedAt: now,
        updatedBy: currentUserId,
        key: meta.key,
        label: meta.label,
        icon: meta.icon,
        color: meta.color,
        fotos: finalFotos,
        fotosMeta: metasOrdered,
        takenAtMs: (takenAt != null)
            ? takenAt.millisecondsSinceEpoch
            : prev?.takenAtMs,
      );

      if (idx == -1) {
        list.add(updated);
      } else {
        list[idx] = updated;
      }

      emit(
        state.copyWith(
          execucoes: List.unmodifiable(list),
          execIndex: _buildExecIndex(list),
          minDate: _minD(list),
          maxDate: _maxD(list),
          error: null,
        ),
      );

      if (reloadAfter) {
        await reloadExecucoes();
      }
    } catch (err) {
      emit(state.copyWith(error: '$err'));
    }
  }

  // ===================== MAPA =====================

  Future<void> importGeoJson({
    required Map<String, dynamic> geojson,
    String? summarySubjectContract,
  }) async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;
    emit(state.copyWith(savingOrImporting: true, error: null));
    try {
      final ScheduleRoadData saved = await _repo.importGeoJson(
        contractId: cid,
        geojson: geojson,
        summarySubjectContract:
        summarySubjectContract ?? state.summarySubjectContract,
      );
      emit(
        state.copyWith(
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
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          savingOrImporting: false,
          error: err.toString(),
        ),
      );
    }
  }

  Future<void> upsertProjectGeometry(ScheduleRoadData data) async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;

    emit(state.copyWith(savingOrImporting: true, error: null));
    try {
      final ScheduleRoadData saved = await _repo.upsertProjectGeometry(
        contractId: cid,
        data: data,
        summarySubjectContract: state.summarySubjectContract,
      );
      emit(
        state.copyWith(
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
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          savingOrImporting: false,
          error: err.toString(),
        ),
      );
    }
  }

  Future<void> deleteProjectGeometry() async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;
    emit(state.copyWith(savingOrImporting: true, error: null));
    try {
      await _repo.deleteProjectGeometry(cid);
      emit(
        state.copyWith(
          savingOrImporting: false,
          geometryType: null,
          multiLine: null,
          points: null,
          totalEstacas: 0,
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          savingOrImporting: false,
          error: err.toString(),
        ),
      );
    }
  }

  // ===================== PHYS/FIN =====================

  /// Atualiza periods + grid na memória e persiste no Firestore.
  ///
  /// A UI sempre trabalha com `grid` por NOME; na gravação convertemos para ÍNDICE.
  Future<void> updatePhysFinGrid({
    required List<int> periods,
    required Map<String, List<double>> grid,
    String? updatedBy,
  }) async {
    final cid = state.contractId;
    if (cid == null || cid.isEmpty) return;

    // Converte NOME -> ÍNDICE para gravar
    final gridIdx = _gridNameToIndex(grid, state.services);

    // Atualiza estado imediatamente (UI continua por nome)
    emit(
      state.copyWith(
        physfinPeriods: periods,
        physfinGrid: grid,
      ),
    );

    try {
      await _repo.savePhysFinGrid(
        contractId: cid,
        periods: periods,
        grid: gridIdx, // grava por índice
        updatedBy: updatedBy,
      );
    } catch (_) {
      // Se der erro na gravação, mantemos o estado local e deixamos a correção
      // para um refresh manual. (Evita travar a UI.)
    }
  }

  // ===================== MAP UI HELPERS =====================

  void setSelectedPolyline(String? polylineId) {
    emit(state.copyWith(selectedPolylineId: polylineId));
  }

  void setMapZoom(double zoom) {
    final z = double.parse(zoom.toStringAsFixed(2));
    if ((state.mapZoom - z).abs() >= 0.05) {
      emit(state.copyWith(mapZoom: z));
    }
  }
}
