import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

// ===== Measurements (separados) =====
import 'package:siged/_blocs/documents/measurement/report/report_measurement_data.dart';
import 'package:siged/_blocs/documents/measurement/report/report_measurement_store.dart';
import 'package:siged/_blocs/documents/measurement/revision/revision_measurement_store.dart';
import 'package:siged/_blocs/documents/measurement/adjustment/adjustment_measurement_store.dart';

// ===== Contracts / Additives / Apostilles =====
import 'package:siged/_blocs/documents/contracts/additives/additives_bloc.dart';
import 'package:siged/_blocs/documents/contracts/apostilles/apostilles_bloc.dart';
import 'package:siged/_blocs/documents/contracts/additives/additive_store.dart';
import 'package:siged/_blocs/documents/contracts/apostilles/apostilles_store.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_rules.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_store.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_storage_bloc.dart';

// ===== Map/Charts =====
import 'package:siged/_blocs/widgets/map/geo_json_manager.dart';
import 'package:siged/_widgets/charts/radar/radar_series_data.dart';
import 'package:siged/_widgets/charts/treemap/treemap_chart_changed.dart';

class ContractsController extends ChangeNotifier {
  ContractsController({
    // --------- Dependências obrigatórias
    required this.store,
    required this.additivesStore,
    required this.apostillesStore,
    required this.reportsMeasurementStore,
    required this.adjustmentsStore,
    required this.revisionsStore,
    required this.contractStorageBloc,

    // --------- Opcionais
    AdditivesBloc? additivesBloc,
    ApostillesBloc? apostillesBloc,
    GeoJsonManager? geoManager,

    // --------- Form/ACL
    this.moduleKey = 'contracts',
    this.forceEditable = false,
  })  : additivesBloc = additivesBloc ?? AdditivesBloc(),
        apostillesBloc = apostillesBloc ?? ApostillesBloc(),
        geoManager = geoManager ?? GeoJsonManager();

  // =======================================================================
  // INJEÇÕES
  // =======================================================================
  final ContractsStore store;
  final AdditivesStore additivesStore;
  final ApostillesStore apostillesStore;

  /// Stores separados
  final ReportsMeasurementStore reportsMeasurementStore;
  final AdjustmentsMeasurementStore adjustmentsStore;
  final RevisionsMeasurementStore revisionsStore;

  final AdditivesBloc additivesBloc;
  final ApostillesBloc apostillesBloc;
  final GeoJsonManager geoManager;

  /// Upload/Storage de PDF do contrato
  final ContractStorageBloc contractStorageBloc;

  /// Apenas para cenários com ACL por módulo (mantido para compat)
  final String moduleKey;
  final bool forceEditable;

  // =======================================================================
  // ESTADO DASHBOARD / AGREGAÇÕES (como no controller antigo)
  // =======================================================================
  List<ContractData> allContracts = [];
  List<ContractData> filteredContracts = [];

  // Lista de medições (REPORT); para Adjustment/Revision usamos as stores específicas.
  List<ReportMeasurementData> allMeasurements = [];

  List<String> uniqueCompanies = []; // <- sempre baseada em allContracts
  List<String> selectedRegions = [];

  String? selectedRegion;
  String? selectedCompany;
  String? selectedStatus;
  int? selectedRegionIndex;
  int? selectedCompanyIndex;

  bool initialized = false;
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

  // Totais de medições/reajustes/revisões para cards
  double? _totalMedicoes;
  double? _totalReajustes;
  double? _totalRevisoes;

  double? get totaisMedicoes => _totalMedicoes;
  double? get totaisReajustes => _totalReajustes;
  double? get totaisRevisoes => _totalRevisoes;

  String tipoDeValorSelecionado = 'Somatório total';

  // ---- Segurança de ciclo de vida / concorrência
  bool _disposed = false;
  int _applyRunId = 0;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  // =======================================================================
  // ESTADO DO FORMULÁRIO (antes no MainInformationController)
  // =======================================================================
  // UI/validação
  final formKey = GlobalKey<FormState>();
  bool showErrors = false;
  bool isSaving = false;

