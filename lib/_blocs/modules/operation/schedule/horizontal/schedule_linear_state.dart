// lib/_blocs/modules/operation/schedule/horizontal/schedule_linear_state.dart

import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_cell_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_lane_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_services_data.dart';

class ScheduleLinearState extends Equatable {
  final bool initialized;

  final String? contractId;
  final String? summarySubjectContract;

  final int totalEstacas;
  final String currentServiceKey;

  final List<ScheduleLinearServicesData> services;
  final List<ScheduleLinearLaneData> lanes;
  final List<ScheduleLinearCellData> execucoes;

  final Map<String, ScheduleLinearCellData> execIndex;

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

  /// Filtro visual por data.
  ///
  /// Quando ativo, somente células com status [ScheduleLinearCellStatus.concluido]
  /// ou [ScheduleLinearCellStatus.emAndamento] e cuja chave esteja em
  /// [dateFilterCellKeys] serão destacadas.
  final bool dateFilterActive;
  final Set<String> dateFilterCellKeys;
  final String? dateFilterLabel;

  const ScheduleLinearState({
    this.initialized = false,
    this.contractId,
    this.summarySubjectContract,
    this.totalEstacas = 0,
    this.currentServiceKey = ScheduleLinearServicesData.geralKey,
    this.services = const <ScheduleLinearServicesData>[],
    this.lanes = const <ScheduleLinearLaneData>[],
    this.execucoes = const <ScheduleLinearCellData>[],
    this.execIndex = const <String, ScheduleLinearCellData>{},
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
    this.dateFilterActive = false,
    this.dateFilterCellKeys = const <String>{},
    this.dateFilterLabel,
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

  static Map<String, ScheduleLinearCellData> buildExecIndex(
      List<ScheduleLinearCellData> cells,
      ) {
    return <String, ScheduleLinearCellData>{
      for (final cell in cells) cell.cellKey: cell,
    };
  }

  ScheduleLinearState copyWith({
    bool? initialized,
    String? contractId,
    String? summarySubjectContract,
    int? totalEstacas,
    String? currentServiceKey,
    List<ScheduleLinearServicesData>? services,
    List<ScheduleLinearLaneData>? lanes,
    List<ScheduleLinearCellData>? execucoes,
    Map<String, ScheduleLinearCellData>? execIndex,
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
    bool? dateFilterActive,
    Set<String>? dateFilterCellKeys,
    Object? dateFilterLabel = const _Unset(),
  }) {
    final nextServices = services ?? this.services;
    final nextLanes = lanes ?? this.lanes;
    final nextExecucoes = execucoes ?? this.execucoes;

    final nextExecIndex = execIndex ??
        (execucoes != null ? buildExecIndex(execucoes) : this.execIndex);

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

    return ScheduleLinearState(
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
      busyReason:
      busyReason is _Unset ? this.busyReason : busyReason as String?,
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
              maxDate != null ||
              dateFilterActive != null ||
              dateFilterCellKeys != null ||
              dateFilterLabel is! _Unset
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
      dateFilterActive: dateFilterActive ?? this.dateFilterActive,
      dateFilterCellKeys: dateFilterCellKeys ?? this.dateFilterCellKeys,
      dateFilterLabel: dateFilterLabel is _Unset
          ? this.dateFilterLabel
          : dateFilterLabel as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[
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
    dateFilterActive,
    Object.hashAll(dateFilterCellKeys.toList()..sort()),
    dateFilterLabel,
  ];

  bool get isBusy => busyReason != null || savingOrImporting;

  bool get hasActiveDateFilter {
    return dateFilterActive && dateFilterCellKeys.isNotEmpty;
  }

  int get dateFilterSignature {
    return Object.hash(
      dateFilterActive,
      dateFilterLabel,
      Object.hashAll(dateFilterCellKeys.toList()..sort()),
    );
  }

  UnmodifiableListView<LatLng> get axisView {
    return UnmodifiableListView<LatLng>(axis);
  }

  bool get isGeral {
    return currentServiceKey.toLowerCase() == ScheduleLinearServicesData.geralKey;
  }

  bool get hasServices => services.isNotEmpty;

  bool get hasSpecificServices {
    return services.any((service) => !service.isGeral);
  }

  List<ScheduleLinearServicesData> get servicesByLayer {
    return ScheduleLinearServicesData.sortByLayer(services);
  }

  List<ScheduleLinearServicesData> get specificServices {
    return services.where((service) => !service.isGeral).toList(growable: false);
  }

  List<ScheduleLinearServicesData> get specificServicesByLayer {
    return ScheduleLinearServicesData.specificSortedByLayer(services);
  }

  List<ScheduleLinearServicesData> get specificServicesByDrawOrder {
    final ordered = specificServicesByLayer;

    return ordered.reversed.toList(growable: false);
  }

  Map<String, int> get serviceLayerOrderIndex {
    return <String, int>{
      for (final service in specificServicesByLayer)
        service.key.toLowerCase().trim(): service.layerOrder,
    };
  }

  ScheduleLinearServicesData? serviceMetaByKey(String serviceKey) {
    final clean = serviceKey.toLowerCase().trim();

    for (final service in services) {
      if (service.key.toLowerCase().trim() == clean) {
        return service;
      }
    }

    return null;
  }

  bool _laneEnabled(ScheduleLinearLaneData lane) {
    if (isGeral) return true;

    return lane.isAllowed(currentServiceKey);
  }

  bool _cellEnabled(ScheduleLinearCellData cell) {
    if (cell.faixaIndex < 0 || cell.faixaIndex >= lanes.length) {
      return false;
    }

    if (isGeral) {
      final serviceKey = cell.serviceKey.toLowerCase().trim();

      if (serviceKey.isEmpty || serviceKey == ScheduleLinearServicesData.geralKey) {
        return true;
      }

      return lanes[cell.faixaIndex].isAllowed(serviceKey);
    }

    return cell.serviceKey == currentServiceKey &&
        _laneEnabled(lanes[cell.faixaIndex]);
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

  bool isDoneOrInProgressCell(ScheduleLinearCellData cell) {
    return cell.isConcluido || cell.isEmAndamento;
  }

  bool matchesActiveDateFilter(ScheduleLinearCellData cell) {
    if (!dateFilterActive) return true;

    if (!isDoneOrInProgressCell(cell)) {
      return false;
    }

    return dateFilterCellKeys.contains(cell.cellKey);
  }

  int get concluidos {
    return execucoes
        .where(
          (cell) => _cellEnabled(cell) && cell.isConcluido,
    )
        .length;
  }

  int get andamento {
    return execucoes
        .where(
          (cell) => _cellEnabled(cell) && cell.isEmAndamento,
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

  ScheduleLinearServicesData get currentServiceMeta {
    if (services.isEmpty) return ScheduleLinearServicesData.emptyGeral;

    return services.firstWhere(
          (service) => service.key == currentServiceKey,
      orElse: () {
        final geral = services.where((service) => service.isGeral);

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

  bool get canEditSingleCell => !isGeral;

  bool get canBulkApply => !isGeral;

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

  String cellKeyFor({
    required String serviceKey,
    required int estaca,
    required int faixa,
  }) {
    return '${serviceKey.trim()}_${faixa}_$estaca';
  }

  ScheduleLinearCellData? cellAt({
    required String serviceKey,
    required int estaca,
    required int faixa,
  }) {
    return execIndex[cellKeyFor(
      serviceKey: serviceKey,
      estaca: estaca,
      faixa: faixa,
    )];
  }

  ScheduleLinearCellData? dominantCellForGeral({
    required int estaca,
    required int faixa,
  }) {
    if (!isGeral) {
      return cellAt(
        serviceKey: currentServiceKey,
        estaca: estaca,
        faixa: faixa,
      );
    }

    ScheduleLinearCellData? bestCell;
    int? bestLayer;

    for (final service in specificServicesByLayer) {
      final serviceKey = service.key.toLowerCase().trim();

      final cell = cellAt(
        serviceKey: serviceKey,
        estaca: estaca,
        faixa: faixa,
      );

      if (cell == null) continue;

      if (dateFilterActive && !matchesActiveDateFilter(cell)) {
        continue;
      }

      final layer = service.layerOrder;

      if (bestCell == null || bestLayer == null || layer < bestLayer) {
        bestCell = cell;
        bestLayer = layer;
      }
    }

    return bestCell;
  }

  List<String> fotosAtuaisFor(int estaca, int faixa) {
    return fotosAtuaisForService(
      serviceKey: currentServiceKey,
      estaca: estaca,
      faixa: faixa,
    );
  }

  List<String> fotosAtuaisForService({
    required String serviceKey,
    required int estaca,
    required int faixa,
  }) {
    final normalizedServiceKey = serviceKey.toLowerCase().trim();

    final found = cellAt(
      serviceKey: normalizedServiceKey,
      estaca: estaca,
      faixa: faixa,
    );

    if (found != null) {
      return List<String>.from(found.fotos, growable: false);
    }

    return const <String>[];
  }

  static const double _kMaxWhiteBlendOldest = 0.60;

  DateTime? _dateForShade(ScheduleLinearCellData cell) {
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

  ScheduleLinearServicesData? _serviceMetaForCell(ScheduleLinearCellData cell) {
    final rawKey = cell.serviceKey.toLowerCase().trim();

    for (final service in services) {
      final serviceKey = service.key.toLowerCase().trim();

      if (serviceKey.isEmpty || service.isGeral) continue;

      if (rawKey == serviceKey) return service;
    }

    return null;
  }

  Color squareColor(ScheduleLinearCellData cell) {
    if (dateFilterActive && !matchesActiveDateFilter(cell)) {
      return const Color(0xFFE0E0E0);
    }

    late final Color base;

    if (isGeral) {
      if (cell.isConcluido || cell.isEmAndamento) {
        final meta = _serviceMetaForCell(cell);

        base = meta?.color ?? ScheduleLinearServicesData.defaultServiceColor;
      } else {
        base = const Color(0xFFE0E0E0);
      }
    } else {
      switch (cell.status) {
        case ScheduleLinearCellStatus.concluido:
          base = Colors.green;
          break;

        case ScheduleLinearCellStatus.emAndamento:
          base = Colors.orange;
          break;

        case ScheduleLinearCellStatus.aIniciar:
          base = const Color(0xFFE0E0E0);
          break;
      }
    }

    final date = _dateForShade(cell);

    return _shadeRelative(base, date);
  }
}

class _Unset {
  const _Unset();
}