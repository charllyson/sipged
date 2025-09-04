import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:siged/_blocs/actives/oaes/active_oaes_data.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_rules.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_style.dart';

// 👇 GeoJSON
import 'package:siged/_blocs/widgets/map/regional_geo_json_class.dart';
import 'package:siged/_blocs/widgets/map/geo_json_manager.dart';

enum ActiveOaesLoadStatus { idle, loading, success, failure }

class ActiveOaesState extends Equatable {
  static const _unset = Object();

  final bool initialized;
  final ActiveOaesLoadStatus loadStatus;
  final String? error;

  /// Lista principal (sem filtro)
  final List<ActiveOaesData> all;

  /// Edição/formulário
  final ActiveOaesData form;
  final bool isEditable;
  final bool saving;
  final int? selectedIndex;

  /// >>> FILTROS <<<
  /// Índice da fatia no pie (0..5) – ou null (sem filtro)
  final int? selectedPieIndexFilter;
  /// Rótulo da região (ex.: "SERTÃO") – ou null (sem filtro)
  final String? selectedRegionFilter;

  // ========= GeoJSON no State =========
  /// Polígonos regionais carregados (para o mapa).
  final List<PolygonChanged> regionalPolygons;
  /// Cores por região (chave deve casar com o nome do GeoJSON).
  final Map<String, Color> regionColors;
  /// Flag de carregamento do GeoJSON.
  final bool geoLoaded;

  ActiveOaesState({
    this.initialized = false,
    this.loadStatus = ActiveOaesLoadStatus.idle,
    this.error,
    this.all = const [],
    ActiveOaesData? form,
    this.isEditable = false,
    this.saving = false,
    this.selectedIndex,
    this.selectedPieIndexFilter,
    this.selectedRegionFilter,

    // Geo
    this.regionalPolygons = const <PolygonChanged>[],
    this.regionColors = const <String, Color>{},
    this.geoLoaded = false,
  }) : form = form ?? ActiveOaesData();

  ActiveOaesState copyWith({
    bool? initialized,
    ActiveOaesLoadStatus? loadStatus,
    String? error,
    List<ActiveOaesData>? all,
    ActiveOaesData? form,
    bool? isEditable,
    bool? saving,
    int? selectedIndex,

    /// Use _unset para diferenciar "não alterar" de "definir null"
    Object? selectedPieIndexFilter = _unset,
    Object? selectedRegionFilter = _unset,

    // Geo
    List<PolygonChanged>? regionalPolygons,
    Map<String, Color>? regionColors,
    bool? geoLoaded,
  }) {
    return ActiveOaesState(
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

      // Geo
      regionalPolygons: regionalPolygons ?? this.regionalPolygons,
      regionColors: regionColors ?? this.regionColors,
      geoLoaded: geoLoaded ?? this.geoLoaded,
    );
  }

  /// Helper para aplicar o GeoJsonManager no state (sincrônico).
  ActiveOaesState withGeoManager(GeoJsonManager gm) {
    return copyWith(
      regionalPolygons: gm.regionalPolygons,
      regionColors: gm.regionColors,
      geoLoaded: true,
    );
  }

  /// Helper assíncrono para carregar e aplicar os dados regionais.
  static Future<ActiveOaesState> loadGeoRegionals(
      ActiveOaesState state,
      GeoJsonManager gm,
      ) async {
    // mesmo método que você usa no DashboardController
    await gm.loadLimitsRegionalsDERAL();
    return state.withGeoManager(gm);
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
    // Geo
    regionalPolygons,
    regionColors,
    geoLoaded,
  ];

  // ===========================================================================
  // PIE (Notas 0..5)
  // ===========================================================================
  List<int> get _pieScoresOrder => const <int>[0, 1, 2, 3, 4, 5];

  Map<int, int> get _countByScore {
    final map = <int, int>{for (final s in _pieScoresOrder) s: 0};
    for (final o in all) {
      final s = (o.score ?? -1).toInt().clamp(0, 5);
      map[s] = (map[s] ?? 0) + 1;
    }
    return map;
  }

  /// Encontra o primeiro índice em `all` com a nota informada (para espelhar seleção)
  int firstOriginalIndexForScore(int scoreInt) {
    return all.indexWhere((o) => (o.score ?? -1).toInt() == scoreInt);
  }

  List<({int score, String label, double value, Color color})> get _pieItems {
    final counts = _countByScore;
    return _pieScoresOrder.map((score) {
      final qtd = counts[score] ?? 0;
      final label = OaesDataStyle.getLabelByNota(score);
      final color = OaesDataStyle.getColorByNota(score.toDouble());
      return (score: score, label: label, value: qtd.toDouble(), color: color);
    }).toList(growable: false);
  }

