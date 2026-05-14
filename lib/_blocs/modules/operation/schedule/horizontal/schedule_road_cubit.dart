import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/line_segmentation.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_repository.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_state.dart';
import 'package:sipged/_widgets/images/carousel/carousel_metadata.dart' as pm;

class ScheduleRoadCubit extends Cubit<ScheduleRoadState> {
  final ScheduleRoadRepository _repo;

  bool _warmingUp = false;
  String? _warmingUpContractId;

  ScheduleRoadCubit({
    required String tenantId,
    ScheduleRoadRepository? repository,
  })  : _repo = repository ?? ScheduleRoadRepository(tenantId: tenantId),
        super(const ScheduleRoadState());

  bool _isIndexKey(String k) => RegExp(r'^\d+$').hasMatch(k);

  String _idxOf(int i) => (i + 1).toString().padLeft(3, '0');

  List<ScheduleRoadData> _validServices(List<ScheduleRoadData> all) {
    return all.where((s) => s.key.toLowerCase() != 'geral').toList(
      growable: false,
    );
  }

  Map<String, String> _nameToIndex(List<ScheduleRoadData> services) {
    final validServices = _validServices(services);
    final map = <String, String>{};

    for (int i = 0; i < validServices.length; i++) {
      map[validServices[i].key] = _idxOf(i);
    }

    return map;
  }

  Map<String, String> _indexToName(List<ScheduleRoadData> services) {
    final validServices = _validServices(services);
    final map = <String, String>{};

    for (int i = 0; i < validServices.length; i++) {
      map[_idxOf(i)] = validServices[i].key;
    }

    return map;
  }

  Map<String, List<double>> _gridNameToIndex(
      Map<String, List<double>> byName,
      List<ScheduleRoadData> services,
      ) {
    final map = _nameToIndex(services);
    final out = <String, List<double>>{};

    byName.forEach((key, value) {
      final idx = _isIndexKey(key) ? key : (map[key] ?? key);

      out[idx] = List<double>.from(
        value,
        growable: false,
      );
    });

    return out;
  }

  Map<String, List<double>> _gridIndexToName(
      Map<String, List<double>> byIndex,
      List<ScheduleRoadData> services,
      ) {
    final map = _indexToName(services);
    final out = <String, List<double>>{};

    byIndex.forEach((key, value) {
      final name = _isIndexKey(key) ? (map[key] ?? key) : key;

      out[name] = List<double>.from(
        value,
        growable: false,
      );
    });

    return out;
  }

  ScheduleRoadData _currentMeta(ScheduleRoadState state) {
    if (state.services.isEmpty) return ScheduleRoadData.emptyGeral;

    return state.services.firstWhere(
          (service) => service.key == state.currentServiceKey,
      orElse: () => state.services.first,
    );
  }

  List<String> _serviceKeysForGeral(ScheduleRoadState state) {
    return state.services
        .where((service) => service.key.toLowerCase() != 'geral')
        .map((service) => service.key)
        .toList(growable: false);
  }

  Map<int, Map<int, ScheduleRoadData>> _buildExecIndex(
      List<ScheduleRoadData> list,
      ) {
    final map = <int, Map<int, ScheduleRoadData>>{};

    for (final item in list) {
      final inner = map.putIfAbsent(
        item.numero,
            () => <int, ScheduleRoadData>{},
      );

      inner[item.faixaIndex] = item;
    }

    return map;
  }

  DateTime? _cellDate(ScheduleRoadData item) {
    return item.takenAt ?? item.updatedAt ?? item.createdAt;
  }

  DateTime? _minD(List<ScheduleRoadData> items) {
    DateTime? date;

    for (final item in items) {
      final current = _cellDate(item);

      if (current == null) continue;

      if (date == null || current.isBefore(date)) {
        date = current;
      }
    }

    return date;
  }

  DateTime? _maxD(List<ScheduleRoadData> items) {
    DateTime? date;

    for (final item in items) {
      final current = _cellDate(item);

      if (current == null) continue;

      if (date == null || current.isAfter(date)) {
        date = current;
      }
    }

    return date;
  }

  List<LatLng> _axisFrom({
    List<List<LatLng>>? multiLine,
    List<LatLng>? points,
  }) {
    return ScheduleRoadState.axisFrom(
      multiLine: multiLine,
      points: points,
    );
  }

