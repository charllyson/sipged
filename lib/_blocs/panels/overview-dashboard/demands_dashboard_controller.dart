// lib/_blocs/panels/overview-dashboard/demands_dashboard_controller.dart
import 'package:flutter/material.dart';

import 'package:siged/_blocs/_process/process_store.dart';
import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_blocs/panels/overview-dashboard/demands_dashboard_overview_style.dart';
import 'package:siged/_blocs/process/hiring/0Stages/hiring_data.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';
import 'package:siged/_services/geoJson/geo_json_manager.dart';

import 'package:siged/_widgets/charts/radar/radar_series_data.dart';
import 'package:siged/_widgets/charts/treemap/treemap_chart_changed.dart';

// Measurements & derivados
import 'package:siged/_blocs/process/report/report_measurement_data.dart';
import 'package:siged/_blocs/process/report/report_measurement_store.dart';
import 'package:siged/_blocs/process/adjustment/adjustment_measurement_store.dart';
import 'package:siged/_blocs/process/revision/revision_measurement_store.dart';

// Aditivos/Apostilas p/ somatórios
import 'package:siged/_blocs/process/additives/additive_store.dart';
import 'package:siged/_blocs/process/apostilles/apostilles_store.dart';

// ==== NOVOS imports: usamos os BLoCs tipados ====
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_bloc.dart';
import 'package:siged/_blocs/process/hiring/5Edital/edital_bloc.dart';
import 'package:siged/_blocs/process/hiring/5Edital/edital_data.dart';

class DemandsDashboardController extends ChangeNotifier {
  DemandsDashboardController({
    required this.store,
    required this.reportsMeasurementStore,
    required this.adjustmentsStore,
    required this.revisionsStore,
    required this.additivesStore,
    required this.apostillesStore,
    required this.dfdBloc,
    required this.editalBloc,
    GeoJsonManager? geoManager,
  }) : geoManager = geoManager ?? GeoJsonManager();

  // Injeções
  final ProcessStore store;
  final ReportsMeasurementStore reportsMeasurementStore;
  final AdjustmentsMeasurementStore adjustmentsStore;
  final RevisionsMeasurementStore revisionsStore;
  final AdditivesStore additivesStore;
  final ApostillesStore apostillesStore;
  final GeoJsonManager geoManager;

  // NOVOS: blocos tipados em vez de repositórios
  final DfdBloc dfdBloc;
  final EditalBloc editalBloc;

  bool initialized = false;
  bool _disposed = false;
  int _applyRunId = 0;

  // Base
  List<ProcessData> allContracts = [];
  List<ProcessData> filteredContracts = [];
  List<ReportMeasurementData> allMeasurements = [];
  List<String> uniqueCompanies = [];

  // Filtros e seleção
  List<String> selectedRegions = [];
  String? selectedRegion;
  int? selectedRegionIndex;

  String? selectedCompany;
  int? selectedCompanyIndex;

  String? selectedStatus;

  // Data para seção de medições
  int? selectedYear = DateTime.now().year;
  int? selectedMonth;

  // Totais por dimensão
  Map<String, double> totaisStatusIniciais = {};
  Map<String, double> totaisStatusAditivos = {};
  Map<String, double> totaisStatusApostilas = {};

  Map<String, double> totaisRegiaoIniciais = {};
  Map<String, double> totaisRegiaoAditivos = {};
  Map<String, double> totaisRegiaoApostilas = {};

  Map<String, double> totaisEmpresaIniciais = {};
  Map<String, double> totaisEmpresaAditivos = {};
  Map<String, double> totaisEmpresaApostilas = {};

  double? _totalMedicoes;
  double? _totalReajustes;
  double? _totalRevisoes;
  String tipoDeValorSelecionado = 'Somatório total';

  // Getters públicos usados nos cards
  double? get totaisMedicoes => _totalMedicoes;
  double? get totaisReajustes => _totalReajustes;
  double? get totaisRevisoes => _totalRevisoes;

  // ===== caches do DFD =====
  final Map<String, String> _roadNameByContract = {};
  final Map<String, String> _regionByContract = {};
  final Map<String, String> _statusByContract = {};
  final Map<String, String> _naturezaByContract = {}; // naturezaIntervencao

