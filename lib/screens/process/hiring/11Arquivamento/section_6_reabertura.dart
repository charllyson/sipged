import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart'
    show DropDownButtonChange;
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_blocs/process/hiring/11Arquivamento/termo_arquivamento_controller.dart';

class SectionReaberturaTA extends StatefulWidget {
  final TermoArquivamentoController controller;
  const SectionReaberturaTA({super.key, required this.controller});

  @override
  State<SectionReaberturaTA> createState() => _SectionReaberturaTAState();
}

class _SectionReaberturaTAState extends State<SectionReaberturaTA> {
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('6) Reabertura (se aplicável)'),
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
                    enabled: c.isEditable,
                    labelText: 'Condição de reabertura',
                    controller: c.taReaberturaCondicaoCtrl,
                    items: const [
                      'Sem reabertura',
                      'Após saneamento',
                      'Após dotação',
                      'Outro',
                    ],
                    onChanged: (v) => setState(
                          () => c.taReaberturaCondicaoCtrl.text = v ?? '',
                    ),
                  ),
                ),
                SizedBox(
                  width: w2,
                  child: CustomTextField(
                    controller: c.taPrazoReaberturaCtrl,
                    labelText: 'Prazo estimado p/ reabertura',
                    enabled: c.isEditable,
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
