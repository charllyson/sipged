import 'package:flutter/material.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:flutter/services.dart';
import 'package:siged/_blocs/process/hiring/8Minuta/minuta_contrato_controller.dart';

class SectionPartesObjeto extends StatelessWidget with FormValidationMixin {
  final MinutaContratoController controller;
  SectionPartesObjeto({super.key, required this.controller});

  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('2) Partes Contratantes e Objeto'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context, itemsPerLine: 2),
            child: CustomTextField(
              controller: c.mcContratanteCtrl,
              labelText: 'Contratante (Órgão/Unidade)',
              enabled: c.isEditable,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 2),
            child: CustomTextField(
              controller: c.mcContratadaRazaoCtrl,
              labelText: 'Contratada (Razão Social)',
              enabled: c.isEditable,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.mcContratadaCnpjCtrl,
              labelText: 'CNPJ da Contratada',
              enabled: c.isEditable,
              inputFormatters: const [],
              keyboardType: TextInputType.number,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.mcObjetoResumoCtrl,
              labelText: 'Objeto (resumo para o contrato)',
              maxLines: 3,
              enabled: c.isEditable,
              validator: validateRequired,
            ),
          ),
        ]),
        const SizedBox(height: 16),
      ],
    );
  }
}
