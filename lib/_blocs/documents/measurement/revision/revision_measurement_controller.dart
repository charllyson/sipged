// lib/_blocs/documents/measurement/revision/revision_measurement_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siged/_blocs/documents/measurement/revision/revision_measurement_bloc.dart';
import 'package:siged/_blocs/documents/measurement/revision/revision_measurement_data.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_state.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

import 'package:siged/_blocs/documents/contracts/additives/additives_bloc.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';

import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_utils/date_utils.dart' show convertDateTimeToDDMMYYYY, convertDDMMYYYYToDateTime;
import 'package:siged/_utils/handle_selection_utils.dart';

class RevisionMeasurementController extends ChangeNotifier with FormValidationMixin {
  RevisionMeasurementController({
    required this.contract,                   // ✅ contrato vem no construtor
    required RevisionMeasurementBloc measurementBloc,
    required AdditivesBloc additivesBloc,
  })  : _measurementBloc = measurementBloc,
        _additivesBloc = additivesBloc;

  // --- Dependências
  final RevisionMeasurementBloc _measurementBloc;
  final AdditivesBloc _additivesBloc;

  // --- Contexto
  final ContractData contract;               // ✅ final, não-late
  UserData? currentUser;

  // 👇 assinatura do UserBloc
  StreamSubscription<UserState>? _userSub;

  // --- Estado UI
  bool isEditable = false;
  bool isSaving = false;
  bool formValidated = false;
  int? selectedIndex;

  // --- Dados
  List<RevisionMeasurementData> _all = <RevisionMeasurementData>[];
  List<RevisionMeasurementData> _selectorUniverse = <RevisionMeasurementData>[];

  // --- Paginação
  final int _itemsPerPage = 50;
  int _currentPage = 1;
  int _totalPages = 1;
  List<RevisionMeasurementData> _pageItems = <RevisionMeasurementData>[];

  // --- Seleção
  RevisionMeasurementData? _selected;
  String? _currentId;

  // --- Totais
  double _valorInicialContrato = 0.0;
  double _totalAditivos = 0.0;

  // --- Controllers de formulário
  final orderCtrl = TextEditingController();
  final processCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final dateCtrl = TextEditingController();

  // --- Guard init ---
  bool _didInit = false;

  // === Getters usados pela UI ===
  List<RevisionMeasurementData> get revision => _all;
  List<RevisionMeasurementData> get selectorUniverse => _selectorUniverse;
  List<RevisionMeasurementData> get pageItems => _pageItems;

  RevisionMeasurementData? get selectedRevision => _selected;
  String? get currentRevisionId => _currentId;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  double get valorInicialContrato => _valorInicialContrato;
  double get totalAditivos => _totalAditivos;

  List<String> get labels =>
      _selectorUniverse.map((m) => (m.order ?? 0).toString()).toList();

  List<double> get values =>
      _selectorUniverse.map((m) => m.value ?? 0.0).toList();

  double get totalMedicoes => values.fold<double>(0.0, (a, b) => a + b);
  double get valorTotalDisponivel => _valorInicialContrato + _totalAditivos;
  double get saldo => valorTotalDisponivel - totalMedicoes;

  // === Init/Dispose ===
  Future<void> init(BuildContext context) async {
    if (_didInit) return;
    _didInit = true;

    // usuário atual e permissão
    final userBloc = context.read<UserBloc>();
    currentUser = userBloc.state.current;
    isEditable = _canEditUser(currentUser);

    // assina mudanças de usuário
    _userSub?.cancel();
    _userSub = userBloc.stream.listen((st) {
      final prevId = currentUser?.id;
      currentUser = st.current;
      final nowId = currentUser?.id;

      final newEditable = _canEditUser(currentUser);
      if (newEditable != isEditable || prevId != nowId) {
        isEditable = newEditable;
        notifyListeners();
      }
    });

    setupValidation([orderCtrl, processCtrl, valueCtrl, dateCtrl], _validateFormInternal);
    await _loadInitial();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    removeValidation([orderCtrl, processCtrl, valueCtrl, dateCtrl], _validateFormInternal);
    orderCtrl.dispose();
    processCtrl.dispose();
    valueCtrl.dispose();
    dateCtrl.dispose();
    super.dispose();
  }

  // === Permissões ===
  bool _canEditUser(UserData? user) {
    if (user == null) return false;
    final base = (user.baseProfile ?? '').toLowerCase();
    if (base == 'administrador' || base == 'colaborador') return true;

    final perms = user.modulePermissions['measurement_revision'];
    if (perms != null) return (perms['edit'] == true) || (perms['create'] == true);
    return false;
  }

  // === Load ===
  Future<void> _loadInitial() async {
    _valorInicialContrato = contract.initialValueContract ?? 0.0;
    if (contract.id != null) {
      _totalAditivos = await _additivesBloc.getAllAdditivesValue(contract.id!);
      _all = await _measurementBloc.getAllRevisionsOfContract(uidContract: contract.id!);
    } else {
      _totalAditivos = 0.0;
      _all = [];
    }

    _all.sort((a, b) {
      final ao = a.order ?? -1;
      final bo = b.order ?? -1;
      if (ao != bo) return ao.compareTo(bo);
      final ad = a.date?.millisecondsSinceEpoch ?? 0;
      final bd = b.date?.millisecondsSinceEpoch ?? 0;
      return ad.compareTo(bd);
    });

    _selectorUniverse = List<RevisionMeasurementData>.from(_all);

    // sugere próxima ordem
    final last = _selectorUniverse.isNotEmpty
        ? _selectorUniverse.map((e) => e.order ?? 0).reduce((a, b) => a > b ? a : b)
        : 0;
    orderCtrl.text = (last + 1).toString();

    _currentPage = 1;
    _refreshPagination();
    notifyListeners();
  }

