// lib/_blocs/modules/actives/oaes/active_oaes_state.dart

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_data.dart';

enum ActiveOaesLoadStatus {
  idle,
  loading,
  success,
  failure,
}

class ActiveOaesState extends Equatable {
  static const Object _unset = Object();

  final bool initialized;
  final ActiveOaesLoadStatus loadStatus;
  final String? error;

  /// Lista principal sem filtro.
  final List<ActiveOaesData> all;

  /// Edição/formulário.
  final ActiveOaesData form;
  final bool isEditable;
  final bool saving;
  final int? selectedIndex;

  /// Índice da fatia no gráfico de pizza, ou null para sem filtro.
  final int? selectedPieIndexFilter;

  /// Rótulo da região selecionada, ou null para sem filtro.
  final String? selectedRegionFilter;

  /// Regiões usadas nos gráficos/filtros.
  final List<String> regionLabels;

  ActiveOaesState({
    this.initialized = false,
    this.loadStatus = ActiveOaesLoadStatus.idle,
    this.error,
    this.all = const <ActiveOaesData>[],
    ActiveOaesData? form,
    this.isEditable = false,
    this.saving = false,
    this.selectedIndex,
    this.selectedPieIndexFilter,
    this.selectedRegionFilter,
    this.regionLabels = const <String>[],
  }) : form = form ?? ActiveOaesData();

