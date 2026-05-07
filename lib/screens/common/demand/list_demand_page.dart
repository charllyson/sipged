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

import 'package:sipged/_blocs/system/module/module_catalog.dart';
import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_resolver.dart';
import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/_widgets/buttons/expanded_button_change.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/map/search/search_widget.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

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

  final Map<String, List<ProcessData>> _cachedByStatus =
  <String, List<ProcessData>>{};

  final Map<String, DfdData?> _dfdByContractId = <String, DfdData?>{};
  final Map<String, EditalData?> _editalByContractId =
  <String, EditalData?>{};
  final Map<String, PublicacaoExtratoData?> _pubByContractId =
  <String, PublicacaoExtratoData?>{};

  final Set<String> _expandedKeys = <String>{};

  Set<String> _preSearchExpandedSnapshot = <String>{};

  Timer? _debounce;

  bool _loading = false;
  bool _didScheduleInitialLoad = false;

  int? _sortColumnIndex;
  bool _isAscending = true;

  String _norm(String value) {
    return value.trim().toUpperCase();
  }

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
          .where((value) => value.isNotEmpty)
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

      await prefs.setStringList(
        _prefsExpandedKey,
        _expandedKeys.toList(growable: false),
      );
    } catch (_) {}
  }

  String? _idToString(Object? id) {
    if (id == null) return null;

    final value = id.toString().trim();

    if (value.isEmpty) return null;

    return value;
  }

  bool _isExpanded(String key) {
    return _expandedKeys.contains(_norm(key));
  }

  Future<void> _setExpanded(String key, bool open) async {
    if (!mounted) return;

    final normalizedKey = _norm(key);

    if (normalizedKey.isEmpty) return;

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

  Future<void> _refresh({
    required ProcessCubit cubit,
    required UserData currentUser,
  }) async {
    if (!mounted) return;

    setState(() {
      _loading = true;
    });

    try {
      final permissionCubit = context.read<PermissionCubit>();
      final permissionState = permissionCubit.state;

      final permissions = PermissionResolver.resolveForUser(
        user: currentUser,
        permissionState: permissionState,
      );

      final tenantId = PermissionResolver.cleanTenantId(
        permissionState.activeTenantId,
      );

      await cubit.refresh(
        currentUser: currentUser,
        currentPermissions: permissions,
        tenantId: tenantId,
      );

      _clearDemandCaches();

      await _applyFilters(cubit);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _clearDemandCaches() {
    _dfdByContractId.clear();
    _editalByContractId.clear();
    _pubByContractId.clear();
  }

  String _statusKeyFromDfd(DfdData? dfd) {
    final raw = dfd?.statusDemanda ?? '';
    final normalized = raw.trim().toUpperCase();

    return normalized.isEmpty ? 'EM PROJETO' : normalized;
  }

  Future<void> _ensurePermissionLoaded({
    required PermissionCubit permissionCubit,
    required UserData currentUser,
  }) async {
    final uid = currentUser.uid?.trim();

    if (uid == null || uid.isEmpty) return;

    final currentPermissions = permissionCubit.state.current;

    if (currentPermissions != null && currentPermissions.uid.trim() == uid) {
      return;
    }

    await permissionCubit.loadByUid(uid);
  }

  Future<void> _ensureDemandDataLoadedForContracts({
    required DfdCubit dfdCubit,
    required EditalCubit editalCubit,
    required PublicacaoExtratoCubit publicacaoCubit,
    required Set<String> ids,
  }) async {
    if (ids.isEmpty) return;

    final futures = <Future<void>>[];

    for (final id in ids) {
      final cleanId = id.trim();

      if (cleanId.isEmpty) continue;

      if (!_dfdByContractId.containsKey(cleanId)) {
        futures.add(
          dfdCubit.getDataForContract(cleanId).then((dfd) {
            _dfdByContractId[cleanId] = dfd;
          }).catchError((_) {
            _dfdByContractId[cleanId] = null;
          }),
        );
      }

      if (!_editalByContractId.containsKey(cleanId)) {
        futures.add(
          editalCubit.getDataForContract(cleanId).then((edital) {
            _editalByContractId[cleanId] = edital;
          }).catchError((_) {
            _editalByContractId[cleanId] = null;
          }),
        );
      }

      if (!_pubByContractId.containsKey(cleanId)) {
        futures.add(
          publicacaoCubit.getDataForContract(cleanId).then((pub) {
            _pubByContractId[cleanId] = pub;
          }).catchError((_) {
            _pubByContractId[cleanId] = null;
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
          final aVal =
          (_pubByContractId[idA]?.numeroContrato ?? '').toUpperCase();
          final bVal =
          (_pubByContractId[idB]?.numeroContrato ?? '').toUpperCase();

          return aVal.compareTo(bVal);

        case 2:
          final aVal =
          (_dfdByContractId[idA]?.descricaoObjeto ?? '').toUpperCase();
          final bVal =
          (_dfdByContractId[idB]?.descricaoObjeto ?? '').toUpperCase();

          return aVal.compareTo(bVal);

        case 3:
          final aVal = (_dfdByContractId[idA]?.regional ?? '').toUpperCase();
          final bVal = (_dfdByContractId[idB]?.regional ?? '').toUpperCase();

          return aVal.compareTo(bVal);

        case 4:
          final aVal =
          (_editalByContractId[idA]?.vencedor ?? '').toUpperCase();
          final bVal =
          (_editalByContractId[idB]?.vencedor ?? '').toUpperCase();

          return aVal.compareTo(bVal);

        case 5:
          final aVal =
          (_dfdByContractId[idA]?.processoAdministrativo ?? '')
              .toUpperCase();
          final bVal =
          (_dfdByContractId[idB]?.processoAdministrativo ?? '')
              .toUpperCase();

          return aVal.compareTo(bVal);

        default:
          return 0;
      }
    }

    for (final entry in _cachedByStatus.entries) {
      entry.value.sort(
            (a, b) {
          final result = compare(a, b);

          return _isAscending ? result : -result;
        },
      );
    }
  }

  Future<void> _applyFilters(ProcessCubit cubit) async {
    if (!mounted) return;

    final userCubit = context.read<UserCubit>();
    final permissionCubit = context.read<PermissionCubit>();
    final dfdCubit = context.read<DfdCubit>();
    final editalCubit = context.read<EditalCubit>();
    final publicacaoCubit = context.read<PublicacaoExtratoCubit>();

    setState(() {
      _loading = true;
    });

    try {
      final currentUser = userCubit.state.current;

      if (currentUser == null) {
        _cachedByStatus.clear();
        return;
      }

      await _ensurePermissionLoaded(
        permissionCubit: permissionCubit,
        currentUser: currentUser,
      );

      if (!mounted) return;

      final permissionState = permissionCubit.state;

      final permissions = PermissionResolver.resolveForUser(
        user: currentUser,
        permissionState: permissionState,
      );

      final tenantId = PermissionResolver.cleanTenantId(
        permissionState.activeTenantId,
      );

      if (permissions == null) {
        _cachedByStatus.clear();
        return;
      }

      final baseAll = cubit.state.allProcesses;

      final base = SystemPermission.filterVisibleContracts(
        permissions: permissions,
        contracts: baseAll,
        module: ModuleCatalog.modContractsList,
        tenantId: tenantId,
      );

      final ids = <String>{
        for (final contract in base)
          if (_idToString(contract.id) != null) _idToString(contract.id)!,
      };

      await _ensureDemandDataLoadedForContracts(
        dfdCubit: dfdCubit,
        editalCubit: editalCubit,
        publicacaoCubit: publicacaoCubit,
        ids: ids,
      );

      if (!mounted) return;

      final statusFiltro =
      _statusCtrl.text.trim().isEmpty ? null : _statusCtrl.text.trim();

      final search =
      _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim();

      Iterable<ProcessData> filtered = base;

      if (statusFiltro != null && statusFiltro.isNotEmpty) {
        final target = statusFiltro.toUpperCase();

        filtered = filtered.where((contract) {
          final id = _idToString(contract.id);

          if (id == null) return false;

          final dfd = _dfdByContractId[id];
          final statusKey = _statusKeyFromDfd(dfd);

          return statusKey == target;
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
          final processo =
          (dfd?.processoAdministrativo ?? '').toUpperCase();
          final numeroContrato = (pub?.numeroContrato ?? '').toUpperCase();
          final vencedor = (edital?.vencedor ?? '').toUpperCase();
          final regional = (dfd?.regional ?? '').toUpperCase();

          return objeto.contains(searchUpper) ||
              processo.contains(searchUpper) ||
              numeroContrato.contains(searchUpper) ||
              vencedor.contains(searchUpper) ||
              regional.contains(searchUpper);
        });
      }

      final list = filtered.toList(growable: false);

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

      await _syncExpansionAfterFilter();
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _syncExpansionAfterFilter() async {
    final hasSearch = _searchCtrl.text.trim().isNotEmpty;

    if (hasSearch) {
      if (_preSearchExpandedSnapshot.isEmpty) {
        _preSearchExpandedSnapshot = Set<String>.from(_expandedKeys);
      }

      final expandedNow = _cachedByStatus.entries
          .where((entry) => entry.value.isNotEmpty)
          .map((entry) => entry.key)
          .toSet();

      if (!mounted) return;

      setState(() {
        _expandedKeys
          ..clear()
          ..addAll(expandedNow);
      });

      await _saveExpandedToPrefs();
      return;
    }

    if (_preSearchExpandedSnapshot.isNotEmpty) {
      if (!mounted) return;

      setState(() {
        _expandedKeys
          ..clear()
          ..addAll(_preSearchExpandedSnapshot);

        _preSearchExpandedSnapshot = <String>{};
      });

      await _saveExpandedToPrefs();
    }

    if (!mounted) return;

    setState(() {
      _expandedKeys.removeWhere(
            (key) =>
        _cachedByStatus.containsKey(key) &&
            (_cachedByStatus[key]?.isEmpty ?? true),
      );
    });

    await _saveExpandedToPrefs();
  }

  Future<void> _runInitialLoad({
    required ProcessCubit cubit,
    required ProcessState processState,
    required PermissionCubit permissionCubit,
    required UserData currentUser,
  }) async {
    await _ensurePermissionLoaded(
      permissionCubit: permissionCubit,
      currentUser: currentUser,
    );

    if (!mounted) return;

    final permissionState = permissionCubit.state;

    final permissions = PermissionResolver.resolveForUser(
      user: currentUser,
      permissionState: permissionState,
    );

    final tenantId = PermissionResolver.cleanTenantId(
      permissionState.activeTenantId,
    );

    if (permissions == null) {
      setState(() {
        _cachedByStatus.clear();
      });
      return;
    }

    final canReadContracts = permissions.canModuleString(
      module: ModuleCatalog.modContractsList,
      action: 'read',
      tenantId: tenantId,
    );

    if (!canReadContracts) {
      setState(() {
        _cachedByStatus.clear();
      });
      return;
    }

    if (processState.allProcesses.isEmpty && !processState.loading) {
      await cubit.refresh(
        currentUser: currentUser,
        currentPermissions: permissions,
        tenantId: tenantId,
      );
    }

    if (!mounted) return;

    await _applyFilters(cubit);
  }

  Future<void> _openCreateDemand({
    required NavigatorState navigator,
    required ProcessCubit cubit,
    required UserData currentUser,
  }) async {
    final result = await navigator.push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => TabBarHingPage(
          key: UniqueKey(),
          contractData: ProcessData.empty(),
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _refresh(
        cubit: cubit,
        currentUser: currentUser,
      );
    }
  }

  bool _canCreateDemand({
    required PermissionCubit permissionCubit,
    required UserData currentUser,
  }) {
    final permissionState = permissionCubit.state;

    final permissions = PermissionResolver.resolveForUser(
      user: currentUser,
      permissionState: permissionState,
    );

    final tenantId = PermissionResolver.cleanTenantId(
      permissionState.activeTenantId,
    );

    return permissions?.canModuleString(
      module: ModuleCatalog.modContractsList,
      action: 'create',
      tenantId: tenantId,
    ) ==
        true;
  }

  bool _canDeleteDemand({
    required PermissionCubit permissionCubit,
    required UserData currentUser,
    required ProcessData item,
  }) {
    final permissionState = permissionCubit.state;

    final permissions = PermissionResolver.resolveForUser(
      user: currentUser,
      permissionState: permissionState,
    );

    final tenantId = PermissionResolver.cleanTenantId(
      permissionState.activeTenantId,
    );

    if (permissions == null) return false;

    return SystemPermission.canContract(
      permissions: permissions,
      contract: item,
      action: 'delete',
      module: ModuleCatalog.modContractsList,
      tenantId: tenantId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final processCubit = context.read<ProcessCubit>();

    final fb_auth.User? firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text('Usuário não autenticado.'),
        ),
      );
    }

    final currentUser = context.select<UserCubit, UserData?>(
          (cubit) => cubit.state.current,
    );

    final permissionCubit = context.watch<PermissionCubit>();

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: LoadingTreeDots(
          color: Colors.blue,
          message: Text('Carregando contratos ...'),
        ),
      );
    }

    final canCreateDemand = _canCreateDemand(
      permissionCubit: permissionCubit,
      currentUser: currentUser,
    );

    return BlocBuilder<ProcessCubit, ProcessState>(
      buildWhen: (previous, current) {
        return previous.loading != current.loading ||
            previous.allProcesses != current.allProcesses ||
            previous.errorMessage != current.errorMessage;
      },
      builder: (context, processState) {
        if (!_didScheduleInitialLoad && !_loading && _cachedByStatus.isEmpty) {
          _didScheduleInitialLoad = true;

          final capturedPermissionCubit = permissionCubit;
          final capturedProcessCubit = processCubit;
          final capturedCurrentUser = currentUser;
          final capturedProcessState = processState;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            unawaited(
              _runInitialLoad(
                cubit: capturedProcessCubit,
                processState: capturedProcessState,
                permissionCubit: capturedPermissionCubit,
                currentUser: capturedCurrentUser,
              ),
            );
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
                        SearchWidget(
                          onSearch: (text) {
                            _onSearchChanged(
                              processCubit,
                              text,
                            );
                          },
                        ),
                      ],
                      titleWidgets: [
                        Text(widget.pageTitle),
                      ],
                    ),
                    Expanded(
                      child: _loading && _cachedByStatus.isEmpty
                          ? const LoadingTreeDots(
                        color: Colors.blue,
                        message: Text('Carregando contratos ...'),
                      )
                          : _buildStatusList(
                        context: context,
                        processCubit: processCubit,
                        permissionCubit: permissionCubit,
                        currentUser: currentUser,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: canCreateDemand
              ? ExpandedButtonChange(
            icon: Icons.add,
            label: 'Nova demanda',
            color: Colors.blue,
            onPressed: () {
              final navigator = Navigator.of(context);

              unawaited(
                _openCreateDemand(
                  navigator: navigator,
                  cubit: processCubit,
                  currentUser: currentUser,
                ),
              );
            },
          )
              : null,
        );
      },
    );
  }

  Widget _buildStatusList({
    required BuildContext context,
    required ProcessCubit processCubit,
    required PermissionCubit permissionCubit,
    required UserData currentUser,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          children: GeneralDashboardStyle.statusMenu.map(
                (status) {
              final label = status.$1;
              final rawKey = status.$2;
              final normalizedKey = _norm(rawKey);

              final items =
                  _cachedByStatus[normalizedKey] ?? const <ProcessData>[];

              return ListDemandStatus(
                title: label,
                statusKey: normalizedKey,
                items: items,
                constraints: constraints,
                sortColumnIndex: _sortColumnIndex,
                isAscending: _isAscending,
                onSort: (index, _) {
                  _handleSort(index);
                },
                onDelete: (item) async {
                  final id = item.id?.trim();

                  if (id == null || id.isEmpty) {
                    return;
                  }

                  final canDelete = _canDeleteDemand(
                    permissionCubit: permissionCubit,
                    currentUser: currentUser,
                    item: item,
                  );

                  if (!canDelete) {
                    return;
                  }

                  await processCubit.delete(id);

                  if (!mounted) return;

                  await _refresh(
                    cubit: processCubit,
                    currentUser: currentUser,
                  );
                },
                onTapItem: widget.onTapItem,
                initiallyExpanded: _isExpanded(normalizedKey),
                onExpansionChanged: (open) {
                  unawaited(
                    _setExpanded(
                      normalizedKey,
                      open,
                    ),
                  );
                },
                dfdByContractId: _dfdByContractId,
                editalByContractId: _editalByContractId,
                pubByContractId: _pubByContractId,
              );
            },
          ).toList(growable: false),
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