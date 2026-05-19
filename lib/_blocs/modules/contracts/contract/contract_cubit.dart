import 'package:flutter_bloc/flutter_bloc.dart';

import 'contract_data.dart';
import 'contract_repository.dart';
import 'contract_state.dart';

import 'package:sipged/_blocs/system/module/module_catalog.dart';
import 'package:sipged/_blocs/system/permission/permission_data.dart';
import 'package:sipged/_blocs/system/permission/permission_resolver.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

class ContractCubit extends Cubit<ContractState> {
  ContractCubit({
    required ContractRepository repository,
  })  : _repository = repository,
        super(ContractState.initial());

  final ContractRepository _repository;

  List<ContractData> get allProcesses => state.allProcesses;
  ContractData? get selectedProcess => state.selectedProcess;
  bool get isLoading => state.loading;
  bool get isInitialized => state.initialized;

  String get activePermissionModule {
    final current = state.activePermissionModule?.trim();

    if (current != null && current.isNotEmpty) {
      return current;
    }

    return ModuleCatalog.modContractsList;
  }

  String? get activeTenantId {
    final current = state.activeTenantId?.trim();

    if (current == null || current.isEmpty) return null;

    return current;
  }

  Future<void> warmup({
    UserData? currentUser,
    UserPermissionData? currentPermissions,
    required String tenantId,
    String permissionModule = ModuleCatalog.modContractsList,
    bool force = false,
  }) async {
    final cleanModule = _cleanPermissionModule(permissionModule);
    final cleanTenantId = _cleanRequiredTenantId(tenantId);

    if (!force &&
        state.initialized &&
        !state.loading &&
        state.activePermissionModule == cleanModule &&
        state.activeTenantId == cleanTenantId) {
      return;
    }

    await refresh(
      currentUser: currentUser,
      currentPermissions: currentPermissions,
      tenantId: cleanTenantId,
      permissionModule: cleanModule,
      force: force,
    );

    if (isClosed) return;

    emit(
      state.copyWith(
        initialized: true,
        activeTenantId: cleanTenantId,
        activePermissionModule: cleanModule,
      ),
    );
  }

