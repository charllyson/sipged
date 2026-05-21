// lib/screens/modules/financial/payments/report/report_measurement_payment_form_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/report/report_executed_data.dart';
import 'package:sipged/_blocs/modules/financial/payments/report/report_paid_cubit.dart';
import 'package:sipged/_blocs/modules/financial/payments/report/report_paid_repository.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';

import 'package:sipged/screens/modules/financial/payments/report/report_paid_empty.dart';
import 'package:sipged/screens/modules/financial/payments/report/report_paid_form_view.dart';

class ReportMeasurementPaymentFormSection extends StatelessWidget {
  const ReportMeasurementPaymentFormSection({
    super.key,
    required this.contractData,
    required this.selectedReportMeasurement,
    required this.orderController,
    required this.isEditable,
    this.onPaymentsChanged,
  });

  final ContractData contractData;
  final ReportExecutedData? selectedReportMeasurement;
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
    final measurement = selectedReportMeasurement;
    final measurementId = _cleanText(measurement?.id);

    if (_contractId.isEmpty) {
      return const PaymentEmpty(
        icon: Icons.warning_amber_rounded,
        title: 'Contrato inválido',
        message: 'Salve o contrato antes de cadastrar pagamentos.',
      );
    }

    if (measurement == null || measurementId.isEmpty) {
      return const PaymentEmpty(
        icon: Icons.receipt_long_outlined,
        title: 'Selecione uma medição',
        message: 'Selecione ou salve uma medição antes de cadastrar pagamentos.',
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

        return BlocProvider<ReportPaidCubit>(
          key: ValueKey<String>(
            'payment-cubit-$tenantId-$_contractId-$measurementId',
          ),
          create: (context) {
            return ReportPaidCubit(
              repository: ReportPaidRepository(
                tenantId: tenantId,
              ),
              initialPermissions: permissionState.current,
              initialTenantId: tenantId,
              moduleId: 'operation_measurements',
            )..loadByMeasurement(
              contractId: _contractId,
              measurementId: measurementId,
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

              context.read<ReportPaidCubit>().updatePermissions(
                permissions: nextPermissionState.current,
                tenantId: nextTenantId,
              );
            },
            child: ReportMeasurementPaymentFormView(
              contractData: contractData,
              selectedReportMeasurement: measurement,
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