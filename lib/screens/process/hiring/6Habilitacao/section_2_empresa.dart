import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_blocs/process/hiring/6Habilitacao/habilitacao_controller.dart';

class SectionEmpresa extends StatelessWidget with FormValidationMixin {
  final HabilitacaoController controller;
  SectionEmpresa({super.key, required this.controller});

  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('2) Empresa Contratada / Identificação'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.empRazaoSocialCtrl,
              labelText: 'Razão Social',
              enabled: c.isEditable,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.empCnpjCtrl,
              labelText: 'CNPJ',
              enabled: c.isEditable,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(14),
                TextInputMask(mask: '99.999.999/9999-99'),
              ],
              keyboardType: TextInputType.number,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.empSociosRepresentantesCtrl,
              labelText: 'Sócios/Representantes legais (nome/CPF)',
              maxLines: 2,
              enabled: c.isEditable,
            ),
          ),
        ]),
        const SizedBox(height: 16),
      ],
    );
  }
}
