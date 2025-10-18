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
import 'package:siged/_widgets/input/drop_down_botton_change.dart' show DropDownButtonChange;

import 'package:siged/screens/process/hiring/2.etp/etp_controller.dart';

class EtpPage extends StatefulWidget {
  final EtpController controller;
  const EtpPage({super.key, required this.controller});

  @override
  State<EtpPage> createState() => _EtpPageState();
}

class _EtpPageState extends State<EtpPage> with FormValidationMixin {
  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Estudo Técnico Preliminar (ETP)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        _SectionTitle('1) Identificação / Metadados'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.etpNumeroCtrl,
              enabled: c.isEditable,
              labelText: 'Nº ETP / Referência interna',
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.etpDataElaboracaoCtrl,
              enabled: c.isEditable,
              labelText: 'Data de elaboração',
              hintText: 'dd/mm/aaaa',
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
            child: AutocompleteUserClass(
              label: 'Responsável técnico pela elaboração',
              controller: c.etpResponsavelElaboracaoCtrl,
              allUsers: users,
              enabled: c.isEditable,
              initialUserId: c.etpResponsavelElaboracaoUserId,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.etpArtNumeroCtrl,
              enabled: c.isEditable,
              labelText: 'Nº ART do responsável (se aplicável)',
            ),
          ),
        ]),
        const SizedBox(height: 16),

        _SectionTitle('2) Motivação, objetivos e requisitos'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.etpMotivacaoCtrl,
              enabled: c.isEditable,
              labelText: 'Motivação / Problema a ser resolvido',
              maxLines: 3, validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.etpObjetivosCtrl,
              enabled: c.isEditable,
              labelText: 'Objetivos da contratação',
              maxLines: 3, validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.etpRequisitosMinimosCtrl,
              enabled: c.isEditable,
              labelText: 'Requisitos mínimos/escopo preliminar',
              maxLines: 4,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        _SectionTitle('3) Alternativas e solução recomendada'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.etpAlternativasAvaliadasCtrl,
              enabled: c.isEditable,
              labelText: 'Alternativas avaliadas (resumo)',
              maxLines: 4,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 3),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Solução recomendada',
              controller: c.etpSolucaoRecomendadaCtrl,
              items: const ['Obra de engenharia','Serviço de engenharia','Serviço comum','Aquisição'],
              onChanged: (v) => setState(() => c.etpSolucaoRecomendadaCtrl.text = v ?? ''),
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 3),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Complexidade',
              controller: c.etpComplexidadeCtrl,
              items: const ['Baixa', 'Média', 'Alta'],
              onChanged: (v) => setState(() => c.etpComplexidadeCtrl.text = v ?? ''),
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 3),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Risco preliminar',
              controller: c.etpNivelRiscoCtrl,
              items: const ['Baixo', 'Moderado', 'Alto', 'Crítico'],
              onChanged: (v) => setState(() => c.etpNivelRiscoCtrl.text = v ?? ''),
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.etpJustificativaSolucaoCtrl,
              enabled: c.isEditable,
              labelText: 'Justificativa da solução escolhida',
              maxLines: 3, validator: validateRequired,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        _SectionTitle('4) Mercado e estimativa de custos/benefícios'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.etpAnaliseMercadoCtrl,
              enabled: c.isEditable,
              labelText: 'Análise de mercado / fornecedores potenciais',
              maxLines: 4,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 3),
            child: CustomTextField(
              controller: c.etpEstimativaValorCtrl,
              enabled: c.isEditable,
              labelText: 'Estimativa de valor (R\$)',
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 3),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Metodologia da estimativa',
              controller: c.etpMetodoEstimativaCtrl,
              items: const ['SINAPI', 'DER ref.', 'Cotações', 'Misto'],
              onChanged: (v) => setState(() => c.etpMetodoEstimativaCtrl.text = v ?? ''),
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.etpBeneficiosEsperadosCtrl,
              enabled: c.isEditable,
              labelText: 'Benefícios esperados (qualitativos/quantitativos)',
              maxLines: 3,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        _SectionTitle('5) Cronograma, indicadores e aceite (preliminares)'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.etpPrazoExecucaoDiasCtrl,
              enabled: c.isEditable,
              labelText: 'Prazo estimado de execução (dias)',
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.etpTempoVigenciaMesesCtrl,
              enabled: c.isEditable,
              labelText: 'Vigência estimada (meses)',
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.etpCriteriosAceiteCtrl,
              enabled: c.isEditable,
              labelText: 'Critérios de medição e aceite (preliminares)',
              maxLines: 3,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.etpIndicadoresDesempenhoCtrl,
              enabled: c.isEditable,
              labelText: 'Indicadores de desempenho (preliminares)',
              maxLines: 3,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        _SectionTitle('6) Premissas, restrições e licenciamento'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.etpPremissasCtrl,
              enabled: c.isEditable,
              labelText: 'Premissas (ex.: disponibilização de áreas, PO)',
              maxLines: 3,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.etpRestricoesCtrl,
              enabled: c.isEditable,
              labelText: 'Restrições (ex.: janela operacional, tráfego)',
              maxLines: 3,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Licenciamento ambiental necessário?',
              controller: c.etpLicenciamentoAmbientalCtrl,
              items: const ['Sim', 'Não', 'A confirmar'],
              onChanged: (v) => setState(() => c.etpLicenciamentoAmbientalCtrl.text = v ?? ''),
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.etpObservacoesAmbientaisCtrl,
              enabled: c.isEditable,
              labelText: 'Observações ambientais (ex.: condicionantes)',
              maxLines: 3,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        _SectionTitle('7) Documentos, evidências e equipe'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Levantamentos de campo (geotécnico/contagem tráfego)',
              controller: c.etpLevantamentosCampoCtrl,
              items: const ['Sim', 'Não', 'Parcial', 'N/A'],
              onChanged: (v) => setState(() => c.etpLevantamentosCampoCtrl.text = v ?? ''),
            ),
          ),
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Projeto básico/executivo já existente?',
              controller: c.etpProjetoExistenteCtrl,
              items: const ['Sim', 'Não', 'Parcial', 'N/A'],
              onChanged: (v) => setState(() => c.etpProjetoExistenteCtrl.text = v ?? ''),
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.etpLinksEvidenciasCtrl,
              enabled: c.isEditable,
              labelText: 'Links/Evidências (SEI, Storage, etc.)',
              maxLines: 2,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.etpEquipeEnvolvidaCtrl,
              enabled: c.isEditable,
              labelText: 'Equipe envolvida (nomes/cargos)',
              maxLines: 2,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        _SectionTitle('8) Conclusão'),
        CustomTextField(
          controller: c.etpConclusaoCtrl,
          enabled: c.isEditable,
          labelText: 'Conclusão / Encaminhamento',
          maxLines: 3,
        ),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: cs.primary)),
    );
  }
}
