import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/process/hiring/3Tr/tr_controller.dart';

class SectionPrecosPagamentoReajuste extends StatelessWidget {
  const SectionPrecosPagamentoReajuste({super.key});

  double _w(BuildContext ctx, {int itemsPerLine = 3}) =>
      responsiveInputWidth(context: ctx, itemsPerLine: itemsPerLine);

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TrController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('7) Preços, Pagamento, Reajuste e Garantia'),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.trEstimativaValorCtrl,
                labelText: 'Estimativa de valor (R\$)',
                enabled: c.isEditable,
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: DropDownButtonChange(
                enabled: c.isEditable,
                labelText: 'Critério de reajuste',
                controller: c.trReajusteIndiceCtrl,
                items: const ['IPCA', 'INCC', 'IGP-M', 'Sem reajuste'],
                onChanged: (v) => c.trReajusteIndiceCtrl.text = v ?? '',
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.trCondicoesPagamentoCtrl,
                labelText: 'Condições de pagamento',
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: _w(context),
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
  }
}
