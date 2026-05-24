import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/revision/revision_measurement_data.dart';
import 'package:sipged/_blocs/system/permission/permission_data.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';

import 'revision_paid_data.dart';
import 'revision_paid_repository.dart';
import 'revision_paid_state.dart';

class RevisionPaidCubit extends Cubit<RevisionPaidState> {
  RevisionPaidCubit({
    RevisionPaidRepository? repository,
    String? tenantId,
    UserPermissionData? initialPermissions,
    String? initialTenantId,
    this.moduleId = 'operation_measurements_revisions',
  })  : _repository = repository ??
      RevisionPaidRepository(
        tenantId: initialTenantId ?? tenantId,
      ),
        _tenantId = (initialTenantId ?? tenantId ?? '').trim(),
        _currentPermissions = initialPermissions,
        super(RevisionPaidState.initial()) {
    _syncRepositoryTenant();
  }

  final RevisionPaidRepository _repository;
  final String moduleId;

  UserPermissionData? _currentPermissions;
  String _tenantId;

  RevisionPaidRepository get repository => _repository;

  void _syncRepositoryTenant() {
    if (_tenantId.trim().isNotEmpty) {
      _repository.setActiveTenantId(_tenantId);
    }
  }

  void setTenantId(String? tenantId) {
    final next = tenantId?.trim() ?? '';

    if (_tenantId == next) return;

    _tenantId = next;
    _repository.setActiveTenantId(next);
  }

  void updatePermissions({
    UserPermissionData? permissions,
    required String tenantId,
  }) {
    _currentPermissions = permissions ?? _currentPermissions;
    setTenantId(tenantId);
  }

  bool canReadContract(ContractData contract) {
    return _canContractAction(
      contract: contract,
      action: 'read',
    );
  }

  bool canCreateContract(ContractData contract) {
    return _canContractAction(
      contract: contract,
      action: 'create',
    );
  }

  bool canEditContract(ContractData contract) {
    return _canContractAction(
      contract: contract,
      action: 'edit',
    );
  }

  bool canDeleteContract(ContractData contract) {
    return _canContractAction(
      contract: contract,
      action: 'delete',
    );
  }

  bool _canContractAction({
    required ContractData contract,
    required String action,
  }) {
    final permissions = _currentPermissions;
    final cleanAction = action.trim().toLowerCase();
    final cleanTenantId = _tenantId.trim();

    if (permissions == null || cleanAction.isEmpty || cleanTenantId.isEmpty) {
      return false;
    }

    return SystemPermission.canContract(
      permissions: permissions,
      contract: contract,
      action: cleanAction,
      module: moduleId,
      tenantId: cleanTenantId,
    );
  }

  void _assertCanContractAction({
    required ContractData contract,
    required String action,
    required String message,
  }) {
    if (_canContractAction(contract: contract, action: action)) {
      return;
    }

    throw Exception(
      '$message Ação: $action | Módulo: $moduleId | tenantId: $_tenantId',
    );
  }

  double totalPaymentValue(RevisionPaidData payment) {
    return _repository.totalPaymentValue(payment);
  }

  double mainPaymentValue(RevisionPaidData payment) {
    return _repository.mainPaymentValue(payment);
  }

  double retentionsValue(RevisionPaidData payment) {
    return _repository.retentionsValue(payment);
  }

  double sumPayments(
      List<RevisionPaidData> payments, {
        bool includeRetentions = false,
      }) {
    return _repository.sumPayments(
      payments,
      includeRetentions: includeRetentions,
    );
  }

  double sumRetentions(List<RevisionPaidData> payments) {
    return _repository.sumRetentions(payments);
  }

  RevisionPaidData? _findPaymentById(
      List<RevisionPaidData> payments,
      String paymentId,
      ) {
    final cleanId = paymentId.trim();

    if (cleanId.isEmpty) return null;

    for (final payment in payments) {
      if ((payment.id ?? '').trim() == cleanId) {
        return payment;
      }
    }

    return null;
  }

  int? _safeSideIndexAfterListChange({
    required List<Attachment> attachments,
    int? preferredIndex,
  }) {
    if (attachments.isEmpty) return null;

    final index = preferredIndex ?? attachments.length - 1;

    return index.clamp(0, attachments.length - 1).toInt();
  }

