// lib/_blocs/actives/oacs/active_oacs_state.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'active_oacs_data.dart';

enum ActiveOacsLoadStatus { idle, loading, success, failure }

class ActiveOacsState extends Equatable {
  static const _unset = Object();

  final bool initialized;
  final ActiveOacsLoadStatus loadStatus;
  final String? error;

  /// Lista principal (sem filtro)
  final List<ActiveOacsData> all;

  /// Edição/formulário
  final ActiveOacsData form;
  final bool isEditable;
  final bool saving;
  final int? selectedIndex;

  /// Filtros
  final int? selectedPieIndexFilter;  // 0..5 ou null
  final String? selectedRegionFilter; // label ou null

  /// Labels de região (fonte única p/ gráficos)
  final List<String> regionLabels;

  ActiveOacsState({
    this.initialized = false,
    this.loadStatus = ActiveOacsLoadStatus.idle,
    this.error,
    this.all = const [],
    ActiveOacsData? form,
    this.isEditable = false,
    this.saving = false,
    this.selectedIndex,
    this.selectedPieIndexFilter,
    this.selectedRegionFilter,
    this.regionLabels = const [],
  }) : form = form ?? ActiveOacsData();

  ActiveOacsState copyWith({
    bool? initialized,
    ActiveOacsLoadStatus? loadStatus,
    String? error,
    List<ActiveOacsData>? all,
    ActiveOacsData? form,
    bool? isEditable,
    bool? saving,
    int? selectedIndex,
    Object? selectedPieIndexFilter = _unset,
    Object? selectedRegionFilter = _unset,
    List<String>? regionLabels,
  }) {
    return ActiveOacsState(
      initialized: initialized ?? this.initialized,
      loadStatus: loadStatus ?? this.loadStatus,
      error: error,
      all: all ?? this.all,
      form: form ?? this.form,
      isEditable: isEditable ?? this.isEditable,
      saving: saving ?? this.saving,
      selectedIndex: selectedIndex,
      selectedPieIndexFilter: identical(selectedPieIndexFilter, _unset)
          ? this.selectedPieIndexFilter
          : selectedPieIndexFilter as int?,
      selectedRegionFilter: identical(selectedRegionFilter, _unset)
          ? this.selectedRegionFilter
          : selectedRegionFilter as String?,
      regionLabels: regionLabels ?? this.regionLabels,
    );
  }

  @override
  List<Object?> get props => [
    initialized,
    loadStatus,
    error,
    all,
    form,
    isEditable,
    saving,
    selectedIndex,
    selectedPieIndexFilter,
    selectedRegionFilter,
    regionLabels,
  ];

  // ===========================================================================
  // PIE (condição 0..5)
  // ===========================================================================
  List<int> get _pieScoresOrder => const <int>[0, 1, 2, 3, 4, 5];

  Map<int, int> get _countByScore {
    final map = <int, int>{for (final s in _pieScoresOrder) s: 0};
    for (final o in all) {
      final s = (o.conditionScore ?? -1).toInt().clamp(0, 5);
      map[s] = (map[s] ?? 0) + 1;
    }
    return map;
  }

  List<({Color color, String labelText, int score, double value})> get _pieItems {
    final counts = _countByScore;
    return _pieScoresOrder.map((score) {
      final qtd = counts[score] ?? 0;
      final label = ActiveOacsData.getLabelByNota(score);
      final color = ActiveOacsData.getColorByNota(score.toDouble());
      return (score: score, labelText: label, value: qtd.toDouble(), color: color);
    }).toList(growable: false);
  }

  List<String> get pieLabelsForChart =>
      _pieItems.map((e) => e.labelText).toList(growable: false);

  List<double> get pieValuesForChart =>
      _pieItems.map((e) => e.value).toList(growable: false);

  List<Color> get pieColorsForChart =>
      _pieItems.map((e) => e.color).toList(growable: false);

  double get pieTotal => _pieItems.fold<double>(0.0, (sum, e) => sum + e.value);

  int scoreFromPieChartIndex(int pieIndex) {
    final items = _pieItems;
    if (pieIndex < 0 || pieIndex >= items.length) return -1;
    return items[pieIndex].score;
  }

