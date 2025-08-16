// lib/screens/commons/listContracts/list_contracts_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sisged/_datas/system/user_data.dart';
import 'package:sisged/_blocs/documents/contracts/contracts/contracts_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/validity/validity_bloc.dart';
import 'package:sisged/_datas/documents/contracts/contracts/contracts_data.dart';

// ⭐️ importa o store global
import '../../../_datas/documents/contracts/contracts/contract_store.dart';

class ListContractsController extends ChangeNotifier {
  ListContractsController({
    required ContractsStore store,
    required ValidityBloc validityBloc,
    required ContractsBloc contractsBloc, // mantém referência se precisar de ações (salvar/deletar)
    bool isEditable = true,
  })  : _store = store,
        _validityBloc = validityBloc,
        _contractsBloc = contractsBloc,
        _isEditable = isEditable;

  // --- Dependências
  final ContractsStore _store;          // <- fonte da verdade (lista global + selecionado)
  final ValidityBloc _validityBloc;
  final ContractsBloc _contractsBloc;   // <- ainda útil para ações CRUD (não mais para listar)

  // --- Estado público (exposto para a UI)
  Map<String, List<ContractData>> get cachedByStatus => _cachedContractsByStatus;
  TextEditingController get statusCtrl => _statusCtrl;
  TextEditingController get searchCtrl => _searchCtrl;

  int? get sortColumnIndex => _sortColumnIndex;
  bool get isAscending => _isAscending;
  bool get isEditable => _isEditable;
  bool get initialized => _initialized;
  bool get loading => _loading;
  UserData? get currentUser => _currentUser;

  // --- Internos
  final Map<String, List<ContractData>> _cachedContractsByStatus = {};
  final _statusCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final bool _isEditable;

  Timer? _debounce;
  int? _sortColumnIndex;
  bool _isAscending = true;
  bool _initialized = false;
  bool _loading = false;
  UserData? _currentUser;

  // ---- Inicialização segura (chame quando tiver UserData)
  Future<void> initIfNeeded(UserData user) async {
    if (_initialized && _currentUser?.id == user.id) return;
    _initialized = true;
    _currentUser = user;

    // SideMenu já chama warmup(user). Mas, por segurança, se a lista estiver vazia, tenta dar um refresh.
    if (_store.all.isEmpty && !_store.loading) {
      await _store.refresh();
    }

    await applyFilters();
  }

  // ---- Busca/filtragem (AGORA em memória via store)
  Future<void> applyFilters() async {
    if (_currentUser == null) return;

    _setLoading(true);
    try {
      // Usa o filtro local do store (sem hits extras no Firestore)
      final contratosFiltrados = _store.filter(
        status: _statusCtrl.text.isNotEmpty ? _statusCtrl.text : null,
        searchText: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      );

      _cachedContractsByStatus
        ..clear();

      for (final c in contratosFiltrados) {
        final status = (c.contractStatus ?? 'SEM STATUS').toUpperCase();
        _cachedContractsByStatus.putIfAbsent(status, () => []).add(c);
      }

      _applyLocalSortIfAny();
    } finally {
      _setLoading(false);
    }
  }

  /// “Puxar do servidor” (Firestore) sob demanda.
  /// Mantém o selecionado e atualiza a lista global dentro do store.
  Future<void> refresh() async {
    _setLoading(true);
    try {
      await _store.refresh();
      await applyFilters();
    } finally {
      _setLoading(false);
    }
  }

  // ---- Debounce da busca
  void onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (_searchCtrl.text != value) _searchCtrl.text = value;
      await applyFilters();
    });
  }

  // ---- Ordenação (apenas flags; a ordenação efetiva é local)
  void handleSort(int columnIndex) {
    if (_sortColumnIndex == columnIndex) {
      _isAscending = !_isAscending;
    } else {
      _sortColumnIndex = columnIndex;
      _isAscending = true;
    }
    _applyLocalSortIfAny();
    notifyListeners();
  }

  void _applyLocalSortIfAny() {
    if (_sortColumnIndex == null) return;

    // Exemplo simples: ordena por summarySubjectContract quando columnIndex == 0
    // Ajuste os critérios conforme as colunas da sua tabela.
    final byName = _sortColumnIndex == 0;
    if (!byName) return;

    int cmp(ContractData a, ContractData b) {
      final an = (a.summarySubjectContract ?? '').toUpperCase();
      final bn = (b.summarySubjectContract ?? '').toUpperCase();
      return an.compareTo(bn);
    }

    for (final entry in _cachedContractsByStatus.entries) {
      entry.value.sort((a, b) => _isAscending ? cmp(a, b) : cmp(b, a));
    }
  }

  // ---- Utilidades expostas (caso a UI precise)
  ValidityBloc get validityBloc => _validityBloc;
  ContractsBloc get contractsBloc => _contractsBloc;
  ContractsStore get store => _store;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _statusCtrl.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ---- Helper estático para obter do contexto
  static ListContractsController of(BuildContext context, {bool listen = true}) =>
      Provider.of<ListContractsController>(context, listen: listen);

  // ---- Fábrica prática para usar no Provider
  static ListContractsController create(BuildContext context) {
    return ListContractsController(
      store: context.read<ContractsStore>(),        // ⭐️ agora lendo o store
      validityBloc: context.read<ValidityBloc>(),
      contractsBloc: context.read<ContractsBloc>(), // mantém para ações CRUD
      isEditable: true,
    );
  }
}