  // ===== cache do EDITAL (vencedor) =====
  final Map<String, String> _winnerByContract = {};

  /// Pré-carrega rótulos do DFD + vencedor do edital usando os BLoCs tipados.
  Future<void> _preloadDfdLabels(Iterable<ProcessData> base) async {
    final futures = <Future<void>>[];

    for (final c in base) {
      final id = _idToString(c.id);
      if (id == null) continue;

      final precisaRodovia = !_roadNameByContract.containsKey(id);
      final precisaRegiao = !_regionByContract.containsKey(id);
      final precisaStatus = !_statusByContract.containsKey(id);
      final precisaNatureza = !_naturezaByContract.containsKey(id);
      final precisaVencedor = !_winnerByContract.containsKey(id);

      // Se nada precisa, pula
      if (!precisaRodovia &&
          !precisaRegiao &&
          !precisaStatus &&
          !precisaNatureza &&
          !precisaVencedor) {
        continue;
      }

      futures.add(() async {
        // ------ DFD ------
        if (precisaRodovia || precisaRegiao || precisaStatus || precisaNatureza) {
          final DfdData? dfd = await dfdBloc.getDataForContract(id);

          if (dfd != null) {
            if (precisaRodovia) {
              final road = dfd.rodovia?.trim();
              if (road != null && road.isNotEmpty) {
                _roadNameByContract[id] = road;
              }
            }

            if (precisaRegiao) {
              final reg = dfd.regional?.trim();
              if (reg != null && reg.isNotEmpty) {
                _regionByContract[id] = reg;
              }
            }

            if (precisaStatus) {
              final s = dfd.statusDemanda?.trim();
              if (s != null && s.isNotEmpty) {
                _statusByContract[id] = s;
              }
            }

            if (precisaNatureza) {
              final nat = dfd.naturezaIntervencao?.trim();
              if (nat != null && nat.isNotEmpty) {
                _naturezaByContract[id] = nat;
              }
            }
          }
        }

        // ------ EDITAL (vencedor) ------
        if (precisaVencedor) {
          final EditalData? edital = await editalBloc.getDataForContract(id);
          final w = edital?.vencedor?.trim();
          if (w != null && w.isNotEmpty) {
            _winnerByContract[id] = w;
          }
        }
      }());
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  String _getRoadLabel(ProcessData c) {
    final id = _idToString(c.id);
    final cached = (id != null) ? _roadNameByContract[id] : null;
    if (cached != null && cached.trim().isNotEmpty) return cached.trim();
    return 'SEM RODOVIA';
  }

  String _getRegionLabel(ProcessData c) {
    final id = _idToString(c.id);
    final cached = (id != null) ? _regionByContract[id] : null;
    return (cached != null && cached.trim().isNotEmpty)
        ? cached.trim()
        : 'SEM REGIÃO';
  }

  String _getStatusLabel(ProcessData c) {
    final id = _idToString(c.id);
    final cached = (id != null) ? _statusByContract[id] : null;
    final v = (cached ?? '').trim();
    if (v.isNotEmpty) return v;
    return 'SEM STATUS';
  }

  /// Natureza da intervenção vinda do DFD (localizacao.naturezaIntervencao)
  String _getNatureLabel(ProcessData c) {
    final id = _idToString(c.id);
    final cached = (id != null) ? _naturezaByContract[id] : null;
    final v = (cached ?? '').trim();
    if (v.isNotEmpty) return v;
    return 'SEM NATUREZA';
  }

  /// Vencedor do edital
  String _getWinnerLabel(ProcessData c) {
    final id = _idToString(c.id);
    final cached = (id != null) ? _winnerByContract[id] : null;
    final v = (cached ?? '').trim();
    if (v.isNotEmpty) return v;
    return 'SEM VENCEDOR';
  }

  // ===== Ciclo de vida / init =====
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed && hasListeners) notifyListeners();
  }

