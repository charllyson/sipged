import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sipged/_blocs/panels/general_dashboard/general_dashboard_style.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_state.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/5Edital/edital_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/5Edital/edital_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart';
import 'package:sipged/_blocs/system/permitions/contract_permission.dart';
import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_widgets/buttons/contract_add_button.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/search/search_widget.dart';
import 'package:sipged/_widgets/user/user_greeting.dart';
import 'package:sipged/screens/modules/contracts/hiring/tab_bar_hiring_page.dart';

import 'list_demand_status.dart';

typedef DemandNavigationCallback = void Function(
    BuildContext context,
    ProcessData contract,
    );

class ListDemandPage extends StatefulWidget {
  const ListDemandPage({
    super.key,
    required this.onTapItem,
    this.pageTitle = '',
  });

  final DemandNavigationCallback onTapItem;
  final String pageTitle;

  @override
  State<ListDemandPage> createState() => _ListDemandPageState();
}

class _ListDemandPageState extends State<ListDemandPage> {
  static const String _prefsExpandedKey = 'contracts_expanded_keys';

  final TextEditingController _statusCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = false;
  int? _sortColumnIndex;
  bool _isAscending = true;
  bool _didScheduleInitialLoad = false;

  final Map<String, List<ProcessData>> _cachedByStatus =
  <String, List<ProcessData>>{};
  final Set<String> _expandedKeys = <String>{};
  Set<String> _preSearchExpandedSnapshot = <String>{};

  Timer? _debounce;

  final Map<String, DfdData?> _dfdByContractId = <String, DfdData?>{};
  final Map<String, EditalData?> _editalByContractId = <String, EditalData?>{};
  final Map<String, PublicacaoExtratoData?> _pubByContractId =
  <String, PublicacaoExtratoData?>{};

  String _norm(String value) => value.trim().toUpperCase();

  @override
  void initState() {
    super.initState();
    _loadExpandedFromPrefs();
  }

