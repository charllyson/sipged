import 'package:flutter_bloc/flutter_bloc.dart';

import 'process_data.dart';
import 'process_repository.dart';
import 'process_state.dart';

import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_blocs/system/permitions/module_permission.dart' as perms;
import 'package:sipged/_blocs/system/permitions/user_permission.dart' as roles;

class ProcessCubit extends Cubit<ProcessState> {
  final ProcessRepository _repository;

  ProcessCubit({
    required ProcessRepository repository,
  })  : _repository = repository,
        super(ProcessState.initial());

  List<ProcessData> get allProcesses => state.allProcesses;
  ProcessData? get selectedProcess => state.selectedProcess;
  bool get isLoading => state.loading;
  bool get isInitialized => state.initialized;

  Future<void> warmup(UserData currentUser) async {
    if (state.initialized) return;
    await refresh(currentUser: currentUser);
    emit(state.copyWith(initialized: true));
  }

  Future<void> refresh({UserData? currentUser}) async {
    if (state.loading) return;

    emit(state.copyWith(
      loading: true,
      clearErrorMessage: true,
    ));

    try {
      final loaded = await _repository.getAllContracts();
      final filtered = _applyAclFilter(loaded, currentUser);

      ProcessData? selected = state.selectedProcess;
      if (selected != null) {
        try {
          selected = filtered.firstWhere((e) => e.id == selected!.id);
        } catch (_) {
          selected = null;
        }
      }

      emit(state.copyWith(
        loading: false,
        allProcesses: filtered,
        selectedProcess: selected,
        clearErrorMessage: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        errorMessage: 'Erro ao carregar contratos: $e',
      ));
    }
  }

  List<ProcessData> _applyAclFilter(
      List<ProcessData> source,
      UserData? user,
      ) {
    if (user == null) return source;

    final baseRole = roles.roleForUser(user);

    if (baseRole == roles.UserProfile.administrador ||
        baseRole == roles.UserProfile.desenvolvedor) {
      return source;
    }

    return source.where((contract) {
      return perms.userCanOnContract(
        user: user,
        contract: contract,
        action: 'read',
      );
    }).toList();
  }

  void select(ProcessData process) {
    emit(state.copyWith(selectedProcess: process));
  }

  void clearSelection() {
    emit(state.copyWith(clearSelectedProcess: true));
  }