  void _refreshPagination() {
    final total = _selectorUniverse.length;
    _totalPages = (total == 0) ? 1 : ((total - 1) ~/ _itemsPerPage + 1);
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage > total) ? total : start + _itemsPerPage;
    _pageItems = (start < end) ? _selectorUniverse.sublist(start, end) : <RevisionMeasurementData>[];
  }

  Future<void> loadPage(int page) async {
    if (page < 1 || page > _totalPages) return;
    _currentPage = page;
    _refreshPagination();
    notifyListeners();
  }

  // === Form/Validação ===
  void _validateFormInternal() {
    final valid = areFieldsFilled([orderCtrl, processCtrl, valueCtrl, dateCtrl], minLength: 1);
    if (formValidated != valid) {
      formValidated = valid;
      notifyListeners();
    }
  }

  // === Seleção (gráfico/tabela) ===
  void onSelectGraphIndex(int index) {
    selectedIndex = index;
    if (index >= 0 && index < _selectorUniverse.length) {
      handleSelect(_selectorUniverse[index]);
    } else {
      notifyListeners();
    }
  }

  void selectRow(RevisionMeasurementData data) {
    final idx = _selectorUniverse.indexOf(data);
    if (idx == -1) return;

    selectedIndex = idx;
    _selected = data;
    _currentId = data.id;

    orderCtrl.text = '${data.order ?? ''}';
    processCtrl.text = data.numberprocess ?? '';
    valueCtrl.text = priceToString(data.value);
    dateCtrl.text = convertDateTimeToDDMMYYYY(data.date);

    _validateFormInternal();
    notifyListeners();
  }

  void handleSelect(RevisionMeasurementData data) {
    handleGenericSelection<RevisionMeasurementData>(
      data: data,
      list: _selectorUniverse,
      getOrder: (e) => e.order,
      onSetState: (index) {
        selectedIndex = index;
        _selected = data;
        _currentId = data.id;
        selectRow(data);
      },
    );
  }

  void createNew() {
    final last = _selectorUniverse.isNotEmpty
        ? _selectorUniverse.map((e) => e.order ?? 0).reduce((a, b) => a > b ? a : b)
        : 0;

    selectedIndex = null;
    _selected = null;
    _currentId = null;

    orderCtrl.text = (last + 1).toString();
    processCtrl.clear();
    valueCtrl.clear();
    dateCtrl.clear();

    _validateFormInternal();
    notifyListeners();
  }

  // === CRUD ===
  Future<bool> saveOrUpdate({
    required Future<bool> Function() onConfirm,
    VoidCallback? onSuccessSnack,
    VoidCallback? onErrorSnack,
  }) async {
    final confirmed = await onConfirm();
    if (!confirmed) return false;

    try {
      isSaving = true;
      notifyListeners();

      final novo = RevisionMeasurementData(
        id: _currentId,
        contractId: contract.id!,
        order: int.tryParse(orderCtrl.text),
        numberprocess: processCtrl.text,
        value: parseCurrencyToDouble(valueCtrl.text),
        date: convertDDMMYYYYToDateTime(dateCtrl.text),
      );

      await _measurementBloc.saveOrUpdateRevision(
        contractId: contract.id!,
        revisionMeasurementId: _currentId ?? '',
        rev: novo,
      );

      await _loadInitial();
      createNew();

      onSuccessSnack?.call();
      return true;
    } catch (_) {
      onErrorSnack?.call();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> saveExact(
      RevisionMeasurementData data, {
        VoidCallback? onSuccess,
        VoidCallback? onError,
      }) async {
    try {
      isSaving = true;
      notifyListeners();

      final toSave = RevisionMeasurementData(
        id: data.id,
        contractId: contract.id!,
        order: data.order,
        numberprocess: data.numberprocess,
        value: data.value,
        date: data.date,
      );

      await _measurementBloc.saveOrUpdateRevision(
        contractId: contract.id!,
        revisionMeasurementId: data.id ?? '',
        rev: toSave,
      );

      await _loadInitial();
      createNew();
      onSuccess?.call();
    } catch (_) {
      onError?.call();
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deleteById(
      String idRevisionMeasurement, {
        VoidCallback? onSuccessSnack,
        VoidCallback? onErrorSnack,
      }) async {
    try {
      await _measurementBloc.deleteRevision(
        contractId: contract.id!,
        revisionId: idRevisionMeasurement,
      );
      await _loadInitial();
      selectedIndex = null;
      onSuccessSnack?.call();
    } catch (_) {
      onErrorSnack?.call();
    } finally {
      notifyListeners();
    }
  }

  // === PDF ===
  Future<void> savePdfUrl(String url) async {
    if (_selected?.id == null) return;
    await _measurementBloc.salvarUrlPdfDaRevisionMeasurement(
      contractId: contract.id!,
      revisionMeasurementId: _selected!.id!,
      url: url,
    );
  }
}
