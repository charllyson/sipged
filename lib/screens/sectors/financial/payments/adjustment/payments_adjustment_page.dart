import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siged/_blocs/sectors/financial/payments/report/payment_report_controller.dart';
import 'package:siged/_blocs/process/additives/additives_bloc.dart';
import 'package:siged/_blocs/sectors/financial/payments/adjustment/payment_adjustment_bloc.dart';
import 'package:siged/_blocs/sectors/financial/payments/adjustment/payments_adjustments_data.dart';
import '../../../../../_blocs/sectors/financial/payments/adjustment/payment_adjustment_controller.dart';

import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/_services/excel/import_excel_page.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';

import 'payment_adjustment_chart_section.dart';
import 'payment_adjustment_form_section.dart';
import 'payment_adjustment_table_section.dart';

// 🔔 Notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class PaymentsAdjustmentPage extends StatelessWidget {
  const PaymentsAdjustmentPage({super.key, this.contractData});
  final ContractData? contractData;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PaymentsAdjustmentController>(
      create: (ctx) => PaymentsAdjustmentController(
        paymentAdjustmentBloc: ctx.read<PaymentAdjustmentBloc>(),
        additivesBloc: ctx.read<AdditivesBloc>(),
      )..init(ctx, contractData: contractData),
      builder: (context, _) {
        final c = context.watch<PaymentsAdjustmentController>();

        if (c.contract?.id == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final labels = c.chartLabels;
        final values = c.chartValues;
        final totalMedicoes = c.totalMedicoes;
        final valorTotal = c.valorTotal;
        final saldo = c.saldo;
        final valorInicial = c.valorInicialBase;
        final valorAditivos = c.valorAditivosTotal;

        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        const DividerText(title: 'Gráfico dos pagamentos de reajuste'),
                        const SizedBox(height: 12),

                        PaymentsAdjustmentChartsSection(
                          labels: labels,
                          values: values,
                          valorTotal: valorTotal,
                          totalMedicoes: totalMedicoes,
                          selectedIndex: c.selectedIndex,
                          onSelectIndex: (index) {
                            if (index < 0 || index >= c.payments.length) return;
                            c.selectRow(c.payments[index]);
                          },
                        ),

                        const SizedBox(height: 12),
                        const DividerText(title: 'Cadastrar pagamento de reajuste no sistema'),
                        const SizedBox(height: 12),

                        PaymentAdjustmentFormSection(
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
                          selected: c.selected,
                          currentPaymentAdjustmentId: c.currentPaymentAdjustmentId,
                          isEditable: c.isEditable,
                          isSaving: c.isSaving,
                          formValidated: c.formValidated,
                          onSaveOrUpdate: () async {
                            await c.saveOrUpdate(
                              onConfirm: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirmação'),
                                    content: const Text('Deseja salvar este pagamento de reajuste?'),
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

                          // 🆕 SideListBox props
                          sideItems: c.sideItems,
                          selectedSideIndex: c.selectedSideIndex,
                          onAddSideItem: c.canAddFile ? c.handleAddFile : null,
                          onTapSideItem: (i) => c.handleOpenFile(i),
                          onDeleteSideItem: c.handleDeleteFile,

                          contractData: c.contract,
                        ),

                        const SizedBox(height: 12),
                        const DividerText(
                          title: 'Pagamentos de reajustes cadastrados no sistema',
                          isSend: true,
                        ),

                        if (c.isAdmin)
                          ImportExcelPage(
                            firstCollection: c.contract?.id ?? '',
                            onFinished: () async => c.init(context, contractData: c.contract),
                            onSave: (dados) async {
                              final data = c.selected == null
                                  ? PaymentsAdjustmentsData.fromMap(dados)
                                  : PaymentsAdjustmentsData.fromMap(dados);
                              await c.saveExact(
                                data,
                                onError: () {
                                  NotificationCenter.instance.show(
                                    AppNotification(
                                      title: Text('Erro ao importar'),
                                      type: AppNotificationType.error,
                                    ),
                                  );
                                },
                              );
                            },
                          ),

                        const SizedBox(height: 12),
                        PaymentAdjustmentTableSection(
                          onTapItem: c.selectRow,
                          onDelete: (id) => c.deleteById(id),
                          paymentAdjustmentData: c.payments,
                          valorInicial: valorInicial,
                          valorAditivos: valorAditivos,
                          valorTotal: valorTotal,
                          saldo: saldo,
                          contractData: c.contract,
                          selectedPaymentAdjustment: c.selected,
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
