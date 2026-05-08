import 'package:flutter_bloc/flutter_bloc.dart';

import 'contract_data.dart';
import 'contract_repository.dart';
import 'contract_state.dart';

import 'package:sipged/_blocs/system/module/module_catalog.dart';
import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
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

  Future<void> warmup({
    UserData? currentUser,
    UserPermissionData? currentPermissions,
    String? tenantId,
  }) async {
    if (state.initialized || state.loading) return;

    await refresh(
      currentUser: currentUser,
      currentPermissions: currentPermissions,
      tenantId: tenantId,
    );

    if (isClosed) return;

    emit(
      state.copyWith(
        initialized: true,
      ),
    );
  }

  Future<void> refresh({
    UserData? currentUser,
    UserPermissionData? currentPermissions,
    String? tenantId,
  }) async {
    if (state.loading) return;

    emit(
      state.copyWith(
        loading: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final permissions = currentPermissions ?? _permissionsFromUser(currentUser);

      if (permissions == null) {
        emit(
          state.copyWith(
            loading: false,
            allProcesses: const <ContractData>[],
            clearSelectedProcess: true,
            errorMessage: 'Permissões do usuário não carregadas.',
          ),
        );
        return;
      }

      final loaded = await _repository.getAllContracts();

      final filtered = _applyAclFilter(
        source: loaded,
        permissions: permissions,
        tenantId: tenantId,
      );

      ContractData? selected = state.selectedProcess;

      if (selected != null) {
        selected = _findByIdOrNull(
          filtered,
          selected.id,
        );
      }

      emit(
        state.copyWith(
          loading: false,
          allProcesses: filtered,
          selectedProcess: selected,
          clearSelectedProcess: selected == null,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          errorMessage: 'Erro ao carregar contratos: $e',
        ),
      );
    }
  }

  List<ContractData> _applyAclFilter({
    required List<ContractData> source,
    required UserPermissionData permissions,
    required String? tenantId,
  }) {
    return SystemPermission.filterVisibleContracts(
      permissions: permissions,
      contracts: source,
      module: ModuleCatalog.modContractsList,
      tenantId: PermissionResolver.cleanTenantId(tenantId),
    );
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

  Future<ContractData?> getById(String id) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) return null;

    final cached = _findInCache(cleanId);

    if (cached != null) return cached;

    emit(
      state.copyWith(
        loading: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final process = await _repository.getContractById(cleanId);

      if (process == null) {
        emit(
          state.copyWith(
            loading: false,
          ),
        );

        return null;
      }

      final updatedList = List<ContractData>.from(state.allProcesses)
        ..removeWhere((p) => p.id == process.id)
        ..add(process);

      emit(
        state.copyWith(
          loading: false,
          allProcesses: updatedList,
          clearErrorMessage: true,
        ),
      );

      return process;
    } catch (e) {
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

    emit(
      state.copyWith(
        loading: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final process = await _repository.getSpecificContract(
        uidContract: cleanId,
      );

      if (process == null) {
        emit(
          state.copyWith(
            loading: false,
          ),
        );

        return null;
      }

      final updatedList = List<ContractData>.from(state.allProcesses)
        ..removeWhere((p) => p.id == process.id)
        ..add(process);

      final selected = state.selectedProcess?.id == process.id
          ? process
          : state.selectedProcess;

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

    emit(
      state.copyWith(
        loading: true,
        clearErrorMessage: true,
      ),
    );

    try {
      await _repository.delete(cleanId);

      final updatedList = List<ContractData>.from(state.allProcesses)
        ..removeWhere((p) => p.id == cleanId);

      final shouldClearSelected = state.selectedProcess?.id == cleanId;

      emit(
        state.copyWith(
          loading: false,
          allProcesses: updatedList,
          clearSelectedProcess: shouldClearSelected,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
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
      );

      _updateItemInState(
        cleanContractId,
            (process) => process.copyWithUpdatedPermission(
          userId: cleanUserId,
          permissionType: cleanType,
          value: value,
        ),
      );

      emit(
        state.copyWith(
          loading: false,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
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
      );

      _updateItemInState(
        cleanContractId,
            (process) => process.copyWithParticipantPerms(
          userId: cleanUserId,
          perms: normalized,
        ),
      );

      emit(
        state.copyWith(
          loading: false,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
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
      );

      _updateItemInState(
        cleanContractId,
            (process) => process.copyWithParticipantRole(
          userId: cleanUserId,
          role: cleanRole,
        ),
      );

      emit(
        state.copyWith(
          loading: false,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
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
      await _repository.saveContractPermissions(contractData);

      _updateItemInState(
        contractId,
            (_) => contractData,
      );

      emit(
        state.copyWith(
          loading: false,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
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
      );

      _updateItemInState(
        cleanContractId,
            (process) => process.copyWithAddedParticipant(
          userId: cleanUserId,
          perms: normalizedPerms,
          meta: meta,
        ),
      );

      emit(
        state.copyWith(
          loading: false,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
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
      );

      _updateItemInState(
        cleanContractId,
            (process) => process.copyWithRemovedParticipant(cleanUserId),
      );

      emit(
        state.copyWith(
          loading: false,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
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
      );

      _updateItemInState(
        cleanContractId,
            (process) => process.copyWithParticipantMeta(
          userId: cleanUserId,
          meta: meta,
        ),
      );

      emit(
        state.copyWith(
          loading: false,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
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

    final updatedList = state.allProcesses.map((item) {
      if ((item.id ?? '').trim() == cleanId) {
        return transform(item);
      }

      return item;
    }).toList(growable: false);

    ContractData? updatedSelected = state.selectedProcess;

    if ((updatedSelected?.id ?? '').trim() == cleanId) {
      updatedSelected = transform(updatedSelected!);
    }

    emit(
      state.copyWith(
        allProcesses: updatedList,
        selectedProcess: updatedSelected,
      ),
    );
  }
}