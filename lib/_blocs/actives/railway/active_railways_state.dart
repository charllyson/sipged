// lib/_blocs/actives/railway/active_railways_state.dart
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:siged/_blocs/actives/railway/active_railway_data.dart';
import 'package:siged/_blocs/actives/railway/active_railways_rules.dart';
import 'package:siged/_blocs/actives/railway/active_railways_style.dart';
import 'package:siged/_widgets/map/polylines/tappable_changed_polyline.dart';
import 'package:siged/_blocs/process/contracts/contract_rules.dart';

import 'package:siged/screens/actives/railways/network/railway_ties.dart';
import 'package:siged/_utils/multi_line_simplifier.dart';

enum ActiveRailwaysLoadStatus { idle, loading, success, failure }

class ActiveRailwaysState extends Equatable {
  static const _unset = Object();

  final bool initialized;
  final ActiveRailwaysLoadStatus loadStatus;
  final String? error;
  final List<ActiveRailwayData> all;

  final String? selectedPolylineId;

  final int? selectedPieIndexFilter;
  final String? selectedRegionFilter;  // usa mesma canonização de regiões
  final String? selectedStatusFilter;  // código canônico (ver Rules)

  final bool savingOrImporting;

  /// 🔹 zoom atual do mapa (dirigido pelo BLoC)
  final double mapZoom;

  const ActiveRailwaysState({
    this.initialized = false,
    this.loadStatus = ActiveRailwaysLoadStatus.idle,
    this.error,
    this.all = const [],
    this.selectedPolylineId,
    this.selectedPieIndexFilter,
    this.selectedRegionFilter,
    this.selectedStatusFilter,
    this.savingOrImporting = false,
    this.mapZoom = 12.0,
  });

  ActiveRailwaysState copyWith({
    bool? initialized,
    ActiveRailwaysLoadStatus? loadStatus,
    String? error,
    List<ActiveRailwayData>? all,
    Object? selectedPolylineId = _unset,
    Object? selectedPieIndexFilter = _unset,
    Object? selectedRegionFilter = _unset,
    Object? selectedStatusFilter = _unset,
    bool? savingOrImporting,
    double? mapZoom,
  }) {
    return ActiveRailwaysState(
      initialized: initialized ?? this.initialized,
      loadStatus: loadStatus ?? this.loadStatus,
      error: error,
      all: all ?? this.all,
      selectedPolylineId: identical(selectedPolylineId, _unset)
          ? this.selectedPolylineId
          : selectedPolylineId as String?,
      selectedPieIndexFilter: identical(selectedPieIndexFilter, _unset)
          ? this.selectedPieIndexFilter
          : selectedPieIndexFilter as int?,
      selectedRegionFilter: identical(selectedRegionFilter, _unset)
          ? this.selectedRegionFilter
          : selectedRegionFilter as String?,
      selectedStatusFilter: identical(selectedStatusFilter, _unset)
          ? this.selectedStatusFilter
          : selectedStatusFilter as String?,
      savingOrImporting: savingOrImporting ?? this.savingOrImporting,
      mapZoom: mapZoom ?? this.mapZoom,
    );
  }

  // =========================
  // Regiões (reuso de ContractRules.regions)
  // =========================
  List<String> get regionLabels => ContractRules.regions;

  String _canonRegion(String? s) =>
      ActiveRailwaysRules.canonRegion(s, regionLabels);

  int? indexOfRegionNormalized(String? label) {
    if (label == null) return null;
    final c = _canonRegion(label);
    return regionLabels.indexWhere((r) => _canonRegion(r) == c);
  }

  // =========================
  // Status -> códigos canônicos
  // =========================
  String _statusCodeOf(ActiveRailwayData r) =>
      ActiveRailwaysRules.statusCodeOf(r.status);

  // =========================
  // PIE: soma extensão (km) por status
  // =========================
  List<String> get _statusOrder => ActiveRailwaysRules.statusOrder;
  String _labelForStatus(String code) =>
      ActiveRailwaysRules.labelForStatus(code);