  List<String> get pieLabelsForChart =>
      _pieItems.map((e) => e.label).toList(growable: false);

  List<double> get pieValuesForChart =>
      _pieItems.map((e) => e.value).toList(growable: false);

  List<Color> get pieColorsForChart =>
      _pieItems.map((e) => e.color).toList(growable: false);

  /// Soma total das fatias do pie (ex.: 294)
  double get pieTotal => _pieItems.fold<double>(0.0, (sum, e) => sum + e.value);

  /// Mapeia índice do pie para a nota correspondente
  int scoreFromPieChartIndex(int pieIndex) {
    final items = _pieItems;
    if (pieIndex < 0 || pieIndex >= items.length) return -1;
    return items[pieIndex].score;
  }

  // ===========================================================================
  // GAUGE (derivado do Pie)
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
  List<String> get regionLabels => ContractRules.regions;

  List<double> get regionCounts {
    final labels = regionLabels;
    final values = <double>[];
    for (final label in labels) {
      final rUp = label.toUpperCase();
      final count =
          all.where((o) => (o.region ?? '').toUpperCase() == rUp).length;
      values.add(count.toDouble());
    }
    return values;
  }

  /// Contagens por região filtradas por uma nota (score) específica.
  List<double> regionCountsFiltered({int? score}) {
    final labels = regionLabels;
    final values = <double>[];
    for (final label in labels) {
      final rUp = label.toUpperCase();
      final count = all.where((o) {
        final sameRegion = (o.region ?? '').toUpperCase() == rUp;
        if (!sameRegion) return false;
        if (score == null) return true;
        final s = (o.score ?? -1).toInt();
        return s == score;
      }).length;
      values.add(count.toDouble());
    }
    return values;
  }

  List<double> get regionTotalsByValue {
    final labels = regionLabels;
    final values = <double>[];
    for (final label in labels) {
      final rUp = label.toUpperCase();
      final sum = all
          .where((o) => (o.region ?? '').toUpperCase() == rUp)
          .fold<double>(0.0, (acc, o) => acc + (o.valueIntervention ?? 0.0));
      values.add(sum);
    }
    return values;
  }

  List<Color> regionBarColors(int? selectedRegionIndex) {
    final values = regionCounts;
    return List<Color>.generate(values.length, (i) {
      final v = values[i];
      if (v == 0.0) return Colors.grey.shade300;
      return (selectedRegionIndex != null && selectedRegionIndex == i)
          ? Colors.orangeAccent
          : Colors.blueAccent;
    });
  }

  // ===========================================================================
  // >>> FILTRO APLICADO (para o MAPA e demais UIs) <<<
  // ===========================================================================
  int? get _scoreFilterOrNull {
    if (selectedPieIndexFilter == null) return null;
    final idx = selectedPieIndexFilter!;
    final score = scoreFromPieChartIndex(idx);
    if (score < 0) return null;
    return score;
  }

  /// Lista já filtrada por (região) e/ou (score do pie)
  List<ActiveOaesData> get filteredAll {
    final scoreFilter = _scoreFilterOrNull;
    final regionFilter = selectedRegionFilter?.toUpperCase();

    return all.where((o) {
      final okRegion = regionFilter == null
          ? true
          : (o.region ?? '').toUpperCase() == regionFilter;
      if (!okRegion) return false;

      if (scoreFilter == null) return true;
      final s = (o.score ?? -1).toInt();
      return s == scoreFilter;
    }).toList(growable: false);
  }

  /// Totais por região levando em conta o score selecionado no pie (se houver)
  List<double> regionCountsFilteredByPie() {
    final labels = regionLabels;
    final scoreFilter = _scoreFilterOrNull;
    final values = <double>[];

    for (final label in labels) {
      final rUp = label.toUpperCase();
      final count = all.where((o) {
        final sameRegion = (o.region ?? '').toUpperCase() == rUp;
        if (!sameRegion) return false;
        if (scoreFilter == null) return true;
        final s = (o.score ?? -1).toInt();
        return s == scoreFilter;
      }).length;
      values.add(count.toDouble());
    }
    return values;
  }

  /// Conveniência para o MapInteractivePage (seleção a espelhar no mapa)
  List<String>? get selectedRegionNamesForMap =>
      selectedRegionFilter == null ? null : [selectedRegionFilter!];

