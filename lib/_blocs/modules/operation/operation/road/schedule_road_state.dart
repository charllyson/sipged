import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_data.dart';
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_style.dart';
import 'package:sipged/_widgets/schedule/linear/schedule_lane_class.dart';

class ScheduleRoadState extends Equatable {
  final bool initialized;

  final String? contractId;
  final String? summarySubjectContract;

  final int totalEstacas;
  final String currentServiceKey;

  final List<ScheduleRoadData> services;
  final List<ScheduleLaneClass> lanes;
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

  /// Revisões para evitar comparação profunda cara no Equatable.
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
    this.lanes = const <ScheduleLaneClass>[],
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
      return multiLine.expand((s) => s).toList(growable: false);
    }
    if (points != null && points.isNotEmpty) {
      return List<LatLng>.from(points);
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
    List<ScheduleLaneClass>? lanes,
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
    final nextPoints =
    points is _Unset ? this.points : points as List<LatLng>?;
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

  UnmodifiableListView<LatLng> get axisView => UnmodifiableListView(axis);

  bool get _isGeral => currentServiceKey.toLowerCase() == 'geral';

  bool _laneEnabled(ScheduleLaneClass l) =>
      _isGeral ? true : l.isAllowed(currentServiceKey);

  bool _cellEnabled(ScheduleRoadData e) {
    if (e.faixaIndex < 0 || e.faixaIndex >= lanes.length) return false;
    return _laneEnabled(lanes[e.faixaIndex]);
  }

  int get totalEsperado {
    if (lanes.isEmpty || totalEstacas <= 0) return 0;
    final enabled = lanes.where(_laneEnabled).length;
    if (enabled <= 0) return 0;
    return totalEstacas * enabled;
  }

  String _canonStatus(String? raw) {
    var t = (raw ?? '')
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

    if (t.contains('conclu')) return 'concluido';
    if (t.contains('andament') || t.contains('in progress')) {
      return 'em_andamento';
    }
    if (t.contains('todo') || t.contains('a iniciar')) {
      return 'a_iniciar';
    }
    return 'a_iniciar';
  }

  int get concluidos => execucoes
      .where((e) => _cellEnabled(e) && _canonStatus(e.status) == 'concluido')
      .length;

  int get andamento => execucoes
      .where((e) => _cellEnabled(e) && _canonStatus(e.status) == 'em_andamento')
      .length;

  int get iniciados => concluidos + andamento;

  int get aIniciarCount =>
      (totalEsperado - iniciados) < 0 ? 0 : (totalEsperado - iniciados);

  double get pctConcluido {
    if (totalEsperado == 0) return 0;
    final raw = (concluidos / totalEsperado) * 100.0;
    if (raw > 0 && raw < 1) return 1.0;
    return raw;
  }

  double get pctAndamento {
    if (totalEsperado == 0) return 0;
    final raw = (andamento / totalEsperado) * 100.0;
    if (raw > 0 && raw < 1) return 1.0;
    return raw;
  }

  double get pctAIniciar {
    if (totalEsperado == 0) return 0;
    final restante = 100.0 - pctConcluido - pctAndamento;
    if (restante < 0) return 0;
    return restante;
  }

  ScheduleRoadData get currentServiceMeta {
    if (services.isEmpty) return ScheduleRoadData.emptyGeral;

    return services.firstWhere(
          (o) => o.key == currentServiceKey,
      orElse: () => services.first,
    );
  }

  String get titleForHeader =>
      (currentServiceMeta.label.isNotEmpty
          ? currentServiceMeta.label
          : currentServiceMeta.key)
          .toUpperCase();

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

    final sel = <String>{};
    for (int e = e0; e <= e1; e++) {
      for (int f = f0; f <= f1; f++) {
        sel.add('${e}_$f');
      }
    }
    return sel;
  }

  List<String> fotosAtuaisFor(int estaca, int faixa) {
    final idxMap = execIndex[estaca];
    final found = idxMap != null ? idxMap[faixa] : null;
    if (found != null) return List<String>.from(found.fotos, growable: false);

    final idx = execucoes.indexWhere(
          (x) => x.numero == estaca && x.faixaIndex == faixa,
    );

    return idx == -1
        ? const <String>[]
        : List<String>.from(execucoes[idx].fotos, growable: false);
  }

  static const double _kMaxWhiteBlendOldest = 0.60;

  DateTime? _dateForShade(ScheduleRoadData e) {
    final dtTaken = e.takenAt ??
        (e.takenAtMs != null
            ? DateTime.fromMillisecondsSinceEpoch(e.takenAtMs!)
            : null);
    return dtTaken ?? e.updatedAt ?? e.createdAt;
  }

  int _channel255(double normalized) {
    return (normalized * 255.0).round().clamp(0, 255);
  }

  Color _blendWithWhite(Color base, double amount) {
    final a = amount.clamp(0.0, 1.0);

    int mix(int c, int w, double alpha) =>
        (c + ((w - c) * alpha)).round().clamp(0, 255);

    final baseR = _channel255(base.r);
    final baseG = _channel255(base.g);
    final baseB = _channel255(base.b);
    final baseA = _channel255(base.a);

    final r = mix(baseR, 255, a);
    final g = mix(baseG, 255, a);
    final b = mix(baseB, 255, a);

    return Color.fromARGB(baseA, r, g, b);
  }

  Color _shadeRelative(Color base, DateTime? dt) {
    final minDLocal = minDate;
    final maxDLocal = maxDate;

    if (dt == null || minDLocal == null || maxDLocal == null) return base;

    final totalMs =
        maxDLocal.millisecondsSinceEpoch - minDLocal.millisecondsSinceEpoch;
    if (totalMs <= 0) return base;

    final posMs = dt.millisecondsSinceEpoch - minDLocal.millisecondsSinceEpoch;
    final t = (posMs / totalMs).clamp(0.0, 1.0);

    final blend = _kMaxWhiteBlendOldest * (1.0 - t);
    return _blendWithWhite(base, blend);
  }

  Color squareColor(ScheduleRoadData e) {
    final hasPhotos = e.fotos.isNotEmpty;
    final raw = (e.status ?? '').trim();
    final t = raw.isEmpty && hasPhotos ? 'em_andamento' : _canonStatus(raw);

    late final Color base;

    if (currentServiceKey == 'geral') {
      if (t == 'concluido' || t == 'em_andamento') {
        final tag = (e.tipo != null && e.tipo!.trim().isNotEmpty)
            ? e.tipo!
            : ((e.key.isNotEmpty && e.key.toLowerCase() != 'geral')
            ? e.key
            : (e.label.isNotEmpty ? e.label : ''));

        base = tag.isNotEmpty
            ? ScheduleRoadStyle.colorForService(tag)
            : Colors.blueGrey.shade300;
      } else {
        base = Colors.grey.shade300;
      }
    } else {
      switch (t) {
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

    final dt = _dateForShade(e);
    return _shadeRelative(base, dt);
  }
}

class _Unset {
  const _Unset();
}