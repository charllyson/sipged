// lib/screens/process/hiring/4Cotacao/section_6_consolidacao_resultado.dart
import 'package:flutter/material.dart';
import 'package:siged/_blocs/process/hiring/0Stages/hiring_data.dart';

import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';

import 'package:siged/_blocs/process/hiring/4Cotacao/cotacao_data.dart';

class SectionConsolidacaoResultado extends StatefulWidget {
  final CotacaoData data;
  final bool isEditable;
  final void Function(CotacaoData updated) onChanged;

  const SectionConsolidacaoResultado({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionConsolidacaoResultado> createState() =>
      _SectionConsolidacaoResultadoState();
}

class _SectionConsolidacaoResultadoState
    extends State<SectionConsolidacaoResultado> {
  late final TextEditingController _criterioCtrl;
  late final TextEditingController _valorConsolidadoCtrl;
  late final TextEditingController _observacoesCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _criterioCtrl =
        TextEditingController(text: d.criterioConsolidacao ?? '');
    _valorConsolidadoCtrl =
        TextEditingController(text: d.valorConsolidado ?? '');
    _observacoesCtrl =
        TextEditingController(text: d.observacoes ?? '');
  }

  @override
  void didUpdateWidget(
      covariant SectionConsolidacaoResultado oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void _sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      _sync(_criterioCtrl, d.criterioConsolidacao);
      _sync(_valorConsolidadoCtrl, d.valorConsolidado);
      _sync(_observacoesCtrl, d.observacoes);
    }
  }

  @override
  void dispose() {
    _criterioCtrl.dispose();
    _valorConsolidadoCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      criterioConsolidacao: _criterioCtrl.text,
      valorConsolidado: _valorConsolidadoCtrl.text,
      observacoes: _observacoesCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w4 = inputW4(context, constraints);
        final w1 = inputW1(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(text: '5) Consolidação e Resultado'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w4,
                  child: DropDownButtonChange(
                    enabled: widget.isEditable,
                    labelText: 'Critério de consolidação',
                    controller: _criterioCtrl,
                    items: HiringData.criterioConsolidacao,
                    onChanged: (v) {
                      _criterioCtrl.text = v ?? '';
                      _emitChange();
                    },
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _valorConsolidadoCtrl,
                    labelText: 'Valor consolidado (R\$)',
                    enabled: widget.isEditable,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w1,
                  child: CustomTextField(
                    controller: _observacoesCtrl,
                    labelText: 'Observações / exclusões / premissas',
                    maxLines: 3,
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
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
