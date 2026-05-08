import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/additives/additives_data.dart';
import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';

import 'package:sipged/_blocs/modules/contracts/validity/validity_data.dart';
import 'package:sipged/_blocs/modules/contracts/validity/validity_repository.dart';
import 'package:sipged/_blocs/modules/contracts/validity/validity_state.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_repository.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/3Tr/tr_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/3Tr/tr_repository.dart';

import 'package:sipged/_blocs/system/permission/permission_data.dart';

import 'package:sipged/_utils/formatters/sipged_format_dates.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';

class ValidityCubit extends Cubit<ValidityState> {
  ValidityCubit({
    required ValidityRepository repository,
    UserPermissionData? initialPermissions,
    String? initialTenantId,
    this.moduleId = 'contracts_validity',
    PublicacaoExtratoRepository? publicacaoRepository,
    TrRepository? trRepository,
  })  : _repository = repository,
        _publicacaoRepository =
            publicacaoRepository ?? PublicacaoExtratoRepository(),
        _trRepository = trRepository ?? TrRepository(),
        _currentPermissions = initialPermissions,
        _tenantId = initialTenantId,
        super(ValidityState.initial());

  final ValidityRepository _repository;
  final PublicacaoExtratoRepository _publicacaoRepository;
  final TrRepository _trRepository;

  final String moduleId;

  UserPermissionData? _currentPermissions;
  String? _tenantId;

  PublicacaoExtratoData? _publicacaoExtrato;
  TrData? _trData;

  PublicacaoExtratoData? get publicacaoExtrato => _publicacaoExtrato;
  TrData? get trData => _trData;

  void updatePermissions({
    UserPermissionData? permissions,
    String? tenantId,
  }) {
    _currentPermissions = permissions ?? _currentPermissions;
    _tenantId = tenantId ?? _tenantId;
  }

  bool get isEditable => _canWrite();

  bool _canWrite() {
    final permissions = _currentPermissions;

    if (permissions == null) return false;

    if (permissions.isGlobalSuperUser ||
        permissions.isSuperUserForTenant(_tenantId)) {
      return true;
    }

    return permissions.canModuleString(
      module: moduleId,
      action: 'create',
      tenantId: _tenantId,
    ) ||
        permissions.canModuleString(
          module: moduleId,
          action: 'edit',
          tenantId: _tenantId,
        ) ||
        permissions.canModuleString(
          module: moduleId,
          action: 'delete',
          tenantId: _tenantId,
        );
  }

  bool _canDelete() {
    final permissions = _currentPermissions;

    if (permissions == null) return false;

    if (permissions.isGlobalSuperUser ||
        permissions.isSuperUserForTenant(_tenantId)) {
      return true;
    }

    return permissions.canModuleString(
      module: moduleId,
      action: 'delete',
      tenantId: _tenantId,
    );
  }

  void _assertCanWrite() {
    if (_canWrite()) return;

    throw Exception(
      'Usuário sem permissão para alterar vigências. '
          'Módulo: $moduleId | tenantId: ${_tenantId ?? 'não definido'}',
    );
  }

  void _assertCanDelete() {
    if (_canDelete()) return;

    throw Exception(
      'Usuário sem permissão para apagar vigências. '
          'Módulo: $moduleId | tenantId: ${_tenantId ?? 'não definido'}',
    );
  }

  Set<int> _existingOrders(List<ValidityData> list) {
    return list
        .map((v) => v.orderNumber ?? 0)
        .where((n) => n > 0)
        .toSet();
  }

  int _nextAvailableOrder(Set<int> set) {
    if (set.isEmpty) return 1;

    for (int i = 1; i <= set.length + 1; i++) {
      if (!set.contains(i)) return i;
    }

    final max = set.reduce((a, b) => a > b ? a : b);

    return max + 1;
  }

  List<String> _orderNumberOptionsFromSet(Set<int> set) {
    final maxPlusOne =
    set.isEmpty ? 1 : set.reduce((a, b) => a > b ? a : b) + 1;

    return List<String>.generate(maxPlusOne, (i) => '${i + 1}');
  }