  int _deriveTotalEstacasFromGeometry({
    List<List<LatLng>>? multiLine,
    List<LatLng>? points,
  }) {
    if (multiLine != null && multiLine.isNotEmpty) {
      var total = 0;

      for (final segment in multiLine) {
        if (segment.length < 2) continue;

        final segmented = splitAxisByFixedStep(
          axis: segment,
          stepMeters: 20.0,
        );

        total += segmented.segments.length;
      }

      return total;
    }

    if (points != null && points.length >= 2) {
      final segmented = splitAxisByFixedStep(
        axis: points,
        stepMeters: 20.0,
      );

      return segmented.segments.length;
    }

    return 0;
  }

  String _canon0(String? value) {
    final normalized = (value ?? '').toLowerCase();

    if (normalized.contains('conclu')) return 'concluido';

    if (normalized.contains('andament') || normalized.contains('progress')) {
      return 'em_andamento';
    }

    return 'a_iniciar';
  }

  Future<void> warmup({
    required String contractId,
    int? totalEstacas,
    String initialServiceKey = 'geral',
    String? summarySubjectContract,
  }) async {
    if (_warmingUp && _warmingUpContractId == contractId) {
      return;
    }

    if (state.initialized && state.contractId == contractId && !_warmingUp) {
      return;
    }

    _warmingUp = true;
    _warmingUpContractId = contractId;

    emit(
      state.copyWith(
        contractId: contractId,
        summarySubjectContract: summarySubjectContract,
        currentServiceKey: initialServiceKey.toLowerCase(),
        loadingServices: true,
        loadingLanes: true,
        loadingExecucoes: true,
        savingOrImporting: true,
        busyReason: 'warmup',
        error: null,
      ),
    );

    try {
      _repo.clearContractCache(contractId);

      await _repo.ensureDefaultLaneIfMissing(contractId);

      final services = await _repo.loadAvailableServicesFromBudget(contractId);
      final lanes = await _repo.loadFaixas(contractId);
      final totals = await _repo.fetchBudgetServiceTotals(contractId);
      final phys = await _repo.loadPhysFinGrid(contractId);
      final geometry = await _repo.fetchProjectGeometry(contractId);

      final geometryType = geometry?.geometryType;
      final multiLine = geometry?.multiLine;
      final points = geometry?.points;

      final axis = _axisFrom(
        multiLine: multiLine,
        points: points,
      );

      final derived = _deriveTotalEstacasFromGeometry(
        multiLine: multiLine,
        points: points,
      );

      final effectiveTotalEstacas = derived > 0 ? derived : (totalEstacas ?? 0);

      final initialKey = initialServiceKey.toLowerCase();
      final currentKey = services.any((service) => service.key == initialKey)
          ? initialKey
          : 'geral';

      final tempState = state.copyWith(
        services: services,
        currentServiceKey: currentKey,
      );

      final meta = _currentMeta(tempState);

      final execs = await _repo.fetchExecucoes(
        contractId: contractId,
        selectedServiceKey: currentKey,
        serviceKeysForGeral: _serviceKeysForGeral(tempState),
        metaForSelected: meta,
      );

      final gridByName = _gridIndexToName(
        phys.grid,
        services,
      );

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
          busyReason: null,
          error: null,
          currentServiceKey: currentKey,
          geometryType: geometryType,
          multiLine: multiLine,
          points: points,
          axis: axis,
          totalEstacas: effectiveTotalEstacas,
          physfinPeriods: phys.periods,
          physfinGrid: gridByName,
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          loadingServices: false,
          loadingLanes: false,
          loadingExecucoes: false,
          savingOrImporting: false,
          busyReason: null,
          error: '$err',
        ),
      );
    } finally {
      _warmingUp = false;
      _warmingUpContractId = null;
    }
  }

  Future<void> refresh() async {
    final contractId = state.contractId;

    if (contractId == null || contractId.isEmpty) return;

    emit(
      state.copyWith(
        loadingServices: true,
        loadingLanes: true,
        loadingExecucoes: true,
        savingOrImporting: true,
        busyReason: 'refresh',
        error: null,
      ),
    );

    try {
      _repo.clearContractCache(contractId);

      await _repo.ensureDefaultLaneIfMissing(contractId);

      final services = await _repo.loadAvailableServicesFromBudget(contractId);
      final lanes = await _repo.loadFaixas(contractId);
      final totals = await _repo.fetchBudgetServiceTotals(contractId);
      final phys = await _repo.loadPhysFinGrid(contractId);
      final geometry = await _repo.fetchProjectGeometry(contractId);

      final geometryType = geometry?.geometryType;
      final multiLine = geometry?.multiLine;
      final points = geometry?.points;

      final axis = _axisFrom(
        multiLine: multiLine,
        points: points,
      );

      final tempState = state.copyWith(
        services: services,
      );

      final currentStillExists = services.any(
            (service) => service.key == state.currentServiceKey,
      );

      final nextCurrentKey = currentStillExists ? state.currentServiceKey : 'geral';

      final stateForExec = tempState.copyWith(
        currentServiceKey: nextCurrentKey,
      );

      final execs = await _repo.fetchExecucoes(
        contractId: contractId,
        selectedServiceKey: nextCurrentKey,
        serviceKeysForGeral: _serviceKeysForGeral(stateForExec),
        metaForSelected: _currentMeta(stateForExec),
      );

      final maybeTotal = _deriveTotalEstacasFromGeometry(
        multiLine: multiLine,
        points: points,
      );

      final nextTotal = maybeTotal > 0 ? maybeTotal : state.totalEstacas;

      final gridByName = _gridIndexToName(
        phys.grid,
        services,
      );

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
          busyReason: null,
          error: null,
          currentServiceKey: nextCurrentKey,
          geometryType: geometryType,
          multiLine: multiLine,
          points: points,
          axis: axis,
          totalEstacas: nextTotal,
          physfinPeriods: phys.periods,
          physfinGrid: gridByName,
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          loadingServices: false,
          loadingLanes: false,
          loadingExecucoes: false,
          savingOrImporting: false,
          busyReason: null,
          error: '$err',
        ),
      );
    }
  }

  Future<void> selectService(String serviceKey) async {
    final contractId = state.contractId;

    if (contractId == null || contractId.isEmpty) return;

    final newKey = serviceKey.toLowerCase();

    if (newKey == state.currentServiceKey) return;

    final exists = state.services.any((service) => service.key == newKey);

    if (!exists) return;

    emit(
      state.copyWith(
        currentServiceKey: newKey,
        loadingExecucoes: true,
        error: null,
      ),
    );

    try {
      final nextState = state.copyWith(
        currentServiceKey: newKey,
      );

      final execs = await _repo.fetchExecucoes(
        contractId: contractId,
        selectedServiceKey: newKey,
        serviceKeysForGeral: _serviceKeysForGeral(nextState),
        metaForSelected: _currentMeta(nextState),
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
      emit(
        state.copyWith(
          loadingExecucoes: false,
          error: '$err',
        ),
      );
    }
  }

  Future<void> saveScheduleConfiguration({
    required List<ScheduleRoadData> lanes,
    required List<ScheduleRoadData> services,
  }) async {
    final contractId = state.contractId;

    if (contractId == null || contractId.isEmpty) return;

    emit(
      state.copyWith(
        loadingServices: true,
        loadingLanes: true,
        savingOrImporting: true,
        busyReason: 'save_schedule_configuration',
        error: null,
      ),
    );

    try {
      await _repo.saveScheduleConfiguration(
        contractId: contractId,
        lanes: lanes,
        services: services,
      );

      final newServices = await _repo.loadAvailableServicesFromBudget(contractId);
      final newLanes = await _repo.loadFaixas(contractId);
      final totals = await _repo.fetchBudgetServiceTotals(contractId);

      final currentStillExists = newServices.any(
            (service) => service.key == state.currentServiceKey,
      );

      final nextCurrentKey = currentStillExists ? state.currentServiceKey : 'geral';

      final tempState = state.copyWith(
        services: newServices,
        lanes: newLanes,
        currentServiceKey: nextCurrentKey,
      );

      final execs = await _repo.fetchExecucoes(
        contractId: contractId,
        selectedServiceKey: nextCurrentKey,
        serviceKeysForGeral: _serviceKeysForGeral(tempState),
        metaForSelected: _currentMeta(tempState),
      );

      emit(
        state.copyWith(
          services: newServices,
          serviceTotals: totals,
          lanes: newLanes,
          currentServiceKey: nextCurrentKey,
          execucoes: execs,
          execIndex: _buildExecIndex(execs),
          minDate: _minD(execs),
          maxDate: _maxD(execs),
          loadingServices: false,
          loadingLanes: false,
          loadingExecucoes: false,
          savingOrImporting: false,
          busyReason: null,
          error: null,
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          loadingServices: false,
          loadingLanes: false,
          savingOrImporting: false,
          busyReason: null,
          error: '$err',
        ),
      );
    }
  }

  Future<void> saveLanes(List<ScheduleRoadData> lanes) async {
    await saveScheduleConfiguration(
      lanes: lanes,
      services: state.services.isEmpty
          ? const <ScheduleRoadData>[
        ScheduleRoadData.emptyGeral,
      ]
          : state.services,
    );
  }

  Future<void> reloadExecucoes() async {
    final contractId = state.contractId;

    if (contractId == null || contractId.isEmpty) return;

    emit(
      state.copyWith(
        loadingExecucoes: true,
        error: null,
      ),
    );

    try {
      final execs = await _repo.fetchExecucoes(
        contractId: contractId,
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
      emit(
        state.copyWith(
          loadingExecucoes: false,
          error: '$err',
        ),
      );
    }
  }

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
    final contractId = state.contractId;

    if (contractId == null || contractId.isEmpty) return;
    if (state.currentServiceKey == 'geral') return;

    try {
      final hasComment = comentario?.trim().isNotEmpty ?? false;
      final hasPhotos = finalPhotoUrls.isNotEmpty || newFilesBytes.isNotEmpty;

      var canon = _canon0(status);

      if (canon == 'a_iniciar' && (hasComment || hasPhotos)) {
        canon = 'em_andamento';
      }

      final uploadedUrls = await _repo.applySquareChanges(
        contractId: contractId,
        serviceKey: state.currentServiceKey,
        estaca: estaca,
        faixaIndex: faixaIndex,
        tipoLabel: tipoLabel,
        status: canon,
        comentario: comentario,
        takenAtForNew: takenAt,
        finalPhotoUrls: finalPhotoUrls,
        newFilesBytes: newFilesBytes,
        newFileNames: newFileNames,
        newPhotoMetas: newPhotoMetas,
        currentUserId: currentUserId,
      );

      final list = List<ScheduleRoadData>.from(state.execucoes);

      final idx = list.indexWhere(
            (item) => item.numero == estaca && item.faixaIndex == faixaIndex,
      );

      final meta = _currentMeta(state);
      final now = DateTime.now();

      if (canon == 'a_iniciar') {
        if (idx != -1) {
          list.removeAt(idx);
        }

        emit(
          state.copyWith(
            execucoes: List<ScheduleRoadData>.unmodifiable(list),
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

      final prev = idx != -1 ? list[idx] : null;
      final finalFotos = <String>[...finalPhotoUrls, ...uploadedUrls];

      final prevMetas = prev?.fotosMeta ?? const <Map<String, dynamic>>[];

      final byUrl = <String, Map<String, dynamic>>{
        for (final metaMap in prevMetas)
          if ((metaMap['url'] as String?)?.isNotEmpty ?? false)
            (metaMap['url'] as String): Map<String, dynamic>.from(metaMap),
      };

      final metasOrdered = finalFotos.map((url) {
        final metaMap = byUrl[url];

        if (metaMap != null) {
          return Map<String, dynamic>.from(metaMap);
        }

        return <String, dynamic>{
          'url': url,
          'name': url.split('/').last,
          'uploadedAtMs': now.millisecondsSinceEpoch,
          'uploadedBy': currentUserId,
        };
      }).toList(growable: false);

      final updated = ScheduleRoadData(
        numero: estaca,
        faixaIndex: faixaIndex,
        tipo: tipoLabel,
        status: canon,
        comentario: (comentario?.trim().isEmpty ?? true)
            ? null
            : comentario!.trim(),
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
        takenAtMs:
        takenAt != null ? takenAt.millisecondsSinceEpoch : prev?.takenAtMs,
      );

      if (idx == -1) {
        list.add(updated);
      } else {
        list[idx] = updated;
      }

      emit(
        state.copyWith(
          execucoes: List<ScheduleRoadData>.unmodifiable(list),
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
      emit(
        state.copyWith(
          error: '$err',
        ),
      );
    }
  }

  Future<void> importGeoJson({
    required Map<String, dynamic> geojson,
    String? summarySubjectContract,
  }) async {
    final contractId = state.contractId;

    if (contractId == null || contractId.isEmpty) return;

    emit(
      state.copyWith(
        savingOrImporting: true,
        busyReason: 'import_geojson',
        error: null,
      ),
    );

    try {
      final saved = await _repo.importGeoJson(
        contractId: contractId,
        geojson: geojson,
        summarySubjectContract:
        summarySubjectContract ?? state.summarySubjectContract,
      );

      final axis = _axisFrom(
        multiLine: saved.multiLine,
        points: saved.points,
      );

      emit(
        state.copyWith(
          savingOrImporting: false,
          busyReason: null,
          geometryType: saved.geometryType,
          multiLine: saved.multiLine,
          points: saved.points,
          axis: axis,
          totalEstacas: _deriveTotalEstacasFromGeometry(
            multiLine: saved.multiLine,
            points: saved.points,
          ),
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          savingOrImporting: false,
          busyReason: null,
          error: err.toString(),
        ),
      );
    }
  }

  Future<void> upsertProjectGeometry(ScheduleRoadData data) async {
    final contractId = state.contractId;

    if (contractId == null || contractId.isEmpty) return;

    emit(
      state.copyWith(
        savingOrImporting: true,
        busyReason: 'upsert_geometry',
        error: null,
      ),
    );

    try {
      final saved = await _repo.upsertProjectGeometry(
        contractId: contractId,
        data: data,
        summarySubjectContract: state.summarySubjectContract,
      );

      final axis = _axisFrom(
        multiLine: saved.multiLine,
        points: saved.points,
      );

      emit(
        state.copyWith(
          savingOrImporting: false,
          busyReason: null,
          geometryType: saved.geometryType,
          multiLine: saved.multiLine,
          points: saved.points,
          axis: axis,
          totalEstacas: _deriveTotalEstacasFromGeometry(
            multiLine: saved.multiLine,
            points: saved.points,
          ),
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          savingOrImporting: false,
          busyReason: null,
          error: err.toString(),
        ),
      );
    }
  }

  Future<void> deleteProjectGeometry() async {
    final contractId = state.contractId;

    if (contractId == null || contractId.isEmpty) return;

    emit(
      state.copyWith(
        savingOrImporting: true,
        busyReason: 'delete_geometry',
        error: null,
      ),
    );

    try {
      await _repo.deleteProjectGeometry(contractId);

      emit(
        state.copyWith(
          savingOrImporting: false,
          busyReason: null,
          geometryType: null,
          multiLine: null,
          points: null,
          axis: const <LatLng>[],
          totalEstacas: 0,
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          savingOrImporting: false,
          busyReason: null,
          error: err.toString(),
        ),
      );
    }
  }

  Future<void> updatePhysFinGrid({
    required List<int> periods,
    required Map<String, List<double>> grid,
    String? updatedBy,
  }) async {
    final contractId = state.contractId;

    if (contractId == null || contractId.isEmpty) return;

    final gridIdx = _gridNameToIndex(
      grid,
      state.services,
    );

    emit(
      state.copyWith(
        physfinPeriods: List<int>.unmodifiable(periods),
        physfinGrid: {
          for (final entry in grid.entries)
            entry.key: List<double>.unmodifiable(entry.value),
        },
      ),
    );

    try {
      await _repo.savePhysFinGrid(
        contractId: contractId,
        periods: periods,
        grid: gridIdx,
        updatedBy: updatedBy,
      );
    } catch (err) {
      emit(
        state.copyWith(
          error: '$err',
        ),
      );
    }
  }

  void setSelectedPolyline(String? polylineId) {
    if (state.selectedPolylineId == polylineId) return;

    emit(
      state.copyWith(
        selectedPolylineId: polylineId,
      ),
    );
  }

  void setMapZoom(double zoom) {
    final normalized = double.parse(
      zoom.toStringAsFixed(2),
    );

    if ((state.mapZoom - normalized).abs() >= 0.05) {
      emit(
        state.copyWith(
          mapZoom: normalized,
        ),
      );
    }
  }
}