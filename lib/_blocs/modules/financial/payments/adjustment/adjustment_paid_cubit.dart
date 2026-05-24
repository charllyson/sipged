// lib/_blocs/modules/financial/payments/adjustment/adjustment_paid_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_data.dart';
import 'package:sipged/_blocs/modules/financial/payments/adjustment/adjustment_paid_data.dart';
import 'package:sipged/_blocs/modules/financial/payments/adjustment/adjustment_paid_repository.dart';
import 'package:sipged/_blocs/modules/financial/payments/adjustment/adjustment_paid_state.dart';

import 'package:sipged/_blocs/system/permission/permission_data.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

class AdjustmentPaidCubit extends Cubit<AdjustmentPaidState> {
  AdjustmentPaidCubit({
    AdjustmentPaidRepository? repository,
    UserPermissionData? initialPermissions,
    String? tenantId,
    String? initialTenantId,
    this.moduleId = 'operation_measurements_adjustments',
  })  : _repository = repository ??
      AdjustmentPaidRepository(
        tenantId: _firstNonEmpty(
          initialTenantId,
          tenantId,
        ),
      ),
        _currentPermissions = initialPermissions,
        _tenantId = _cleanOptionalTenantId(
          _firstNonEmpty(
            initialTenantId,
            tenantId,
          ),
        ),
        super(AdjustmentPaidState.initial()) {
    _syncRepositoryTenant();
  }

  final AdjustmentPaidRepository _repository;
  final String moduleId;

  UserPermissionData? _currentPermissions;
  String? _tenantId;

  AdjustmentPaidRepository get repository => _repository;

  static String? _firstNonEmpty(String? a, String? b) {
    final cleanA = a?.trim();

    if (cleanA != null && cleanA.isNotEmpty) return cleanA;

    final cleanB = b?.trim();

    if (cleanB != null && cleanB.isNotEmpty) return cleanB;

    return null;
  }

  static String? _cleanOptionalTenantId(String? value) {
    final clean = value?.trim();

    if (clean == null || clean.isEmpty) return null;

    return clean;
  }

  static String _cleanRequiredTenantId(
      String? value, {
        required String context,
      }) {
    final clean = value?.trim() ?? '';

    if (clean.isEmpty) {
      throw ArgumentError(
        'tenantId é obrigatório em $context.',
      );
    }

    return clean;
  }

  String _cleanId(String? value) {
    return (value ?? '').trim();
  }

  void _syncRepositoryTenant() {
    _repository.setActiveTenantId(_tenantId);
  }

  void setTenantId(String? tenantId) {
    final previousTenantId = _tenantId;

    _tenantId = _cleanOptionalTenantId(tenantId);

    _syncRepositoryTenant();

    final currentContractId = state.contractId?.trim();

    if (previousTenantId != _tenantId &&
        currentContractId != null &&
        currentContractId.isNotEmpty) {
      final currentAdjustmentId = state.adjustmentId?.trim();

      if (currentAdjustmentId != null && currentAdjustmentId.isNotEmpty) {
        Future.microtask(
              () => loadByAdjustment(
            contractId: currentContractId,
            adjustmentId: currentAdjustmentId,
          ),
        );
      } else {
        Future.microtask(
              () => loadByContract(
            contractId: currentContractId,
          ),
        );
      }
    }
  }

  String _requireTenantId() {
    final clean = _cleanRequiredTenantId(
      _tenantId,
      context: 'AdjustmentPaidCubit._requireTenantId',
    );

    _tenantId = clean;
    _repository.setActiveTenantId(clean);

    return clean;
  }

