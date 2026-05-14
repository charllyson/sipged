import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_data.dart';

class ScheduleRoadState extends Equatable {
  final bool initialized;

  final String? contractId;
  final String? summarySubjectContract;

  final int totalEstacas;
  final String currentServiceKey;

  /// Serviços configurados manualmente em:
  /// /tenants/{tenantId}/contracts/{contractId}/schedule/lanes
  ///
  /// O primeiro item normalmente é o GERAL.
  final List<ScheduleRoadData> services;

  /// Faixas configuradas manualmente em:
  /// /tenants/{tenantId}/contracts/{contractId}/schedule/lanes
  final List<ScheduleRoadData> lanes;

  /// Células/estacas salvas em:
  /// /tenants/{tenantId}/contracts/{contractId}/schedule/cells/items
  final List<ScheduleRoadData> execucoes;

  final Map<int, Map<int, ScheduleRoadData>> execIndex;

  final DateTime? minDate;
  final DateTime? maxDate;

  final bool loadingServices;
  final bool loadingLanes;
  final bool loadingExecucoes;
  final bool savingOrImporting;

  final String? error;

  final String? geometryType;
  final List<List<LatLng>>? multiLine;
  final List<LatLng>? points;
  final List<LatLng> axis;

  final Map<String, double> serviceTotals;
  final List<int> physfinPeriods;
  final Map<String, List<double>> physfinGrid;

  final String? selectedPolylineId;
  final double mapZoom;
  final String? busyReason;

  final int servicesRevision;
  final int lanesRevision;
  final int execRevision;
  final int geometryRevision;
  final int physfinRevision;

  const ScheduleRoadState({
    this.initialized = false,
    this.contractId,
    this.summarySubjectContract,
    this.totalEstacas = 0,
    this.currentServiceKey = 'geral',
    this.services = const <ScheduleRoadData>[],
    this.lanes = const <ScheduleRoadData>[],
    this.execucoes = const <ScheduleRoadData>[],
    this.execIndex = const <int, Map<int, ScheduleRoadData>>{},
    this.minDate,
    this.maxDate,
    this.loadingServices = false,
    this.loadingLanes = false,
    this.loadingExecucoes = false,
    this.savingOrImporting = false,
    this.error,
    this.geometryType,
    this.multiLine,
    this.points,
    this.axis = const <LatLng>[],
    this.serviceTotals = const <String, double>{},
    this.physfinPeriods = const <int>[],
    this.physfinGrid = const <String, List<double>>{},
    this.selectedPolylineId,
    this.mapZoom = 12.0,
    this.busyReason,
    this.servicesRevision = 0,
    this.lanesRevision = 0,
    this.execRevision = 0,
    this.geometryRevision = 0,
    this.physfinRevision = 0,
  });

  static List<LatLng> axisFrom({
    required List<List<LatLng>>? multiLine,
    required List<LatLng>? points,
  }) {
    if (multiLine != null && multiLine.isNotEmpty) {
      return multiLine.expand((segment) => segment).toList(growable: false);
    }

    if (points != null && points.isNotEmpty) {
      return List<LatLng>.from(points, growable: false);
    }

    return const <LatLng>[];
  }