  bool get isEditable => forceEditable; // ajuste aqui se tiver ACL dinâmica

  bool get isBtnEnabled {
    return !isSaving &&
        (contractStatusCtrl.text.trim().isNotEmpty) &&
        (contractBiddingProcessNumberCtrl.text.trim().isNotEmpty) &&
        (contractNumberCtrl.text.trim().isNotEmpty) &&
        (initialValueOfContractCtrl.text.trim().isNotEmpty) &&
        (summarySubjectContractCtrl.text.trim().isNotEmpty) &&
        (contractRegionOfStateCtrl.text.trim().isNotEmpty) &&
        (contractTextKmCtrl.text.trim().isNotEmpty) &&
        (initialValidityContractDaysCtrl.text.trim().isNotEmpty) &&
        (initialValidityExecutionDaysCtrl.text.trim().isNotEmpty) &&
        (contractWorkTypeCtrl.text.trim().isNotEmpty);
  }

  // Modelo editado atualmente pela tela de informações gerais
  late ContractData contractData;

  // ===== Controllers de texto (empresa)
  final TextEditingController contractCompanyLeaderCtrl = TextEditingController();
  final TextEditingController contractCompaniesInvolvedCtrl = TextEditingController();
  final TextEditingController cnoNumberCtrl = TextEditingController();
  final TextEditingController cnpjNumberCtrl = TextEditingController(); // (se usar)
  final TextEditingController generalNumberCtrl = TextEditingController(); // (se usar)

  // ===== Controllers de texto (gerais do contrato)
  final TextEditingController contractStatusCtrl = TextEditingController();
  final TextEditingController contractBiddingProcessNumberCtrl = TextEditingController();
  final TextEditingController contractNumberCtrl = TextEditingController();
  final TextEditingController initialValueOfContractCtrl = TextEditingController();
  final TextEditingController contractHighWayCtrl = TextEditingController();
  final TextEditingController summarySubjectContractCtrl = TextEditingController();
  final TextEditingController contractRegionOfStateCtrl = TextEditingController();
  final TextEditingController contractTextKmCtrl = TextEditingController();
  final TextEditingController contractTypeCtrl = TextEditingController();      // texto livre
  final TextEditingController contractWorkTypeCtrl = TextEditingController();  // dropdown (Tipo de obra)
  final TextEditingController contractServiceTypeCtrl = TextEditingController();
  final TextEditingController datapublicacaodoeCtrl = TextEditingController();
  final TextEditingController initialValidityContractDaysCtrl = TextEditingController();
  final TextEditingController initialValidityExecutionDaysCtrl = TextEditingController();

  // ===== Descrição
  final TextEditingController contractObjectDescriptionCtrl = TextEditingController();

  // ===== Gestor
  final TextEditingController regionalManagerCtrl = TextEditingController();
  final TextEditingController managerIdCtrl = TextEditingController();
  final TextEditingController managerPhoneNumberCtrl = TextEditingController();
  final TextEditingController cpfContractManagerCtrl = TextEditingController();
  final TextEditingController contractManagerArtNumberCtrl = TextEditingController();

  // =======================================================================
  // CICLO DE VIDA
  // =======================================================================
  @override
  void dispose() {
    _disposed = true;

    // Dispose dos controllers de formulário
    contractCompanyLeaderCtrl.dispose();
    contractCompaniesInvolvedCtrl.dispose();
    cnoNumberCtrl.dispose();
    cnpjNumberCtrl.dispose();
    generalNumberCtrl.dispose();

    contractStatusCtrl.dispose();
    contractBiddingProcessNumberCtrl.dispose();
    contractNumberCtrl.dispose();
    initialValueOfContractCtrl.dispose();
    contractHighWayCtrl.dispose();
    summarySubjectContractCtrl.dispose();
    contractRegionOfStateCtrl.dispose();
    contractTextKmCtrl.dispose();
    contractTypeCtrl.dispose();
    contractWorkTypeCtrl.dispose();
    contractServiceTypeCtrl.dispose();
    datapublicacaodoeCtrl.dispose();
    initialValidityContractDaysCtrl.dispose();
    initialValidityExecutionDaysCtrl.dispose();

    contractObjectDescriptionCtrl.dispose();

    regionalManagerCtrl.dispose();
    managerIdCtrl.dispose();
    managerPhoneNumberCtrl.dispose();
    cpfContractManagerCtrl.dispose();
    contractManagerArtNumberCtrl.dispose();

    super.dispose();
  }

