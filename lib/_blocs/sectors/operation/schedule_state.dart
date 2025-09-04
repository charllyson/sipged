import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:siged/_blocs/sectors/operation/schedule_data.dart';
import 'package:siged/_widgets/schedule/schedule_lane_class.dart';
import 'package:siged/_blocs/sectors/operation/schedule_style.dart';

enum ScheduleStatusLoad { idle, loading, success, failure }

class ScheduleState extends Equatable {
  final bool initialized;

  final String? contractId;
  final int totalEstacas;

  final String currentServiceKey;

  final List<ScheduleData> services;         // opções de serviço
  final List<ScheduleLaneClass> lanes;       // faixas
  final List<ScheduleData> execucoes;        // células

  final bool loadingServices;
  final bool loadingLanes;
  final bool loadingExecucoes;

  final String? error;

  const ScheduleState({
    this.initialized = false,
    this.contractId,
    this.totalEstacas = 0,
    this.currentServiceKey = 'geral',
    this.services = const [],
    this.lanes = const [],
    this.execucoes = const [],
    this.loadingServices = false,
    this.loadingLanes = false,
    this.loadingExecucoes = false,
    this.error,
  });

  ScheduleState copyWith({
    bool? initialized,
    String? contractId,
    int? totalEstacas,
    String? currentServiceKey,
    List<ScheduleData>? services,
    List<ScheduleLaneClass>? lanes,
    List<ScheduleData>? execucoes,
    bool? loadingServices,
    bool? loadingLanes,
    bool? loadingExecucoes,
    String? error,
  }) {
    return ScheduleState(
      initialized: initialized ?? this.initialized,
      contractId: contractId ?? this.contractId,
      totalEstacas: totalEstacas ?? this.totalEstacas,
      currentServiceKey: currentServiceKey ?? this.currentServiceKey,
      services: services ?? this.services,
      lanes: lanes ?? this.lanes,
      execucoes: execucoes ?? this.execucoes,
      loadingServices: loadingServices ?? this.loadingServices,
      loadingLanes: loadingLanes ?? this.loadingLanes,
      loadingExecucoes: loadingExecucoes ?? this.loadingExecucoes,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    initialized,
    contractId,
    totalEstacas,
    currentServiceKey,
    services,
    lanes,
    execucoes,
    loadingServices,
    loadingLanes,
    loadingExecucoes,
    error,
  ];

  // --------- Derivados ---------

  int get totalEsperado => totalEstacas * lanes.length;

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
    return t;
  }

  int get concluidos => execucoes.where((e) => _canonStatus(e.status) == 'concluido').length;
  int get andamento  => execucoes.where((e) => _canonStatus(e.status) == 'em_andamento').length;
  int get iniciados  => concluidos + andamento;
  int get aIniciar   => (totalEsperado - iniciados) < 0 ? 0 : (totalEsperado - iniciados);

  double get pctConcluido => totalEsperado == 0 ? 0 : concluidos / totalEsperado * 100.0;
  double get pctAndamento => totalEsperado == 0 ? 0 : andamento  / totalEsperado * 100.0;
  double get pctAIniciar  => totalEsperado == 0 ? 0 : aIniciar   / totalEsperado * 100.0;

  // ================== Helpers expostos p/ SchedulePage ==================