  ScheduleRoadState copyWith({
    bool? initialized,
    String? contractId,
    String? summarySubjectContract,
    int? totalEstacas,
    String? currentServiceKey,
    List<ScheduleRoadData>? services,
    List<ScheduleRoadData>? lanes,
    List<ScheduleRoadData>? execucoes,
    Map<int, Map<int, ScheduleRoadData>>? execIndex,
    DateTime? minDate,
    DateTime? maxDate,
    bool? loadingServices,
    bool? loadingLanes,
    bool? loadingExecucoes,
    bool? savingOrImporting,
    String? error,
    Object? geometryType = const _Unset(),
    Object? multiLine = const _Unset(),
    Object? points = const _Unset(),
    Object? axis = const _Unset(),
    Map<String, double>? serviceTotals,
    List<int>? physfinPeriods,
    Map<String, List<double>>? physfinGrid,
    Object? selectedPolylineId = const _Unset(),
    double? mapZoom,
    Object? busyReason = const _Unset(),
    int? servicesRevision,
    int? lanesRevision,
    int? execRevision,
    int? geometryRevision,
    int? physfinRevision,
  }) {
    final nextServices = services ?? this.services;
    final nextLanes = lanes ?? this.lanes;
    final nextExecucoes = execucoes ?? this.execucoes;
    final nextExecIndex = execIndex ?? this.execIndex;

    final nextGeometryType =
    geometryType is _Unset ? this.geometryType : geometryType as String?;

    final nextMultiLine = multiLine is _Unset
        ? this.multiLine
        : multiLine as List<List<LatLng>>?;

    final nextPoints = points is _Unset ? this.points : points as List<LatLng>?;

    final nextAxis = axis is _Unset ? this.axis : axis as List<LatLng>;

    final nextServiceTotals = serviceTotals ?? this.serviceTotals;
    final nextPhysfinPeriods = physfinPeriods ?? this.physfinPeriods;
    final nextPhysfinGrid = physfinGrid ?? this.physfinGrid;

    return ScheduleRoadState(
      initialized: initialized ?? this.initialized,
      contractId: contractId ?? this.contractId,
      summarySubjectContract:
      summarySubjectContract ?? this.summarySubjectContract,
      totalEstacas: totalEstacas ?? this.totalEstacas,
      currentServiceKey: currentServiceKey ?? this.currentServiceKey,
      services: nextServices,
      lanes: nextLanes,
      execucoes: nextExecucoes,
      execIndex: nextExecIndex,
      minDate: minDate ?? this.minDate,
      maxDate: maxDate ?? this.maxDate,
      loadingServices: loadingServices ?? this.loadingServices,
      loadingLanes: loadingLanes ?? this.loadingLanes,
      loadingExecucoes: loadingExecucoes ?? this.loadingExecucoes,
      savingOrImporting: savingOrImporting ?? this.savingOrImporting,
      error: error,
      geometryType: nextGeometryType,
      multiLine: nextMultiLine,
      points: nextPoints,
      axis: nextAxis,
      serviceTotals: nextServiceTotals,
      physfinPeriods: nextPhysfinPeriods,
      physfinGrid: nextPhysfinGrid,
      selectedPolylineId: selectedPolylineId is _Unset
          ? this.selectedPolylineId
          : selectedPolylineId as String?,
      mapZoom: mapZoom ?? this.mapZoom,
      busyReason: busyReason is _Unset ? this.busyReason : busyReason as String?,
      servicesRevision: servicesRevision ??
          (services != null || serviceTotals != null
              ? this.servicesRevision + 1
              : this.servicesRevision),
      lanesRevision: lanesRevision ??
          (lanes != null ? this.lanesRevision + 1 : this.lanesRevision),
      execRevision: execRevision ??
          (execucoes != null ||
              execIndex != null ||
              minDate != null ||
              maxDate != null
              ? this.execRevision + 1
              : this.execRevision),
      geometryRevision: geometryRevision ??
          ((geometryType is! _Unset ||
              multiLine is! _Unset ||
              points is! _Unset ||
              axis is! _Unset ||
              totalEstacas != null)
              ? this.geometryRevision + 1
              : this.geometryRevision),
      physfinRevision: physfinRevision ??
          (physfinPeriods != null || physfinGrid != null
              ? this.physfinRevision + 1
              : this.physfinRevision),
    );
  }

  @override
  List<Object?> get props => [
    initialized,
    contractId,
    summarySubjectContract,
    totalEstacas,
    currentServiceKey,
    minDate,
    maxDate,
    loadingServices,
    loadingLanes,
    loadingExecucoes,
    savingOrImporting,
    error,
    selectedPolylineId,
    mapZoom,
    busyReason,
    servicesRevision,
    lanesRevision,
    execRevision,
    geometryRevision,
    physfinRevision,
  ];

  bool get isBusy => busyReason != null || savingOrImporting;

  UnmodifiableListView<LatLng> get axisView {
    return UnmodifiableListView<LatLng>(axis);
  }

  bool get isGeral => currentServiceKey.toLowerCase() == 'geral';

  bool get hasServices => services.isNotEmpty;

  bool get hasSpecificServices {
    return services.any((service) => service.key.toLowerCase() != 'geral');
  }

  List<ScheduleRoadData> get specificServices {
    return services
        .where((service) => service.key.toLowerCase() != 'geral')
        .toList(growable: false);
  }

  bool _laneEnabled(ScheduleRoadData lane) {
    if (isGeral) return true;

    return lane.isAllowed(currentServiceKey);
  }