  // ===========================================================================
  // GAUGE (derivado do pie)
  // ===========================================================================
  GaugeVM gaugeForPieSelection({int? selectedPieIndex}) {
    final total = pieTotal;
    if (total <= 0) {
      return const GaugeVM(label: 'Total', count: 0, total: 0, percent: 0);
    }

    if (selectedPieIndex == null ||
        selectedPieIndex < 0 ||
        selectedPieIndex >= pieValuesForChart.length) {
      return GaugeVM(label: 'Total', count: total, total: total, percent: 1.0);
    }

    final value = pieValuesForChart[selectedPieIndex];
    final label = pieLabelsForChart[selectedPieIndex];

    return GaugeVM(
      label: label,
      count: value,
      total: total,
      percent: (value / total).clamp(0.0, 1.0),
    );
  }

  // ===========================================================================
  // REGIÕES (Bar Chart)
  // ===========================================================================
  List<String> get regionLabelsForCharts => regionLabels;

  List<double> get regionCounts {
    final labels = regionLabelsForCharts;
    final values = <double>[];
    for (final label in labels) {
      final rUp = label.toUpperCase();
      final count = all.where((o) => (o.region ?? '').toUpperCase() == rUp).length;
      values.add(count.toDouble());
    }
    return values;
  }

  // ===========================================================================
  // FILTRO APLICADO (região + score)
  // ===========================================================================
  int? get _scoreFilterOrNull {
    if (selectedPieIndexFilter == null) return null;
    final idx = selectedPieIndexFilter!;
    final score = scoreFromPieChartIndex(idx);
    if (score < 0) return null;
    return score;
  }

  List<ActiveOacsData> get filteredAll {
    final scoreFilter = _scoreFilterOrNull;
    final regionFilter = selectedRegionFilter?.toUpperCase();

    return all.where((o) {
      final okRegion = regionFilter == null
          ? true
          : (o.region ?? '').toUpperCase() == regionFilter;
      if (!okRegion) return false;

      if (scoreFilter == null) return true;
      final s = (o.conditionScore ?? -1).toInt();
      return s == scoreFilter;
    }).toList(growable: false);
  }

  List<double> regionCountsFilteredByPie() {
    final labels = regionLabelsForCharts;
    final scoreFilter = _scoreFilterOrNull;
    final values = <double>[];

    for (final label in labels) {
      final rUp = label.toUpperCase();
      final count = all.where((o) {
        final sameRegion = (o.region ?? '').toUpperCase() == rUp;
        if (!sameRegion) return false;
        if (scoreFilter == null) return true;
        final s = (o.conditionScore ?? -1).toInt();
        return s == scoreFilter;
      }).length;
      values.add(count.toDouble());
    }
    return values;
  }

  List<String>? get selectedRegionNamesForMap =>
      selectedRegionFilter == null ? null : [selectedRegionFilter!];

  GaugeVM gaugeForPieSelectionWithRegion({
    String? region,
    int? selectedPieIndex,
  }) {
    // Reaproveita a lógica: se tiver região, calcula pie só para região
    final subset = (region == null || region.isEmpty)
        ? all
        : all.where((o) => (o.region ?? '').toUpperCase() == region.toUpperCase()).toList();

    final order = _pieScoresOrder;
    final counts = <int, int>{for (final s in order) s: 0};
    for (final o in subset) {
      final s = (o.conditionScore ?? -1).toInt().clamp(0, 5);
      counts[s] = (counts[s] ?? 0) + 1;
    }

    final labels = <String>[];
    final values = <double>[];
    for (final score in order) {
      labels.add(ActiveOacsData.getLabelByNota(score));
      values.add((counts[score] ?? 0).toDouble());
    }

    final total = values.fold<double>(0.0, (acc, v) => acc + v);
    if (total <= 0) {
      return const GaugeVM(label: 'Total', count: 0, total: 0, percent: 0);
    }

    if (selectedPieIndex == null ||
        selectedPieIndex < 0 ||
        selectedPieIndex >= values.length) {
      return GaugeVM(
        label: region == null ? 'Total' : region,
        count: total,
        total: total,
        percent: 1.0,
      );
    }

    final value = values[selectedPieIndex];
    final label = labels[selectedPieIndex];
    return GaugeVM(
      label: label,
      count: value,
      total: total,
      percent: (value / total).clamp(0.0, 1.0),
    );
  }
}

/// VM do Gauge (igual ao seu padrão)
class GaugeVM {
  final String label;
  final double count;
  final double total;
  final double percent;
  const GaugeVM({
    required this.label,
    required this.count,
    required this.total,
    required this.percent,
  });

  String get subtitle => '${count.toStringAsFixed(0)} de ${total.toStringAsFixed(0)}';
}
