// lib/screens/sectors/traffic/accidents/controllers/accidents_controller.dart
import 'dart:math' as math;
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:sisged/_blocs/sectors/transit/accidents/accidents_bloc.dart';
import 'package:sisged/_blocs/system/system_bloc.dart';
import 'package:sisged/_datas/sectors/transit/accidents/accidents_data.dart';
import 'package:sisged/_datas/system/user_data.dart';
import 'package:sisged/_blocs/system/user_provider.dart';
import 'package:sisged/_widgets/formats/format_field.dart';

import 'package:sisged/_blocs/widgets/map_bloc.dart';
import 'package:sisged/_datas/widgets/regional_geo_json_class.dart';
import 'package:sisged/_services/geo_json_service.dart';

/// Controlador unificado: formulário + paginação + filtros globais + gráficos/mapa.
class AccidentsController extends ChangeNotifier {
  AccidentsController({
    required AccidentsBloc accidentsBloc,
    required SystemBloc systemBloc,
  })  : _accidentsBloc = accidentsBloc,
        _systemBloc = systemBloc;

  // ========= DEPS (atualizáveis em hot reload via ProxyProvider) =========
  AccidentsBloc _accidentsBloc;
  SystemBloc _systemBloc;

  void updateDeps(AccidentsBloc a, SystemBloc s) {
    _accidentsBloc = a;
    _systemBloc = s;
  }

  // ========= ESTADO BASE / PERMISSÃO =========
  bool initRan = false;
  bool isEditable = false;
  bool isSaving = false;
  bool formValidated = false;
  bool _loading = false;
  bool get loading => _loading;

  // ========= FILTROS GLOBAIS (dashboard + tabela) =========
  int? yearFilter;   // null = todos os anos
  int? monthFilter;  // null = todos os meses

  // ========= PAGINAÇÃO (tabela) =========
  int currentPage = 1;
  int totalPages = 1;
  final int limitPerPage = 15;
  bool isFiltering = false;
  bool isPaging = false;

  // ========= SELEÇÃO (tabela) =========
  int? selectedLine;
  String? currentAccidentId;
  AccidentsData? selectedAccident;

  // ========= DADOS (base e visões) =========
  List<AccidentsData> _all = [];          // tudo (todos anos)
  List<AccidentsData> _byYearMonth = [];  // filtrado por yearFilter/monthFilter
  List<AccidentsData> _view = [];         // filtrado localmente (tipo/região/status)
  List<AccidentsData> get allData => _all;
  List<AccidentsData> get dataFiltered => _byYearMonth;
  List<AccidentsData> get dataView => _view;

  // Universo cache para tabela
  List<AccidentsData> selectorUniverse = [];
  List<AccidentsData> _allUniverse = [];
  List<AccidentsData> _filtered = [];
  List<AccidentsData> pageItems = [];
  List<AccidentsData> allCached = [];

  // ========= FORM CONTROLLERS =========
  final orderCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final highwayCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final typeOfAccidentCtrl = TextEditingController();
  final deathCtrl = TextEditingController();
  final scoresVictimsCtrl = TextEditingController();
  final transportInvolvedCtrl = TextEditingController();

  final latitudeCtrl = TextEditingController();
  final longitudeCtrl = TextEditingController();
  final postalCodeCtrl = TextEditingController();
  final streetCtrl = TextEditingController();
  final city2Ctrl = TextEditingController();
  final subLocalityCtrl = TextEditingController();
  final administrativeAreaCtrl = TextEditingController();
  final countryCtrl = TextEditingController();
  final isoCountryCodeCtrl = TextEditingController();

  // ========= DASHBOARD (gráficos/mapa) =========
  final MapBloc mapBloc = MapBloc();

  // seleção de filtros locais
  String? selectedRegionName;
  String? selectedStatus;
  String? selectedAccidentType;

  int? selectedIndexRegion;
  int? selectedIndexType;
  int? selectedIndexMortes;

  final List<String> _selectedRegionUpper = [];
  String? _typeSelectedUpper;

