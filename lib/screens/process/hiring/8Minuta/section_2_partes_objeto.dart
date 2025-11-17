import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/formats/mask_class.dart';

import 'package:siged/_blocs/process/hiring/8Minuta/minuta_contrato_controller.dart';

class SectionPartesObjeto extends StatelessWidget with FormValidationMixin {
  final MinutaContratoController controller;

  SectionPartesObjeto({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('2) Partes Contratantes e Objeto'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w3 = inputW3(context, constraints);
            final w1 = inputW1(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.mcContratanteCtrl,
                    labelText: 'Contratante (Órgão/Unidade)',
                    enabled: c.isEditable,
                    validator: validateRequired,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.mcContratadaRazaoCtrl,
                    labelText: 'Contratada (Razão Social)',
                    enabled: c.isEditable,
                    validator: validateRequired,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.mcContratadaCnpjCtrl,
                    labelText: 'CNPJ da Contratada',
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
                  width: w1,
                  child: CustomTextField(
                    controller: c.mcObjetoResumoCtrl,
                    labelText: 'Objeto (resumo para o contrato)',
                    maxLines: 3,
                    enabled: c.isEditable,
                    validator: validateRequired,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