  List<String> _rulesOrderTypes(List<ValidityData> validities) {
    final sorted = _sorted(validities);

    final newOrders = <String>[];

    final lastOrder = sorted.isEmpty ? null : sorted.last.ordertype;

    if (lastOrder == null) {
      newOrders.addAll(ValidityData.typeOfOrder);
    } else if (lastOrder == 'ORDEM DE INÍCIO') {
      newOrders.addAll(<String>[
        'ORDEM DE PARALISAÇÃO',
        'ORDEM DE FINALIZAÇÃO',
      ]);
    } else if (lastOrder == 'ORDEM DE PARALISAÇÃO') {
      newOrders.add('ORDEM DE REINÍCIO');
    } else if (lastOrder == 'ORDEM DE REINÍCIO') {
      newOrders.addAll(<String>[
        'ORDEM DE PARALISAÇÃO',
        'ORDEM DE FINALIZAÇÃO',
      ]);
    } else if (lastOrder != 'ORDEM DE FINALIZAÇÃO') {
      newOrders.addAll(ValidityData.typeOfOrder);
    }

    return newOrders;
  }

  List<ValidityData> _sorted(List<ValidityData> list) {
    final sorted = List<ValidityData>.from(list);

    sorted.sort(
          (a, b) => (a.orderNumber ?? 0).compareTo(b.orderNumber ?? 0),
    );

    return List<ValidityData>.unmodifiable(sorted);
  }

  ValidityState _stateWithListMetadata({
    required List<ValidityData> validities,
    ValidityData? selected,
    List<Attachment>? attachments,
    bool clearSelected = false,
  }) {
    final sorted = _sorted(validities);
    final existingSet = _existingOrders(sorted);
    final nextOrder = _nextAvailableOrder(existingSet);

    return state.copyWith(
      validities: sorted,
      selectedValidity: selected,
      clearSelectedValidity: clearSelected,
      attachments: attachments,
      nextOrderNumber: nextOrder,
      orderNumberOptions: _orderNumberOptionsFromSet(existingSet),
      greyOrderItems: existingSet.map((e) => e.toString()).toSet(),
      availableOrderTypes: _rulesOrderTypes(sorted),
      clearError: true,
    );
  }

  List<ValidityData> _replaceValidityInList(ValidityData updated) {
    final list = List<ValidityData>.from(state.validities);

    final index = list.indexWhere((item) => item.id == updated.id);

    if (index >= 0) {
      list[index] = updated;
    } else {
      list.add(updated);
    }

    return _sorted(list);
  }

