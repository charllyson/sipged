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

import 'package:siged/screens/process/hiring/3.tr/tr_controller.dart';

class TermoReferenciaPage extends StatefulWidget {
  final TrController controller;
  final bool readOnly;
  const TermoReferenciaPage({super.key, required this.controller, this.readOnly = false});

  @override
  State<TermoReferenciaPage> createState() => _TermoReferenciaPageState();
}

class _TermoReferenciaPageState extends State<TermoReferenciaPage>
    with FormValidationMixin {
  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = widget.controller..isEditable = !widget.readOnly;
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Termo de Referência',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        _Section('1) Objeto e Fundamentação'),
        Wrap(spacing: 16, runSpacing: 16, children: [
          SizedBox(
            width: _w(context, itemsPerLine: 2),
            child: CustomTextField(
              controller: c.trObjetoCtrl,
              labelText: 'Objeto do Termo de Referência',
              maxLines: 4,
              enabled: c.isEditable,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 2),
            child: CustomTextField(
              controller: c.trJustificativaCtrl,
              labelText: 'Justificativa Técnica',
              maxLines: 4,
              enabled: c.isEditable,
              validator: validateRequired,
            ),
          ),
          // ⛔ Tipo de contratação – removido (propriedade do DFD)
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Regime de execução',
              controller: c.trRegimeExecucaoCtrl,
              items: const ['Preço unitário','Preço global','Empreitada integral','Tarefa'],
              onChanged: (v) => setState(() => c.trRegimeExecucaoCtrl.text = v ?? ''),
              validator: validateRequired,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        _Section('2) Escopo / Requisitos'),
        Wrap(spacing: 16, runSpacing: 16, children: [
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.trEscopoDetalhadoCtrl,
              labelText: 'Escopo detalhado da contratação',
              maxLines: 6,
              enabled: c.isEditable,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.trRequisitosTecnicosCtrl,
              labelText: 'Requisitos técnicos mínimos',
              maxLines: 5,
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.trEspecificacoesNormasCtrl,
              labelText: 'Especificações / normas aplicáveis (ABNT, DNIT etc.)',
              maxLines: 4,
              enabled: c.isEditable,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        _Section('3) Local, Prazos e Cronograma'),
        Wrap(spacing: 16, runSpacing: 16, children: [
          SizedBox(
            width: _w(context, itemsPerLine: 3),
            child: CustomTextField(
              controller: c.trLocalExecucaoCtrl,
              labelText: 'Local de execução',
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 3),
            child: CustomTextField(
              controller: c.trPrazoExecucaoDiasCtrl,
              labelText: 'Prazo de execução (dias)',
              enabled: c.isEditable,
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 3),
            child: CustomTextField(
              controller: c.trVigenciaMesesCtrl,
              labelText: 'Vigência contratual (meses)',
              enabled: c.isEditable,
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.trCronogramaFisicoCtrl,
              labelText: 'Cronograma físico preliminar (marcos/etapas)',
              maxLines: 4,
              enabled: c.isEditable,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        _Section('4) Medição, Aceite e Indicadores'),
        Wrap(spacing: 16, runSpacing: 16, children: [
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.trCriteriosMedicaoCtrl,
              labelText: 'Critérios de medição',
              maxLines: 3,
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.trCriteriosAceiteCtrl,
              labelText: 'Critérios de aceite',
              maxLines: 3,
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.trIndicadoresDesempenhoCtrl,
              labelText: 'Indicadores de desempenho (SLA/KPI)',
              maxLines: 3,
              enabled: c.isEditable,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        _Section('5) Obrigações, Equipe e Gestão'),
        Wrap(spacing: 16, runSpacing: 16, children: [
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.trObrigacoesContratadaCtrl,
              labelText: 'Obrigações da contratada',
              maxLines: 4,
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.trObrigacoesContratanteCtrl,
              labelText: 'Obrigações da contratante',
              maxLines: 4,
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Equipe mínima exigida',
              controller: c.trEquipeMinimaCtrl,
              items: const [
                'Eng. civil + técnico de obras',
                'Eng. civil + encarregado + laboratório',
                'A definir no TR',
              ],
              onChanged: (v) => setState(() => c.trEquipeMinimaCtrl.text = v ?? ''),
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 2),
            child: AutocompleteUserClass(
              label: 'Fiscal do contrato (indicativo)',
              controller: c.trFiscalCtrl,
              enabled: c.isEditable,
              allUsers: users,
              initialUserId: c.trFiscalUserId,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 2),
            child: AutocompleteUserClass(
              label: 'Gestor do contrato (indicativo)',
              controller: c.trGestorCtrl,
              enabled: c.isEditable,
              allUsers: users,
              initialUserId: c.trGestorUserId,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        _Section('6) Licenciamento, Segurança e Sustentabilidade'),
        Wrap(spacing: 16, runSpacing: 16, children: [
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Licenciamento ambiental',
              controller: c.trLicenciamentoAmbientalCtrl,
              items: const ['Sim', 'Não', 'A confirmar'],
              onChanged: (v) => setState(() => c.trLicenciamentoAmbientalCtrl.text = v ?? ''),
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.trSegurancaTrabalhoCtrl,
              labelText: 'Segurança do trabalho / Sinalização de obra',
              maxLines: 3,
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.trSustentabilidadeCtrl,
              labelText: 'Diretrizes de sustentabilidade e acessibilidade',
              maxLines: 3,
              enabled: c.isEditable,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        _Section('7) Preços, Pagamento, Reajuste e Garantia'),
        Wrap(spacing: 16, runSpacing: 16, children: [
          SizedBox(
            width: _w(context, itemsPerLine: 3),
            child: CustomTextField(
              controller: c.trEstimativaValorCtrl,
              labelText: 'Estimativa de valor (R\$)',
              enabled: c.isEditable,
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 3),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Critério de reajuste',
              controller: c.trReajusteIndiceCtrl,
              items: const ['IPCA', 'INCC', 'IGP-M', 'Sem reajuste'],
              onChanged: (v) => setState(() => c.trReajusteIndiceCtrl.text = v ?? ''),
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 3),
            child: CustomTextField(
              controller: c.trCondicoesPagamentoCtrl,
              labelText: 'Condições de pagamento',
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Garantia contratual',
              controller: c.trGarantiaCtrl,
              items: const ['Não exigida','Caução em dinheiro','Seguro-garantia','Fiança bancária'],
              onChanged: (v) => setState(() => c.trGarantiaCtrl.text = v ?? ''),
            ),
          ),
        ]),
        const SizedBox(height: 16),

        _Section('8) Riscos, Penalidades e Demais Condições'),
        Wrap(spacing: 16, runSpacing: 16, children: [
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.trMatrizRiscosCtrl,
              labelText: 'Matriz de riscos (preliminar)',
              maxLines: 4,
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.trPenalidadesCtrl,
              labelText: 'Penalidades e sanções',
              maxLines: 3,
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.trDemaisCondicoesCtrl,
              labelText: 'Demais condições (visita técnica, seguros, interfaces etc.)',
              maxLines: 3,
              enabled: c.isEditable,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        _Section('9) Documentos / Referências'),
        Wrap(spacing: 16, runSpacing: 16, children: [
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.trLinksDocumentosCtrl,
              labelText: 'Links/Referências (SEI, projetos, estudos, mapas)',
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

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: cs.primary)),
    );
  }
}
