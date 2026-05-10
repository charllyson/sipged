// lib/screens/modules/actives/oaes/records/active_oaes_records_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_cubit.dart';
import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_data.dart';
import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_repository.dart';
import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_state.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';

import 'package:sipged/_blocs/system/tenant/tenant_cubit.dart';
import 'package:sipged/_blocs/system/tenant/tenant_state.dart';

import 'package:sipged/_blocs/system/user/user_cubit.dart';

import 'package:sipged/_widgets/buttons/expanded_button_change.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/map/search/search_widget.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

import 'package:sipged/screens/modules/actives/oaes/records/list_oaes_page.dart';
import 'package:sipged/screens/modules/actives/oaes/records/tab_bar_oaes_page.dart';

class ActiveOaesRecordsPage extends StatefulWidget {
  const ActiveOaesRecordsPage({super.key});

  @override
  State<ActiveOaesRecordsPage> createState() => _ActiveOaesRecordsPageState();
}

class _ActiveOaesRecordsPageState extends State<ActiveOaesRecordsPage> {
  late final ActiveOaesCubit _cubit;

  final TextEditingController _searchCtrl = TextEditingController();

  final Set<String> _expandedKeys = <String>{};
  Set<String> _preSearchExpandedSnapshot = <String>{};

  Timer? _debounce;

  bool _firedUserWarmup = false;
  bool _didScheduleInitialLoad = false;
  bool _loadingLocal = false;

  String? _lastTenantId;
  String? _lastFailureMessage;

  int? _sortColumnIndex = 1;
  bool _isAscending = true;

  static const String _prefsExpandedKey = 'active_oaes_expanded_score_keys';

  @override
  void initState() {
    super.initState();

    _cubit = ActiveOaesCubit(
      repository: ActiveOaesRepository(),
    );

    unawaited(_loadExpandedFromPrefs());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_firedUserWarmup) {
      _firedUserWarmup = true;

      context.read<UserCubit>().warmup(
        listenRealtime: true,
        bindCurrentUser: true,
      );
    }

    final tenantState = context.read<TenantCubit>().state;
    final permissionState = context.read<PermissionCubit>().state;

    final tenantId = _tenantIdFromTenantState(tenantState) ??
        _cleanId(permissionState.activeTenantId);

    _syncTenantAndPermissions(
      tenantId: tenantId,
      permissionState: permissionState,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _cubit.close();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Preferências de expansão
  // ---------------------------------------------------------------------------

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

  String _norm(String value) {
    return value.trim().toUpperCase();
  }

  String _scoreKeyOf(int score) {
    return 'SCORE_$score';
  }

  // ---------------------------------------------------------------------------
  // Tenant helpers
  // ---------------------------------------------------------------------------

  String? _cleanId(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty) return null;
    if (text.toLowerCase() == 'null') return null;

    return text;
  }

  String? _idFromObject(dynamic object) {
    if (object == null) return null;

    try {
      final clean = _cleanId(object.id);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _cleanId(object.tenantId);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _cleanId(object.companyId);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _cleanId(object.uid);
      if (clean != null) return clean;
    } catch (_) {}

    return null;
  }

