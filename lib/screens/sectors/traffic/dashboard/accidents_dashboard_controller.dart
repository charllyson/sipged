import 'dart:math' as math;
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:sisged/_blocs/widgets/map_bloc.dart';
import 'package:sisged/_blocs/sectors/transit/accidents/accidents_bloc.dart';
import 'package:sisged/_datas/sectors/transit/accidents/accidents_data.dart';
import '../../../../_services/regional_geo_json_class.dart';
import '../../../../_services/geo_json_service.dart';

class AccidentsDashboardController extends ChangeNotifier {
  final MapBloc mapBloc = MapBloc();
  final AccidentsBloc accidentsBloc = AccidentsBloc();

  bool initRan = false;

  bool _loading = true;
  bool get loading => _loading;

  // Dados base
  List<AccidentsData> _allData = [];
  List<AccidentsData> _dataFilteredByYearMonth = [];
  List<AccidentsData> _dataView = [];

  List<AccidentsData> get allData => _allData;
  List<AccidentsData> get dataFiltered => _dataFilteredByYearMonth;
  List<AccidentsData> get dataView => _dataView;

  // Filtros
  int? currentYear = DateTime.now().year;
  int? currentMonth;

  String? selectedRegionName;
  String? selectedStatus;
  String? selectedAccidentType;

  int? selectedIndexRegion;
  int? selectedIndexType;
  int? selectedIndexMortes; // (reservado, se for usar depois)

  final List<String> _selectedRegionUpper = [];
  String? _typeSelectedUpper;

  // ---- dados dos gráficos (prontos para UI) ----
  Map<String, double> _totaisPorCidade = {};
  Map<String, double> _totaisPorTipo = {};
  Map<String, double> _mortesPorCidade = {};

  List<String> labelsRegiao = [];
  List<double> valuesRegiao = [];
  List<String> labelsType = [];
  List<double> valuesType = [];

  Future<void> _recalcularGraficos() async {
    _totaisPorCidade = await accidentsBloc.getValoresPorCidade(_dataView);
    _totaisPorTipo = await accidentsBloc.getTotaisPorTipoAcidente(_dataView);
    _mortesPorCidade = await accidentsBloc.getMortesPorCidade(_dataView);

    labelsRegiao = _totaisPorCidade.entries.where((e) => e.value > 0).map((e) => e.key).toList();
    valuesRegiao = _totaisPorCidade.entries.where((e) => e.value > 0).map((e) => e.value).toList();

    labelsType = _totaisPorTipo.entries.where((e) => e.value > 0).map((e) => e.key).toList();
    valuesType = _totaisPorTipo.entries.where((e) => e.value > 0).map((e) => e.value).toList();

    // índices coerentes com o que está visível
    selectedIndexRegion = labelsRegiao.indexWhere(
          (r) => r.toUpperCase() == selectedRegionName?.toUpperCase(),
    );
    selectedIndexType = labelsType.indexWhere(
          (t) => t.toUpperCase() == selectedAccidentType?.toUpperCase(),
    );
  }

  // --------- resumo (selectorDates) ---------
  Map<String, double> totalsByAccidentType = {
    for (final t in AccidentsData.accidentTypes) t: 0.0,
  };

  void _recalcularResumo() {
    // zera
    for (final k in totalsByAccidentType.keys) {
      totalsByAccidentType[k] = 0.0;
    }
    // conta direto (sem async)
    for (final a in _dataView) {
      final tipo = (a.typeOfAccident ?? '').toUpperCase().trim();
      if (tipo.isEmpty) continue;

      // Se quiser normalizar para as chaves conhecidas:
      final key = AccidentsData.getTitleByAccidentType(tipo).toUpperCase() == 'OUTROS'
          ? 'OUTROS'
          : tipo;

      if (totalsByAccidentType.containsKey(key)) {
        totalsByAccidentType[key] = (totalsByAccidentType[key] ?? 0) + 1.0;
      } else {
        // se vier um tipo novo, jogue em OUTROS
        totalsByAccidentType['OUTROS'] = (totalsByAccidentType['OUTROS'] ?? 0) + 1.0;
      }
    }
  }

