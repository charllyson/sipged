import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/revision/revision_measurement_data.dart';

import 'package:sipged/_blocs/modules/financial/payments/revision/revision_paid_cubit.dart';
import 'package:sipged/_blocs/modules/financial/payments/revision/revision_paid_repository.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';

import 'package:sipged/screens/modules/financial/payments/revision/revision_payment_form_view.dart';

import 'package:sipged/screens/modules/financial/payments/report/report_paid_empty.dart';

class RevisionPaymentFormSection extends StatelessWidget {
  const RevisionPaymentFormSection({
    super.key,
    required this.contractData,
    required this.selectedRevisionMeasurement,
    required this.orderController,
    required this.isEditable,
    this.onPaymentsChanged,
  });

  final ContractData contractData;
  final RevisionMeasurementData? selectedRevisionMeasurement;
  final TextEditingController orderController;
  final bool isEditable;

  final Future<void> Function()? onPaymentsChanged;

  String get _contractId {
    return _cleanText(contractData.id);
  }

  String? _resolveTenantId(PermissionState permissionState) {
    final tenantId = _cleanText(permissionState.activeTenantId);

    if (tenantId.isEmpty) {
      return null;
    }

    return tenantId;
  }

  @override
  Widget build(BuildContext context) {
    final revision = selectedRevisionMeasurement;
    final revisionId = _cleanText(revision?.id);

    if (_contractId.isEmpty) {
      return const PaymentEmpty(
        icon: Icons.warning_amber_rounded,
        title: 'Contrato inválido',
        message: 'Salve o contrato antes de cadastrar pagamentos.',
      );
    }

    if (revision == null || revisionId.isEmpty) {
      return const PaymentEmpty(
        icon: Icons.price_change_outlined,
        title: 'Selecione uma revisão',
        message: 'Selecione ou salve uma revisão antes de cadastrar pagamentos.',
      );
    }

    return BlocBuilder<PermissionCubit, PermissionState>(
      buildWhen: (previous, current) {
        return previous.activeTenantId != current.activeTenantId ||
            previous.current != current.current;
      },
      builder: (context, permissionState) {
        final tenantId = _resolveTenantId(permissionState);

        if (tenantId == null) {
          return const PaymentEmpty(
            icon: Icons.business_outlined,
            title: 'Empresa ativa não selecionada',
            message: 'Selecione uma empresa ativa para carregar pagamentos.',
          );
        }

        if (permissionState.current == null) {
          return const PaymentEmpty(
            icon: Icons.lock_outline,
            title: 'Permissões não carregadas',
            message: 'Aguarde o carregamento das permissões do usuário.',
          );
        }

        return BlocProvider<RevisionPaidCubit>(
          key: ValueKey<String>(
            'revision-payment-cubit-$tenantId-$_contractId-$revisionId',
          ),
          create: (context) {
            return RevisionPaidCubit(
              repository: RevisionPaidRepository(
                tenantId: tenantId,
              ),
              initialPermissions: permissionState.current,
              initialTenantId: tenantId,
              moduleId: 'operation_measurements_revisions',
            )..loadByRevision(
              contractId: _contractId,
              revisionId: revisionId,
              contract: contractData,
            );
          },
          child: BlocListener<PermissionCubit, PermissionState>(
            listenWhen: (previous, current) {
              return previous.current != current.current ||
                  previous.activeTenantId != current.activeTenantId;
            },
            listener: (context, nextPermissionState) {
              final nextTenantId = _resolveTenantId(nextPermissionState);

              if (nextTenantId == null) return;

              context.read<RevisionPaidCubit>().updatePermissions(
                permissions: nextPermissionState.current,
                tenantId: nextTenantId,
              );
            },
            child: RevisionPaymentFormView(
              contractData: contractData,
              selectedRevisionMeasurement: revision,
              orderController: orderController,
              isEditable: isEditable,
              onPaymentsChanged: onPaymentsChanged,
            ),
          ),
        );
      },
    );
  }

  static String _cleanText(Object? value) {
    final text = value?.toString().trim() ?? '';

    if (text.toLowerCase() == 'null') {
      return '';
    }

    return text;
  }
}