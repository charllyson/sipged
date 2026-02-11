import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_blocs/modules/contracts/additives/additives_repository.dart';

import 'package:siged/_blocs/modules/financial/payments/adjustment/payment_adjustment_bloc.dart';
import 'package:siged/_blocs/modules/financial/payments/adjustment/payments_adjustments_data.dart';
import 'package:siged/_blocs/modules/financial/payments/adjustment/payment_adjustment_controller.dart';

import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:siged/_services/excel/import_excel_page.dart';
import 'package:siged/_widgets/menu/footBar/foot_bar.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/windows/show_window_dialog.dart';

import 'payment_adjustment_chart_section.dart';
import 'payment_adjustment_form_section.dart';
import 'payment_adjustment_table_section.dart';

// 🔔 Notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

// 🧩 Attachment (para onRenamePersist)
import 'package:siged/_widgets/list/files/attachment.dart';

class PaymentAdjustmentPage extends StatelessWidget {
  const PaymentAdjustmentPage({super.key, this.contractData});
  final ProcessData? contractData;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PaymentsAdjustmentController>(
      create: (ctx) => PaymentsAdjustmentController(
        paymentAdjustmentBloc: ctx.read<PaymentAdjustmentBloc>(),
        additivesRepository: ctx.read<AdditivesRepository>(),
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
                        const SectionTitle(text: 'Gráfico dos pagamentos de reajuste'),
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

                        const SectionTitle(text: 'Cadastrar pagamento de reajuste no sistema'),
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
                                final ok = confirmDialog(context, 'Deseja salvar o pagamento?');
                                return ok == true;
                              },
                            );
                          },
                          onClear: c.createNew,

                          // ===== SideListBox =====
                          sideItems: c.sideItems,
                          selectedSideIndex: c.selectedSideIndex,
                          onAddSideItem: c.canAddFile ? () => c.handleAddFile(context) : null,
                          onTapSideItem: (i) => c.handleOpenFile(context, i),
                          onDeleteSideItem: (i) => c.handleDeleteFile(i, context),

                          // ✅ NOVO: rename interno do SideListBox
                          onRenamePersist: ({
                            required int index,
                            required Attachment oldItem,
                            required Attachment newItem,
                          }) async {
                            try {
                              // Mantém sua lógica centralizada no controller
                              final ok = await c.handleRenamePersist(
                                index: index,
                                oldItem: oldItem,
                                newItem: newItem,
                              );
                              return ok;
                            } catch (_) {
                              return false;
                            }
                          },

                          // ✅ opcional: se você quiser sincronizar lista no controller
                          onItemsChanged: (newItems) {
                            c.syncSideItemsFromWidget(newItems);
                          },

                          contractData: c.contract,

                          // ===== Ordem =====
                          orderNumberOptions: c.orderNumberOptions,
                          greyOrderItems: c.greyOrderItems,
                          onChangedOrderNumber: c.onChangeOrderNumber,
                        ),

                        const SectionTitle(
                          text: 'Pagamentos de reajustes cadastrados no sistema',
                        ),

                        if (c.isAdmin)
                          ImportExcelPage(
                            firstCollection: c.contract?.id ?? '',
                            onFinished: () async => c.init(context, contractData: c.contract),
                            onSave: (dados) async {
                              final data = PaymentsAdjustmentsData.fromMap(dados);
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
