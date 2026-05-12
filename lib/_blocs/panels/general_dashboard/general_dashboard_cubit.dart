import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/panels/general_dashboard/general_dashboard_state.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';

import 'package:sipged/_blocs/modules/contracts/additives/additives_data.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_repository.dart';

import 'package:sipged/_blocs/modules/contracts/apostilles/apostilles_data.dart';
import 'package:sipged/_blocs/modules/contracts/apostilles/apostilles_repository.dart';

import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_data.dart';

import 'package:sipged/_blocs/modules/contracts/measurement/report/report_executed_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/report/report_executed_data.dart';

import 'package:sipged/_blocs/modules/contracts/measurement/revision/revision_measurement_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/revision/revision_measurement_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/5Edital/edital_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/5Edital/edital_data.dart';

import 'package:sipged/_widgets/charts/radar/radar_series_data.dart';
import 'package:sipged/_widgets/charts/treemap/treemap_class.dart';
import 'package:sipged/_widgets/charts/treemap/treemap_style.dart';

class GeneralDashboardCubit extends Cubit<GeneralDashboardState> {
  GeneralDashboardCubit({
    required this.processCubit,
    required this.reportMeasurementCubit,
    required this.adjustmentMeasurementCubit,
    required this.revisionMeasurementCubit,
    required this.additivesRepository,
    required this.apostillesRepository,
    required this.dfdCubit,
    required this.editalCubit,
  }) : super(const GeneralDashboardState());

  final ContractCubit processCubit;

  final ReportExecutedCubit reportMeasurementCubit;
  final AdjustmentMeasurementCubit adjustmentMeasurementCubit;
  final RevisionMeasurementCubit revisionMeasurementCubit;

  final AdditivesRepository additivesRepository;
  final ApostillesRepository apostillesRepository;

  final DfdCubit dfdCubit;
  final EditalCubit editalCubit;

  int _applyRunId = 0;

  final Map<String, String> _roadNameByContract = {};
  final Map<String, String> _regionByContract = {};
  final Map<String, String> _statusByContract = {};
  final Map<String, String> _naturezaByContract = {};
  final Map<String, String> _winnerByContract = {};
  final Map<String, String> _municipioByContract = {};
  final Map<String, double> _valueByContract = {};

  final Set<String> _dfdCheckedContracts = {};
  final Set<String> _editalCheckedContracts = {};

  List<ContractData> get _allContractsFromProcessCubit {
    return processCubit.state.allProcesses;
  }

  Future<List<ContractData>> _waitContractsFromProcessCubit() async {
    const maxAttempts = 40;
    const delay = Duration(milliseconds: 250);

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final contracts = processCubit.state.allProcesses;

      if (contracts.isNotEmpty) {
        return List<ContractData>.from(contracts);
      }

      if (isClosed) {
        return const <ContractData>[];
      }

      await Future<void>.delayed(delay);
    }

