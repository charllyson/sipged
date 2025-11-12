import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_blocs/process/hiring/4Cotacao/cotacao_controller.dart';

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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionTitle('4) Respostas dos Fornecedores'),
            Row(children: [
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
            ]),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(fornCount, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: _FornecedorCard(
            title: 'Fornecedor ${i + 1}',
            enabled: c.isEditable,
            nomeCtrl: [c.f1NomeCtrl, c.f2NomeCtrl, c.f3NomeCtrl][i],
            cnpjCtrl: [c.f1CnpjCtrl, c.f2CnpjCtrl, c.f3CnpjCtrl][i],
            valorCtrl: [c.f1ValorCtrl, c.f2ValorCtrl, c.f3ValorCtrl][i],
            dataCtrl: [c.f1DataRecebimentoCtrl, c.f2DataRecebimentoCtrl, c.f3DataRecebimentoCtrl][i],
            linkCtrl: [c.f1LinkPropostaCtrl, c.f2LinkPropostaCtrl, c.f3LinkPropostaCtrl][i],
          ),
        )),
      ],
    );
  }
}

class _FornecedorCard extends StatelessWidget {
  final String title;
  final TextEditingController nomeCtrl;
  final TextEditingController cnpjCtrl;
  final TextEditingController valorCtrl;
  final TextEditingController dataCtrl;
  final TextEditingController linkCtrl;
  final bool enabled;

  const _FornecedorCard({
    required this.title,
    required this.nomeCtrl,
    required this.cnpjCtrl,
    required this.valorCtrl,
    required this.dataCtrl,
    required this.linkCtrl,
    required this.enabled,
  });

  double _w(BuildContext ctx, {int itemsPerLine = 4}) =>
      responsiveInputWidth(context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: cs.primary)),
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: nomeCtrl,
                labelText: 'Razão/Nome',
                enabled: enabled,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: cnpjCtrl,
                labelText: 'CNPJ',
                enabled: enabled,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(14),
                  TextInputMask(mask: '99.999.999/9999-99'),
                ],
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: valorCtrl,
                labelText: 'Valor cotado (R\$)',
                enabled: enabled,
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: dataCtrl,
                labelText: 'Data recebimento',
                hintText: 'dd/mm/aaaa',
                enabled: enabled,
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
                controller: linkCtrl,
                labelText: 'Link/Arquivo da proposta',
                enabled: enabled,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