  // --------- mapa (migrado p/ controller) ---------
  final Map<String, int> cityOfAccident = {};
  late List<RegionalPolygon> regionalPolygons = [];

  String normalizeString(String? nome) {
    if (nome == null) return '';
    final noAccent = removeDiacritics(nome);
    final noMultipleSpace = noAccent.replaceAll(RegExp(r'\s+'), ' ');
    return noMultipleSpace.trim().toUpperCase();
  }

  Future<void> loadAccidentsData(List<AccidentsData> accidentsData) async {
    cityOfAccident.clear();
    for (final acc in accidentsData) {
      final city = normalizeString(acc.city);
      if (city.isEmpty) continue;
      cityOfAccident[city] = (cityOfAccident[city] ?? 0) + 1;
    }
  }

  Map<String, Color> calculateColorsFilteredCity(List<AccidentsData> filteredAccidentsData) {
    final count = <String, int>{};
    for (final accidents in filteredAccidentsData) {
      final city = normalizeString(accidents.city);
      if (city.isEmpty) continue;
      count[city] = (count[city] ?? 0) + 1;
    }
    final max = count.values.fold<int>(1, (a, b) => math.max(a, b));
    return {
      for (final entry in count.entries)
        entry.key: interpolateColorsAccidentsFactor(
          (entry.value / max).clamp(0.05, 1.0),
        ),
    };
  }

  Color interpolateColorsAccidentsFactor(double accidentsFactor) {
    final palette = AccidentsData.statusColorsAccidentType;
    final index = (accidentsFactor * (palette.length - 1)).floor().clamp(0, palette.length - 2);
    final t = accidentsFactor * (palette.length - 1) - index;
    return Color.lerp(palette[index], palette[index + 1], t)!;
  }

  Future<void> loadLimitsCitiesOfAlagoas() async {
    final geoJsonData = await GeoJsonService.loadServicePolygonsOfCitiesAL(
      assetPath: 'assets/geojson/limits/limites_cidades_al.geojson',
    );
    regionalPolygons
      ..clear()
      ..addAll(geoJsonData);
  }

  // --------------------------- ciclo de vida ---------------------------
  void start() {
    WidgetsBinding.instance.addPostFrameCallback((_) => initialize());
  }

  Future<void> initialize() async {
    if (initRan) return;
    initRan = true;

    _setLoading(true);
    try {
      await loadLimitsCitiesOfAlagoas();

      _allData = await accidentsBloc.getAllAccidents();

      _dataFilteredByYearMonth = await accidentsBloc.getAllAccidents(
        year: currentYear,
        month: currentMonth,
      );

      _applyLocalFilters(); // define _dataView
      await _refreshMapWith(_dataView);
      await _recalcularTudo(); // gráficos + resumo
      _safeNotify();
    } finally {
      _setLoading(false);
    }
  }

  // --------------------------- handlers de filtro ---------------------------
  Future<void> onSelectorChanged({int? year, int? month}) async {
    _setLoading(true);
    try {
      currentYear = year;
      currentMonth = month;

      _dataFilteredByYearMonth = await accidentsBloc.getAllAccidents(
        year: year,
        month: month,
      );

      _applyLocalFilters();
      await _refreshMapWith(_dataView);
      await _recalcularTudo(); // recalcula gráficos + resumo após trocar período
      _safeNotify();
    } finally {
      _setLoading(false);
    }
  }

