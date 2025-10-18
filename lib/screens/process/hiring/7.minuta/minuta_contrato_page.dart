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
import 'package:siged/screens/process/hiring/7.minuta/minuta_contrato_controller.dart';

class MinutaContratoPage extends StatefulWidget {
  final MinutaContratoController controller;
  final bool readOnly;
  const MinutaContratoPage({super.key, required this.controller, this.readOnly = false});

  @override
  State<MinutaContratoPage> createState() => _MinutaContratoPageState();
}

class _MinutaContratoPageState extends State<MinutaContratoPage>
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
        const Text('Minuta do Contrato',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        _Section('1) Identificação da Minuta'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.mcNumeroCtrl,
              labelText: 'Nº da Minuta / Referência',
              enabled: c.isEditable,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.mcVersaoCtrl,
              labelText: 'Versão',
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.mcDataElaboracaoCtrl,
              labelText: 'Data de elaboração',
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
        ]),
        const SizedBox(height: 16),

        _Section('2) Partes Contratantes e Objeto'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context, itemsPerLine: 2),
            child: CustomTextField(
              controller: c.mcContratanteCtrl,
              labelText: 'Contratante (Órgão/Unidade)',
              enabled: c.isEditable,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 2),
            child: CustomTextField(
              controller: c.mcContratadaRazaoCtrl,
              labelText: 'Contratada (Razão Social)',
              enabled: c.isEditable,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.mcContratadaCnpjCtrl,
              labelText: 'CNPJ da Contratada',
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
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.mcObjetoResumoCtrl,
              labelText: 'Objeto (resumo para o contrato)',
              maxLines: 3,
              enabled: c.isEditable,
              validator: validateRequired,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        _Section('3) Valor Contratual'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.mcValorGlobalCtrl,
              labelText: 'Valor global (R\$)',
              enabled: c.isEditable,
              keyboardType: TextInputType.number,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        _Section('4) Gestão e Referências (do TR/Edital)'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context, itemsPerLine: 2),
            child: AutocompleteUserClass(
              label: 'Gestor do contrato (definido no processo)',
              controller: c.mcGestorCtrl,
              allUsers: users,
              enabled: c.isEditable,
              initialUserId: c.mcGestorUserId,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 2),
            child: AutocompleteUserClass(
              label: 'Fiscal do contrato (definido no processo)',
              controller: c.mcFiscalCtrl,
              allUsers: users,
              enabled: c.isEditable,
              initialUserId: c.mcFiscalUserId,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.mcLinksAnexosCtrl,
              labelText: 'Links/Anexos (TR, ETP, ARP, proposta, documentos do gestor)',
              maxLines: 2,
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: false, // referência — preenchido a partir do TR
              labelText: 'Regime de execução (referência TR)',
              controller: TextEditingController(text: c.mcRegimeExecucaoRef ?? ''),
              items: const [],
              onChanged: (_) {},
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              enabled: false, // referência — prazos do TR
              controller: TextEditingController(text: c.mcPrazosRef ?? ''),
              labelText: 'Prazos/Vigência (referência TR)',
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
