// lib/screens/modules/contracts/hiring/3Tr/section_7_precos_pagamento_reajuste.dart
import 'package:flutter/material.dart';

import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/input/drop_down_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/3Tr/tr_data.dart';

class SectionPrecosPagamentoReajuste extends StatefulWidget {
  final bool isEditable;
  final TrData data;
  final void Function(TrData updated) onChanged;

  const SectionPrecosPagamentoReajuste({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
  });

  @override
  State<SectionPrecosPagamentoReajuste> createState() =>
      _SectionPrecosPagamentoReajusteState();
}

class _SectionPrecosPagamentoReajusteState
    extends State<SectionPrecosPagamentoReajuste> {
  late final TextEditingController _estimativaValorCtrl;
  late final TextEditingController _reajusteIndiceCtrl;
  late final TextEditingController _condicoesPagamentoCtrl;
  late final TextEditingController _garantiaCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _estimativaValorCtrl =
        TextEditingController(text: d.estimativaValor ?? '');
    _reajusteIndiceCtrl =
        TextEditingController(text: d.reajusteIndice ?? '');
    _condicoesPagamentoCtrl =
        TextEditingController(text: d.condicoesPagamento ?? '');
    _garantiaCtrl = TextEditingController(text: d.garantia ?? '');
  }

  @override
  void didUpdateWidget(
      covariant SectionPrecosPagamentoReajuste oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;
      void sync(TextEditingController c, String? v) {
        final nv = v ?? '';
        if (c.text != nv) c.text = nv;
      }

      sync(_estimativaValorCtrl, d.estimativaValor);
      sync(_reajusteIndiceCtrl, d.reajusteIndice);
      sync(_condicoesPagamentoCtrl, d.condicoesPagamento);
      sync(_garantiaCtrl, d.garantia);
    }
  }

  @override
  void dispose() {
    _estimativaValorCtrl.dispose();
    _reajusteIndiceCtrl.dispose();
    _condicoesPagamentoCtrl.dispose();
    _garantiaCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      estimativaValor: _estimativaValorCtrl.text,
      reajusteIndice: _reajusteIndiceCtrl.text,
      condicoesPagamento: _condicoesPagamentoCtrl.text,
      garantia: _garantiaCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w4 = inputW4(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(text: '7) Preços, Pagamento, Reajuste e Garantia'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _estimativaValorCtrl,
                    labelText: 'Estimativa de valor (R\$)',
                    enabled: widget.isEditable,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: DropDownChange(
                    enabled: widget.isEditable,
                    labelText: 'Critério de reajuste',
                    controller: _reajusteIndiceCtrl,
                    items: const [
                      'IPCA',
                      'INCC',
                      'IGP-M',
                      'Sem reajuste',
                    ],
                    onChanged: (v) {
                      _reajusteIndiceCtrl.text = v ?? '';
                      _emitChange();
                      setState(() {});
                    },
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _condicoesPagamentoCtrl,
                    labelText: 'Condições de pagamento',
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: DropDownChange(
                    enabled: widget.isEditable,
                    labelText: 'Garantia contratual',
                    controller: _garantiaCtrl,
                    items: const [
                      'Não exigida',
                      'Caução em dinheiro',
                      'Seguro-garantia',
                      'Fiança bancária',
                    ],
                    onChanged: (v) {
                      _garantiaCtrl.text = v ?? '';
                      _emitChange();
                      setState(() {});
                    },
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
