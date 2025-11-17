import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_blocs/process/hiring/4Cotacao/cotacao_controller.dart';
import 'package:siged/screens/process/hiring/4Cotacao/fornecedor_card.dart';

class SectionRespostasFornecedores extends StatelessWidget {
  final CotacaoController controller;
  final int fornCount;
  final VoidCallback? onAdd;
  final VoidCallback? onRemoveOne;

  const SectionRespostasFornecedores({
    super.key,
    required this.controller,
    required this.fornCount,
    this.onAdd,
    this.onRemoveOne,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const SizedBox(height: 8),
        ...List.generate(
          fornCount,
              (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: FornecedorCard(
              title: 'Fornecedor ${i + 1}',
              enabled: c.isEditable,
              nomeCtrl: [c.f1NomeCtrl, c.f2NomeCtrl, c.f3NomeCtrl][i],
              cnpjCtrl: [c.f1CnpjCtrl, c.f2CnpjCtrl, c.f3CnpjCtrl][i],
              valorCtrl: [c.f1ValorCtrl, c.f2ValorCtrl, c.f3ValorCtrl][i],
              dataCtrl: [
                c.f1DataRecebimentoCtrl,
                c.f2DataRecebimentoCtrl,
                c.f3DataRecebimentoCtrl
              ][i],
              linkCtrl: [
                c.f1LinkPropostaCtrl,
                c.f2LinkPropostaCtrl,
                c.f3LinkPropostaCtrl
              ][i],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionTitle('4) Respostas dos Fornecedores'),
            Row(
              children: [
                if (onRemoveOne != null && c.isEditable && fornCount > 1)
                  TextButton.icon(
                    onPressed: onRemoveOne,
                    icon: const Icon(Icons.remove_circle_outline),
                    label: const Text('Remover fornecedor'),
                  ),
                const SizedBox(width: 8),
                if (onAdd != null && c.isEditable && fornCount < 3)
                  OutlinedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar fornecedor'),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