  Map<String, double> get _sumExtByStatus {
    final map = <String, double>{for (final s in _statusOrder) s: 0.0};
    for (final f in all) {
      final code = _statusCodeOf(f);
      final km = (f.extensao ?? 0.0).toDouble();
      map[code] = (map[code] ?? 0.0) + km;
    }
    return map;
  }

  List<({String code, String label, double value, Color color})> get _pieItems {
    final sums = _sumExtByStatus;
    return _statusOrder.map((code) {
      final km = (sums[code] ?? 0.0);
      return (
      code: code,
      label: _labelForStatus(code),
      value: km,
      color: ActiveRailwaysStyle.colorForStatus(code),
      );
    }).toList(growable: false);
  }

  List<String> get pieLabelsForChart =>
      _pieItems.map((e) => e.label).toList(growable: false);
  List<double> get pieValuesForChart =>
      _pieItems.map((e) => e.value).toList(growable: false);
  List<Color> get pieColorsForChart =>
      _pieItems.map((e) => e.color).toList(growable: false);
  double get pieTotal => _pieItems.fold<double>(0.0, (s, e) => s + e.value);

  String statusCodeFromPieChartIndex(int i) {
    final items = _pieItems;
    if (i < 0 || i >= items.length) return 'OUTRO';
    return items[i].code;
  }

  // =========================
  // Regiões — soma extensão, com filtro opcional do Pie/Status
  // =========================
  List<double> regionSumsKm() {
    final values = <double>[];
    final statusFilter = selectedPieIndexFilter == null
        ? null
        : statusCodeFromPieChartIndex(selectedPieIndexFilter!);

    for (final label in regionLabels) {
      final labelC = _canonRegion(label);
      final sumKm = all.where((f) {
        final regRaw = (f.municipio ?? f.uf ?? f.nome ?? '').toString();
        if (_canonRegion(regRaw) != labelC) return false;
        if (statusFilter == null) return true;
        return _statusCodeOf(f) == statusFilter;
      }).fold<double>(0.0, (acc, f) => acc + (f.extensao ?? 0.0));
      values.add(sumKm);
    }
    return values;
  }

  List<Color> regionBarColors(int? selectedRegionIndex) {
    final values = regionSumsKm();
    return List<Color>.generate(values.length, (i) {
      if (values[i] == 0.0) return Colors.grey.shade300;
      return (selectedRegionIndex != null && selectedRegionIndex == i)
          ? Colors.orangeAccent
          : Colors.blueAccent;
    });
  }

  // =========================
  // Filtros aplicados
  // =========================
  String? get _statusFilterFromPieOrNull =>
      selectedPieIndexFilter == null
          ? null
          : statusCodeFromPieChartIndex(selectedPieIndexFilter!);

  List<ActiveRailwayData> get filteredAll {
    final regionFilterC =
    selectedRegionFilter == null ? null : _canonRegion(selectedRegionFilter);
    final statusCode = _statusFilterFromPieOrNull ?? selectedStatusFilter;

    return all.where((f) {
      if (regionFilterC != null) {
        final regRaw = (f.municipio ?? f.uf ?? f.nome ?? '').toString();
        if (_canonRegion(regRaw) != regionFilterC) return false;
      }
      if (statusCode != null && statusCode.isNotEmpty) {
        if (_statusCodeOf(f) != statusCode) return false;
      }
      return true;
    }).toList(growable: false);
  }

  List<String>? get selectedRegionNamesForMap =>
      selectedRegionFilter == null ? null : [selectedRegionFilter!];

