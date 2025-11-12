import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_blocs/process/hiring/9Juridico/parecer_juridico_controller.dart';

class SectionPendencias extends StatelessWidget {
  final ParecerJuridicoController controller;
  const SectionPendencias({super.key, required this.controller});

  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('5) Pendências e Prazos de Saneamento'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.pendenciaDescricaoCtrl,
              labelText: 'Pendências apontadas (resumo)',
              maxLines: 2,
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.pendenciaPrazoCtrl,
              labelText: 'Prazo para saneamento',
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
              controller: c.pendenciaResponsavelCtrl,
              labelText: 'Responsável pelo saneamento',
              enabled: c.isEditable,
            ),
          ),
        ]),
        const SizedBox(height: 16),
      ],
    );
  }
}
