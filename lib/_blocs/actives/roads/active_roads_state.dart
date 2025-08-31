import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:siged/_blocs/actives/roads/active_roads_data.dart';
import 'package:siged/_blocs/actives/roads/active_road_style.dart';
import 'package:siged/_blocs/actives/roads/active_road_rules.dart';
import 'package:siged/_widgets/map/polylines/tappable_changed_polyline.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_rules.dart';

enum ActiveRoadsLoadStatus { idle, loading, success, failure }

class ActiveRoadsState extends Equatable {
  static const _unset = Object();

  final bool initialized;
  final ActiveRoadsLoadStatus loadStatus;
  final String? error;

  /// Dados
  final List<ActiveRoadsData> all;

  /// Seleção visual no mapa (id/tag da polyline)
  final String? selectedPolylineId;

  /// >>> FILTROS <<<
  final int? selectedPieIndexFilter;   // índice 0..N-1
  final String? selectedRegionFilter;  // rótulo da região
  final String? selectedSurfaceFilter; // fallback textual

  final bool savingOrImporting;

  const ActiveRoadsState({
    this.initialized = false,
    this.loadStatus = ActiveRoadsLoadStatus.idle,
    this.error,
    this.all = const [],
    this.selectedPolylineId,
    this.selectedPieIndexFilter,
    this.selectedRegionFilter,
    this.selectedSurfaceFilter,
    this.savingOrImporting = false,
  });

  ActiveRoadsState copyWith({
    bool? initialized,
    ActiveRoadsLoadStatus? loadStatus,
    String? error,
    List<ActiveRoadsData>? all,
    Object? selectedPolylineId = _unset,
    Object? selectedPieIndexFilter = _unset,
    Object? selectedRegionFilter = _unset,
    Object? selectedSurfaceFilter = _unset,
    bool? savingOrImporting,
  }) {
    return ActiveRoadsState(
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
      selectedSurfaceFilter: identical(selectedSurfaceFilter, _unset)
          ? this.selectedSurfaceFilter
          : selectedSurfaceFilter as String?,
      savingOrImporting: savingOrImporting ?? this.savingOrImporting,
    );
  }

  // ===========================================================================
  // Normalização/canonização de REGIÕES
  // ===========================================================================
  String _stripDiacritics(String s) {
    const map = {
      'Á': 'A', 'À': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A',
      'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
      'Í': 'I', 'Ì': 'I', 'Î': 'I', 'Ï': 'I',
      'Ó': 'O', 'Ò': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O',
      'Ú': 'U', 'Ù': 'U', 'Û': 'U', 'Ü': 'U',
      'Ç': 'C',
    };
    final buf = StringBuffer();
    for (final r in s.runes) {
      final ch = String.fromCharCode(r);
      buf.write(map[ch] ?? ch);
    }
    return buf.toString();
  }

  String _normRegion(String? s) {
    if (s == null) return '';
    var t = s.toUpperCase().trim();
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    t = _stripDiacritics(t);
    return t;
  }

  /// Canoniza para um rótulo **oficial** (normalizado) de `regionLabels`.
  /// Aceita apelidos/parciais como "MUNDAÚ"/"MUNDAU" ou "PARAÍBA"/"PARAIBA".
  String _canonRegion(String? s) {
    final n = _normRegion(s);
    if (n.isEmpty) return n;

    // 1) bate com algum rótulo oficial?
    for (final label in regionLabels) {
      final ln = _normRegion(label);
      if (n == ln) return ln;
    }

    // 2) aliases por substring
    if (n.contains('MUNDAU')) return _normRegion('VALE DO MUNDAÚ');
    if (n.contains('PARAIBA')) return _normRegion('VALE DO PARAÍBA');

    // (poderia incluir mais aliases aqui, se necessário)
    return n;
  }

  /// Índice da região selecionada (com normalização/canonização).
  int? indexOfRegionNormalized(String? label) {
    if (label == null) return null;
    final selC = _canonRegion(label);
    return regionLabels.indexWhere((r) => _canonRegion(r) == selC);
  }

  // ===========================================================================
  // Status/Superfície
  // ===========================================================================
  List<String> get _surfaceCodesOrder =>
      const <String>['DUP', 'EOD', 'PAV', 'EOP', 'IMP', 'EOI', 'PLA', 'LEN', 'OUTRO'];