  // =========================
  // Mapa — polylines estilizadas (com dormentes)
  // =========================
  List<TappableChangedPolyline> buildStyledPolylines({double? zoom}) {
    final z = zoom ?? mapZoom;
    final List<TappableChangedPolyline> lines = [];

    // Métricas por zoom
    final m = RailwayTies.metricsForZoom(z);

    // Simplificação adaptativa por zoom
    List<LatLng> _simplifyForZoom(List<LatLng> seg) {
      return MultiLineSimplifier.simplifyAdaptive(
        seg,
        zoom: z,
        tolerancePxFar: 5.5,   // z < 9
        tolerancePxMid: 3.5,   // 9 <= z < 12
        minAngleDeg: 18,       // preserva curvas acentuadas
        maxSegmentMeters: 120, // anti-“quadrado”
      );
    }

    for (final fer in filteredAll) {
      if (fer.id == null) continue;

      final tagId = fer.id!;
      final statusCode = ActiveRailwaysRules.statusCodeOf(fer.status);
      final estiloCamadas = ActiveRailwaysStyle.styleLane(statusCode, z);
      final isSelected = (selectedPolylineId != null && selectedPolylineId == tagId);

      for (final rawSeg in fer.getSegments()) {
        if (rawSeg.length < 2) continue;

        final seg = _simplifyForZoom(rawSeg);

        // --- TRILHO (sempre) ---
        for (final entry in estiloCamadas.asMap().entries) {
          final idx = entry.key;
          final camada = entry.value;

          final ptsMain = ActiveRailwaysRules.deslocarPontos(
            seg,
            deslocamentoOrtogonal: idx * 0.00003,
          );

          // halo branco em z baixo / interm.
          if (m.outlinePx > 0) {
            lines.add(
              TappableChangedPolyline(
                isDotted: false,
                points: ptsMain,
                color: Colors.white.withOpacity(0.95),
                defaultColor: Colors.white,
                strokeWidth:
                (isSelected ? camada.width + 2 : camada.width) + m.outlinePx * 2,
                tag: '${tagId}_halo_$idx',
                hitTestable: false, // halo não intercepta clique
              ),
            );
          }

          // trilho principal — TAG = id puro (para seleção/tooltip)
          lines.add(
            TappableChangedPolyline(
              isDotted: false,
              points: ptsMain,
              color: isSelected ? Colors.redAccent : camada.cor,
              defaultColor: camada.cor,
              strokeWidth:
              isSelected ? camada.width + 2 : math.max(camada.width, m.railStrokePx),
              tag: tagId,       // ✅ mantém id puro
              hitTestable: true,
            ),
          );
        }

        // --- DORMENTES ---
        if (m.showTies) {
          final ties = RailwayTies.generateTiesPx(
            seg,
            z,
            spacingPx: m.spacingPx,
            lengthPx: m.lengthPx,
          );

          // evita excesso em linhas longas
          const maxTiesPerSeg = 220;
          final usable = ties.length > maxTiesPerSeg
              ? [
            for (var i = 0;
            i < ties.length;
            i += (ties.length / maxTiesPerSeg).ceil())
              ties[i]
          ]
              : ties;

          for (var i = 0; i < usable.length; i++) {
            final t = usable[i];

            // halo dos dormentes (zoom médio)
            if (m.tieHaloPx > 0) {
              lines.add(
                TappableChangedPolyline(
                  isDotted: false,
                  points: t,
                  color: Colors.white,
                  defaultColor: Colors.white,
                  strokeWidth: m.tieStrokePx + m.tieHaloPx * 2,
                  tag: '${tagId}_tie_halo_$i',
                  hitTestable: false, // não clica
                ),
              );
            }

            // dormente
            lines.add(
              TappableChangedPolyline(
                isDotted: false,
                points: t,
                color: Colors.black,
                defaultColor: Colors.black,
                strokeWidth: m.tieStrokePx,
                tag: '${tagId}_tie_$i',
                hitTestable: false, // não clica
              ),
            );
          }
        }
      }
    }
    return lines;
  }

  @override
  List<Object?> get props => [
    initialized,
    loadStatus,
    error,
    all,
    selectedPolylineId,
    selectedPieIndexFilter,
    selectedRegionFilter,
    selectedStatusFilter,
    savingOrImporting,
    mapZoom,
  ];
}