  Future<void> initialize() async {
    geoManager.loadLimitsRegionalsPolygonDERAL();

    allContracts = store.all;
    if (allContracts.isEmpty && !store.loading) {
      allContracts = store.all;
    }

    // Pré-carrega rodovia, regional, status, natureza (DFD) e vencedor (edital)
    await _preloadDfdLabels(allContracts);
    if (_disposed) return;

    await reportsMeasurementStore.ensureAllLoaded();
    await adjustmentsStore.ensureAllLoaded();
    await revisionsStore.ensureAllLoaded();
    if (_disposed) return;

    allMeasurements = reportsMeasurementStore.all;

    filteredContracts = allContracts;
    uniqueCompanies = _extractCompanies(allContracts);

    await aplicarFiltrosERecalcular();

    if (_disposed) return;
    initialized = true;
    _safeNotify();
  }

  Future<void> refreshAndRecalc() async {
    final runId = ++_applyRunId;
    allContracts = store.all;
    allMeasurements = reportsMeasurementStore.all;
    filteredContracts = allContracts;
    if (_disposed || runId != _applyRunId) return;
    await aplicarFiltrosERecalcular();
  }

  Future<void> onHotReload() => refreshAndRecalc();

  bool get houveInteracaoComFiltros =>
      selectedStatus != null ||
          selectedCompany != null ||
          selectedRegions.isNotEmpty;

  // ===== Handlers de seleção =====
  Future<void> onStatusSelected(String? status) async {
    final sel = status?.trim();
    final same =
        (selectedStatus ?? '').toUpperCase() == (sel ?? '').toUpperCase();

    if (sel == null || same) {
      _limparTudo();
    } else {
      selectedStatus = sel;
      selectedCompany = null;
      selectedCompanyIndex = null;
      selectedRegion = null;
      selectedRegionIndex = null;

      // regiões relacionadas aos contratos que possuem esse STATUS (via DFD)
      selectedRegions = store.all
          .where(
            (c) => _getStatusLabel(c).toUpperCase() == sel.toUpperCase(),
      )
          .map((c) => _getRegionLabel(c).toUpperCase())
          .where((r) => r.isNotEmpty && r != 'SEM REGIÃO')
          .toSet()
          .toList();
    }
    await aplicarFiltrosERecalcular();
  }

  Future<void> onCompanySelected(String company) async {
    final isSame =
        (selectedCompany ?? '').toUpperCase() == company.toUpperCase();
    if (isSame) {
      selectedCompany = null;
      selectedCompanyIndex = null;
      selectedRegions = [];
    } else {
      selectedCompany = company;
      selectedCompanyIndex = uniqueCompanies
          .indexWhere((e) => e.toUpperCase() == company.toUpperCase());

      final contratosEmpresa = store.all.where(
            (c) => _getWinnerLabel(c).toUpperCase() == company.toUpperCase(),
      );

      selectedRegions = contratosEmpresa
          .map((c) => _getRegionLabel(c).toUpperCase())
          .where((r) => r.isNotEmpty && r != 'SEM REGIÃO')
          .toSet()
          .toList();
    }
    await aplicarFiltrosERecalcular();
  }

  Future<void> onRegionSelected(String? region) async {
    final same =
        region != null && selectedRegions.contains(region.toUpperCase());
    if (region == null || same) {
      selectedRegion = null;
      selectedRegions = [];
      selectedRegionIndex = null;
    } else {
      selectedRegion = region;
      selectedRegions = [region.toUpperCase()];
      selectedRegionIndex = HiringData.regions
          .indexWhere((r) => r.toUpperCase() == region.toUpperCase());
    }
    await aplicarFiltrosERecalcular();
  }

  Future<void> limparSelecoes() async {
    _limparTudo();
    await aplicarFiltrosERecalcular();
  }

  void _limparTudo() {
    selectedStatus = null;
    selectedCompany = null;
    selectedCompanyIndex = null;
    selectedRegion = null;
    selectedRegionIndex = null;
    selectedRegions = [];
  }

  void onTipoDeValorSelecionado(String novoTipo) {
    tipoDeValorSelecionado = novoTipo;
    _safeNotify();
  }