  String _labelForSurface(String code) {
    switch (code) {
      case 'DUP': return 'Duplicada';
      case 'EOD': return 'Em obra (duplicação)';
      case 'PAV': return 'Pavimentada';
      case 'EOP': return 'Em obra (pavim.)';
      case 'IMP': return 'Implantada';
      case 'EOI': return 'Em obra (impl.)';
      case 'PLA': return 'Planejada';
      case 'LEN': return 'Leito natural';
      default:    return 'Outro';
    }
  }

  String _surfaceCodeOf(ActiveRoadsData r) {
    final raw = (r.stateSurface ?? r.surface ?? r.state ?? '')
        .toString().trim().toUpperCase();
    if (raw.isEmpty) return 'OUTRO';
    if (_surfaceCodesOrder.contains(raw)) return raw;

    if (raw.contains('DUP')) return 'DUP';
    if (raw.contains('OBRA') && raw.contains('DUP')) return 'EOD';
    if (raw.contains('PAV') && raw.contains('OBRA')) return 'EOP';
    if (raw.contains('PAV')) return 'PAV';
    if (raw.contains('IMPL')) return 'IMP';
    if (raw.contains('OBRA') && raw.contains('IMP')) return 'EOI';
    if (raw.contains('PLAN')) return 'PLA';
    if (raw.contains('LEITO') || raw.contains('NAT')) return 'LEN';
    return 'OUTRO';
  }

  // ===========================================================================
  // PIE — soma de extensão (km) por superfície
  // ===========================================================================
  Map<String, double> get _sumExtBySurface {
    final map = <String, double>{for (final s in _surfaceCodesOrder) s: 0.0};
    for (final r in all) {
      final code = _surfaceCodeOf(r);
      final extKm = (r.extension ?? 0.0).toDouble();
      map[code] = (map[code] ?? 0.0) + extKm;
    }
    return map;
  }

  List<({String code, String label, double value, Color color})> get _pieItems {
    final sums = _sumExtBySurface;
    return _surfaceCodesOrder.map((code) {
      final km = (sums[code] ?? 0.0);
      return (code: code, label: _labelForSurface(code), value: km, color: ActiveRoadsStyle.colorForSurface(code));
    }).toList(growable: false);
  }

  List<String> get pieLabelsForChart => _pieItems.map((e) => e.label).toList(growable: false);
  List<double> get pieValuesForChart => _pieItems.map((e) => e.value).toList(growable: false);
  List<Color> get pieColorsForChart => _pieItems.map((e) => e.color).toList(growable: false);
  double get pieTotal => _pieItems.fold<double>(0.0, (sum, e) => sum + e.value);

  String surfaceCodeFromPieChartIndex(int pieIndex) {
    final items = _pieItems;
    if (pieIndex < 0 || pieIndex >= items.length) return 'OUTRO';
    return items[pieIndex].code;
  }

  // ===========================================================================
  // GAUGE — percentual de km
  // ===========================================================================
  GaugeVM gaugeForPieSelection({int? selectedPieIndex}) {
    final totalKm = pieTotal;
    if (totalKm <= 0) {
      return const GaugeVM(label: 'Total', count: 0, total: 0, percent: 0);
    }
    if (selectedPieIndex == null ||
        selectedPieIndex < 0 ||
        selectedPieIndex >= pieValuesForChart.length) {
      return GaugeVM(label: 'Total', count: totalKm, total: totalKm, percent: 1.0);
    }
    final km = pieValuesForChart[selectedPieIndex];
    final label = pieLabelsForChart[selectedPieIndex];
    return GaugeVM(label: label, count: km, total: totalKm, percent: (km / totalKm).clamp(0.0, 1.0));
  }

  // ===========================================================================
  // REGIÕES — soma de extensão (km)
  // ===========================================================================
  List<String> get regionLabels => ContractRules.regions;

  /// Soma total de km por região (sem considerar pie)
  List<double> get regionSumsKm {
    final values = <double>[];
    for (final label in regionLabels) {
      final labelC = _canonRegion(label);
      final sumKm = all.where((r) {
        final regRaw = (r.regional ?? r.metadata?['regional'] ?? '').toString();
        return _canonRegion(regRaw) == labelC;
      }).fold<double>(0.0, (acc, r) => acc + (r.extension ?? 0.0));
      values.add(sumKm);
    }
    return values;
  }

