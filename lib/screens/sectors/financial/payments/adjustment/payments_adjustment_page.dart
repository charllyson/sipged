import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sisged/_blocs/documents/contracts/additives/additives_bloc.dart';
import 'package:sisged/_blocs/sectors/financial/payments/adjustment/payment_adjustment_bloc.dart';
import 'payment_adjustment_controller.dart';

import 'package:sisged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:sisged/_blocs/sectors/financial/payments/adjustment/payments_adjustments_data.dart';
import 'package:sisged/_widgets/texts/divider_text.dart';
import 'package:sisged/admPanel/converters/importExcel/import_excel_page.dart';
import 'package:sisged/_widgets/footBar/foot_bar.dart';

import 'payment_adjustment_chart_section.dart';
import 'payment_adjustment_form_section.dart';
import 'payment_adjustment_table_section.dart';

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

                        const PaymentAdjustmentFormSection(),

                        const SizedBox(height: 12),
                        const DividerText(
                          title: 'Pagamentos de reajustes cadastrados no sistema',
                          isSend: true,
                        ),

                        ImportExcelPage(
                          firstCollection: c.contract?.id ?? '',
                          onFinished: () async => c.init(context, contractData: c.contract),
                          onSave: (dados) async {
                            final data = PaymentsAdjustmentsData.fromMap(dados);
                            await c.saveExact(
                              data,
                              onError: () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Erro ao importar pagamento de reajuste.'),
                                  backgroundColor: Colors.red,
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 12),
                        PaymentAdjustmentTableSection(
                          onTapItem: c.selectRow,
                          onDelete: (id) => c.deleteById(
                            id,
                            onSuccessSnack: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pagamento de reajustamento apagado com sucesso.'),
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ),
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