  /// Metadado do serviço atual (UI).
  ScheduleData get currentServiceMeta {
    if (services.isEmpty) {
      return const ScheduleData(
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

  /// Título do header (label/key em UPPERCASE).
  String get titleForHeader {
    final meta = currentServiceMeta;
    return (meta.label.isNotEmpty ? meta.label : meta.key).toUpperCase();
  }

  /// Cor da tarja do header.
  Color get colorForHeader => currentServiceMeta.color;

  /// Pode editar célula individual? (não permite quando está em "geral")
  bool get canEditSingleCell => currentServiceKey != 'geral';

  /// Pode aplicar em lote? (mesma regra de cima; lógica extra pode ser adicionada depois)
  bool get canBulkApply => currentServiceKey != 'geral';

  /// Seleção retangular entre dois pontos (estaca/faixa) → chaves "e_f".
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

  /// Fotos atuais da célula (se existir).
  List<String> fotosAtuaisFor(int estaca, int faixa) {
    final idx = execucoes.indexWhere((x) => x.numero == estaca && x.faixaIndex == faixa);
    return idx == -1 ? const <String>[] : List<String>.from(execucoes[idx].fotos);
  }

  // ================== Sombreamento relativo por recência ==================

  // Quão clara a mais antiga pode ficar (0.0 = sem clarear; 0.8 = clareia muito).
  static const double _kMaxWhiteBlendOldest = 0.60; // 60% de branco na mais antiga

  /// Data de referência de uma célula (prioriza a escolhida no modal).
  DateTime? _dateForShade(ScheduleData e) {
    final dtTaken = e.takenAt ??
        (e.takenAtMs != null ? DateTime.fromMillisecondsSinceEpoch(e.takenAtMs!) : null);
    return dtTaken ?? e.updatedAt ?? e.createdAt;
  }

  /// Mistura linear de uma cor com branco.
  Color _blendWithWhite(Color base, double amount) {
    amount = amount.clamp(0.0, 1.0);
    int _mix(int c, int w, double a) => (c + ((w - c) * a)).round().clamp(0, 255);
    final r = _mix(base.red,   255, amount);
    final g = _mix(base.green, 255, amount);
    final b = _mix(base.blue,  255, amount);
    return Color.fromARGB(base.alpha, r, g, b);
  }

  /// Clareia a cor base **relativamente** ao intervalo [minDate, maxDate] das execuções:
  /// - data == minDate  → blend = _kMaxWhiteBlendOldest (mais clara)
  /// - data == maxDate  → blend = 0.0 (sem clarear)
  /// - valores no meio  → interpolação linear
  Color _shadeRelative(Color base, DateTime? dt) {
    if (dt == null) return base;

    // calcula min e max entre execuções que têm data
    DateTime? minD, maxD;
    for (final ex in execucoes) {
      final d = _dateForShade(ex);
      if (d == null) continue;
      if (minD == null || d.isBefore(minD)) minD = d;
      if (maxD == null || d.isAfter(maxD))  maxD = d;
    }

    if (minD == null || maxD == null) return base;
    final totalMs = maxD.millisecondsSinceEpoch - minD.millisecondsSinceEpoch;
    if (totalMs <= 0) return base; // todas as datas iguais → sem variação

    final posMs = dt.millisecondsSinceEpoch - minD.millisecondsSinceEpoch;
    final t = (posMs / totalMs).clamp(0.0, 1.0); // 0 = mais antiga, 1 = mais recente

    // Blend maior para as antigas (t=0), zero para as recentes (t=1)
    final blend = _kMaxWhiteBlendOldest * (1.0 - t);
    return _blendWithWhite(base, blend);
  }

  /// Falha segura: se vier sem status mas com foto, considere "em_andamento" para colorir.
  /// Regras originais mantidas; depois aplica o sombreamento relativo.
  Color squareColor(ScheduleData e) {
    final hasPhotos = e.fotos.isNotEmpty;
    final raw = (e.status ?? '').trim();
    final t = raw.isEmpty && hasPhotos ? 'em_andamento' : _canonStatus(raw);

    // 1) Cor base pelas regras existentes
    Color base;
    if (currentServiceKey == 'geral') {
      if (t == 'concluido' || t == 'em_andamento') {
        final tag = (e.tipo != null && e.tipo!.trim().isNotEmpty)
            ? e.tipo!
            : ((e.key.isNotEmpty && e.key.toLowerCase() != 'geral')
            ? e.key
            : (e.label.isNotEmpty ? e.label : ''));
        base = (tag.isNotEmpty)
            ? ScheduleStyle.colorForService(tag)
            : Colors.blueGrey.shade300;
      } else {
        base = Colors.grey.shade300;
      }
    } else {
      switch (t) {
        case 'concluido':     base = Colors.green;   break;
        case 'em_andamento':  base = Colors.orange;  break;
        default:              base = Colors.grey.shade300;
      }
    }

    // 2) Aplica sombreamento relativo (mais antiga = mais clara; mais recente = mais escura)
    final dt = _dateForShade(e);
    return _shadeRelative(base, dt);
  }
}