  // gráficos
  Map<String, double> _totaisPorCidade = {};
  Map<String, double> _totaisPorTipo = {};
  Map<String, double> _mortesPorCidade = {};
  List<String> labelsRegiao = [];
  List<double> valuesRegiao = [];
  List<String> labelsType = [];
  List<double> valuesType = [];

  // resumo
  Map<String, double> totalsByAccidentType = {
    for (final t in AccidentsData.accidentTypes) t: 0.0,
  };
  double valorTotal = 0;   // total global (todos anos)
  double totalByType = 0;  // total do período filtrado (após filtros locais)

  // mapa
  late List<PolygonChanged> regionalPolygons = [];
  final Map<String, int> cityOfAccident = {};

  // heatmap
  List<Color> _heatmapPalette = const [
    Color(0xFFFFF59D), // amarelo claro
    Color(0xFFFFB300), // laranja
    Color(0xFFD32F2F), // vermelho
  ];
  bool useLogScale = false;
  Color? zeroValueColor = const Color(0xFF2E7D32); // cidades com 0 → verde

  // ========= LIFECYCLE =========
  Future<void> postFrameInit(BuildContext context) async {
    if (initRan) return;
    initRan = true;

    final user = context.read<UserProvider>().userData;
    if (user != null) isEditable = _canEditUser(user);

    _setLoading(true);
    try {
      await _loadLimitsCitiesOfAlagoas();

      // Carrega tudo
      _all = await _accidentsBloc.getAllAccidents();

      // Filtro padrão: ano atual (como era o AccidentsController)
      yearFilter = DateTime.now().year;
      monthFilter = null;

      _byYearMonth = await _accidentsBloc.getAllAccidents(
        year: yearFilter,
        month: monthFilter,
      );

      // Dados para tabela baseados em "universo"
      selectorUniverse = List<AccidentsData>.from(_all);
      _allUniverse = List<AccidentsData>.from(selectorUniverse);

      // Aplica filtros locais (tipo/região/status) => _view
      _applyLocalFilters();

      // Paginador e campos default
      await _sliceAndCalcPagination(resetToFirstPage: true, allowReset: true);

      // Map + gráficos
      await _refreshMapWith(_view);
      await _recalcChartsAndSummary();

      _attachValidation();
      _safeNotify();
    } finally {
      _setLoading(false);
    }
  }

  bool _canEditUser(UserData user) {
    final base = (user.baseProfile ?? '').toLowerCase();
    if (base == 'administrador' || base == 'colaborador') return true;
    final perms = user.modulePermissions['accidents'];
    if (perms != null) return (perms['edit'] == true) || (perms['create'] == true);
    return false;
  }

