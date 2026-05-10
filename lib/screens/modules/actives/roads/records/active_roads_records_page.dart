// lib/screens/modules/actives/roads/records/active_roads_records_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sipged/_blocs/modules/actives/roads/active_roads_cubit.dart';
import 'package:sipged/_blocs/modules/actives/roads/active_roads_data.dart';
import 'package:sipged/_blocs/modules/actives/roads/active_roads_repository.dart';
import 'package:sipged/_blocs/modules/actives/roads/active_roads_state.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_blocs/system/tenant/tenant_cubit.dart';
import 'package:sipged/_blocs/system/tenant/tenant_state.dart';

import 'package:sipged/_blocs/system/user/user_cubit.dart';

import 'package:sipged/_widgets/buttons/expanded_button_change.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/map/search/search_widget.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

import 'package:sipged/screens/modules/actives/roads/records/list_roads_page.dart';

import 'tab_bar_roads_page.dart';

class ActiveRoadsRecordsPage extends StatefulWidget {
  const ActiveRoadsRecordsPage({super.key});

  @override
  State<ActiveRoadsRecordsPage> createState() => _ActiveRoadsRecordsPageState();
}

class _ActiveRoadsRecordsPageState extends State<ActiveRoadsRecordsPage> {
  late final ActiveRoadsCubit _cubit;

  final TextEditingController _searchCtrl = TextEditingController();

  final Set<String> _expandedKeys = <String>{};
  Set<String> _preSearchExpandedSnapshot = <String>{};

  Timer? _debounce;

  bool _firedUserWarmup = false;
  bool _didScheduleInitialLoad = false;
  bool _loadingLocal = false;

  String? _lastTenantId;
  String? _lastFailureMessage;

  int? _sortColumnIndex;
  bool _isAscending = true;

  static const String _prefsExpandedKey = 'active_roads_expanded_keys';

