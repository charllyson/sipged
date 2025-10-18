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
import 'package:siged/screens/process/hiring/10.finish/termo_arquivamento_controller.dart';


class TermoArquivamentoPage extends StatefulWidget {
  final TermoArquivamentoController controller;
  final bool readOnly;

  const TermoArquivamentoPage({
    super.key,
    required this.controller,
    this.readOnly = false,
  });

  @override
  State<TermoArquivamentoPage> createState() => _TermoArquivamentoPageState();
}

class _TermoArquivamentoPageState extends State<TermoArquivamentoPage>
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
        const Text('Termo de Arquivamento',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // 1) Metadados
        _Section('1) Metadados'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.taNumeroCtrl,
              labelText: 'Nº do Termo',
              enabled: c.isEditable,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.taDataCtrl,
              labelText: 'Data',
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
              controller: c.taProcessoCtrl,
              labelText: 'Nº do processo (SEI/Interno)',
              enabled: c.isEditable,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: AutocompleteUserClass(
              label: 'Responsável pelo termo',
              controller: c.taResponsavelCtrl,
              allUsers: users,
              enabled: c.isEditable,
              initialUserId: c.taResponsavelUserId,
              validator: validateRequired,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // 2) Motivo e Abrangência
        _Section('2) Motivo e Abrangência'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Motivo do arquivamento',
              controller: c.taMotivoCtrl,
              items: const [
                'Concluído com êxito (objeto atendido)',
                'Desistência/Perda de objeto',
                'Fracasso/Deserto',
                'Inviabilidade técnica/econômica',
                'Determinação superior',
                'Outros'
              ],
              onChanged: (v) => setState(() => c.taMotivoCtrl.text = v ?? ''),
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Abrangência',
              controller: c.taAbrangenciaCtrl,
              items: const ['Total', 'Parcial (lotes/itens)'],
              onChanged: (v) => setState(() => c.taAbrangenciaCtrl.text = v ?? ''),
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.taDescricaoAbrangenciaCtrl,
              labelText: 'Descrição da abrangência (lotes/itens atingidos)',
              maxLines: 2,
              enabled: c.isEditable,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // 3) Fundamentação
        _Section('3) Fundamentação'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.taFundamentosLegaisCtrl,
              labelText: 'Fundamentos legais (ex.: Lei 14.133/2021, art. ...)',
              maxLines: 3,
              enabled: c.isEditable,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.taJustificativaCtrl,
              labelText: 'Justificativa (resumo técnico/jurídico)',
              maxLines: 3,
              enabled: c.isEditable,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // 4) Peças Anexas
        _Section('4) Peças Anexas'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.taPecasAnexasCtrl,
              labelText: 'Peças anexas (TR, ETP, pareceres, publicações etc.)',
              maxLines: 2,
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.taLinksCtrl,
              labelText: 'Links (SEI/Drive/PNCP)',
              maxLines: 2,
              enabled: c.isEditable,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // 5) Decisão da Autoridade
        _Section('5) Decisão da Autoridade'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context, itemsPerLine: 2),
            child: AutocompleteUserClass(
              label: 'Autoridade competente',
              controller: c.taAutoridadeCtrl,
              allUsers: users,
              enabled: c.isEditable,
              initialUserId: c.taAutoridadeUserId,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Decisão',
              controller: c.taDecisaoCtrl,
              items: const ['Aprovo o arquivamento', 'Arquivar após saneamento', 'Não aprovo'],
              onChanged: (v) => setState(() => c.taDecisaoCtrl.text = v ?? ''),
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.taDataDecisaoCtrl,
              labelText: 'Data da decisão',
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
              controller: c.taObservacoesDecisaoCtrl,
              labelText: 'Observações da decisão',
              maxLines: 2,
              enabled: c.isEditable,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // 6) Reabertura (se aplicável)
        _Section('6) Reabertura (se aplicável)'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Condição de reabertura',
              controller: c.taReaberturaCondicaoCtrl,
              items: const ['Sem reabertura', 'Após saneamento', 'Após dotação', 'Outro'],
              onChanged: (v) => setState(() => c.taReaberturaCondicaoCtrl.text = v ?? ''),
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.taPrazoReaberturaCtrl,
              labelText: 'Prazo estimado p/ reabertura',
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
