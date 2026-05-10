// lib/_blocs/modules/actives/oaes/active_oaes_cubit.dart

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/permission/permission_data.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';

import 'active_oaes_data.dart';
import 'active_oaes_repository.dart';
import 'active_oaes_state.dart';

class ActiveOaesCubit extends Cubit<ActiveOaesState> {
  ActiveOaesCubit({
    ActiveOaesRepository? repository,
    UserPermissionData? initialPermissions,
    String? tenantId,
    String? initialTenantId,
    this.moduleId = 'active-oaes-records',
  })  : _repo = repository ??
      ActiveOaesRepository(
        tenantId: tenantId ?? initialTenantId,
      ),
        _currentPermissions = initialPermissions,
        super(ActiveOaesState()) {
    emit(
      state.copyWith(
        isEditable: _canWrite(),
      ),
    );
  }

  final ActiveOaesRepository _repo;
  final String moduleId;

  UserPermissionData? _currentPermissions;

  ActiveOaesRepository get repository => _repo;

  String? get currentTenantId => _repo.currentTenantId;

  bool get hasTenant => _repo.hasTenant;

  bool get isEditable => _canWrite();

  // ---------------------------------------------------------------------------
  // Tenant
  // ---------------------------------------------------------------------------

  void setTenantId(String? tenantId) {
    setActiveTenantId(tenantId);
  }

  void setActiveTenantId(String? tenantId) {
    final before = _repo.currentTenantId;

    _repo.setActiveTenantId(tenantId);

    final after = _repo.currentTenantId;

    if (before == after) {
      emit(
        state.copyWith(
          isEditable: _canWrite(),
        ),
      );
      return;
    }

    emit(
      ActiveOaesState(
        isEditable: _canWrite(),
      ),
    );
  }

  void updatePermissions({
    UserPermissionData? permissions,
    String? tenantId,
  }) {
    final before = _repo.currentTenantId;

    _currentPermissions = permissions ?? _currentPermissions;

    if (tenantId != null) {
      _repo.setActiveTenantId(tenantId);
    }

    final after = _repo.currentTenantId;

    if (before != after) {
      emit(
        ActiveOaesState(
          isEditable: _canWrite(),
        ),
      );

      unawaited(warmup());
      return;
    }

    emit(
      state.copyWith(
        isEditable: _canWrite(),
      ),
    );
  }

  String _requireTenantId() {
    final tenantId = _repo.currentTenantId;

    if (tenantId == null || tenantId.trim().isEmpty) {
      throw Exception(
        'Nenhuma empresa ativa foi selecionada para acessar OAEs.',
      );
    }

    return tenantId;
  }

  // ---------------------------------------------------------------------------
  // Permissões
  // ---------------------------------------------------------------------------

  bool _canWrite() {
    final permissions = _currentPermissions;
    final tenantId = _repo.currentTenantId;

    if (permissions == null) return false;

    if (permissions.isGlobalSuperUser ||
        permissions.isSuperUserForTenant(tenantId)) {
      return true;
    }

    return permissions.canModuleString(
      module: moduleId,
      action: 'create',
      tenantId: tenantId,
    ) ||
        permissions.canModuleString(
          module: moduleId,
          action: 'edit',
          tenantId: tenantId,
        ) ||
        permissions.canModuleString(
          module: moduleId,
          action: 'delete',
          tenantId: tenantId,
        );
  }

  bool _canDelete() {
    final permissions = _currentPermissions;
    final tenantId = _repo.currentTenantId;

    if (permissions == null) return false;

    if (permissions.isGlobalSuperUser ||
        permissions.isSuperUserForTenant(tenantId)) {
      return true;
    }

    return permissions.canModuleString(
      module: moduleId,
      action: 'delete',
      tenantId: tenantId,
    );
  }

  void _assertCanWrite() {
    final tenantId = _requireTenantId();

    if (_canWrite()) return;

    throw Exception(
      'Usuário sem permissão para alterar OAEs. '
          'Módulo: $moduleId | tenantId: $tenantId',
    );
  }

