import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/screens/sectors/financial/payments/revision/payment_revision_controller.dart';

import 'package:siged/_blocs/documents/contracts/additives/additives_bloc.dart';
import 'package:siged/_blocs/sectors/financial/payments/revision/payment_revision_bloc.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_blocs/sectors/financial/payments/revision/payments_revisions_data.dart';
import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/admPanel/converters/importExcel/import_excel_page.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';

import 'payment_revision_chart_section.dart';
import 'payment_revision_form_section.dart';
import 'payment_revision_table_section.dart';

class PaymentsRevisionPage extends StatelessWidget {
  const PaymentsRevisionPage({super.key, this.contractData});

  final ContractData? contractData;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PaymentsRevisionController>(
      create: (ctx) =>
      PaymentsRevisionController(
        paymentRevisionBloc: ctx.read<PaymentRevisionBloc>(),
        additivesBloc: ctx.read<AdditivesBloc>(),
      )
        ..init(ctx, contractData: contractData),
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
                        const DividerText(
                            title: 'Gráfico dos pagamentos da revisão'),
                        const SizedBox(height: 12),
                        PaymentsRevisionChartsSection(
                          labels: labels,
                          values: values,
                          valorTotal: valorTotal,
                          totalMedicoes: totalMedicoes,
                          selectedIndex: c.selectedIndex,
                          onSelectIndex: (index) {
                            if (index < 0 ||
                                index >= c.revisions.length) return;
                            c.selectRow(c.revisions[index]);
                          },
                        ),
                        const SizedBox(height: 12),
                        const DividerText(
                            title: 'Cadastrar pagamento (revisão) no sistema'),
                        const SizedBox(height: 12),

                        // Form consome o controller via Provider
                        const PaymentRevisionFormSection(),

                        const SizedBox(height: 12),
                        const DividerText(
                          title: 'Pagamentos de revisão cadastrados no sistema',
                          isSend: true,
                        ),

                        // Import Excel usando saveExact
                        ImportExcelPage(
                          firstCollection: c.contract?.id ?? '',
                          onFinished: () async =>
                              c.init(context, contractData: c.contract),
                          onSave: (dados) async {
                            final data = PaymentsRevisionsData.fromMap(dados);
                            await c.saveExact(
                              data,
                              onError: () =>
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Erro ao importar pagamento da revisão.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  ),
                            );
                          },
                        ),

                        const SizedBox(height: 12),
                        PaymentRevisionTableSection(
                          onTapItem: c.selectRow,
                          onDelete: (id) =>
                              c.deleteById(
                                id,
                                onSuccessSnack: () =>
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Pagamento da revisão apagado com sucesso.'),
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
                  ModalBarrier(
                      dismissible: false, color: Colors.black.withOpacity(0.4)),
                  const Center(child: CircularProgressIndicator()),
                ],
              ),
          ],
        );
      },
    );
  }
}