import 'dart:async';
import 'package:extended_image/extended_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:siged/_blocs/panels/overview-dashboard/demands_dashboard_overview_style.dart';
import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/buttons/contract_add_button.dart';
import 'package:siged/_widgets/search/search_widget.dart';
import 'package:siged/_widgets/user/user_greeting.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/screens/process/hiring/tab_bar_hiring_page.dart';

import 'package:siged/_blocs/_process/process_store.dart';
import 'list_demand_status.dart';

// 🆕 DFD
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_repository.dart';

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
  static const _prefsExpandedKey = 'contracts_expanded_keys';

  final _statusCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  bool _loading = false;
  int? _sortColumnIndex;
  bool _isAscending = true;

  final Map<String, List<ProcessData>> _cachedByStatus = {};
  final Set<String> _expandedKeys = {}; // chaves normalizadas
  Set<String> _preSearchExpandedSnapshot = {};

  Timer? _debounce;

  // 🆕 caches DFD
  final Map<String, String> _regionById = {};
  final Map<String, String> _processNumberById = {};
  final Map<String, String> _statusById = {}; // 🔸 status do DFD

  final DfdRepository _dfdRepo = DfdRepository();

  String _norm(String k) => k.trim().toUpperCase();

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

  void _applyLocalSortIfAny() {
    if (_sortColumnIndex == null) return;

    final byName = _sortColumnIndex == 0;
    if (!byName) return;

    int cmp(ProcessData a, ProcessData b) {
      final an = (a.summarySubject ?? '').toUpperCase();
      final bn = (b.summarySubject ?? '').toUpperCase();
      return an.compareTo(bn);
    }

    for (final e in _cachedByStatus.entries) {
      e.value.sort((a, b) => _isAscending ? cmp(a, b) : cmp(b, a));
    }
  }

  void _onSearchChanged(ProcessStore store, String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (_searchCtrl.text != value) _searchCtrl.text = value;
      await _applyFilters(store);
    });
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

  bool _isExpanded(String k) => _expandedKeys.contains(_norm(k));
  Future<void> _setExpanded(String k, bool open) async {
    final nk = _norm(k);
    setState(() {
      if (open) {
        _expandedKeys.add(nk);
      } else {
        _expandedKeys.remove(nk);
      }
    });
    await _saveExpandedToPrefs();
  }

  Future<void> _refresh(ProcessStore store) async {
    setState(() => _loading = true);
    try {
      await _applyFilters(store);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _idToString(Object? id) {
    if (id == null) return null;
    try {
      final dyn = id as dynamic;
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

  Future<void> _ensureDfdLightForIds(Iterable<String> ids) async {
    final futures = <Future<void>>[];
    for (final id in ids) {
      // status
      if (!_statusById.containsKey(id)) {
        futures.add(() async {
          final leve = await _dfdRepo.readLightFields(id);
          final s = (leve.status ?? '').trim();
          if (s.isNotEmpty) _statusById[id] = s;
        }());
      }
      // regional
      if (!_regionById.containsKey(id)) {
        futures.add(_dfdRepo.readRegionalLabel(id).then((v) {
          if (v != null && v.trim().isNotEmpty) _regionById[id] = v.trim();
        }));
      }
      // nº processo
      if (!_processNumberById.containsKey(id)) {
        futures.add(_dfdRepo.readProcessNumber(id).then((v) {
          if (v != null && v.trim().isNotEmpty) _processNumberById[id] = v.trim();
        }));
      }
    }
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  /// Aplica filtros locais com status vindo do DFD
  Future<void> _applyFilters(ProcessStore store) async {
    setState(() => _loading = true);
    try {
      final statusFiltro = _statusCtrl.text.isNotEmpty ? _statusCtrl.text : null;
      final search = _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim();

      final base = store.all;
      final ids = <String>{
        for (final c in base)
          if (_idToString(c.id) != null) _idToString(c.id)!,
      };

      // garante status/região/nº processo do DFD
      await _ensureDfdLightForIds(ids);

      Iterable<ProcessData> r = base;

      // 🔸 filtra por status do DFD (não por c.status)
      if (statusFiltro != null && statusFiltro.isNotEmpty) {
        final alvo = statusFiltro.trim().toUpperCase();
        r = r.where((c) {
          final id = _idToString(c.id);
          final st = id != null ? _statusById[id] : null;
          return (st ?? '').toUpperCase() == alvo;
        });
      }

      if (search != null && search.isNotEmpty) {
        final s = search.toUpperCase();
        r = r.where((c) =>
        (c.summarySubject ?? '').toUpperCase().contains(s) ||
            (c.contractNumber ?? '').toUpperCase().contains(s) ||
            (c.companyLeader ?? '').toUpperCase().contains(s));
      }

      final list = r.toList(growable: false);

      // 🔸 reagrupa por status do DFD
      _cachedByStatus
        ..clear();

      for (final c in list) {
        final id = _idToString(c.id);
        final st = id != null ? (_statusById[id] ?? 'SEM STATUS') : 'SEM STATUS';
        final k = _norm(st);
        _cachedByStatus.putIfAbsent(k, () => <ProcessData>[]).add(c);
      }

      _applyLocalSortIfAny();

      final hasSearch = _searchCtrl.text.trim().isNotEmpty;
      if (hasSearch) {
        _preSearchExpandedSnapshot = _preSearchExpandedSnapshot.isEmpty
            ? Set<String>.from(_expandedKeys)
            : _preSearchExpandedSnapshot;

        final expandedNow = _cachedByStatus.entries
            .where((e) => e.value.isNotEmpty)
            .map((e) => e.key)
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
            _preSearchExpandedSnapshot = {};
          });
          await _saveExpandedToPrefs();
        }

        setState(() {
          _expandedKeys.removeWhere(
                (k) => _cachedByStatus.containsKey(k) &&
                (_cachedByStatus[k]?.isEmpty ?? true),
          );
        });
        await _saveExpandedToPrefs();

        // sincroniza pós-frame (apenas visual)
        SchedulerBinding.instance.addPostFrameCallback((_) {});
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProcessStore>();
    final User? firebaseUser = FirebaseAuth.instance.currentUser;

    final UserData? currentUser = context.select<UserBloc, UserData?>(
          (b) => b.state.current,
    );

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const BackgroundClean(),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UpBar(
                          actions: [
                            SearchAction(
                              onSearch: (txt) => _onSearchChanged(store, txt),
                            ),
                            UserGreeting(firebaseUser: firebaseUser),
                          ],
                          titleWidgets: [
                            Text(widget.pageTitle),
                          ],
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: DemandsDashboardOverviewStyle.statusMenu.map((status) {
                            final label = status.$1;
                            final rawKey = status.$2;
                            final k = _norm(rawKey);
                            final items = _cachedByStatus[k] ?? const <ProcessData>[];

                            return ListDemandStatus(
                              title: label,
                              statusKey: k,
                              items: items,
                              constraints: constraints,
                              sortColumnIndex: _sortColumnIndex,
                              isAscending: _isAscending,
                              onSort: (index, _) => _handleSort(index),
                              onDelete: (item) async {
                                if (item.id != null && item.id!.isNotEmpty) {
                                  await store.delete(item.id!);
                                  await _refresh(store);
                                }
                              },
                              onTapItem: widget.onTapItem,
                              initiallyExpanded: _isExpanded(k),
                              onExpansionChanged: (open) => _setExpanded(k, open),

                              // repasse dos mapas DFD
                              regionByContractId: _regionById,
                              processNumberByContractId: _processNumberById,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: ContractAddButton(
        isEditable: true,
        onAdd: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TabBarHingPage(contractData: ProcessData()),
            ),
          );
          if (result == true) {
            await _refresh(store);
          }
        },
      ),
      bottomNavigationBar: const FootBar(),
    );
  }
}

// Corrige import antigo gerado pelo IDE (caso necessário)
class TabBarHingPage extends TabBarHiringPage {
  const TabBarHingPage({super.key, required super.contractData});
}
