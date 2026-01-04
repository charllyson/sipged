// lib/_blocs/panels/general_dashboard/general_dashboard_cubit.dart
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/process/apostilles/apostilles_repository.dart';

import 'general_dashboard_state.dart';

import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_blocs/_process/process_store.dart';

import 'package:siged/_blocs/process/additives/additives_data.dart';
import 'package:siged/_blocs/process/additives/additives_repository.dart';
import 'package:siged/_blocs/process/apostilles/apostilles_data.dart';

import 'package:siged/_blocs/process/measurement/adjustment/adjustment_measurement_data.dart';
import 'package:siged/_blocs/process/measurement/adjustment/adjustments_measurement_cubit.dart';
import 'package:siged/_blocs/process/measurement/report/report_measurement_cubit.dart';
import 'package:siged/_blocs/process/measurement/report/report_measurement_data.dart';
import 'package:siged/_blocs/process/measurement/revision/revision_measurement_cubit.dart';
import 'package:siged/_blocs/process/measurement/revision/revision_measurement_data.dart';

import 'package:siged/_blocs/process/hiring/1Dfd/dfd_cubit.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';
import 'package:siged/_blocs/process/hiring/5Edital/edital_cubit.dart';
import 'package:siged/_blocs/process/hiring/5Edital/edital_data.dart';

import 'package:siged/_widgets/charts/radar/radar_series_data.dart';
import 'package:siged/_widgets/charts/treemap/treemap_class.dart';
import 'package:siged/_widgets/charts/treemap/treemap_style.dart';

class GeneralDashboardCubit extends Cubit<GeneralDashboardState> {
  GeneralDashboardCubit({
    required this.store,
    required this.reportMeasurementCubit,
    required this.adjustmentMeasurementCubit,
    required this.revisionMeasurementCubit,
    required this.additivesRepository,
    required this.apostillesRepository,
    required this.dfdCubit,
    required this.editalCubit,
  }) : super(const GeneralDashboardState());

  // Injeções
  final ProcessStore store;

  // Cubits de medição / reajuste / revisão
  final ReportMeasurementCubit reportMeasurementCubit;
  final AdjustmentMeasurementCubit adjustmentMeasurementCubit;
  final RevisionMeasurementCubit revisionMeasurementCubit;

  // Aditivos / Apostilas
  final AdditivesRepository additivesRepository; ///DEVE CHAMAR O REPO E NAO O CUBIT
  final ApostillesRepository apostillesRepository;

  // DFD / Edital
  final DfdCubit dfdCubit;
  final EditalCubit editalCubit;

  int _applyRunId = 0;

  // Caches do DFD / Edital
  final Map<String, String> _roadNameByContract = {};
  final Map<String, String> _regionByContract = {};
  final Map<String, String> _statusByContract = {};
  final Map<String, String> _naturezaByContract = {};
  final Map<String, String> _winnerByContract = {};

  /// Município por contrato (DFD.municipio)
  final Map<String, String> _municipioByContract = {};

  /// valorDemanda por contrato (usando DFD)
  final Map<String, double> _valueByContract = {};

  /// Contratos para os quais já tentamos buscar DFD uma vez
  final Set<String> _dfdCheckedContracts = {};

  /// Contratos para os quais já tentamos buscar Edital uma vez
  final Set<String> _editalCheckedContracts = {};

  // ========= HELPERS PERF =========

  void _logPerf(String message) {
    if (kDebugMode) {
      debugPrint('[GeneralDashboardCubit] $message');
    }
  }

  // ========= HELPERS =========

  String? _idToString(Object? id) {
    if (id == null) return null;
    try {
      final dynamic dyn = id;
      final hasUid = (() {
        try {
          return (dyn as dynamic).uid is String;
        } catch (_) {
          return false;
        }
      })();
      if (hasUid) return (dyn as dynamic).uid as String;
    } catch (_) {}
    return id.toString();
  }

