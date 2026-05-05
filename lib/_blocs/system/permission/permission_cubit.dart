// lib/_blocs/system/permission/permission_cubit.dart

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/system/module/module_data.dart';
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

      emit(
        state.copyWith(
          isLoading: false,
          hasLoaded: true,
          current: data,
          clearError: true,
        ),
      );
    } catch (e) {
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

        emit(
          state.copyWith(
            isLoading: false,
            hasLoaded: true,
            realtimeEnabled: true,
            current: data,
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

  void setActiveTenant(String? tenantId) {
    final cleanTenantId = tenantId?.trim();

    if (cleanTenantId == null || cleanTenantId.isEmpty) {
      emit(
        state.copyWith(
          clearActiveTenantId: true,
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

  bool canAccessTenant(String tenantId) {
    return state.current?.canAccessTenant(tenantId) == true;
  }

  SystemUserRole roleForActiveTenant() {
    return state.current?.roleForTenant(state.activeTenantId) ??
        SystemUserRole.leitor;
  }

  SystemUserRole roleForTenant(String? tenantId) {
    return state.current?.roleForTenant(tenantId) ?? SystemUserRole.leitor;
  }

  bool isSuperUser({
    String? tenantId,
  }) {
    final data = state.current;

    if (data == null) return false;

    return data.isSuperUserForTenant(
      tenantId ?? state.activeTenantId,
    );
  }

  PermissionSet effectiveModulePermissions({
    required String module,
    String? tenantId,
  }) {
    final data = state.current;

    if (data == null) {
      return PermissionSet.none;
    }

    return data.effectiveModulePermissions(
      module: module,
      tenantId: tenantId ?? state.activeTenantId,
    );
  }

  bool canModule({
    required String module,
    required String action,
    String? tenantId,
  }) {
    final data = state.current;

    if (data == null) {
      return false;
    }

    return data.canModuleString(
      module: module,
      action: action,
      tenantId: tenantId ?? state.activeTenantId,
    );
  }

  bool canContract({
    required ProcessData contract,
    required String action,
    String module = ModuleData.modContractsList,
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
      tenantId: tenantId ?? state.activeTenantId,
    );
  }

  List<ProcessData> filterVisibleContracts({
    required Iterable<ProcessData> contracts,
    String module = ModuleData.modContractsList,
    String? tenantId,
  }) {
    final data = state.current;

    if (data == null) {
      return const <ProcessData>[];
    }

    return SystemPermission.filterVisibleContracts(
      permissions: data,
      contracts: contracts,
      module: module,
      tenantId: tenantId ?? state.activeTenantId,
    );
  }

  Future<void> setGlobalRole({
    required String uid,
    required SystemUserRole role,
  }) async {
    try {
      await _repo.setGlobalRole(
        uid: uid,
        role: role,
      );

      await loadByUid(uid);
    } catch (e) {
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
    try {
      await _repo.setTenantAccess(
        uid: uid,
        tenantId: tenantId,
        enabled: enabled,
        role: role,
        label: label,
      );

      await loadByUid(uid);
    } catch (e) {
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
    try {
      await _repo.setTenantRole(
        uid: uid,
        tenantId: tenantId,
        role: role,
      );

      await loadByUid(uid);
    } catch (e) {
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
    try {
      await _repo.setTenantModuleOverride(
        uid: uid,
        tenantId: tenantId,
        module: module,
        permissions: permissions,
      );

      await loadByUid(uid);
    } catch (e) {
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
    try {
      await _repo.setGlobalModuleOverride(
        uid: uid,
        module: module,
        permissions: permissions,
      );

      await loadByUid(uid);
    } catch (e) {
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
}

class SystemPermission {
  const SystemPermission._();

  static PermissionSet docPermissionsOf({
    required ProcessData contract,
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
    required ProcessData contract,
    required String action,
    String? tenantId,
  }) {
    if (permissions.isSuperUserForTenant(tenantId)) {
      return true;
    }

    final uid = permissions.uid.trim();

    if (uid.isEmpty) {
      return false;
    }

    final docPerms = docPermissionsOf(
      contract: contract,
      uid: uid,
    );

    return docPerms.allowsString(action);
  }

  static bool canContract({
    required UserPermissionData permissions,
    required ProcessData contract,
    required String action,
    String module = ModuleData.modContractsList,
    String? tenantId,
  }) {
    final cleanTenantId = tenantId?.trim();

    if (cleanTenantId != null && cleanTenantId.isNotEmpty) {
      if (!permissions.canAccessTenant(cleanTenantId)) {
        return false;
      }
    }

    final canModule = permissions.canModuleString(
      module: module,
      action: action,
      tenantId: cleanTenantId,
    );

    if (!canModule) {
      return false;
    }

    if (permissions.isSuperUserForTenant(cleanTenantId)) {
      return true;
    }

    return canContractDocOnly(
      permissions: permissions,
      contract: contract,
      action: action,
      tenantId: cleanTenantId,
    );
  }

  static List<ProcessData> filterVisibleContracts({
    required UserPermissionData permissions,
    required Iterable<ProcessData> contracts,
    String module = ModuleData.modContractsList,
    String? tenantId,
  }) {
    final cleanTenantId = tenantId?.trim();

    if (permissions.isSuperUserForTenant(cleanTenantId)) {
      return contracts.toList(growable: false);
    }

    return contracts
        .where(
          (contract) => canContract(
        permissions: permissions,
        contract: contract,
        action: 'read',
        module: module,
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
}