  /// Soma de km por região, filtrada pelo Pie (se houver)
  List<double> regionCountsFilteredByPie() {
    final values = <double>[];
    final codeFilter = _surfaceFilterFromPieOrNull;

    for (final label in regionLabels) {
      final labelC = _canonRegion(label);
      final sumKm = all.where((r) {
        final regRaw = (r.regional ?? r.metadata?['regional'] ?? '').toString();
        if (_canonRegion(regRaw) != labelC) return false;
        if (codeFilter == null) return true;
        return _surfaceCodeOf(r) == codeFilter;
      }).fold<double>(0.0, (acc, r) => acc + (r.extension ?? 0.0));
      values.add(sumKm);
    }
    return values;
  }

  List<Color> regionBarColors(int? selectedRegionIndex) {
    final values = regionSumsKm;
    return List<Color>.generate(values.length, (i) {
      final v = values[i];
      if (v == 0.0) return Colors.grey.shade300;
      return (selectedRegionIndex != null && selectedRegionIndex == i)
          ? Colors.orangeAccent
          : Colors.blueAccent;
    });
  }

  // ===========================================================================
  // FILTROS aplicados (para mapa e UIs)
  // ===========================================================================
  String? get _surfaceFilterFromPieOrNull {
    if (selectedPieIndexFilter == null) return null;
    return surfaceCodeFromPieChartIndex(selectedPieIndexFilter!);
  }

  List<ActiveRoadsData> get filteredAll {
    final regionFilterC =
    selectedRegionFilter == null ? null : _canonRegion(selectedRegionFilter);
    final codeFilter = _surfaceFilterFromPieOrNull;
    final fallbackText = selectedSurfaceFilter?.toUpperCase();

    return all.where((r) {
      if (regionFilterC != null) {
        final regRaw = (r.regional ?? r.metadata?['regional'] ?? '').toString();
        if (_canonRegion(regRaw) != regionFilterC) return false;
      }
      if (codeFilter != null) return _surfaceCodeOf(r) == codeFilter;
      if (fallbackText != null && fallbackText.isNotEmpty) {
        final raw = (r.stateSurface ?? r.surface ?? r.state ?? '').toString().toUpperCase();
        return raw.contains(fallbackText);
      }
      return true;
    }).toList(growable: false);
  }

  List<String>? get selectedRegionNamesForMap =>
      selectedRegionFilter == null ? null : [selectedRegionFilter!];

  // ===========================================================================
  // MAPA — polylines estilizadas
  // ===========================================================================
  List<TappableChangedPolyline> buildStyledPolylines() {
    final List<TappableChangedPolyline> lines = [];
    for (final road in filteredAll) {
      if (road.id == null || road.points == null || road.points!.isEmpty) continue;

      final tagId = road.id!;
      final statusCode = _surfaceCodeOf(road);
      final estilo = ActiveRoadsStyle.styleLane(statusCode, 12);
      final isSelected = (selectedPolylineId != null && selectedPolylineId == tagId);

      for (final entry in estilo.asMap().entries) {
        final idx = entry.key;
        final camada = entry.value;
        lines.add(
          TappableChangedPolyline(
            isDotted: false,
            points: ActiveRoadsRules.deslocarPontos(
              road.points!,
              deslocamentoOrtogonal: idx * 0.00003,
            ),
            color: isSelected ? Colors.redAccent : camada.cor,
            defaultColor: camada.cor,
            strokeWidth: isSelected ? camada.width + 2 : camada.width,
            tag: tagId,
          ),
        );
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
    selectedSurfaceFilter,
    savingOrImporting,
  ];
}

/// VM do Gauge
class GaugeVM {
  final String label;
  final double count; // km selecionados
  final double total; // km total
  final double percent;
  const GaugeVM({
    required this.label,
    required this.count,
    required this.total,
    required this.percent,
  });

  String get subtitle =>
      '${count.toStringAsFixed(1)} km de ${total.toStringAsFixed(1)} km';
}
