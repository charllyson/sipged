import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_blocs/process/hiring/6Habilitacao/habilitacao_controller.dart';

class SectionConsolidacao extends StatelessWidget with FormValidationMixin {
  final HabilitacaoController controller;
  SectionConsolidacao({super.key, required this.controller});

  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('6) Consolidação e Parecer do Gestor'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Situação da habilitação',
              controller: c.dgSituacaoHabilitacaoCtrl,
              items: const ['Habilitada', 'Habilitada com ressalvas', 'Não habilitada', 'Aguardando complementos'],
              onChanged: (v) => c.dgSituacaoHabilitacaoCtrl.text = v ?? '',
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.dgDataConclusaoCtrl,
              labelText: 'Data da conclusão',
              hintText: 'dd/mm/aaaa',
              enabled: c.isEditable,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
                TextInputMask(mask: '99/99/9999'),
              ],
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.dgParecerConclusivoCtrl,
              labelText: 'Parecer conclusivo do gestor',
              maxLines: 3,
              enabled: c.isEditable,
            ),
          ),
        ]),
        const SizedBox(height: 24),
      ],
    );
  }
}
