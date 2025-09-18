import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siged/_blocs/sectors/financial/payments/revision/payment_revision_controller.dart';
import 'package:siged/_blocs/documents/contracts/additives/additives_bloc.dart';
import 'package:siged/_blocs/sectors/financial/payments/revision/payment_revision_bloc.dart';

import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/_services/excel/import_excel_page.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';

import 'payment_revision_chart_section.dart';
import 'payment_revision_form_section.dart';
import 'payment_revision_table_section.dart';
import 'package:siged/_blocs/sectors/financial/payments/revision/payments_revisions_data.dart';

class PaymentsRevisionPage extends StatelessWidget {
  const PaymentsRevisionPage({super.key, this.contractData});
  final ContractData? contractData;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PaymentsRevisionController>(
      create: (ctx) => PaymentsRevisionController(
        paymentRevisionBloc: ctx.read<PaymentRevisionBloc>(),
        additivesBloc: ctx.read<AdditivesBloc>(),
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
                        const SizedBox(height: 12),
                        const DividerText(title: 'Gráfico dos pagamentos da revisão'),
                        const SizedBox(height: 12),

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

                        const SizedBox(height: 12),
                        const DividerText(title: 'Cadastrar pagamento (revisão) no sistema'),
                        const SizedBox(height: 12),

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
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirmação'),
                                      content: const Text('Deseja salvar este pagamento da revisão?'),
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
                                onSuccessSnack: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Pagamento salvo com sucesso!'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                },
                                onErrorSnack: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Falha ao salvar pagamento.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                },
                              );
                            },
                            onClear: c.createNew,
                            // Side
                            sideItems: c.sideItems,
                            selectedSideIndex: c.selectedSideIndex,
                            onAddSideItem: () => c.addSideItem(context),
                            onTapSideItem: (i) => c.openSideItem(context, i),
                            onDeleteSideItem: (i) => c.deleteSideItem(context, i),
                          ),
                        ),

                        const SizedBox(height: 12),
                        const DividerText(
                          title: 'Pagamentos de revisão cadastrados no sistema',
                          isSend: true,
                        ),

                        if (c.isAdmin)
                          ImportExcelPage(
                          firstCollection: c.contract?.id ?? '',
                          onFinished: () async => c.init(context, contractData: c.contract),
                          onSave: (dados) async {
                            final data = PaymentsRevisionsData.fromMap(dados);
                            await c.saveExact(
                              data,
                              onError: () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Erro ao importar pagamento da revisão.'),
                                  backgroundColor: Colors.red,
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 12),
                        PaymentRevisionTableSection(
                          onTapItem: c.selectRow,
                          onDelete: (id) => c.deleteById(
                            id,
                            onSuccessSnack: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pagamento da revisão apagado com sucesso.'),
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ),
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
