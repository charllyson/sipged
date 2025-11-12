import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/formats/mask_class.dart';

import 'package:siged/_blocs/process/hiring/5Edital/edital_julgamento_controller.dart';

class SectionResultado extends StatelessWidget {
  final EditalJulgamentoController controller;
  final GlobalKey? keyResultado;
  const SectionResultado({super.key, required this.controller, this.keyResultado});

  double _w(BuildContext ctx, {int itemsPerLine = 4}) =>
      responsiveInputWidth(context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24);

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final cs = Theme.of(context).colorScheme;

    final highlightBg = c.highlightWinner
        ? cs.secondaryContainer.withOpacity(0.55)
        : Colors.transparent;
    final highlightBorder = c.highlightWinner ? cs.secondary : cs.outlineVariant;

    return KeyedSubtree(
      key: keyResultado,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: highlightBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: highlightBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Resultado / Adjudicação / Homologação'),
            Wrap(spacing: 12, runSpacing: 12, children: [
              SizedBox(
                width: _w(context),
                child: CustomTextField(
                  controller: c.sjVencedorCtrl,
                  labelText: 'Vencedor provisório',
                  enabled: c.isEditable,
                ),
              ),
              SizedBox(
                width: _w(context),
                child: CustomTextField(
                  controller: c.sjVencedorCnpjCtrl,
                  labelText: 'CNPJ vencedor',
                  enabled: c.isEditable,
                ),
              ),
              SizedBox(
                width: _w(context),
                child: CustomTextField(
                  controller: c.sjValorVencedorCtrl,
                  labelText: 'Valor vencedor (R\$)',
                  enabled: c.isEditable,
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(
                width: _w(context),
                child: CustomTextField(
                  controller: c.sjDataResultadoCtrl,
                  labelText: 'Data do resultado',
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
              // adjudicação
              SizedBox(
                width: _w(context),
                child: CustomTextField(
                  controller: c.sjAdjudicacaoDataCtrl,
                  labelText: 'Data da adjudicação',
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
                  controller: c.sjAdjudicacaoLinkCtrl,
                  labelText: 'Link da adjudicação',
                  enabled: c.isEditable,
                ),
              ),
              // homologação
              SizedBox(
                width: _w(context),
                child: CustomTextField(
                  controller: c.sjHomologacaoDataCtrl,
                  labelText: 'Data da homologação',
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
                  controller: c.sjHomologacaoLinkCtrl,
                  labelText: 'Link da homologação',
                  enabled: c.isEditable,
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(
              children: [
                Switch(
                  value: c.highlightWinner,
                  onChanged: c.isEditable ? (v) => c.setWinnerHighlight(v) : null,
                ),
                const SizedBox(width: 8),
                const Expanded(child: Text('Destaque visual do resultado')),
              ],
            ),
            Row(
              children: [
                Switch(
                  value: c.habilitarSomenteVencedor,
                  onChanged: c.isEditable
                      ? (v) => c.habilitarSomenteVencedor = v
                      : null,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Habilitar apenas o vencedor provisório na aba "Habilitação"',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