  // Só highlight por padrão (applyFilter=false)
  Future<void> onTypeSelected(String? typeName, {bool applyFilter = false}) async {
    final same = typeName != null && _typeSelectedUpper == typeName.toUpperCase();

    if (typeName == null || same) {
      selectedAccidentType = null;
      _typeSelectedUpper = null;
    } else {
      selectedAccidentType = typeName;
      _typeSelectedUpper = typeName.toUpperCase();
    }

    if (applyFilter) {
      selectedRegionName = null;
      selectedIndexRegion = null;
      _selectedRegionUpper.clear();

      _applyLocalFilters();
      await _refreshMapWith(_dataView);
      await _recalcularTudo();
      _safeNotify();
    } else {
      // apenas highlight → atualiza índice imediato
      selectedIndexType = labelsType.indexWhere(
            (t) => t.toUpperCase() == selectedAccidentType?.toUpperCase(),
      );
      _safeNotify();
    }
  }

  Future<void> onRegionSelected(String? regionName, {bool applyFilter = false}) async {
    final touchedSame =
        regionName != null && _selectedRegionUpper.contains(regionName.toUpperCase());

    if (regionName == null || touchedSame) {
      selectedRegionName = null;
      _selectedRegionUpper.clear();
    } else {
      selectedRegionName = regionName;
      _selectedRegionUpper
        ..clear()
        ..add(regionName.toUpperCase());
    }

    if (applyFilter) {
      _applyLocalFilters();
      await _refreshMapWith(_dataView);
      await _recalcularTudo();
      _safeNotify();
    } else {
      // apenas highlight
      selectedIndexRegion = labelsRegiao.indexWhere(
            (r) => r.toUpperCase() == selectedRegionName?.toUpperCase(),
      );
      _safeNotify();
    }
  }

  void onStatusSelected(String? status) {
    final same = status != null && (selectedStatus?.toUpperCase() == status.toUpperCase());
    selectedStatus = (status == null || same) ? null : status;

    // TODO: quando houver campo de status no modelo, aplicar no filtro:
    // _applyLocalFilters(); await _refreshMapWith(_dataView); await _recalcularTudo();
    _safeNotify();
  }

  Future<void> clearSelections() async {
    selectedStatus = null;
    selectedRegionName = null;
    selectedAccidentType = null;

    selectedIndexRegion = null;
    selectedIndexType = null;
    selectedIndexMortes = null;

    _selectedRegionUpper.clear();
    _typeSelectedUpper = null;

    _applyLocalFilters();
    await _refreshMapWith(_dataView);
    await _recalcularTudo();
    _safeNotify();
  }

  // --------------------------- mapa: cores & fetch ---------------------------
  Map<String, Color> get regionColorsForMap => calculateColorsFilteredCity(_dataView);

  Future<List<AccidentsData>> fetchCityAccidents(String city) {
    return accidentsBloc.getAccidentsByCityList(
      cityName: city,
      year: currentYear,
      month: currentMonth,
    );
  }

  // --------------------------- filtragem local ---------------------------
  void _applyLocalFilters() {
    final base = _dataFilteredByYearMonth;

    final result = base.where((d) {
      final cityUpper = (d.city ?? '').toUpperCase();
      final typeUpper = (d.typeOfAccident ?? '').toUpperCase();

      final matchRegion = _selectedRegionUpper.isEmpty
          ? true
          : _selectedRegionUpper.any((r) => cityUpper.contains(r));

      final matchType = _typeSelectedUpper == null ? true : typeUpper == _typeSelectedUpper;

      // ainda não aplicamos status
      final matchStatus = true;

      return matchRegion && matchType && matchStatus;
    }).toList();

    _dataView = result;
    // não notifica aqui; quem chama vai recalcular gráficos/resumo e notificar
  }

  Future<void> _refreshMapWith(List<AccidentsData> data) async {
    await loadAccidentsData(data);
  }

  Future<void> _recalcularTudo() async {
    await _recalcularGraficos();
    _recalcularResumo();
  }

  // --------------------------- infra ---------------------------
  void _setLoading(bool v) {
    _loading = v;
    _safeNotify();
  }

  void _safeNotify() {
    if (!hasListeners) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle) {
      notifyListeners();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