  // ===========================================================================
  // ViewModel/VMs auxiliares
  // ===========================================================================
  List<ActiveOaesData> _dataForRegion(String? region) {
    if (region == null || region.isEmpty) return all;
    final rUp = region.toUpperCase();
    return all.where((o) => (o.region ?? '').toUpperCase() == rUp).toList();
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
    final counts = <int, int>{for (final s in order) s: 0};
    for (final oae in subset) {
      final s = (oae.score ?? -1).toInt().clamp(0, 5);
      counts[s] = (counts[s] ?? 0) + 1;
    }

    final labels = <String>[];
    final values = <double>[];
    final colors = <Color>[];
    for (final score in order) {
      labels.add(OaesDataStyle.getLabelByNota(score));
      values.add((counts[score] ?? 0).toDouble());
      colors.add(OaesDataStyle.getColorByNota(score.toDouble()));
    }
    final total = values.fold<double>(0.0, (acc, v) => acc + v);
    return PieVM(labels: labels, values: values, colors: colors, total: total);
  }

  GaugeVM gaugeForPieSelectionWithRegion({
    String? region,
    int? selectedPieIndex,
  }) {
    final vm = pieVM(region: region);
    final total = vm.total;

    if (total <= 0) {
      return const GaugeVM(label: 'Total', count: 0, total: 0, percent: 0);
    }

    if (selectedPieIndex == null ||
        selectedPieIndex < 0 ||
        selectedPieIndex >= vm.values.length) {
      return GaugeVM(
        label: region == null ? 'Total' : region,
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

  // ---- VMs tabela ----
  List<OaeRowVM> get oaesRowsVM {
    return all.map((a) {
      final scoreStr = () {
        final s = a.score;
        if (s == null) return '-';
        final asInt = s.truncateToDouble() == s;
        return s.toStringAsFixed(asInt ? 0 : 1);
      }();

      return OaeRowVM(
        id: a.id,
        order: '${a.order ?? '-'}',
        score: scoreStr,
        state: a.state ?? '-',
        region: a.region ?? '-',
        identificationName: a.identificationName ?? '-',
        extensionStr: _fmtNum(a.extension),
        widthStr: _fmtNum(a.width),
        areaStr: _fmtNum(a.area),
        structureType: a.structureType ?? '-',
        relatedContracts: a.relatedContracts ?? '-',
        valueInterventionStr: _fmtMoneyBR(a.valueIntervention),
        linearCostMediaStr: _fmtMoneyBR(a.linearCostMedia),
        costEstimateStr: _fmtMoneyBR(a.costEstimate),
        lastDateInterventionStr: _fmtDate(a.lastDateIntervention),
        companyBuild: a.companyBuild ?? '-',
        latStr: _fmtNum(a.latitude, maxDecimals: 6),
        lngStr: _fmtNum(a.longitude, maxDecimals: 6),
        altStr: _fmtNum(a.altitude, maxDecimals: 2),
      );
    }).toList(growable: false);
  }
}

/// VM do Gauge
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

  String get subtitle =>
      '${count.toStringAsFixed(0)} de ${total.toStringAsFixed(0)}';
}

/// VM do Pie
class PieVM {
  final List<String> labels;
  final List<double> values;
  final List<Color> colors;
  final double total; // soma(values)
  const PieVM({
    required this.labels,
    required this.values,
    required this.colors,
    required this.total,
  });
}

/// ViewModel de uma linha pré-formatada
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
  final String order, score, state, region, identificationName;
  final String extensionStr, widthStr, areaStr;
  final String structureType, relatedContracts;
  final String valueInterventionStr, linearCostMediaStr, costEstimateStr;
  final String lastDateInterventionStr, companyBuild;
  final String latStr, lngStr, altStr;
}

// ---------- Helpers locais simples (sem intl) ----------
String _fmtDate(DateTime? d) {
  if (d == null) return '-';
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final yy = d.year.toString().padLeft(4, '0');
  return '$dd/$mm/$yy';
}

String _fmtMoneyBR(double? v) {
  if (v == null) return '-';
  final s = v.toStringAsFixed(2);
  final parts = s.split('.');
  final intPart = parts[0];
  final dec = parts[1];

  final buf = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    buf.write(intPart[i]);
    final left = intPart.length - i - 1;
    if (left > 0 && left % 3 == 0) buf.write('.');
  }
  return 'R\$ ${buf.toString()},$dec';
}

String _fmtNum(num? v, {int maxDecimals = 3}) {
  if (v == null) return '-';
  var s = v.toStringAsFixed(maxDecimals);
  while (s.contains('.') && (s.endsWith('0') || s.endsWith('.'))) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}