  // ===== Filtros =====
  void filterContracts() {
    allContracts = store.all;
    final base = allContracts;

    filteredContracts = base.where((c) {
      final region = _getRegionLabel(c).toUpperCase();
      final company = _getWinnerLabel(c).toUpperCase();
      final statusDfd = _getStatusLabel(c).toUpperCase();

      final matchCompany =
          selectedCompany == null ||
              company == (selectedCompany!.toUpperCase());
      final matchRegion = selectedRegions.isEmpty ||
          selectedRegions.any((r) => region.contains(r));
      final matchStatus =
          selectedStatus == null ||
              statusDfd == (selectedStatus!.toUpperCase());

      return matchCompany && matchRegion && matchStatus;
    }).toList();
  }

  List<String> _extractCompanies(List<ProcessData> data) {
    final set = <String>{
      for (final c in data) _getWinnerLabel(c).trim().toUpperCase(),
    };
    final list = set.toList()..sort();
    return list;
  }

  String? _idToString(Object? id) {
    if (id == null) return null;
    try {
      final dynamic dyn = id;
      final hasId = (() {
        try {
          return (dyn as dynamic).uid is String;
        } catch (_) {
          return false;
        }
      })();
      if (hasId) return (dyn as dynamic).uid as String;
    } catch (_) {}
    return id.toString();
  }

  String? _parseContractIdFromPath(String? p) {
    if (p == null || p.isEmpty) return null;
    final m = RegExp(r'/contracts/([^/]+)').firstMatch(p);
    return m != null ? m.group(1) : null;
  }

  String? _dynString(dynamic v) {
    try {
      if (v == null) return null;
      if (v is String && v.trim().isNotEmpty) return v.trim();
      final id = (v as dynamic).uid;
      if (id is String && id.trim().isNotEmpty) return id.trim();
    } catch (_) {}
    return null;
  }

  String? _extractContractId(dynamic entry) {
    try {
      final direct = _dynString((entry as dynamic).contractId) ??
          _dynString((entry as dynamic).idContract) ??
          _dynString((entry as dynamic).contractRef);
      if (direct != null) return direct;

      final path = (entry as dynamic).path ??
          (entry as dynamic).docPath ??
          (entry as dynamic).parentPath ??
          (entry as dynamic).fullPath ??
          (entry as dynamic).storagePath ??
          (entry as dynamic).measurementPath;

      final fromPath = _parseContractIdFromPath(path?.toString());
      if (fromPath != null) return fromPath;

      final idMaybePath = (entry as dynamic).uid?.toString();
      final fromId = _parseContractIdFromPath(idMaybePath);
      if (fromId != null) return fromId;
    } catch (_) {}
    return null;
  }

  // ===== Cálculos =====
  Future<void> _calcularTotaisIniciais() async {
    totaisStatusIniciais.clear();
    totaisEmpresaIniciais.clear();
    totaisRegiaoIniciais.clear();

    for (final c in filteredContracts) {
      final status = _getStatusLabel(c);
      final empresa = _getWinnerLabel(c);
      final regiao = _getRegionLabel(c);
      final valor = c.initialValueContract ?? 0.0;

      totaisStatusIniciais[status] =
          (totaisStatusIniciais[status] ?? 0.0) + valor;
      totaisEmpresaIniciais[empresa] =
          (totaisEmpresaIniciais[empresa] ?? 0.0) + valor;
      totaisRegiaoIniciais[regiao] =
          (totaisRegiaoIniciais[regiao] ?? 0.0) + valor;
    }
  }

  Future<void> _calcularTotaisAditivos() async {
    final contratosIds = <String>{
      for (final c in filteredContracts)
        if (_idToString(c.id) != null) _idToString(c.id)!,
    };
    final aditivos = await additivesStore.getForContractIds(contratosIds);
    if (_disposed) return;

    totaisStatusAditivos.clear();
    totaisEmpresaAditivos.clear();
    totaisRegiaoAditivos.clear();

    final byId = <String, ProcessData>{
      for (final c in filteredContracts)
        if (_idToString(c.id) != null) _idToString(c.id)!: c,
    };

    for (final ad in aditivos) {
      final adId = _idToString(ad.contractId);
      final c = adId == null ? null : byId[adId];
      if (c == null) continue;

      final status = _getStatusLabel(c);
      final empresa = _getWinnerLabel(c);
      final regiao = _getRegionLabel(c);
      final valor = ad.additiveValue ?? 0.0;

      totaisStatusAditivos[status] =
          (totaisStatusAditivos[status] ?? 0.0) + valor;
      totaisEmpresaAditivos[empresa] =
          (totaisEmpresaAditivos[empresa] ?? 0.0) + valor;
      totaisRegiaoAditivos[regiao] =
          (totaisRegiaoAditivos[regiao] ?? 0.0) + valor;
    }
  }