  Future<void> loadForContract(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return;

    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
      ),
    );

    try {
      final contract = await _repository.getSpecificContract(
        uid: cleanContractId,
      );

      final effectiveContract = contract ??
          ContractData(
            id: cleanContractId,
            permissionContractId: const <String, Map<String, bool>>{},
            participantsInfo: const <String, Map<String, dynamic>>{},
          );

      List<ValidityData> validities = const <ValidityData>[];
      List<AdditivesData> additives = const <AdditivesData>[];

      try {
        validities = await _repository.getAllValidityOfContract(
          uidContract: cleanContractId,
        );
      } catch (e) {
        emit(
          state.copyWith(
            isLoading: false,
            contract: effectiveContract,
            errorMessage: 'Erro ao carregar ordens/vigências: $e',
          ),
        );
        return;
      }

      try {
        additives = await _repository.buscarAditivos(cleanContractId);
      } catch (_) {
        additives = const <AdditivesData>[];
      }

      try {
        _publicacaoExtrato = await _publicacaoRepository.readDataForContract(
          cleanContractId,
        );
      } catch (_) {
        _publicacaoExtrato = null;
      }

      try {
        _trData = await _trRepository.readDataForContract(cleanContractId);
      } catch (_) {
        _trData = null;
      }

      final sortedValidities = _sorted(validities);
      final existingSet = _existingOrders(sortedValidities);
      final nextOrder = _nextAvailableOrder(existingSet);

      emit(
        state.copyWith(
          isLoading: false,
          contract: effectiveContract,
          validities: sortedValidities,
          additives: additives,
          nextOrderNumber: nextOrder,
          orderNumberOptions: _orderNumberOptionsFromSet(existingSet),
          greyOrderItems: existingSet.map((e) => e.toString()).toSet(),
          availableOrderTypes: _rulesOrderTypes(sortedValidities),
          clearSelectedValidity: true,
          clearAttachments: true,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Erro ao carregar validades: $e',
        ),
      );
    }
  }

  Future<void> selectOrderNumber(String? value) async {
    final picked = int.tryParse(value ?? '');

    if (picked == null || picked <= 0) return;

    final idx = state.validities.indexWhere(
          (x) => (x.orderNumber ?? -1) == picked,
    );

    if (idx >= 0) {
      await selectValidity(state.validities[idx]);
      return;
    }

    final draft = ValidityData(
      uidContract: state.contract?.id,
      orderNumber: picked,
    );

    emit(
      state.copyWith(
        selectedValidity: draft,
        attachments: const <Attachment>[],
        clearError: true,
      ),
    );
  }

  Future<void> selectValidity(ValidityData data) async {
    final contract = state.contract;

    if (contract == null) return;

    try {
      final attachments = await _repository.loadAndEnsureAttachments(
        contract: contract,
        validity: data,
      );

      final updated = data.copyWith(
        attachments: attachments,
        clearPdfUrl: (data.pdfUrl ?? '').trim().isNotEmpty,
      );

      final list = _replaceValidityInList(updated);

      emit(
        _stateWithListMetadata(
          validities: list,
          selected: updated,
          attachments: attachments,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          selectedValidity: data,
          attachments: const <Attachment>[],
          errorMessage: 'Erro ao carregar anexos: $e',
        ),
      );
    }
  }

  Future<void> createNewValidity() async {
    _assertCanWrite();

    final contract = state.contract;

    if (contract == null) return;

    final existingSet = _existingOrders(state.validities);
    final nextOrder = _nextAvailableOrder(existingSet);

    final draft = ValidityData(
      uidContract: contract.id,
      orderNumber: nextOrder,
    );

    emit(
      state.copyWith(
        selectedValidity: draft,
        nextOrderNumber: nextOrder,
        attachments: const <Attachment>[],
        clearError: true,
      ),
    );
  }

  void updateOrderType(String? type) {
    final current = state.selectedValidity;

    if (current == null) return;

    emit(
      state.copyWith(
        selectedValidity: current.copyWith(ordertype: type),
      ),
    );
  }

  void updateOrderDate(String? ddMMyyyy) {
    final current = state.selectedValidity;

    if (current == null) return;

    emit(
      state.copyWith(
        selectedValidity: current.copyWith(
          orderdate: ddMMyyyy != null && ddMMyyyy.trim().isNotEmpty
              ? SipGedFormatDates.ddMMyyyyToDate(ddMMyyyy)
              : null,
          clearOrderDate: ddMMyyyy == null || ddMMyyyy.trim().isEmpty,
        ),
      ),
    );
  }

  Future<void> saveSelected() async {
    _assertCanWrite();

    final contract = state.contract;
    final current = state.selectedValidity;

    if (contract == null || current == null) return;

    if (contract.id == null || contract.id!.trim().isEmpty) {
      throw Exception('Contrato sem ID para salvar vigência.');
    }

    emit(
      state.copyWith(
        isSaving: true,
        clearError: true,
      ),
    );

    try {
      final toSave = current.copyWith(
        uidContract: contract.id,
        attachments: state.attachments,
      );

      final saved = await _repository.salvarOuAtualizarValidade(toSave);

      await _repository.notificarUsuariosSobreValidade(saved, contract.id!);

      final list = _replaceValidityInList(saved);

      emit(
        _stateWithListMetadata(
          validities: list,
          selected: saved,
          attachments: saved.attachments ?? state.attachments,
        ).copyWith(isSaving: false),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Erro ao salvar validade: $e',
        ),
      );

      rethrow;
    }
  }

  Future<void> deleteValidity(String validityId) async {
    _assertCanDelete();

    final contract = state.contract;

    if (contract == null || contract.id == null) return;

    emit(
      state.copyWith(
        isSaving: true,
        clearError: true,
      ),
    );

    try {
      await _repository.deletarValidade(
        contract.id!,
        validityId,
      );

      final list = List<ValidityData>.from(state.validities)
        ..removeWhere((e) => e.id == validityId);

      emit(
        _stateWithListMetadata(
          validities: list,
          attachments: const <Attachment>[],
          clearSelected: true,
        ).copyWith(
          isSaving: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Erro ao apagar validade: $e',
        ),
      );

      rethrow;
    }
  }

  String _suggestLabelFromName(ValidityData validity, String original) {
    final base = original
        .split('/')
        .last
        .replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');

    final order = validity.orderNumber ?? 0;

    return 'Ordem $order - $base';
  }

  Future<Attachment?> addAttachmentFromBytes({
    required Uint8List bytes,
    required String originalName,
    required String? customLabel,
  }) async {
    _assertCanWrite();

    final contract = state.contract;
    final validity = state.selectedValidity;

    if (contract == null ||
        validity == null ||
        contract.id == null ||
        validity.id == null) {
      return null;
    }

    emit(
      state.copyWith(
        isSaving: true,
        clearError: true,
      ),
    );

    try {
      final suggestion = _suggestLabelFromName(validity, originalName);

      final label = customLabel == null || customLabel.trim().isEmpty
          ? suggestion
          : customLabel.trim();

      final attachment = await _repository.uploadAttachmentBytes(
        contract: contract,
        validity: validity,
        bytes: bytes,
        originalName: originalName,
        label: label,
      );

      final current = List<Attachment>.from(state.attachments)..add(attachment);

      await _repository.setAttachments(
        contractId: contract.id!,
        validityId: validity.id!,
        attachments: current,
      );

      final updatedValidity = validity.copyWith(
        attachments: current,
      );

      final list = _replaceValidityInList(updatedValidity);

      emit(
        _stateWithListMetadata(
          validities: list,
          selected: updatedValidity,
          attachments: current,
        ).copyWith(isSaving: false),
      );

      return attachment;
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Erro ao adicionar anexo: $e',
        ),
      );

      rethrow;
    }
  }

  Future<void> renameAttachment(int index, String newLabel) async {
    _assertCanWrite();

    final contract = state.contract;
    final validity = state.selectedValidity;

    if (contract == null || validity == null || validity.id == null) return;
    if (contract.id == null || contract.id!.trim().isEmpty) return;
    if (index < 0 || index >= state.attachments.length) return;

    emit(
      state.copyWith(
        isSaving: true,
        clearError: true,
      ),
    );

    try {
      final old = state.attachments[index];

      final updated = Attachment(
        id: old.id,
        label: newLabel.trim().isEmpty ? old.label : newLabel.trim(),
        url: old.url,
        path: old.path,
        ext: old.ext,
        size: old.size,
        createdAt: old.createdAt,
        createdBy: old.createdBy,
        updatedAt: DateTime.now(),
        updatedBy: _currentPermissions?.uid,
      );

      final listAttachments = List<Attachment>.from(state.attachments);
      listAttachments[index] = updated;

      await _repository.setAttachments(
        contractId: contract.id!,
        validityId: validity.id!,
        attachments: listAttachments,
      );

      final updatedValidity = validity.copyWith(
        attachments: listAttachments,
      );

      final list = _replaceValidityInList(updatedValidity);

      emit(
        _stateWithListMetadata(
          validities: list,
          selected: updatedValidity,
          attachments: listAttachments,
        ).copyWith(isSaving: false),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Erro ao renomear anexo: $e',
        ),
      );

      rethrow;
    }
  }

  Future<void> deleteAttachmentAt(int index) async {
    _assertCanWrite();

    final contract = state.contract;
    final validity = state.selectedValidity;

    if (contract == null || validity == null || validity.id == null) return;
    if (contract.id == null || contract.id!.trim().isEmpty) return;
    if (index < 0 || index >= state.attachments.length) return;

    emit(
      state.copyWith(
        isSaving: true,
        clearError: true,
      ),
    );

    try {
      final attachments = List<Attachment>.from(state.attachments);
      final removed = attachments.removeAt(index);

      if (removed.path.trim().isNotEmpty) {
        await _repository.deleteStorageByPath(removed.path);
      }

      await _repository.setAttachments(
        contractId: contract.id!,
        validityId: validity.id!,
        attachments: attachments,
      );

      final updatedValidity = validity.copyWith(
        attachments: attachments,
        clearAttachments: attachments.isEmpty,
      );

      final list = _replaceValidityInList(updatedValidity);

      emit(
        _stateWithListMetadata(
          validities: list,
          selected: updatedValidity,
          attachments: attachments,
        ).copyWith(isSaving: false),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Erro ao remover anexo: $e',
        ),
      );

      rethrow;
    }
  }

  DateTime? get dataFinalContrato {
    return _repository.calcularDataFinalContratoLocal(
      publicacao: _publicacaoExtrato,
      tr: _trData,
      additives: state.additives,
    );
  }

  DateTime? get dataFinalExecucao {
    return _repository.calcularDataFinalExecucaoLocal(
      tr: _trData,
      validities: state.validities,
      additives: state.additives,
    );
  }
}