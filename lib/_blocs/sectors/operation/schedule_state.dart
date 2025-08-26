// lib/blocs/schedule/schedule_state.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:sisged/_blocs/sectors/operation/schedule_data.dart';
import 'package:sisged/_widgets/schedule/schedule_lane_class.dart';
import 'package:sisged/_blocs/sectors/operation/schedule_style.dart';

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

  // --------- Derivados (mantendo o que você tinha no Store) ---------

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

  Color squareColor(ScheduleData e) {
    final t = _canonStatus(e.status);
    if (currentServiceKey == 'geral') {
      if (t == 'concluido' || t == 'em_andamento') {
        final tag = (e.tipo != null && e.tipo!.trim().isNotEmpty)
            ? e.tipo!
            : ((e.key.isNotEmpty && e.key.toLowerCase() != 'geral')
            ? e.key
            : (e.label.isNotEmpty ? e.label : ''));
        return (tag.isNotEmpty)
            ? ScheduleStyle.colorForService(tag)
            : Colors.blueGrey.shade300;
      }
      return Colors.grey.shade300;
    } else {
      switch (t) {
        case 'concluido':    return Colors.green;
        case 'em_andamento': return Colors.orange;
        default:             return Colors.grey.shade300;
      }
    }
  }
}