  @override
  void dispose() {
    for (final c in [
      orderCtrl,
      dateCtrl,
      highwayCtrl,
      cityCtrl,
      typeOfAccidentCtrl,
      deathCtrl,
      scoresVictimsCtrl,
      transportInvolvedCtrl,
      latitudeCtrl,
      longitudeCtrl,
      postalCodeCtrl,
      streetCtrl,
      city2Ctrl,
      subLocalityCtrl,
      administrativeAreaCtrl,
      countryCtrl,
      isoCountryCodeCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ========= TABELA: filtros por data + paginação =========
  Future<void> changeYear(int? year) async {
    await onSelectorChanged(year: year, month: monthFilter);
  }

  Future<void> changeMonth(int? month) async {
    await onSelectorChanged(year: yearFilter, month: month);
  }

  Future<void> onSelectorChanged({int? year, int? month}) async {
    // Atualiza filtros globais e refaz tudo
    _setLoading(true);
    try {
      yearFilter = year;
      monthFilter = month;

      _byYearMonth = await _accidentsBloc.getAllAccidents(
        year: yearFilter,
        month: monthFilter,
      );

      _applyLocalFilters();
      await _sliceAndCalcPagination(resetToFirstPage: true, allowReset: true);

      await _refreshMapWith(_view);
      await _recalcChartsAndSummary();
      _safeNotify();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _sliceAndCalcPagination({required bool resetToFirstPage, required bool allowReset}) async {
    isFiltering = true;
    try {
      // Para a tabela, usamos _view (pós filtros locais)
      _filtered = List<AccidentsData>.from(_view)
        ..sort((a, b) {
          final ad = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bd = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bd.compareTo(ad);
        });

      allCached = _filtered;

      final totalDocs = _filtered.length;
      totalPages = totalDocs == 0 ? 1 : ((totalDocs + limitPerPage - 1) ~/ limitPerPage);

      if (allowReset && resetToFirstPage) {
        currentPage = 1;
      } else {
        if (currentPage > totalPages) currentPage = totalPages;
        if (currentPage < 1) currentPage = 1;
      }

      _slicePage();

      if (allowReset) {
        orderCtrl.text = _calcNextOrder(allCached).toString();
        dateCtrl.text = dateToString(DateTime.now());
      }
    } finally {
      isFiltering = false;
      _safeNotify();
    }
  }

  void _slicePage() {
    if (_filtered.isEmpty) {
      pageItems = [];
      return;
    }
    final start = (currentPage - 1) * limitPerPage;
    final end = (start + limitPerPage) > _filtered.length ? _filtered.length : (start + limitPerPage);
    pageItems = _filtered.sublist(start, end);
  }

  Future<void> loadPage(int page) async {
    if (isPaging) return;
    if (page < 1 || page > totalPages) return;
    isPaging = true;
    _safeNotify();
    try {
      currentPage = page;
      _slicePage();
    } finally {
      isPaging = false;
      _safeNotify();
    }
  }

  int _calcNextOrder(List<AccidentsData> list) {
    return (list.map((e) => e.order ?? 0).fold(0, (a, b) => a > b ? a : b)) + 1;
  }

  // ========= FORM =========
  void _attachValidation() {
    for (final c in [cityCtrl, dateCtrl, highwayCtrl, typeOfAccidentCtrl]) {
      c.addListener(_validateForm);
    }
    _validateForm();
  }

  void _validateForm() {
    final ok = cityCtrl.text.trim().isNotEmpty &&
        dateCtrl.text.trim().isNotEmpty &&
        highwayCtrl.text.trim().isNotEmpty &&
        typeOfAccidentCtrl.text.trim().isNotEmpty;
    if (formValidated != ok) {
      formValidated = ok;
      _safeNotify();
    }
  }

  void selectFromTable(AccidentsData data, int index) {
    selectedLine = index;
    fillFields(data);
  }

  void fillFields(AccidentsData data) {
    selectedAccident = data;
    currentAccidentId = data.id;

    cityCtrl.text = data.city ?? '';
    dateCtrl.text = data.date != null ? dateToString(data.date!) : '';
    deathCtrl.text = (data.death ?? 0).toString();
    highwayCtrl.text = data.highway ?? '';
    scoresVictimsCtrl.text = (data.scoresVictims ?? 0).toString();
    transportInvolvedCtrl.text = data.transportInvolved ?? '';
    typeOfAccidentCtrl.text = data.typeOfAccident ?? '';

    latitudeCtrl.text = data.latLng?.latitude.toString() ?? '';
    longitudeCtrl.text = data.latLng?.longitude.toString() ?? '';
    postalCodeCtrl.text = data.postalCode ?? '';
    streetCtrl.text = data.street ?? '';
    city2Ctrl.text = data.city ?? '';
    subLocalityCtrl.text = data.subLocality ?? '';
    administrativeAreaCtrl.text = data.administrativeArea ?? '';
    countryCtrl.text = data.country ?? '';
    isoCountryCodeCtrl.text = data.isoCountryCode ?? '';

    orderCtrl.text = (data.order ?? '').toString();

    _validateForm();
    _safeNotify();
  }

  Future<void> createNew() async {
    selectedLine = null;
    currentAccidentId = null;
    selectedAccident = null;

    orderCtrl.text = _calcNextOrder(allCached).toString();

    for (final c in [
      dateCtrl,
      deathCtrl,
      highwayCtrl,
      scoresVictimsCtrl,
      transportInvolvedCtrl,
      typeOfAccidentCtrl,
      latitudeCtrl,
      longitudeCtrl,
      postalCodeCtrl,
      streetCtrl,
      cityCtrl,
      city2Ctrl,
      subLocalityCtrl,
      administrativeAreaCtrl,
      countryCtrl,
      isoCountryCodeCtrl,
    ]) {
      c.clear();
    }
    dateCtrl.text = dateToString(DateTime.now());

    _validateForm();
    _safeNotify();
  }

  Future<void> saveOrUpdate(BuildContext context) async {
    isSaving = true;
    _safeNotify();

    final newAccident = AccidentsData(
      id: currentAccidentId,
      date: stringToDate(dateCtrl.text),
      death: int.tryParse(deathCtrl.text),
      highway: highwayCtrl.text,
      scoresVictims: int.tryParse(scoresVictimsCtrl.text),
      transportInvolved: transportInvolvedCtrl.text,
      typeOfAccident: typeOfAccidentCtrl.text,
      latLng: LatLng(
        double.tryParse(latitudeCtrl.text) ?? 0,
        double.tryParse(longitudeCtrl.text) ?? 0,
      ),
      postalCode: postalCodeCtrl.text,
      street: streetCtrl.text,
      city: city2Ctrl.text.isNotEmpty ? city2Ctrl.text : cityCtrl.text,
      subLocality: subLocalityCtrl.text,
      administrativeArea: administrativeAreaCtrl.text,
      country: countryCtrl.text,
      isoCountryCode: isoCountryCodeCtrl.text,
      order: int.tryParse(orderCtrl.text),
    );

    await _accidentsBloc.saveOrUpdateAccident(newAccident);

    // Recarrega bases (tudo e período) para manter dashboard + tabela coerentes
    _all = await _accidentsBloc.getAllAccidents();
    _byYearMonth = await _accidentsBloc.getAllAccidents(year: yearFilter, month: monthFilter);

    selectorUniverse = List<AccidentsData>.from(_all);
    _allUniverse = List<AccidentsData>.from(selectorUniverse);

    _applyLocalFilters();
    await _sliceAndCalcPagination(resetToFirstPage: false, allowReset: false);

    await createNew();

    isSaving = false;
    _safeNotify();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acidente salvo com sucesso!'), backgroundColor: Colors.green),
      );
    }

    // Atualiza mapa + gráficos
    await _refreshMapWith(_view);
    await _recalcChartsAndSummary();
    _safeNotify();
  }

  Future<void> deleteAccident(BuildContext context, String id) async {
    final AccidentsData? item = _allUniverse.firstWhere(
          (e) => e.id == id,
      orElse: () => AccidentsData(id: id),
    );
    final int year = item?.date?.year ?? yearFilter ?? DateTime.now().year;

    await _accidentsBloc.deletarAccident(id: id, year: year);

    _all = await _accidentsBloc.getAllAccidents();
    _byYearMonth = await _accidentsBloc.getAllAccidents(year: yearFilter, month: monthFilter);

    selectorUniverse = List<AccidentsData>.from(_all);
    _allUniverse = List<AccidentsData>.from(selectorUniverse);

    _applyLocalFilters();
    await _sliceAndCalcPagination(resetToFirstPage: false, allowReset: false);

    selectedLine = null;
    _safeNotify();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acidente apagado com sucesso.'), backgroundColor: Colors.red),
      );
    }

    await _refreshMapWith(_view);
    await _recalcChartsAndSummary();
    _safeNotify();
  }

  // ========= GEOLOCALIZAÇÃO =========
  Future<void> fillFromUserLocation(BuildContext context) async {
    final coords = await _systemBloc.getUserCurrentLocation();
    if (coords == null) return;

    latitudeCtrl.text = coords.latitude.toStringAsFixed(6);
    longitudeCtrl.text = coords.longitude.toStringAsFixed(6);

    final placemark = await _systemBloc.getPlaceMarkAdapted(coords);
    if (placemark != null) {
      postalCodeCtrl.text = placemark.postalCode ?? '';
      streetCtrl.text = placemark.street ?? '';
      cityCtrl.text = placemark.locality ?? '';
      subLocalityCtrl.text = placemark.subLocality ?? '';
      administrativeAreaCtrl.text = placemark.administrativeArea ?? '';
      countryCtrl.text = placemark.country ?? '';
      isoCountryCodeCtrl.text = placemark.isoCountryCode ?? '';
    }

    _safeNotify();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            placemark != null
                ? 'Endereço preenchido com sucesso.'
                : 'Coordenadas obtidas, mas endereço não encontrado.',
          ),
          backgroundColor: placemark != null ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  // ========= CONFIRMAÇÃO =========
  Future<bool> confirm(BuildContext context, String msg) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmação'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    ) ??
        false;
  }

