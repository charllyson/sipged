import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/report/report_executed_data.dart';
import 'package:sipged/_blocs/system/permission/permission_data.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';

import 'report_paid_data.dart';
import 'report_paid_repository.dart';
import 'report_paid_state.dart';

class ReportPaidCubit extends Cubit<ReportPaidState> {
  ReportPaidCubit({
    ReportPaidRepository? repository,
    UserPermissionData? initialPermissions,
    required String initialTenantId,
    this.moduleId = 'operation_measurements',
  })  : _repo = repository ??
      ReportPaidRepository(
        tenantId: _cleanRequiredTenantId(
          initialTenantId,
          context: 'ReportPaidCubit.repository',
        ),
      ),
        _currentPermissions = initialPermissions,
        _tenantId = _cleanRequiredTenantId(
          initialTenantId,
          context: 'ReportPaidCubit.initialTenantId',
        ),
        super(ReportPaidState.initial()) {
    _syncRepositoryTenant();
  }

  final ReportPaidRepository _repo;
  final String moduleId;

  UserPermissionData? _currentPermissions;
  String _tenantId;

  static String _cleanRequiredTenantId(
      String value, {
        required String context,
      }) {
    final clean = value.trim();

    if (clean.isEmpty) {
      throw ArgumentError(
        'tenantId é obrigatório em $context.',
      );
    }

    return clean;
  }

  String _clean(String? value) {
    return value?.trim() ?? '';
  }

  bool _sameId(String? a, String? b) {
    final aa = _clean(a);
    final bb = _clean(b);

    return aa.isNotEmpty && bb.isNotEmpty && aa == bb;
  }

  void _syncRepositoryTenant() {
    _repo.setActiveTenantId(_tenantId);
  }

  void setTenantId(String tenantId) {
    final previousTenantId = _tenantId;

    _tenantId = _cleanRequiredTenantId(
      tenantId,
      context: 'ReportPaidCubit.setTenantId',
    );

    _syncRepositoryTenant();

    final currentContractId = state.contractId?.trim();
    final currentMeasurementId = state.measurementId?.trim();

    if (previousTenantId != _tenantId &&
        currentContractId != null &&
        currentContractId.isNotEmpty &&
        currentMeasurementId != null &&
        currentMeasurementId.isNotEmpty) {
      Future.microtask(
            () => loadByMeasurement(
          contractId: currentContractId,
          measurementId: currentMeasurementId,
        ),
      );
    }
  }

  String _requireTenantId() {
    final clean = _cleanRequiredTenantId(
      _tenantId,
      context: 'ReportPaidCubit._requireTenantId',
    );

    _tenantId = clean;
    _repo.setActiveTenantId(clean);

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
      context: 'ReportPaidCubit.updatePermissions',
    );

    _syncRepositoryTenant();

    final currentContractId = state.contractId?.trim();
    final currentMeasurementId = state.measurementId?.trim();

    final tenantChanged = previousTenantId != _tenantId;
    final permissionsChanged =
        permissions != null && previousPermissions != _currentPermissions;

