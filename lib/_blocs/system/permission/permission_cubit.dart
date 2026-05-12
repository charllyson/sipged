// lib/_blocs/system/permission/permission_cubit.dart

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/system/module/module_catalog.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import 'permission_data.dart';
import 'permission_repository.dart';

class PermissionCubit extends Cubit<PermissionState> {
  PermissionCubit({
    PermissionRepository? repository,
  })  : _repo = repository ?? PermissionRepository(),
        super(PermissionState.initial());

  final PermissionRepository _repo;

  StreamSubscription<UserPermissionData?>? _sub;

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }

  Future<void> loadByUid(String uid) async {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      emit(
        state.copyWith(
          hasLoaded: true,
          clearCurrent: true,
          clearActiveTenantId: true,
          error: 'UID do usuário não informado.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
      ),
    );

    try {
      final data = await _repo.loadUserPermissions(cleanUid);

      if (isClosed) return;

      final resolvedTenantId = _resolveActiveTenantId(
        data: data,
        preferredTenantId: state.activeTenantId,
      );

      emit(
        state.copyWith(
          isLoading: false,
          hasLoaded: true,
          current: data,
          activeTenantId: resolvedTenantId,
          clearActiveTenantId: resolvedTenantId == null,
          clearError: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;

      emit(
        state.copyWith(
          isLoading: false,
          hasLoaded: true,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> loadFromUser(UserData? user) async {
    final uid = user?.uid?.trim();

    if (uid == null || uid.isEmpty) {
      emit(
        state.copyWith(
          hasLoaded: true,
          clearCurrent: true,
          clearActiveTenantId: true,
          error: 'Usuário não informado.',
        ),
      );
      return;
    }

    await loadByUid(uid);
  }

  Future<void> watchByUid(String uid) async {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      emit(
        state.copyWith(
          realtimeEnabled: false,
          clearCurrent: true,
          clearActiveTenantId: true,
          error: 'UID do usuário não informado.',
        ),
      );
      return;
    }

    await _sub?.cancel();

    emit(
      state.copyWith(
        isLoading: true,
        realtimeEnabled: true,
        clearError: true,
      ),
    );

    _sub = _repo.watchUserPermissions(cleanUid).listen(
          (data) {
        if (isClosed) return;

        final resolvedTenantId = _resolveActiveTenantId(
          data: data,
          preferredTenantId: state.activeTenantId,
        );

        emit(
          state.copyWith(
            isLoading: false,
            hasLoaded: true,
            realtimeEnabled: true,
            current: data,
            activeTenantId: resolvedTenantId,
            clearActiveTenantId: resolvedTenantId == null,
            clearError: true,
          ),
        );
      },
      onError: (error) {
        if (isClosed) return;

        emit(
          state.copyWith(
            isLoading: false,
            hasLoaded: true,
            realtimeEnabled: true,
            error: error.toString(),
          ),
        );
      },
    );
  }

  Future<void> stopWatch() async {
    await _sub?.cancel();

    _sub = null;

    emit(
      state.copyWith(
        realtimeEnabled: false,
      ),
    );
  }

  Future<void> persistActiveTenantForCurrentUser(String? tenantId) async {
    final uid = state.current?.uid.trim();

    if (uid == null || uid.isEmpty) return;

    final cleanTenantId = _cleanTenantId(tenantId);

    await _repo.setCurrentTenantId(
      uid: uid,
      tenantId: cleanTenantId,
    );
  }

  void setActiveTenant(String? tenantId) {
    final cleanTenantId = _cleanTenantId(tenantId);

    if (cleanTenantId == null) {
      emit(
        state.copyWith(
          clearActiveTenantId: true,
          clearError: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        activeTenantId: cleanTenantId,
        clearError: true,
      ),
    );
  }

  void changeActiveTenant(String? tenantId) {
    setActiveTenant(tenantId);
  }

  Future<bool> setActiveTenantIfAllowed(
      String? tenantId, {
        bool persist = true,
      }) async {
    final cleanTenantId = _cleanTenantId(tenantId);

    if (cleanTenantId == null) {
      setActiveTenant(null);

      if (persist) {
        await persistActiveTenantForCurrentUser(null);
      }

      return true;
    }

    if (!canAccessTenant(cleanTenantId)) {
      emit(
        state.copyWith(
          error: 'Usuário sem acesso à empresa selecionada.',
        ),
      );

      return false;
    }

    setActiveTenant(cleanTenantId);

    if (persist) {
      await persistActiveTenantForCurrentUser(cleanTenantId);
    }

    return true;
  }

  bool canAccessTenant(String? tenantId) {
    final cleanTenantId = _cleanTenantId(tenantId);

    if (cleanTenantId == null) return false;

    return state.current?.canAccessTenant(cleanTenantId) == true;
  }

  List<String> enabledTenantIds() {
    return state.current?.enabledTenantIds ?? const <String>[];
  }

  SystemUserRole roleForActiveTenant() {
    return state.current?.roleForTenant(state.activeTenantId) ??
        SystemUserRole.leitor;
  }

  SystemUserRole roleForTenant(String? tenantId) {
    return state.current?.roleForTenant(_cleanTenantId(tenantId)) ??
        SystemUserRole.leitor;
  }

  bool isSuperUser({
    String? tenantId,
  }) {
    final data = state.current;

    if (data == null) return false;

    return data.isSuperUserForTenant(
      _cleanTenantId(tenantId) ?? _cleanTenantId(state.activeTenantId),
    );
  }

  PermissionSet effectiveModulePermissions({
    required String module,
    String? tenantId,
  }) {
    final data = state.current;
    final cleanModule = module.trim();

    if (data == null || cleanModule.isEmpty) {
      return PermissionSet.none;
    }

    return data.effectiveModulePermissions(
      module: cleanModule,
      tenantId: _cleanTenantId(tenantId) ?? _cleanTenantId(state.activeTenantId),
    );
  }

  bool canModule({
    required String module,
    required String action,
    String? tenantId,
  }) {
    final data = state.current;
    final cleanModule = module.trim();
    final cleanAction = action.trim().toLowerCase();

    if (data == null || cleanModule.isEmpty || cleanAction.isEmpty) {
      return false;
    }

    return data.canModuleString(
      module: cleanModule,
      action: cleanAction,
      tenantId: _cleanTenantId(tenantId) ?? _cleanTenantId(state.activeTenantId),
    );
  }

  bool canContract({
    required ContractData contract,
    required String action,
    String module = ModuleCatalog.modContractsList,
    String? tenantId,
  }) {
    final data = state.current;

    if (data == null) {
      return false;
    }

    return SystemPermission.canContract(
      permissions: data,
      contract: contract,
      action: action,
      module: module,
      tenantId: _cleanTenantId(tenantId) ?? _cleanTenantId(state.activeTenantId),
    );
  }

  List<ContractData> filterVisibleContracts({
    required Iterable<ContractData> contracts,
    String module = ModuleCatalog.modContractsList,
    String? tenantId,
  }) {
    final data = state.current;

    if (data == null) {
      return const <ContractData>[];
    }

    return SystemPermission.filterVisibleContracts(
      permissions: data,
      contracts: contracts,
      module: module,
      tenantId: _cleanTenantId(tenantId) ?? _cleanTenantId(state.activeTenantId),
    );
  }

  Future<void> setGlobalRole({
    required String uid,
    required SystemUserRole role,
  }) async {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      emit(
        state.copyWith(
          error: 'UID do usuário não informado.',
        ),
      );
      return;
    }

    try {
      await _repo.setGlobalRole(
        uid: cleanUid,
        role: role,
      );

      await loadByUid(cleanUid);
    } catch (e) {
      if (isClosed) return;

      emit(
        state.copyWith(
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> setTenantAccess({
    required String uid,
    required String tenantId,
    bool enabled = true,
    SystemUserRole? role,
    String? label,
  }) async {
    final cleanUid = uid.trim();
    final cleanTenantId = tenantId.trim();

    if (cleanUid.isEmpty || cleanTenantId.isEmpty) {
      emit(
        state.copyWith(
          error: 'UID ou empresa não informados.',
        ),
      );
      return;
    }

    try {
      await _repo.setTenantAccess(
        uid: cleanUid,
        tenantId: cleanTenantId,
        enabled: enabled,
        role: role,
        label: label,
      );

      await loadByUid(cleanUid);
    } catch (e) {
      if (isClosed) return;

      emit(
        state.copyWith(
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> removeTenantAccess({
    required String uid,
    required String tenantId,
  }) async {
    final cleanUid = uid.trim();
    final cleanTenantId = tenantId.trim();

    if (cleanUid.isEmpty || cleanTenantId.isEmpty) {
      emit(
        state.copyWith(
          error: 'UID ou empresa não informados.',
        ),
      );
      return;
    }

    try {
      await _repo.removeTenantAccess(
        uid: cleanUid,
        tenantId: cleanTenantId,
      );

      if (state.activeTenantId == cleanTenantId) {
        emit(
          state.copyWith(
            clearActiveTenantId: true,
          ),
        );
      }

      await loadByUid(cleanUid);
    } catch (e) {
      if (isClosed) return;

      emit(
        state.copyWith(
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> setTenantRole({
    required String uid,
    required String tenantId,
    required SystemUserRole role,
  }) async {
    final cleanUid = uid.trim();
    final cleanTenantId = tenantId.trim();

    if (cleanUid.isEmpty || cleanTenantId.isEmpty) {
      emit(
        state.copyWith(
          error: 'UID ou empresa não informados.',
        ),
      );
      return;
    }

    try {
      await _repo.setTenantRole(
        uid: cleanUid,
        tenantId: cleanTenantId,
        role: role,
      );

      await loadByUid(cleanUid);
    } catch (e) {
      if (isClosed) return;

      emit(
        state.copyWith(
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> setTenantModuleOverride({
    required String uid,
    required String tenantId,
    required String module,
    required PermissionSet permissions,
  }) async {
    final cleanUid = uid.trim();
    final cleanTenantId = tenantId.trim();
    final cleanModule = module.trim();

    if (cleanUid.isEmpty || cleanTenantId.isEmpty || cleanModule.isEmpty) {
      emit(
        state.copyWith(
          error: 'UID, empresa ou módulo não informados.',
        ),
      );
      return;
    }

    try {
      await _repo.setTenantModuleOverride(
        uid: cleanUid,
        tenantId: cleanTenantId,
        module: cleanModule,
        permissions: permissions,
      );

      await loadByUid(cleanUid);
    } catch (e) {
      if (isClosed) return;

      emit(
        state.copyWith(
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> setGlobalModuleOverride({
    required String uid,
    required String module,
    required PermissionSet permissions,
  }) async {
    final cleanUid = uid.trim();
    final cleanModule = module.trim();

    if (cleanUid.isEmpty || cleanModule.isEmpty) {
      emit(
        state.copyWith(
          error: 'UID ou módulo não informados.',
        ),
      );
      return;
    }

    try {
      await _repo.setGlobalModuleOverride(
        uid: cleanUid,
        module: cleanModule,
        permissions: permissions,
      );

      await loadByUid(cleanUid);
    } catch (e) {
      if (isClosed) return;

      emit(
        state.copyWith(
          error: e.toString(),
        ),
      );
    }
  }

  void clearError() {
    if (state.error == null) return;

    emit(
      state.copyWith(
        clearError: true,
      ),
    );
  }

  String? _resolveActiveTenantId({
    required UserPermissionData? data,
    required String? preferredTenantId,
  }) {
    if (data == null || data.uid.trim().isEmpty) {
      return null;
    }

    final preferred = _cleanTenantId(preferredTenantId);

    if (preferred != null && data.canAccessTenant(preferred)) {
      return preferred;
    }

    final fromData = _cleanTenantId(data.activeTenantId);

    if (fromData != null && data.canAccessTenant(fromData)) {
      return fromData;
    }

    final enabled = data.enabledTenantIds;

    if (enabled.isNotEmpty) {
      return enabled.first.trim();
    }

    return null;
  }

  String? _cleanTenantId(String? tenantId) {
    final id = tenantId?.trim();

    if (id == null || id.isEmpty) {
      return null;
    }

    return id;
  }
}

class SystemPermission {
  const SystemPermission._();

  static PermissionSet docPermissionsOf({
    required ContractData contract,
    required String uid,
  }) {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return PermissionSet.none;
    }

    final raw = contract.permissionContractId[cleanUid];

    return PermissionSet.fromDynamic(raw);
  }

  static bool canContractDocOnly({
    required UserPermissionData permissions,
    required ContractData contract,
    required String action,
    String? tenantId,
  }) {
    if (permissions.isSuperUserForTenant(_cleanTenantId(tenantId))) {
      return true;
    }

    final uid = permissions.uid.trim();
    final cleanAction = action.trim().toLowerCase();

    if (uid.isEmpty || cleanAction.isEmpty) {
      return false;
    }

    final docPerms = docPermissionsOf(
      contract: contract,
      uid: uid,
    );

    return docPerms.allowsString(cleanAction);
  }

  static bool canContract({
    required UserPermissionData permissions,
    required ContractData contract,
    required String action,
    String module = ModuleCatalog.modContractsList,
    String? tenantId,
  }) {
    final cleanTenantId = _cleanTenantId(tenantId);
    final cleanModule = module.trim();
    final cleanAction = action.trim().toLowerCase();

    if (cleanModule.isEmpty || cleanAction.isEmpty) {
      return false;
    }

    if (cleanTenantId != null && cleanTenantId.isNotEmpty) {
      if (!permissions.canAccessTenant(cleanTenantId)) {
        return false;
      }
    }

    if (permissions.isSuperUserForTenant(cleanTenantId)) {
      return true;
    }

    final canModule = permissions.canModuleString(
      module: cleanModule,
      action: cleanAction,
      tenantId: cleanTenantId,
    );

    if (!canModule) {
      return false;
    }

    return canContractDocOnly(
      permissions: permissions,
      contract: contract,
      action: cleanAction,
      tenantId: cleanTenantId,
    );
  }

  static List<ContractData> filterVisibleContracts({
    required UserPermissionData permissions,
    required Iterable<ContractData> contracts,
    String module = ModuleCatalog.modContractsList,
    String? tenantId,
  }) {
    final cleanTenantId = _cleanTenantId(tenantId);
    final cleanModule = module.trim();

    if (cleanModule.isEmpty) {
      return const <ContractData>[];
    }

    if (cleanTenantId != null && cleanTenantId.isNotEmpty) {
      if (!permissions.canAccessTenant(cleanTenantId)) {
        return const <ContractData>[];
      }
    }

    if (permissions.isSuperUserForTenant(cleanTenantId)) {
      return contracts.toList(growable: false);
    }

    final canReadModule = permissions.canModuleString(
      module: cleanModule,
      action: 'read',
      tenantId: cleanTenantId,
    );

    if (!canReadModule) {
      return const <ContractData>[];
    }

    return contracts
        .where(
          (contract) => canContract(
        permissions: permissions,
        contract: contract,
        action: 'read',
        module: cleanModule,
        tenantId: cleanTenantId,
      ),
    )
        .toList(growable: false);
  }

  static Map<String, bool> initialDocPerms() {
    return const {
      'read': true,
      'create': false,
      'edit': false,
      'delete': false,
      'approve': false,
    };
  }

  static Map<String, bool> normalizeDocPerms(dynamic raw) {
    return PermissionSet.fromDynamic(raw).toBoolMap();
  }

  static String? _cleanTenantId(String? tenantId) {
    final id = tenantId?.trim();

    if (id == null || id.isEmpty) {
      return null;
    }

    return id;
  }
}