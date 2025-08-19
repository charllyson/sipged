import 'package:flutter/material.dart';
import 'package:sisged/_datas/documents/measurement/reports/report_measurement_data.dart';
import 'package:sisged/_datas/documents/measurement/reports/report_measurement_store.dart';

import '../../../../_blocs/documents/contracts/additives/additives_bloc.dart';
import '../../../../_blocs/documents/contracts/apostilles/apostilles_bloc.dart';
import '../../../../_datas/documents/contracts/additive/additive_store.dart';
import '../../../../_datas/documents/contracts/apostilles/apostilles_store.dart';
import '../../../../_datas/documents/contracts/contracts/contract_rules.dart';
import '../../../../_datas/documents/contracts/contracts/contract_store.dart';
import '../../../../_datas/documents/contracts/contracts/contract_data.dart';
import '../../../../_services/geo_json_manager.dart';

class DashboardController extends ChangeNotifier {
  DashboardController({
    required this.store,               // ContractsStore
    required this.additivesStore,     // AdditivesStore
    required this.apostillesStore,    // ApostillesStore
    required this.reportsMeasurementStore,       // ⭐ ReportsStore
    AdditivesBloc? additivesBloc,
    ApostillesBloc? apostillesBloc,
    GeoJsonManager? geoManager,
  })  : additivesBloc = additivesBloc ?? AdditivesBloc(),
        apostillesBloc = apostillesBloc ?? ApostillesBloc(),
        geoManager = geoManager ?? GeoJsonManager();

  // --------- Dependências
  final ContractsStore store;
  final AdditivesStore additivesStore;
  final ApostillesStore apostillesStore;
  final ReportsMeasurementStore reportsMeasurementStore;      // ⭐ agora usamos o store de medições

  // (opcional) ainda úteis para ações diretas (upload/delete PDF, etc.)
  final AdditivesBloc additivesBloc;
  final ApostillesBloc apostillesBloc;

  final GeoJsonManager geoManager;

  // --------- Estado
  List<ContractData> allContracts = [];
  List<ContractData> filteredContracts = [];

  List<ReportMeasurementData> allMeasurements = [];
  late Future<List<ReportMeasurementData>> measurementsFuture = Future.value([]);

  List<String> uniqueCompanies = [];
  List<String> selectedRegions = [];

  String? selectedRegion;
  String? selectedCompany;
  String? selectedStatus;
  int? selectedRegionIndex;
  int? selectedCompanyIndex;

  bool initialized = false;
  int? selectedYear = DateTime.now().year;
  int? selectedMonth;

  // Mapas centralizados
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

  double? get totaisMedicoes  => _totalMedicoes;
  double? get totaisReajustes => _totalReajustes;
  double? get totaisRevisoes  => _totalRevisoes;

  String tipoDeValorSelecionado = 'Somatório total';

  // --------- Ciclo de vida
  Future<void> initialize() async {
    geoManager.loadLimitsRegionalsDERAL();

    // Contratos a partir do store (com fallback de refresh)
    allContracts = store.all;
    if (allContracts.isEmpty && !store.loading) {
      await store.refresh();
      allContracts = store.all;
    }

    // Medições via ReportsStore (carrega uma vez o collectionGroup)
    await reportsMeasurementStore.ensureAllLoaded();
    allMeasurements = reportsMeasurementStore.all;
    measurementsFuture = Future.value(allMeasurements);

    filteredContracts = allContracts;
    uniqueCompanies = _extractCompanies(filteredContracts);

    await aplicarFiltrosERecalcular();

    initialized = true;
    notifyListeners();
  }

  // --------- Seletores / Interações
  bool get houveInteracaoComFiltros =>
      selectedStatus != null || selectedCompany != null || selectedRegions.isNotEmpty;

  Future<void> onStatusSelected(String? status) async {
    if (selectedStatus?.toUpperCase() == status?.toUpperCase()) {
      _limparTudo();
    } else {
      selectedStatus = status;
      selectedCompany = null;
      selectedCompanyIndex = null;
      selectedRegion = null;
      selectedRegionIndex = null;

      selectedRegions = store.all
          .where((c) => (c.contractStatus ?? '').toUpperCase() == status?.toUpperCase())
          .map((c) => (c.regionOfState ?? '').trim().toUpperCase())
          .where((r) => r.isNotEmpty)
          .toSet()
          .toList();
    }
    await aplicarFiltrosERecalcular();
    notifyListeners();
  }

