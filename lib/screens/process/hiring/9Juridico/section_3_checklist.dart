import 'package:flutter/material.dart';

import 'package:siged/_blocs/process/hiring/0Stages/hiring_data.dart';
import 'package:siged/_blocs/process/hiring/0Stages/hiring_style.dart';

import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart'
    show DropDownButtonChange;
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_blocs/process/hiring/9Juridico/parecer_juridico_controller.dart';

class SectionChecklist extends StatelessWidget {
  final ParecerJuridicoController controller;

  const SectionChecklist({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('3) Análise de Conformidade'),
        const SizedBox(height: 4),
        _CheckItem(
          label: 'Competência e motivação do processo',
          statusCtrl: c.chkCompetenciaMotivacaoCtrl,
          obsCtrl: c.obsCompetenciaMotivacaoCtrl,
          enabled: c.isEditable,
        ),
        const SizedBox(height: 8),
        _CheckItem(
          label: 'Estimativa de preços / Dotação compatível',
          statusCtrl: c.chkEstimativaDotacaoCtrl,
          obsCtrl: c.obsEstimativaDotacaoCtrl,
          enabled: c.isEditable,
        ),
        const SizedBox(height: 8),
        _CheckItem(
          label: 'Adequação da modalidade / regime',
          statusCtrl: c.chkModalidadeRegimeCtrl,
          obsCtrl: c.obsModalidadeRegimeCtrl,
          enabled: c.isEditable,
        ),
        const SizedBox(height: 8),
        _CheckItem(
          label: 'Habilitação / Documentos do gestor',
          statusCtrl: c.chkHabilitacaoCtrl,
          obsCtrl: c.obsHabilitacaoCtrl,
          enabled: c.isEditable,
        ),
        const SizedBox(height: 8),
        _CheckItem(
          label:
          'Cláusulas essenciais da minuta (reajuste, garantia, penalidades)',
          statusCtrl: c.chkClausulasEssenciaisCtrl,
          obsCtrl: c.obsClausulasEssenciaisCtrl,
          enabled: c.isEditable,
        ),
        const SizedBox(height: 8),
        _CheckItem(
          label: 'Matriz de riscos / Responsabilidades',
          statusCtrl: c.chkMatrizRiscosCtrl,
          obsCtrl: c.obsMatrizRiscosCtrl,
          enabled: c.isEditable,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String label;
  final TextEditingController statusCtrl;
  final TextEditingController obsCtrl;
  final bool enabled;

  const _CheckItem({
    required this.label,
    required this.statusCtrl,
    required this.obsCtrl,
    required this.enabled,
  });

  List<String> get _status =>
      HiringData.checklistProposta; // ['Conforme', 'Parcial', 'Não conforme', 'N/A']

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w2 = inputWidth(
          context: context,
          inner: constraints,
          perLine: 2,
          minItemWidth: 260,
          extraPadding: 29,
          spacing: 12,
        );

        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: statusCtrl,
          builder: (context, value, _) {
            final status = value.text;
            final theme = Theme.of(context);
            final colors =
            HiringStyle.checklistColorsForStatus(status, theme);

            return Container(
              decoration: BoxDecoration(
                color: colors.background,
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colors.title,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: w2,
                        child: DropDownButtonChange(
                          enabled: enabled,
                          labelText: 'Status',
                          controller: statusCtrl,
                          items: _status,
                          onChanged: (v) => statusCtrl.text = v ?? '',
                        ),
                      ),
                      SizedBox(
                        width: w2,
                        child: CustomTextField(
                          controller: obsCtrl,
                          labelText: 'Observações',
                          enabled: enabled,
                          textAlignVertical: TextAlignVertical.top,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
