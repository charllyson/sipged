import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart' show DropDownButtonChange;
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/formats/mask_class.dart';

import 'package:siged/_blocs/process/hiring/5Edital/edital_julgamento_controller.dart';

class SectionDivulgacaoRecebimento extends StatelessWidget with FormValidationMixin {
  final EditalJulgamentoController controller;
  SectionDivulgacaoRecebimento({super.key, required this.controller});

  double _w(BuildContext ctx, {int itemsPerLine = 4}) =>
      responsiveInputWidth(context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24);

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('1) Divulgação do Edital & Recebimento'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.edNumeroCtrl,
              labelText: 'Nº do edital/processo',
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Modalidade',
              controller: c.edModalidadeCtrl,
              items: const ['Pregão','Concorrência','Dispensa','Inexigibilidade','RDC','Concurso'],
              onChanged: (v) => c.edModalidadeCtrl.text = v ?? '',
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Critério de julgamento',
              controller: c.edCriterioCtrl,
              items: const ['Menor preço','Técnica e preço','Maior desconto','Maior retorno econômico'],
              onChanged: (v) => c.edCriterioCtrl.text = v ?? '',
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.edIdPncpCtrl,
              labelText: 'ID PNCP',
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.edLinkPncpCtrl,
              labelText: 'Link PNCP',
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.edLinkSeiCtrl,
              labelText: 'Link SEI (processo)',
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.edLinksPublicacoesCtrl,
              labelText: 'Outras publicações (links)',
              enabled: c.isEditable,
              maxLines: 2,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.edDataPublicacaoCtrl,
              labelText: 'Data publicação',
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
              controller: c.edPrazoImpugnacaoCtrl,
              labelText: 'Prazo impugnação',
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
              controller: c.edPrazoPropostasCtrl,
              labelText: 'Limite para propostas',
              hintText: 'dd/mm/aaaa hh:mm',
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.edObservacoesCtrl,
              labelText: 'Observações',
              enabled: c.isEditable,
              maxLines: 3,
            ),
          ),
        ]),
        const SizedBox(height: 16),
      ],
    );
  }
}