  Future<void> refresh({
    UserData? currentUser,
    UserPermissionData? currentPermissions,
    required String tenantId,
    String permissionModule = ModuleCatalog.modContractsList,
    bool force = false,
  }) async {
    final cleanModule = _cleanPermissionModule(permissionModule);
    final cleanTenantId = _cleanRequiredTenantId(tenantId);

    if (state.loading && !force) {
      return;
    }

    emit(
      state.copyWith(
        loading: true,
        activeTenantId: cleanTenantId,
        activePermissionModule: cleanModule,
        clearErrorMessage: true,
      ),
    );

    try {
      final permissions = currentPermissions ?? _permissionsFromUser(currentUser);

      if (permissions == null) {
        if (isClosed) return;

        emit(
          state.copyWith(
            loading: false,
            initialized: false,
            allProcesses: const <ContractData>[],
            clearSelectedProcess: true,
            activeTenantId: cleanTenantId,
            activePermissionModule: cleanModule,
            errorMessage: 'Permissões do usuário não carregadas.',
          ),
        );
        return;
      }

      final loaded = await _repository.getAllContracts(
        tenantId: cleanTenantId,
      );

      final filtered = _applyAclFilter(
        source: loaded,
        permissions: permissions,
        tenantId: cleanTenantId,
        permissionModule: cleanModule,
      );

      ContractData? selected = state.selectedProcess;

      if (selected != null) {
        selected = _findByIdOrNull(
          filtered,
          selected.id,
        );
      }

      if (isClosed) return;

      emit(
        state.copyWith(
          loading: false,
          initialized: true,
          allProcesses: filtered,
          selectedProcess: selected,
          clearSelectedProcess: selected == null,
          activeTenantId: cleanTenantId,
          activePermissionModule: cleanModule,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;

      emit(
        state.copyWith(
          loading: false,
          activeTenantId: cleanTenantId,
          activePermissionModule: cleanModule,
          errorMessage: 'Erro ao carregar contratos: $e',
        ),
      );
    }
  }

  List<ContractData> _applyAclFilter({
    required List<ContractData> source,
    required UserPermissionData permissions,
    required String tenantId,
    required String permissionModule,
  }) {
    final cleanTenantId = _cleanRequiredTenantId(tenantId);
    final cleanModule = _cleanPermissionModule(permissionModule);

    return SystemPermission.filterVisibleContracts(
      permissions: permissions,
      contracts: source,
      module: cleanModule,
      tenantId: cleanTenantId,
    );
  }

  String _cleanPermissionModule(String? permissionModule) {
    final clean = permissionModule?.trim();

    if (clean == null || clean.isEmpty) {
      return ModuleCatalog.modContractsList;
    }

    return clean;
  }

  String _cleanRequiredTenantId(String? tenantId) {
    final clean = PermissionResolver.cleanTenantId(tenantId);

    if (clean == null || clean.trim().isEmpty) {
      throw ArgumentError('tenantId é obrigatório para carregar contratos.');
    }

    return clean.trim();
  }

  String? _activeTenantOrEmitError() {
    final clean = state.activeTenantId?.trim();

    if (clean != null && clean.isNotEmpty) {
      return clean;
    }

    if (!isClosed) {
      emit(
        state.copyWith(
          loading: false,
          errorMessage: 'Tenant ativo não informado para acessar contratos.',
        ),
      );
    }

    return null;
  }

  UserPermissionData? _permissionsFromUser(UserData? user) {
    if (user == null) return null;

    final uid = (user.uid ?? '').trim();

    if (uid.isEmpty) return null;

    final raw = user.userSnap?.data();

    if (raw is Map<String, dynamic>) {
      return UserPermissionData.fromMap(
        uid: uid,
        map: raw,
      );
    }

    return UserPermissionData(
      uid: uid,
    );
  }

  ContractData? _findByIdOrNull(
      Iterable<ContractData> items,
      String? id,
      ) {
    final cleanId = id?.trim();

    if (cleanId == null || cleanId.isEmpty) {
      return null;
    }

    for (final item in items) {
      if ((item.id ?? '').trim() == cleanId) {
        return item;
      }
    }

    return null;
  }

  void select(ContractData process) {
    if (isClosed) return;

    emit(
      state.copyWith(
        selectedProcess: process,
      ),
    );
  }

  void clearSelection() {
    if (isClosed) return;

    emit(
      state.copyWith(
        clearSelectedProcess: true,
      ),
    );
  }

  Future<ContractData?> getById(
      String id, {
        bool forceServer = false,
      }) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) return null;

    final cleanTenantId = _activeTenantOrEmitError();

    if (cleanTenantId == null) return null;

    if (!forceServer) {
      final cached = _findInCache(cleanId);

      if (cached != null) {
        return cached;
      }
    }

    emit(
      state.copyWith(
        loading: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final process = await _repository.getContractById(
        id: cleanId,
        tenantId: cleanTenantId,
        forceServer: forceServer,
      );

      if (process == null) {
        if (isClosed) return null;

        emit(
          state.copyWith(
            loading: false,
          ),
        );

        return null;
      }

      final updatedList = List<ContractData>.from(state.allProcesses);

      final index = updatedList.indexWhere(
            (p) => (p.id ?? '').trim() == cleanId,
      );

      if (index >= 0) {
        updatedList[index] = process;
      } else {
        updatedList.add(process);
      }

      final updatedSelected =
      (state.selectedProcess?.id ?? '').trim() == cleanId
          ? process
          : state.selectedProcess;

      if (isClosed) return process;

      emit(
        state.copyWith(
          loading: false,
          allProcesses: updatedList,
          selectedProcess: updatedSelected,
          clearErrorMessage: true,
        ),
      );

      return process;
    } catch (e) {
      if (isClosed) return null;

      emit(
        state.copyWith(
          loading: false,
          errorMessage: 'Erro ao buscar contrato por id: $e',
        ),
      );

      return null;
    }
  }

  Future<ContractData?> getSpecificContract({
    required String uidContract,
  }) async {
    final cleanId = uidContract.trim();

    if (cleanId.isEmpty) return null;

    final cleanTenantId = _activeTenantOrEmitError();

    if (cleanTenantId == null) return null;

    emit(
      state.copyWith(
        loading: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final process = await _repository.getSpecificContract(
        uidContract: cleanId,
        tenantId: cleanTenantId,
        forceServer: true,
      );

      if (process == null) {
        if (isClosed) return null;

        emit(
          state.copyWith(
            loading: false,
          ),
        );

        return null;
      }

      final updatedList = List<ContractData>.from(state.allProcesses);

      final index = updatedList.indexWhere(
            (p) => (p.id ?? '').trim() == process.id,
      );

      if (index >= 0) {
        updatedList[index] = process;
      } else {
        updatedList.add(process);
      }

      final selected = state.selectedProcess?.id == process.id
          ? process
          : state.selectedProcess;

      if (isClosed) return process;

      emit(
        state.copyWith(
          loading: false,
          allProcesses: updatedList,
          selectedProcess: selected,
          clearErrorMessage: true,
        ),
      );

      return process;
    } catch (e) {
      if (isClosed) return null;

      emit(
        state.copyWith(
          loading: false,
          errorMessage: 'Erro ao buscar contrato específico: $e',
        ),
      );

      return null;
    }
  }

  Future<void> delete(String id) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) return;

    final cleanTenantId = _activeTenantOrEmitError();

    if (cleanTenantId == null) return;

    emit(
      state.copyWith(
        loading: true,
        clearErrorMessage: true,
      ),
    );

    try {
      await _repository.delete(
        id: cleanId,
        tenantId: cleanTenantId,
      );

      final updatedList = List<ContractData>.from(state.allProcesses)
        ..removeWhere((p) => (p.id ?? '').trim() == cleanId);

      final shouldClearSelected =
          (state.selectedProcess?.id ?? '').trim() == cleanId;

      if (isClosed) return;

      emit(
        state.copyWith(
          loading: false,
          allProcesses: updatedList,
          clearSelectedProcess: shouldClearSelected,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;

      emit(
        state.copyWith(
          loading: false,
          errorMessage: 'Erro ao excluir contrato: $e',
        ),
      );
    }
  }

  Future<void> updateContractPermissions({
    required String contractId,
    required String userId,
    required String permissionType,
    required bool value,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanUserId = userId.trim();
    final cleanType = permissionType.trim();
    final cleanTenantId = _activeTenantOrEmitError();

    if (cleanTenantId == null) return;

    if (cleanContractId.isEmpty || cleanUserId.isEmpty || cleanType.isEmpty) {
      return;
    }

    emit(
      state.copyWith(
        loading: true,
        clearErrorMessage: true,
      ),
    );

    try {
      await _repository.updateContractPermissions(
        contractId: cleanContractId,
        userId: cleanUserId,
        permissionType: cleanType,
        value: value,
        tenantId: cleanTenantId,
      );

      _updateItemInState(
        cleanContractId,
            (process) => process.copyWithUpdatedPermission(
          userId: cleanUserId,
          permissionType: cleanType,
          value: value,
        ),
      );

      if (isClosed) return;

      emit(
        state.copyWith(
          loading: false,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;

      emit(
        state.copyWith(
          loading: false,
          errorMessage: 'Erro ao atualizar permissão do contrato: $e',
        ),
      );
    }
  }

  Future<void> setParticipantPerms({
    required String contractId,
    required String userId,
    required Map<String, bool> permsMap,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanUserId = userId.trim();
    final cleanTenantId = _activeTenantOrEmitError();

    if (cleanTenantId == null) return;

    if (cleanContractId.isEmpty || cleanUserId.isEmpty) {
      return;
    }

    emit(
      state.copyWith(
        loading: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final normalized = SystemPermission.normalizeDocPerms(permsMap);

      await _repository.setParticipantPerms(
        contractId: cleanContractId,
        userId: cleanUserId,
        permsMap: normalized,
        tenantId: cleanTenantId,
      );

      _updateItemInState(
        cleanContractId,
            (process) => process.copyWithParticipantPerms(
          userId: cleanUserId,
          perms: normalized,
        ),
      );

      if (isClosed) return;

      emit(
        state.copyWith(
          loading: false,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;

      emit(
        state.copyWith(
          loading: false,
          errorMessage: 'Erro ao definir permissões do participante: $e',
        ),
      );
    }
  }

  Future<void> setParticipantRole({
    required String contractId,
    required String userId,
    required String role,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanUserId = userId.trim();
    final cleanRole = role.trim();
    final cleanTenantId = _activeTenantOrEmitError();

    if (cleanTenantId == null) return;

    if (cleanContractId.isEmpty || cleanUserId.isEmpty || cleanRole.isEmpty) {
      return;
    }

    emit(
      state.copyWith(
        loading: true,
        clearErrorMessage: true,
      ),
    );

    try {
      await _repository.setParticipantRole(
        contractId: cleanContractId,
        userId: cleanUserId,
        role: cleanRole,
        tenantId: cleanTenantId,
      );

      _updateItemInState(
        cleanContractId,
            (process) => process.copyWithParticipantRole(
          userId: cleanUserId,
          role: cleanRole,
        ),
      );

      if (isClosed) return;

      emit(
        state.copyWith(
          loading: false,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;

      emit(
        state.copyWith(
          loading: false,
          errorMessage: 'Erro ao definir papel do participante: $e',
        ),
      );
    }
  }

  Future<void> saveContractPermissions(ContractData contractData) async {
    final contractId = contractData.id?.trim();
    final cleanTenantId = _activeTenantOrEmitError();

    if (cleanTenantId == null) return;

    if (contractId == null || contractId.isEmpty) {
      return;
    }

    emit(
      state.copyWith(
        loading: true,
        clearErrorMessage: true,
      ),
    );

    try {
      await _repository.saveContractPermissions(
        contractData: contractData,
        tenantId: cleanTenantId,
      );

      _updateItemInState(
        contractId,
            (_) => contractData,
      );

      if (isClosed) return;

      emit(
        state.copyWith(
          loading: false,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;

      emit(
        state.copyWith(
          loading: false,
          errorMessage: 'Erro ao salvar permissões do contrato: $e',
        ),
      );
    }
  }

  Future<void> addParticipant({
    required String contractId,
    required String userId,
    Map<String, bool>? permMap,
    Map<String, dynamic> meta = const {},
  }) async {
    final cleanContractId = contractId.trim();
    final cleanUserId = userId.trim();
    final cleanTenantId = _activeTenantOrEmitError();

    if (cleanTenantId == null) return;

    if (cleanContractId.isEmpty || cleanUserId.isEmpty) {
      return;
    }

    emit(
      state.copyWith(
        loading: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final normalizedPerms = SystemPermission.normalizeDocPerms(
        permMap ?? SystemPermission.initialDocPerms(),
      );

      await _repository.addParticipant(
        contractId: cleanContractId,
        userId: cleanUserId,
        permMap: normalizedPerms,
        meta: meta,
        tenantId: cleanTenantId,
      );

      _updateItemInState(
        cleanContractId,
            (process) => process.copyWithAddedParticipant(
          userId: cleanUserId,
          perms: normalizedPerms,
          meta: meta,
        ),
      );

      if (isClosed) return;

      emit(
        state.copyWith(
          loading: false,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;

      emit(
        state.copyWith(
          loading: false,
          errorMessage: 'Erro ao adicionar participante: $e',
        ),
      );
    }
  }

  Future<void> removeParticipant({
    required String contractId,
    required String userId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanUserId = userId.trim();
    final cleanTenantId = _activeTenantOrEmitError();

    if (cleanTenantId == null) return;

    if (cleanContractId.isEmpty || cleanUserId.isEmpty) {
      return;
    }

    emit(
      state.copyWith(
        loading: true,
        clearErrorMessage: true,
      ),
    );

    try {
      await _repository.removeParticipant(
        contractId: cleanContractId,
        userId: cleanUserId,
        tenantId: cleanTenantId,
      );

      _updateItemInState(
        cleanContractId,
            (process) => process.copyWithRemovedParticipant(cleanUserId),
      );

      if (isClosed) return;

      emit(
        state.copyWith(
          loading: false,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;

      emit(
        state.copyWith(
          loading: false,
          errorMessage: 'Erro ao remover participante: $e',
        ),
      );
    }
  }

  Future<void> updateParticipantMeta({
    required String contractId,
    required String userId,
    required Map<String, dynamic> meta,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanUserId = userId.trim();
    final cleanTenantId = _activeTenantOrEmitError();

    if (cleanTenantId == null) return;

    if (cleanContractId.isEmpty || cleanUserId.isEmpty) {
      return;
    }

    emit(
      state.copyWith(
        loading: true,
        clearErrorMessage: true,
      ),
    );

    try {
      await _repository.updateParticipantMeta(
        contractId: cleanContractId,
        userId: cleanUserId,
        meta: meta,
        tenantId: cleanTenantId,
      );

      _updateItemInState(
        cleanContractId,
            (process) => process.copyWithParticipantMeta(
          userId: cleanUserId,
          meta: meta,
        ),
      );

      if (isClosed) return;

      emit(
        state.copyWith(
          loading: false,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;

      emit(
        state.copyWith(
          loading: false,
          errorMessage: 'Erro ao atualizar metadados do participante: $e',
        ),
      );
    }
  }

  Future<void> setParticipantPermsExt({
    required String contractId,
    required String userId,
    required Map<String, bool> permsMap,
  }) async {
    await setParticipantPerms(
      contractId: contractId,
      userId: userId,
      permsMap: permsMap,
    );
  }

  Future<void> setParticipantRoleExt({
    required String contractId,
    required String userId,
    required String role,
  }) async {
    await setParticipantRole(
      contractId: contractId,
      userId: userId,
      role: role,
    );
  }

  ContractData? _findInCache(String id) {
    return _findByIdOrNull(
      state.allProcesses,
      id,
    );
  }

  void _updateItemInState(
      String contractId,
      ContractData Function(ContractData current) transform,
      ) {
    final cleanId = contractId.trim();

    if (cleanId.isEmpty) return;

    var found = false;

    final updatedList = state.allProcesses.map((item) {
      if ((item.id ?? '').trim() == cleanId) {
        found = true;
        return transform(item);
      }

      return item;
    }).toList(growable: true);

    if (!found) {
      return;
    }

    ContractData? updatedSelected = state.selectedProcess;

    if ((updatedSelected?.id ?? '').trim() == cleanId) {
      updatedSelected = transform(updatedSelected!);
    }

    if (isClosed) return;

    emit(
      state.copyWith(
        allProcesses: updatedList,
        selectedProcess: updatedSelected,
      ),
    );
  }
}