  bool _cellEnabled(ScheduleRoadData cell) {
    if (cell.faixaIndex < 0 || cell.faixaIndex >= lanes.length) {
      return false;
    }

    if (isGeral) {
      final serviceKey = cell.key.toLowerCase().trim();

      if (serviceKey.isEmpty || serviceKey == 'geral') {
        return true;
      }

      return lanes[cell.faixaIndex].isAllowed(serviceKey);
    }

    return _laneEnabled(lanes[cell.faixaIndex]);
  }

  int get enabledLaneCount {
    if (lanes.isEmpty) return 0;

    return lanes.where(_laneEnabled).length;
  }

  int get totalEsperado {
    if (lanes.isEmpty || totalEstacas <= 0) return 0;

    if (isGeral) {
      final serviceCount = specificServices.length;

      if (serviceCount <= 0) {
        return totalEstacas * lanes.length;
      }

      var total = 0;

      for (final service in specificServices) {
        final serviceKey = service.key.toLowerCase();

        final enabledForService = lanes.where((lane) {
          return lane.isAllowed(serviceKey);
        }).length;

        total += totalEstacas * enabledForService;
      }

      return total;
    }

    final enabled = enabledLaneCount;

    if (enabled <= 0) return 0;

    return totalEstacas * enabled;
  }

  String _canonStatus(String? raw) {
    final text = (raw ?? '')
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[\-_]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    if (text.contains('conclu')) return 'concluido';

    if (text.contains('andament') || text.contains('in progress')) {
      return 'em_andamento';
    }

    if (text.contains('todo') || text.contains('a iniciar')) {
      return 'a_iniciar';
    }

    return 'a_iniciar';
  }

  int get concluidos {
    return execucoes
        .where(
          (cell) =>
      _cellEnabled(cell) && _canonStatus(cell.status) == 'concluido',
    )
        .length;
  }

  int get andamento {
    return execucoes
        .where(
          (cell) =>
      _cellEnabled(cell) && _canonStatus(cell.status) == 'em_andamento',
    )
        .length;
  }

  int get iniciados => concluidos + andamento;

  int get aIniciarCount {
    final remaining = totalEsperado - iniciados;

    return remaining < 0 ? 0 : remaining;
  }

  double get pctConcluido {
    if (totalEsperado == 0) return 0;

    final raw = (concluidos / totalEsperado) * 100.0;

    if (raw > 0 && raw < 1) return 1.0;

    return raw.clamp(0.0, 100.0);
  }

  double get pctAndamento {
    if (totalEsperado == 0) return 0;

    final raw = (andamento / totalEsperado) * 100.0;

    if (raw > 0 && raw < 1) return 1.0;

    return raw.clamp(0.0, 100.0);
  }

  double get pctAIniciar {
    if (totalEsperado == 0) return 0;

    final remaining = 100.0 - pctConcluido - pctAndamento;

    if (remaining < 0) return 0;

    return remaining.clamp(0.0, 100.0);
  }

  ScheduleRoadData get currentServiceMeta {
    if (services.isEmpty) return ScheduleRoadData.emptyGeral;

    return services.firstWhere(
          (service) => service.key == currentServiceKey,
      orElse: () {
        final geral = services.where((service) => service.key == 'geral');

        if (geral.isNotEmpty) {
          return geral.first;
        }

        return services.first;
      },
    );
  }

  String get titleForHeader {
    final meta = currentServiceMeta;

    final value = meta.label.isNotEmpty ? meta.label : meta.key;

    return value.toUpperCase();
  }

  Color get colorForHeader => currentServiceMeta.color;

  bool get canEditSingleCell => currentServiceKey != 'geral';

  bool get canBulkApply => currentServiceKey != 'geral';

  Set<String> selectionBetween(
      int estacaA,
      int faixaA,
      int estacaB,
      int faixaB,
      ) {
    final e0 = estacaA <= estacaB ? estacaA : estacaB;
    final e1 = estacaA <= estacaB ? estacaB : estacaA;
    final f0 = faixaA <= faixaB ? faixaA : faixaB;
    final f1 = faixaA <= faixaB ? faixaB : faixaA;

    final selection = <String>{};

    for (int e = e0; e <= e1; e++) {
      for (int f = f0; f <= f1; f++) {
        selection.add('${e}_$f');
      }
    }

    return selection;
  }