  @override
  void initState() {
    super.initState();

    _cubit = ActiveRoadsCubit(
      repository: ActiveRoadsRepository(),
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
    final tenantId = _tenantIdFromTenantState(tenantState);

    _syncTenant(tenantId);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _cubit.close();

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

  String _norm(String value) {
    return value.trim().toUpperCase();
  }

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

  void _syncTenant(String? tenantId) {
    final cleanTenantId = tenantId?.trim();

    if (_lastTenantId == cleanTenantId) return;

    _lastTenantId = cleanTenantId;
    _lastFailureMessage = null;
    _didScheduleInitialLoad = false;

    _searchCtrl.clear();
    _preSearchExpandedSnapshot.clear();

    _cubit.setActiveTenantId(cleanTenantId);

    if (cleanTenantId == null || cleanTenantId.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      unawaited(_refreshRoads(forceRefresh: true));
    });
  }

  Future<void> _refreshRoads({bool forceRefresh = false}) async {
    if (!_cubit.hasTenant) return;

    if (mounted) {
      setState(() {
        _loadingLocal = true;
      });
    }

    try {
      await _cubit.warmupRecords(forceRefresh: forceRefresh);
      await _syncExpansionAfterFilter(_visibleRoads(_cubit.state.all));
    } finally {
      if (mounted) {
        setState(() {
          _loadingLocal = false;
        });
      }
    }
  }

  void _showNotification({
    required String title,
    String? subtitle,
    NotificationStatus type = NotificationStatus.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    context.read<NotificationLocalCubit>().show(
      NotificationData(
        title: title,
        subtitle: subtitle,
        leadingLabel: 'Rodovias',
        type: type,
        duration: duration,
      ),
    );
  }

  Future<void> _openTabBarForRoad(ActiveRoadsData? road) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _cubit,
          child: TabBarRoadsPage(editing: road),
        ),
      ),
    );

    if (!mounted) return;

    await _refreshRoads(forceRefresh: true);
  }

  String _textOf(ActiveRoadsData road) {
    return [
      road.id,
      road.acronym,
      road.roadCode,
      road.roadName,
      road.uf,
      road.segmentType,
      road.initialSegment,
      road.finalSegment,
      road.regional,
      road.displayRegion,
      road.stateSurface,
      road.surface,
      road.state,
      road.description,
      road.managingAgency,
      road.jurisdiction,
      road.administration,
      road.vsa?.toString(),
      road.extension?.toString(),
    ].whereType<String>().join(' ').toUpperCase();
  }

  List<ActiveRoadsData> _visibleRoads(List<ActiveRoadsData> source) {
    final search = _searchCtrl.text.trim().toUpperCase();

    Iterable<ActiveRoadsData> filtered = source;

    if (search.isNotEmpty) {
      filtered = filtered.where((road) {
        return _textOf(road).contains(search);
      });
    }

    final list = filtered.toList(growable: false);

    _sortList(list);

    return list;
  }

  void _sortList(List<ActiveRoadsData> list) {
    if (_sortColumnIndex == null) return;

    int compareText(String? a, String? b) {
      return (a ?? '').toUpperCase().compareTo((b ?? '').toUpperCase());
    }

    int compareNum(num? a, num? b) {
      return (a ?? 0).compareTo(b ?? 0);
    }

    list.sort((a, b) {
      late final int result;

      switch (_sortColumnIndex) {
        case 0:
          result = compareText(a.roadCode, b.roadCode);
          break;
        case 1:
          result = compareText(a.segmentType, b.segmentType);
          break;
        case 2:
          result = compareText(a.initialSegment, b.initialSegment);
          break;
        case 3:
          result = compareText(a.finalSegment, b.finalSegment);
          break;
        case 4:
          result = compareText(a.displayRegion, b.displayRegion);
          break;
        case 5:
          result = compareNum(a.extension, b.extension);
          break;
        case 6:
          result = compareText(
            a.stateSurface ?? a.surface,
            b.stateSurface ?? b.surface,
          );
          break;
        default:
          result = compareText(a.acronym, b.acronym);
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

      await _syncExpansionAfterFilter(_visibleRoads(_cubit.state.all));

      if (mounted) {
        setState(() {});
      }
    });
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
      List<ActiveRoadsData> visibleRoads,
      ) async {
    final hasSearch = _searchCtrl.text.trim().isNotEmpty;

    final grouped = ActiveRoadsData.groupByAcronym(visibleRoads);
    final visibleKeys = grouped.keys.map(_norm).toSet();

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

  Future<void> _deleteRoad(String id) async {
    await _cubit.deleteById(id);

    if (!mounted) return;

    _showNotification(
      title: 'Rodovia excluída',
      subtitle: 'O registro foi removido.',
      type: NotificationStatus.warning,
      duration: const Duration(seconds: 3),
    );

    await _syncExpansionAfterFilter(_visibleRoads(_cubit.state.all));
  }

  Widget _emptyState({
    required String title,
    required String subtitle,
    IconData icon = Icons.alt_route_outlined,
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
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<TenantCubit, TenantState>(
        listener: (context, tenantState) {
          final tenantId = _tenantIdFromTenantState(tenantState);
          _syncTenant(tenantId);
        },
        child: Builder(
          builder: (context) {
            final tenantState = context.watch<TenantCubit>().state;
            final tenantId = _tenantIdFromTenantState(tenantState);

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
                              Text('Rodovias'),
                            ],
                          ),
                          Expanded(
                            child: _emptyState(
                              title: 'Nenhuma empresa selecionada',
                              subtitle:
                              'Selecione uma empresa para visualizar as rodovias.',
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

            return BlocBuilder<ActiveRoadsCubit, ActiveRoadsState>(
              builder: (context, st) {
                if (!_didScheduleInitialLoad &&
                    !_loadingLocal &&
                    !st.initialized) {
                  _didScheduleInitialLoad = true;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    unawaited(_refreshRoads(forceRefresh: true));
                  });
                }

                if (st.loadStatus == ActiveRoadsLoadStatus.failure) {
                  final error = st.error ?? 'Erro desconhecido';

                  if (_lastFailureMessage != error) {
                    _lastFailureMessage = error;

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;

                      _showNotification(
                        title: 'Falha ao carregar rodovias',
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
                    (!st.initialized &&
                        st.loadStatus == ActiveRoadsLoadStatus.loading);

                final visibleRoads = _visibleRoads(st.all);

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
                                Text('Rodovias'),
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
                                    unawaited(
                                      _refreshRoads(forceRefresh: true),
                                    );
                                  },
                                ),
                              ],
                            ),
                            Expanded(
                              child: loading && st.all.isEmpty
                                  ? const LoadingTreeDots(
                                color: Colors.blue,
                                message: Text('Carregando rodovias ...'),
                              )
                                  : st.loadStatus ==
                                  ActiveRoadsLoadStatus.failure
                                  ? _emptyState(
                                title: 'Erro ao carregar rodovias',
                                subtitle: st.error ?? '-',
                                icon: Icons.error_outline,
                              )
                                  : ListRoadsPage(
                                roads: visibleRoads,
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
                                    _openTabBarForRoad(item),
                                  );

                                  final rotulo =
                                      item.acronym ?? item.id ?? '';

                                  _showNotification(
                                    title: 'Editando rodovia',
                                    subtitle: rotulo,
                                    type: NotificationStatus.info,
                                    duration:
                                    const Duration(seconds: 3),
                                  );
                                },
                                onDelete: (id) {
                                  unawaited(_deleteRoad(id));
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (st.savingOrImporting)
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
                    label: 'Nova rodovia',
                    color: Colors.blue,
                    onPressed: st.savingOrImporting
                        ? null
                        : () {
                      unawaited(_openTabBarForRoad(null));
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