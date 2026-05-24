// lib/screens/modules/financial/payments/adjustment/adjustment_payment_form_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_data.dart';

import 'package:sipged/_blocs/modules/financial/payments/adjustment/adjustment_paid_cubit.dart';
import 'package:sipged/_blocs/modules/financial/payments/adjustment/adjustment_paid_repository.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';

import 'package:sipged/screens/modules/financial/payments/adjustment/adjustment_payment_form_view.dart';
import 'package:sipged/screens/modules/financial/payments/report/report_paid_empty.dart';

class AdjustmentPaymentFormSection extends StatelessWidget {
  const AdjustmentPaymentFormSection({
    super.key,
    required this.contractData,
    required this.selectedAdjustmentMeasurement,
    required this.orderController,
    required this.isEditable,
    this.onPaymentsChanged,
  });

  final ContractData contractData;
  final AdjustmentMeasurementData? selectedAdjustmentMeasurement;
  final TextEditingController orderController;
  final bool isEditable;

  final Future<void> Function()? onPaymentsChanged;

  String get _contractId {
    return _cleanText(contractData.id);
  }

  String? _resolveTenantId(PermissionState permissionState) {
    final tenantId = _cleanText(permissionState.activeTenantId);

    if (tenantId.isEmpty) return null;

    return tenantId;
  }

  @override
  Widget build(BuildContext context) {
    final adjustment = selectedAdjustmentMeasurement;
    final adjustmentId = _cleanText(adjustment?.id);

    if (_contractId.isEmpty) {
      return const PaymentEmpty(
        icon: Icons.warning_amber_rounded,
        title: 'Contrato inválido',
        message: 'Salve o contrato antes de cadastrar pagamentos.',
      );
    }

    if (adjustment == null || adjustmentId.isEmpty) {
      return const PaymentEmpty(
        icon: Icons.price_change_outlined,
        title: 'Selecione um reajuste',
        message: 'Selecione ou salve um reajuste antes de cadastrar pagamentos.',
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

        return BlocProvider<AdjustmentPaidCubit>(
          key: ValueKey<String>(
            'adjustment-payment-cubit-$tenantId-$_contractId-$adjustmentId',
          ),
          create: (context) {
            return AdjustmentPaidCubit(
              repository: AdjustmentPaidRepository(
                tenantId: tenantId,
              ),
              initialTenantId: tenantId,
              initialPermissions: permissionState.current,
              moduleId: 'operation_measurements_adjustments',
            )..loadByAdjustment(
              contractId: _contractId,
              adjustmentId: adjustmentId,
              contract: contractData,
            );
          },
          child: BlocListener<PermissionCubit, PermissionState>(
            listenWhen: (previous, current) {
              return previous.activeTenantId != current.activeTenantId ||
                  previous.current != current.current;
            },
            listener: (context, nextPermissionState) {
              final nextTenantId = _resolveTenantId(nextPermissionState);

              if (nextTenantId == null) {
                context.read<AdjustmentPaidCubit>().setTenantId(null);
                return;
              }

              context.read<AdjustmentPaidCubit>().updatePermissions(
                permissions: nextPermissionState.current,
                tenantId: nextTenantId,
              );

              context.read<AdjustmentPaidCubit>().loadByAdjustment(
                contractId: _contractId,
                adjustmentId: adjustmentId,
                contract: contractData,
              );
            },
            child: AdjustmentPaymentFormView(
              contractData: contractData,
              selectedAdjustmentMeasurement: adjustment,
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

    if (text.toLowerCase() == 'null') return '';

    return text;
  }
}