  // ========= DASHBOARD: handlers de seleção =========
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
      await _sliceAndCalcPagination(resetToFirstPage: true, allowReset: true);
      await _refreshMapWith(_view);
      await _recalcChartsAndSummary();
      _safeNotify();
    } else {
      selectedIndexType =
          labelsType.indexWhere((t) => t.toUpperCase() == selectedAccidentType?.toUpperCase());
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
      _selectedRegionUpper..clear()..add(regionName.toUpperCase());
    }

    if (applyFilter) {
      _applyLocalFilters();
      await _sliceAndCalcPagination(resetToFirstPage: true, allowReset: true);
      await _refreshMapWith(_view);
      await _recalcChartsAndSummary();
      _safeNotify();
    } else {
      selectedIndexRegion =
          labelsRegiao.indexWhere((r) => r.toUpperCase() == selectedRegionName?.toUpperCase());
      _safeNotify();
    }
  }

  void onStatusSelected(String? status) {
    final same = status != null && (selectedStatus?.toUpperCase() == status.toUpperCase());
    selectedStatus = (status == null || same) ? null : status;
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

    // limpa filtro de data também (todos os anos/meses)
    yearFilter = null;
    monthFilter = null;

    _byYearMonth = await _accidentsBloc.getAllAccidents();
    _applyLocalFilters();
    await _sliceAndCalcPagination(resetToFirstPage: true, allowReset: true);
    await _refreshMapWith(_view);
    await _recalcChartsAndSummary();
    _safeNotify();
  }

  // ========= DASHBOARD: cálculos =========
  Future<void> _recalcChartsAndSummary() async {
    await _recalcularGraficos();
    _recalcularResumo();
    valorTotal = _all.length.toDouble();     // total histórico
    totalByType = _view.length.toDouble();   // total após filtros
  }

  Future<void> _recalcularGraficos() async {
    _totaisPorCidade = await _accidentsBloc.getValoresPorCidade(_view);
    _totaisPorTipo   = await _accidentsBloc.getTotaisPorTipoAcidente(_view);
    _mortesPorCidade = await _accidentsBloc.getMortesPorCidade(_view);

    labelsRegiao = _totaisPorCidade.entries.where((e) => e.value > 0).map((e) => e.key).toList();
    valuesRegiao = _totaisPorCidade.entries.where((e) => e.value > 0).map((e) => e.value).toList();

    labelsType = _totaisPorTipo.entries.where((e) => e.value > 0).map((e) => e.key).toList();
    valuesType = _totaisPorTipo.entries.where((e) => e.value > 0).map((e) => e.value).toList();

    selectedIndexRegion =
        labelsRegiao.indexWhere((r) => r.toUpperCase() == selectedRegionName?.toUpperCase());
    selectedIndexType =
        labelsType.indexWhere((t) => t.toUpperCase() == selectedAccidentType?.toUpperCase());
  }

  void _recalcularResumo() {
    for (final k in totalsByAccidentType.keys) {
      totalsByAccidentType[k] = 0.0;
    }
    for (final a in _view) {
      final tipo = (a.typeOfAccident ?? '').toUpperCase().trim();
      if (tipo.isEmpty) continue;

      final key = AccidentsData.getTitleByAccidentType(tipo).toUpperCase() == 'OUTROS'
          ? 'OUTROS'
          : tipo;

      if (totalsByAccidentType.containsKey(key)) {
        totalsByAccidentType[key] = (totalsByAccidentType[key] ?? 0) + 1.0;
      } else {
        totalsByAccidentType['OUTROS'] = (totalsByAccidentType['OUTROS'] ?? 0) + 1.0;
      }
    }
  }

  // ========= MAPA: cores & dados =========
  String normalizeString(String? nome) {
    if (nome == null) return '';
    final noAccent = removeDiacritics(nome);
    final noMultipleSpace = noAccent.replaceAll(RegExp(r'\s+'), ' ');
    return noMultipleSpace.trim().toUpperCase();
  }

  Future<void> _loadLimitsCitiesOfAlagoas() async {
    final geoJsonData = await GeoJsonService.loadServicePolygonsOfCitiesAL(
      assetPath: 'assets/geojson/limits/limites_cidades_al.geojson',
    );
    regionalPolygons..clear()..addAll(geoJsonData);
  }

  Future<void> _refreshMapWith(List<AccidentsData> data) async {
    cityOfAccident.clear();
    for (final acc in data) {
      final city = normalizeString(acc.city);
      if (city.isEmpty) continue;
      cityOfAccident[city] = (cityOfAccident[city] ?? 0) + 1;
    }
  }

  Map<String, Color> get regionColorsForMap => _colorsForAllCities(_view);

  Map<String, Color> _colorsOnlyForFilteredCities(List<AccidentsData> filtered) {
    final count = <String, int>{};
    for (final a in filtered) {
      final city = normalizeString(a.city);
      if (city.isEmpty) continue;
      count[city] = (count[city] ?? 0) + 1;
    }
    if (count.isEmpty) return <String, Color>{};

    final maxRaw = count.values.reduce(math.max);
    double normMax = useLogScale ? math.log(maxRaw + 1) : maxRaw.toDouble();
    if (normMax <= 0) normMax = 1;

    final colors = <String, Color>{};
    for (final e in count.entries) {
      final vNorm = useLogScale ? math.log(e.value + 1) : e.value.toDouble();
      final factor = (vNorm / normMax).clamp(0.0, 1.0);
      colors[e.key] = _interpolateHeatColor(factor);
    }
    return colors;
  }

  Map<String, Color> _colorsForAllCities(List<AccidentsData> filtered) {
    final colors = Map<String, Color>.from(_colorsOnlyForFilteredCities(filtered));
    final zeroColor = zeroValueColor;

    if (regionalPolygons.isEmpty || zeroColor == null) return colors;
    for (final poly in regionalPolygons) {
      final key = normalizeString(poly.regionName);
      colors.putIfAbsent(key, () => zeroColor); // zero → verde
    }
    return colors;
  }

  Color _interpolateHeatColor(double factor) {
    if (_heatmapPalette.length == 1) return _heatmapPalette.first;
    final n = _heatmapPalette.length;
    final scaled = factor * (n - 1);
    final i = scaled.floor().clamp(0, n - 2);
    final t = scaled - i;
    return Color.lerp(_heatmapPalette[i], _heatmapPalette[i + 1], t)!;
  }

  void setHeatmapPalette(List<Color> palette, {bool notify = true}) {
    if (palette.length < 2) throw ArgumentError('A paleta deve ter pelo menos 2 cores.');
    _heatmapPalette = List<Color>.from(palette);
    if (notify) _safeNotify();
  }

  Future<List<AccidentsData>> fetchCityAccidents(String city) {
    return _accidentsBloc.getAccidentsByCityList(
      cityName: city,
      year: yearFilter,
      month: monthFilter,
    );
  }

  // ========= FILTRO LOCAL (tipo/região/status) =========
  void _applyLocalFilters() {
    final base = _byYearMonth;
    final result = base.where((d) {
      final cityUpper = (d.city ?? '').toUpperCase();
      final typeUpper = (d.typeOfAccident ?? '').toUpperCase();

      final matchRegion = _selectedRegionUpper.isEmpty
          ? true
          : _selectedRegionUpper.any((r) => cityUpper.contains(r));

      final matchType = _typeSelectedUpper == null ? true : typeUpper == _typeSelectedUpper;

      final matchStatus = true; // placeholder para status (se aplicar depois)

      return matchRegion && matchType && matchStatus;
    }).toList();

    _view = result;
  }

  // ========= INFRA =========
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
}
