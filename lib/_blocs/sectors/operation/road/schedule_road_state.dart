// lib/_blocs/sectors/operation/road/board/schedule_road_state.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:siged/_blocs/sectors/operation/road/schedule_road_data.dart';
import 'package:siged/_widgets/schedule/linear/schedule_lane_class.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_style.dart';

class ScheduleRoadState extends Equatable {
  final bool initialized;

  // contrato / header
  final String? contractId;
  final String? summarySubjectContract;

  // grid
  final int totalEstacas;
  final String currentServiceKey;

  // dados
  final List<ScheduleRoadData> services;   // opções de serviço
  final List<ScheduleLaneClass> lanes;          // faixas
  final List<ScheduleRoadData> execucoes;  // células

  /// Índice O(1): [estaca][faixa] -> ScheduleData
  final Map<int, Map<int, ScheduleRoadData>> execIndex;

  /// Cache de datas globais para sombreamento relativo
  final DateTime? minDate;
  final DateTime? maxDate;

  // carregamentos
  final bool loadingServices;
  final bool loadingLanes;
  final bool loadingExecucoes;
  final bool savingOrImporting;

  final String? error;

  // ======== GEOMETRIA (migrada p/ o Board) ========
  /// "LineString" | "MultiLineString"
  final String? geometryType;

  /// Preferido: lista de segmentos (cada segmento é uma lista de pontos)
  final List<List<LatLng>>? multiLine;

  /// Fallback: linha achatada (um único array de pontos)
  final List<LatLng>? points;

  /// Retorna o eixo achatado (multiLine -> flatten; senão points; senão vazio)
  List<LatLng> get axis => axisFrom(
    geometryType: geometryType,
    multiLine: multiLine,
    points: points,
  );

  /// Helper estático para uso pelo BLoC
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

  // ======== MAPA (estado leve) ========
  final String? selectedPolylineId;
  final double mapZoom;

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

    // geometria
    this.geometryType,
    this.multiLine,
    this.points,

    // mapa
    this.selectedPolylineId,
    this.mapZoom = 12.0,
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

    // geometria
    String? geometryType,
    List<List<LatLng>>? multiLine,
    List<LatLng>? points,

    // mapa
    Object? selectedPolylineId,
    double? mapZoom,
  }) {
    return ScheduleRoadState(
      initialized: initialized ?? this.initialized,
      contractId: contractId ?? this.contractId,
      summarySubjectContract: summarySubjectContract ?? this.summarySubjectContract,
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
      error: error,

      // geometria
      geometryType: geometryType ?? this.geometryType,
      multiLine: multiLine ?? this.multiLine,
      points: points ?? this.points,

      // mapa
      selectedPolylineId: selectedPolylineId is _Unset
          ? this.selectedPolylineId
          : (selectedPolylineId as String?),
      mapZoom: mapZoom ?? this.mapZoom,
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

    // geometria
    geometryType,
    multiLine,
    points,

    // mapa
    selectedPolylineId,
    mapZoom,
  ];

  // ================== Derivados p/ Header/Resumo ==================

  bool get _isGeral => currentServiceKey.toLowerCase() == 'geral';

  bool _laneEnabled(ScheduleLaneClass l) =>
      _isGeral ? true : l.isAllowed(currentServiceKey);

  bool _cellEnabled(ScheduleRoadData e) {
    if (e.faixaIndex < 0 || e.faixaIndex >= lanes.length) return false;
    return _laneEnabled(lanes[e.faixaIndex]);
  }

  /// Total esperado = estacas * (somente lanes habilitadas ao serviço atual)
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
    if (t.contains('andament') || t.contains('in progress')) return 'em_andamento';
    if (t.contains('todo') || t.contains('a iniciar')) return 'a_iniciar';
    return 'a_iniciar';
  }

  int get concluidos => execucoes
      .where((e) => _cellEnabled(e) && _canonStatus(e.status) == 'concluido')
      .length;

  int get andamento => execucoes
      .where((e) => _cellEnabled(e) && _canonStatus(e.status) == 'em_andamento')
      .length;

  int get iniciados => concluidos + andamento;

  /// A iniciar = totalEsperado - (concluídos + andamento)
  int get aIniciar {
    final total = totalEsperado;
    final ai = total - iniciados;
    return ai < 0 ? 0 : ai;
  }

  double get pctConcluido =>
      totalEsperado == 0 ? 0 : (concluidos / totalEsperado) * 100.0;

  double get pctAndamento =>
      totalEsperado == 0 ? 0 : (andamento / totalEsperado) * 100.0;

  double get pctAIniciar =>
      totalEsperado == 0 ? 0 : (aIniciar / totalEsperado) * 100.0;

  // ================== Helpers expostos p/ SchedulePage ==================

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

  String get titleForHeader {
    final meta = currentServiceMeta;
    return (meta.label.isNotEmpty ? meta.label : meta.key).toUpperCase();
  }

  Color get colorForHeader => currentServiceMeta.color;

  bool get canEditSingleCell => currentServiceKey != 'geral';
  bool get canBulkApply => currentServiceKey != 'geral';

  Set<String> selectionBetween(int estacaA, int faixaA, int estacaB, int faixaB) {
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

    final idx = execucoes.indexWhere((x) => x.numero == estaca && x.faixaIndex == faixa);
    return idx == -1 ? const <String>[] : List<String>.from(execucoes[idx].fotos);
  }

  // ====== Sombreamento relativo por recência ======
  static const double _kMaxWhiteBlendOldest = 0.60;

  DateTime? _dateForShade(ScheduleRoadData e) {
    final dtTaken = e.takenAt ??
        (e.takenAtMs != null ? DateTime.fromMillisecondsSinceEpoch(e.takenAtMs!) : null);
    return dtTaken ?? e.updatedAt ?? e.createdAt;
  }

  Color _blendWithWhite(Color base, double amount) {
    amount = amount.clamp(0.0, 1.0);
    int _mix(int c, int w, double a) => (c + ((w - c) * a)).round().clamp(0, 255);
    final r = _mix(base.red, 255, amount);
    final g = _mix(base.green, 255, amount);
    final b = _mix(base.blue, 255, amount);
    return Color.fromARGB(base.alpha, r, g, b);
  }

  Color _shadeRelative(Color base, DateTime? dt) {
    final minD = minDate, maxD = maxDate;
    if (dt == null || minD == null || maxD == null) return base;

    final totalMs = maxD.millisecondsSinceEpoch - minD.millisecondsSinceEpoch;
    if (totalMs <= 0) return base;

    final posMs = dt.millisecondsSinceEpoch - minD.millisecondsSinceEpoch;
    final t = (posMs / totalMs).clamp(0.0, 1.0);

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

// helper para copyWith(selectedPolylineId opcional)
class _Unset {
  const _Unset();
}
