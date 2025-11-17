import 'package:flutter/material.dart';

import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

import 'package:siged/_blocs/process/hiring/8Minuta/minuta_contrato_controller.dart';

class SectionValor extends StatelessWidget {
  final MinutaContratoController controller;

  const SectionValor({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('3) Valor Contratual'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w4 = inputW4(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: c.mcValorGlobalCtrl,
                    labelText: 'Valor global (R\$)',
                    enabled: c.isEditable,
                    keyboardType: TextInputType.number,
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