  ActiveOaesState copyWith({
    bool? initialized,
    ActiveOaesLoadStatus? loadStatus,
    String? error,
    List<ActiveOaesData>? all,
    ActiveOaesData? form,
    bool? isEditable,
    bool? saving,

    /// Usar Object para permitir limpar com null.
    Object? selectedIndex = _unset,
    Object? selectedPieIndexFilter = _unset,
    Object? selectedRegionFilter = _unset,

    List<String>? regionLabels,
  }) {
    return ActiveOaesState(
      initialized: initialized ?? this.initialized,
      loadStatus: loadStatus ?? this.loadStatus,
      error: error,
      all: all ?? this.all,
      form: form ?? this.form,
      isEditable: isEditable ?? this.isEditable,
      saving: saving ?? this.saving,
      selectedIndex: identical(selectedIndex, _unset)
          ? this.selectedIndex
          : selectedIndex as int?,
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
  // PIE - Notas 0..5
  // ===========================================================================

  List<int> get _pieScoresOrder => const <int>[0, 1, 2, 3, 4, 5];

  Map<int, int> get _countByScore {
    final map = <int, int>{
      for (final score in _pieScoresOrder) score: 0,
    };

    for (final oae in all) {
      final score = (oae.score ?? -1).toInt().clamp(0, 5);
      map[score] = (map[score] ?? 0) + 1;
    }

    return map;
  }

  int firstOriginalIndexForScore(int scoreInt) {
    return all.indexWhere(
          (oae) => (oae.score ?? -1).toInt() == scoreInt,
    );
  }

  List<({Color color, String labelText, int score, double value})>
  get _pieItems {
    final counts = _countByScore;

    return _pieScoresOrder.map((score) {
      final quantity = counts[score] ?? 0;
      final label = ActiveOaesData.getLabelByNota(score);
      final color = ActiveOaesData.getColorByNota(score.toDouble());

      return (
      score: score,
      labelText: label,
      value: quantity.toDouble(),
      color: color,
      );
    }).toList(growable: false);
  }

  List<String> get pieLabelsForChart {
    return _pieItems.map((item) => item.labelText).toList(growable: false);
  }

  List<double> get pieValuesForChart {
    return _pieItems.map((item) => item.value).toList(growable: false);
  }

  List<Color> get pieColorsForChart {
    return _pieItems.map((item) => item.color).toList(growable: false);
  }

  double get pieTotal {
    return _pieItems.fold<double>(
      0.0,
          (previousTotal, item) => previousTotal + item.value,
    );
  }

  int scoreFromPieChartIndex(int pieIndex) {
    final items = _pieItems;

    if (pieIndex < 0 || pieIndex >= items.length) {
      return -1;
    }

    return items[pieIndex].score;
  }

  // ===========================================================================
  // GAUGE
  // ===========================================================================

  GaugeVM gaugeForPieSelection({int? selectedPieIndex}) {
    final total = pieTotal;

    if (total <= 0) {
      return const GaugeVM(
        label: 'Total',
        count: 0,
        total: 0,
        percent: 0,
      );
    }

    if (selectedPieIndex == null ||
        selectedPieIndex < 0 ||
        selectedPieIndex >= pieValuesForChart.length) {
      return GaugeVM(
        label: 'Total',
        count: total,
        total: total,
        percent: 1.0,
      );
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
  // REGIÕES
  // ===========================================================================

  List<String> get regionLabelsForCharts => regionLabels;

  List<double> get regionCounts {
    final labels = regionLabelsForCharts;
    final values = <double>[];

    for (final label in labels) {
      final normalizedRegion = label.toUpperCase();

      final count = all.where((oae) {
        return (oae.region ?? '').toUpperCase() == normalizedRegion;
      }).length;

      values.add(count.toDouble());
    }

    return values;
  }

  List<double> regionCountsFiltered({int? score}) {
    final labels = regionLabelsForCharts;
    final values = <double>[];

    for (final label in labels) {
      final normalizedRegion = label.toUpperCase();

      final count = all.where((oae) {
        final sameRegion =
            (oae.region ?? '').toUpperCase() == normalizedRegion;

        if (!sameRegion) return false;
        if (score == null) return true;

        final currentScore = (oae.score ?? -1).toInt();

        return currentScore == score;
      }).length;

      values.add(count.toDouble());
    }

    return values;
  }

  List<double> get regionTotalsByValue {
    final labels = regionLabelsForCharts;
    final values = <double>[];

    for (final label in labels) {
      final normalizedRegion = label.toUpperCase();

      final total = all
          .where(
            (oae) => (oae.region ?? '').toUpperCase() == normalizedRegion,
      )
          .fold<double>(
        0.0,
            (previousTotal, oae) {
          return previousTotal + (oae.valueIntervention ?? 0.0);
        },
      );

      values.add(total);
    }

    return values;
  }

  List<Color> regionBarColors(int? selectedRegionIndex) {
    final values = regionCounts;

    return List<Color>.generate(values.length, (index) {
      final value = values[index];

      if (value == 0.0) {
        return Colors.grey.shade300;
      }

      if (selectedRegionIndex != null && selectedRegionIndex == index) {
        return Colors.orangeAccent;
      }

      return Colors.blueAccent;
    });
  }

  // ===========================================================================
  // FILTROS APLICADOS
  // ===========================================================================

  int? get _scoreFilterOrNull {
    if (selectedPieIndexFilter == null) return null;

    final index = selectedPieIndexFilter!;
    final score = scoreFromPieChartIndex(index);

    if (score < 0) return null;

    return score;
  }

  List<ActiveOaesData> get filteredAll {
    final scoreFilter = _scoreFilterOrNull;
    final regionFilter = selectedRegionFilter?.toUpperCase();

    return all.where((oae) {
      final okRegion = regionFilter == null
          ? true
          : (oae.region ?? '').toUpperCase() == regionFilter;

      if (!okRegion) return false;

      if (scoreFilter == null) return true;

      final score = (oae.score ?? -1).toInt();

      return score == scoreFilter;
    }).toList(growable: false);
  }

  List<double> regionCountsFilteredByPie() {
    final labels = regionLabelsForCharts;
    final scoreFilter = _scoreFilterOrNull;
    final values = <double>[];

    for (final label in labels) {
      final normalizedRegion = label.toUpperCase();

      final count = all.where((oae) {
        final sameRegion =
            (oae.region ?? '').toUpperCase() == normalizedRegion;

        if (!sameRegion) return false;
        if (scoreFilter == null) return true;

        final score = (oae.score ?? -1).toInt();

        return score == scoreFilter;
      }).length;

      values.add(count.toDouble());
    }

    return values;
  }

  List<String>? get selectedRegionNamesForMap {
    if (selectedRegionFilter == null) return null;

    return <String>[selectedRegionFilter!];
  }

  // ===========================================================================
  // ViewModels auxiliares
  // ===========================================================================

  List<ActiveOaesData> _dataForRegion(String? region) {
    if (region == null || region.trim().isEmpty) {
      return all;
    }

    final normalizedRegion = region.toUpperCase();

    return all.where((oae) {
      return (oae.region ?? '').toUpperCase() == normalizedRegion;
    }).toList(growable: false);
  }

  PieVM pieVM({String? region}) {
    if (region == null) {
      return PieVM(
        labels: pieLabelsForChart,
        values: pieValuesForChart,
        colors: pieColorsForChart,
        total: pieTotal,
      );
    }

    final subset = _dataForRegion(region);
    final order = _pieScoresOrder;

    final counts = <int, int>{
      for (final score in order) score: 0,
    };

    for (final oae in subset) {
      final score = (oae.score ?? -1).toInt().clamp(0, 5);
      counts[score] = (counts[score] ?? 0) + 1;
    }

    final labels = <String>[];
    final values = <double>[];
    final colors = <Color>[];

    for (final score in order) {
      labels.add(ActiveOaesData.getLabelByNota(score));
      values.add((counts[score] ?? 0).toDouble());
      colors.add(ActiveOaesData.getColorByNota(score.toDouble()));
    }

    final total = values.fold<double>(
      0.0,
          (previousTotal, value) => previousTotal + value,
    );

    return PieVM(
      labels: labels,
      values: values,
      colors: colors,
      total: total,
    );
  }

  GaugeVM gaugeForPieSelectionWithRegion({
    String? region,
    int? selectedPieIndex,
  }) {
    final vm = pieVM(region: region);
    final total = vm.total;

    if (total <= 0) {
      return const GaugeVM(
        label: 'Total',
        count: 0,
        total: 0,
        percent: 0,
      );
    }

    if (selectedPieIndex == null ||
        selectedPieIndex < 0 ||
        selectedPieIndex >= vm.values.length) {
      return GaugeVM(
        label: region ?? 'Total',
        count: total,
        total: total,
        percent: 1.0,
      );
    }

    final value = vm.values[selectedPieIndex];
    final label = vm.labels[selectedPieIndex];

    return GaugeVM(
      label: label,
      count: value,
      total: total,
      percent: (value / total).clamp(0.0, 1.0),
    );
  }

  List<OaeRowVM> get oaesRowsVM {
    return all.map((oae) {
      final scoreText = () {
        final score = oae.score;

        if (score == null) return '-';

        final isInteger = score.truncateToDouble() == score;

        return score.toStringAsFixed(isInteger ? 0 : 1);
      }();

      return OaeRowVM(
        id: oae.id,
        order: '${oae.order ?? '-'}',
        score: scoreText,
        state: oae.state ?? '-',
        region: oae.region ?? '-',
        identificationName: oae.identificationName ?? '-',
        extensionStr: _fmtNum(oae.extension),
        widthStr: _fmtNum(oae.width),
        areaStr: _fmtNum(oae.area),
        structureType: oae.structureType ?? '-',
        relatedContracts: oae.relatedContracts ?? '-',
        valueInterventionStr: _fmtMoneyBR(oae.valueIntervention),
        linearCostMediaStr: _fmtMoneyBR(oae.linearCostMedia),
        costEstimateStr: _fmtMoneyBR(oae.costEstimate),
        lastDateInterventionStr: _fmtDate(oae.lastDateIntervention),
        companyBuild: oae.companyBuild ?? '-',
        latStr: _fmtNum(oae.latitude, maxDecimals: 6),
        lngStr: _fmtNum(oae.longitude, maxDecimals: 6),
        altStr: _fmtNum(oae.altitude, maxDecimals: 2),
      );
    }).toList(growable: false);
  }
}

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

  String get subtitle {
    return '${count.toStringAsFixed(0)} de ${total.toStringAsFixed(0)}';
  }
}

class PieVM {
  final List<String> labels;
  final List<double> values;
  final List<Color> colors;
  final double total;

  const PieVM({
    required this.labels,
    required this.values,
    required this.colors,
    required this.total,
  });
}

class OaeRowVM {
  OaeRowVM({
    required this.id,
    required this.order,
    required this.score,
    required this.state,
    required this.region,
    required this.identificationName,
    required this.extensionStr,
    required this.widthStr,
    required this.areaStr,
    required this.structureType,
    required this.relatedContracts,
    required this.valueInterventionStr,
    required this.linearCostMediaStr,
    required this.costEstimateStr,
    required this.lastDateInterventionStr,
    required this.companyBuild,
    required this.latStr,
    required this.lngStr,
    required this.altStr,
  });

  final String? id;

  final String order;
  final String score;
  final String state;
  final String region;
  final String identificationName;

  final String extensionStr;
  final String widthStr;
  final String areaStr;

  final String structureType;
  final String relatedContracts;

  final String valueInterventionStr;
  final String linearCostMediaStr;
  final String costEstimateStr;

  final String lastDateInterventionStr;
  final String companyBuild;

  final String latStr;
  final String lngStr;
  final String altStr;
}

// -----------------------------------------------------------------------------
// Helpers locais
// -----------------------------------------------------------------------------

String _fmtDate(DateTime? date) {
  if (date == null) return '-';

  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString().padLeft(4, '0');

  return '$day/$month/$year';
}

String _fmtMoneyBR(double? value) {
  if (value == null) return '-';

  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final decimals = parts[1];

  final buffer = StringBuffer();

  for (int i = 0; i < intPart.length; i++) {
    buffer.write(intPart[i]);

    final left = intPart.length - i - 1;

    if (left > 0 && left % 3 == 0) {
      buffer.write('.');
    }
  }

  return 'R\$ ${buffer.toString()},$decimals';
}

String _fmtNum(num? value, {int maxDecimals = 3}) {
  if (value == null) return '-';

  var text = value.toStringAsFixed(maxDecimals);

  while (text.contains('.') && (text.endsWith('0') || text.endsWith('.'))) {
    text = text.substring(0, text.length - 1);
  }

  return text;
}