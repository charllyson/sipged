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
import 'package:siged/screens/process/hiring/9.publication/publicacao_extrato_controller.dart';

class PublicacaoExtratoPage extends StatefulWidget {
  final PublicacaoExtratoController controller;
  final bool readOnly;

  const PublicacaoExtratoPage({
    super.key,
    required this.controller,
    this.readOnly = false,
  });

  @override
  State<PublicacaoExtratoPage> createState() => _PublicacaoExtratoPageState();
}

class _PublicacaoExtratoPageState extends State<PublicacaoExtratoPage>
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
        const Text('Publicação do Extrato',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // 1) Metadados do Extrato
        _Section('1) Metadados do Extrato'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Tipo de extrato',
              controller: c.peTipoExtratoCtrl,
              items: const ['Extrato de Contrato', 'Extrato de ARP', 'Extrato de Aditivo/Apostilamento'],
              onChanged: (v) => setState(() => c.peTipoExtratoCtrl.text = v ?? ''),
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.peNumeroContratoCtrl,
              labelText: 'Nº do contrato/ARP',
              enabled: c.isEditable,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.peProcessoCtrl,
              labelText: 'Nº do processo (SEI/Interno)',
              enabled: c.isEditable,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.peObjetoResumoCtrl,
              labelText: 'Objeto (resumo para o extrato)',
              maxLines: 3,
              enabled: c.isEditable,
              validator: validateRequired,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // 2) Partes / Valores / Vigência
        _Section('2) Partes, Valores e Vigência'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.peContratadaRazaoCtrl,
              labelText: 'Contratada (Razão Social)',
              enabled: c.isEditable,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.peContratadaCnpjCtrl,
              labelText: 'CNPJ',
              enabled: c.isEditable,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(14),
                TextInputMask(mask: '99.999.999/9999-99'),
              ],
              keyboardType: TextInputType.number,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.peValorCtrl,
              labelText: 'Valor (R\$)',
              enabled: c.isEditable,
              keyboardType: TextInputType.number,
              //validator: validateNumber,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.peVigenciaCtrl,
              labelText: 'Vigência (ex.: 12 meses ou 24/09/2025 a 23/09/2026)',
              enabled: c.isEditable,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // 3) Veículo de Publicação
        _Section('3) Veículo de Publicação'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Veículo',
              controller: c.peVeiculoCtrl,
              items: const ['DOE/Estadual', 'DOU', 'Diário Municipal', 'PNCP', 'Site Oficial', 'Outro'],
              onChanged: (v) => setState(() => c.peVeiculoCtrl.text = v ?? ''),
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.peEdicaoNumeroCtrl,
              labelText: 'Edição/Nº',
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.peDataEnvioCtrl,
              labelText: 'Data de envio',
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
              controller: c.peDataPublicacaoCtrl,
              labelText: 'Data da publicação',
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
              controller: c.peLinkPublicacaoCtrl,
              labelText: 'Link da publicação (URL/PNCP/arquivo)',
              enabled: c.isEditable,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // 4) Status / Controle de Prazos
        _Section('4) Status e Controle de Prazos'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Status',
              controller: c.peStatusCtrl,
              items: const ['Rascunho', 'Enviado', 'Publicado', 'Devolvido para ajustes'],
              onChanged: (v) => setState(() => c.peStatusCtrl.text = v ?? ''),
            ),
          ),
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Prazo legal atendido?',
              controller: c.pePrazoLegalCtrl,
              items: const ['Sim', 'Não', 'N/A'],
              onChanged: (v) => setState(() => c.pePrazoLegalCtrl.text = v ?? ''),
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.peObservacoesCtrl,
              labelText: 'Observações / ajustes solicitados',
              maxLines: 2,
              enabled: c.isEditable,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // 5) Responsável
        _Section('5) Responsável'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: AutocompleteUserClass(
              label: 'Responsável pela publicação',
              controller: c.peResponsavelCtrl,
              allUsers: users,
              enabled: c.isEditable,
              initialUserId: c.peResponsavelUserId,
              validator: validateRequired,
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
