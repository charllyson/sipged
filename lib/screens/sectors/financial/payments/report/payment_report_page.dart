import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siged/_blocs/sectors/financial/payments/report/payment_report_controller.dart';
import 'package:siged/_blocs/process/additives/additives_bloc.dart';
import 'package:siged/_blocs/sectors/financial/payments/report/payment_reports_bloc.dart';

import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'package:siged/_blocs/process/report/report_measurement_data.dart';
import 'package:siged/_blocs/sectors/financial/payments/report/payments_reports_data.dart';
import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/_services/excel/import_excel_page.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';

import 'payment_report_chart_section.dart';
import 'payment_report_form_section.dart';
import 'payment_report_table_section.dart';

// 🔔 Notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class PaymentsReportPage extends StatelessWidget {
  const PaymentsReportPage({
    super.key,
    this.contractData,
    this.reportData = const [],
  });

  final ContractData? contractData;
  final List<ReportMeasurementData> reportData;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PaymentsReportController>(
      create: (ctx) => PaymentsReportController(
        paymentReportBloc: ctx.read<PaymentReportBloc>(),
        additivesBloc: ctx.read<AdditivesBloc>(),
      )..init(ctx, contractData: contractData),
      builder: (context, _) {
        final c = context.watch<PaymentsReportController>();

        if (c.contract?.id == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final labels = c.chartLabels;
        final values = c.chartValues;
        final total = c.totalMedicoes;
        final valorTotal = c.valorTotal;

        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        const DividerText(title: 'Gráfico dos pagamentos'),
                        const SizedBox(height: 12),
                        PaymentsReportChartsSection(
                          labels: labels,
                          values: values,
                          valorTotal: valorTotal,
                          totalMedicoes: total,
                          selectedIndex: c.selectedIndex,
                          onSelectIndex: (index) {
                            if (index < 0 || index >= c.reports.length) return;
                            c.selectRow(c.reports[index]);
                          },
                        ),
                        const SizedBox(height: 12),
                        const DividerText(title: 'Cadastrar pagamento no sistema'),
                        const SizedBox(height: 12),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: PaymentReportFormSection(
                            isSaving: c.isSaving,
                            selectedPaymentReportData: c.selected,
                            currentPaymentReportId: c.currentPaymentReportId,
                            contractData: c.contract,
                            orderPaymentReportController: c.orderCtrl,
                            processNumberPaymentReportController: c.processCtrl,
                            datePaymentReportController: c.dateCtrl,
                            valuePaymentReportController: c.valueCtrl,
                            statePaymentReportController: c.stateCtrl,
                            observationPaymentReportController: c.observationCtrl,
                            bankPaymentReportController: c.bankCtrl,
                            electronicTicketPaymentReportController: c.electronicTicketCtrl,
                            fontPaymentReportController: c.fontCtrl,
                            taxPaymentReportController: c.taxCtrl,
                            isEditable: c.isEditable,
                            formValidated: c.formValidated,
                            onSaveOrUpdate: () async {
                              await c.saveOrUpdate(
                                onConfirm: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirmação'),
                                      content: const Text('Deseja salvar este pagamento?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Confirmar'),
                                        ),
                                      ],
                                    ),
                                  );
                                  return ok == true;
                                },
                              );
                            },
                            onClear: c.createNew,

                            // 🆕 SideListBox hooks
                            sideItems: c.sideItems,
                            selectedSideIndex: c.selectedSideIndex,
                            onAddSideItem: c.canAddFile ? c.handleAddFile : null,
                            onTapSideItem: (i) => c.handleOpenFile(i),
                            onDeleteSideItem: c.handleDeleteFile,
                          ),
                        ),

                        const SizedBox(height: 12),
                        const DividerText(title: 'Pagamentos cadastrados no sistema', isSend: true),

                        if (c.isAdmin)
                          ImportExcelPage(
                            firstCollection: c.contract?.id ?? '',
                            onFinished: () async {
                              await c.init(context, contractData: c.contract);
                            },
                            onSave: (dados) async {
                              final data = PaymentsReportData.fromMap(dados);
                              await c.saveExact(
                                data,
                                onError: () {
                                  NotificationCenter.instance.show(
                                    AppNotification(
                                      title: Text('Erro ao importar pagamento'),
                                      type: AppNotificationType.error,
                                    ),
                                  );
                                },
                              );
                            },
                          ),

                        const SizedBox(height: 12),
                        PaymentReportTableSection(
                          reportData: c.reports,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                const FootBar(),
              ],
            ),

            if (c.isSaving)
              Stack(
                children: [
                  ModalBarrier(dismissible: false, color: Colors.black.withOpacity(0.4)),
                  const Center(child: CircularProgressIndicator()),
                ],
              ),
          ],
        );
      },
    );
  }
}
