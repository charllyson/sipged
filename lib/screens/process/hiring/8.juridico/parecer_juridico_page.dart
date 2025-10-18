import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

import 'package:siged/_utils/responsive_utils.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/mask_class.dart';

import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/autocomplete/autocomplete_user_class.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/screens/process/hiring/8.juridico/parecer_juridico_controller.dart';

class ParecerJuridicoPage extends StatefulWidget {
  final ParecerJuridicoController controller;
  final bool readOnly;

  const ParecerJuridicoPage({
    super.key,
    required this.controller,
    this.readOnly = false,
  });

  @override
  State<ParecerJuridicoPage> createState() => _ParecerJuridicoPageState();
}

class _ParecerJuridicoPageState extends State<ParecerJuridicoPage>
    with FormValidationMixin {
  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx,
    itemsPerLine: itemsPerLine,
    spacing: 12,
    margin: 12,
    extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = widget.controller..isEditable = !widget.readOnly;
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Parecer Jurídico',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // 1) Metadados
        _Section('1) Metadados'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.pjNumeroCtrl,
              labelText: 'Nº do parecer',
              enabled: c.isEditable,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.pjDataCtrl,
              labelText: 'Data do parecer',
              hintText: 'dd/mm/aaaa',
              enabled: c.isEditable,
              validator: validateRequired,
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
              controller: c.pjOrgaoJuridicoCtrl,
              labelText: 'Órgão/Unidade jurídica',
              enabled: c.isEditable,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: AutocompleteUserClass(
              label: 'Parecerista',
              controller: c.pjPareceristaCtrl,
              allUsers: users,
              enabled: c.isEditable,
              initialUserId: c.pjPareceristaUserId,
              validator: validateRequired,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // 2) Documentos analisados
        _Section('2) Documentos/Peças analisadas'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.pjRefProcessoCtrl,
              labelText: 'Referência do processo (SEI/Interno)',
              enabled: c.isEditable,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.pjDocumentosExaminadosCtrl,
              labelText: 'Documentos examinados (TR, ETP, Minuta, Edital etc.)',
              maxLines: 3,
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.pjLinksAnexosCtrl,
              labelText: 'Links/Anexos (SEI/Drive/PNCP)',
              maxLines: 2,
              enabled: c.isEditable,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // 3) Análise de conformidade (checklist resumido)
        _Section('3) Análise de Conformidade'),
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

        // 4) Conclusão
        _Section('4) Conclusão do Parecer'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Conclusão',
              controller: c.pjConclusaoCtrl,
              items: const [
                'Favorável',
                'Favorável com recomendações',
                'Favorável condicionado (ajustes obrigatórios)',
                'Desfavorável',
              ],
              onChanged: (v) => setState(() => c.pjConclusaoCtrl.text = v ?? ''),
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.pjDataAssinaturaCtrl,
              labelText: 'Data da assinatura do parecer',
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
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.pjRecomendacoesCtrl,
              labelText: 'Recomendações e/ou condicionantes',
              maxLines: 3,
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.pjAjustesObrigatoriosCtrl,
              labelText: 'Ajustes obrigatórios na minuta/edital',
              maxLines: 3,
              enabled: c.isEditable,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // 5) Pendências e prazos de saneamento
        _Section('5) Pendências e Prazos de Saneamento'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.pendenciaDescricaoCtrl,
              labelText: 'Pendências apontadas (resumo)',
              maxLines: 2,
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.pendenciaPrazoCtrl,
              labelText: 'Prazo para saneamento',
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
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.pendenciaResponsavelCtrl,
              labelText: 'Responsável pelo saneamento',
              enabled: c.isEditable,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // 6) Assinaturas / Referências finais
        _Section('6) Assinaturas / Referências finais'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context, itemsPerLine: 2),
            child: AutocompleteUserClass(
              label: 'Autoridade que aprovou o parecer',
              controller: c.pjAutoridadeCtrl,
              allUsers: users,
              enabled: c.isEditable,
              initialUserId: c.pjAutoridadeUserId,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 2),
            child: CustomTextField(
              controller: c.pjLocalCtrl,
              labelText: 'Local',
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.pjObservacoesFinaisCtrl,
              labelText: 'Observações finais',
              maxLines: 2,
              enabled: c.isEditable,
            ),
          ),
        ]),

        const SizedBox(height: 24),
      ]),
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
    context: ctx,
    itemsPerLine: itemsPerLine,
    spacing: 12,
    margin: 12,
    extraPadding: 24,
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
          child: Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600)),
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

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: cs.primary,
        ),
      ),
    );
  }
}