  /// Inicialização para a **dashboard** (mantida).
  Future<void> initialize() async {
    // Carrega limites regionais (mapa)
    geoManager.loadLimitsRegionalsDERAL();

    // Contratos
    allContracts = store.all;
    if (allContracts.isEmpty && !store.loading) {
      await store.refresh();
      if (_disposed) return;
      allContracts = store.all;
    }

    // Medições (carrega as três stores)
    await reportsMeasurementStore.ensureAllLoaded();
    await adjustmentsStore.ensureAllLoaded();
    await revisionsStore.ensureAllLoaded();
    if (_disposed) return;

    allMeasurements = reportsMeasurementStore.all;

    // Estado inicial
    filteredContracts = allContracts;

    // Sempre todas as empresas
    uniqueCompanies = _extractCompanies(allContracts);

    await aplicarFiltrosERecalcular();

    if (_disposed) return;
    initialized = true;
    _safeNotify();
  }

  /// Inicialização para a **tela de informações gerais** (substitui o antigo MainInformationController.init).
  Future<void> init(BuildContext context, {ContractData? initial}) async {
    contractData = _clone(initial ?? ContractData.empty());
    _fillControllersFromModel();
    notifyListeners();
  }

  // =======================================================================
  // AÇÕES GERAIS / RELOAD
  // =======================================================================
  Future<void> refreshAndRecalc() async {
    final runId = ++_applyRunId;
    allContracts = store.all;
    allMeasurements = reportsMeasurementStore.all;
    filteredContracts = allContracts;

    if (_disposed || runId != _applyRunId) return;
    await aplicarFiltrosERecalcular();
  }

  Future<void> onHotReload() => refreshAndRecalc();

  // =======================================================================
  // SELETORES / INTERAÇÕES (dashboard)
  // =======================================================================
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