    return List<ContractData>.from(processCubit.state.allProcesses);
  }

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

      if (hasUid) {
        final uid = (dyn as dynamic).uid as String;
        final cleanUid = uid.trim();

        if (cleanUid.isNotEmpty) return cleanUid;
      }
    } catch (_) {}

    final value = id.toString().trim();

    return value.isEmpty ? null : value;
  }

  String? _parseContractIdFromPath(String? path) {
    final cleanPath = path?.trim();

    if (cleanPath == null || cleanPath.isEmpty) {
      return null;
    }

    final parts = cleanPath
        .split('/')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    final contractsIndex = parts.indexOf('contracts');

    if (contractsIndex < 0) {
      return null;
    }

    final contractIndex = contractsIndex + 1;

    if (contractIndex >= parts.length) {
      return null;
    }

    final contractId = parts[contractIndex].trim();

    if (contractId.isEmpty) {
      return null;
    }

    return contractId;
  }

  String? _dynString(dynamic value) {
    try {
      if (value == null) return null;

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }

      final uid = (value as dynamic).uid;

      if (uid is String && uid.trim().isNotEmpty) {
        return uid.trim();
      }
    } catch (_) {}

    return null;
  }

  String? _extractContractId(dynamic entry) {
    try {
      final direct = _dynString((entry as dynamic).contractId) ??
          _dynString((entry as dynamic).idContract) ??
          _dynString((entry as dynamic).contractRef);

      if (direct != null && direct.trim().isNotEmpty) {
        return direct.trim();
      }

      final path = (entry as dynamic).path ??
          (entry as dynamic).docPath ??
          (entry as dynamic).parentPath ??
          (entry as dynamic).fullPath ??
          (entry as dynamic).storagePath ??
          (entry as dynamic).measurementPath ??
          (entry as dynamic).recordPath;

      final fromPath = _parseContractIdFromPath(path?.toString());

      if (fromPath != null) {
        return fromPath;
      }

      final uidMaybePath = (entry as dynamic).uid?.toString();
      final fromUidPath = _parseContractIdFromPath(uidMaybePath);

      if (fromUidPath != null) {
        return fromUidPath;
      }
    } catch (_) {}

    return null;
  }

  Future<void> _preloadDfdLabels(Iterable<ContractData> base) async {
    final futures = <Future<void>>[];

    for (final contract in base) {
      final id = _idToString(contract.id);

      if (id == null || id.trim().isEmpty) {
        continue;
      }

      final precisaRodovia = !_roadNameByContract.containsKey(id);
      final precisaRegiao = !_regionByContract.containsKey(id);
      final precisaStatus = !_statusByContract.containsKey(id);
      final precisaNatureza = !_naturezaByContract.containsKey(id);
      final precisaVencedor = !_winnerByContract.containsKey(id);
      final precisaMunicipio = !_municipioByContract.containsKey(id);
      final precisaValor = !_valueByContract.containsKey(id);

      final precisaAlgoDeDfd = precisaRodovia ||
          precisaRegiao ||
          precisaStatus ||
          precisaNatureza ||
          precisaMunicipio ||
          precisaValor;

      final precisaAlgoDeEdital = precisaVencedor;

      final jaTentouDfd = _dfdCheckedContracts.contains(id);
      final jaTentouEdital = _editalCheckedContracts.contains(id);

      if (!precisaAlgoDeDfd && !precisaAlgoDeEdital) {
        continue;
      }

      futures.add(
            () async {
          if (precisaAlgoDeDfd && !jaTentouDfd) {
            _dfdCheckedContracts.add(id);

            try {
              final DfdData? dfd = await dfdCubit.getDataForContract(id);

              if (dfd != null) {
                if (precisaRodovia) {
                  final road = dfd.rodovia?.trim();

                  if (road != null && road.isNotEmpty) {
                    _roadNameByContract[id] = road;
                  }
                }

                if (precisaRegiao) {
                  final region = dfd.regional?.trim();

                  if (region != null && region.isNotEmpty) {
                    _regionByContract[id] = region;
                  }
                }

                if (precisaStatus) {
                  final status = dfd.statusDemanda?.trim();

                  if (status != null && status.isNotEmpty) {
                    _statusByContract[id] = status;
                  }
                }

                if (precisaNatureza) {
                  final natureza = dfd.naturezaIntervencao?.trim();

                  if (natureza != null && natureza.isNotEmpty) {
                    _naturezaByContract[id] = natureza;
                  }
                }

                if (precisaMunicipio) {
                  final municipio = dfd.municipio?.trim();

                  if (municipio != null && municipio.isNotEmpty) {
                    _municipioByContract[id] = municipio;
                  }
                }

                if (precisaValor) {
                  _valueByContract[id] = dfd.valorDemanda ?? 0.0;
                }
              }
            } catch (_) {}
          }

          if (precisaAlgoDeEdital && !jaTentouEdital) {
            _editalCheckedContracts.add(id);

            try {
              final EditalData? edital = await editalCubit.getDataForContract(
                id,
              );

              final winner = edital?.vencedor.trim();

              if (winner != null && winner.isNotEmpty) {
                _winnerByContract[id] = winner;
              }
            } catch (_) {}
          }
        }(),
      );
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  Map<String, String> get regionByMunicipio {
    final map = <String, String>{};

    for (final contract in state.allContracts) {
      final municipio = _getMunicipioLabel(contract).trim();
      final region = _getRegionLabel(contract).trim();

      if (municipio.isEmpty ||
          municipio.toUpperCase() == 'SEM MUNICÍPIO' ||
          region.isEmpty ||
          region.toUpperCase() == 'SEM REGIÃO') {
        continue;
      }

      map.putIfAbsent(
        municipio.toUpperCase(),
            () => region,
      );
    }

    return map;
  }

  String _getRoadLabel(ContractData contract) {
    final id = _idToString(contract.id);
    final cached = id == null ? null : _roadNameByContract[id];

    if (cached != null && cached.trim().isNotEmpty) {
      return cached.trim();
    }

    return 'SEM RODOVIA';
  }

  String _getRegionLabel(ContractData contract) {
    final id = _idToString(contract.id);
    final cached = id == null ? null : _regionByContract[id];

    if (cached != null && cached.trim().isNotEmpty) {
      return cached.trim();
    }

    return 'SEM REGIÃO';
  }

  String _getStatusLabel(ContractData contract) {
    final id = _idToString(contract.id);
    final cached = id == null ? null : _statusByContract[id];
    final value = (cached ?? '').trim();

    if (value.isNotEmpty) {
      return value;
    }

    return 'SEM STATUS';
  }

  String _getNatureLabel(ContractData contract) {
    final id = _idToString(contract.id);
    final cached = id == null ? null : _naturezaByContract[id];
    final value = (cached ?? '').trim();

    if (value.isNotEmpty) {
      return value;
    }

    return 'SEM NATUREZA';
  }

  String _getWinnerLabel(ContractData contract) {
    final id = _idToString(contract.id);
    final cached = id == null ? null : _winnerByContract[id];
    final value = (cached ?? '').trim();

    if (value.isNotEmpty) {
      return value;
    }

    return 'EM PROJETO';
  }

  String _getMunicipioLabel(ContractData contract) {
    final id = _idToString(contract.id);
    final cached = id == null ? null : _municipioByContract[id];
    final value = (cached ?? '').trim();

    if (value.isNotEmpty) {
      return value;
    }

    return 'SEM MUNICÍPIO';
  }

  double _getContractValue(ContractData contract) {
    final id = _idToString(contract.id);

    if (id == null) {
      return 0.0;
    }

    return _valueByContract[id] ?? 0.0;
  }

  List<String> _extractCompanies(List<ContractData> data) {
    final set = <String>{
      for (final contract in data)
        _getWinnerLabel(contract).trim().toUpperCase(),
    };

    final list = set.toList()..sort();

    return list;
  }

  bool get houveInteracaoComFiltros {
    return state.selectedStatus != null ||
        state.selectedCompany != null ||
        state.selectedRegions.isNotEmpty ||
        state.selectedRoad != null ||
        state.selectedMunicipio != null;
  }

  double? get totaisMedicoes => state.totalMedicoes;

  double? get totaisReajustes => state.totalReajustes;

  double? get totaisRevisoes => state.totalRevisoes;

  List<String> get municipiosSelecionadosParaMapa {
    final selected = state.selectedMunicipio;

    if (selected != null &&
        selected.trim().isNotEmpty &&
        selected.trim().toUpperCase() != 'SEM MUNICÍPIO') {
      return <String>[selected.trim()];
    }

    final set = <String>{};

    for (final contract in state.filteredContracts) {
      final municipio = _getMunicipioLabel(contract).trim();

      if (municipio.isEmpty) continue;
      if (municipio.toUpperCase() == 'SEM MUNICÍPIO') continue;

      set.add(municipio);
    }

    final list = set.toList()..sort();

    return list;
  }

  List<String> get municipiosComContratosGeral {
    final set = <String>{};

    for (final contract in state.allContracts) {
      final municipio = _getMunicipioLabel(contract).trim();

      if (municipio.isEmpty) continue;
      if (municipio.toUpperCase() == 'SEM MUNICÍPIO') continue;

      set.add(municipio);
    }

    final list = set.toList()..sort();

    return list;
  }

  Map<String, double> _somarMapas(List<Map<String, double>> maps) {
    final output = <String, double>{};

    for (final map in maps) {
      for (final entry in map.entries) {
        output[entry.key] = (output[entry.key] ?? 0.0) + entry.value;
      }
    }

    return output;
  }

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
        return _somarMapas(
          [
            state.totaisStatusIniciais,
            state.totaisStatusAditivos,
            state.totaisStatusApostilas,
          ],
        );
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
        return _somarMapas(
          [
            state.totaisStatusIniciaisFull,
            state.totaisStatusAditivosFull,
            state.totaisStatusApostilasFull,
          ],
        );
    }
  }

  List<String> get labelsStatusGeneralContracts {
    final entries = totaisStatusAtuaisFull.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.map((entry) => entry.key).toList();
  }

  List<double> get valuesStatusGeneralContractsFull {
    final labels = labelsStatusGeneralContracts;

    return labels.map((label) {
      return totaisStatusAtuaisFull[label] ?? 0.0;
    }).toList();
  }

  List<double> get valuesStatusGeneralContractsFiltered {
    final labels = labelsStatusGeneralContracts;

    return labels.map((label) {
      return totaisStatusAtuais[label] ?? 0.0;
    }).toList();
  }

  List<double> get valuesStatusGeneralContracts {
    return valuesStatusGeneralContractsFiltered;
  }

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
        return _somarMapas(
          [
            state.totaisRegiaoIniciais,
            state.totaisRegiaoAditivos,
            state.totaisRegiaoApostilas,
          ],
        );
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
        return _somarMapas(
          [
            state.totaisRegiaoIniciaisFull,
            state.totaisRegiaoAditivosFull,
            state.totaisRegiaoApostilasFull,
          ],
        );
    }
  }

  List<String> get labelsRegionOfMap {
    final keys = <String>{
      ...totaisRegiaoAtuaisFull.keys,
      ...totaisRegiaoAtuais.keys,
    };

    keys.removeWhere(
          (key) {
        final value = key.trim().toUpperCase();

        return value.isEmpty || value == 'SEM REGIÃO';
      },
    );

    final list = keys.toList()..sort();

    return list;
  }

  List<double?> get valuesRegionOfMapFull {
    return labelsRegionOfMap.map((region) {
      return totaisRegiaoAtuaisFull[region];
    }).toList();
  }

  List<double?> get valuesRegionOfMapFiltered {
    return labelsRegionOfMap.map((region) {
      return totaisRegiaoAtuais[region];
    }).toList();
  }

  List<double?> get valuesRegionOfMap {
    return valuesRegionOfMapFiltered;
  }

  List<Color> get barColorsRegion {
    return List<Color>.generate(
      labelsRegionOfMap.length,
          (index) {
        if (state.selectedRegionIndex != null &&
            state.selectedRegionIndex == index) {
          return Colors.orangeAccent;
        }

        return Colors.cyan;
      },
    );
  }

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
        return _somarMapas(
          [
            state.totaisEmpresaIniciais,
            state.totaisEmpresaAditivos,
            state.totaisEmpresaApostilas,
          ],
        );
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
        return _somarMapas(
          [
            state.totaisEmpresaIniciaisFull,
            state.totaisEmpresaAditivosFull,
            state.totaisEmpresaApostilasFull,
          ],
        );
    }
  }

  List<String> get labelsCompany {
    return state.uniqueCompanies;
  }

  List<double> get valuesCompanyFull {
    return state.uniqueCompanies.map((company) {
      return totaisEmpresaAtuaisFull[company] ?? 0.0;
    }).toList();
  }

  List<double> get valuesCompany {
    return state.uniqueCompanies.map((company) {
      return totaisEmpresaAtuais[company] ?? 0.0;
    }).toList();
  }

  List<Color> get barColorsEmpresa {
    return List<Color>.generate(
      state.uniqueCompanies.length,
          (index) {
        if (state.selectedCompanyIndex != null &&
            state.selectedCompanyIndex == index) {
          return Colors.orangeAccent;
        }

        return Colors.blueAccent;
      },
    );
  }

  List<String> get radarServiceLabels {
    final set = <String>{};

    for (final contract in state.allContracts) {
      final service = _getNatureLabel(contract);

      if (service != 'SEM NATUREZA') {
        set.add(service);
      }
    }

    final ordered = set.toList()..sort();

    return ordered;
  }

  double _valorRadarParaContrato(ContractData contract) {
    switch (state.tipoDeValorSelecionado) {
      case 'Valor contratado':
        return _getContractValue(contract);

      case 'Total em aditivos':
      case 'Total em apostilas':
        return 0.0;

      case 'Somatório total':
      default:
        return _getContractValue(contract);
    }
  }

  List<double> _sumRadarPorNatureza(
      List<ContractData> base,
      List<String> labels,
      ) {
    final map = <String, double>{
      for (final label in labels) label: 0.0,
    };

    for (final contract in base) {
      final value = _valorRadarParaContrato(contract);

      if (value == 0.0) continue;

      final natureza = _getNatureLabel(contract);

      if (natureza == 'SEM NATUREZA') continue;

      if (map.containsKey(natureza)) {
        map[natureza] = (map[natureza] ?? 0.0) + value;
      }
    }

    return labels.map((label) {
      return map[label] ?? 0.0;
    }).toList();
  }

  List<double> radarServiceValuesGeral() {
    final labels = radarServiceLabels;

    return _sumRadarPorNatureza(
      state.filteredContracts,
      labels,
    );
  }

  List<double> radarServiceValuesEmpresaSelecionada() {
    if (state.selectedCompany == null) {
      return const <double>[];
    }

    final labels = radarServiceLabels;
    final selectedCompany = state.selectedCompany!.toUpperCase();

    final base = state.filteredContracts.where((contract) {
      return _getWinnerLabel(contract).toUpperCase() == selectedCompany;
    }).toList();

    return _sumRadarPorNatureza(
      base,
      labels,
    );
  }

  List<double> radarServiceValuesRegiaoSelecionada() {
    if (state.selectedRegion == null && state.selectedRegions.isEmpty) {
      return const <double>[];
    }

    final labels = radarServiceLabels;

    final selectedRegion = (state.selectedRegion ??
        (state.selectedRegions.isNotEmpty
            ? state.selectedRegions.first
            : ''))
        .toUpperCase();

    if (selectedRegion.isEmpty) {
      return const <double>[];
    }

    final base = state.filteredContracts.where((contract) {
      return _getRegionLabel(contract).toUpperCase().contains(selectedRegion);
    }).toList();

    return _sumRadarPorNatureza(
      base,
      labels,
    );
  }

  List<RadarSeriesData> radarDatasetsServices({
    required Color primary,
    required Color warning,
    required Color success,
  }) {
    final labels = radarServiceLabels;

    if (labels.isEmpty) {
      return const <RadarSeriesData>[];
    }

    final geral = radarServiceValuesGeral();
    final empresa = radarServiceValuesEmpresaSelecionada();
    final regiao = radarServiceValuesRegiaoSelecionada();

    final raw = <RadarSeriesData>[
      RadarSeriesData(
        name: 'Geral',
        values: geral,
        color: primary,
      ),
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

    return raw.where((series) {
      return series.values.length == labels.length &&
          series.values.any((value) => value > 0);
    }).toList(growable: false);
  }

  List<TreemapItem> get treemapRodovias {
    final ordered = state.totaisRodoviaFull.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    var index = 0;

    return ordered.map((entry) {
      final color =
      TreemapStyle.tradeMapColors[index % TreemapStyle.tradeMapColors.length];

      index++;

      return TreemapItem(
        label: entry.key,
        value: entry.value,
        color: color,
      );
    }).toList(growable: false);
  }

  List<double?> get treemapRodoviasFilteredValues {
    final ordered = state.totaisRodoviaFull.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ordered.map((entry) {
      return state.totaisRodoviaFiltrado[entry.key] ?? 0.0;
    }).toList();
  }

  Future<void> initialize() async {
    emit(
      state.copyWith(
        isLoading: true,
        initialized: false,
      ),
    );

    try {
      final allContracts = await _waitContractsFromProcessCubit();

      if (isClosed) return;

      await _preloadDfdLabels(allContracts);

      if (isClosed) return;

      final uniqueCompanies = _extractCompanies(allContracts);

      emit(
        state.copyWith(
          allContracts: allContracts,
          filteredContracts: allContracts,
          uniqueCompanies: uniqueCompanies,
          selectedYear: DateTime.now().year,
        ),
      );

      await _reloadMeasurementGroups();

      if (isClosed) return;

      await aplicarFiltrosERecalcular();

      if (isClosed) return;

      emit(
        state.copyWith(
          initialized: true,
          isLoading: false,
        ),
      );
    } catch (_) {
      if (isClosed) return;

      emit(
        state.copyWith(
          initialized: true,
          isLoading: false,
        ),
      );
    }
  }

  Future<void> refreshAndRecalc() async {
    emit(
      state.copyWith(
        isLoading: true,
      ),
    );

    try {
      await _reloadMeasurementGroups();

      if (isClosed) return;

      await aplicarFiltrosERecalcular();

      if (isClosed) return;

      emit(
        state.copyWith(
          isLoading: false,
          initialized: true,
        ),
      );
    } catch (_) {
      if (isClosed) return;

      emit(
        state.copyWith(
          isLoading: false,
          initialized: true,
        ),
      );
    }
  }

  Future<void> onHotReload() {
    return refreshAndRecalc();
  }

  Future<void> _reloadMeasurementGroups() async {
    List<ReportExecutedData> allMeasurements = const <ReportExecutedData>[];
    List<AdjustmentMeasurementData> allAdjustments =
    const <AdjustmentMeasurementData>[];
    List<RevisionMeasurementData> allRevisions =
    const <RevisionMeasurementData>[];

    try {
      allMeasurements =
      await reportMeasurementCubit.getAllMeasurementsCollectionGroup();
    } catch (_) {}

    try {
      allAdjustments =
      await adjustmentMeasurementCubit.getAllAdjustmentsCollectionGroup();
    } catch (_) {}

    try {
      allRevisions =
      await revisionMeasurementCubit.getAllRevisionsCollectionGroup();
    } catch (_) {}

    if (isClosed) return;

    emit(
      state.copyWith(
        allMeasurements: allMeasurements,
        allAdjustments: allAdjustments,
        allRevisions: allRevisions,
      ),
    );
  }

  Future<void> onStatusSelected(String? status) async {
    final selected = status?.trim();

    final same = (state.selectedStatus ?? '').toUpperCase() ==
        (selected ?? '').toUpperCase();

    if (selected == null || selected.isEmpty || same) {
      emit(
        state.copyWith(
          selectedStatus: null,
          selectedCompany: null,
          selectedCompanyIndex: null,
          selectedRegion: null,
          selectedRegionIndex: null,
          selectedRegions: const <String>[],
          selectedRoad: null,
          selectedMunicipio: null,
        ),
      );
    } else {
      final selectedUpper = selected.toUpperCase();

      final regions = _allContractsFromProcessCubit
          .where((contract) {
        return _getStatusLabel(contract).toUpperCase() == selectedUpper;
      })
          .map((contract) => _getRegionLabel(contract).toUpperCase())
          .where((region) {
        return region.isNotEmpty && region != 'SEM REGIÃO';
      })
          .toSet()
          .toList();

      emit(
        state.copyWith(
          selectedStatus: selected,
          selectedCompany: null,
          selectedCompanyIndex: null,
          selectedRegion: null,
          selectedRegionIndex: null,
          selectedRegions: regions,
          selectedRoad: null,
          selectedMunicipio: null,
        ),
      );
    }

    await aplicarFiltrosERecalcular();
  }

  Future<void> onCompanySelected(String company) async {
    final cleanCompany = company.trim();

    if (cleanCompany.isEmpty) {
      return;
    }

    final index = state.uniqueCompanies.indexWhere((item) {
      return item.toUpperCase() == cleanCompany.toUpperCase();
    });

    if (index >= 0) {
      await onCompanyIndexSelected(index);
      return;
    }

    final isSame =
        (state.selectedCompany ?? '').toUpperCase() == cleanCompany.toUpperCase();

    if (isSame) {
      emit(
        state.copyWith(
          selectedCompany: null,
          selectedCompanyIndex: null,
          selectedRegions: const <String>[],
          selectedMunicipio: null,
        ),
      );
    } else {
      final contracts = _allContractsFromProcessCubit.where((contract) {
        return _getWinnerLabel(contract).toUpperCase() ==
            cleanCompany.toUpperCase();
      });

      final regions = contracts
          .map((contract) => _getRegionLabel(contract).toUpperCase())
          .where((region) {
        return region.isNotEmpty && region != 'SEM REGIÃO';
      })
          .toSet()
          .toList();

      emit(
        state.copyWith(
          selectedCompany: cleanCompany,
          selectedCompanyIndex: null,
          selectedRegions: regions,
          selectedStatus: null,
          selectedRegion: null,
          selectedRegionIndex: null,
          selectedRoad: null,
          selectedMunicipio: null,
        ),
      );
    }

    await aplicarFiltrosERecalcular();
  }

  Future<void> onCompanyIndexSelected(int? index) async {
    if (index == null || state.selectedCompanyIndex == index) {
      emit(
        state.copyWith(
          selectedCompany: null,
          selectedCompanyIndex: null,
          selectedRegions: const <String>[],
          selectedStatus: null,
          selectedRegion: null,
          selectedRegionIndex: null,
          selectedRoad: null,
          selectedMunicipio: null,
        ),
      );

      await aplicarFiltrosERecalcular();
      return;
    }

    if (index < 0 || index >= state.uniqueCompanies.length) {
      return;
    }

    final company = state.uniqueCompanies[index];

    final contracts = _allContractsFromProcessCubit.where((contract) {
      return _getWinnerLabel(contract).toUpperCase() == company.toUpperCase();
    });

    final regions = contracts
        .map((contract) => _getRegionLabel(contract).toUpperCase())
        .where((region) {
      return region.isNotEmpty && region != 'SEM REGIÃO';
    })
        .toSet()
        .toList();

    emit(
      state.copyWith(
        selectedCompany: company,
        selectedCompanyIndex: index,
        selectedRegions: regions,
        selectedStatus: null,
        selectedRegion: null,
        selectedRegionIndex: null,
        selectedRoad: null,
        selectedMunicipio: null,
      ),
    );

    await aplicarFiltrosERecalcular();
  }

  Future<void> onRegionSelected(String? region) async {
    final cleanRegion = region?.trim();

    if (cleanRegion == null || cleanRegion.isEmpty) {
      await onRegionIndexSelected(null);
      return;
    }

    final index = labelsRegionOfMap.indexWhere((item) {
      return item.toUpperCase() == cleanRegion.toUpperCase();
    });

    if (index >= 0) {
      await onRegionIndexSelected(index);
      return;
    }

    final same = state.selectedRegions.contains(cleanRegion.toUpperCase());

    if (same) {
      emit(
        state.copyWith(
          selectedRegion: null,
          selectedRegions: const <String>[],
          selectedRegionIndex: null,
          selectedMunicipio: null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          selectedRegion: cleanRegion,
          selectedRegions: <String>[cleanRegion.toUpperCase()],
          selectedRegionIndex: null,
          selectedMunicipio: null,
        ),
      );
    }

    await aplicarFiltrosERecalcular();
  }

  Future<void> onRegionIndexSelected(int? index) async {
    if (index == null || state.selectedRegionIndex == index) {
      emit(
        state.copyWith(
          selectedRegion: null,
          selectedRegions: const <String>[],
          selectedRegionIndex: null,
          selectedMunicipio: null,
        ),
      );

      await aplicarFiltrosERecalcular();
      return;
    }

    if (index < 0 || index >= labelsRegionOfMap.length) {
      return;
    }

    final region = labelsRegionOfMap[index];

    emit(
      state.copyWith(
        selectedRegion: region,
        selectedRegions: <String>[region.toUpperCase()],
        selectedRegionIndex: index,
        selectedMunicipio: null,
      ),
    );

    await aplicarFiltrosERecalcular();
  }

  Future<void> onRoadSelected(String? roadLabel) async {
    final selected = roadLabel?.trim();

    final same =
        (state.selectedRoad ?? '').toUpperCase() == (selected ?? '').toUpperCase();

    if (selected == null || selected.isEmpty || same) {
      emit(
        state.copyWith(
          selectedRoad: null,
          selectedRegions: const <String>[],
          selectedRegion: null,
          selectedRegionIndex: null,
          selectedStatus: null,
          selectedCompany: null,
          selectedCompanyIndex: null,
          selectedMunicipio: null,
        ),
      );
    } else {
      final regions = _allContractsFromProcessCubit
          .where((contract) {
        return _getRoadLabel(contract).toUpperCase() == selected.toUpperCase();
      })
          .map((contract) => _getRegionLabel(contract).toUpperCase())
          .where((region) {
        return region.isNotEmpty && region != 'SEM REGIÃO';
      })
          .toSet()
          .toList();

      emit(
        state.copyWith(
          selectedRoad: selected,
          selectedRegions: regions,
          selectedStatus: null,
          selectedCompany: null,
          selectedCompanyIndex: null,
          selectedRegion: null,
          selectedRegionIndex: null,
          selectedMunicipio: null,
        ),
      );
    }

    await aplicarFiltrosERecalcular();
  }

  Future<void> onMunicipioSelected(String? municipio) async {
    final selected = municipio?.trim();

    final same = (state.selectedMunicipio ?? '').toUpperCase() ==
        (selected ?? '').toUpperCase();

    if (selected == null || selected.isEmpty || same) {
      emit(
        state.copyWith(
          selectedMunicipio: null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          selectedMunicipio: selected,
          selectedStatus: null,
          selectedCompany: null,
          selectedCompanyIndex: null,
          selectedRegion: null,
          selectedRegionIndex: null,
          selectedRegions: const <String>[],
          selectedRoad: null,
        ),
      );
    }

    await aplicarFiltrosERecalcular();
  }

  Future<void> limparSelecoes() async {
    emit(
      state.copyWith(
        selectedStatus: null,
        selectedCompany: null,
        selectedCompanyIndex: null,
        selectedRegion: null,
        selectedRegionIndex: null,
        selectedRegions: const <String>[],
        selectedRoad: null,
        selectedMunicipio: null,
      ),
    );

    await aplicarFiltrosERecalcular();
  }

  void onTipoDeValorSelecionado(String novoTipo) {
    emit(
      state.copyWith(
        tipoDeValorSelecionado: novoTipo,
      ),
    );
  }

  void updateSelectedYearMonth(int? year, int? month) {
    emit(
      state.copyWith(
        selectedYear: year,
        selectedMonth: month,
      ),
    );
  }

  List<ContractData> _filterContracts(List<ContractData> base) {
    final selectedStatus = state.selectedStatus?.toUpperCase();
    final selectedCompany = state.selectedCompany?.toUpperCase();
    final selectedRoad = state.selectedRoad?.toUpperCase();
    final selectedMunicipio = state.selectedMunicipio?.toUpperCase();

    final regionsUpper = state.selectedRegions.map((region) {
      return region.toUpperCase();
    }).toList();

    return base.where((contract) {
      final region = _getRegionLabel(contract).toUpperCase();
      final company = _getWinnerLabel(contract).toUpperCase();
      final status = _getStatusLabel(contract).toUpperCase();
      final road = _getRoadLabel(contract).toUpperCase();
      final municipio = _getMunicipioLabel(contract).toUpperCase();

      final matchCompany =
          selectedCompany == null || company == selectedCompany;

      final matchRegion = state.selectedRegions.isEmpty ||
          regionsUpper.any((selectedRegion) {
            return region.contains(selectedRegion);
          });

      final matchStatus = selectedStatus == null || status == selectedStatus;

      final matchRoad = selectedRoad == null || road == selectedRoad;

      final matchMunicipio =
          selectedMunicipio == null || municipio == selectedMunicipio;

      return matchCompany &&
          matchRegion &&
          matchStatus &&
          matchRoad &&
          matchMunicipio;
    }).toList();
  }

  Future<void> aplicarFiltrosERecalcular() async {
    final runId = ++_applyRunId;

    try {
      final allContracts = state.allContracts.isEmpty
          ? _allContractsFromProcessCubit
          : state.allContracts;

      final allMeasurements = state.allMeasurements;
      final allAdjustments = state.allAdjustments;
      final allRevisions = state.allRevisions;

      await _preloadDfdLabels(allContracts);

      if (isClosed || runId != _applyRunId) return;

      final filtered = _filterContracts(allContracts);

      final statusIni = <String, double>{};
      final empIni = <String, double>{};
      final regIni = <String, double>{};

      for (final contract in filtered) {
        final status = _getStatusLabel(contract);
        final empresa = _getWinnerLabel(contract);
        final regiao = _getRegionLabel(contract);
        final valor = _getContractValue(contract);

        statusIni[status] = (statusIni[status] ?? 0.0) + valor;
        empIni[empresa] = (empIni[empresa] ?? 0.0) + valor;
        regIni[regiao] = (regIni[regiao] ?? 0.0) + valor;
      }

      final allIds = <String>{
        for (final contract in allContracts)
          if (_idToString(contract.id) != null) _idToString(contract.id)!,
      };

      final filteredIds = <String>{
        for (final contract in filtered)
          if (_idToString(contract.id) != null) _idToString(contract.id)!,
      };

      final byIdAllContracts = <String, ContractData>{
        for (final contract in allContracts)
          if (_idToString(contract.id) != null)
            _idToString(contract.id)!: contract,
      };

      final allAdditives = allIds.isNotEmpty
          ? await additivesRepository.getAdditivesByContractIds(allIds)
          : <AdditivesData>[];

      if (isClosed || runId != _applyRunId) return;

      final allApostilles = allIds.isNotEmpty
          ? await apostillesRepository.getApostillesByContractIds(allIds)
          : <ApostillesData>[];

      if (isClosed || runId != _applyRunId) return;

      final regIniFull = <String, double>{};
      final empIniFull = <String, double>{};
      final statusIniFull = <String, double>{};

      for (final contract in allContracts) {
        final regiao = _getRegionLabel(contract);
        final empresa = _getWinnerLabel(contract);
        final status = _getStatusLabel(contract);
        final valor = _getContractValue(contract);

        regIniFull[regiao] = (regIniFull[regiao] ?? 0.0) + valor;
        empIniFull[empresa] = (empIniFull[empresa] ?? 0.0) + valor;
        statusIniFull[status] = (statusIniFull[status] ?? 0.0) + valor;
      }

      final regAdFull = <String, double>{};
      final regApFull = <String, double>{};

      final empAdFull = <String, double>{};
      final empApFull = <String, double>{};

      final statusAdFull = <String, double>{};
      final statusApFull = <String, double>{};

      final statusAd = <String, double>{};
      final empAd = <String, double>{};
      final regAd = <String, double>{};

      final statusAp = <String, double>{};
      final empAp = <String, double>{};
      final regAp = <String, double>{};

      for (final additive in allAdditives) {
        final contractId = _idToString(additive.contractId);

        if (contractId == null) continue;

        final contract = byIdAllContracts[contractId];

        if (contract == null) continue;

        final regiao = _getRegionLabel(contract);
        final empresa = _getWinnerLabel(contract);
        final status = _getStatusLabel(contract);
        final valor = additive.additiveValue ?? 0.0;

        regAdFull[regiao] = (regAdFull[regiao] ?? 0.0) + valor;
        empAdFull[empresa] = (empAdFull[empresa] ?? 0.0) + valor;
        statusAdFull[status] = (statusAdFull[status] ?? 0.0) + valor;

        if (filteredIds.contains(contractId)) {
          regAd[regiao] = (regAd[regiao] ?? 0.0) + valor;
          empAd[empresa] = (empAd[empresa] ?? 0.0) + valor;
          statusAd[status] = (statusAd[status] ?? 0.0) + valor;
        }
      }

      for (final apostille in allApostilles) {
        final contractId = _idToString(apostille.contractId);

        if (contractId == null) continue;

        final contract = byIdAllContracts[contractId];

        if (contract == null) continue;

        final regiao = _getRegionLabel(contract);
        final empresa = _getWinnerLabel(contract);
        final status = _getStatusLabel(contract);
        final valor = apostille.apostilleValue ?? 0.0;

        regApFull[regiao] = (regApFull[regiao] ?? 0.0) + valor;
        empApFull[empresa] = (empApFull[empresa] ?? 0.0) + valor;
        statusApFull[status] = (statusApFull[status] ?? 0.0) + valor;

        if (filteredIds.contains(contractId)) {
          regAp[regiao] = (regAp[regiao] ?? 0.0) + valor;
          empAp[empresa] = (empAp[empresa] ?? 0.0) + valor;
          statusAp[status] = (statusAp[status] ?? 0.0) + valor;
        }
      }

      final rodFull = <String, double>{};

      for (final contract in allContracts) {
        final rodovia = _getRoadLabel(contract);

        if (rodovia.isEmpty || rodovia == 'SEM RODOVIA') continue;

        final valor = _valorRadarParaContrato(contract);

        if (valor == 0.0) continue;

        rodFull[rodovia] = (rodFull[rodovia] ?? 0.0) + valor;
      }

      final rodFiltrado = <String, double>{};

      for (final contract in filtered) {
        final rodovia = _getRoadLabel(contract);

        if (rodovia.isEmpty || rodovia == 'SEM RODOVIA') continue;

        final valor = _valorRadarParaContrato(contract);

        if (valor == 0.0) continue;

        rodFiltrado[rodovia] = (rodFiltrado[rodovia] ?? 0.0) + valor;
      }

      final filteredMeasurements = allMeasurements.where((measurement) {
        final contractId = _extractContractId(measurement);

        return contractId != null && filteredIds.contains(contractId);
      }).toList();

      final totalMedicoes = reportMeasurementCubit.sum(filteredMeasurements);

      final filteredAdjustments = allAdjustments.where((adjustment) {
        final contractId = _extractContractId(adjustment);

        return contractId != null && filteredIds.contains(contractId);
      }).toList();

      final totalReajustes = adjustmentMeasurementCubit.sum(filteredAdjustments);

      final filteredRevisions = allRevisions.where((revision) {
        final contractId = _extractContractId(revision);

        return contractId != null && filteredIds.contains(contractId);
      }).toList();

      final totalRevisoes = revisionMeasurementCubit.sum(filteredRevisions);

      final uniqueCompanies = _extractCompanies(allContracts);

      if (isClosed || runId != _applyRunId) return;

      emit(
        state.copyWith(
          allContracts: allContracts,
          filteredContracts: filtered,
          allMeasurements: allMeasurements,
          allAdjustments: allAdjustments,
          allRevisions: allRevisions,
          uniqueCompanies: uniqueCompanies,
          totaisStatusIniciais: statusIni,
          totaisStatusAditivos: statusAd,
          totaisStatusApostilas: statusAp,
          totaisRegiaoIniciais: regIni,
          totaisRegiaoAditivos: regAd,
          totaisRegiaoApostilas: regAp,
          totaisEmpresaIniciais: empIni,
          totaisEmpresaAditivos: empAd,
          totaisEmpresaApostilas: empAp,
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
        ),
      );
    } catch (_) {
      if (isClosed || runId != _applyRunId) return;

      emit(
        state.copyWith(
          initialized: true,
          isLoading: false,
        ),
      );
    }
  }
}