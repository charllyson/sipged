import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/process/hiring/3Tr/tr_controller.dart';

class SectionPrecosPagamentoReajuste extends StatelessWidget {
  const SectionPrecosPagamentoReajuste({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TrController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final w4 = inputW4(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('7) Preços, Pagamento, Reajuste e Garantia'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: c.trEstimativaValorCtrl,
                    labelText: 'Estimativa de valor (R\$)',
                    enabled: c.isEditable,
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: DropDownButtonChange(
                    enabled: c.isEditable,
                    labelText: 'Critério de reajuste',
                    controller: c.trReajusteIndiceCtrl,
                    items: const ['IPCA', 'INCC', 'IGP-M', 'Sem reajuste'],
                    onChanged: (v) => c.trReajusteIndiceCtrl.text = v ?? '',
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: c.trCondicoesPagamentoCtrl,
                    labelText: 'Condições de pagamento',
                    enabled: c.isEditable,
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: DropDownButtonChange(
                    enabled: c.isEditable,
                    labelText: 'Garantia contratual',
                    controller: c.trGarantiaCtrl,
                    items: const [
                      'Não exigida',
                      'Caução em dinheiro',
                      'Seguro-garantia',
                      'Fiança bancária',
                    ],
                    onChanged: (v) => c.trGarantiaCtrl.text = v ?? '',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
