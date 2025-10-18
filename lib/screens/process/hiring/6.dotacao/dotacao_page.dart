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
import 'package:siged/screens/process/hiring/6.dotacao/dotacao_controller.dart';

class DotacaoPage extends StatefulWidget {
  final DotacaoController controller;
  const DotacaoPage({super.key, required this.controller});

  @override
  State<DotacaoPage> createState() => _DotacaoPageState();
}

class _DotacaoPageState extends State<DotacaoPage> with FormValidationMixin {
  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx,
    itemsPerLine: itemsPerLine,
    spacing: 12,
    margin: 12,
    extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dotação Orçamentária',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // 1) Identificação/Exercício
          _Section('1) Identificação / Exercício'),
          Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.exercicioCtrl,
                labelText: 'Exercício (ano)',
                enabled: c.isEditable,
                keyboardType: TextInputType.number,
                //validator: validateNumber,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.processoSeiCtrl,
                labelText: 'Nº do processo (SEI/Interno)',
                enabled: c.isEditable,
                validator: validateRequired,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: AutocompleteUserClass(
                label: 'Responsável orçamentário',
                controller: c.responsavelOrcCtrl,
                allUsers: users,
                enabled: c.isEditable,
                initialUserId: c.responsavelOrcUserId,
                validator: validateRequired,
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // 2) Vinculação Programática
          _Section('2) Vinculação Programática'),
          Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.unidadeOrcCtrl,
                labelText: 'Unidade Orçamentária (UO)',
                enabled: c.isEditable,
                validator: validateRequired,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.ugCtrl,
                labelText: 'UG (Unidade Gestora)',
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.programaCtrl,
                labelText: 'Programa',
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.acaoCtrl,
                labelText: 'Ação',
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.ptresCtrl,
                labelText: 'PTRES/PI/OB (quando aplicável)',
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.planoOrcCtrl,
                labelText: 'Plano Orçamentário (PO)',
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: DropDownButtonChange(
                enabled: c.isEditable,
                labelText: 'Fonte de Recurso',
                controller: c.fonteRecursoCtrl,
                items: const [
                  '0100 - Tesouro',
                  '0120 - Convênios',
                  '0150 - Vinculados',
                  'Outros'
                ],
                onChanged: (v) => setState(() => c.fonteRecursoCtrl.text = v ?? ''),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // 3) Natureza da Despesa
          _Section('3) Natureza da Despesa'),
          Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.modalidadeAplicacaoCtrl,
                labelText: 'Modalidade de aplicação (ex.: 90)',
                enabled: c.isEditable,
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.elementoDespesaCtrl,
                labelText: 'Elemento (ex.: 39, 44)',
                enabled: c.isEditable,
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.subelementoCtrl,
                labelText: 'Subelemento (quando houver)',
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: _w(context, itemsPerLine: 1),
              child: CustomTextField(
                controller: c.descricaoNdCtrl,
                labelText: 'Descrição da ND',
                enabled: c.isEditable,
                maxLines: 2,
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // 4) Reserva / Planejamento
          _Section('4) Reserva Orçamentária / Planejamento'),
          Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.reservaNumeroCtrl,
                labelText: 'Nº da Reserva',
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.reservaDataCtrl,
                labelText: 'Data da Reserva',
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
              width: _w(context),
              child: CustomTextField(
                controller: c.reservaValorCtrl,
                labelText: 'Valor Reservado (R\$)',
                enabled: c.isEditable,
                keyboardType: TextInputType.number,
                //validator: validateNumber,
              ),
            ),
            SizedBox(
              width: _w(context, itemsPerLine: 1),
              child: CustomTextField(
                controller: c.reservaObservacoesCtrl,
                labelText: 'Observações da reserva',
                enabled: c.isEditable,
                maxLines: 2,
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // 5) Empenho
          _Section('5) Empenho'),
          Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(
              width: _w(context),
              child: DropDownButtonChange(
                enabled: c.isEditable,
                labelText: 'Modalidade de Empenho',
                controller: c.empenhoModalidadeCtrl,
                items: const ['Ordinário', 'Estimativo', 'Global'],
                onChanged: (v) => setState(() => c.empenhoModalidadeCtrl.text = v ?? ''),
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.empenhoNumeroCtrl,
                labelText: 'Nº da NE (Nota de Empenho)',
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.empenhoDataCtrl,
                labelText: 'Data da NE',
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
              width: _w(context),
              child: CustomTextField(
                controller: c.empenhoValorCtrl,
                labelText: 'Valor Empenhado (R\$)',
                enabled: c.isEditable,
                keyboardType: TextInputType.number,
                //validator: validateNumber,
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // 6) Cronograma de Desembolso
          _Section('6) Cronograma de Desembolso (resumo)'),
          Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(
              width: _w(context),
              child: DropDownButtonChange(
                enabled: c.isEditable,
                labelText: 'Periodicidade',
                controller: c.desembolsoPeriodicidadeCtrl,
                items: const ['Mensal', 'Bimestral', 'Trimestral', 'Outro'],
                onChanged: (v) => setState(() => c.desembolsoPeriodicidadeCtrl.text = v ?? ''),
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.desembolsoMesesCtrl,
                labelText: 'Meses/Marcos (ex.: Jan–Jun)',
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: _w(context, itemsPerLine: 1),
              child: CustomTextField(
                controller: c.desembolsoObservacoesCtrl,
                labelText: 'Observações / condicionantes',
                enabled: c.isEditable,
                maxLines: 2,
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // 7) Documentos e Links
          _Section('7) Documentos / Links'),
          CustomTextField(
            controller: c.linksComprovacoesCtrl,
            labelText: 'Links (NE, Reserva, prints do SIAF/SIGEF, planilhas)',
            enabled: c.isEditable,
            maxLines: 2,
          ),

          const SizedBox(height: 24),
        ],
      ),
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
