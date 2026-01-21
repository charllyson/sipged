// lib/screens/modules/contracts/hiring/11Arquivamento/section_3_fundamentacao.dart
import 'package:flutter/material.dart';

import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

import 'package:siged/_blocs/modules/contracts/hiring/11Arquivamento/termo_arquivamento_data.dart';

class SectionFundamentacaoTA extends StatefulWidget {
  final TermoArquivamentoData data;
  final bool isEditable;
  final void Function(TermoArquivamentoData updated) onChanged;

  const SectionFundamentacaoTA({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionFundamentacaoTA> createState() =>
      _SectionFundamentacaoTAState();
}

class _SectionFundamentacaoTAState extends State<SectionFundamentacaoTA>
    with FormValidationMixin {
  late final TextEditingController _fundamentosCtrl;
  late final TextEditingController _justificativaCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _fundamentosCtrl =
        TextEditingController(text: d.taFundamentosLegais ?? '');
    _justificativaCtrl =
        TextEditingController(text: d.taJustificativa ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionFundamentacaoTA oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void _sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      _sync(_fundamentosCtrl, d.taFundamentosLegais);
      _sync(_justificativaCtrl, d.taJustificativa);
    }
  }

  @override
  void dispose() {
    _fundamentosCtrl.dispose();
    _justificativaCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      taFundamentosLegais: _fundamentosCtrl.text,
      taJustificativa: _justificativaCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '3) Fundamentação'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w2 = inputW2(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w2,
                  child: CustomTextField(
                    controller: _fundamentosCtrl,
                    labelText:
                    'Fundamentos legais (ex.: Lei 14.133/2021, art. ...)',
                    maxLines: 4,
                    enabled: widget.isEditable,
                    validator: validateRequired,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w2,
                  child: CustomTextField(
                    controller: _justificativaCtrl,
                    labelText: 'Justificativa (resumo técnico/jurídico)',
                    maxLines: 4,
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
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
