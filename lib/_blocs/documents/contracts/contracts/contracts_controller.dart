import 'package:flutter/material.dart';
import 'package:sisged/_blocs/documents/measurement/report/report_measurement_data.dart';
import 'package:sisged/_blocs/documents/measurement/report/report_measurement_store.dart';

import 'package:sisged/_blocs/documents/contracts/additives/additives_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/apostilles/apostilles_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/additives/additive_store.dart';
import 'package:sisged/_blocs/documents/contracts/apostilles/apostilles_store.dart';
import 'package:sisged/_blocs/documents/contracts/contracts/contract_rules.dart';
import 'package:sisged/_blocs/documents/contracts/contracts/contract_store.dart';
import 'package:sisged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:sisged/_blocs/widgets/map/geo_json_manager.dart';
import 'package:sisged/_widgets/charts/radar/radar_series_data.dart';
import 'package:sisged/_widgets/charts/treemap/treemap_chart_changed.dart';

import '../../../../_widgets/charts/radar/radar_chart_changed_widget.dart';

class ContractsController extends ChangeNotifier {
  ContractsController({
    required this.store,
    required this.additivesStore,
    required this.apostillesStore,
    required this.reportsMeasurementStore,
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
  final ReportsMeasurementStore reportsMeasurementStore;

  final AdditivesBloc additivesBloc;
  final ApostillesBloc apostillesBloc;
  final GeoJsonManager geoManager;

  // --------- Estado
  List<ContractData> allContracts = [];
  List<ContractData> filteredContracts = [];

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

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // --------- Ciclo de vida
  Future<void> initialize() async {
    // Carrega limites regionais (mapa)
    geoManager.loadLimitsRegionalsDERAL();

    // Contratos (usa cache do store; se vazio, busca)
    allContracts = store.all;
    if (allContracts.isEmpty && !store.loading) {
      await store.refresh();
      if (_disposed) return;
      allContracts = store.all;
    }

    // Medições (collectionGroup carregado uma vez)
    await reportsMeasurementStore.ensureAllLoaded();
    if (_disposed) return;
    allMeasurements = reportsMeasurementStore.all;

    // Estado inicial
    filteredContracts = allContracts;

    // 🔧 Sempre todas as empresas (mesmo se filtro reduzir os valores)
    uniqueCompanies = _extractCompanies(allContracts);

    await aplicarFiltrosERecalcular();

    if (_disposed) return;
    initialized = true;
    _safeNotify();
  }

  // ---------- Recarregar “geral” quando quiser forçar atualização de tudo
  Future<void> refreshAndRecalc() async {
    final runId = ++_applyRunId;
    allContracts = store.all;
    allMeasurements = reportsMeasurementStore.all;
    filteredContracts = allContracts;

    if (_disposed || runId != _applyRunId) return;
    await aplicarFiltrosERecalcular();
  }

  /// Útil para ser chamado do widget em `reassemble()` ou após hot-reload.
  Future<void> onHotReload() => refreshAndRecalc();

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

  // --------- Filtragem
  void filterContracts() {
    // 🔄 Sincroniza sempre com o store (importante após reload/refresh)
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
    // ❌ sem notify aqui; notificamos ao final do recálculo
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

  // 🔧 sempre baseada em allContracts (não em filtered)
  void _atualizarEmpresasComBaseNosContratos() {
    uniqueCompanies = _extractCompanies(allContracts);
  }

  // --------- Helpers de ID (corrigem o problema dos aditivos/apostilas)
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

  // --------- Recalcular totais (helpers não notificam)
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
    allMeasurements = reportsMeasurementStore.all;
    _totalReajustes = reportsMeasurementStore.sumReajustes(allMeasurements);
  }

  Future<void> _calcularTotaisRevisoes() async {
    allMeasurements = reportsMeasurementStore.all;
    _totalRevisoes = reportsMeasurementStore.sumRevisoes(allMeasurements);
  }

  // --------- Orquestrador (uma notificação no fim + proteção de concorrência)
  Future<void> aplicarFiltrosERecalcular() async {
    final runId = ++_applyRunId;

    // 🔄 Garanta dados mais recentes antes de qualquer cálculo
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

    // 🔧 mantém lista global de empresas (com base no allContracts atualizado)
    _atualizarEmpresasComBaseNosContratos();

    _safeNotify();
  }

  void onTipoDeValorSelecionado(String novoTipo) {
    tipoDeValorSelecionado = novoTipo;
    _safeNotify();
  }

  // --------- Combinações p/ gráficos (Status/Região/Empresa)
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

  // --------- Labels/valores ordenados (Status)
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

  // --------- Gráfico de regiões
  List<String> get labelsRegiao => ContractRules.regions;

  List<double?> get valuesRegiao =>
      ContractRules.regions.map((r) => totaisRegiaoAtuais[r]).toList();

  List<Color> get barColorsRegiao {
    return List.generate(ContractRules.regions.length, (i) {
      final valor = valuesRegiao[i] ?? 0.0;
      if (valor == 0.0) return Colors.grey.shade300;
      if (selectedRegionIndex != null && selectedRegionIndex == i) {
        return Colors.orangeAccent; // destaque região selecionada
      }
      return Colors.blueAccent;
    });
  }

  // --------- Gráfico de empresas
  List<String> get labelsEmpresa => uniqueCompanies;

  // 🔧 nunca retorna null (barra vira 0.0 e aparece cinza)
  List<double> get valuesEmpresa =>
      uniqueCompanies.map((e) => totaisEmpresaAtuais[e] ?? 0.0).toList();

  List<Color> get barColorsEmpresa {
    return List.generate(uniqueCompanies.length, (i) {
      final valor = valuesEmpresa[i];
      if (valor == 0.0) return Colors.grey.shade300;
      if (selectedCompanyIndex != null && selectedCompanyIndex == i) {
        return Colors.orangeAccent; // destaque empresa selecionada
      }
      return Colors.blueAccent;
    });
  }

  // ================== Radar 100% baseado no contractServices ==================
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
        return 0.0; // conectar AdditivesStore se desejar
      case 'Total em apostilas':
        return 0.0; // conectar ApostillesStore se desejar
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
  /// Agrupa os contratos filtrados por `mainContractHighway` somando o valor contratado.
  /// Retorna uma lista de `TreemapItem` pronta para o TreemapChanged.
  List<TreemapItem> get treemapRodovias {
    final mapa = <String, double>{};

    for (final contrato in filteredContracts) {
      final rodovia = (contrato.mainContractHighway ?? 'SEM RODOVIA').trim();
      if (rodovia.isEmpty) continue;

      // Usa o mesmo "tipoDeValorSelecionado" se quiser deixar dinâmico
      double valor;
      switch (tipoDeValorSelecionado) {
        case 'Valor contratado':
          valor = contrato.initialValueContract ?? 0.0;
          break;
        case 'Total em aditivos':
        // opcional: somar via AdditivesStore por contrato
          valor = 0.0;
          break;
        case 'Total em apostilas':
        // opcional: somar via ApostillesStore por contrato
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

    // Ordena rodovias por valor desc (opcional, útil para cores)
    final ordenado = mapa.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Paleta simples cíclica
    final colors = <Color>[
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.brown,
      Colors.cyan,
      Colors.deepOrange,
      Colors.pink,
      Colors.lime,
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
}
