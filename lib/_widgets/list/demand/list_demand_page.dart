import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:siged/_blocs/panels/overview-dashboard/demands_dashboard_overview_style.dart';
import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/buttons/contract_add_button.dart';
import 'package:siged/_widgets/search/search_widget.dart';
import 'package:siged/_widgets/user/user_greeting.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/screens/process/hiring/tab_bar_hiring_page.dart';

import 'package:siged/_blocs/_process/process_store.dart';
import 'list_demand_status.dart';

// 🆕 DFD
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_bloc.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';

// 🆕 EDITAL
import 'package:siged/_blocs/process/hiring/5Edital/edital_bloc.dart';
import 'package:siged/_blocs/process/hiring/5Edital/edital_data.dart';

// 🆕 PUBLICAÇÃO EXTRATO
import 'package:siged/_blocs/process/hiring/10Publicacao/publicacao_extrato_bloc.dart';
import 'package:siged/_blocs/process/hiring/10Publicacao/publicacao_extrato_data.dart';

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

  /// cache dos contratos agrupados por status (chave normalizada)
  final Map<String, List<ProcessData>> _cachedByStatus = {};

  /// chaves de grupos expandidos
  final Set<String> _expandedKeys = {};
  Set<String> _preSearchExpandedSnapshot = {};

  Timer? _debounce;

  /// cache ESTRUTURADO por contrato (sem maps de campo soltos)
  final Map<String, DfdData?> _dfdByContractId = {};
  final Map<String, EditalData?> _editalByContractId = {};
  final Map<String, PublicacaoExtratoData?> _pubByContractId = {};

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

  // ===========================================================================
  // PREFERÊNCIAS DE EXPANSÃO
  // ===========================================================================

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

  // ===========================================================================
  // HELPERS
  // ===========================================================================

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

  void _onSearchChanged(ProcessStore store, String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (_searchCtrl.text != value) _searchCtrl.text = value;
      await _applyFilters(store);
    });
  }

  Future<void> _refresh(ProcessStore store) async {
    setState(() => _loading = true);
    try {
      await store.refresh();
      // limpa caches de DFD/edital/publicação para recarregar
      _dfdByContractId.clear();
      _editalByContractId.clear();
      _pubByContractId.clear();
      await _applyFilters(store);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ===========================================================================
  // CARREGAR DFD / EDITAL / PUBLICAÇÃO PARA UMA LISTA DE CONTRATOS
  // ===========================================================================

  Future<void> _ensureDemandDataLoadedForContracts(Set<String> ids) async {
    if (ids.isEmpty) return;

    final dfdBloc = context.read<DfdBloc>();
    final editalBloc = context.read<EditalBloc>();
    final pubBloc = context.read<PublicacaoExtratoBloc>();

    final futures = <Future<void>>[];

    for (final id in ids) {
      if (id.isEmpty) continue;

      if (!_dfdByContractId.containsKey(id)) {
        futures.add(
          dfdBloc.getDataForContract(id).then((dfd) {
            _dfdByContractId[id] = dfd;
          }),
        );
      }

      if (!_editalByContractId.containsKey(id)) {
        futures.add(
          editalBloc.getDataForContract(id).then((edital) {
            _editalByContractId[id] = edital;
          }),
        );
      }

      if (!_pubByContractId.containsKey(id)) {
        futures.add(
          pubBloc.getDataForContract(id).then((pub) {
            _pubByContractId[id] = pub;
          }),
        );
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  // ===========================================================================
  // ORDENAÇÃO LOCAL (por objeto / descrição)
  // ===========================================================================

  void _applyLocalSortIfAny() {
    if (_sortColumnIndex == null) return;

    // por enquanto só tratamos ordenação pela primeira coluna (nome da obra)
    final byName = _sortColumnIndex == 0;
    if (!byName) return;

    int cmp(ProcessData a, ProcessData b) {
      final idA = _idToString(a.id);
      final idB = _idToString(b.id);

      final dfdA = idA != null ? _dfdByContractId[idA] : null;
      final dfdB = idB != null ? _dfdByContractId[idB] : null;

      final an = (dfdA?.descricaoObjeto ?? '').toUpperCase();
      final bn = (dfdB?.descricaoObjeto ?? '').toUpperCase();

      return an.compareTo(bn);
    }

    for (final e in _cachedByStatus.entries) {
      e.value.sort((a, b) => _isAscending ? cmp(a, b) : cmp(b, a));
    }
  }

  // ===========================================================================
  // FILTROS / AGRUPAMENTO
  // ===========================================================================

  Future<void> _applyFilters(ProcessStore store) async {
    setState(() => _loading = true);
    try {
      final statusFiltro =
      _statusCtrl.text.isNotEmpty ? _statusCtrl.text : null;
      final search =
      _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim();

      final base = store.all;

      final ids = <String>{
        for (final c in base)
          if (_idToString(c.id) != null) _idToString(c.id)!,
      };

      // Carrega DFD / Edital / Publicação para todos esses contratos
      await _ensureDemandDataLoadedForContracts(ids);

      Iterable<ProcessData> r = base;

      // 🔹 filtro por status da DEMANDA (statusDemanda do DfdData)
      if (statusFiltro != null && statusFiltro.isNotEmpty) {
        final alvo = statusFiltro.trim().toUpperCase();

        r = r.where((c) {
          final id = _idToString(c.id);
          if (id == null) return false;
          final dfd = _dfdByContractId[id];
          final stRaw = dfd?.statusDemanda ?? '';
          return stRaw.trim().toUpperCase() == alvo;
        });
      }

      // 🔹 filtro de busca textual
      if (search != null && search.isNotEmpty) {
        final s = search.toUpperCase();

        r = r.where((c) {
          final id = _idToString(c.id);
          if (id == null) return false;

          final dfd = _dfdByContractId[id];
          final edital = _editalByContractId[id];
          final pub = _pubByContractId[id];

          final objeto = (dfd?.descricaoObjeto ?? '').toUpperCase();
          final processo =
          (dfd?.processoAdministrativo ?? '').toUpperCase();
          final numeroContrato =
          (pub?.numeroContrato ?? '').toUpperCase();
          final vencedor = (edital?.vencedor ?? '').toUpperCase();

          return objeto.contains(s) ||
              processo.contains(s) ||
              numeroContrato.contains(s) ||
              vencedor.contains(s);
        });
      }

      final list = r.toList(growable: false);

      // 🔹 reagrupa por statusDemanda do DFD (sem fallback)
      _cachedByStatus.clear();

      for (final c in list) {
        final id = _idToString(c.id);
        final dfd = (id != null) ? _dfdByContractId[id] : null;
        final stRaw = dfd?.statusDemanda ?? '';
        final k = _norm(stRaw);
        _cachedByStatus.putIfAbsent(k, () => <ProcessData>[]).add(c);
      }

      _applyLocalSortIfAny();

      // 🔹 lógica de expansão automática durante busca
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
        // restaura estados de expansão anteriores à busca
        if (_preSearchExpandedSnapshot.isNotEmpty) {
          setState(() {
            _expandedKeys
              ..clear()
              ..addAll(_preSearchExpandedSnapshot);
            _preSearchExpandedSnapshot = {};
          });
          await _saveExpandedToPrefs();
        }

        // remove grupos vazios salvos na prefs
        setState(() {
          _expandedKeys.removeWhere(
                (k) =>
            _cachedByStatus.containsKey(k) &&
                (_cachedByStatus[k]?.isEmpty ?? true),
          );
        });
        await _saveExpandedToPrefs();

        SchedulerBinding.instance.addPostFrameCallback((_) {});
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProcessStore>();
    final User? firebaseUser = FirebaseAuth.instance.currentUser;

    final UserData? currentUser =
    context.select<UserBloc, UserData?>((b) => b.state.current);

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // primeira carga — padrão
    if (!_loading && _cachedByStatus.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (store.all.isEmpty && !store.loading) {
          await store.refresh(currentUser: currentUser);
        }
        if (mounted) {
          await _applyFilters(store);
        }
      });
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
                          children: DemandsDashboardOverviewStyle.statusMenu
                              .map((status) {
                            final label = status.$1;
                            final rawKey = status.$2;
                            final k = _norm(rawKey);
                            final items =
                                _cachedByStatus[k] ?? const <ProcessData>[];

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
                              onExpansionChanged: (open) =>
                                  _setExpanded(k, open),

                              // 🔥 passa caches já carregados
                              dfdByContractId: _dfdByContractId,
                              editalByContractId: _editalByContractId,
                              pubByContractId: _pubByContractId,
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
    );
  }
}

// Corrige import antigo gerado pelo IDE (caso necessário)
class TabBarHingPage extends TabBarHiringPage {
  const TabBarHingPage({super.key, required super.contractData});
}