  Future<void> loadByRevision({
    required String contractId,
    required String revisionId,
    ContractData? contract,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanRevisionId = revisionId.trim();

    if (cleanContractId.isEmpty || cleanRevisionId.isEmpty) {
      emit(
        state.copyWith(
          status: RevisionPaidStatus.success,
          payments: const <RevisionPaidData>[],
          contractId: cleanContractId,
          revisionId: cleanRevisionId,
          clearSelected: true,
          clearError: true,
          uploading: false,
          clearUploadProgress: true,
          clearSelectedSideIndex: true,
        ),
      );
      return;
    }

    if (contract != null) {
      _assertCanContractAction(
        contract: contract,
        action: 'read',
        message: 'Usuário sem permissão para visualizar pagamentos de revisão.',
      );
    }

    final previousSelectedId = state.selected?.id?.trim() ?? '';

    emit(
      state.copyWith(
        status: RevisionPaidStatus.loading,
        contractId: cleanContractId,
        revisionId: cleanRevisionId,
        clearError: true,
      ),
    );

    try {
      final payments = await _repository.getPaymentsByRevision(
        contractId: cleanContractId,
        revisionId: cleanRevisionId,
      );

      final selected = _findPaymentById(payments, previousSelectedId);

      emit(
        state.copyWith(
          status: RevisionPaidStatus.success,
          payments: payments,
          selected: selected,
          clearSelected: selected == null,
          contractId: cleanContractId,
          revisionId: cleanRevisionId,
          clearError: true,
          uploading: false,
          clearUploadProgress: true,
          clearSelectedSideIndex: selected == null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: RevisionPaidStatus.failure,
          error: e.toString(),
          uploading: false,
          clearUploadProgress: true,
        ),
      );

      rethrow;
    }
  }

  Future<void> loadByContract({
    required String contractId,
    ContractData? contract,
  }) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      emit(
        state.copyWith(
          status: RevisionPaidStatus.success,
          payments: const <RevisionPaidData>[],
          contractId: cleanContractId,
          clearSelected: true,
          clearError: true,
          uploading: false,
          clearUploadProgress: true,
          clearSelectedSideIndex: true,
        ),
      );
      return;
    }

    if (contract != null) {
      _assertCanContractAction(
        contract: contract,
        action: 'read',
        message: 'Usuário sem permissão para visualizar pagamentos de revisão.',
      );
    }

    emit(
      state.copyWith(
        status: RevisionPaidStatus.loading,
        contractId: cleanContractId,
        clearError: true,
      ),
    );