  List<String> fotosAtuaisFor(int estaca, int faixa) {
    final idxMap = execIndex[estaca];
    final found = idxMap != null ? idxMap[faixa] : null;

    if (found != null) {
      return List<String>.from(found.fotos, growable: false);
    }

    final idx = execucoes.indexWhere(
          (cell) => cell.numero == estaca && cell.faixaIndex == faixa,
    );

    return idx == -1
        ? const <String>[]
        : List<String>.from(execucoes[idx].fotos, growable: false);
  }

  List<String> fotosAtuaisForService({
    required String serviceKey,
    required int estaca,
    required int faixa,
  }) {
    final normalizedServiceKey = serviceKey.toLowerCase().trim();

    final idx = execucoes.indexWhere(
          (cell) =>
      cell.key.toLowerCase() == normalizedServiceKey &&
          cell.numero == estaca &&
          cell.faixaIndex == faixa,
    );

    return idx == -1
        ? const <String>[]
        : List<String>.from(execucoes[idx].fotos, growable: false);
  }

  static const double _kMaxWhiteBlendOldest = 0.60;

  DateTime? _dateForShade(ScheduleRoadData cell) {
    final dtTaken = cell.takenAt ??
        (cell.takenAtMs != null
            ? DateTime.fromMillisecondsSinceEpoch(cell.takenAtMs!)
            : null);

    return dtTaken ?? cell.updatedAt ?? cell.createdAt;
  }

  int _channel255(double normalized) {
    return (normalized * 255.0).round().clamp(0, 255);
  }

  Color _blendWithWhite(Color base, double amount) {
    final alpha = amount.clamp(0.0, 1.0);

    int mix(int c, int w, double a) {
      return (c + ((w - c) * a)).round().clamp(0, 255);
    }

    final baseR = _channel255(base.r);
    final baseG = _channel255(base.g);
    final baseB = _channel255(base.b);
    final baseA = _channel255(base.a);

    final r = mix(baseR, 255, alpha);
    final g = mix(baseG, 255, alpha);
    final b = mix(baseB, 255, alpha);

    return Color.fromARGB(baseA, r, g, b);
  }

  Color _shadeRelative(Color base, DateTime? date) {
    final minDLocal = minDate;
    final maxDLocal = maxDate;

    if (date == null || minDLocal == null || maxDLocal == null) {
      return base;
    }

    final totalMs =
        maxDLocal.millisecondsSinceEpoch - minDLocal.millisecondsSinceEpoch;

    if (totalMs <= 0) return base;

    final posMs = date.millisecondsSinceEpoch - minDLocal.millisecondsSinceEpoch;
    final t = (posMs / totalMs).clamp(0.0, 1.0);

    final blend = _kMaxWhiteBlendOldest * (1.0 - t);

    return _blendWithWhite(base, blend);
  }

  Color squareColor(ScheduleRoadData cell) {
    final hasPhotos = cell.fotos.isNotEmpty;
    final raw = (cell.status ?? '').trim();

    final status = raw.isEmpty && hasPhotos ? 'em_andamento' : _canonStatus(raw);

    late final Color base;

    if (currentServiceKey == 'geral') {
      if (status == 'concluido' || status == 'em_andamento') {
        final tag = (cell.tipo != null && cell.tipo!.trim().isNotEmpty)
            ? cell.tipo!
            : ((cell.key.isNotEmpty && cell.key.toLowerCase() != 'geral')
            ? cell.key
            : (cell.label.isNotEmpty ? cell.label : ''));

        final meta = services.where((service) {
          final key = service.key.toLowerCase().trim();
          final label = service.label.toLowerCase().trim();
          final normalizedTag = tag.toLowerCase().trim();

          return key == normalizedTag || label == normalizedTag;
        });

        base = meta.isNotEmpty
            ? meta.first.color
            : tag.isNotEmpty
            ? ScheduleRoadData.colorForService(tag)
            : Colors.blueGrey.shade300;
      } else {
        base = Colors.grey.shade300;
      }
    } else {
      switch (status) {
        case 'concluido':
          base = Colors.green;
          break;

        case 'em_andamento':
          base = Colors.orange;
          break;

        default:
          base = Colors.grey.shade300;
      }
    }

    final date = _dateForShade(cell);

    return _shadeRelative(base, date);
  }
}

class _Unset {
  const _Unset();
}