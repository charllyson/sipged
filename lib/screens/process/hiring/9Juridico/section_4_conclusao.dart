import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart' show DropDownButtonChange;
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_blocs/process/hiring/9Juridico/parecer_juridico_controller.dart';

class SectionConclusao extends StatelessWidget {
  final ParecerJuridicoController controller;
  const SectionConclusao({super.key, required this.controller});

  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('4) Conclusão do Parecer'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Conclusão',
              controller: c.pjConclusaoCtrl,
              items: const [
                'Favorável',
                'Favorável com recomendações',
                'Favorável condicionado (ajustes obrigatórios)',
                'Desfavorável',
              ],
              onChanged: (v) => c.pjConclusaoCtrl.text = v ?? '',
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.pjDataAssinaturaCtrl,
              labelText: 'Data da assinatura do parecer',
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
              controller: c.pjRecomendacoesCtrl,
              labelText: 'Recomendações e/ou condicionantes',
              maxLines: 3,
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.pjAjustesObrigatoriosCtrl,
              labelText: 'Ajustes obrigatórios na minuta/edital',
              maxLines: 3,
              enabled: c.isEditable,
            ),
          ),
        ]),
        const SizedBox(height: 16),
      ],
    );
  }
}