  String? _tenantIdFromTenantState(TenantState state) {
    final dynamic s = state;

    try {
      final clean = _cleanId(s.activeTenantId);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _cleanId(s.currentTenantId);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _cleanId(s.tenantId);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _cleanId(s.companyId);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.current);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.tenant);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.currentTenant);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.activeTenant);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.selectedTenant);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.company);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.selectedCompany);
      if (clean != null) return clean;
    } catch (_) {}

    return null;
  }

  void _syncTenantAndPermissions({
    required String? tenantId,
    required PermissionState permissionState,
  }) {
    final cleanTenantId = tenantId?.trim();

    final tenantChanged = _lastTenantId != cleanTenantId;

    if (tenantChanged) {
      _lastTenantId = cleanTenantId;
      _lastFailureMessage = null;
      _didScheduleInitialLoad = false;

      _searchCtrl.clear();
      _preSearchExpandedSnapshot.clear();

      _cubit.updatePermissions(
        permissions: permissionState.current,
        tenantId: cleanTenantId,
      );

      if (cleanTenantId == null || cleanTenantId.isEmpty) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        unawaited(_refreshOaes());
      });

      return;
    }

    _cubit.updatePermissions(
      permissions: permissionState.current,
      tenantId: cleanTenantId,
    );
  }

  // ---------------------------------------------------------------------------
  // Carregamento
  // ---------------------------------------------------------------------------

  Future<void> _refreshOaes() async {
    if (!_cubit.hasTenant) return;

    if (mounted) {
      setState(() {
        _loadingLocal = true;
      });
    }

    try {
      await _cubit.refresh();
      await _syncExpansionAfterFilter(_visibleOaes(_cubit.state.all));
    } finally {
      if (mounted) {
        setState(() {
          _loadingLocal = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Notificações
  // ---------------------------------------------------------------------------

  void _showNotification({
    required String title,
    String? subtitle,
    NotificationStatus type = NotificationStatus.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!mounted) return;

    context.read<NotificationLocalCubit>().show(
      NotificationData(
        title: title,
        subtitle: subtitle,
        leadingLabel: 'OAEs',
        type: type,
        duration: duration,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Navegação
  // ---------------------------------------------------------------------------

  Future<void> _openTabBarForOae(ActiveOaesData? item) async {
    if (item == null) {
      _cubit.clearSelection();
    } else {
      final idx = _cubit.state.all.indexWhere((e) => e.id == item.id);

      if (idx != -1) {
        _cubit.selectByIndex(idx);
      } else {
        _cubit.patchForm(item);
      }
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: _cubit,
          child: const TabBarOaesPage(),
        ),
      ),
    );

    if (!mounted) return;

    await _refreshOaes();
  }

  // ---------------------------------------------------------------------------
  // Busca / ordenação / expansão
  // ---------------------------------------------------------------------------

  String _textOf(ActiveOaesData oae) {
    return [
      oae.id,
      oae.order?.toString(),
      oae.score?.toString(),
      oae.state,
      oae.road,
      oae.region,
      oae.identificationName,
      oae.structureType,
      oae.relatedContracts,
      oae.companyBuild,
      oae.latitude?.toString(),
      oae.longitude?.toString(),
      oae.altitude?.toString(),
    ].whereType<String>().join(' ').toUpperCase();
  }

  List<ActiveOaesData> _visibleOaes(List<ActiveOaesData> source) {
    final search = _searchCtrl.text.trim().toUpperCase();

    Iterable<ActiveOaesData> filtered = source;

    if (search.isNotEmpty) {
      filtered = filtered.where((oae) {
        return _textOf(oae).contains(search);
      });
    }

    final list = filtered.toList(growable: false);

    _sortList(list);

    return list;
  }

  void _sortList(List<ActiveOaesData> list) {
    if (_sortColumnIndex == null) return;

    String txt(String? value) {
      final text = (value ?? '').trim();
      if (text.isEmpty || text.toLowerCase() == 'null') return '';
      return text.toUpperCase();
    }

    int compareText(String? a, String? b) {
      return txt(a).compareTo(txt(b));
    }

    int compareNum(num? a, num? b) {
      return (a ?? 0).compareTo(b ?? 0);
    }

    list.sort((a, b) {
      late final int result;

      switch (_sortColumnIndex) {
        case 0:
          result = compareNum(a.score, b.score);
          break;
        case 1:
          result = compareText(a.identificationName, b.identificationName);
          break;
        case 2:
          result = compareText(a.region, b.region);
          break;
        case 3:
          result = compareText(a.road, b.road);
          break;
        case 4:
          result = compareText(a.structureType, b.structureType);
          break;
        case 5:
          result = compareText(a.relatedContracts, b.relatedContracts);
          break;
        default:
          result = compareText(a.identificationName, b.identificationName);
      }

      return _isAscending ? result : -result;
    });
  }

  void _handleSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;

      if (_searchCtrl.text != value) {
        _searchCtrl.text = value;
      }

      await _syncExpansionAfterFilter(_visibleOaes(_cubit.state.all));

      if (mounted) {
        setState(() {});
      }
    });
  }

  Map<int, List<ActiveOaesData>> _groupByScore(List<ActiveOaesData> list) {
    final map = <int, List<ActiveOaesData>>{};

    for (final oae in list) {
      final scoreKey = OaeScoreHelper.normalizeScore(oae.score);

      map.putIfAbsent(scoreKey, () => <ActiveOaesData>[]).add(oae);
    }

    return map;
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

  Future<void> _syncExpansionAfterFilter(
      List<ActiveOaesData> visibleOaes,
      ) async {
    final hasSearch = _searchCtrl.text.trim().isNotEmpty;

    final grouped = _groupByScore(visibleOaes);

    final visibleKeys = grouped.keys
        .where((score) {
      final items = grouped[score] ?? const <ActiveOaesData>[];
      return items.isNotEmpty;
    })
        .map((score) => _norm(_scoreKeyOf(score)))
        .toSet();

    if (hasSearch) {
      if (_preSearchExpandedSnapshot.isEmpty) {
        _preSearchExpandedSnapshot = Set<String>.from(_expandedKeys);
      }

      if (!mounted) return;

      setState(() {
        _expandedKeys
          ..clear()
          ..addAll(visibleKeys);
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
      return;
    }

    if (!mounted) return;

    setState(() {
      _expandedKeys.removeWhere((key) => !visibleKeys.contains(key));
    });

    await _saveExpandedToPrefs();
  }

  // ---------------------------------------------------------------------------
  // Delete
  // ---------------------------------------------------------------------------

  Future<void> _deleteOae(String id) async {
    try {
      await _cubit.deleteById(id);

      if (!mounted) return;

      _showNotification(
        title: 'OAE excluída',
        subtitle: 'O registro foi removido.',
        type: NotificationStatus.warning,
        duration: const Duration(seconds: 3),
      );

      await _syncExpansionAfterFilter(_visibleOaes(_cubit.state.all));
    } catch (e) {
      if (!mounted) return;

      _showNotification(
        title: 'Erro ao excluir OAE',
        subtitle: '$e',
        type: NotificationStatus.error,
        duration: const Duration(seconds: 6),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  Widget _emptyState({
    required String title,
    required String subtitle,
    IconData icon = Icons.account_tree_outlined,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 42,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ActiveOaesCubit>.value(
      value: _cubit,
      child: MultiBlocListener(
        listeners: [
          BlocListener<TenantCubit, TenantState>(
            listener: (context, tenantState) {
              final permissionState = context.read<PermissionCubit>().state;
              final tenantId = _tenantIdFromTenantState(tenantState) ??
                  _cleanId(permissionState.activeTenantId);

              _syncTenantAndPermissions(
                tenantId: tenantId,
                permissionState: permissionState,
              );
            },
          ),
          BlocListener<PermissionCubit, PermissionState>(
            listenWhen: (previous, current) {
              return previous.current != current.current ||
                  previous.activeTenantId != current.activeTenantId;
            },
            listener: (context, permissionState) {
              final tenantState = context.read<TenantCubit>().state;

              final tenantId = _tenantIdFromTenantState(tenantState) ??
                  _cleanId(permissionState.activeTenantId);

              _syncTenantAndPermissions(
                tenantId: tenantId,
                permissionState: permissionState,
              );
            },
          ),
        ],
        child: Builder(
          builder: (context) {
            final tenantState = context.watch<TenantCubit>().state;
            final permissionState = context.watch<PermissionCubit>().state;

            final tenantId = _tenantIdFromTenantState(tenantState) ??
                _cleanId(permissionState.activeTenantId);

            if (tenantId == null || tenantId.isEmpty) {
              return Scaffold(
                backgroundColor: Colors.white,
                body: Stack(
                  children: [
                    const BackgroundChange(),
                    SafeArea(
                      top: false,
                      bottom: false,
                      child: Column(
                        children: [
                          const UpBar(
                            includeSafeTop: true,
                            titleWidgets: [
                              Text('OAEs'),
                            ],
                          ),
                          Expanded(
                            child: _emptyState(
                              title: 'Nenhuma empresa selecionada',
                              subtitle:
                              'Selecione uma empresa para visualizar as OAEs.',
                              icon: Icons.business_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return BlocBuilder<ActiveOaesCubit, ActiveOaesState>(
              builder: (context, state) {
                if (!_didScheduleInitialLoad &&
                    !_loadingLocal &&
                    !state.initialized) {
                  _didScheduleInitialLoad = true;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;

                    unawaited(_refreshOaes());
                  });
                }

                if (state.loadStatus == ActiveOaesLoadStatus.failure) {
                  final error = state.error ?? 'Erro desconhecido';

                  if (_lastFailureMessage != error) {
                    _lastFailureMessage = error;

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;

                      _showNotification(
                        title: 'Falha ao carregar OAEs',
                        subtitle: error,
                        type: NotificationStatus.error,
                        duration: const Duration(seconds: 6),
                      );
                    });
                  }
                } else {
                  _lastFailureMessage = null;
                }

                final loading = _loadingLocal ||
                    (!state.initialized &&
                        state.loadStatus == ActiveOaesLoadStatus.loading);

                final visibleOaes = _visibleOaes(state.all);

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
                              titleWidgets: const [
                                Text('OAEs'),
                              ],
                              actions: [
                                SearchWidget(
                                  onSearch: _onSearchChanged,
                                ),
                                IconButton(
                                  tooltip: 'Atualizar',
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                  ),
                                  onPressed: loading
                                      ? null
                                      : () {
                                    unawaited(_refreshOaes());
                                  },
                                ),
                              ],
                            ),
                            Expanded(
                              child: loading && state.all.isEmpty
                                  ? const LoadingTreeDots(
                                color: Colors.blue,
                                message: Text('Carregando OAEs ...'),
                              )
                                  : state.loadStatus ==
                                  ActiveOaesLoadStatus.failure
                                  ? _emptyState(
                                title: 'Erro ao carregar OAEs',
                                subtitle: state.error ?? '-',
                                icon: Icons.error_outline,
                              )
                                  : ListOaesPage(
                                oaes: visibleOaes,
                                sortColumnIndex: _sortColumnIndex,
                                isAscending: _isAscending,
                                onSort: _handleSort,
                                isExpanded: _isExpanded,
                                onExpansionChanged: (key, open) {
                                  unawaited(
                                    _setExpanded(key, open),
                                  );
                                },
                                onTapItem: (item) {
                                  unawaited(
                                    _openTabBarForOae(item),
                                  );

                                  final label =
                                      item.identificationName ??
                                          item.id ??
                                          '';

                                  _showNotification(
                                    title: 'Editando OAE',
                                    subtitle: label,
                                    type: NotificationStatus.info,
                                    duration:
                                    const Duration(seconds: 3),
                                  );
                                },
                                onDelete: (id) {
                                  unawaited(_deleteOae(id));
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (state.saving)
                        Stack(
                          children: [
                            ModalBarrier(
                              dismissible: false,
                              color: Colors.black.withValues(alpha: 0.35),
                            ),
                            const Center(
                              child: LoadingTreeDots(size: 120),
                            ),
                          ],
                        ),
                    ],
                  ),
                  floatingActionButton: ExpandedButtonChange(
                    icon: Icons.add,
                    label: 'Nova OAE',
                    color: Colors.blue,
                    onPressed: state.saving || !_cubit.isEditable
                        ? null
                        : () {
                      unawaited(_openTabBarForOae(null));
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}