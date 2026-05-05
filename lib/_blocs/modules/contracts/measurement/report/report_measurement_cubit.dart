import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/permission/permission_data.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';

import 'report_measurement_state.dart';
import 'report_measurement_data.dart';
import 'report_measurement_repository.dart';

class ReportMeasurementCubit extends Cubit<ReportMeasurementState> {
  ReportMeasurementCubit({
    ReportMeasurementRepository? repository,
    UserPermissionData? initialPermissions,
    String? initialTenantId,
    this.moduleId = 'operation_measurements',
  })  : _repo = repository ?? ReportMeasurementRepository(),
        _currentPermissions = initialPermissions,
        _tenantId = initialTenantId,
        super(ReportMeasurementState.initial());

  final ReportMeasurementRepository _repo;

  final String moduleId;

  UserPermissionData? _currentPermissions;
  String? _tenantId;

  void updatePermissions({
    UserPermissionData? permissions,
    String? tenantId,
  }) {
    _currentPermissions = permissions;
    _tenantId = tenantId;
  }

  bool get isEditable => _canWrite();

  bool _canWrite() {
    final permissions = _currentPermissions;

    if (permissions == null) {
      return false;
    }

    if (permissions.isSuperUserForTenant(_tenantId)) {
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

    if (permissions == null) {
      return false;
    }

    if (permissions.isSuperUserForTenant(_tenantId)) {
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
      'Usuário sem permissão para alterar medições. '
          'Módulo: $moduleId | tenantId: ${_tenantId ?? 'não definido'}',
    );
  }

  void _assertCanDelete() {
    if (_canDelete()) return;

    throw Exception(
      'Usuário sem permissão para apagar medições. '
          'Módulo: $moduleId | tenantId: ${_tenantId ?? 'não definido'}',
    );
  }

  Future<void> loadByContract(String contractId) async {
    emit(
      state.copyWith(
        status: ReportMeasurementStatus.loading,
        error: null,
        contractId: contractId,
      ),
    );

    try {
      final list = await _repo.getAllMeasurementsOfContract(
        uidContract: contractId,
      );

      emit(
        state.copyWith(
          status: ReportMeasurementStatus.success,
          measurements: list,
          error: null,
          contractId: contractId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ReportMeasurementStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<List<ReportMeasurementData>> getAllMeasurementsCollectionGroup() {
    return _repo.getAllMeasurementsCollectionGroup();
  }

  Future<void> saveOrUpdate(ReportMeasurementData data) async {
    _assertCanWrite();

    await _repo.saveOrUpdateReport(data);

    if (state.contractId != null && data.contractId == state.contractId) {
      await loadByContract(state.contractId!);
    }
  }

  Future<void> delete({
    required String contractId,
    required String measurementId,
  }) async {
    _assertCanDelete();

    await _repo.deleteMeasurement(
      contractId: contractId,
      measurementId: measurementId,
    );

    if (state.contractId == contractId) {
      await loadByContract(contractId);
    }
  }

  double sum(List<ReportMeasurementData> list) {
    return _repo.somarValorMedicoes(list);
  }

  Future<Attachment> pickAndUploadAttachment({
    required String contractId,
    required String measurementId,
  }) async {
    _assertCanWrite();

    emit(
      state.copyWith(
        uploading: true,
        uploadProgress: 0.0,
        error: null,
      ),
    );

    try {
      final att = await _repo.pickAndUploadAttachment(
        contractId: contractId,
        measurementId: measurementId,
        onProgress: (p) {
          emit(
            state.copyWith(
              uploading: true,
              uploadProgress: p,
            ),
          );
        },
      );

      if (state.contractId == contractId) {
        await loadByContract(contractId);
      }

      emit(
        state.copyWith(
          uploading: false,
          uploadProgress: null,
        ),
      );

      return att;
    } catch (e) {
      emit(
        state.copyWith(
          uploading: false,
          uploadProgress: null,
          error: e.toString(),
        ),
      );

      rethrow;
    }
  }

  Future<void> deleteAttachment({
    required String contractId,
    required String measurementId,
    required Attachment attachment,
  }) async {
    _assertCanWrite();

    await _repo.deleteAttachment(
      contractId: contractId,
      measurementId: measurementId,
      attachment: attachment,
    );

    if (state.contractId == contractId) {
      await loadByContract(contractId);
    }
  }

  Future<void> renameAttachmentLabel({
    required String contractId,
    required String measurementId,
    required Attachment oldItem,
    required Attachment newItem,
  }) async {
    _assertCanWrite();

    await _repo.renameAttachmentLabel(
      contractId: contractId,
      measurementId: measurementId,
      oldItem: oldItem,
      newItem: newItem,
    );

    if (state.contractId == contractId) {
      await loadByContract(contractId);
    }
  }
}