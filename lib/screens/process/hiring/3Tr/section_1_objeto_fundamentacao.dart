import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_blocs/process/hiring/3Tr/tr_controller.dart';

class SectionObjetoFundamentacao extends StatelessWidget with FormValidationMixin {
  SectionObjetoFundamentacao({super.key});

  double _w(BuildContext ctx, {int itemsPerLine = 4}) =>
      responsiveInputWidth(context: ctx, itemsPerLine: itemsPerLine);

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TrController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('1) Objeto e Fundamentação'),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: _w(context, itemsPerLine: 2),
              child: CustomTextField(
                controller: c.trObjetoCtrl,
                labelText: 'Objeto do Termo de Referência',
                maxLines: 4,
                enabled: c.isEditable,
                validator: validateRequired,
              ),
            ),
            SizedBox(
              width: _w(context, itemsPerLine: 2),
              child: CustomTextField(
                controller: c.trJustificativaCtrl,
                labelText: 'Justificativa Técnica',
                maxLines: 4,
                enabled: c.isEditable,
                validator: validateRequired,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: DropDownButtonChange(
                enabled: c.isEditable,
                labelText: 'Tipo de contratação',
                controller: c.trTipoContratacaoCtrl,
                items: const [
                  'Obra de engenharia',
                  'Serviço de engenharia',
                  'Serviço comum',
                  'Aquisição'
                ],
                onChanged: (v) => c.trTipoContratacaoCtrl.text = v ?? '',
                validator: validateRequired,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: DropDownButtonChange(
                enabled: c.isEditable,
                labelText: 'Regime de execução',
                controller: c.trRegimeExecucaoCtrl,
                items: const [
                  'Preço unitário',
                  'Preço global',
                  'Empreitada integral',
                  'Tarefa'
                ],
                onChanged: (v) => c.trRegimeExecucaoCtrl.text = v ?? '',
                validator: validateRequired,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