  Future<ProcessData?> getById(String id) async {
    if (id.trim().isEmpty) return null;

    final cached = _findInCache(id);
    if (cached != null) return cached;

    emit(state.copyWith(
      loading: true,
      clearErrorMessage: true,
    ));

    try {
      final process = await _repository.getContractById(id);

      if (process == null) {
        emit(state.copyWith(loading: false));
        return null;
      }

      final updatedList = List<ProcessData>.from(state.allProcesses)
        ..removeWhere((p) => p.id == process.id)
        ..add(process);

      emit(state.copyWith(
        loading: false,
        allProcesses: updatedList,
      ));

      return process;
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        errorMessage: 'Erro ao buscar contrato por id: $e',
      ));
      return null;
    }
  }

  Future<ProcessData?> getSpecificContract({
    required String uidContract,
  }) async {
    emit(state.copyWith(
      loading: true,
      clearErrorMessage: true,
    ));

    try {
      final process = await _repository.getSpecificContract(
        uidContract: uidContract,
      );

      if (process == null) {
        emit(state.copyWith(loading: false));
        return null;
      }

      final updatedList = List<ProcessData>.from(state.allProcesses)
        ..removeWhere((p) => p.id == process.id)
        ..add(process);

      final selected = state.selectedProcess?.id == process.id
          ? process
          : state.selectedProcess;

      emit(state.copyWith(
        loading: false,
        allProcesses: updatedList,
        selectedProcess: selected,
      ));

      return process;
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        errorMessage: 'Erro ao buscar contrato específico: $e',
      ));
      return null;
    }
  }

  Future<void> delete(String id) async {
    if (id.trim().isEmpty) return;

    emit(state.copyWith(
      loading: true,
      clearErrorMessage: true,
    ));

    try {
      await _repository.delete(id);

      final updatedList = List<ProcessData>.from(state.allProcesses)
        ..removeWhere((p) => p.id == id);

      final shouldClearSelected = state.selectedProcess?.id == id;

      emit(state.copyWith(
        loading: false,
        allProcesses: updatedList,
        clearSelectedProcess: shouldClearSelected,
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        errorMessage: 'Erro ao excluir contrato: $e',
      ));
    }
  }

  Future<void> updateContractPermissions({
    required String contractId,
    required String userId,
    required String permissionType,
    required bool value,
  }) async {
    emit(state.copyWith(
      loading: true,
      clearErrorMessage: true,
    ));

    try {
      await _repository.updateContractPermissions(
        contractId: contractId,
        userId: userId,
        permissionType: permissionType,
        value: value,
      );

      _updateItemInState(
        contractId,
            (process) => process.copyWithUpdatedPermission(
          userId: userId,
          permissionType: permissionType,
          value: value,
        ),
      );

      emit(state.copyWith(loading: false));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        errorMessage: 'Erro ao atualizar permissão do contrato: $e',
      ));
    }
  }

  Future<void> setParticipantPerms({
    required String contractId,
    required String userId,
    required Map<String, bool> permsMap,
  }) async {
    emit(state.copyWith(
      loading: true,
      clearErrorMessage: true,
    ));

    try {
      await _repository.setParticipantPerms(
        contractId: contractId,
        userId: userId,
        permsMap: permsMap,
      );

      _updateItemInState(
        contractId,
            (process) => process.copyWithParticipantPerms(
          userId: userId,
          perms: permsMap,
        ),
      );

      emit(state.copyWith(loading: false));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        errorMessage: 'Erro ao definir permissões do participante: $e',
      ));
    }
  }

  Future<void> setParticipantRole({
    required String contractId,
    required String userId,
    required String role,
  }) async {
    emit(state.copyWith(
      loading: true,
      clearErrorMessage: true,
    ));

    try {
      await _repository.setParticipantRole(
        contractId: contractId,
        userId: userId,
        role: role,
      );

      _updateItemInState(
        contractId,
            (process) => process.copyWithParticipantRole(
          userId: userId,
          role: role,
        ),
      );

      emit(state.copyWith(loading: false));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        errorMessage: 'Erro ao definir papel do participante: $e',
      ));
    }
  }

  Future<void> saveContractPermissions(ProcessData contractData) async {
    final contractId = contractData.id;
    if (contractId == null || contractId.isEmpty) return;

    emit(state.copyWith(
      loading: true,
      clearErrorMessage: true,
    ));

    try {
      await _repository.saveContractPermissions(contractData);

      _updateItemInState(contractId, (_) => contractData);

      emit(state.copyWith(loading: false));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        errorMessage: 'Erro ao salvar permissões do contrato: $e',
      ));
    }
  }

  Future<void> addParticipant({
    required String contractId,
    required String userId,
    Map<String, bool>? permMap,
    Map<String, dynamic> meta = const {},
  }) async {
    emit(state.copyWith(
      loading: true,
      clearErrorMessage: true,
    ));

    try {
      await _repository.addParticipant(
        contractId: contractId,
        userId: userId,
        permMap: permMap,
        meta: meta,
      );

      final normalizedPerms = permMap ?? perms.initialDocPerms();

      _updateItemInState(
        contractId,
            (process) => process.copyWithAddedParticipant(
          userId: userId,
          perms: normalizedPerms,
          meta: meta,
        ),
      );

      emit(state.copyWith(loading: false));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        errorMessage: 'Erro ao adicionar participante: $e',
      ));
    }
  }

  Future<void> removeParticipant({
    required String contractId,
    required String userId,
  }) async {
    emit(state.copyWith(
      loading: true,
      clearErrorMessage: true,
    ));

    try {
      await _repository.removeParticipant(
        contractId: contractId,
        userId: userId,
      );

      _updateItemInState(
        contractId,
            (process) => process.copyWithRemovedParticipant(userId),
      );

      emit(state.copyWith(loading: false));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        errorMessage: 'Erro ao remover participante: $e',
      ));
    }
  }

  Future<void> updateParticipantMeta({
    required String contractId,
    required String userId,
    required Map<String, dynamic> meta,
  }) async {
    emit(state.copyWith(
      loading: true,
      clearErrorMessage: true,
    ));

    try {
      await _repository.updateParticipantMeta(
        contractId: contractId,
        userId: userId,
        meta: meta,
      );

      _updateItemInState(
        contractId,
            (process) => process.copyWithParticipantMeta(
          userId: userId,
          meta: meta,
        ),
      );

      emit(state.copyWith(loading: false));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        errorMessage: 'Erro ao atualizar metadados do participante: $e',
      ));
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

  ProcessData? _findInCache(String id) {
    try {
      return state.allProcesses.firstWhere((p) => (p.id ?? '') == id);
    } catch (_) {
      return null;
    }
  }

  void _updateItemInState(
      String contractId,
      ProcessData Function(ProcessData current) transform,
      ) {
    final updatedList = state.allProcesses.map((item) {
      if (item.id == contractId) {
        return transform(item);
      }
      return item;
    }).toList();

    ProcessData? updatedSelected = state.selectedProcess;
    if (updatedSelected?.id == contractId) {
      updatedSelected = transform(updatedSelected!);
    }

    emit(state.copyWith(
      allProcesses: updatedList,
      selectedProcess: updatedSelected,
    ));
  }
}