    if ((tenantChanged || permissionsChanged) &&
        currentContractId != null &&
        currentContractId.isNotEmpty &&
        currentMeasurementId != null &&
        currentMeasurementId.isNotEmpty) {
      Future.microtask(
            () => loadByMeasurement(
          contractId: currentContractId,
          measurementId: currentMeasurementId,
        ),
      );
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

  bool canApproveContract(ContractData contract) {
    return _canContractAction(
      contract: contract,
      action: 'approve',
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

    _requireTenantId();

    return SystemPermission.canContract(
      permissions: permissions,
      contract: contract,
      action: cleanAction,
      module: moduleId,
      tenantId: _tenantId,
    );
  }

  void _assertCanContractAction({
    required ContractData contract,
    required String action,
    required String message,
  }) {
    _requireTenantId();

    if (_canContractAction(contract: contract, action: action)) {
      return;
    }

    throw Exception(
      '$message '
          'Ação: $action | Módulo: $moduleId | tenantId: $_tenantId',
    );
  }

  double paymentMainValue(ReportPaidData payment) {
    final value = payment.paymentValue ?? 0.0;

    if (!value.isFinite || value <= 0) return 0.0;

    return value;
  }

  double paymentRetentionsValue(ReportPaidData payment) {
    final values = <double>[
      payment.inssPaymentValue ?? 0.0,
      payment.irpfPaymentValue ?? 0.0,
      payment.issPaymentValue ?? 0.0,
    ];

    return values.fold<double>(
      0.0,
          (total, value) {
        if (!value.isFinite || value <= 0) return total;

        return total + value;
      },
    );
  }

  double paymentTotalWithRetentions(ReportPaidData payment) {
    return paymentMainValue(payment) + paymentRetentionsValue(payment);
  }

  double sumPayments(
      List<ReportPaidData> payments, {
        bool includeRetentions = false,
      }) {
    return payments.fold<double>(
      0.0,
          (total, payment) {
        final value = includeRetentions
            ? paymentTotalWithRetentions(payment)
            : paymentMainValue(payment);

        return total + value;
      },
    );
  }

  double sumRetentions(List<ReportPaidData> payments) {
    return payments.fold<double>(
      0.0,
          (total, payment) => total + paymentRetentionsValue(payment),
    );
  }

  Future<void> loadByMeasurement({
    required String contractId,
    required String measurementId,
    ContractData? contract,
    String? keepSelectedPaymentId,
    bool autoSelectFirstPayment = true,
  }) async {
    _requireTenantId();

    final cleanContractId = contractId.trim();
    final cleanMeasurementId = measurementId.trim();

    if (cleanContractId.isEmpty || cleanMeasurementId.isEmpty) {
      emit(
        state.copyWith(
          status: ReportPaidStatus.success,
          payments: const <ReportPaidData>[],
          clearSelected: true,
          clearSelectedSideIndex: true,
          contractId: cleanContractId,
          measurementId: cleanMeasurementId,
          clearError: true,
          uploading: false,
          clearUploadProgress: true,
        ),
      );
      return;
    }

    if (contract != null) {
      _assertCanContractAction(
        contract: contract,
        action: 'read',
        message: 'Usuário sem permissão para visualizar pagamentos.',
      );
    }

    final previousSelectedId = keepSelectedPaymentId?.trim().isNotEmpty == true
        ? keepSelectedPaymentId!.trim()
        : _clean(state.selected?.id);

    emit(
      state.copyWith(
        status: ReportPaidStatus.loading,
        contractId: cleanContractId,
        measurementId: cleanMeasurementId,
        clearError: true,
        uploading: false,
        clearUploadProgress: true,
      ),
    );

    try {
      final list = await _repo.getPaymentsByMeasurement(
        contractId: cleanContractId,
        measurementId: cleanMeasurementId,
      );

      ReportPaidData? selected;

      if (previousSelectedId.isNotEmpty) {
        for (final item in list) {
          if (_sameId(item.id, previousSelectedId)) {
            selected = item;
            break;
          }
        }
      }

      if (selected == null && autoSelectFirstPayment && list.isNotEmpty) {
        selected = list.first;
      }

      final selectedSideIndex = _resolveSelectedSideIndex(
        selected: selected,
        currentIndex: state.selectedSideIndex,
      );

      emit(
        state.copyWith(
          status: ReportPaidStatus.success,
          payments: list,
          selected: selected,
          clearSelected: selected == null,
          selectedSideIndex: selectedSideIndex,
          clearSelectedSideIndex: selectedSideIndex == null,
          contractId: cleanContractId,
          measurementId: cleanMeasurementId,
          clearError: true,
          uploading: false,
          clearUploadProgress: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ReportPaidStatus.failure,
          error: e.toString(),
          uploading: false,
          clearUploadProgress: true,
        ),
      );

      rethrow;
    }
  }

  int? _resolveSelectedSideIndex({
    required ReportPaidData? selected,
    required int? currentIndex,
  }) {
    if (selected == null) return null;

    final attachments = selected.attachments ?? const <Attachment>[];

    if (attachments.isEmpty) return null;

    final index = currentIndex ?? 0;

    if (index < 0) return 0;

    if (index >= attachments.length) {
      return attachments.length - 1;
    }

    return index;
  }

  Future<List<ReportPaidData>> getPaymentsByContract({
    required String contractId,
    ContractData? contract,
  }) {
    _requireTenantId();

    if (contract != null) {
      _assertCanContractAction(
        contract: contract,
        action: 'read',
        message: 'Usuário sem permissão para visualizar pagamentos.',
      );
    }

    return _repo.getPaymentsByContract(contractId: contractId);
  }

  List<double> buildPaymentValuesForMeasurements({
    required List<ReportExecutedData> measurements,
    required List<ReportPaidData> payments,
    bool includeRetentions = false,
  }) {
    final totalsByMeasurementId = <String, double>{};
    final totalsByMeasurementOrder = <int, double>{};

    for (final payment in payments) {
      final value = includeRetentions
          ? paymentTotalWithRetentions(payment)
          : paymentMainValue(payment);

      if (!value.isFinite || value <= 0) continue;

      final measurementId = _clean(payment.measurementId);

      if (measurementId.isNotEmpty) {
        totalsByMeasurementId[measurementId] =
            (totalsByMeasurementId[measurementId] ?? 0.0) + value;
      }

      final order = payment.measurementOrder;

      if (order != null) {
        totalsByMeasurementOrder[order] =
            (totalsByMeasurementOrder[order] ?? 0.0) + value;
      }
    }

    return measurements.map((measurement) {
      final measurementId = _clean(measurement.id);

      if (measurementId.isNotEmpty &&
          totalsByMeasurementId.containsKey(measurementId)) {
        return totalsByMeasurementId[measurementId] ?? 0.0;
      }

      final order = measurement.order;

      if (order != null && totalsByMeasurementOrder.containsKey(order)) {
        return totalsByMeasurementOrder[order] ?? 0.0;
      }

      return 0.0;
    }).toList();
  }

  void select(ReportPaidData? payment) {
    final selectedSideIndex = _resolveSelectedSideIndex(
      selected: payment,
      currentIndex: null,
    );

    emit(
      state.copyWith(
        selected: payment,
        clearSelected: payment == null,
        selectedSideIndex: selectedSideIndex,
        clearSelectedSideIndex: selectedSideIndex == null,
        clearError: true,
      ),
    );
  }

  void clearSelection() {
    emit(
      state.copyWith(
        clearSelected: true,
        clearSelectedSideIndex: true,
        clearError: true,
      ),
    );
  }

  void selectSideIndex(int? index) {
    final selected = state.selected;

    if (selected == null || index == null) {
      emit(
        state.copyWith(
          clearSelectedSideIndex: true,
        ),
      );
      return;
    }

    final attachments = selected.attachments ?? const <Attachment>[];

    if (attachments.isEmpty) {
      emit(
        state.copyWith(
          clearSelectedSideIndex: true,
        ),
      );
      return;
    }

    final safeIndex = index.clamp(0, attachments.length - 1);

    emit(
      state.copyWith(
        selectedSideIndex: safeIndex,
        clearError: true,
      ),
    );
  }

  Future<void> saveOrUpdate({
    required ContractData contract,
    required ReportPaidData data,
    required double measurementValue,
  }) async {
    final cleanContractId = _clean(data.contractId).isNotEmpty
        ? _clean(data.contractId)
        : _clean(state.contractId);

    final cleanMeasurementId = _clean(data.measurementId).isNotEmpty
        ? _clean(data.measurementId)
        : _clean(state.measurementId);

    if (cleanContractId.isEmpty) {
      throw Exception('contractId é obrigatório para salvar pagamento.');
    }

    if (cleanMeasurementId.isEmpty) {
      throw Exception('measurementId é obrigatório para salvar pagamento.');
    }

    final paymentId = data.id?.trim();
    final isNew = paymentId == null || paymentId.isEmpty;
    final action = isNew ? 'create' : 'edit';

    _assertCanContractAction(
      contract: contract,
      action: action,
      message: isNew
          ? 'Usuário sem permissão para criar pagamentos.'
          : 'Usuário sem permissão para editar pagamentos.',
    );

    data.contractId = cleanContractId;
    data.measurementId = cleanMeasurementId;

    await _repo.saveOrUpdatePayment(
      data,
      measurementValue: measurementValue,
    );

    await loadByMeasurement(
      contractId: cleanContractId,
      measurementId: cleanMeasurementId,
      contract: contract,
      keepSelectedPaymentId: data.id,
    );
  }

  Future<void> deletePayment({
    required ContractData contract,
    required String contractId,
    required String measurementId,
    required String paymentId,
    required double measurementValue,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'delete',
      message: 'Usuário sem permissão para apagar pagamentos.',
    );

    final cleanContractId = contractId.trim();
    final cleanMeasurementId = measurementId.trim();
    final cleanPaymentId = paymentId.trim();

    if (cleanContractId.isEmpty ||
        cleanMeasurementId.isEmpty ||
        cleanPaymentId.isEmpty) {
      return;
    }

    await _repo.deletePayment(
      contractId: cleanContractId,
      measurementId: cleanMeasurementId,
      paymentId: cleanPaymentId,
    );

    final wasSelected = _sameId(state.selected?.id, cleanPaymentId);

    if (state.contractId == cleanContractId &&
        state.measurementId == cleanMeasurementId) {
      await loadByMeasurement(
        contractId: cleanContractId,
        measurementId: cleanMeasurementId,
        contract: contract,
      );

      if (wasSelected) {
        clearSelection();
      }
    }
  }

  Future<Attachment> pickAndUploadAttachment({
    required ContractData contract,
    required String contractId,
    required String measurementId,
    required String paymentId,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'edit',
      message: 'Usuário sem permissão para anexar arquivos em pagamentos.',
    );

    final cleanContractId = contractId.trim();
    final cleanMeasurementId = measurementId.trim();
    final cleanPaymentId = paymentId.trim();

    if (cleanContractId.isEmpty ||
        cleanMeasurementId.isEmpty ||
        cleanPaymentId.isEmpty) {
      throw Exception('Dados inválidos para anexar arquivo ao pagamento.');
    }

    emit(
      state.copyWith(
        uploading: true,
        uploadProgress: 0.0,
        clearError: true,
      ),
    );

    try {
      final attachment = await _repo.pickAndUploadAttachment(
        contractId: cleanContractId,
        measurementId: cleanMeasurementId,
        paymentId: cleanPaymentId,
        onProgress: (progress) {
          final value = progress.isNaN ? 0.0 : progress.clamp(0.0, 1.0);

          emit(
            state.copyWith(
              uploading: true,
              uploadProgress: value.toDouble(),
              clearError: true,
            ),
          );
        },
      );

      await loadByMeasurement(
        contractId: cleanContractId,
        measurementId: cleanMeasurementId,
        contract: contract,
        keepSelectedPaymentId: cleanPaymentId,
      );

      emit(
        state.copyWith(
          uploading: false,
          clearUploadProgress: true,
          clearError: true,
        ),
      );

      return attachment;
    } catch (e) {
      emit(
        state.copyWith(
          uploading: false,
          clearUploadProgress: true,
          error: e.toString(),
        ),
      );

      rethrow;
    }
  }

  Future<void> deleteAttachment({
    required ContractData contract,
    required String contractId,
    required String measurementId,
    required String paymentId,
    required Attachment attachment,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'edit',
      message: 'Usuário sem permissão para remover anexos de pagamento.',
    );

    final cleanContractId = contractId.trim();
    final cleanMeasurementId = measurementId.trim();
    final cleanPaymentId = paymentId.trim();

    if (cleanContractId.isEmpty ||
        cleanMeasurementId.isEmpty ||
        cleanPaymentId.isEmpty) {
      return;
    }

    await _repo.deleteAttachment(
      contractId: cleanContractId,
      measurementId: cleanMeasurementId,
      paymentId: cleanPaymentId,
      attachment: attachment,
    );

    await loadByMeasurement(
      contractId: cleanContractId,
      measurementId: cleanMeasurementId,
      contract: contract,
      keepSelectedPaymentId: cleanPaymentId,
    );
  }

  Future<void> renameAttachmentLabel({
    required ContractData contract,
    required String contractId,
    required String measurementId,
    required String paymentId,
    required Attachment oldItem,
    required Attachment newItem,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'edit',
      message: 'Usuário sem permissão para renomear anexos de pagamento.',
    );

    final cleanContractId = contractId.trim();
    final cleanMeasurementId = measurementId.trim();
    final cleanPaymentId = paymentId.trim();

    if (cleanContractId.isEmpty ||
        cleanMeasurementId.isEmpty ||
        cleanPaymentId.isEmpty) {
      return;
    }

    await _repo.renameAttachmentLabel(
      contractId: cleanContractId,
      measurementId: cleanMeasurementId,
      paymentId: cleanPaymentId,
      oldItem: oldItem,
      newItem: newItem,
    );

    await loadByMeasurement(
      contractId: cleanContractId,
      measurementId: cleanMeasurementId,
      contract: contract,
      keepSelectedPaymentId: cleanPaymentId,
    );
  }
}