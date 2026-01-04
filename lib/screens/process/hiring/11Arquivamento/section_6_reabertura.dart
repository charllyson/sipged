// lib/screens/process/hiring/11Arquivamento/section_6_reabertura.dart
import 'package:flutter/material.dart';

import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart'
    show DropDownButtonChange;
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

import 'package:siged/_blocs/process/hiring/11Arquivamento/termo_arquivamento_data.dart';

class SectionReaberturaTA extends StatefulWidget {
  final TermoArquivamentoData data;
  final bool isEditable;
  final void Function(TermoArquivamentoData updated) onChanged;

  const SectionReaberturaTA({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionReaberturaTA> createState() => _SectionReaberturaTAState();
}

class _SectionReaberturaTAState extends State<SectionReaberturaTA> {
  late final TextEditingController _condicaoCtrl;
  late final TextEditingController _prazoCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _condicaoCtrl =
        TextEditingController(text: d.taReaberturaCondicao ?? '');
    _prazoCtrl =
        TextEditingController(text: d.taPrazoReabertura ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionReaberturaTA oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void _sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      _sync(_condicaoCtrl, d.taReaberturaCondicao);
      _sync(_prazoCtrl, d.taPrazoReabertura);
    }
  }

  @override
  void dispose() {
    _condicaoCtrl.dispose();
    _prazoCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      taReaberturaCondicao: _condicaoCtrl.text,
      taPrazoReabertura: _prazoCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '6) Reabertura (se aplicável)'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w2 = inputW2(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w2,
                  child: DropDownButtonChange(
                    enabled: widget.isEditable,
                    labelText: 'Condição de reabertura',
                    controller: _condicaoCtrl,
                    items: const [
                      'Sem reabertura',
                      'Após saneamento',
                      'Após dotação',
                      'Outro',
                    ],
                    onChanged: (v) {
                      _condicaoCtrl.text = v ?? '';
                      _emitChange();
                    },
                  ),
                ),
                SizedBox(
                  width: w2,
                  child: CustomTextField(
                    controller: _prazoCtrl,
                    labelText: 'Prazo estimado p/ reabertura',
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