  void updatePermissions({
    UserPermissionData? permissions,
    required String tenantId,
  }) {
    final previousTenantId = _tenantId;
    final previousPermissions = _currentPermissions;

    if (permissions != null) {
      _currentPermissions = permissions;
    }

    _tenantId = _cleanRequiredTenantId(
      tenantId,
      context: 'AdjustmentPaidCubit.updatePermissions',
    );

    _syncRepositoryTenant();

    final currentContractId = state.contractId?.trim();

    final tenantChanged = previousTenantId != _tenantId;
    final permissionsChanged =
        permissions != null && previousPermissions != _currentPermissions;

    if ((tenantChanged || permissionsChanged) &&
        currentContractId != null &&
        currentContractId.isNotEmpty) {
      final currentAdjustmentId = state.adjustmentId?.trim();

      if (currentAdjustmentId != null && currentAdjustmentId.isNotEmpty) {
        Future.microtask(
              () => loadByAdjustment(
            contractId: currentContractId,
            adjustmentId: currentAdjustmentId,
          ),
        );
      } else {
        Future.microtask(
              () => loadByContract(
            contractId: currentContractId,
          ),
        );
      }
    }
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

    if (permissions == null || cleanAction.isEmpty) {
      return false;
    }

    final tenantId = _requireTenantId();

    return SystemPermission.canContract(
      permissions: permissions,
      contract: contract,
      action: cleanAction,
      module: moduleId,
      tenantId: tenantId,
    );
  }

  void _assertCanContractAction({
    required ContractData contract,
    required String action,
    required String message,
  }) {
    final tenantId = _requireTenantId();

    if (_canContractAction(contract: contract, action: action)) {
      return;
    }

    throw Exception(
      '$message '
          'Ação: $action | Módulo: $moduleId | tenantId: $tenantId',
    );
  }

  double totalPaymentValue(AdjustmentPaidData payment) {
    return _repository.totalPaymentValue(payment);
  }

  double mainPaymentValue(AdjustmentPaidData payment) {
    return _repository.mainPaymentValue(payment);
  }

  double retentionsValue(AdjustmentPaidData payment) {
    return _repository.retentionsValue(payment);
  }

  double sumPayments(
      List<AdjustmentPaidData> payments, {
        bool includeRetentions = false,
      }) {
    return _repository.sumPayments(
      payments,
      includeRetentions: includeRetentions,
    );
  }

  double sumRetentions(List<AdjustmentPaidData> payments) {
    return _repository.sumRetentions(payments);
  }

  Future<void> loadByAdjustment({
    required String contractId,
    required String adjustmentId,
    ContractData? contract,
  }) async {
    _requireTenantId();

    final cleanContractId = contractId.trim();
    final cleanAdjustmentId = adjustmentId.trim();

    if (cleanContractId.isEmpty || cleanAdjustmentId.isEmpty) {
      emit(
        state.copyWith(
          status: AdjustmentPaidStatus.success,
          payments: const <AdjustmentPaidData>[],
          contractId: cleanContractId,
          adjustmentId: cleanAdjustmentId,
          selected: null,
          error: null,
          uploading: false,
          uploadProgress: null,
          selectedSideIndex: null,
        ),
      );
      return;
    }

    if (contract != null) {
      _assertCanContractAction(
        contract: contract,
        action: 'read',
        message: 'Usuário sem permissão para visualizar pagamentos de reajuste.',
      );
    }

    emit(
      state.copyWith(
        status: AdjustmentPaidStatus.loading,
        contractId: cleanContractId,
        adjustmentId: cleanAdjustmentId,
        error: null,
      ),
    );

    try {
      final payments = await _repository.getPaymentsByAdjustment(
        contractId: cleanContractId,
        adjustmentId: cleanAdjustmentId,
      );

      AdjustmentPaidData? selected;

      final previousSelectedId = state.selected?.id?.trim();

      if (previousSelectedId != null && previousSelectedId.isNotEmpty) {
        final index = payments.indexWhere(
              (item) => item.id?.trim() == previousSelectedId,
        );

        if (index >= 0) {
          selected = payments[index];
        }
      }

      emit(
        state.copyWith(
          status: AdjustmentPaidStatus.success,
          payments: payments,
          selected: selected,
          contractId: cleanContractId,
          adjustmentId: cleanAdjustmentId,
          error: null,
          uploading: false,
          uploadProgress: null,
          selectedSideIndex: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AdjustmentPaidStatus.failure,
          error: e.toString(),
          uploading: false,
          uploadProgress: null,
        ),
      );

      rethrow;
    }
  }

