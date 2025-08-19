import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'payment_adjustment_controller.dart';

import '../../../../../_datas/documents/contracts/contracts/contract_data.dart';
import '../../../../../_datas/sectors/financial/payments/adjustments/payments_adjustments_data.dart';
import '../../../../../../_widgets/texts/divider_text.dart';
import '../../../../../admPanel/converters/importExcel/import_excel_page.dart';
import 'package:sisged/screens/commons/footBar/foot_bar.dart';

import 'payment_adjustment_chart_section.dart';
import 'payment_adjustment_form_section.dart';
import 'payment_adjustment_table_section.dart';

class PaymentsAdjustmentPage extends StatelessWidget {
  const PaymentsAdjustmentPage({super.key, this.contractData});
  final ContractData? contractData;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
      PaymentsAdjustmentController()..init(context, contractData: contractData),
      builder: (context, _) {
        final c = context.watch<PaymentsAdjustmentController>();

        // loading simples enquanto não inicializa/conhece contrato
        if (c.contract?.id == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final labels = c.chartLabels;
        final values = c.chartValues;
        final totalMedicoes = c.totalMedicoes;
        final valorTotal = c.valorTotal;            // inicial + aditivos
        final saldo = c.saldo;
        final valorInicial = c.valorInicialBase;    // getter
        final valorAditivos = c.valorAditivosTotal; // getter

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
                            if (index == null || index < 0 || index >= c.payments.length) return;
                            c.selectRow(c.payments[index]);
                          },
                        ),

                        const SizedBox(height: 12),
                        const DividerText(title: 'Cadastrar pagamento de reajuste no sistema'),
                        const SizedBox(height: 12),

                        // Form pega tudo do controller
                        const PaymentAdjustmentFormSection(),

                        const SizedBox(height: 12),
                        const DividerText(
                          title: 'Pagamentos de reajustes cadastrados no sistema',
                          isSend: true,
                        ),

                        // Import Excel - salva exatamente o objeto importado
                        ImportExcelPage(
                          firstCollection: c.contract?.id ?? '',
                          onFinished: () async {
                            await c.init(context, contractData: c.contract);
                          },
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
                          onTapItem: (data) => c.selectRow(data),
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