  void _assertCanDelete() {
    final tenantId = _requireTenantId();

    if (_canDelete()) return;

    throw Exception(
      'Usuário sem permissão para apagar OAEs. '
          'Módulo: $moduleId | tenantId: $tenantId',
    );
  }

  // ---------------------------------------------------------------------------
  // Loaders
  // ---------------------------------------------------------------------------

  Future<void> warmup() async {
    if (!_repo.hasTenant) {
      emit(
        ActiveOaesState(
          isEditable: _canWrite(),
        ),
      );
      return;
    }

    if (state.initialized && state.loadStatus == ActiveOaesLoadStatus.success) {
      return;
    }

    await _loadAll(setInitialized: true);
  }

  Future<void> refresh() async {
    if (!_repo.hasTenant) {
      emit(
        ActiveOaesState(
          isEditable: _canWrite(),
        ),
      );
      return;
    }

    await _loadAll(setInitialized: state.initialized);
  }

  Future<void> _loadAll({required bool setInitialized}) async {
    if (!_repo.hasTenant) {
      emit(
        ActiveOaesState(
          isEditable: _canWrite(),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        loadStatus: ActiveOaesLoadStatus.loading,
        error: null,
        isEditable: _canWrite(),
      ),
    );

    try {
      final list = await _repo.fetchAll();
      final regions = _buildRegionLabelsFromList(list);

      emit(
        state.copyWith(
          initialized: setInitialized ? true : state.initialized,
          all: list,
          regionLabels: regions,
          loadStatus: ActiveOaesLoadStatus.success,
          error: null,
          isEditable: _canWrite(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loadStatus: ActiveOaesLoadStatus.failure,
          error: e.toString(),
          isEditable: _canWrite(),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Regiões
  // ---------------------------------------------------------------------------

  List<String> _buildRegionLabelsFromList(List<ActiveOaesData> source) {
    final map = <String, String>{};

    for (final oae in source) {
      final raw = (oae.region ?? '').trim();
      if (raw.isEmpty) continue;

      final key = raw.toUpperCase();

      map.putIfAbsent(key, () => raw);
    }

    final labels = map.values.toList();
    labels.sort((a, b) => a.toUpperCase().compareTo(b.toUpperCase()));

    return labels;
  }

  ActiveOaesState _withRebuiltRegions(List<ActiveOaesData> all) {
    final regions = _buildRegionLabelsFromList(all);

    return state.copyWith(
      all: all,
      regionLabels: regions,
    );
  }

  void syncRegionsFromTenantItems(List<String> tenantRegions) {
    final labels = tenantRegions
        .map((region) => region.trim())
        .where((label) => label.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toUpperCase().compareTo(b.toUpperCase()));

    emit(
      state.copyWith(
        regionLabels: labels,
      ),
    );
  }

  void syncRegionsFromSetup(List<String> tenantRegions) {
    syncRegionsFromTenantItems(tenantRegions);
  }

  // ---------------------------------------------------------------------------
  // Seleção / Form
  // ---------------------------------------------------------------------------

  void selectByIndex(int index) {
    if (index < 0 || index >= state.all.length) return;

    final selected = state.all[index];

    emit(
      state.copyWith(
        selectedIndex: index,
        form: ActiveOaesData.fromData(selected),
      ),
    );
  }

  ActiveOaesData? findById(String id) {
    final cleanId = id.trim();

    if (cleanId.isEmpty) return null;

    for (final item in state.all) {
      if (item.id == cleanId) return item;
    }

    return null;
  }

  void clearSelection() {
    emit(
      state.copyWith(
        selectedIndex: null,
        form: ActiveOaesData(),
      ),
    );
  }

  void patchForm(ActiveOaesData data) {
    emit(
      state.copyWith(
        form: data,
      ),
    );
  }

  void clearAllFilters() {
    emit(
      state.copyWith(
        selectedPieIndexFilter: null,
        selectedRegionFilter: null,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Upsert / Delete
  // ---------------------------------------------------------------------------

  Future<ActiveOaesData?> upsert(ActiveOaesData data) async {
    _assertCanWrite();

    emit(
      state.copyWith(
        saving: true,
        error: null,
      ),
    );

    try {
      final saved = await _repo.upsert(data);

      final all = List<ActiveOaesData>.from(state.all);
      final idx = all.indexWhere((item) => item.id == saved.id);

      if (idx == -1) {
        all.add(saved);
      } else {
        all[idx] = saved;
      }

      all.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

      final nextState = _withRebuiltRegions(all).copyWith(
        initialized: true,
        form: ActiveOaesData(),
        selectedIndex: null,
        saving: false,
        loadStatus: ActiveOaesLoadStatus.success,
        error: null,
        isEditable: _canWrite(),
      );

      emit(nextState);

      return saved;
    } catch (e) {
      emit(
        state.copyWith(
          saving: false,
          error: e.toString(),
          isEditable: _canWrite(),
        ),
      );

      rethrow;
    }
  }

  Future<void> deleteById(String id) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) return;

    _assertCanDelete();

    emit(
      state.copyWith(
        saving: true,
        error: null,
      ),
    );

    try {
      await _repo.deleteById(cleanId);

      final all = List<ActiveOaesData>.from(state.all)
        ..removeWhere((item) => item.id == cleanId);

      final nextState = _withRebuiltRegions(all).copyWith(
        initialized: true,
        form: ActiveOaesData(),
        selectedIndex: null,
        saving: false,
        loadStatus: ActiveOaesLoadStatus.success,
        error: null,
        isEditable: _canWrite(),
      );

      emit(nextState);
    } catch (e) {
      emit(
        state.copyWith(
          saving: false,
          error: e.toString(),
          isEditable: _canWrite(),
        ),
      );

      rethrow;
    }
  }

  Future<void> delete(String id) async {
    await deleteById(id);
  }

  // ---------------------------------------------------------------------------
  // Anexos
  // ---------------------------------------------------------------------------

  Future<void> updateAttachments({
    required String oaeId,
    required List<Attachment> attachments,
  }) async {
    _assertCanWrite();

    final cleanId = oaeId.trim();

    if (cleanId.isEmpty) return;

    emit(
      state.copyWith(
        saving: true,
        error: null,
      ),
    );

    try {
      await _repo.setAttachments(
        oaeId: cleanId,
        attachments: attachments,
      );

      final updatedList = state.all.map((item) {
        if (item.id != cleanId) return item;

        return item.copyWith(
          attachments: attachments,
        );
      }).toList();

      final updatedForm = state.form.id == cleanId
          ? state.form.copyWith(attachments: attachments)
          : state.form;

      final nextState = _withRebuiltRegions(updatedList).copyWith(
        saving: false,
        form: updatedForm,
        error: null,
        isEditable: _canWrite(),
      );

      emit(nextState);
    } catch (e) {
      emit(
        state.copyWith(
          saving: false,
          error: e.toString(),
          isEditable: _canWrite(),
        ),
      );

      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Fotos
  // ---------------------------------------------------------------------------

  Future<List<Attachment>> loadPhotos(String oaeId) async {
    if (!_repo.hasTenant) return const <Attachment>[];

    final cleanId = oaeId.trim();

    if (cleanId.isEmpty) return const <Attachment>[];

    return _repo.loadPhotos(cleanId);
  }

  Future<void> savePhotos({
    required String oaeId,
    required List<Attachment> photos,
  }) async {
    _assertCanWrite();

    final cleanId = oaeId.trim();

    if (cleanId.isEmpty) return;

    emit(
      state.copyWith(
        saving: true,
        error: null,
      ),
    );

    try {
      await _repo.savePhotos(cleanId, photos);

      emit(
        state.copyWith(
          saving: false,
          error: null,
          isEditable: _canWrite(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          saving: false,
          error: e.toString(),
          isEditable: _canWrite(),
        ),
      );

      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Filtros
  // ---------------------------------------------------------------------------

  void setPieFilter(int? pieIndex) {
    emit(
      state.copyWith(
        selectedPieIndexFilter: pieIndex,
      ),
    );
  }

  void setRegionFilter(String? regionLabel) {
    emit(
      state.copyWith(
        selectedRegionFilter: regionLabel,
      ),
    );
  }
}