import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

import 'package:siged/_utils/mask_class.dart';
import 'package:siged/_utils/responsive_utils.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/autocomplete/autocomplete_user_class.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';

import 'package:siged/screens/process/hiring/1.dfd/dfd_controller.dart';

class DfdPage extends StatefulWidget {
  final DfdController controller;
  const DfdPage({super.key, required this.controller});

  @override
  State<DfdPage> createState() => _DfdPageState();
}

class _DfdPageState extends State<DfdPage> with FormValidationMixin {
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);

    inputWidth({int itemsPerLine = 4}) => responsiveInputWidth(
      context: context,
      itemsPerLine: itemsPerLine,
      spacing: 12,
      margin: 12,
      extraPadding: 24,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionTitle('1) Identificação da Demanda'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: inputWidth(itemsPerLine: 4),
            child: CustomTextField(
              controller: c.dfdOrgaoDemandanteCtrl,
              enabled: c.isEditable,
              validator: validateRequired,
              labelText: 'Órgão demandante',
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 4),
            child: CustomTextField(
              controller: c.dfdUnidadeSolicitanteCtrl,
              enabled: c.isEditable,
              validator: validateRequired,
              labelText: 'Unidade/Setor solicitante',
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 4),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Regional/Área',
              controller: TextEditingController(text: c.dfdRegionalValue),
              items: c.dfdRegionaisOptions,
              onChanged: (v) => setState(() => c.dfdRegionalValue = v),
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 4),
            child: AutocompleteUserClass(
              label: 'Solicitante (responsável pela demanda)',
              controller: c.dfdSolicitanteCtrl,
              allUsers: users,
              enabled: c.isEditable,
              initialUserId: c.dfdSolicitanteUserId,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 4),
            child: CustomTextField(
              controller: c.dfdCpfSolicitanteCtrl,
              validator: validateRequired,
              enabled: c.isEditable,
              labelText: 'CPF do solicitante',
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
                TextInputMask(mask: '999.999.999-99'),
              ],
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 4),
            child: CustomTextField(
              controller: c.dfdCargoSolicitanteCtrl,
              enabled: c.isEditable,
              validator: validateRequired,
              labelText: 'Cargo/Função',
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 4),
            child: CustomTextField(
              controller: c.dfdEmailSolicitanteCtrl,
              enabled: c.isEditable,
              validator: validateEmail,
              labelText: 'E-mail institucional',
              keyboardType: TextInputType.emailAddress,
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 4),
            child: CustomTextField(
              controller: c.dfdTelefoneSolicitanteCtrl,
              enabled: c.isEditable,
              validator: validateRequired,
              labelText: 'Telefone do solicitante',
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
                TextInputMask(mask: '(99) 99999-9999'),
              ],
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 4),
            child: CustomTextField(
              controller: c.dfdDataSolicitacaoCtrl,
              enabled: c.isEditable,
              validator: validateRequired,
              labelText: 'Data da solicitação',
              hintText: 'dd/mm/aaaa',
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
                TextInputMask(mask: '99/99/9999'),
              ],
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 4),
            child: CustomTextField(
              controller: c.dfdProtocoloSeiCtrl,
              enabled: c.isEditable,
              validator: validateRequired,
              labelText: 'Nº do processo/SEI/Protocolo',
            ),
          ),
        ]),
        const SizedBox(height: 16),

        _SectionTitle('2) Objeto / Escopo'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: inputWidth(itemsPerLine: 3),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Tipo de contratação',
              controller: TextEditingController(text: c.dfdTipoContratacaoValue),
              items: const [
                'Obra de engenharia',
                'Serviço de engenharia',
                'Serviço comum',
                'Aquisição de material/equipamento',
              ],
              onChanged: (v) => setState(() => c.dfdTipoContratacaoValue = v),
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 3),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Modalidade estimada',
              controller: TextEditingController(text: c.dfdModalidadeEstimativaValue),
              items: const [
                'Dispensa',
                'Inexigibilidade',
                'Pregão',
                'Concorrência',
                'RDC',
                'Concurso',
              ],
              onChanged: (v) => setState(() => c.dfdModalidadeEstimativaValue = v),
              validator: validateRequired,
            ),
          ),
          // ⛔ Regime de execução – removido do DFD (fica no TR)
          SizedBox(
            width: inputWidth(itemsPerLine: 1),
            child: CustomTextField(
              controller: c.dfdDescricaoObjetoCtrl,
              enabled: c.isEditable,
              validator: validateRequired,
              labelText: 'Descrição resumida do objeto',
              maxLines: 3,
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 1),
            child: CustomTextField(
              controller: c.dfdJustificativaCtrl,
              enabled: c.isEditable,
              validator: validateRequired,
              labelText: 'Justificativa da contratação (problema/objetivo)',
              maxLines: 4,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        _SectionTitle('3) Localização / Escopo rodoviário'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: inputWidth(itemsPerLine: 6),
            child: CustomTextField(
              controller: c.dfdUFCtrl,
              enabled: c.isEditable,
              validator: validateRequired,
              labelText: 'UF',
              hintText: 'ex.: AL',
              inputFormatters: [LengthLimitingTextInputFormatter(2)],
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 6),
            child: CustomTextField(
              controller: c.dfdMunicipioCtrl,
              enabled: c.isEditable,
              validator: validateRequired,
              labelText: 'Município (principal)',
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 6),
            child: CustomTextField(
              controller: c.dfdRodoviaCtrl,
              enabled: c.isEditable,
              validator: validateRequired,
              labelText: 'Rodovia',
              hintText: 'ex.: AL-101 SUL',
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 6),
            child: CustomTextField(
              controller: c.dfdKmInicialCtrl,
              enabled: c.isEditable,
              labelText: 'KM inicial',
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 6),
            child: CustomTextField(
              controller: c.dfdKmFinalCtrl,
              enabled: c.isEditable,
              labelText: 'KM final',
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 6),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Natureza da intervenção',
              controller: TextEditingController(text: c.dfdNaturezaIntervencaoValue),
              items: const [
                'Conservação rotineira',
                'Conservação periódica',
                'Restauração',
                'Reabilitação',
                'Duplicação',
                'Construção',
                'Sinalização',
              ],
              onChanged: (v) => setState(() => c.dfdNaturezaIntervencaoValue = v),
              validator: validateRequired,
            ),
          ),
          // ⛔ Prazo/Vigência – removidos do DFD (ficam no TR)
        ]),
        const SizedBox(height: 16),

        _SectionTitle('4) Estimativa Orçamentária (preliminar)'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: inputWidth(itemsPerLine: 3),
            child: CustomTextField(
              controller: c.dfdFonteRecursoCtrl,
              enabled: c.isEditable,
              validator: validateRequired,
              labelText: 'Fonte de recurso',
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 3),
            child: CustomTextField(
              controller: c.dfdProgramaTrabalhoCtrl,
              enabled: c.isEditable,
              labelText: 'Programa de trabalho / Ação',
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 3),
            child: CustomTextField(
              controller: c.dfdPtresCtrl,
              enabled: c.isEditable,
              labelText: 'PTRES (opcional)',
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 3),
            child: CustomTextField(
              controller: c.dfdNaturezaDespesaCtrl,
              enabled: c.isEditable,
              labelText: 'Natureza da despesa (ND)',
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 3),
            child: CustomTextField(
              controller: c.dfdEstimativaValorCtrl,
              enabled: c.isEditable,
              labelText: 'Estimativa de valor (R\$)',
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 3),
            child: CustomTextField(
              controller: c.dfdMetodologiaEstimativaCtrl,
              enabled: c.isEditable,
              labelText: 'Metodologia da estimativa (ex.: SINAPI, DER, etc.)',
            ),
          ),
        ]),
        const SizedBox(height: 16),

        _SectionTitle('5) Riscos e Impacto'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: inputWidth(itemsPerLine: 2),
            child: CustomTextField(
              controller: c.dfdRiscosPrincipaisCtrl,
              enabled: c.isEditable,
              labelText: 'Riscos principais',
              maxLines: 3,
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 2),
            child: CustomTextField(
              controller: c.dfdImpactoNaoContratarCtrl,
              enabled: c.isEditable,
              labelText: 'Impacto se não contratar',
              maxLines: 3,
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 4),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Prioridade',
              controller: TextEditingController(text: c.dfdPrioridadeValue),
              items: const ['Baixa', 'Média', 'Alta', 'Crítica'],
              onChanged: (v) => setState(() => c.dfdPrioridadeValue = v),
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 4),
            child: CustomTextField(
              controller: c.dfdDataLimiteUrgenciaCtrl,
              enabled: c.isEditable,
              labelText: 'Data limite/urgência (se houver)',
              hintText: 'dd/mm/aaaa',
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
                TextInputMask(mask: '99/99/9999'),
              ],
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 4),
            child: CustomTextField(
              controller: c.dfdMotivacaoLegalCtrl,
              enabled: c.isEditable,
              labelText: 'Motivação legal (ex.: decisão judicial)',
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 4),
            child: CustomTextField(
              controller: c.dfdAmparoNormativoCtrl,
              enabled: c.isEditable,
              labelText: 'Amparo normativo (lei/artigo)',
            ),
          ),
        ]),
        const SizedBox(height: 16),

        _SectionTitle('6) Documentos / Checklists'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          _yesNoDrop(
            width: inputWidth(itemsPerLine: 4),
            label: 'ETP/Estudos preliminares anexos?',
            value: c.dfdEtpAnexoValue,
            onChanged: (v) => setState(() => c.dfdEtpAnexoValue = v),
          ),
          _yesNoDrop(
            width: inputWidth(itemsPerLine: 4),
            label: 'Projeto básico/executivo disponível?',
            value: c.dfdProjetoBasicoValue,
            onChanged: (v) => setState(() => c.dfdProjetoBasicoValue = v),
          ),
          _yesNoDrop(
            width: inputWidth(itemsPerLine: 4),
            label: 'Termo de Referência/Matriz de riscos?',
            value: c.dfdTermoMatrizRiscosValue,
            onChanged: (v) => setState(() => c.dfdTermoMatrizRiscosValue = v),
          ),
          _yesNoDrop(
            width: inputWidth(itemsPerLine: 4),
            label: 'Parecer jurídico prévio?',
            value: c.dfdParecerJuridicoValue,
            onChanged: (v) => setState(() => c.dfdParecerJuridicoValue = v),
          ),
          _yesNoDrop(
            width: inputWidth(itemsPerLine: 4),
            label: 'Autorização de abertura do processo?',
            value: c.dfdAutorizacaoAberturaValue,
            onChanged: (v) => setState(() => c.dfdAutorizacaoAberturaValue = v),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 2),
            child: CustomTextField(
              controller: c.dfdLinksDocumentosCtrl,
              enabled: c.isEditable,
              labelText: 'Links/Referências (SEI, Storage, etc.)',
              maxLines: 2,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        _SectionTitle('7) Aprovação / Alçada'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: inputWidth(itemsPerLine: 3),
            child: AutocompleteUserClass(
              label: 'Autoridade aprovadora',
              controller: c.dfdAutoridadeAprovadoraCtrl,
              allUsers: users,
              enabled: c.isEditable,
              initialUserId: c.dfdAutoridadeAprovadoraUserId,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 3),
            child: CustomTextField(
              controller: c.dfdCpfAutoridadeCtrl,
              enabled: c.isEditable,
              validator: validateRequired,
              labelText: 'CPF da autoridade',
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
                TextInputMask(mask: '999.999.999-99'),
              ],
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 3),
            child: CustomTextField(
              controller: c.dfdDataAprovacaoCtrl,
              enabled: c.isEditable,
              validator: validateRequired,
              labelText: 'Data da aprovação',
              hintText: 'dd/mm/aaaa',
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
                TextInputMask(mask: '99/99/9999'),
              ],
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(
            width: inputWidth(itemsPerLine: 1),
            child: CustomTextField(
              controller: c.dfdParecerResumoCtrl,
              enabled: c.isEditable,
              labelText: 'Parecer/resumo da aprovação',
              maxLines: 3,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        _SectionTitle('8) Observações'),
        CustomTextField(
          controller: c.dfdObservacoesCtrl,
          enabled: c.isEditable,
          labelText: 'Observações complementares',
          maxLines: 4,
        ),
      ]),
    );
  }

  Widget _yesNoDrop({
    required double width,
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: width,
      child: DropDownButtonChange(
        enabled: widget.controller.isEditable,
        labelText: label,
        controller: TextEditingController(text: value),
        items: const ['Sim', 'Não', 'N/A'],
        onChanged: onChanged,
        validator: validateRequired,
      ),
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
