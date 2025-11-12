import 'package:flutter/material.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart' show DropDownButtonChange;
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_blocs/process/hiring/9Juridico/parecer_juridico_controller.dart';

class SectionChecklist extends StatelessWidget {
  final ParecerJuridicoController controller;
  const SectionChecklist({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('3) Análise de Conformidade'),
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
          label: 'Cláusulas essenciais da minuta (reajuste, garantia, penalidades)',
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

  List<String> get _status => const ['Conforme', 'Parcial', 'Não conforme', 'N/A'];

  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Wrap(spacing: 12, runSpacing: 12, children: [
        SizedBox(
          width: _w(context),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        SizedBox(
          width: _w(context),
          child: DropDownButtonChange(
            enabled: enabled,
            labelText: 'Status',
            controller: statusCtrl,
            items: _status,
            onChanged: (v) => statusCtrl.text = v ?? '',
          ),
        ),
        SizedBox(
          width: _w(context, itemsPerLine: 1),
          child: CustomTextField(
            controller: obsCtrl,
            labelText: 'Observações',
            maxLines: 2,
            enabled: enabled,
          ),
        ),
      ]),
    );
  }
}
