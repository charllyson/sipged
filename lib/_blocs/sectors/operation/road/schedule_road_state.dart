import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:siged/_blocs/sectors/operation/road/schedule_road_data.dart';
import 'package:siged/_widgets/schedule/linear/schedule_lane_class.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_style.dart';

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

  final Map<String, double> serviceTotals;
  final List<int> physfinPeriods;
  final Map<String, List<double>> physfinGrid;

  List<LatLng> get axis => axisFrom(
    geometryType: geometryType,
    multiLine: multiLine,
    points: points,
  );

  static List<LatLng> axisFrom({
    required String? geometryType,
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

  final String? selectedPolylineId;
  final double mapZoom;

  /// ⚠️ Novo campo — controla quando mostrar o ScreenLock
  /// Valores possíveis:
  /// - 'warmup'
  /// - 'refresh'
  /// - 'import_geojson'
  /// - 'upsert_geometry'
  /// - 'delete_geometry'
  /// null = desbloqueado
  final String? busyReason;

  const ScheduleRoadState({
    this.initialized = false,
    this.contractId,
    this.summarySubjectContract,
    this.totalEstacas = 0,
    this.currentServiceKey = 'geral',
    this.services = const [],
    this.lanes = const [],
    this.execucoes = const [],
    this.execIndex = const {},
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
    this.serviceTotals = const {},
    this.physfinPeriods = const [],
    this.physfinGrid = const {},
    this.selectedPolylineId,
    this.mapZoom = 12.0,
    this.busyReason, // 👈 novo
  });

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
    Map<String, double>? serviceTotals,
    List<int>? physfinPeriods,
    Map<String, List<double>>? physfinGrid,
    Object? selectedPolylineId = const _Unset(),
    double? mapZoom,

    /// 👇 novo
    Object? busyReason = const _Unset(),
  }) {
    return ScheduleRoadState(
      initialized: initialized ?? this.initialized,
      contractId: contractId ?? this.contractId,
      summarySubjectContract:
      summarySubjectContract ?? this.summarySubjectContract,
      totalEstacas: totalEstacas ?? this.totalEstacas,
      currentServiceKey: currentServiceKey ?? this.currentServiceKey,
      services: services ?? this.services,
      lanes: lanes ?? this.lanes,
      execucoes: execucoes ?? this.execucoes,
      execIndex: execIndex ?? this.execIndex,
      minDate: minDate ?? this.minDate,
      maxDate: maxDate ?? this.maxDate,
      loadingServices: loadingServices ?? this.loadingServices,
      loadingLanes: loadingLanes ?? this.loadingLanes,
      loadingExecucoes: loadingExecucoes ?? this.loadingExecucoes,
      savingOrImporting: savingOrImporting ?? this.savingOrImporting,
      error: error ?? this.error,
      geometryType: geometryType is _Unset
          ? this.geometryType
          : geometryType as String?,
      multiLine: multiLine is _Unset
          ? this.multiLine
          : multiLine as List<List<LatLng>>?,
      points:
      points is _Unset ? this.points : points as List<LatLng>?,
      serviceTotals: serviceTotals ?? this.serviceTotals,
      physfinPeriods: physfinPeriods ?? this.physfinPeriods,
      physfinGrid: physfinGrid ?? this.physfinGrid,
      selectedPolylineId: selectedPolylineId is _Unset
          ? this.selectedPolylineId
          : selectedPolylineId as String?,
      mapZoom: mapZoom ?? this.mapZoom,

      /// 👇 novo
      busyReason:
      busyReason is _Unset ? this.busyReason : busyReason as String?,
    );
  }

  @override
  List<Object?> get props => [
    initialized,
    contractId,
    summarySubjectContract,
    totalEstacas,
    currentServiceKey,
    services,
    lanes,
    execucoes,
    execIndex,
    minDate,
    maxDate,
    loadingServices,
    loadingLanes,
    loadingExecucoes,
    savingOrImporting,
    error,
    geometryType,
    multiLine,
    points,
    serviceTotals,
    physfinPeriods,
    physfinGrid,
    selectedPolylineId,
    mapZoom,
    busyReason, // 👈 novo
  ];

  // ======================================================
  // HELPERS DE SERVIÇOS PARA A UI (DINÂMICOS)
  // ======================================================

  /// Quantidade total de serviços incluindo o GERAL.
  ///
  /// Obs.: `loadAvailableServicesFromBudget` sempre insere GERAL na frente,
  /// então esta contagem é:
  ///
  ///   1 (GERAL) + N serviços de orçamento.
  int get totalServicesIncludingGeral => services.length;

  /// Quantidade de serviços "reais" (sem o GERAL).
  int get totalServicesWithoutGeral =>
      services.where((s) => s.key.toLowerCase() != 'geral').length;

  // ======================================================
  // LÓGICA DE CÉLULAS / PERCENTUAIS
  // ======================================================

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
    String t = (raw ?? '')
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
        .replaceAll(RegExp(r'[\-\_]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (t.contains('conclu')) return 'concluido';
    if (t.contains('andament') || t.contains('in progress')) {
      return 'em_andamento';
    }
    if (t.contains('todo') || t.contains('a iniciar')) return 'a_iniciar';
    return 'a_iniciar';
  }

  int get concluidos => execucoes
      .where(
        (e) => _cellEnabled(e) && _canonStatus(e.status) == 'concluido',
  )
      .length;

  int get andamento => execucoes
      .where(
        (e) => _cellEnabled(e) && _canonStatus(e.status) == 'em_andamento',
  )
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
    if (services.isEmpty) {
      return const ScheduleRoadData(
        numero: 0,
        faixaIndex: 0,
        key: 'geral',
        label: 'GERAL',
        icon: Icons.clear_all,
        color: Colors.grey,
      );
    }
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
      int estacaA, int faixaA, int estacaB, int faixaB) {
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
    if (found != null) return List<String>.from(found.fotos);

    final idx = execucoes.indexWhere(
            (x) => x.numero == estaca && x.faixaIndex == faixa);
    return idx == -1
        ? const <String>[]
        : List<String>.from(execucoes[idx].fotos);
  }

  static const double _kMaxWhiteBlendOldest = 0.60;

  DateTime? _dateForShade(ScheduleRoadData e) {
    final dtTaken = e.takenAt ??
        (e.takenAtMs != null
            ? DateTime.fromMillisecondsSinceEpoch(e.takenAtMs!)
            : null);
    return dtTaken ?? e.updatedAt ?? e.createdAt;
  }

  Color _blendWithWhite(Color base, double amount) {
    if (amount < 0.0) {
      amount = 0.0;
    } else if (amount > 1.0) {
      amount = 1.0;
    }

    int _mix(int c, int w, double a) =>
        (c + ((w - c) * a)).round().clamp(0, 255);

    final r = _mix(base.red, 255, amount);
    final g = _mix(base.green, 255, amount);
    final b = _mix(base.blue, 255, amount);
    return Color.fromARGB(base.alpha, r, g, b);
  }

  Color _shadeRelative(Color base, DateTime? dt) {
    final minD = minDate, maxD = maxDate;
    if (dt == null || minD == null || maxD == null) return base;

    final totalMs =
        maxD.millisecondsSinceEpoch - minD.millisecondsSinceEpoch;
    if (totalMs <= 0) return base;

    final posMs =
        dt.millisecondsSinceEpoch - minD.millisecondsSinceEpoch;
    final double t =
    (posMs / totalMs).clamp(0.0, 1.0) as double;

    final blend = _kMaxWhiteBlendOldest * (1.0 - t);
    return _blendWithWhite(base, blend);
  }

  Color squareColor(ScheduleRoadData e) {
    final hasPhotos = e.fotos.isNotEmpty;
    final raw = (e.status ?? '').trim();
    final t = raw.isEmpty && hasPhotos ? 'em_andamento' : _canonStatus(raw);

    Color base;
    if (currentServiceKey == 'geral') {
      if (t == 'concluido' || t == 'em_andamento') {
        final tag = (e.tipo != null && e.tipo!.trim().isNotEmpty)
            ? e.tipo!
            : ((e.key.isNotEmpty && e.key.toLowerCase() != 'geral')
            ? e.key
            : (e.label.isNotEmpty ? e.label : ''));
        base = (tag.isNotEmpty)
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

/// sentinela para diferenciar "não passado" de "passado como null"
class _Unset {
  const _Unset();
}