  String? _parseContractIdFromPath(String? p) {
    if (p == null || p.isEmpty) return null;
    final m = RegExp(r'/contracts/([^/]+)').firstMatch(p);
    return m?.group(1);
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

  /// Extrai contractId de qualquer coisa (Report/Adjustment/RevisionData)
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

  /// Pré-carrega labels de DFD/Edital para os contratos informados.
  ///
  /// Importante: com os sets [_dfdCheckedContracts] e [_editalCheckedContracts],
  /// cada contrato só dispara as chamadas remotas de DFD/Edital **uma vez**.
  Future<void> _preloadDfdLabels(Iterable<ProcessData> base) async {
    final swTotal = Stopwatch()..start();

    int dfdCalls = 0;
    int editalCalls = 0;

    final futures = <Future<void>>[];

    for (final c in base) {
      final id = _idToString(c.id);
      if (id == null) continue;

      final precisaRodovia = !_roadNameByContract.containsKey(id);
      final precisaRegiao = !_regionByContract.containsKey(id);
      final precisaStatus = !_statusByContract.containsKey(id);
      final precisaNatureza = !_naturezaByContract.containsKey(id);
      final precisaVencedor = !_winnerByContract.containsKey(id);
      final precisaValor = !_valueByContract.containsKey(id);
      final precisaMunicipio = !_municipioByContract.containsKey(id);

      final precisaAlgoDeDfd = precisaRodovia ||
          precisaRegiao ||
          precisaStatus ||
          precisaNatureza ||
          precisaValor ||
          precisaMunicipio;

      final precisaAlgoDeEdital = precisaVencedor;

      // Se já tentamos DFD uma vez para este contrato, não tentamos de novo
      final jaTentouDfd = _dfdCheckedContracts.contains(id);
      final jaTentouEdital = _editalCheckedContracts.contains(id);

      if (!precisaAlgoDeDfd && !precisaAlgoDeEdital) {
        continue;
      }

      futures.add(() async {
        // DFD
        if (precisaAlgoDeDfd && !jaTentouDfd) {
          _dfdCheckedContracts.add(id);
          dfdCalls++;

          final DfdData? dfd = await dfdCubit.getDataForContract(id);

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
            if (precisaValor) {
              _valueByContract[id] = dfd.valorDemanda ?? 0.0;
            }
            if (precisaMunicipio) {
              final mun = dfd.municipio?.trim();
              if (mun != null && mun.isNotEmpty) {
                _municipioByContract[id] = mun;
              }
            }
          }
        }

        // Edital (vencedor)
        if (precisaAlgoDeEdital && !jaTentouEdital) {
          _editalCheckedContracts.add(id);
          editalCalls++;

          final EditalData? edital = await editalCubit.getDataForContract(id);
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

    swTotal.stop();
    _logPerf(
      '_preloadDfdLabels: contratos=${base.length}, DFD calls=$dfdCalls, Edital calls=$editalCalls => ${swTotal.elapsedMilliseconds} ms',
    );
  }

  Map<String, String> get regionByMunicipio {
    final map = <String, String>{};

    for (final c in state.allContracts) {
      final mun = _getMunicipioLabel(c).trim();
      final reg = _getRegionLabel(c).trim();

      if (mun.isEmpty ||
          mun.toUpperCase() == 'SEM MUNICÍPIO' ||
          reg.isEmpty ||
          reg.toUpperCase() == 'SEM REGIÃO') {
        continue;
      }

      final key = mun.toUpperCase();
      map.putIfAbsent(key, () => reg);
    }

    return map;
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

  String _getNatureLabel(ProcessData c) {
    final id = _idToString(c.id);
    final cached = (id != null) ? _naturezaByContract[id] : null;
    final v = (cached ?? '').trim();
    if (v.isNotEmpty) return v;
    return 'SEM NATUREZA';
  }

  String _getWinnerLabel(ProcessData c) {
    final id = _idToString(c.id);
    final cached = (id != null) ? _winnerByContract[id] : null;
    final v = (cached ?? '').trim();
    if (v.isNotEmpty) return v;
    return 'EM PROJETO';
  }

  /// MUNICÍPIO (DFD.municipio)
  String _getMunicipioLabel(ProcessData c) {
    final id = _idToString(c.id);
    final cached = (id != null) ? _municipioByContract[id] : null;
    final v = (cached ?? '').trim();
    if (v.isNotEmpty) return v;
    return 'SEM MUNICÍPIO';
  }

  double _getContractValue(ProcessData c) {
    final id = _idToString(c.id);
    if (id == null) return 0.0;
    final v = _valueByContract[id];
    if (v == null) return 0.0;
    return v;
  }

  List<String> _extractCompanies(List<ProcessData> data) {
    final set = <String>{
      for (final c in data) _getWinnerLabel(c).trim().toUpperCase(),
    };
    final list = set.toList()..sort();
    return list;
  }

  // ========= PUBLIC GETTERS =========

  bool get houveInteracaoComFiltros =>
      state.selectedStatus != null ||
          state.selectedCompany != null ||
          state.selectedRegions.isNotEmpty ||
          state.selectedRoad != null ||
          state.selectedMunicipio != null;

  double? get totaisMedicoes => state.totalMedicoes;
  double? get totaisReajustes => state.totalReajustes;
  double? get totaisRevisoes => state.totalRevisoes;

  List<String> get municipiosSelecionadosParaMapa {
    final sel = state.selectedMunicipio;
    if (sel != null &&
        sel.trim().isNotEmpty &&
        sel.trim().toUpperCase() != 'SEM MUNICÍPIO') {
      return [sel.trim()];
    }

    final set = <String>{};
    for (final c in state.filteredContracts) {
      final m = _getMunicipioLabel(c);
      final v = m.trim();
      if (v.isEmpty) continue;
      if (v.toUpperCase() == 'SEM MUNICÍPIO') continue;
      set.add(v);
    }

    final list = set.toList()..sort();
    return list;
  }

  List<String> get municipiosComContratosGeral {
    final set = <String>{};
    for (final c in state.allContracts) {
      final m = _getMunicipioLabel(c);
      final v = m.trim();
      if (v.isEmpty) continue;
      if (v.toUpperCase() == 'SEM MUNICÍPIO') continue;
      set.add(v);
    }
    final list = set.toList()..sort();
    return list;
  }

  Map<String, double> _somarMapas(List<Map<String, double>> maps) {
    final out = <String, double>{};
    for (final m in maps) {
      for (final e in m.entries) {
        out[e.key] = (out[e.key] ?? 0.0) + e.value;
      }
    }
    return out;
  }

  // ===== STATUS (derivados) =====

  Map<String, double> get totaisStatusAtuais {
    switch (state.tipoDeValorSelecionado) {
      case 'Valor contratado':
        return state.totaisStatusIniciais;
      case 'Total em aditivos':
        return state.totaisStatusAditivos;
      case 'Total em apostilas':
        return state.totaisStatusApostilas;
      case 'Somatório total':
      default:
        return _somarMapas([
          state.totaisStatusIniciais,
          state.totaisStatusAditivos,
          state.totaisStatusApostilas,
        ]);
    }
  }

  Map<String, double> get totaisStatusAtuaisFull {
    switch (state.tipoDeValorSelecionado) {
      case 'Valor contratado':
        return state.totaisStatusIniciaisFull;
      case 'Total em aditivos':
        return state.totaisStatusAditivosFull;
      case 'Total em apostilas':
        return state.totaisStatusApostilasFull;
      case 'Somatório total':
      default:
        return _somarMapas([
          state.totaisStatusIniciaisFull,
          state.totaisStatusAditivosFull,
          state.totaisStatusApostilasFull,
        ]);
    }
  }

  List<String> get labelsStatusGeneralContracts {
    final entries = totaisStatusAtuaisFull.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => e.key).toList();
  }

  List<double> get valuesStatusGeneralContractsFull {
    final labels = labelsStatusGeneralContracts;
    return labels.map((k) => totaisStatusAtuaisFull[k] ?? 0.0).toList();
  }

  List<double> get valuesStatusGeneralContractsFiltered {
    final labels = labelsStatusGeneralContracts;
    return labels.map((k) => totaisStatusAtuais[k] ?? 0.0).toList();
  }

  List<double> get valuesStatusGeneralContracts =>
      valuesStatusGeneralContractsFiltered;

  // ===== REGIÃO =====

  Map<String, double> get totaisRegiaoAtuais {
    switch (state.tipoDeValorSelecionado) {
      case 'Valor contratado':
        return state.totaisRegiaoIniciais;
      case 'Total em aditivos':
        return state.totaisRegiaoAditivos;
      case 'Total em apostilas':
        return state.totaisRegiaoApostilas;
      case 'Somatório total':
      default:
        return _somarMapas([
          state.totaisRegiaoIniciais,
          state.totaisRegiaoAditivos,
          state.totaisRegiaoApostilas,
        ]);
    }
  }

  Map<String, double> get totaisRegiaoAtuaisFull {
    switch (state.tipoDeValorSelecionado) {
      case 'Valor contratado':
        return state.totaisRegiaoIniciaisFull;
      case 'Total em aditivos':
        return state.totaisRegiaoAditivosFull;
      case 'Total em apostilas':
        return state.totaisRegiaoApostilasFull;
      case 'Somatório total':
      default:
        return _somarMapas([
          state.totaisRegiaoIniciaisFull,
          state.totaisRegiaoAditivosFull,
          state.totaisRegiaoApostilasFull,
        ]);
    }
  }

  List<String> get labelsRegionOfMap {
    final keys = <String>{
      ...totaisRegiaoAtuaisFull.keys,
      ...totaisRegiaoAtuais.keys,
    }
      ..removeWhere(
            (k) => k.trim().isEmpty || k.trim().toUpperCase() == 'SEM REGIÃO',
      );

    final list = keys.toList()..sort();
    return list;
  }

  List<double?> get valuesRegionOfMapFull =>
      labelsRegionOfMap.map((r) => totaisRegiaoAtuaisFull[r]).toList();

  List<double?> get valuesRegionOfMapFiltered =>
      labelsRegionOfMap.map((r) => totaisRegiaoAtuais[r]).toList();

  List<double?> get valuesRegionOfMap => valuesRegionOfMapFiltered;

  List<Color> get barColorsRegion {
    return List.generate(labelsRegionOfMap.length, (i) {
      if (state.selectedRegionIndex != null &&
          state.selectedRegionIndex == i) {
        return Colors.orangeAccent;
      }
      return Colors.cyan;
    });
  }

  // ===== EMPRESA =====

  Map<String, double> get totaisEmpresaAtuais {
    switch (state.tipoDeValorSelecionado) {
      case 'Valor contratado':
        return state.totaisEmpresaIniciais;
      case 'Total em aditivos':
        return state.totaisEmpresaAditivos;
      case 'Total em apostilas':
        return state.totaisEmpresaApostilas;
      case 'Somatório total':
      default:
        return _somarMapas([
          state.totaisEmpresaIniciais,
          state.totaisEmpresaAditivos,
          state.totaisEmpresaApostilas,
        ]);
    }
  }

  Map<String, double> get totaisEmpresaAtuaisFull {
    switch (state.tipoDeValorSelecionado) {
      case 'Valor contratado':
        return state.totaisEmpresaIniciaisFull;
      case 'Total em aditivos':
        return state.totaisEmpresaAditivosFull;
      case 'Total em apostilas':
        return state.totaisEmpresaApostilasFull;
      case 'Somatório total':
      default:
        return _somarMapas([
          state.totaisEmpresaIniciaisFull,
          state.totaisEmpresaAditivosFull,
          state.totaisEmpresaApostilasFull,
        ]);
    }
  }

  List<String> get labelsCompany => state.uniqueCompanies;

  List<double> get valuesCompanyFull =>
      state.uniqueCompanies
          .map((e) => totaisEmpresaAtuaisFull[e] ?? 0.0)
          .toList();

  List<double> get valuesCompany =>
      state.uniqueCompanies
          .map((e) => totaisEmpresaAtuais[e] ?? 0.0)
          .toList();

  List<Color> get barColorsEmpresa {
    return List.generate(state.uniqueCompanies.length, (i) {
      if (state.selectedCompanyIndex != null &&
          state.selectedCompanyIndex == i) {
        return Colors.orangeAccent;
      }
      return Colors.blueAccent;
    });
  }

  // ===== Radar (natureza intervenção) =====

  List<String> get radarServiceLabels {
    final set = <String>{};
    for (final c in state.allContracts) {
      final s = _getNatureLabel(c);
      if (s != 'SEM NATUREZA') set.add(s);
    }
    final ordered = set.toList()..sort();
    return ordered;
  }

  double _valorRadarParaContrato(ProcessData c) {
    switch (state.tipoDeValorSelecionado) {
      case 'Valor contratado':
        return _getContractValue(c);
      case 'Total em aditivos':
      case 'Total em apostilas':
        return 0.0;
      case 'Somatório total':
      default:
        return _getContractValue(c);
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
    return _sumRadarPorNatureza(state.filteredContracts, labels);
  }

  List<double> radarServiceValuesEmpresaSelecionada() {
    if (state.selectedCompany == null) return const [];
    final labels = radarServiceLabels;
    final alvo = state.selectedCompany!.toUpperCase();
    final base = state.filteredContracts
        .where((c) => _getWinnerLabel(c).toUpperCase() == alvo)
        .toList();
    return _sumRadarPorNatureza(base, labels);
  }

  List<double> radarServiceValuesRegiaoSelecionada() {
    if (state.selectedRegion == null && state.selectedRegions.isEmpty) {
      return const [];
    }
    final labels = radarServiceLabels;
    final alvo =
    (state.selectedRegion ?? state.selectedRegions.first).toUpperCase();
    final base = state.filteredContracts
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
          name: state.selectedCompany ?? 'Empresa',
          values: empresa,
          color: warning,
        ),
      if (regiao.isNotEmpty)
        RadarSeriesData(
          name: state.selectedRegion ??
              (state.selectedRegions.isNotEmpty
                  ? state.selectedRegions.first
                  : 'Região'),
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

  // ===== Treemap rodovias =====

  List<TreemapItem> get treemapRodovias {
    final ordenado = state.totaisRodoviaFull.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    int i = 0;
    return ordenado.map((e) {
      final color =
      TreemapStyle.tradeMapColors[i % TreemapStyle.tradeMapColors.length];
      i++;
      return TreemapItem(label: e.key, value: e.value, color: color);
    }).toList(growable: false);
  }

  List<double?> get treemapRodoviasFilteredValues {
    final ordenado = state.totaisRodoviaFull.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ordenado
        .map((e) => state.totaisRodoviaFiltrado[e.key] ?? 0.0)
        .toList();
  }

  // ========= CICLO DE VIDA =========

  Future<void> initialize() async {
    final swTotal = Stopwatch()..start();
    _logPerf('initialize() START');

    emit(state.copyWith(isLoading: true));

    final swContracts = Stopwatch()..start();
    final allContracts = store.all;
    swContracts.stop();
    _logPerf(
      'initialize(): store.all => ${swContracts.elapsedMilliseconds} ms (count=${allContracts.length})',
    );

    final swPreload = Stopwatch()..start();
    await _preloadDfdLabels(allContracts);
    swPreload.stop();
    _logPerf(
      'initialize(): _preloadDfdLabels => ${swPreload.elapsedMilliseconds} ms',
    );

    final swReloadGroups = Stopwatch()..start();
    await _reloadMeasurementGroups();
    swReloadGroups.stop();
    _logPerf(
      'initialize(): _reloadMeasurementGroups => ${swReloadGroups.elapsedMilliseconds} ms',
    );

    final uniqueCompanies = _extractCompanies(allContracts);

    emit(state.copyWith(
      allContracts: allContracts,
      filteredContracts: allContracts,
      uniqueCompanies: uniqueCompanies,
      selectedYear: DateTime.now().year,
    ));

    final swApply = Stopwatch()..start();
    await aplicarFiltrosERecalcular();
    swApply.stop();
    _logPerf(
      'initialize(): aplicarFiltrosERecalcular => ${swApply.elapsedMilliseconds} ms',
    );

    emit(state.copyWith(
      initialized: true,
      isLoading: false,
    ));

    swTotal.stop();
    _logPerf(
      'initialize() TOTAL => ${swTotal.elapsedMilliseconds} ms',
    );
  }

  /// Recarrega listas globais de medições/reajustes/revisões e recalcula
  Future<void> refreshAndRecalc() async {
    final sw = Stopwatch()..start();
    _logPerf('refreshAndRecalc() START');

    await _reloadMeasurementGroups();
    await aplicarFiltrosERecalcular();

    sw.stop();
    _logPerf('refreshAndRecalc() TOTAL => ${sw.elapsedMilliseconds} ms');
  }

  /// Usado em hot-reload
  Future<void> onHotReload() => refreshAndRecalc();

  /// Carrega TODAS medições/reajustes/revisões (collectionGroup) via cubits
  Future<void> _reloadMeasurementGroups() async {
    final sw = Stopwatch()..start();

    final results = await Future.wait([
      reportMeasurementCubit.getAllMeasurementsCollectionGroup(),
      adjustmentMeasurementCubit.getAllAdjustmentsCollectionGroup(),
      revisionMeasurementCubit.getAllRevisionsCollectionGroup(),
    ]);

    final allMeasurements = results[0] as List<ReportMeasurementData>;
    final allAdjustments = results[1] as List<AdjustmentMeasurementData>;
    final allRevisions = results[2] as List<RevisionMeasurementData>;

    emit(state.copyWith(
      allMeasurements: allMeasurements,
      allAdjustments: allAdjustments,
      allRevisions: allRevisions,
    ));

    sw.stop();
    _logPerf(
      '_reloadMeasurementGroups: med=${allMeasurements.length}, reaj=${allAdjustments.length}, rev=${allRevisions.length} => ${sw.elapsedMilliseconds} ms',
    );
  }

  // ========= MUTAÇÕES DE FILTRO =========

  Future<void> onStatusSelected(String? status) async {
    final sel = status?.trim();
    final same = (state.selectedStatus ?? '').toUpperCase() ==
        (sel ?? '').toUpperCase();

    if (sel == null || same) {
      emit(state.copyWith(
        selectedStatus: null,
        selectedCompany: null,
        selectedCompanyIndex: null,
        selectedRegion: null,
        selectedRegionIndex: null,
        selectedRegions: const [],
        selectedRoad: null,
        selectedMunicipio: null,
      ));
    } else {
      final selUpper = sel.toUpperCase();
      final regs = store.all
          .where((c) => _getStatusLabel(c).toUpperCase() == selUpper)
          .map((c) => _getRegionLabel(c).toUpperCase())
          .where((r) => r.isNotEmpty && r != 'SEM REGIÃO')
          .toSet()
          .toList();

      emit(state.copyWith(
        selectedStatus: sel,
        selectedCompany: null,
        selectedCompanyIndex: null,
        selectedRegion: null,
        selectedRegionIndex: null,
        selectedRegions: regs,
        selectedRoad: null,
        selectedMunicipio: null,
      ));
    }

    await aplicarFiltrosERecalcular();
  }

  Future<void> onCompanySelected(String company) async {
    final idx = state.uniqueCompanies
        .indexWhere((e) => e.toUpperCase() == company.toUpperCase());

    if (idx < 0) {
      final isSame =
          (state.selectedCompany ?? '').toUpperCase() == company.toUpperCase();

      if (isSame) {
        emit(state.copyWith(
          selectedCompany: null,
          selectedCompanyIndex: null,
          selectedRegions: const [],
          selectedMunicipio: null,
        ));
      } else {
        final contratosEmpresa = store.all.where(
              (c) => _getWinnerLabel(c).toUpperCase() == company.toUpperCase(),
        );

        final regs = contratosEmpresa
            .map((c) => _getRegionLabel(c).toUpperCase())
            .where((r) => r.isNotEmpty && r != 'SEM REGIÃO')
            .toSet()
            .toList();

        emit(state.copyWith(
          selectedCompany: company,
          selectedCompanyIndex: null,
          selectedRegions: regs,
          selectedStatus: null,
          selectedRegion: null,
          selectedRegionIndex: null,
          selectedRoad: null,
          selectedMunicipio: null,
        ));
      }

      await aplicarFiltrosERecalcular();
      return;
    }

    await onCompanyIndexSelected(idx);
  }

  Future<void> onCompanyIndexSelected(int? index) async {
    if (index == null || state.selectedCompanyIndex == index) {
      emit(state.copyWith(
        selectedCompany: null,
        selectedCompanyIndex: null,
        selectedRegions: const [],
        selectedStatus: null,
        selectedRegion: null,
        selectedRegionIndex: null,
        selectedRoad: null,
        selectedMunicipio: null,
      ));
      await aplicarFiltrosERecalcular();
      return;
    }

    if (index < 0 || index >= state.uniqueCompanies.length) return;

    final company = state.uniqueCompanies[index];
    final contratosEmpresa = store.all.where(
          (c) => _getWinnerLabel(c).toUpperCase() == company.toUpperCase(),
    );

    final regs = contratosEmpresa
        .map((c) => _getRegionLabel(c).toUpperCase())
        .where((r) => r.isNotEmpty && r != 'SEM REGIÃO')
        .toSet()
        .toList();

    emit(state.copyWith(
      selectedCompany: company,
      selectedCompanyIndex: index,
      selectedRegions: regs,
      selectedStatus: null,
      selectedRegion: null,
      selectedRegionIndex: null,
      selectedRoad: null,
      selectedMunicipio: null,
    ));

    await aplicarFiltrosERecalcular();
  }

  Future<void> onRegionSelected(String? region) async {
    if (region == null) {
      await onRegionIndexSelected(null);
      return;
    }

    final idx = labelsRegionOfMap
        .indexWhere((r) => r.toUpperCase() == region.toUpperCase());

    if (idx < 0) {
      final same = state.selectedRegions.contains(region.toUpperCase());

      if (same) {
        emit(state.copyWith(
          selectedRegion: null,
          selectedRegions: const [],
          selectedRegionIndex: null,
          selectedMunicipio: null,
        ));
      } else {
        emit(state.copyWith(
          selectedRegion: region,
          selectedRegions: [region.toUpperCase()],
          selectedRegionIndex: null,
          selectedMunicipio: null,
        ));
      }

      await aplicarFiltrosERecalcular();
      return;
    }

    await onRegionIndexSelected(idx);
  }

  Future<void> onRegionIndexSelected(int? index) async {
    if (index == null || state.selectedRegionIndex == index) {
      emit(state.copyWith(
        selectedRegion: null,
        selectedRegions: const [],
        selectedRegionIndex: null,
        selectedMunicipio: null,
      ));
      await aplicarFiltrosERecalcular();
      return;
    }

    if (index < 0 || index >= labelsRegionOfMap.length) return;

    final region = labelsRegionOfMap[index];

    emit(state.copyWith(
      selectedRegion: region,
      selectedRegions: [region.toUpperCase()],
      selectedRegionIndex: index,
      selectedMunicipio: null,
    ));

    await aplicarFiltrosERecalcular();
  }

  Future<void> onRoadSelected(String? roadLabel) async {
    final sel = roadLabel?.trim();
    final same =
        (state.selectedRoad ?? '').toUpperCase() == (sel ?? '').toUpperCase();

    if (sel == null || same) {
      emit(state.copyWith(
        selectedRoad: null,
        selectedRegions: const [],
        selectedRegion: null,
        selectedRegionIndex: null,
        selectedStatus: null,
        selectedCompany: null,
        selectedCompanyIndex: null,
        selectedMunicipio: null,
      ));
    } else {
      final regs = store.all
          .where((c) => _getRoadLabel(c).toUpperCase() == sel.toUpperCase())
          .map((c) => _getRegionLabel(c).toUpperCase())
          .where((r) => r.isNotEmpty && r != 'SEM REGIÃO')
          .toSet()
          .toList();

      emit(state.copyWith(
        selectedRoad: sel,
        selectedRegions: regs,
        selectedStatus: null,
        selectedCompany: null,
        selectedCompanyIndex: null,
        selectedRegion: null,
        selectedRegionIndex: null,
        selectedMunicipio: null,
      ));
    }

    await aplicarFiltrosERecalcular();
  }

  /// Filtro por município (chamado pelo mapa/GeoJSON)
  Future<void> onMunicipioSelected(String? municipio) async {
    final sel = municipio?.trim();
    final same = (state.selectedMunicipio ?? '').toUpperCase() ==
        (sel ?? '').toUpperCase();

    if (sel == null || same) {
      emit(state.copyWith(
        selectedMunicipio: null,
      ));
    } else {
      emit(state.copyWith(
        selectedMunicipio: sel,
        selectedStatus: null,
        selectedCompany: null,
        selectedCompanyIndex: null,
        selectedRegion: null,
        selectedRegionIndex: null,
        selectedRegions: const [],
        selectedRoad: null,
      ));
    }

    await aplicarFiltrosERecalcular();
  }

  Future<void> limparSelecoes() async {
    emit(state.copyWith(
      selectedStatus: null,
      selectedCompany: null,
      selectedCompanyIndex: null,
      selectedRegion: null,
      selectedRegionIndex: null,
      selectedRegions: const [],
      selectedRoad: null,
      selectedMunicipio: null,
    ));
    await aplicarFiltrosERecalcular();
  }

  void onTipoDeValorSelecionado(String novoTipo) {
    emit(state.copyWith(tipoDeValorSelecionado: novoTipo));
  }

  void updateSelectedYearMonth(int? year, int? month) {
    emit(state.copyWith(
      selectedYear: year,
      selectedMonth: month,
    ));
  }

  // ========= FILTRO / RECÁLCULO =========

  List<ProcessData> _filterContracts(
      List<ProcessData> base,
      ) {
    final selStatus = state.selectedStatus?.toUpperCase();
    final selCompany = state.selectedCompany?.toUpperCase();
    final selRoad = state.selectedRoad?.toUpperCase();
    final selMunicipio = state.selectedMunicipio?.toUpperCase();
    final regionsUpper = state.selectedRegions.map((e) => e.toUpperCase());

    return base.where((c) {
      final region = _getRegionLabel(c).toUpperCase();
      final company = _getWinnerLabel(c).toUpperCase();
      final statusDfd = _getStatusLabel(c).toUpperCase();
      final road = _getRoadLabel(c).toUpperCase();
      final municipio = _getMunicipioLabel(c).toUpperCase();

      final matchCompany = selCompany == null || company == selCompany;
      final matchRegion = state.selectedRegions.isEmpty ||
          regionsUpper.any((r) => region.contains(r));
      final matchStatus = selStatus == null || statusDfd == selStatus;
      final matchRoad = selRoad == null || road == selRoad;
      final matchMunicipio =
          selMunicipio == null || municipio == selMunicipio;

      return matchCompany &&
          matchRegion &&
          matchStatus &&
          matchRoad &&
          matchMunicipio;
    }).toList();
  }

  Future<void> aplicarFiltrosERecalcular() async {
    final runId = ++_applyRunId;
    final swTotal = Stopwatch()..start();
    _logPerf('aplicarFiltrosERecalcular(runId=$runId) START');

    final allContracts =
    state.allContracts.isEmpty ? store.all : state.allContracts;

    // Listas globais de medição/reajuste/revisão já carregadas via _reloadMeasurementGroups
    final allMeasurements = state.allMeasurements;
    final allAdjustments = state.allAdjustments;
    final allRevisions = state.allRevisions;

    // Garante DFD/valorDemanda/municipio para quem ainda não foi tentado
    final swPreload = Stopwatch()..start();
    await _preloadDfdLabels(allContracts);
    swPreload.stop();
    if (isClosed || runId != _applyRunId) return;
    _logPerf(
      'aplicarFiltrosERecalcular: _preloadDfdLabels => ${swPreload.elapsedMilliseconds} ms',
    );

    final swFilter = Stopwatch()..start();
    final filtered = _filterContracts(allContracts);
    swFilter.stop();
    _logPerf(
      'aplicarFiltrosERecalcular: _filterContracts => ${swFilter.elapsedMilliseconds} ms (filtered=${filtered.length}/${allContracts.length})',
    );

    // ===== Cálculos em mapas locais (iniciais, filtrados) =====
    final swMapsIni = Stopwatch()..start();
    final statusIni = <String, double>{};
    final empIni = <String, double>{};
    final regIni = <String, double>{};

    for (final c in filtered) {
      final status = _getStatusLabel(c);
      final empresa = _getWinnerLabel(c);
      final regiao = _getRegionLabel(c);
      final valor = _getContractValue(c);

      statusIni[status] = (statusIni[status] ?? 0.0) + valor;
      empIni[empresa] = (empIni[empresa] ?? 0.0) + valor;
      regIni[regiao] = (regIni[regiao] ?? 0.0) + valor;
    }
    swMapsIni.stop();
    _logPerf(
      'aplicarFiltrosERecalcular: mapas iniciais (status/empresa/região FILTRADO) => ${swMapsIni.elapsedMilliseconds} ms',
    );

    // ===== Preparação de IDs / mapas auxiliares =====
    final allIds = <String>{
      for (final c in allContracts)
        if (_idToString(c.id) != null) _idToString(c.id)!,
    };

    final filtradosIds = <String>{
      for (final c in filtered)
        if (_idToString(c.id) != null) _idToString(c.id)!,
    };

    final byIdAllContracts = <String, ProcessData>{
      for (final c in allContracts)
        if (_idToString(c.id) != null) _idToString(c.id)!: c,
    };

    // ===== Carregar aditivos/apostilas UMA VEZ só =====
    final swAddAll = Stopwatch()..start();
    final allAdditives = allIds.isNotEmpty
        ? await additivesRepository.getAdditivesByContractIds(allIds)
        : <AdditivesData>[];
    swAddAll.stop();
    if (isClosed || runId != _applyRunId) return;
    _logPerf(
      'aplicarFiltrosERecalcular: getAdditivesByContractIds(allIds=${allIds.length}) ONCE => ${swAddAll.elapsedMilliseconds} ms (ret=${allAdditives.length})',
    );

    final swApAll = Stopwatch()..start();
    final allApostilles = allIds.isNotEmpty
        ? await apostillesRepository.getApostillesByContractIds(allIds)
        : <ApostillesData>[];
    swApAll.stop();
    if (isClosed || runId != _applyRunId) return;
    _logPerf(
      'aplicarFiltrosERecalcular: getForContractIds(allIds=${allIds.length}) ONCE => ${swApAll.elapsedMilliseconds} ms (ret=${allApostilles.length})',
    );

    // ===== Mapas FULL e FILTRADOS de uma vez (status, empresa, região) =====
    final swMapsFull = Stopwatch()..start();

    // FULL iniciais
    final regIniFull = <String, double>{};
    final empIniFull = <String, double>{};
    final statusIniFull = <String, double>{};

    for (final c in allContracts) {
      final regiao = _getRegionLabel(c);
      final empresa = _getWinnerLabel(c);
      final status = _getStatusLabel(c);
      final valor = _getContractValue(c);

      regIniFull[regiao] = (regIniFull[regiao] ?? 0.0) + valor;
      empIniFull[empresa] = (empIniFull[empresa] ?? 0.0) + valor;
      statusIniFull[status] = (statusIniFull[status] ?? 0.0) + valor;
    }

    // FULL aditivos/apostilas
    final regAdFull = <String, double>{};
    final regApFull = <String, double>{};

    final empAdFull = <String, double>{};
    final empApFull = <String, double>{};

    final statusAdFull = <String, double>{};
    final statusApFull = <String, double>{};

    // FILTRADOS aditivos/apostilas
    final statusAd = <String, double>{};
    final empAd = <String, double>{};
    final regAd = <String, double>{};

    final statusAp = <String, double>{};
    final empAp = <String, double>{};
    final regAp = <String, double>{};

    // Percorre TODOS aditivos só UMA vez
    for (final ad in allAdditives) {
      final adId = _idToString(ad.contractId);
      if (adId == null) continue;
      final c = byIdAllContracts[adId];
      if (c == null) continue;

      final regiao = _getRegionLabel(c);
      final empresa = _getWinnerLabel(c);
      final status = _getStatusLabel(c);
      final valor = ad.additiveValue ?? 0.0;

      // FULL
      regAdFull[regiao] = (regAdFull[regiao] ?? 0.0) + valor;
      empAdFull[empresa] = (empAdFull[empresa] ?? 0.0) + valor;
      statusAdFull[status] = (statusAdFull[status] ?? 0.0) + valor;

      // FILTRADO
      if (filtradosIds.contains(adId)) {
        regAd[regiao] = (regAd[regiao] ?? 0.0) + valor;
        empAd[empresa] = (empAd[empresa] ?? 0.0) + valor;
        statusAd[status] = (statusAd[status] ?? 0.0) + valor;
      }
    }

    // Percorre TODAS apostilas só UMA vez
    for (final ap in allApostilles) {
      final apId = _idToString(ap.contractId);
      if (apId == null) continue;
      final c = byIdAllContracts[apId];
      if (c == null) continue;

      final regiao = _getRegionLabel(c);
      final empresa = _getWinnerLabel(c);
      final status = _getStatusLabel(c);
      final valor = ap.apostilleValue ?? 0.0;

      // FULL
      regApFull[regiao] = (regApFull[regiao] ?? 0.0) + valor;
      empApFull[empresa] = (empApFull[empresa] ?? 0.0) + valor;
      statusApFull[status] = (statusApFull[status] ?? 0.0) + valor;

      // FILTRADO
      if (filtradosIds.contains(apId)) {
        regAp[regiao] = (regAp[regiao] ?? 0.0) + valor;
        empAp[empresa] = (empAp[empresa] ?? 0.0) + valor;
        statusAp[status] = (statusAp[status] ?? 0.0) + valor;
      }
    }

    swMapsFull.stop();
    _logPerf(
      'aplicarFiltrosERecalcular: mapas FULL + FILTRADOS (status/empresa/região/adit/apostila) => ${swMapsFull.elapsedMilliseconds} ms',
    );

    // ===== Rodovias Full / Filtrado =====
    final swRod = Stopwatch()..start();
    final rodFull = <String, double>{};
    for (final c in allContracts) {
      final rod = _getRoadLabel(c);
      if (rod.isEmpty || rod == 'SEM RODOVIA') continue;
      final valor = _valorRadarParaContrato(c);
      if (valor == 0.0) continue;
      rodFull[rod] = (rodFull[rod] ?? 0.0) + valor;
    }

    final rodFiltrado = <String, double>{};
    for (final c in filtered) {
      final rod = _getRoadLabel(c);
      if (rod.isEmpty || rod == 'SEM RODOVIA') continue;
      final valor = _valorRadarParaContrato(c);
      if (valor == 0.0) continue;
      rodFiltrado[rod] = (rodFiltrado[rod] ?? 0.0) + valor;
    }
    swRod.stop();
    _logPerf(
      'aplicarFiltrosERecalcular: mapas rodovias FULL/FILTRADO => ${swRod.elapsedMilliseconds} ms',
    );

    // ===== Totais Medições / Reajustes / Revisões =====
    final swMed = Stopwatch()..start();

    final idsFiltro = filtradosIds;

    final filtradasMed = allMeasurements.where((m) {
      final cid = _extractContractId(m);
      return cid != null && idsFiltro.contains(cid);
    }).toList();
    final totalMedicoes = reportMeasurementCubit.sum(filtradasMed);

    final entriesReaj = allAdjustments.where((e) {
      final cid = _extractContractId(e);
      return cid != null && idsFiltro.contains(cid);
    }).toList();
    final totalReajustes = adjustmentMeasurementCubit.sum(entriesReaj);

    final entriesRev = allRevisions.where((e) {
      final cid = _extractContractId(e);
      return cid != null && idsFiltro.contains(cid);
    }).toList();
    final totalRevisoes = revisionMeasurementCubit.sum(entriesRev);

    swMed.stop();
    _logPerf(
      'aplicarFiltrosERecalcular: totais medições/reajustes/revisões => ${swMed.elapsedMilliseconds} ms (med=${filtradasMed.length}, reaj=${entriesReaj.length}, rev=${entriesRev.length})',
    );

    final uniqueCompanies = _extractCompanies(allContracts);

    if (isClosed || runId != _applyRunId) return;

    final swEmit = Stopwatch()..start();
    emit(state.copyWith(
      allContracts: allContracts,
      filteredContracts: filtered,
      allMeasurements: allMeasurements,
      allAdjustments: allAdjustments,
      allRevisions: allRevisions,
      uniqueCompanies: uniqueCompanies,
      // FILTRADOS
      totaisStatusIniciais: statusIni,
      totaisStatusAditivos: statusAd,
      totaisStatusApostilas: statusAp,
      totaisRegiaoIniciais: regIni,
      totaisRegiaoAditivos: regAd,
      totaisRegiaoApostilas: regAp,
      totaisEmpresaIniciais: empIni,
      totaisEmpresaAditivos: empAd,
      totaisEmpresaApostilas: empAp,
      // FULL
      totaisStatusIniciaisFull: statusIniFull,
      totaisStatusAditivosFull: statusAdFull,
      totaisStatusApostilasFull: statusApFull,
      totaisRegiaoIniciaisFull: regIniFull,
      totaisRegiaoAditivosFull: regAdFull,
      totaisRegiaoApostilasFull: regApFull,
      totaisEmpresaIniciaisFull: empIniFull,
      totaisEmpresaAditivosFull: empAdFull,
      totaisEmpresaApostilasFull: empApFull,
      totaisRodoviaFull: rodFull,
      totaisRodoviaFiltrado: rodFiltrado,
      totalMedicoes: totalMedicoes,
      totalReajustes: totalReajustes,
      totalRevisoes: totalRevisoes,
    ));
    swEmit.stop();
    _logPerf(
      'aplicarFiltrosERecalcular: emit state => ${swEmit.elapsedMilliseconds} ms',
    );

    swTotal.stop();
    _logPerf(
      'aplicarFiltrosERecalcular(runId=$runId) TOTAL => ${swTotal.elapsedMilliseconds} ms',
    );
  }
}