  Future<void> _calcularTotaisApostilas() async {
    final contratosIds = <String>{
      for (final c in filteredContracts)
        if (_idToString(c.id) != null) _idToString(c.id)!,
    };
    final aps = await apostillesStore.getForContractIds(contratosIds);
    if (_disposed) return;

    totaisStatusApostilas.clear();
    totaisEmpresaApostilas.clear();
    totaisRegiaoApostilas.clear();

    final byId = <String, ProcessData>{
      for (final c in filteredContracts)
        if (_idToString(c.id) != null) _idToString(c.id)!: c,
    };

    for (final ap in aps) {
      final apId = _idToString(ap.contractId);
      final c = apId == null ? null : byId[apId];
      if (c == null) continue;

      final status = _getStatusLabel(c);
      final empresa = _getWinnerLabel(c);
      final regiao = _getRegionLabel(c);
      final valor = ap.apostilleValue ?? 0.0;

      totaisStatusApostilas[status] =
          (totaisStatusApostilas[status] ?? 0.0) + valor;
      totaisEmpresaApostilas[empresa] =
          (totaisEmpresaApostilas[empresa] ?? 0.0) + valor;
      totaisRegiaoApostilas[regiao] =
          (totaisRegiaoApostilas[regiao] ?? 0.0) + valor;
    }
  }

  Future<void> _calcularTotaisMedicoes() async {
    final idsFiltro = <String>{
      for (final c in filteredContracts)
        if (_idToString(c.id) != null) _idToString(c.id)!,
    };
    allMeasurements = reportsMeasurementStore.all;

    final filtradas = allMeasurements.where((m) {
      final cid = _extractContractId(m);
      return cid != null && idsFiltro.contains(cid);
    }).toList();

    _totalMedicoes = reportsMeasurementStore.sumMedicoes(filtradas);
  }

  Future<void> _calcularTotaisReajustes() async {
    final idsFiltro = <String>{
      for (final c in filteredContracts)
        if (_idToString(c.id) != null) _idToString(c.id)!,
    };
    final entries = adjustmentsStore.all.where((e) {
      final cid = _extractContractId(e);
      return cid != null && idsFiltro.contains(cid);
    }).toList();
    _totalReajustes = adjustmentsStore.sumAdjustments(entries);
  }

  Future<void> _calcularTotaisRevisoes() async {
    final idsFiltro = <String>{
      for (final c in filteredContracts)
        if (_idToString(c.id) != null) _idToString(c.id)!,
    };
    final entries = revisionsStore.all.where((e) {
      final cid = _extractContractId(e);
      return cid != null && idsFiltro.contains(cid);
    }).toList();
    _totalRevisoes = revisionsStore.sumRevisions(entries);
  }

  Future<void> aplicarFiltrosERecalcular() async {
    final runId = ++_applyRunId;

    allContracts = store.all;
    allMeasurements = reportsMeasurementStore.all;

    filterContracts();

    // garante cache DFD + vencedor para os contratos filtrados
    await _preloadDfdLabels(filteredContracts);
    if (_disposed || runId != _applyRunId) return;

    await _calcularTotaisIniciais();
    if (_disposed || runId != _applyRunId) return;
    await _calcularTotaisAditivos();
    if (_disposed || runId != _applyRunId) return;
    await _calcularTotaisApostilas();
    if (_disposed || runId != _applyRunId) return;
    await _calcularTotaisMedicoes();
    if (_disposed || runId != _applyRunId) return;
    await _calcularTotaisReajustes();
    if (_disposed || runId != _applyRunId) return;
    await _calcularTotaisRevisoes();
    if (_disposed || runId != _applyRunId) return;

    uniqueCompanies = _extractCompanies(allContracts);
    _safeNotify();
  }