  @override
  void dispose() {
    _statusCtrl.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadExpandedFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = (prefs.getStringList(_prefsExpandedKey) ?? const <String>[])
          .map(_norm)
          .toSet();

      if (!mounted) return;

      setState(() {
        _expandedKeys
          ..clear()
          ..addAll(saved);
      });
    } catch (_) {}
  }

  Future<void> _saveExpandedToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsExpandedKey, _expandedKeys.toList());
    } catch (_) {}
  }

  String? _idToString(Object? id) {
    if (id == null) return null;
    if (id is String) return id;
    return id.toString();
  }

  bool _isExpanded(String key) => _expandedKeys.contains(_norm(key));

  Future<void> _setExpanded(String key, bool open) async {
    final normalizedKey = _norm(key);

    setState(() {
      if (open) {
        _expandedKeys.add(normalizedKey);
      } else {
        _expandedKeys.remove(normalizedKey);
      }
    });

    await _saveExpandedToPrefs();
  }

  void _handleSort(int columnIndex) {
    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _isAscending = !_isAscending;
      } else {
        _sortColumnIndex = columnIndex;
        _isAscending = true;
      }

      _applyLocalSortIfAny();
    });
  }

  void _onSearchChanged(ProcessCubit cubit, String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;

      if (_searchCtrl.text != value) {
        _searchCtrl.text = value;
      }

      await _applyFilters(cubit);
    });
  }

  Future<void> _refresh(ProcessCubit cubit, UserData currentUser) async {
    setState(() => _loading = true);

    try {
      await cubit.refresh(currentUser: currentUser);
      _dfdByContractId.clear();
      _editalByContractId.clear();
      _pubByContractId.clear();

      await _applyFilters(cubit);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _statusKeyFromDfd(DfdData? dfd) {
    final raw = dfd?.statusDemanda ?? '';
    final normalized = raw.trim().toUpperCase();
    return normalized.isEmpty ? 'EM PROJETO' : normalized;
  }

  Future<void> _ensureDemandDataLoadedForContracts(Set<String> ids) async {
    if (ids.isEmpty) return;

    final dfdCubit = context.read<DfdCubit>();
    final editalCubit = context.read<EditalCubit>();
    final publicacaoCubit = context.read<PublicacaoExtratoCubit>();

    final List<Future<void>> futures = <Future<void>>[];

    for (final id in ids) {
      if (id.isEmpty) continue;

      if (!_dfdByContractId.containsKey(id)) {
        futures.add(
          dfdCubit.getDataForContract(id).then((dfd) {
            _dfdByContractId[id] = dfd;
          }),
        );
      }

      if (!_editalByContractId.containsKey(id)) {
        futures.add(
          editalCubit.getDataForContract(id).then((edital) {
            _editalByContractId[id] = edital;
          }),
        );
      }

      if (!_pubByContractId.containsKey(id)) {
        futures.add(
          publicacaoCubit.getDataForContract(id).then((pub) {
            _pubByContractId[id] = pub;
          }),
        );
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  void _applyLocalSortIfAny() {
    if (_sortColumnIndex == null) return;

    int compare(ProcessData a, ProcessData b) {
      final idA = _idToString(a.id);
      final idB = _idToString(b.id);

      switch (_sortColumnIndex) {
        case 1:
          final aVal = (_pubByContractId[idA]?.numeroContrato ?? '').toUpperCase();
          final bVal = (_pubByContractId[idB]?.numeroContrato ?? '').toUpperCase();
          return aVal.compareTo(bVal);

        case 2:
          final aVal = (_dfdByContractId[idA]?.descricaoObjeto ?? '').toUpperCase();
          final bVal = (_dfdByContractId[idB]?.descricaoObjeto ?? '').toUpperCase();
          return aVal.compareTo(bVal);

        case 3:
          final aVal = (_dfdByContractId[idA]?.regional ?? '').toUpperCase();
          final bVal = (_dfdByContractId[idB]?.regional ?? '').toUpperCase();
          return aVal.compareTo(bVal);

        case 4:
          final aVal = (_editalByContractId[idA]?.vencedor ?? '').toUpperCase();
          final bVal = (_editalByContractId[idB]?.vencedor ?? '').toUpperCase();
          return aVal.compareTo(bVal);

        case 5:
          final aVal =
          (_dfdByContractId[idA]?.processoAdministrativo ?? '').toUpperCase();
          final bVal =
          (_dfdByContractId[idB]?.processoAdministrativo ?? '').toUpperCase();
          return aVal.compareTo(bVal);

        default:
          return 0;
      }
    }

    for (final entry in _cachedByStatus.entries) {
      entry.value.sort((a, b) => _isAscending ? compare(a, b) : compare(b, a));
    }
  }

  Future<void> _applyFilters(ProcessCubit cubit) async {
    setState(() => _loading = true);

    try {
      final statusFiltro =
      _statusCtrl.text.isNotEmpty ? _statusCtrl.text.trim() : null;
      final search =
      _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim();

      final currentUser = context.read<UserCubit>().state.current;
      if (currentUser == null) return;

      final List<ProcessData> baseAll = cubit.state.allProcesses;

      final List<ProcessData> base = ContractPermissions.filterVisible(
        user: currentUser,
        contracts: baseAll,
      );

      final Set<String> ids = <String>{
        for (final contract in base)
          if (_idToString(contract.id) != null) _idToString(contract.id)!,
      };

      await _ensureDemandDataLoadedForContracts(ids);

      Iterable<ProcessData> filtered = base;

      if (statusFiltro != null && statusFiltro.isNotEmpty) {
        final alvo = statusFiltro.toUpperCase();

        filtered = filtered.where((contract) {
          final id = _idToString(contract.id);
          if (id == null) return false;

          final dfd = _dfdByContractId[id];
          final statusKey = _statusKeyFromDfd(dfd);
          return statusKey == alvo;
        });
      }

      if (search != null && search.isNotEmpty) {
        final searchUpper = search.toUpperCase();

        filtered = filtered.where((contract) {
          final id = _idToString(contract.id);
          if (id == null) return false;

          final dfd = _dfdByContractId[id];
          final edital = _editalByContractId[id];
          final pub = _pubByContractId[id];

          final objeto = (dfd?.descricaoObjeto ?? '').toUpperCase();
          final processo = (dfd?.processoAdministrativo ?? '').toUpperCase();
          final numeroContrato = (pub?.numeroContrato ?? '').toUpperCase();
          final vencedor = (edital?.vencedor ?? '').toUpperCase();

          return objeto.contains(searchUpper) ||
              processo.contains(searchUpper) ||
              numeroContrato.contains(searchUpper) ||
              vencedor.contains(searchUpper);
        });
      }

      final List<ProcessData> list = filtered.toList(growable: false);

      _cachedByStatus.clear();

      for (final contract in list) {
        final id = _idToString(contract.id);
        final dfd = id != null ? _dfdByContractId[id] : null;
        final statusKey = _statusKeyFromDfd(dfd);
        final normalizedStatus = _norm(statusKey);

        _cachedByStatus
            .putIfAbsent(normalizedStatus, () => <ProcessData>[])
            .add(contract);
      }

      _applyLocalSortIfAny();

      final hasSearch = _searchCtrl.text.trim().isNotEmpty;

      if (hasSearch) {
        if (_preSearchExpandedSnapshot.isEmpty) {
          _preSearchExpandedSnapshot = Set<String>.from(_expandedKeys);
        }

        final expandedNow = _cachedByStatus.entries
            .where((entry) => entry.value.isNotEmpty)
            .map((entry) => entry.key)
            .toSet();

        setState(() {
          _expandedKeys
            ..clear()
            ..addAll(expandedNow);
        });

        await _saveExpandedToPrefs();
      } else {
        if (_preSearchExpandedSnapshot.isNotEmpty) {
          setState(() {
            _expandedKeys
              ..clear()
              ..addAll(_preSearchExpandedSnapshot);
            _preSearchExpandedSnapshot = <String>{};
          });

          await _saveExpandedToPrefs();
        }

        setState(() {
          _expandedKeys.removeWhere(
                (key) =>
            _cachedByStatus.containsKey(key) &&
                (_cachedByStatus[key]?.isEmpty ?? true),
          );
        });

        await _saveExpandedToPrefs();
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ProcessCubit cubit = context.read<ProcessCubit>();
    final fb_auth.User? firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;

    final UserData? currentUser =
    context.select<UserCubit, UserData?>((cubit) => cubit.state.current);

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return BlocBuilder<ProcessCubit, ProcessState>(
      builder: (context, processState) {
        if (!_didScheduleInitialLoad && !_loading && _cachedByStatus.isEmpty) {
          _didScheduleInitialLoad = true;

          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;

            if (processState.allProcesses.isEmpty && !processState.loading) {
              await cubit.refresh(currentUser: currentUser);
            }

            if (!mounted) return;
            await _applyFilters(cubit);
          });
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              const BackgroundChange(),
              SafeArea(
                top: false,
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UpBar(
                      includeSafeTop: true,
                      actions: [
                        SearchAction(
                          onSearch: (text) => _onSearchChanged(cubit, text),
                        ),
                        UserGreeting(firebaseUser: firebaseUser),
                      ],
                      titleWidgets: [
                        Text(widget.pageTitle),
                      ],
                    ),
                    Expanded(
                      child: _loading && _cachedByStatus.isEmpty
                          ? const Center(
                        child: CircularProgressIndicator(),
                      )
                          : LayoutBuilder(
                        builder: (context, constraints) {
                          return ListView(
                            children: GeneralDashboardStyle.statusMenu
                                .map((status) {
                              final label = status.$1;
                              final rawKey = status.$2;
                              final normalizedKey = _norm(rawKey);
                              final items =
                                  _cachedByStatus[normalizedKey] ??
                                      const <ProcessData>[];

                              return ListDemandStatus(
                                title: label,
                                statusKey: normalizedKey,
                                items: items,
                                constraints: constraints,
                                sortColumnIndex: _sortColumnIndex,
                                isAscending: _isAscending,
                                onSort: (index, _) => _handleSort(index),
                                onDelete: (item) async {
                                  if ((item.id ?? '').isNotEmpty) {
                                    await cubit.delete(item.id!);
                                    await _refresh(cubit, currentUser);
                                  }
                                },
                                onTapItem: widget.onTapItem,
                                initiallyExpanded:
                                _isExpanded(normalizedKey),
                                onExpansionChanged: (open) =>
                                    _setExpanded(normalizedKey, open),
                                dfdByContractId: _dfdByContractId,
                                editalByContractId: _editalByContractId,
                                pubByContractId: _pubByContractId,
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: DemandAddButton(
            isEditable: ContractPermissions.isSuperUser(currentUser),
            onAdd: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TabBarHingPage(
                    key: UniqueKey(),
                    contractData: ProcessData.empty(),
                  ),
                ),
              );

              if (result == true) {
                await _refresh(cubit, currentUser);
              }
            },
          ),
        );
      },
    );
  }
}

class TabBarHingPage extends TabBarHiringPage {
  const TabBarHingPage({
    super.key,
    required super.contractData,
  });
}