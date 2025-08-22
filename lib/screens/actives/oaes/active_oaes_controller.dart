import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';

import 'package:sisged/_datas/actives/oaes/active_oaes_data.dart';
import 'package:sisged/_datas/actives/oaes/active_oaes_store.dart';
import 'package:sisged/_datas/system/user_data.dart';
import 'package:sisged/_widgets/map/markers/tagged_marker.dart';

class ActiveOaesController extends ChangeNotifier {
  ActiveOaesController({
    required ActiveOaesStore store,
    required UserData currentUser, // ✅ injete o usuário atual
  })  : _store = store,
        _currentUser = currentUser {
    _storeListener = () => _syncFromStore();
    _store.addListener(_storeListener);
    _syncFromStore(); // estado inicial
    // define ordem inicial
    form.order = _nextOrder();
    _isEditable = _canEditUser(_currentUser);
    _validateForm();
  }

  final ActiveOaesStore _store;
  late final VoidCallback _storeListener;

  // ---- STATE ----
  bool _saving = false;
  bool _editingMode = false;
  bool _formValid = false;
  bool _isEditable = false;

  bool _loading = false;
  List<ActiveOaesData> _all = const [];
  List<TaggedChangedMarker<ActiveOaesData>> _markers = const [];

  int? _selectedIndex;
  UserData _currentUser;

  ActiveOaesData form = ActiveOaesData();

  bool get loading => _loading;
  bool get saving => _saving;
  bool get editingMode => _editingMode;
  bool get formValid => _formValid;
  bool get isEditable => _isEditable;

  List<ActiveOaesData> get all => _all;
  List<TaggedChangedMarker<ActiveOaesData>> get markers => _markers;
  int? get selectedIndex => _selectedIndex;

  // ---- INIT/REFRESH ----
  Future<void> init(UserData user) async {
    if (_currentUser.id == user.id && _store.initialized) return;
    _currentUser = user;
    _isEditable = _canEditUser(_currentUser);
    await _store.ensureAllLoaded();
    _syncFromStore();
    if (!_editingMode) {
      form.order = _nextOrder();
      _validateForm();
      notifyListeners();
    }
  }

  Future<void> load() async {
    await _store.refresh();
    _syncFromStore();
    if (!_editingMode) {
      form.order = _nextOrder();
      _validateForm();
      notifyListeners();
    }
  }

  void _syncFromStore() {
    _loading = _store.loading;
    _all = _store.all;

    final duplicated = groupBy(_all, (ActiveOaesData d) => d.order ?? -1)
        .entries
        .where((e) => e.value.length > 1 && e.key != -1)
        .toList();
    for (final dup in duplicated) {
      // ignore: avoid_print
      print('⚠️ Ordem duplicada ${dup.key}: ${dup.value.map((e) => e.id).toList()}');
    }

    _markers = _all
        .map((o) => o.toTaggedMarker())
        .whereType<TaggedChangedMarker<ActiveOaesData>>()
        .toList(growable: false);

    if (_selectedIndex != null && (_selectedIndex! < 0 || _selectedIndex! >= _all.length)) {
      _selectedIndex = null;
      _editingMode = false;
      form = ActiveOaesData()..order = _nextOrder();
      _validateForm();
    }

    notifyListeners();
  }

  // ---- SELEÇÃO ----
  void selectByIndex(int index) {
    if (index < 0 || index >= _all.length) return;
    _selectedIndex = index;
    _editingMode = true;
    form = ActiveOaesData.fromData(_all[index]);
    _validateForm();
    notifyListeners();
  }

  void clearSelectionAndReset() {
    _selectedIndex = null;
    _editingMode = false;
    form = ActiveOaesData()..order = _nextOrder();
    _validateForm();
    notifyListeners();
  }

  // ---- CRUD ----
  Future<String?> saveOrUpdate() async {
    if (!_isEditable) return 'Sem permissão para salvar/editar.';
    if (!_formValid) return 'Formulário inválido. Preencha os campos obrigatórios.';

    _saving = true;
    notifyListeners();
    try {
      await _store.saveOrUpdate(form.toData());
      clearSelectionAndReset();
      return null;
    } catch (e) {
      return 'Erro ao salvar: $e';
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<String?> deleteById(String id) async {
    if (!_isEditable) return 'Sem permissão para deletar.';
    _saving = true;
    notifyListeners();
    try {
      await _store.delete(id);
      if (_selectedIndex != null) {
        clearSelectionAndReset();
      }
      return null;
    } catch (e) {
      return 'Erro ao deletar: $e';
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  // ---- FORM BINDINGS ----
  void updateField<T>(T? value, void Function(T?) setter) {
    setter(value);
    _validateForm();
    notifyListeners();
  }

  void _validateForm() {
    _formValid = (form.order != null &&
        (form.identificationName?.trim().isNotEmpty ?? false) &&
        form.latitude != null &&
        form.longitude != null);
  }

  int _nextOrder() {
    if (_all.isEmpty) return 1;
    final last = _all.map((e) => e.order ?? 0).fold<int>(0, (a, b) => a > b ? a : b);
    return last + 1;
  }

  // ---- PERMISSÃO ----
  bool _canEditUser(UserData user) {
    final base = (user.baseProfile ?? '').toLowerCase();
    if (base == 'administrador' || base == 'colaborador') return true;
    final perms = user.modulePermissions['oaes']; // ajuste o nome do módulo se for diferente
    return (perms?['edit'] == true) || (perms?['create'] == true);
  }

  @override
  void dispose() {
    _store.removeListener(_storeListener);
    super.dispose();
  }
}