      // Pré-seleciona regiões com contratos nesse status
      selectedRegions = store.all
          .where((c) => (c.contractStatus ?? '').toUpperCase() == status?.toUpperCase())
          .map((c) => (c.regionOfState ?? '').trim().toUpperCase())
          .where((r) => r.isNotEmpty)
          .toSet()
          .toList();
    }
    await aplicarFiltrosERecalcular();
  }

  Future<void> onCompanySelected(String company) async {
    final isSame = selectedCompany?.toUpperCase() == company.toUpperCase();

    if (isSame) {
      selectedCompany = null;
      selectedCompanyIndex = null;
      selectedRegions = [];
    } else {
      selectedCompany = company;
      selectedCompanyIndex =
          uniqueCompanies.indexWhere((e) => e.toUpperCase() == company.toUpperCase());

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
      selectedRegionIndex =
          ContractRules.regions.indexWhere((r) => r.toUpperCase() == region.toUpperCase());
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

  // =======================================================================
  // FILTRAGEM (dashboard)
  // =======================================================================
  void filterContracts() {
    allContracts = store.all;

    final base = allContracts;

    filteredContracts = base.where((c) {
      final region = (c.regionOfState ?? '').toUpperCase();
      final company = (c.companyLeader ?? '').toUpperCase();
      final status = (c.contractStatus ?? '').toUpperCase();

      final matchCompany =
          selectedCompany == null || company == selectedCompany!.toUpperCase();
      final matchRegion =
          selectedRegions.isEmpty || selectedRegions.any((r) => region.contains(r));
      final matchStatus =
          selectedStatus == null || status == selectedStatus!.toUpperCase();
      return matchCompany && matchRegion && matchStatus;
    }).toList();
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
    uniqueCompanies = _extractCompanies(allContracts);
  }

  // =======================================================================
  // HELPERS DE ID
  // =======================================================================
  String? _idToString(Object? id) {
    if (id == null) return null;
    try {
      final dynamic dyn = id;
      final hasId = (() {
        try {
          return (dyn as dynamic).id is String;
        } catch (_) {
          return false;
        }
      })();
      if (hasId) return (dyn as dynamic).id as String;
    } catch (_) {}
    return id.toString();
  }

  // =======================================================================
  // RECÁLCULOS (dashboard)
  // =======================================================================
  Future<void> _calcularTotaisIniciais() async {
    totaisStatusIniciais.clear();
    totaisEmpresaIniciais.clear();
    totaisRegiaoIniciais.clear();

    for (final contrato in filteredContracts) {
      final status = contrato.contractStatus ?? 'SEM STATUS';
      final empresa = contrato.companyLeader ?? 'SEM EMPRESA';
      final regiao = contrato.regionOfState ?? 'SEM REGIÃO';
      final valor = contrato.initialValueContract ?? 0.0;

      totaisStatusIniciais[status] = (totaisStatusIniciais[status] ?? 0.0) + valor;
      totaisEmpresaIniciais[empresa] = (totaisEmpresaIniciais[empresa] ?? 0.0) + valor;
      totaisRegiaoIniciais[regiao] = (totaisRegiaoIniciais[regiao] ?? 0.0) + valor;
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

    final byId = <String, ContractData>{
      for (final c in filteredContracts)
        if (_idToString(c.id) != null) _idToString(c.id)!: c,
    };

    for (final ad in aditivos) {
      final adId = _idToString(ad.contractId);
      final contrato = adId == null ? null : byId[adId];
      if (contrato == null) continue;

      final status = contrato.contractStatus ?? 'SEM STATUS';
      final empresa = contrato.companyLeader ?? 'SEM EMPRESA';
      final regiao = contrato.regionOfState ?? 'SEM REGIÃO';
      final valor = ad.additiveValue ?? 0.0;

      totaisStatusAditivos[status] = (totaisStatusAditivos[status] ?? 0.0) + valor;
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

    final apostilas = await apostillesStore.getForContractIds(contratosIds);
    if (_disposed) return;

    totaisStatusApostilas.clear();
    totaisEmpresaApostilas.clear();
    totaisRegiaoApostilas.clear();

    final byId = <String, ContractData>{
      for (final c in filteredContracts)
        if (_idToString(c.id) != null) _idToString(c.id)!: c,
    };

    for (final ap in apostilas) {
      final apId = _idToString(ap.contractId);
      final contrato = apId == null ? null : byId[apId];
      if (contrato == null) continue;

      final status = contrato.contractStatus ?? 'SEM STATUS';
      final empresa = contrato.companyLeader ?? 'SEM EMPRESA';
      final regiao = contrato.regionOfState ?? 'SEM REGIÃO';
      final valor = ap.apostilleValue ?? 0.0;

      totaisStatusApostilas[status] = (totaisStatusApostilas[status] ?? 0.0) + valor;
      totaisEmpresaApostilas[empresa] =
          (totaisEmpresaApostilas[empresa] ?? 0.0) + valor;
      totaisRegiaoApostilas[regiao] =
          (totaisRegiaoApostilas[regiao] ?? 0.0) + valor;
    }
  }

  Future<void> _calcularTotaisMedicoes() async {
    allMeasurements = reportsMeasurementStore.all;
    _totalMedicoes = reportsMeasurementStore.sumMedicoes(allMeasurements);
  }

  Future<void> _calcularTotaisReajustes() async {
    final entries = adjustmentsStore.all;
    _totalReajustes = adjustmentsStore.sumAdjustments(entries);
  }

  Future<void> _calcularTotaisRevisoes() async {
    final entries = revisionsStore.all;
    _totalRevisoes = revisionsStore.sumRevisions(entries);
  }

  Future<void> aplicarFiltrosERecalcular() async {
    final runId = ++_applyRunId;

    allContracts = store.all;
    allMeasurements = reportsMeasurementStore.all;

    filterContracts();

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

    _atualizarEmpresasComBaseNosContratos();

    _safeNotify();
  }

  void onTipoDeValorSelecionado(String novoTipo) {
    tipoDeValorSelecionado = novoTipo;
    _safeNotify();
  }

  // =======================================================================
  // COMBINAÇÕES/GRÁFICOS (dashboard)
  // =======================================================================
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
    final entries = totaisStatusAtuais.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => e.key).toList();
  }

  List<double> get valuesStatusOrdenados {
    final entries = totaisStatusAtuais.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => e.value).toList();
  }

  // Regiões
  List<String> get labelsRegiao => ContractRules.regions;
  List<double?> get valuesRegiao =>
      ContractRules.regions.map((r) => totaisRegiaoAtuais[r]).toList();

  List<Color> get barColorsRegiao {
    return List.generate(ContractRules.regions.length, (i) {
      final valor = valuesRegiao[i] ?? 0.0;
      if (valor == 0.0) return Colors.grey.shade300;
      if (selectedRegionIndex != null && selectedRegionIndex == i) {
        return Colors.orangeAccent;
      }
      return Colors.blueAccent;
    });
  }

  // Empresas
  List<String> get labelsEmpresa => uniqueCompanies;
  List<double> get valuesEmpresa =>
      uniqueCompanies.map((e) => totaisEmpresaAtuais[e] ?? 0.0).toList();

  List<Color> get barColorsEmpresa {
    return List.generate(uniqueCompanies.length, (i) {
      final valor = valuesEmpresa[i];
      if (valor == 0.0) return Colors.grey.shade300;
      if (selectedCompanyIndex != null && selectedCompanyIndex == i) {
        return Colors.orangeAccent;
      }
      return Colors.blueAccent;
    });
  }

  // ================== Radar (services) ==================
  List<String> get radarServiceLabels {
    final set = <String>{};
    for (final c in allContracts) {
      final s = (c.contractServices ?? '').trim();
      if (s.isNotEmpty) set.add(s);
    }
    final ordered = set.toList()..sort();
    return ordered;
  }

  double _valorRadarParaContrato(ContractData c) {
    switch (tipoDeValorSelecionado) {
      case 'Valor contratado':
        return c.initialValueContract ?? 0.0;
      case 'Total em aditivos':
        return 0.0;
      case 'Total em apostilas':
        return 0.0;
      case 'Somatório total':
      default:
        return (c.initialValueContract ?? 0.0);
    }
  }

  List<double> _sumRadarPorContractServices(
      List<ContractData> base, List<String> labels) {
    final mapa = {for (final t in labels) t: 0.0};

    for (final c in base) {
      final valor = _valorRadarParaContrato(c);
      if (valor == 0) continue;

      final service = (c.contractServices ?? '').trim();
      if (service.isEmpty) continue;

      if (mapa.containsKey(service)) {
        mapa[service] = (mapa[service] ?? 0.0) + valor;
      }
    }
    return labels.map((t) => mapa[t] ?? 0.0).toList();
  }

  List<double> radarServiceValuesGeral() {
    final labels = radarServiceLabels;
    return _sumRadarPorContractServices(filteredContracts, labels);
  }

  List<double> radarServiceValuesEmpresaSelecionada() {
    if (selectedCompany == null) return const [];
    final labels = radarServiceLabels;
    final alvo = (selectedCompany ?? '').toUpperCase();

    final base = filteredContracts
        .where((c) => (c.companyLeader ?? '').toUpperCase() == alvo)
        .toList();

    return _sumRadarPorContractServices(base, labels);
  }

  List<double> radarServiceValuesRegiaoSelecionada() {
    if (selectedRegion == null && selectedRegions.isEmpty) return const [];
    final labels = radarServiceLabels;
    final alvo = (selectedRegion ?? selectedRegions.first).toUpperCase();

    final base = filteredContracts
        .where((c) => (c.regionOfState ?? '').toUpperCase().contains(alvo))
        .toList();

    return _sumRadarPorContractServices(base, labels);
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

    final List<RadarSeriesData> raw = [
      RadarSeriesData(
        name: 'Geral',
        values: geral,
        color: primary,
      ),
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
        .where((s) => s.values.length == labels.length && s.values.any((v) => v > 0))
        .toList(growable: false);
  }

  // ================== TREEMAP POR RODOVIA ==================
  List<TreemapItem> get treemapRodovias {
    final mapa = <String, double>{};

    for (final contrato in filteredContracts) {
      final rodovia = (contrato.mainContractHighway ?? 'SEM RODOVIA').trim();
      if (rodovia.isEmpty) continue;

      double valor;
      switch (tipoDeValorSelecionado) {
        case 'Valor contratado':
          valor = contrato.initialValueContract ?? 0.0;
          break;
        case 'Total em aditivos':
          valor = 0.0;
          break;
        case 'Total em apostilas':
          valor = 0.0;
          break;
        case 'Somatório total':
        default:
          valor = (contrato.initialValueContract ?? 0.0);
          break;
      }

      if (valor == 0.0) continue;
      mapa[rodovia] = (mapa[rodovia] ?? 0.0) + valor;
    }

    final ordenado = mapa.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = <Color>[
      Colors.blue, Colors.green, Colors.orange, Colors.purple,
      Colors.red, Colors.teal, Colors.indigo, Colors.brown,
      Colors.cyan, Colors.deepOrange, Colors.pink, Colors.lime,
    ];

    int i = 0;
    return ordenado.map((e) {
      final color = colors[i % colors.length];
      i++;
      return TreemapItem(
        label: e.key,
        value: e.value,
        color: color,
      );
    }).toList(growable: false);
  }

  // =======================================================================
  // ------ BLOCO DE FORM (Salvar/Atualizar + PDF) -------------------------
  // =======================================================================

  /// Salva/Atualiza as informações do contrato atual em [contractData],
  /// preenchendo a partir dos controllers de texto.
  Future<void> saveInformation(
      BuildContext context, {
        void Function(ContractData)? onSaved,
      }) async {
    showErrors = true;
    notifyListeners();

    if (!(formKey.currentState?.validate() ?? false)) return;

    // a) controllers -> modelo
    _applyControllersToModel();

    // b) status de salvamento
    isSaving = true;
    notifyListeners();

    try {
      // c) salva via store
      final saved = await store.saveOrUpdate(contractData);

      // d) atualiza instância local
      contractData = _clone(saved);

      // e) callback
      onSaved?.call(contractData);
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// Após upload, salva a URL do PDF no Firestore e atualiza a instância local.
  Future<void> salvarUrlPdfDoContratoEAtualizarUI(
      BuildContext context, {
        required String contractId,
        required String url,
        void Function(ContractData)? onSaved,
      }) async {
    await store.salvarUrlPdfDoContrato(contractId, url);

    final updated = await store.getById(contractId);
    if (updated != null) {
      contractData = _clone(updated);
      onSaved?.call(contractData);
      notifyListeners();
    }
  }

  // =======================================================================
  // ------ HELPERS DO FORM -------------------------------------------------
  // =======================================================================

  ContractData _clone(ContractData src) {
    return ContractData(
      id: src.id,
      managerId: src.managerId,
      summarySubjectContract: src.summarySubjectContract,
      contractNumber: src.contractNumber,
      mainContractHighway: src.mainContractHighway,
      restriction: src.restriction,
      contractServices: src.contractServices,
      contractManagerArtNumber: src.contractManagerArtNumber,
      contractExtKm: src.contractExtKm,
      regionOfState: src.regionOfState,
      managerPhoneNumber: src.managerPhoneNumber,
      companyLeader: src.companyLeader,
      generalNumber: src.generalNumber,
      contractNumberProcess: src.contractNumberProcess,
      automaticNumberSiafe: src.automaticNumberSiafe,
      physicalPercentage: src.physicalPercentage,
      regionalManager: src.regionalManager,
      contractStatus: src.contractStatus,
      contractObjectDescription: src.contractObjectDescription,
      contractType: src.contractType,
      workType: src.workType,
      contractCompaniesInvolved: src.contractCompaniesInvolved,
      urlContractPdf: src.urlContractPdf,
      initialValidityExecutionDays: src.initialValidityExecutionDays,
      initialValidityContractDays: src.initialValidityContractDays,
      cpfContractManager: src.cpfContractManager,
      cnoNumber: src.cnoNumber,
      cnpjNumber: src.cnpjNumber,
      existContract: src.existContract,
      publicationDateDoe: src.publicationDateDoe,
      financialPercentage: src.financialPercentage,
      initialValueContract: src.initialValueContract,
      permissionContractId: Map<String, Map<String, bool>>.fromEntries(
        src.permissionContractId.entries.map(
              (e) => MapEntry(e.key, Map<String, bool>.from(e.value)),
        ),
      ),
    );
  }

  void _fillControllersFromModel() {
    // Empresa
    contractCompanyLeaderCtrl.text = (contractData.companyLeader ?? '');
    contractCompaniesInvolvedCtrl.text = (contractData.contractCompaniesInvolved ?? '');
    cnoNumberCtrl.text = (contractData.cnoNumber ?? '');
    cnpjNumberCtrl.text = (contractData.cnpjNumber?.toString() ?? '');
    generalNumberCtrl.text = (contractData.generalNumber ?? '');

    // Gerais
    contractStatusCtrl.text = (contractData.contractStatus ?? '');
    contractBiddingProcessNumberCtrl.text = (contractData.contractNumberProcess ?? '');
    contractNumberCtrl.text = (contractData.contractNumber ?? '');
    initialValueOfContractCtrl.text = _formatCurrency(contractData.initialValueContract);
    contractHighWayCtrl.text = (contractData.mainContractHighway ?? '');
    summarySubjectContractCtrl.text = (contractData.summarySubjectContract ?? '');
    contractRegionOfStateCtrl.text = (contractData.regionOfState ?? '');
    contractTextKmCtrl.text = _formatNumber(contractData.contractExtKm, decimals: 3);
    contractTypeCtrl.text = (contractData.contractType ?? '');
    contractWorkTypeCtrl.text = (contractData.workType ?? '');
    contractServiceTypeCtrl.text = (contractData.contractServices ?? '');
    datapublicacaodoeCtrl.text = contractData.publicationDateDoe != null
        ? contractData.publicationDateDoe!.toIso8601String()
        : '';
    initialValidityContractDaysCtrl.text =
    (contractData.initialValidityContractDays?.toString() ?? '');
    initialValidityExecutionDaysCtrl.text =
    (contractData.initialValidityExecutionDays?.toString() ?? '');

    // Descrição
    contractObjectDescriptionCtrl.text = (contractData.contractObjectDescription ?? '');

    // Gestor
    regionalManagerCtrl.text = (contractData.regionalManager ?? '');
    managerIdCtrl.text = (contractData.managerId ?? '');
    managerPhoneNumberCtrl.text = (contractData.managerPhoneNumber ?? '');
    cpfContractManagerCtrl.text = (contractData.cpfContractManager?.toString() ?? '');
    contractManagerArtNumberCtrl.text = (contractData.contractManagerArtNumber ?? '');
  }

  void _applyControllersToModel() {
    // Empresa
    contractData.companyLeader = _nullIfEmpty(contractCompanyLeaderCtrl.text);
    contractData.contractCompaniesInvolved = _nullIfEmpty(contractCompaniesInvolvedCtrl.text);
    contractData.cnoNumber = _nullIfEmpty(cnoNumberCtrl.text);
    contractData.cnpjNumber = _tryParseInt(cnpjNumberCtrl.text);
    contractData.generalNumber = _nullIfEmpty(generalNumberCtrl.text);

    // Gerais
    contractData.contractStatus =
        _normalizeFromList(contractStatusCtrl.text, ContractRules.statusTypes);
    contractData.contractNumberProcess = _nullIfEmpty(contractBiddingProcessNumberCtrl.text);
    contractData.contractNumber = _nullIfEmpty(contractNumberCtrl.text);
    contractData.initialValueContract = _parseCurrency(initialValueOfContractCtrl.text);
    contractData.mainContractHighway = _nullIfEmpty(contractHighWayCtrl.text);
    contractData.summarySubjectContract = _nullIfEmpty(summarySubjectContractCtrl.text);
    contractData.regionOfState = _nullIfEmpty(contractRegionOfStateCtrl.text);
    contractData.contractExtKm = _tryParseDouble(contractTextKmCtrl.text);
    contractData.contractType = _nullIfEmpty(contractTypeCtrl.text);
    contractData.workType =
        _normalizeFromList(contractWorkTypeCtrl.text, ContractRules.workTypes);
    contractData.contractServices = _nullIfEmpty(contractServiceTypeCtrl.text);

    // A data já é setada pela UI via onChanged do CustomDateField; se quiser, parse daqui:
    // contractData.publicationDateDoe = _tryParseIso(datapublicacaodoeCtrl.text);

    contractData.initialValidityContractDays =
        _tryParseInt(initialValidityContractDaysCtrl.text);
    contractData.initialValidityExecutionDays =
        _tryParseInt(initialValidityExecutionDaysCtrl.text);

    // Descrição
    contractData.contractObjectDescription = _nullIfEmpty(contractObjectDescriptionCtrl.text);

    // Gestor
    contractData.regionalManager = _nullIfEmpty(regionalManagerCtrl.text);
    contractData.managerId = _nullIfEmpty(managerIdCtrl.text);
    contractData.managerPhoneNumber = _nullIfEmpty(managerPhoneNumberCtrl.text);
    contractData.cpfContractManager = _tryParseInt(cpfContractManagerCtrl.text);
    contractData.contractManagerArtNumber = _nullIfEmpty(contractManagerArtNumberCtrl.text);
  }

  // =======================================================================
  // ------ Utils de formatação/parse (reaproveitados) ----------------------
  // =======================================================================

  String _nullIfEmpty(String? v) {
    final s = (v ?? '').trim();
    return s.isEmpty ? '' : s;
  }

  String _formatCurrency(double? value) {
    if (value == null) return '';
    return 'R\$ ${_formatNumber(value, decimals: 2, decimalComma: true, thousandsDot: true)}';
    // Observação: a máscara visual do campo cuida do layout final.
  }

  String _formatNumber(num? value,
      {int decimals = 0, bool decimalComma = false, bool thousandsDot = false}) {
    if (value == null) return '';
    String s = value.toStringAsFixed(decimals);
    if (decimalComma) {
      s = s.replaceAll('.', ',');
    }
    if (thousandsDot) {
      final parts = s.split(decimalComma ? ',' : '.');
      String intPart = parts[0];
      String fracPart = parts.length > 1 ? parts[1] : '';
      final buf = StringBuffer();
      for (int i = 0; i < intPart.length; i++) {
        final remain = intPart.length - i - 1;
        buf.write(intPart[i]);
        if (remain > 0 && (remain % 3 == 0)) buf.write('.');
      }
      s = buf.toString();
      if (decimals > 0) {
        s = '$s${decimalComma ? ',' : '.'}$fracPart';
      }
    }
    return s;
  }

  double? _parseCurrency(String? text) {
    if (text == null) return null;
    var s = text.trim();
    if (s.isEmpty) return null;
    s = s
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(s);
  }

  double? _tryParseDouble(String? text) {
    if (text == null) return null;
    final s = text.trim().replaceAll(',', '.');
    return double.tryParse(s);
  }

  int? _tryParseInt(String? text) {
    if (text == null) return null;
    final s = text.trim().replaceAll(RegExp(r'[^0-9-]'), '');
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }

  DateTime? _tryParseIso(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    try {
      return DateTime.parse(text.trim());
    } catch (_) {
      return null;
    }
  }

  /// Normaliza um valor contra uma lista (case-insensitive). Retorna exatamente
  /// como está na lista, se encontrar; caso contrário, mantém o digitado.
  String? _normalizeFromList(String? value, List<String> candidates) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    final found = candidates.firstWhereOrNull(
          (c) => c.toUpperCase() == v.toUpperCase(),
    );
    return found ?? v;
  }
}
