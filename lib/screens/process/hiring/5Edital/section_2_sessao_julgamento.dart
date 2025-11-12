import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/formats/mask_class.dart';

import 'package:siged/_blocs/process/hiring/5Edital/edital_julgamento_controller.dart';

class SectionSessaoJulgamento extends StatelessWidget {
  final EditalJulgamentoController controller;
  const SectionSessaoJulgamento({super.key, required this.controller});

  double _w(BuildContext ctx, {int itemsPerLine = 4}) =>
      responsiveInputWidth(context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24);

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('2) Sessão / Abertura & Julgamento'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.sjDataSessaoCtrl,
              labelText: 'Data da sessão',
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
            width: _w(context),
            child: CustomTextField(
              controller: c.sjHoraSessaoCtrl,
              labelText: 'Hora da sessão',
              hintText: 'hh:mm',
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.sjResponsavelCtrl,
              labelText: 'Responsável (pregoeiro/comissão)',
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.sjLocalPlataformaCtrl,
              labelText: 'Local/Plataforma',
              enabled: c.isEditable,
            ),
          ),
        ]),
        const SizedBox(height: 8),
      ],
    );
  }
}