  Future<void> onCompanySelected(String company) async {
    final isSame = selectedCompany?.toUpperCase() == company.toUpperCase();

    if (isSame) {
      selectedCompany = null;
      selectedCompanyIndex = null;
      selectedRegions = [];
    } else {
      selectedCompany = company;
      selectedCompanyIndex = uniqueCompanies.indexWhere(
            (e) => e.toUpperCase() == company.toUpperCase(),
      );

      final contratosEmpresa = store.all.where(
            (c) => (c.companyLeader ?? '').toUpperCase() == company.toUpperCase(),
      );

      selectedRegions = contratosEmpresa
          .map((c) => (c.regionOfState ?? '').trim().toUpperCase())
          .where((r) => r.isNotEmpty)
          .toSet()
          .toList();
    }

    await aplicarFiltrosERecalcular();
    notifyListeners();
  }

  Future<void> onRegionSelected(String? region) async {
    final same = region != null && selectedRegions.contains(region.toUpperCase());

    if (region == null || same) {
      selectedRegion = null;
      selectedRegions = [];
      selectedRegionIndex = null;
    } else {
      selectedRegion = region;
      selectedRegions = [region.toUpperCase()];
      selectedRegionIndex = ContractRules.regions
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

  // --------- Filtragem
  void filterContracts() {
    final base = store.all;

    filteredContracts = base.where((c) {
      final region  = (c.regionOfState ?? '').toUpperCase();
      final company = (c.companyLeader  ?? '').toUpperCase();
      final status  = (c.contractStatus ?? '').toUpperCase();

      final matchCompany = selectedCompany == null || company == selectedCompany!.toUpperCase();
      final matchRegion  = selectedRegions.isEmpty || selectedRegions.any((r) => region.contains(r));
      final matchStatus  = selectedStatus == null || status == selectedStatus!.toUpperCase();
      return matchCompany && matchRegion && matchStatus;
    }).toList();

    notifyListeners();
  }

  List<String> _extractCompanies(List<ContractData> data) {
    final set = <String>{};
    for (final c in data) {
      final name = (c.companyLeader ?? 'NÃO INFORMADO').trim().toUpperCase();
      set.add(name);
    }
    final list = set.toList()..sort();
    return list;
  }

  void _atualizarEmpresasComBaseNosContratos() {
    uniqueCompanies = _extractCompanies(filteredContracts);
  }

  // --------- Recalcular totais
  Future<void> aplicarFiltrosERecalcular() async {
    filterContracts();

    await _calcularTotaisIniciais();
    await _calcularTotaisAditivos();    // via AdditivesStore
    await _calcularTotaisApostilas();   // via ApostillesStore

    await _calcularTotaisMedicoes();    // via ReportsStore
    await _calcularTotaisReajustes();   // via ReportsStore
    await _calcularTotaisRevisoes();    // via ReportsStore

    _atualizarEmpresasComBaseNosContratos();
  }

  void onTipoDeValorSelecionado(String novoTipo) {
    tipoDeValorSelecionado = novoTipo;
    notifyListeners();
  }

  Future<void> _calcularTotaisIniciais() async {
    totaisStatusIniciais.clear();
    totaisEmpresaIniciais.clear();
    totaisRegiaoIniciais.clear();

    for (final contrato in filteredContracts) {
      final status = contrato.contractStatus ?? 'SEM STATUS';
      final empresa = contrato.companyLeader ?? 'SEM EMPRESA';
      final regiao = contrato.regionOfState ?? 'SEM REGIÃO';
      final valor  = contrato.initialValueContract ?? 0.0;

      totaisStatusIniciais[status]   = (totaisStatusIniciais[status]   ?? 0.0) + valor;
      totaisEmpresaIniciais[empresa] = (totaisEmpresaIniciais[empresa] ?? 0.0) + valor;
      totaisRegiaoIniciais[regiao]   = (totaisRegiaoIniciais[regiao]   ?? 0.0) + valor;
    }
  }

  Future<void> _calcularTotaisAditivos() async {
    final contratosIds = filteredContracts.map((c) => c.id).whereType<String>().toSet();
    final aditivos = await additivesStore.getForContractIds(contratosIds);

    totaisStatusAditivos.clear();
    totaisEmpresaAditivos.clear();
    totaisRegiaoAditivos.clear();

    final byId = { for (final c in filteredContracts.where((c) => c.id != null)) c.id!: c };

    for (final ad in aditivos) {
      final contrato = byId[ad.contractId];
      if (contrato == null) continue;

      final status = contrato.contractStatus ?? 'SEM STATUS';
      final empresa = contrato.companyLeader ?? 'SEM EMPRESA';
      final regiao = contrato.regionOfState ?? 'SEM REGIÃO';
      final valor  = ad.additiveValue ?? 0.0;

      totaisStatusAditivos[status]   = (totaisStatusAditivos[status]   ?? 0.0) + valor;
      totaisEmpresaAditivos[empresa] = (totaisEmpresaAditivos[empresa] ?? 0.0) + valor;
      totaisRegiaoAditivos[regiao]   = (totaisRegiaoAditivos[regiao]   ?? 0.0) + valor;
    }
  }

  Future<void> _calcularTotaisApostilas() async {
    final contratosIds = filteredContracts.map((c) => c.id).whereType<String>().toSet();
    final apostilas = await apostillesStore.getForContractIds(contratosIds);

    totaisStatusApostilas.clear();
    totaisEmpresaApostilas.clear();
    totaisRegiaoApostilas.clear();

    final byId = { for (final c in filteredContracts.where((c) => c.id != null)) c.id!: c };

    for (final ap in apostilas) {
      final contrato = byId[ap.contractId];
      if (contrato == null) continue;

      final status = contrato.contractStatus ?? 'SEM STATUS';
      final empresa = contrato.companyLeader ?? 'SEM EMPRESA';
      final regiao = contrato.regionOfState ?? 'SEM REGIÃO';
      final valor  = ap.apostilleValue ?? 0.0;

      totaisStatusApostilas[status]   = (totaisStatusApostilas[status]   ?? 0.0) + valor;
      totaisEmpresaApostilas[empresa] = (totaisEmpresaApostilas[empresa] ?? 0.0) + valor;
      totaisRegiaoApostilas[regiao]   = (totaisRegiaoApostilas[regiao]   ?? 0.0) + valor;
    }
  }

  // --------- Métricas de medições (agora via ReportsStore)
  Future<void> _calcularTotaisMedicoes() async {
    final dados = await measurementsFuture;
    _totalMedicoes = reportsMeasurementStore.sumMedicoes(dados);
    notifyListeners();
  }

  Future<void> _calcularTotaisReajustes() async {
    final dados = await measurementsFuture;
    _totalReajustes = reportsMeasurementStore.sumReajustes(dados);
    notifyListeners();
  }

  Future<void> _calcularTotaisRevisoes() async {
    final dados = await measurementsFuture;
    _totalRevisoes = reportsMeasurementStore.sumRevisoes(dados);
    notifyListeners();
  }

  // --------- Combinações p/ gráficos
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
        return _somarMapas([
          totaisStatusIniciais,
          totaisStatusAditivos,
          totaisStatusApostilas,
        ]);
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
        return _somarMapas([
          totaisRegiaoIniciais,
          totaisRegiaoAditivos,
          totaisRegiaoApostilas,
        ]);
    }
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
        return _somarMapas([
          totaisEmpresaIniciais,
          totaisEmpresaAditivos,
          totaisEmpresaApostilas,
        ]);
    }
  }

  Map<String, double> _somarMapas(List<Map<String, double>> mapas) {
    final Map<String, double> resultado = {};
    for (final mapa in mapas) {
      for (final entry in mapa.entries) {
        resultado[entry.key] = (resultado[entry.key] ?? 0.0) + entry.value;
      }
    }
    return resultado;
  }

  List<String> get labelsStatusOrdenados {
    final entries = totaisStatusAtuais.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => e.key).toList();
  }

  List<double> get valuesStatusOrdenados {
    final entries = totaisStatusAtuais.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => e.value).toList();
  }

  List<double?> get valuesRegiao => ContractRules.regions
      .map((r) => totaisRegiaoAtuais[r])
      .toList();

  List<double> get valuesEmpresa => uniqueCompanies
      .map((e) => totaisEmpresaAtuais[e] ?? 0.0)
      .toList();

  List<Color> get barColorsEmpresa => valuesEmpresa
      .map((v) => v == 0.0 ? Colors.grey.shade300 : Colors.blueAccent)
      .toList();
}
