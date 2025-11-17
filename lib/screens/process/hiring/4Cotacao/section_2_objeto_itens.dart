import 'package:flutter/material.dart';

import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/process/hiring/4Cotacao/cotacao_controller.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

class SectionObjetoItens extends StatelessWidget with FormValidationMixin {
  final CotacaoController controller;
  SectionObjetoItens({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w3 = inputW3(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('2) Objeto/Itens (resumo)'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: Column(
                    children: [
                      SizedBox(
                        width: w3,
                        child: CustomTextField(
                          controller: c.ctUnidadeMedidaCtrl,
                          labelText: 'Unidade de medida',
                          enabled: c.isEditable,
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: w3,
                        child: CustomTextField(
                          controller: c.ctQuantidadeCtrl,
                          labelText: 'Quantidade estimada',
                          enabled: c.isEditable,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.ctObjetoCtrl,
                    labelText: 'Objeto/escopo resumido da cotação',
                    maxLines: 4,
                    enabled: c.isEditable,
                    validator: validateRequired,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.ctEspecificacoesCtrl,
                    labelText: 'Especificações técnicas relevantes',
                    maxLines: 4,
                    enabled: c.isEditable,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
