import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_blocs/process/additives/additives_repository.dart';

import 'package:siged/_blocs/sectors/financial/payments/report/payment_report_controller.dart';
import 'package:siged/_blocs/sectors/financial/payments/report/payment_reports_bloc.dart';

import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_blocs/process/measurement/report/report_measurement_data.dart';
import 'package:siged/_blocs/sectors/financial/payments/report/payments_reports_data.dart';

import 'package:siged/_services/excel/import_excel_page.dart';
import 'package:siged/_widgets/menu/footBar/foot_bar.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/windows/show_window_dialog.dart';

import 'payment_report_chart_section.dart';
import 'payment_report_form_section.dart';
import 'payment_report_table_section.dart';

// 🔔 Notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class PaymentReportPage extends StatelessWidget {
  const PaymentReportPage({
    super.key,
    this.contractData,
    this.reportData = const [],
  });

  final ProcessData? contractData;
  final List<ReportMeasurementData> reportData;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PaymentsReportController>(
      create: (ctx) => PaymentsReportController(
        paymentReportBloc: ctx.read<PaymentReportBloc>(),
        additivesRepository: ctx.read<AdditivesRepository>(),
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
                        const SectionTitle(text: 'Gráfico dos pagamentos'),
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
                        const SectionTitle(
                          text: 'Cadastrar pagamento no sistema',
                        ),
                        Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 12.0),
                          child: PaymentReportFormSection(
                            isSaving: c.isSaving,
                            selectedPaymentReportData: c.selected,
                            currentPaymentReportId: c.currentPaymentReportId,
                            contractData: c.contract,

                            // controllers
                            orderPaymentReportController: c.orderCtrl,
                            processNumberPaymentReportController: c.processCtrl,
                            datePaymentReportController: c.dateCtrl,
                            valuePaymentReportController: c.valueCtrl,
                            statePaymentReportController: c.stateCtrl,
                            observationPaymentReportController:
                            c.observationCtrl,
                            bankPaymentReportController: c.bankCtrl,
                            electronicTicketPaymentReportController:
                            c.electronicTicketCtrl,
                            fontPaymentReportController: c.fontCtrl,
                            taxPaymentReportController: c.taxCtrl,

                            isEditable: c.isEditable,
                            formValidated: c.formValidated,
                            onSaveOrUpdate: () async {
                              await c.saveOrUpdate(
                                onConfirm: () async {
                                  final ok = await confirmDialog(
                                    context,
                                    'Deseja salvar este pagamento?',
                                  );
                                  return ok == true;
                                },
                              );
                            },
                            onClear: c.createNew,

                            // 🆕 Dropdown de ordem
                            orderNumberOptions: c.orderNumberOptions,
                            greyOrderItems: c.greyOrderItems,
                            onChangedOrderNumber: c.onChangeOrderNumber,

                            // 🆕 SideListBox (multi anexos + rótulo)
                            sideItems: c.sideItems,
                            selectedSideIndex: c.selectedSideIndex,
                            onAddSideItem: c.canAddFile
                                ? () => c.handleAddFile(context)
                                : null,
                            onTapSideItem: (i) =>
                                c.handleOpenFile(context, i),
                            onDeleteSideItem: (i) =>
                                c.handleDeleteFile(i, context),
                            onEditLabelSideItem: (i) =>
                                c.handleEditLabelFile(i, context),
                          ),
                        ),
                        const SectionTitle(
                          text: 'Pagamentos cadastrados no sistema',
                        ),
                        if (c.isAdmin)
                          ImportExcelPage(
                            firstCollection: c.contract?.id ?? '',
                            onFinished: () async {
                              await c.init(context,
                                  contractData: c.contract);
                            },
                            onSave: (dados) async {
                              final data = PaymentsReportData.fromMap(dados);
                              await c.saveExact(
                                data,
                                onError: () {
                                  NotificationCenter.instance.show(
                                    AppNotification(
                                      title: const Text(
                                        'Erro ao importar pagamento',
                                      ),
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
                  ModalBarrier(
                    dismissible: false,
                    color: Colors.black.withOpacity(0.4),
                  ),
                  const Center(child: CircularProgressIndicator()),
                ],
              ),
          ],
        );
      },
    );
  }
}