  // ===== Mapas finalizados para os gráficos =====
  Map<String, double> _somarMapas(List<Map<String, double>> maps) {
    final out = <String, double>{};
    for (final m in maps) {
      for (final e in m.entries) {
        out[e.key] = (out[e.key] ?? 0.0) + e.value;
      }
    }
    return out;
  }

  Map<String, double> get totaisStatusAtuais {
    switch (tipoDeValorSelecionado) {
      case 'Valor contratado':
        return totaisStatusIniciais;
      case 'Total em aditivos':
        return totaisStatusAditivos;
      case 'Total em apostilas':
        return totaisStatusApostilas;
      case 'Somatório total':
      default:
        return _somarMapas(
          [totaisStatusIniciais, totaisStatusAditivos, totaisStatusApostilas],
        );
    }
  }

  Map<String, double> get totaisRegiaoAtuais {
    switch (tipoDeValorSelecionado) {
      case 'Valor contratado':
        return totaisRegiaoIniciais;
      case 'Total em aditivos':
        return totaisRegiaoAditivos;
      case 'Total em apostilas':
        return totaisRegiaoApostilas;
      case 'Somatório total':
      default:
        return _somarMapas(
          [totaisRegiaoIniciais, totaisRegiaoAditivos, totaisRegiaoApostilas],
        );
    }
  }