  Future<void> loadByContract({
    required String contractId,
    ContractData? contract,
  }) async {
    _requireTenantId();

    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      emit(
        state.copyWith(
          status: AdjustmentPaidStatus.success,
          payments: const <AdjustmentPaidData>[],
          contractId: cleanContractId,
          selected: null,
          error: null,
          uploading: false,
          uploadProgress: null,
          selectedSideIndex: null,
        ),
      );
      return;
    }

    if (contract != null) {
      _assertCanContractAction(
        contract: contract,
        action: 'read',
        message: 'Usuário sem permissão para visualizar pagamentos de reajuste.',
      );
    }

    emit(
      state.copyWith(
        status: AdjustmentPaidStatus.loading,
        contractId: cleanContractId,
        error: null,
      ),
    );

    try {
      final payments = await _repository.getPaymentsByContract(
        contractId: cleanContractId,
      );

      emit(
        state.copyWith(
          status: AdjustmentPaidStatus.success,
          payments: payments,
          contractId: cleanContractId,
          selected: null,
          error: null,
          uploading: false,
          uploadProgress: null,
          selectedSideIndex: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AdjustmentPaidStatus.failure,
          error: e.toString(),
          uploading: false,
          uploadProgress: null,
        ),
      );

      rethrow;
    }
  }

  List<AdjustmentPaidData> paymentsOfAdjustment({
    required String adjustmentId,
  }) {
    final cleanAdjustmentId = adjustmentId.trim();

    if (cleanAdjustmentId.isEmpty) {
      return const <AdjustmentPaidData>[];
    }

    return state.payments.where((item) {
      return item.adjustmentId?.trim() == cleanAdjustmentId;
    }).toList();
  }

  double totalPaidByAdjustment({
    required String adjustmentId,
    bool includeRetentions = false,
  }) {
    return sumPayments(
      paymentsOfAdjustment(adjustmentId: adjustmentId),
      includeRetentions: includeRetentions,
    );
  }

  double totalRetentionsByAdjustment({
    required String adjustmentId,
  }) {
    return sumRetentions(
      paymentsOfAdjustment(adjustmentId: adjustmentId),
    );
  }

  void selectPayment(AdjustmentPaidData? payment) {
    emit(
      state.copyWith(
        selected: payment,
        selectedSideIndex: null,
      ),
    );
  }

  void select(AdjustmentPaidData? payment) {
    selectPayment(payment);
  }

  void clearSelectedPayment() {
    emit(
      state.copyWith(
        selected: null,
        selectedSideIndex: null,
      ),
    );
  }

  void selectSideIndex(int? index) {
    if (index == null || index < 0) {
      emit(
        state.copyWith(
          selectedSideIndex: null,
        ),
      );
      return;
    }

    final selected = state.selected;
    final attachments = selected?.attachments ?? const <Attachment>[];

    if (index >= attachments.length) {
      emit(
        state.copyWith(
          selectedSideIndex: null,
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
    required AdjustmentMeasurementData adjustment,
    required AdjustmentPaidData data,
  }) {
    return saveOrUpdatePayment(
      contract: contract,
      adjustment: adjustment,
      payment: data,
    );
  }

  Future<void> saveOrUpdatePayment({
    required ContractData contract,
    required AdjustmentMeasurementData adjustment,
    required AdjustmentPaidData payment,
  }) async {
    final contractId = contract.id?.trim() ?? payment.contractId?.trim() ?? '';
    final adjustmentId =
        adjustment.id?.trim() ?? payment.adjustmentId?.trim() ?? '';

    if (contractId.isEmpty) {
      throw Exception('contractId é obrigatório para salvar pagamento.');
    }

    if (adjustmentId.isEmpty) {
      throw Exception('adjustmentId é obrigatório para salvar pagamento.');
    }

    final isNew = payment.id == null || payment.id!.trim().isEmpty;
    final action = isNew ? 'create' : 'edit';

    _assertCanContractAction(
      contract: contract,
      action: action,
      message: isNew
          ? 'Usuário sem permissão para criar pagamento de reajuste.'
          : 'Usuário sem permissão para editar pagamento de reajuste.',
    );

    final next = payment.copyWith(
      contractId: contractId,
      adjustmentId: adjustmentId,
      adjustmentOrder: adjustment.order,
    );

    emit(
      state.copyWith(
        status: AdjustmentPaidStatus.loading,
        contractId: contractId,
        adjustmentId: adjustmentId,
        error: null,
      ),
    );

    try {
      await _repository.saveOrUpdatePayment(
        next,
        adjustmentValue: adjustment.value ?? 0.0,
      );

      await loadByAdjustment(
        contractId: contractId,
        adjustmentId: adjustmentId,
        contract: contract,
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AdjustmentPaidStatus.failure,
          error: e.toString(),
          uploading: false,
          uploadProgress: null,
        ),
      );

      rethrow;
    }
  }

  Future<void> deletePayment({
    required ContractData contract,
    required AdjustmentMeasurementData adjustment,
    required AdjustmentPaidData payment,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'delete',
      message: 'Usuário sem permissão para apagar pagamento de reajuste.',
    );

    final contractId = contract.id?.trim() ?? payment.contractId?.trim() ?? '';
    final adjustmentId =
        adjustment.id?.trim() ?? payment.adjustmentId?.trim() ?? '';
    final paymentId = payment.id?.trim() ?? '';

    if (contractId.isEmpty || adjustmentId.isEmpty || paymentId.isEmpty) {
      throw Exception(
        'contractId, adjustmentId e paymentId são obrigatórios para apagar pagamento.',
      );
    }

    emit(
      state.copyWith(
        status: AdjustmentPaidStatus.loading,
        error: null,
      ),
    );

    try {
      await _repository.deletePayment(
        contractId: contractId,
        adjustmentId: adjustmentId,
        paymentId: paymentId,
      );

      await loadByAdjustment(
        contractId: contractId,
        adjustmentId: adjustmentId,
        contract: contract,
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AdjustmentPaidStatus.failure,
          error: e.toString(),
          uploading: false,
          uploadProgress: null,
        ),
      );

      rethrow;
    }
  }

  Future<Attachment> pickAndUploadAttachment({
    required ContractData contract,
    required AdjustmentMeasurementData adjustment,
    required AdjustmentPaidData payment,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'edit',
      message: 'Usuário sem permissão para anexar arquivo em pagamento de reajuste.',
    );

    final contractId = contract.id?.trim() ?? payment.contractId?.trim() ?? '';
    final adjustmentId =
        adjustment.id?.trim() ?? payment.adjustmentId?.trim() ?? '';
    final paymentId = payment.id?.trim() ?? '';

    if (contractId.isEmpty || adjustmentId.isEmpty || paymentId.isEmpty) {
      throw Exception(
        'Salve o pagamento antes de anexar arquivos.',
      );
    }

    emit(
      state.copyWith(
        uploading: true,
        uploadProgress: 0.0,
        error: null,
      ),
    );

    try {
      final attachment = await _repository.pickAndUploadAttachment(
        contractId: contractId,
        adjustmentId: adjustmentId,
        paymentId: paymentId,
        onProgress: (progress) {
          emit(
            state.copyWith(
              uploading: true,
              uploadProgress: progress.clamp(0.0, 1.0).toDouble(),
            ),
          );
        },
      );

      await loadByAdjustment(
        contractId: contractId,
        adjustmentId: adjustmentId,
        contract: contract,
      );

      final updated = state.payments.firstWhere(
            (item) => item.id?.trim() == paymentId,
        orElse: () => payment,
      );

      final attachments = updated.attachments ?? const <Attachment>[];

      emit(
        state.copyWith(
          selected: updated,
          selectedSideIndex: attachments.isEmpty ? null : attachments.length - 1,
          uploading: false,
          uploadProgress: null,
          error: null,
        ),
      );

      return attachment;
    } catch (e) {
      emit(
        state.copyWith(
          status: AdjustmentPaidStatus.failure,
          error: e.toString(),
          uploading: false,
          uploadProgress: null,
        ),
      );

      rethrow;
    }
  }

  Future<void> deleteAttachment({
    required ContractData contract,
    required AdjustmentMeasurementData adjustment,
    required AdjustmentPaidData payment,
    required Attachment attachment,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'edit',
      message: 'Usuário sem permissão para remover anexo de pagamento de reajuste.',
    );

    final contractId = contract.id?.trim() ?? payment.contractId?.trim() ?? '';
    final adjustmentId =
        adjustment.id?.trim() ?? payment.adjustmentId?.trim() ?? '';
    final paymentId = payment.id?.trim() ?? '';

    if (contractId.isEmpty || adjustmentId.isEmpty || paymentId.isEmpty) {
      throw Exception(
        'contractId, adjustmentId e paymentId são obrigatórios para remover anexo.',
      );
    }

    emit(
      state.copyWith(
        uploading: true,
        error: null,
      ),
    );

    try {
      await _repository.deleteAttachment(
        contractId: contractId,
        adjustmentId: adjustmentId,
        paymentId: paymentId,
        attachment: attachment,
      );

      await loadByAdjustment(
        contractId: contractId,
        adjustmentId: adjustmentId,
        contract: contract,
      );

      final updated = state.payments.firstWhere(
            (item) => item.id?.trim() == paymentId,
        orElse: () => payment,
      );

      final attachments = updated.attachments ?? const <Attachment>[];

      emit(
        state.copyWith(
          selected: updated,
          selectedSideIndex: attachments.isEmpty ? null : 0,
          uploading: false,
          uploadProgress: null,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AdjustmentPaidStatus.failure,
          error: e.toString(),
          uploading: false,
          uploadProgress: null,
        ),
      );

      rethrow;
    }
  }

  Future<bool> renameAttachmentLabel({
    required ContractData contract,
    required AdjustmentMeasurementData adjustment,
    required AdjustmentPaidData payment,
    required Attachment oldItem,
    required Attachment newItem,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'edit',
      message: 'Usuário sem permissão para renomear anexo de pagamento de reajuste.',
    );

    final contractId = contract.id?.trim() ?? payment.contractId?.trim() ?? '';
    final adjustmentId =
        adjustment.id?.trim() ?? payment.adjustmentId?.trim() ?? '';
    final paymentId = payment.id?.trim() ?? '';

    if (contractId.isEmpty || adjustmentId.isEmpty || paymentId.isEmpty) {
      return false;
    }

    try {
      await _repository.renameAttachmentLabel(
        contractId: contractId,
        adjustmentId: adjustmentId,
        paymentId: paymentId,
        oldItem: oldItem,
        newItem: newItem,
      );

      await loadByAdjustment(
        contractId: contractId,
        adjustmentId: adjustmentId,
        contract: contract,
      );

      final updated = state.payments.firstWhere(
            (item) => _cleanId(item.id) == paymentId,
        orElse: () => payment,
      );

      emit(
        state.copyWith(
          selected: updated,
          error: null,
        ),
      );

      return true;
    } catch (e) {
      emit(
        state.copyWith(
          status: AdjustmentPaidStatus.failure,
          error: e.toString(),
          uploading: false,
          uploadProgress: null,
        ),
      );

      return false;
    }
  }
}