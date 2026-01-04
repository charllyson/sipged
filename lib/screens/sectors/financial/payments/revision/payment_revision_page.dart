import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_blocs/process/additives/additives_repository.dart';

import 'package:siged/_blocs/sectors/financial/payments/revision/payment_revision_controller.dart';
import 'package:siged/_blocs/sectors/financial/payments/revision/payment_revision_bloc.dart';

import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_services/excel/import_excel_page.dart';
import 'package:siged/_widgets/menu/footBar/foot_bar.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/windows/show_window_dialog.dart';

import 'payment_revision_chart_section.dart';
import 'payment_revision_form_section.dart';
import 'payment_revision_table_section.dart';
import 'package:siged/_blocs/sectors/financial/payments/revision/payments_revisions_data.dart';

// 🔔 Notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class PaymentRevisionPage extends StatelessWidget {
  const PaymentRevisionPage({super.key, this.contractData});
  final ProcessData? contractData;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PaymentsRevisionController>(
      create: (ctx) => PaymentsRevisionController(
        paymentRevisionBloc: ctx.read<PaymentRevisionBloc>(),
        additivesRepository: ctx.read<AdditivesRepository>(),
      )..init(ctx, contractData: contractData),
      builder: (context, _) {
        final c = context.watch<PaymentsRevisionController>();

        if (c.contract?.id == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final labels = c.chartLabels;
        final values = c.chartValues;
        final totalMedicoes = c.totalMedicoes;
        final valorTotal = c.valorTotal;
        final saldo = c.saldo;

        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SectionTitle(text: 'Gráfico dos pagamentos da revisão'),
                        PaymentsRevisionChartsSection(
                          labels: labels,
                          values: values,
                          valorTotal: valorTotal,
                          totalMedicoes: totalMedicoes,
                          selectedIndex: c.selectedIndex,
                          onSelectIndex: (index) {
                            if (index < 0 || index >= c.revisions.length) return;
                            c.selectRow(c.revisions[index]);
                          },
                        ),
                        const SectionTitle(text: 'Cadastrar pagamento (revisão) no sistema'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: PaymentRevisionFormSection(
                            // controllers
                            orderCtrl: c.orderCtrl,
                            processCtrl: c.processCtrl,
                            valueCtrl: c.valueCtrl,
                            stateCtrl: c.stateCtrl,
                            observationCtrl: c.observationCtrl,
                            bankCtrl: c.bankCtrl,
                            electronicTicketCtrl: c.electronicTicketCtrl,
                            fontCtrl: c.fontCtrl,
                            dateCtrl: c.dateCtrl,
                            taxCtrl: c.taxCtrl,
                            // estado
                            selectedPaymentRevisionData: c.selected,
                            currentPaymentRevisionId: c.currentPaymentRevisionId,
                            isEditable: c.isEditable,
                            isSaving: c.isSaving,
                            formValidated: c.formValidated,
                            onSaveOrUpdate: () async {
                              await c.saveOrUpdate(
                                onConfirm: () async {
                                  final ok = confirmDialog(context, 'Deseja realmente salvar?');
                                  return ok == true;
                                },
                              );
                            },
                            onClear: c.createNew,

                            // 🔽 Dropdown de ordem
                            orderNumberOptions: c.orderNumberOptions,
                            greyOrderItems: c.greyOrderItems,
                            onChangedOrderNumber: c.onChangeOrderNumber,

                            // 🆕 SideListBox (multi anexos + rótulo)
                            sideItems: c.sideItems,
                            selectedSideIndex: c.selectedSideIndex,
                            onAddSideItem: c.canAddFile ? () => c.handleAddFile(context) : null,
                            onTapSideItem: (i) => c.handleOpenFile(context, i),
                            onDeleteSideItem: (i) => c.handleDeleteFile(i, context),
                            onEditLabelSideItem: (i) => c.handleEditLabelFile(i, context),
                          ),
                        ),
                        const SectionTitle(
                          text: 'Pagamentos de revisão cadastrados no sistema',
                        ),
                        if (c.isAdmin)
                          ImportExcelPage(
                            firstCollection: c.contract?.id ?? '',
                            onFinished: () async => c.init(context, contractData: c.contract),
                            onSave: (dados) async {
                              final data = PaymentsRevisionsData.fromMap(dados);
                              await c.saveExact(
                                data,
                                onError: () {
                                  NotificationCenter.instance.show(
                                    AppNotification(
                                      title: Text('Erro ao importar pagamento da revisão'),
                                      type: AppNotificationType.error,
                                    ),
                                  );
                                },
                              );
                            },
                          ),

                        const SizedBox(height: 12),
                        PaymentRevisionTableSection(
                          onTapItem: c.selectRow,
                          onDelete: (id) => c.deleteById(id),
                          paymentsRevisionsData: c.revisions,
                          selectedPaymentsRevisionsData: c.selected,
                          valorInicial: c.valorInicialBase,
                          valorAditivos: c.valorAditivosTotal,
                          valorTotal: valorTotal,
                          saldo: saldo,
                          contractData: c.contract,
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
