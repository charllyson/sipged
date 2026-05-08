// lib/screens/modules/financial/payments/report_paid_form.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/report/report_executed_data.dart';
import 'package:sipged/_blocs/modules/financial/payments/report/report_paid_cubit.dart';

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

  String get _contractId => contractData.id?.trim() ?? '';

  @override
  Widget build(BuildContext context) {
    final measurement = selectedReportMeasurement;
    final measurementId = measurement?.id?.trim() ?? '';

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

    return BlocProvider(
      key: ValueKey('payment-cubit-$_contractId-$measurementId'),
      create: (context) {
        final permissionState = context.read<PermissionCubit>().state;

        return ReportPaidCubit(
          initialPermissions: permissionState.current,
          initialTenantId: permissionState.activeTenantId,
          moduleId: 'operation_measurements',
        )..loadByMeasurement(
          contractId: _contractId,
          measurementId: measurementId,
        );
      },
      child: BlocListener<PermissionCubit, PermissionState>(
        listenWhen: (previous, current) {
          return previous.current != current.current ||
              previous.activeTenantId != current.activeTenantId;
        },
        listener: (context, permissionState) {
          context.read<ReportPaidCubit>().updatePermissions(
            permissions: permissionState.current,
            tenantId: permissionState.activeTenantId,
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
  }
}