    try {
      final payments = await _repository.getPaymentsByContract(
        contractId: cleanContractId,
      );

      emit(
        state.copyWith(
          status: RevisionPaidStatus.success,
          payments: payments,
          contractId: cleanContractId,
          clearSelected: true,
          clearError: true,
          uploading: false,
          clearUploadProgress: true,
          clearSelectedSideIndex: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: RevisionPaidStatus.failure,
          error: e.toString(),
          uploading: false,
          clearUploadProgress: true,
        ),
      );

      rethrow;
    }
  }

  List<RevisionPaidData> paymentsOfRevision({
    required String revisionId,
  }) {
    final cleanRevisionId = revisionId.trim();

    if (cleanRevisionId.isEmpty) {
      return const <RevisionPaidData>[];
    }

    return state.payments.where((item) {
      return item.revisionId?.trim() == cleanRevisionId;
    }).toList();
  }

  double totalPaidByRevision({
    required String revisionId,
    bool includeRetentions = false,
  }) {
    return sumPayments(
      paymentsOfRevision(revisionId: revisionId),
      includeRetentions: includeRetentions,
    );
  }

  double totalRetentionsByRevision({
    required String revisionId,
  }) {
    return sumRetentions(
      paymentsOfRevision(revisionId: revisionId),
    );
  }

  void selectPayment(RevisionPaidData? payment) {
    emit(
      state.copyWith(
        selected: payment,
        clearSelected: payment == null,
        clearSelectedSideIndex: true,
      ),
    );
  }

  void select(RevisionPaidData? payment) {
    selectPayment(payment);
  }

  void clearSelectedPayment() {
    emit(
      state.copyWith(
        clearSelected: true,
        clearSelectedSideIndex: true,
      ),
    );
  }

  void selectSideIndex(int? index) {
    if (index == null || index < 0) {
      emit(
        state.copyWith(
          clearSelectedSideIndex: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        selectedSideIndex: index,
      ),
    );
  }

  Future<void> saveOrUpdate({
    required ContractData contract,
    required RevisionPaidData data,
    required double revisionValue,
  }) async {
    final isEditing = data.id?.trim().isNotEmpty == true;

    _assertCanContractAction(
      contract: contract,
      action: isEditing ? 'edit' : 'create',
      message: isEditing
          ? 'Usuário sem permissão para editar pagamento de revisão.'
          : 'Usuário sem permissão para criar pagamento de revisão.',
    );

    final contractId = contract.id?.trim() ?? data.contractId?.trim() ?? '';
    final revisionId = data.revisionId?.trim() ?? state.revisionId?.trim() ?? '';

    if (contractId.isEmpty) {
      throw Exception('contractId é obrigatório para salvar pagamento.');
    }

    if (revisionId.isEmpty) {
      throw Exception('revisionId é obrigatório para salvar pagamento.');
    }

    final next = data.copyWith(
      contractId: contractId,
      revisionId: revisionId,
    );

    emit(
      state.copyWith(
        status: RevisionPaidStatus.loading,
        contractId: contractId,
        revisionId: revisionId,
        clearError: true,
      ),
    );

    try {
      await _repository.saveOrUpdatePayment(
        next,
        revisionValue: revisionValue,
      );

      await loadByRevision(
        contractId: contractId,
        revisionId: revisionId,
        contract: contract,
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: RevisionPaidStatus.failure,
          error: e.toString(),
          uploading: false,
          clearUploadProgress: true,
        ),
      );

      rethrow;
    }
  }

  Future<void> saveOrUpdatePayment({
    required ContractData contract,
    required RevisionMeasurementData revision,
    required RevisionPaidData payment,
  }) async {
    final contractId = contract.id?.trim() ?? payment.contractId?.trim() ?? '';
    final revisionId = revision.id?.trim() ?? payment.revisionId?.trim() ?? '';

    if (contractId.isEmpty) {
      throw Exception('contractId é obrigatório para salvar pagamento.');
    }

    if (revisionId.isEmpty) {
      throw Exception('revisionId é obrigatório para salvar pagamento.');
    }

    final next = payment.copyWith(
      contractId: contractId,
      revisionId: revisionId,
      revisionOrder: revision.order,
    );

    await saveOrUpdate(
      contract: contract,
      data: next,
      revisionValue: revision.value ?? 0.0,
    );
  }

  Future<void> deletePayment({
    required ContractData contract,
    required String contractId,
    required String revisionId,
    required String paymentId,
    double? revisionValue,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'delete',
      message: 'Usuário sem permissão para apagar pagamento de revisão.',
    );

    final cleanContractId = contractId.trim();
    final cleanRevisionId = revisionId.trim();
    final cleanPaymentId = paymentId.trim();

    if (cleanContractId.isEmpty ||
        cleanRevisionId.isEmpty ||
        cleanPaymentId.isEmpty) {
      throw Exception(
        'contractId, revisionId e paymentId são obrigatórios para apagar pagamento.',
      );
    }

    emit(
      state.copyWith(
        status: RevisionPaidStatus.loading,
        clearError: true,
      ),
    );

    try {
      await _repository.deletePayment(
        contractId: cleanContractId,
        revisionId: cleanRevisionId,
        paymentId: cleanPaymentId,
      );

      emit(
        state.copyWith(
          clearSelected: true,
          clearSelectedSideIndex: true,
        ),
      );

      await loadByRevision(
        contractId: cleanContractId,
        revisionId: cleanRevisionId,
        contract: contract,
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: RevisionPaidStatus.failure,
          error: e.toString(),
          uploading: false,
          clearUploadProgress: true,
        ),
      );

      rethrow;
    }
  }

  Future<void> deleteRevisionPayment({
    required ContractData contract,
    required RevisionMeasurementData revision,
    required RevisionPaidData payment,
  }) async {
    final contractId = contract.id?.trim() ?? payment.contractId?.trim() ?? '';
    final revisionId = revision.id?.trim() ?? payment.revisionId?.trim() ?? '';
    final paymentId = payment.id?.trim() ?? '';

    await deletePayment(
      contract: contract,
      contractId: contractId,
      revisionId: revisionId,
      paymentId: paymentId,
      revisionValue: revision.value,
    );
  }

  Future<Attachment> pickAndUploadAttachment({
    required ContractData contract,
    required String contractId,
    required String revisionId,
    required String paymentId,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'edit',
      message: 'Usuário sem permissão para anexar arquivo ao pagamento de revisão.',
    );

    final cleanContractId = contractId.trim();
    final cleanRevisionId = revisionId.trim();
    final cleanPaymentId = paymentId.trim();

    if (cleanContractId.isEmpty ||
        cleanRevisionId.isEmpty ||
        cleanPaymentId.isEmpty) {
      throw Exception(
        'Salve o pagamento antes de anexar arquivos.',
      );
    }

    emit(
      state.copyWith(
        uploading: true,
        uploadProgress: 0.0,
        clearError: true,
      ),
    );

    try {
      final attachment = await _repository.pickAndUploadAttachment(
        contractId: cleanContractId,
        revisionId: cleanRevisionId,
        paymentId: cleanPaymentId,
        onProgress: (progress) {
          emit(
            state.copyWith(
              uploading: true,
              uploadProgress: progress.clamp(0.0, 1.0).toDouble(),
            ),
          );
        },
      );

      await loadByRevision(
        contractId: cleanContractId,
        revisionId: cleanRevisionId,
        contract: contract,
      );

      final updated = _findPaymentById(
        state.payments,
        cleanPaymentId,
      );

      if (updated == null) {
        emit(
          state.copyWith(
            uploading: false,
            clearUploadProgress: true,
            clearSelectedSideIndex: true,
            clearError: true,
          ),
        );

        return attachment;
      }

      final attachments = updated.attachments ?? const <Attachment>[];
      final selectedSideIndex = _safeSideIndexAfterListChange(
        attachments: attachments,
        preferredIndex: attachments.length - 1,
      );

      emit(
        state.copyWith(
          selected: updated,
          selectedSideIndex: selectedSideIndex,
          clearSelectedSideIndex: selectedSideIndex == null,
          uploading: false,
          clearUploadProgress: true,
          clearError: true,
        ),
      );

      return attachment;
    } catch (e) {
      emit(
        state.copyWith(
          status: RevisionPaidStatus.failure,
          error: e.toString(),
          uploading: false,
          clearUploadProgress: true,
        ),
      );

      rethrow;
    }
  }

  Future<void> deleteAttachment({
    required ContractData contract,
    required String contractId,
    required String revisionId,
    required String paymentId,
    required Attachment attachment,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'edit',
      message: 'Usuário sem permissão para remover anexo do pagamento de revisão.',
    );

    final cleanContractId = contractId.trim();
    final cleanRevisionId = revisionId.trim();
    final cleanPaymentId = paymentId.trim();

    if (cleanContractId.isEmpty ||
        cleanRevisionId.isEmpty ||
        cleanPaymentId.isEmpty) {
      throw Exception(
        'contractId, revisionId e paymentId são obrigatórios para remover anexo.',
      );
    }

    emit(
      state.copyWith(
        uploading: true,
        clearError: true,
      ),
    );

    try {
      await _repository.deleteAttachment(
        contractId: cleanContractId,
        revisionId: cleanRevisionId,
        paymentId: cleanPaymentId,
        attachment: attachment,
      );

      await loadByRevision(
        contractId: cleanContractId,
        revisionId: cleanRevisionId,
        contract: contract,
      );

      final updated = _findPaymentById(
        state.payments,
        cleanPaymentId,
      );

      if (updated == null) {
        emit(
          state.copyWith(
            uploading: false,
            clearUploadProgress: true,
            clearSelectedSideIndex: true,
            clearError: true,
          ),
        );

        return;
      }

      final attachments = updated.attachments ?? const <Attachment>[];
      final selectedSideIndex = _safeSideIndexAfterListChange(
        attachments: attachments,
        preferredIndex: state.selectedSideIndex,
      );

      emit(
        state.copyWith(
          selected: updated,
          selectedSideIndex: selectedSideIndex,
          clearSelectedSideIndex: selectedSideIndex == null,
          uploading: false,
          clearUploadProgress: true,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: RevisionPaidStatus.failure,
          error: e.toString(),
          uploading: false,
          clearUploadProgress: true,
        ),
      );

      rethrow;
    }
  }

  Future<bool> renameAttachmentLabel({
    required ContractData contract,
    required String contractId,
    required String revisionId,
    required String paymentId,
    required Attachment oldItem,
    required Attachment newItem,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'edit',
      message: 'Usuário sem permissão para renomear anexo do pagamento de revisão.',
    );

    final cleanContractId = contractId.trim();
    final cleanRevisionId = revisionId.trim();
    final cleanPaymentId = paymentId.trim();

    if (cleanContractId.isEmpty ||
        cleanRevisionId.isEmpty ||
        cleanPaymentId.isEmpty) {
      return false;
    }

    try {
      await _repository.renameAttachmentLabel(
        contractId: cleanContractId,
        revisionId: cleanRevisionId,
        paymentId: cleanPaymentId,
        oldItem: oldItem,
        newItem: newItem,
      );

      await loadByRevision(
        contractId: cleanContractId,
        revisionId: cleanRevisionId,
        contract: contract,
      );

      final updated = _findPaymentById(
        state.payments,
        cleanPaymentId,
      );

      if (updated != null) {
        final attachments = updated.attachments ?? const <Attachment>[];
        final selectedSideIndex = _safeSideIndexAfterListChange(
          attachments: attachments,
          preferredIndex: state.selectedSideIndex,
        );

        emit(
          state.copyWith(
            selected: updated,
            selectedSideIndex: selectedSideIndex,
            clearSelectedSideIndex: selectedSideIndex == null,
            uploading: false,
            clearUploadProgress: true,
            clearError: true,
          ),
        );
      }

      return true;
    } catch (e) {
      emit(
        state.copyWith(
          status: RevisionPaidStatus.failure,
          error: e.toString(),
          uploading: false,
          clearUploadProgress: true,
        ),
      );

      return false;
    }
  }
}