  List<String> get labelsStatusGeneralContracts {
    final entries = totaisStatusAtuais.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => e.key).toList();
  }

  List<double> get valuesStatusGeneralContracts {
    final entries = totaisStatusAtuais.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => e.value).toList();
  }

  List<String> get labelsRegionOfMap => HiringData.regions;

  List<double?> get valuesRegionOfMap =>
      HiringData.regions.map((r) => totaisRegiaoAtuais[r]).toList();

  List<Color> get barColorsRegion {
    return List.generate(HiringData.regions.length, (i) {
      final valor = valuesRegionOfMap[i] ?? 0.0;
      if (valor == 0.0) return Colors.grey.shade300;
      if (selectedRegionIndex != null && selectedRegionIndex == i) {
        return Colors.orangeAccent;
      }
      return Colors.blueAccent;
    });
  }

  Map<String, double> get totaisEmpresaAtuais {
    switch (tipoDeValorSelecionado) {
      case 'Valor contratado':
        return totaisEmpresaIniciais;
      case 'Total em aditivos':
        return totaisEmpresaAditivos;
      case 'Total em apostilas':
        return totaisEmpresaApostilas;
      case 'Somatório total':
      default:
        return _somarMapas(
          [totaisEmpresaIniciais, totaisEmpresaAditivos, totaisEmpresaApostilas],
        );
    }
  }

  List<String> get labelsCompany => uniqueCompanies;

  List<double> get valuesCompany =>
      uniqueCompanies.map((e) => totaisEmpresaAtuais[e] ?? 0.0).toList();

  List<Color> get barColorsEmpresa {
    return List.generate(uniqueCompanies.length, (i) {
      final valor = valuesCompany[i];
      if (valor == 0.0) return Colors.grey.shade300;
      if (selectedCompanyIndex != null && selectedCompanyIndex == i) {
        return Colors.orangeAccent;
      }
      return Colors.blueAccent;
    });
  }

  // ===== Radar por "Natureza da intervenção" (DFD) =====
  List<String> get radarServiceLabels {
    final set = <String>{};
    for (final c in allContracts) {
      final s = _getNatureLabel(c);
      if (s != 'SEM NATUREZA') set.add(s);
    }
    final ordered = set.toList()..sort();
    return ordered;
  }

  double _valorRadarParaContrato(ProcessData c) {
    switch (tipoDeValorSelecionado) {
      case 'Valor contratado':
        return c.initialValueContract ?? 0.0;
      case 'Total em aditivos':
        return 0.0; // se quiser somar aditivos depois, dá pra integrar
      case 'Total em apostilas':
        return 0.0;
      case 'Somatório total':
      default:
        return (c.initialValueContract ?? 0.0);
    }
  }

  List<double> _sumRadarPorNatureza(
      List<ProcessData> base,
      List<String> labels,
      ) {
    final mapa = {for (final t in labels) t: 0.0};
    for (final c in base) {
      final valor = _valorRadarParaContrato(c);
      if (valor == 0) continue;
      final natureza = _getNatureLabel(c);
      if (natureza == 'SEM NATUREZA') continue;
      if (mapa.containsKey(natureza)) {
        mapa[natureza] = (mapa[natureza] ?? 0.0) + valor;
      }
    }
    return labels.map((t) => mapa[t] ?? 0.0).toList();
  }

  List<double> radarServiceValuesGeral() {
    final labels = radarServiceLabels;
    return _sumRadarPorNatureza(filteredContracts, labels);
  }

  List<double> radarServiceValuesEmpresaSelecionada() {
    if (selectedCompany == null) return const [];
    final labels = radarServiceLabels;
    final alvo = (selectedCompany ?? '').toUpperCase();
    final base = filteredContracts
        .where(
          (c) => _getWinnerLabel(c).toUpperCase() == alvo,
    )
        .toList();
    return _sumRadarPorNatureza(base, labels);
  }

  List<double> radarServiceValuesRegiaoSelecionada() {
    if (selectedRegion == null && selectedRegions.isEmpty) return const [];
    final labels = radarServiceLabels;
    final alvo = (selectedRegion ?? selectedRegions.first).toUpperCase();
    final base = filteredContracts
        .where((c) => _getRegionLabel(c).toUpperCase().contains(alvo))
        .toList();
    return _sumRadarPorNatureza(base, labels);
  }

  List<RadarSeriesData> radarDatasetsServices({
    required Color primary,
    required Color warning,
    required Color success,
  }) {
    final labels = radarServiceLabels;
    if (labels.isEmpty) return const <RadarSeriesData>[];

    final geral = radarServiceValuesGeral();
    final empresa = radarServiceValuesEmpresaSelecionada();
    final regiao = radarServiceValuesRegiaoSelecionada();

    final raw = <RadarSeriesData>[
      RadarSeriesData(name: 'Geral', values: geral, color: primary),
      if (empresa.isNotEmpty)
        RadarSeriesData(
          name: selectedCompany ?? 'Empresa',
          values: empresa,
          color: warning,
        ),
      if (regiao.isNotEmpty)
        RadarSeriesData(
          name: selectedRegion ??
              (selectedRegions.isNotEmpty ? selectedRegions.first : 'Região'),
          values: regiao,
          color: success,
        ),
    ];

    return raw
        .where(
          (s) =>
      s.values.length == labels.length &&
          s.values.any((v) => v > 0),
    )
        .toList(growable: false);
  }

  // ===== Treemap de rodovias =====
  List<TreemapItem> get treemapRodovias {
    final mapa = <String, double>{};
    for (final c in filteredContracts) {
      final rodovia = _getRoadLabel(c);
      if (rodovia.isEmpty || rodovia == 'SEM RODOVIA') continue;

      double valor;
      switch (tipoDeValorSelecionado) {
        case 'Valor contratado':
          valor = c.initialValueContract ?? 0.0;
          break;
        case 'Total em aditivos':
          valor = 0.0;
          break;
        case 'Total em apostilas':
          valor = 0.0;
          break;
        case 'Somatório total':
        default:
          valor = (c.initialValueContract ?? 0.0);
          break;
      }
      if (valor == 0.0) continue;
      mapa[rodovia] = (mapa[rodovia] ?? 0.0) + valor;
    }

    final ordenado = mapa.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    int i = 0;
    return ordenado.map((e) {
      final color = DemandsDashboardOverviewStyle
          .tradeMapColors[i % DemandsDashboardOverviewStyle.tradeMapColors.length];
      i++;
      return TreemapItem(label: e.key, value: e.value, color: color);
    }).toList(growable: false);
  }
}
